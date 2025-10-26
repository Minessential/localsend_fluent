#ifndef RUNNER_WINRT_EXT_H_
#define RUNNER_WINRT_EXT_H_ 

#include <winrt/base.h>

bool IsRunningWithIdentity();
winrt::hstring GetSharedMedia();

bool IsStartupTaskEnabled();
bool EnableStartupTask();
bool DisableStartupTask();
bool IsAutoStartHidden();
bool SetAutoStartHidden(bool value);
bool IsLaunchedByStartupTask();

#endif  // RUNNER_WINRT_EXT_H_
