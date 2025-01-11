import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/dialogs/custom_bottom_sheet.dart';
import 'package:routerino/routerino.dart';

class EncryptionDisabledNotice extends StatelessWidget {
  const EncryptionDisabledNotice({super.key});

  static Future<void> open(BuildContext context) async {
    if (checkPlatformIsDesktop()) {
      await showDialog(
        context: context,
        builder: (_) => ContentDialog(
          title: Text(t.dialogs.encryptionDisabledNotice.title),
          content: Text(t.dialogs.encryptionDisabledNotice.content),
          actions: [
            Container(),
            FilledButton(
              onPressed: () => context.pop(),
              child: Text(t.general.close),
            ),
            Container(),
          ],
        ),
      );
    } else {
      await context.pushBottomSheet(() => const EncryptionDisabledNotice());
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      title: t.dialogs.encryptionDisabledNotice.title,
      description: t.dialogs.encryptionDisabledNotice.content,
      child: Center(
        child: FilledButton(
          onPressed: () => context.popUntilRoot(),
          child: Text(t.general.close),
        ),
      ),
    );
  }
}
