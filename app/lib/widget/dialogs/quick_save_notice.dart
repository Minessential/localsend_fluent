import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';

class QuickSaveNotice {
  const QuickSaveNotice();

  static Future<void> open(BuildContext context) async {
    await displayInfoBar(
      context,
      duration: Duration(seconds: 4),
      builder: (context, close) {
        return InfoBar(
          title: Text(t.dialogs.quickSaveNotice.title),
          content: Text(t.dialogs.quickSaveNotice.content),
          severity: InfoBarSeverity.warning,
          isLong: true,
        );
      },
    );
  }
}
