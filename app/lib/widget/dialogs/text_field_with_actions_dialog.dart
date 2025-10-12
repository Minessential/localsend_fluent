import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/widget/fluent/custom_text_box.dart';
import 'package:routerino/routerino.dart';

class TextFieldWithActionsDialog extends StatelessWidget {
  final String name;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<Widget> actions;
  const TextFieldWithActionsDialog(
      {super.key, required this.name, required this.controller, required this.onChanged, required this.actions});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 10,
            children: [
              Expanded(
                child: CustomTextBox(
                  controller: controller,
                  textAlign: TextAlign.center,
                  onChanged: onChanged,
                  autofocus: true,
                  onSubmitted: (_) => context.pop(),
                ),
              ),
              ...actions,
            ],
          ),
        ],
      ),
      actions: [
        Container(),
        FilledButton(
          onPressed: () => context.pop(),
          child: Text(t.general.confirm),
        ),
        Container(),
      ],
    );
  }
}
