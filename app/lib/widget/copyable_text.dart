import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/util/ui/snackbar.dart';

class CopyableText extends StatelessWidget {
  final TextSpan? prefix;
  final String name;
  final String? value;

  const CopyableText({
    this.prefix,
    required this.name,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      style: ButtonStyle(padding: WidgetStateProperty.all(EdgeInsets.zero)),
      onPressed: value == null
          ? null
          : () async {
              await Clipboard.setData(ClipboardData(text: value!));
              if (context.mounted) {
                context.showSnackBar('Copied $name to clipboard!');
              }
            },
      icon: Text.rich(
        textAlign: TextAlign.start,
        TextSpan(
          children: [
            if (prefix != null) prefix!,
            TextSpan(text: value ?? '-'),
          ],
        ),
      ),
    );
  }
}
