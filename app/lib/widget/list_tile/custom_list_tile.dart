import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/widget/fluent/card_ink_well.dart';

class CustomListTile extends StatelessWidget {
  final Widget? icon;
  final Widget title;
  final Widget subTitle;
  final Widget? trailing;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const CustomListTile({
    this.icon,
    required this.title,
    required this.subTitle,
    this.trailing,
    this.padding = const EdgeInsets.all(15),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CardInkWell(
      padding: padding,
      onPressed: onTap,
      child: Row(
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 15),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  child: title,
                ),
                const SizedBox(height: 5),
                subTitle,
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
