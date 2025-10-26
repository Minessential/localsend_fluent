#include "winrt_ext.h"

#include <windows.h>
#include <appmodel.h>
#include <winrt/windows.foundation.h>
#include <winrt/windows.foundation.collections.h>
#include <winrt/windows.storage.h>
#include <winrt/windows.storage.streams.h>
#include <winrt/windows.applicationmodel.activation.h>
#include <winrt/windows.applicationmodel.datatransfer.h>
#include <winrt/windows.applicationmodel.datatransfer.sharetarget.h>
#include <winrt/windows.data.json.h>
#include <winrt/windows.system.h>
#include <shlobj.h>

using winrt::Windows::ApplicationModel::AppInstance;
using winrt::Windows::ApplicationModel::Activation::ActivationKind;
using winrt::Windows::ApplicationModel::Activation::ShareTargetActivatedEventArgs;
using winrt::Windows::ApplicationModel::Activation::LaunchActivatedEventArgs;
using winrt::Windows::ApplicationModel::DataTransfer::DataPackageView;
using winrt::Windows::ApplicationModel::DataTransfer::StandardDataFormats;
using winrt::Windows::ApplicationModel::StartupTask;
using winrt::Windows::ApplicationModel::StartupTaskState;
using winrt::Windows::System::Launcher;
using winrt::Windows::Data::Json::JsonArray;
using winrt::Windows::Data::Json::JsonObject;
using winrt::Windows::Data::Json::JsonValue;

enum class SharedAttachmentType {
  IMAGE,
  VIDEO,
  AUDIO,
  FILE,
};

bool IsRunningWithIdentity() {
  constexpr SIZE_T kPackageNameMaxLength = 1024;
  UINT32 length = kPackageNameMaxLength;
  wchar_t packageName[kPackageNameMaxLength];
  LONG result = GetCurrentPackageFullName(&length, packageName);

  return (result == ERROR_SUCCESS);
}

winrt::hstring GetSharedMedia() {
  auto args = AppInstance::GetActivatedEventArgs();
  if (args == nullptr)
    return winrt::hstring();
  if (args.Kind() != ActivationKind::ShareTarget)
    return winrt::hstring();
  auto share_target_args = args.as<ShareTargetActivatedEventArgs>();
  auto op = share_target_args.ShareOperation();
  auto data = op.Data();
  JsonObject json;
  if (data.Contains(StandardDataFormats::Text())) {
    auto text = data.GetTextAsync().get();
    json.SetNamedValue(L"content", JsonValue::CreateStringValue(text));
  }
  if (data.Contains(StandardDataFormats::Uri())) {
    auto uri = data.GetUriAsync().get();
    json.SetNamedValue(L"content", JsonValue::CreateStringValue(uri.ToString()));
  }
  if (data.Contains(StandardDataFormats::StorageItems())) {
    JsonArray attachments;
    auto storage_items = data.GetStorageItemsAsync().get();
    for (const auto& item : storage_items) {
      JsonObject attachment;
      attachment.SetNamedValue(L"type", JsonValue::CreateNumberValue(double(SharedAttachmentType::FILE)));
      attachment.SetNamedValue(L"path", JsonValue::CreateStringValue(item.Path()));
      attachments.Append(attachment);
    }
    json.SetNamedValue(L"attachments", attachments);
  }
  return json.Stringify();
}

// Check if startup task is enabled
bool IsStartupTaskEnabled() {
  if (!IsRunningWithIdentity()) {
    return false;
  }
  
  try {
    auto startupTask = StartupTask::GetAsync(L"LocalSendFluentStartupTask").get();
    auto state = startupTask.State();
    return state == StartupTaskState::Enabled;
  } catch (...) {
    return false;
  }
}

// Enable startup task
bool EnableStartupTask() {
  if (!IsRunningWithIdentity()) {
    return false;
  }
  
  try {
    auto startupTask = StartupTask::GetAsync(L"LocalSendFluentStartupTask").get();
    auto state = startupTask.RequestEnableAsync().get();
    if (state != StartupTaskState::Enabled) {
      // Open Windows Settings if enabling failed
      auto uri = winrt::Windows::Foundation::Uri(L"ms-settings:startupapps");
      Launcher::LaunchUriAsync(uri).get();
      return false;
    }
    return true;
  } catch (...) {
    // Open Windows Settings on exception
    try {
      auto uri = winrt::Windows::Foundation::Uri(L"ms-settings:startupapps");
      Launcher::LaunchUriAsync(uri).get();
    } catch (...) {}
    return false;
  }
}

// Disable startup task
bool DisableStartupTask() {
  if (!IsRunningWithIdentity()) {
    return false;
  }
  
  try {
    auto startupTask = StartupTask::GetAsync(L"LocalSendFluentStartupTask").get();
    startupTask.Disable();
    return true;
  } catch (...) {
    // Open Windows Settings on exception
    try {
      auto uri = winrt::Windows::Foundation::Uri(L"ms-settings:startupapps");
      Launcher::LaunchUriAsync(uri).get();
    } catch (...) {}
    return false;
  }
}

// Check if auto-start should be hidden (minimize to tray enabled)
bool IsAutoStartHidden() {
  try {
    // Get APPDATA path
    wchar_t* appDataPath = nullptr;
    if (SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, nullptr, &appDataPath) != S_OK) {
      return false;
    }
    
    // Build INI file path
    std::wstring iniPath = std::wstring(appDataPath) + L"\\LocalSend\\settings.ini";
    CoTaskMemFree(appDataPath);
    
    // Read value from INI file
    wchar_t buffer[16] = {0};
    DWORD result = GetPrivateProfileStringW(
      L"Startup",
      L"MinimizeToTray",
      L"0",  // Default value
      buffer,
      sizeof(buffer) / sizeof(wchar_t),
      iniPath.c_str()
    );
    
    if (result > 0) {
      return (wcscmp(buffer, L"1") == 0 || _wcsicmp(buffer, L"true") == 0);
    }
    
    return false;
  } catch (...) {
    return false;
  }
}

// Set auto-start hidden setting (minimize to tray on startup)
bool SetAutoStartHidden(bool value) {
  try {
    // Get APPDATA path
    wchar_t* appDataPath = nullptr;
    if (SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, nullptr, &appDataPath) != S_OK) {
      return false;
    }
    
    // Build INI file path
    std::wstring iniPath = std::wstring(appDataPath) + L"\\LocalSend\\settings.ini";
    std::wstring dirPath = std::wstring(appDataPath) + L"\\LocalSend";
    CoTaskMemFree(appDataPath);
    
    // Ensure directory exists
    CreateDirectoryW(dirPath.c_str(), nullptr);
    
    // Write value to INI file
    BOOL result = WritePrivateProfileStringW(
      L"Startup",
      L"MinimizeToTray",
      value ? L"1" : L"0",
      iniPath.c_str()
    );
    
    return result != 0;
  } catch (...) {
    return false;
  }
}

// Check if app was launched by startup task
bool IsLaunchedByStartupTask() {
  try {
    auto args = AppInstance::GetActivatedEventArgs();
    if (args == nullptr) {
      return false;
    }
    
    return args.Kind() == ActivationKind::StartupTask;
  } catch (...) {
    return false;
  }
}