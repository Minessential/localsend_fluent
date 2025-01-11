import 'package:fluent_ui/fluent_ui.dart';

class CustomTextBox extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final bool readOnly;
  final bool autofocus;
  final bool obscureText;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool? enabled;

  const CustomTextBox({
    super.key,
    this.controller,
    this.placeholder,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextBox(
      controller: controller,
      placeholder: placeholder,
      padding: EdgeInsets.fromLTRB(10, 8, 6, 8),
      prefix: prefix != null ? Padding(padding: const EdgeInsets.only(left: 10), child: prefix) : null,
      suffix: suffix != null ? Padding(padding: const EdgeInsets.only(right: 10), child: suffix) : null,
      keyboardType: keyboardType,
      textAlign: textAlign,
      readOnly: readOnly,
      autofocus: autofocus,
      obscureText: obscureText,
      maxLines: maxLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
    );
  }
}
