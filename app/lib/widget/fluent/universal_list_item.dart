import 'package:fluent_ui/fluent_ui.dart';

class UniversalListItem extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? trailing;

  final ShapeBorder? shape;
  final WidgetStateProperty<Color>? backgroundColor;
  final VoidCallback? onPressed;

  const UniversalListItem({
    super.key,
    this.leading,
    required this.title,
    this.trailing,
    this.shape,
    this.backgroundColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return HoverButton(
      onPressed: onPressed,
      hitTestBehavior: HitTestBehavior.deferToChild,
      builder: (context, states) {
        return FocusBorder(
          focused: states.isFocused,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            constraints: const BoxConstraints(minHeight: 42),
            decoration: ShapeDecoration(
              color: backgroundColor?.resolve(states) ?? theme.resources.cardBackgroundFillColorDefault,
              shape: shape ??
                  RoundedRectangleBorder(
                    side: BorderSide(color: theme.resources.cardStrokeColorDefault),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6.0), bottom: Radius.circular(6.0)),
                  ),
            ),
            padding: const EdgeInsetsDirectional.only(start: 16.0, end: 20.0),
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              children: [
                if (leading != null) Padding(padding: const EdgeInsetsDirectional.only(end: 10.0), child: leading!),
                Expanded(child: title),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        );
      },
    );
  }
}
