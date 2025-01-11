import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/dialogs/custom_bottom_sheet.dart';
import 'package:routerino/routerino.dart';

class CannotOpenFileDialog extends StatelessWidget {
  final String path;

  const CannotOpenFileDialog({required this.path, super.key});

  static Future<void> open(BuildContext context, String path, void Function()? onDeleteTap) async {
    if (checkPlatformIsDesktop()) {
      await showDialog(
        context: context,
        builder: (_) => ContentDialog(
          title: Text(t.dialogs.cannotOpenFile.title),
          content: Text(t.dialogs.cannotOpenFile.content(file: path)),
          actions: [
            if (onDeleteTap != null) ...[
              FilledButton(
                onPressed: () {
                  onDeleteTap();
                  context.pop();
                },
                child: Text(t.receiveHistoryPage.entryActions.deleteFromHistory),
              ),
              Button(onPressed: () => context.pop(), child: Text(t.general.close)),
            ] else ...[
              Container(),
              FilledButton(onPressed: () => context.pop(), child: Text(t.general.close)),
              Container(),
            ]
          ],
        ),
      );
    } else {
      await context.pushBottomSheet(() => CannotOpenFileDialog(path: path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      title: t.dialogs.cannotOpenFile.title,
      description: t.dialogs.cannotOpenFile.content(file: path),
      child: Center(
        child: FilledButton(
          onPressed: () => context.popUntilRoot(),
          child: Text(t.general.close),
        ),
      ),
    );
  }
}
