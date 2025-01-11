import 'package:common/model/device.dart';
import 'package:fluent_ui/fluent_ui.dart';

extension DeviceTypeExt on DeviceType {
  IconData get icon {
    return switch (this) {
      DeviceType.mobile => FluentIcons.cell_phone,
      DeviceType.desktop => FluentIcons.devices3,
      DeviceType.web => FluentIcons.globe,
      DeviceType.headless => FluentIcons.command_prompt,
      DeviceType.server => FluentIcons.server,
    };
  }
}
