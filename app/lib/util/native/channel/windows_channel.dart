import 'dart:async';

import 'package:flutter/services.dart';

const _methodChannel = MethodChannel('windows-delegate-channel');

///IsRunningWithIdentity
Future<bool> havePackageIdentity() async {
  return await _methodChannel.invokeMethod('havePackageIdentity');
}

///IsStartupTaskEnabled
Future<bool> isRunAtStartup() async {
  return await _methodChannel.invokeMethod('isRunAtStartup');
}

///EnableStartupTask
Future<bool> enableRunAtStartup() async {
  return await _methodChannel.invokeMethod('enableRunAtStartup');
}

///DisableStartupTask
Future<bool> disableRunAtStartup() async {
  return await _methodChannel.invokeMethod('disableRunAtStartup');
}

///IsAutoStartHidden
Future<bool> isRunAtStartupHidden() async {
  return await _methodChannel.invokeMethod('isRunAtStartupHidden');
}

///SetAutoStartHidden
Future<bool> setRunAtStartupHidden(bool value) async {
  return await _methodChannel.invokeMethod('setRunAtStartupHidden', value);
}
