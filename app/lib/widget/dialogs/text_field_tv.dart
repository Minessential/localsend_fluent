import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/provider/tv_provider.dart';
import 'package:localsend_app/widget/fluent/custom_text_box.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

/// A normal [TextFormField] on mobile and desktop.
/// A button which opens a dialog on Android TV
class TextFieldTv extends StatefulWidget {
  final String name;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onDelete;

  const TextFieldTv({
    required this.name,
    required this.controller,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<TextFieldTv> createState() => _TextFieldTvState();
}

class _TextFieldTvState extends State<TextFieldTv> with Refena {
  @override
  Widget build(BuildContext context) {
    final isTv = ref.watch(tvProvider);

    if (isTv) {
      return FilledButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) {
              return ContentDialog(
                title: Text(widget.name),
                content: CustomTextBox(
                  controller: widget.controller,
                  textAlign: TextAlign.center,
                  onChanged: widget.onChanged,
                  autofocus: true,
                  onSubmitted: (_) => context.pop(),
                ),
                actions: [
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: Text(t.general.confirm),
                  )
                ],
              );
            },
          );
        },
        child: Padding(
          padding: EdgeInsets.zero,
          child: Text(widget.controller.text, style: FluentTheme.of(context).typography.bodyStrong),
        ),
      );
    } else {
      return CustomTextBox(
        controller: widget.controller,
        textAlign: TextAlign.center,
        onChanged: widget.onChanged,
        suffix: widget.onDelete != null
            ? IconButton(
                icon: Icon(FluentIcons.clear),
                onPressed: () {
                  widget.onDelete?.call();
                },
              )
            : null,
      );
    }
  }
}
