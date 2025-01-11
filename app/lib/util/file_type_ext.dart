import 'package:common/model/file_type.dart';
import 'package:fluent_ui/fluent_ui.dart';

extension FileTypeExt on FileType {
  IconData get icon {
    return switch (this) {
      FileType.image => FluentIcons.photo2,
      FileType.video => FluentIcons.media,
      FileType.pdf => FluentIcons.pdf,
      FileType.text => FluentIcons.text_document,
      FileType.apk => FluentIcons.app_icon_default,
      FileType.other => FluentIcons.file_template,
    };
  }
}
