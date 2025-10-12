import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class BaseDialogPage extends StatelessWidget {
  final Widget body;
  final String? title;
  const BaseDialogPage({this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      style: ContentDialogThemeData(padding: EdgeInsets.all(8)),
      constraints: const BoxConstraints(maxWidth: 700),
      content: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    title!,
                    style: FluentTheme.of(context).typography.title,
                  ),
                ),
              Flexible(child: body),
            ],
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Card(
              padding: EdgeInsets.zero,
              child: IconButton(
                style: ButtonStyle(padding: WidgetStateProperty.all(EdgeInsets.all(10))),
                icon: const Icon(FluentIcons.dismiss_20_regular, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
