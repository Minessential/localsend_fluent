import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:localsend_app/util/native/channel/macos_channel.dart';
import 'package:localsend_app/util/native/channel/windows_channel.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:win32_registry/win32_registry.dart';

const startHiddenFlag = '--hidden';

final _logger = Logger('AutoStartHelper');

Future<bool> enableAutoStart({required bool startHidden}) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
        String contents =
            '''
[Desktop Entry]
Type=Application
Name=${packageInfo.appName}
Comment=${packageInfo.appName} startup script
Exec=${Platform.resolvedExecutable}${startHidden ? ' $startHiddenFlag' : ''}
StartupNotify=false
Terminal=false
''';
        final file = File(_getLinuxFilePath(packageInfo.packageName));
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        file.writeAsStringSync(contents);
        return true;
      case TargetPlatform.macOS:
        await setLaunchAtLogin(true);
        await setLaunchAtLoginMinimized(startHidden);
        return true;
      case TargetPlatform.windows:
        if (await havePackageIdentity()) {
          await setRunAtStartupHidden(startHidden);
          return await enableRunAtStartup();
        } else {
          _getWindowsRegistryKey().createValue(
            RegistryValue(
              _windowsRegistryKeyValue,
              RegistryValueType.string,
              '"${Platform.resolvedExecutable}"${startHidden ? ' $startHiddenFlag' : ''}',
            ),
          );
        }
        return true;
      default:
        return false;
    }
  } catch (e) {
    _logger.warning('Could enable auto start', e);
    return false;
  }
}

Future<bool> disableAutoStart() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
        File(_getLinuxFilePath(packageInfo.packageName)).deleteSync();
        break;
      case TargetPlatform.macOS:
        await setLaunchAtLogin(false);
        break;
      case TargetPlatform.windows:
        if (await havePackageIdentity()) {
          return await disableRunAtStartup();
        } else {
          _getWindowsRegistryKey().deleteValue(_windowsRegistryKeyValue);
        }
        break;
      default:
        break;
    }
    return true;
  } catch (e) {
    _logger.warning('Could disable auto start', e);
    return false;
  }
}

Future<bool> isAutoStartEnabled() async {
  final packageInfo = await PackageInfo.fromPlatform();
  switch (defaultTargetPlatform) {
    case TargetPlatform.linux:
      return File(_getLinuxFilePath(packageInfo.packageName)).existsSync();
    case TargetPlatform.macOS:
      return await getLaunchAtLogin();
    case TargetPlatform.windows:
      if (await havePackageIdentity()) {
        return await isRunAtStartup();
      } else {
        return _getWindowsRegistryKey()
                .getValueAsString(_windowsRegistryKeyValue)
                ?.contains(Platform.resolvedExecutable) ??
            false;
      }
    default:
      return false;
  }
}

Future<bool> isAutoStartHidden() async {
  final packageInfo = await PackageInfo.fromPlatform();
  switch (defaultTargetPlatform) {
    case TargetPlatform.linux:
      final file = File(_getLinuxFilePath(packageInfo.packageName));
      if (!file.existsSync()) {
        return false;
      }
      return file.readAsStringSync().contains(startHiddenFlag);
    case TargetPlatform.macOS:
      return await getLaunchAtLoginMinimized();
    case TargetPlatform.windows:
      if (await havePackageIdentity()) {
        return await isRunAtStartup() && await isRunAtStartupHidden();
      } else {
        return _getWindowsRegistryKey().getValueAsString(_windowsRegistryKeyValue)?.contains(startHiddenFlag) ?? false;
      }
    default:
      return false;
  }
}

const _windowsRegistryKeyValue = 'LocalSend';

RegistryKey _getWindowsRegistryKey() {
  return Registry.openPath(
    RegistryHive.currentUser,
    path: r'Software\Microsoft\Windows\CurrentVersion\Run',
    desiredAccessRights: AccessRights.allAccess,
  );
}

String _getLinuxFilePath(String appName) {
  return '${Platform.environment['HOME']}/.config/autostart/$appName.desktop';
}
