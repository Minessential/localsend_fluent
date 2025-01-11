import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:routerino/routerino.dart';

class ErrorDialog extends StatelessWidget {
  final String error;

  const ErrorDialog({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(t.dialogs.errorDialog.title),
      content: SelectableText(error),
      actions: [
        Container(),
        FilledButton(
          onPressed: () => context.pop(),
          child: Text(t.general.close),
        ),
        Container(),
      ],
    );
  }
}
