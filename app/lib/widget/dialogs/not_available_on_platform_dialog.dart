import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/util/platform_strings.dart';
import 'package:routerino/routerino.dart';

class NotAvailableOnPlatformDialog extends StatelessWidget {
  final List<TargetPlatform> platforms;

  const NotAvailableOnPlatformDialog({required this.platforms});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(t.dialogs.notAvailableOnPlatform.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.dialogs.notAvailableOnPlatform.content),
          const SizedBox(height: 10),
          ...platforms.map((p) {
            return Text('- ${p.humanName}');
          }),
        ],
      ),
      actions: [
        Container(),
        FilledButton(
          onPressed: () => context.pop(),
          child: Text(t.general.close),
        ),
        Container(),
      ],
    );
  }
}
