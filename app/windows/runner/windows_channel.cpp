#include "windows_channel.h"
#include "winrt_ext.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>

#include <memory>

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResult;

void SetupWindowsChannel(flutter::FlutterEngine* engine) {
  const std::string channel_name = "windows-delegate-channel";
  
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      engine->messenger(), channel_name,
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const MethodCall<EncodableValue>& call,
         std::unique_ptr<MethodResult<EncodableValue>> result) {
        const std::string& method = call.method_name();

        if (method == "havePackageIdentity") {
          bool has_identity = IsRunningWithIdentity();
          result->Success(EncodableValue(has_identity));
        }
        else if (method == "isRunAtStartup") {
          bool is_enabled = IsStartupTaskEnabled();
          result->Success(EncodableValue(is_enabled));
        }
        else if (method == "enableRunAtStartup") {
          bool success = EnableStartupTask();
          result->Success(EncodableValue(success));
        }
        else if (method == "disableRunAtStartup") {
          bool success = DisableStartupTask();
          result->Success(EncodableValue(success));
        }
        else if (method == "isRunAtStartupHidden") {
          bool is_hidden = IsAutoStartHidden();
          result->Success(EncodableValue(is_hidden));
        }
        else if (method == "setRunAtStartupHidden") {
          const auto* arguments = std::get_if<bool>(call.arguments());
          if (arguments == nullptr) {
            result->Error("INVALID_ARGUMENT", "Expected a boolean argument");
            return;
          }
          bool value = *arguments;
          bool success = SetAutoStartHidden(value);
          result->Success(EncodableValue(success));
        }
        else {
          result->NotImplemented();
        }
      });
}
