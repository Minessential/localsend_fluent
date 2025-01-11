import 'package:fluent_ui/fluent_ui.dart';

class CardInkWell extends StatelessWidget {
  final void Function()? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const CardInkWell({super.key, required this.child, this.onPressed, this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.zero,
      borderColor: theme.resources.controlStrokeColorDefault,
      child: onPressed != null
          ? IconButton(
              style: ButtonStyle(padding: WidgetStateProperty.all(padding ?? EdgeInsets.zero)),
              onPressed: onPressed,
              icon: child,
            )
          : Container(padding: padding, child: child),
    );
  }
}
