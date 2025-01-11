import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/dialogs/custom_bottom_sheet.dart';
import 'package:routerino/routerino.dart';

class NoFilesDialog extends StatelessWidget {
  const NoFilesDialog({super.key});

  static Future<void> open(BuildContext context) async {
    if (checkPlatformIsDesktop()) {
      await showDialog(
        context: context,
        builder: (_) => ContentDialog(
          title: Text(t.dialogs.noFiles.title),
          content: Text(t.dialogs.noFiles.content),
          actions: [
            Container(),
            FilledButton(
              onPressed: () => context.popUntilRoot(),
              child: Text(t.general.close),
            ),
            Container(),
          ],
        ),
      );
    } else {
      await context.pushBottomSheet(() => NoFilesDialog());
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      title: t.dialogs.noFiles.title,
      description: t.dialogs.noFiles.content,
      child: Center(
        child: FilledButton(
          onPressed: () => context.popUntilRoot(),
          child: Text(t.general.close),
        ),
      ),
    );
  }
}
