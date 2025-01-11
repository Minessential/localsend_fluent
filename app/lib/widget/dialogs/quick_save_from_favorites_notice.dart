import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';

class QuickSaveFromFavoritesNotice {
  const QuickSaveFromFavoritesNotice();

  static Future<void> open(BuildContext context) async {
    await displayInfoBar(
      context,
      duration: Duration(seconds: 5),
      builder: (context, close) {
        return InfoBar(
          title: Text(t.dialogs.quickSaveFromFavoritesNotice.title),
          content: Text(t.dialogs.quickSaveFromFavoritesNotice.content.join('\n')),
          severity: InfoBarSeverity.warning,
          isLong: true,
        );
      },
    );
  }
}
