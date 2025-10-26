#ifndef RUNNER_WINDOWS_CHANNEL_H_
#define RUNNER_WINDOWS_CHANNEL_H_

#include <flutter/flutter_engine.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>

// Sets up the Windows method channel for native Windows functionality
void SetupWindowsChannel(flutter::FlutterEngine* engine);

#endif  // RUNNER_WINDOWS_CHANNEL_H_
