import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/widget/fluent/custom_text_box.dart';
import 'package:routerino/routerino.dart';

class MessageInputDialog extends StatefulWidget {
  final String? initialText;

  const MessageInputDialog({this.initialText});

  @override
  State<MessageInputDialog> createState() => _MessageInputDialogState();
}

class _MessageInputDialogState extends State<MessageInputDialog> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.initialText ?? '';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(t.dialogs.messageInput.title),
      content: IntrinsicHeight(
        child: CustomTextBox(
          controller: _textController,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          autofocus: true,
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => context.pop(_textController.text),
          child: Text(t.general.confirm),
        ),
        Button(
          onPressed: () => context.pop(),
          child: Text(t.general.cancel),
        ),
      ],
    );
  }
}
