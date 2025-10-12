import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/fluent/window_buttons.dart';
import 'package:localsend_app/widget/local_send_logo.dart';
import 'package:window_manager/window_manager.dart';

enum WindowLeadingType { back, appLogo, custom }

class BaseNormalPage extends StatelessWidget {
  final Widget? windowLeading;
  final WindowLeadingType windowLeadingType;
  final String? windowTitle;
  final String? headerTitle;
  final Widget? headerSuffix;

  final NavigationPane? pane;
  final Widget? body;
  const BaseNormalPage({
    super.key,
    this.windowTitle,
    this.windowLeading,
    this.windowLeadingType = WindowLeadingType.back,
    this.headerTitle,
    this.headerSuffix,
    this.pane,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: () {
          var title = Text(windowTitle ?? t.appNameF);

          if (checkPlatformIsDesktop()) {
            return DragToMoveArea(child: Container(alignment: Alignment.centerLeft, child: title));
          } else {
            return title;
          }
        }(),
        leading: () {
          final appLogo = Center(child: LocalSendLogo(withText: false, size: 25));
          return switch (windowLeadingType) {
            WindowLeadingType.back => IconButton(
                icon: Center(child: const Icon(FluentIcons.arrow_left_20_regular, size: 20)),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            WindowLeadingType.appLogo => checkPlatformIsDesktop() ? DragToMoveArea(child: appLogo) : appLogo,
            WindowLeadingType.custom => windowLeading,
          };
        }(),
        automaticallyImplyLeading: false,
        actions: checkPlatformIsDesktop() ? const WindowButtons() : null,
      ),
      pane: pane,
      content: body != null
          ? ScaffoldPage(
              header: headerTitle != null || headerSuffix != null
                  ? PageHeader(title: headerTitle != null ? Text(headerTitle!) : null, commandBar: headerSuffix)
                  : null,
              content: body!,
            )
          : null,
    );
  }
}
