import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:routerino/routerino.dart';

class HistoryClearDialog extends StatelessWidget {
  const HistoryClearDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(t.dialogs.historyClearDialog.title),
      content: Text(t.dialogs.historyClearDialog.content),
      actions: [
        FilledButton(
          onPressed: () => context.pop(true),
          child: Text(t.general.delete),
        ),
        Button(
          onPressed: () => context.pop(),
          child: Text(t.general.cancel),
        ),
      ],
    );
  }
}
