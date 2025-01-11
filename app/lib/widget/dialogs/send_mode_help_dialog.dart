import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:routerino/routerino.dart';

class SendModeHelpDialog extends StatelessWidget {
  const SendModeHelpDialog();

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(t.dialogs.sendModeHelp.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SendModeItem(
            mode: t.sendTab.sendModes.single,
            explanation: t.dialogs.sendModeHelp.single,
          ),
          const SizedBox(height: 10),
          _SendModeItem(
            mode: t.sendTab.sendModes.multiple,
            explanation: t.dialogs.sendModeHelp.multiple,
          ),
          const SizedBox(height: 10),
          _SendModeItem(
            mode: t.sendTab.sendModes.link,
            explanation: t.dialogs.sendModeHelp.link,
          ),
        ],
      ),
      actions: [
        Container(),
        FilledButton(
          onPressed: () => context.popUntil(HomePage),
          child: Text(t.general.close),
        ),
        Container(),
      ],
    );
  }
}

class _SendModeItem extends StatelessWidget {
  final String mode;
  final String explanation;
  const _SendModeItem({
    required this.mode,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(mode, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(explanation),
      ],
    );
  }
}
