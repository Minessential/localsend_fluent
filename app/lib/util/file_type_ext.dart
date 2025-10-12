import 'package:common/model/file_type.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

extension FileTypeExt on FileType {
  IconData get icon {
    return switch (this) {
      FileType.image => FluentIcons.image_24_regular,
      FileType.video => FluentIcons.video_24_regular,
      FileType.pdf => FluentIcons.document_pdf_24_regular,
      FileType.text => FluentIcons.document_text_24_regular,
      FileType.apk => FluentIcons.apps_24_regular,
      FileType.other => FluentIcons.document_24_regular,
    };
  }
}
