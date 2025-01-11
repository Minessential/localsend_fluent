import 'package:fluent_ui/fluent_ui.dart';

enum ButtonType { filled, outlined, inkwell }

class CustomIconLabelButton extends StatelessWidget {
  final ButtonType type;
  final Widget icon;
  final Widget label;
  final void Function()? onPressed;
  const CustomIconLabelButton(this.type, {super.key, required this.icon, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final child = Row(mainAxisSize: MainAxisSize.min, children: [icon, const SizedBox(width: 8), label]);
    return switch (type) {
      ButtonType.filled => FilledButton(onPressed: onPressed, child: child),
      ButtonType.outlined => Button(onPressed: onPressed, child: child),
      ButtonType.inkwell => IconButton(onPressed: onPressed, icon: child),
    };
  }
}
