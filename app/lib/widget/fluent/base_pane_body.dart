import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/widget/fluent/universal_scroll_view.dart';

class BasePaneBody extends StatelessWidget {
  final String? title;
  final List<Widget>? titleActions;
  final Widget? body;

  const BasePaneBody({super.key, this.title, this.titleActions, this.body});

  BasePaneBody.scrollable({
    super.key,
    this.title,
    this.titleActions,
    ScrollController? scrollController,
    final double spacing = 0,
    required List<Widget> children,
  }) : body = UniversalScrollView(controller: scrollController, spacing: spacing, children: children);

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return ScaffoldPage(
      header: title != null || titleActions != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Row(
                children: [
                  if (title != null) Expanded(child: Text(title!, style: theme.typography.title)),
                  if (titleActions != null) ...titleActions!,
                ],
              ),
            )
          : null,
      content: body != null ? body! : const SizedBox.shrink(),
    );
  }
}
