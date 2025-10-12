import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/dialogs/custom_bottom_sheet.dart';
import 'package:localsend_app/widget/fluent/custom_icon_label_button.dart';
import 'package:routerino/routerino.dart';

class CancelSessionDialog extends StatelessWidget {
  const CancelSessionDialog();

  static Future<bool> open(BuildContext context) async {
    final List<Widget> actions = [
      CustomIconLabelButton(
        ButtonType.filled,
        onPressed: () => context.pop(true),
        icon: const Icon(FluentIcons.dismiss_16_filled, size: 10),
        label: Text(t.general.cancel),
      ),
      Button(
        onPressed: () => context.pop(false),
        child: Text(t.general.continueStr),
      ),
    ];
    if (checkPlatformIsDesktop()) {
      final res = await showDialog(
        context: context,
        builder: (_) => ContentDialog(
          title: Text(t.dialogs.cancelSession.title),
          content: Text(t.dialogs.cancelSession.content),
          actions: actions,
        ),
      );
      return res == true;
    } else {
      final res = await context.pushBottomSheet(
        () => CustomBottomSheet(
          title: t.dialogs.cancelSession.title,
          description: t.dialogs.cancelSession.content,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: actions),
        ),
      );
      return res == true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
