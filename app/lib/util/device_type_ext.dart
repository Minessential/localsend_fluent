import 'package:common/model/device.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

extension DeviceTypeExt on DeviceType {
  IconData get icon {
    return switch (this) {
      DeviceType.mobile => FluentIcons.phone_20_regular,
      DeviceType.desktop => FluentIcons.desktop_20_regular,
      DeviceType.web => FluentIcons.globe_20_regular,
      DeviceType.headless => FluentIcons.window_console_20_regular,
      DeviceType.server => FluentIcons.server_20_regular,
    };
  }
}
