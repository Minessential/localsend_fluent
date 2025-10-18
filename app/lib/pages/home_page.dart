import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:localsend_app/config/init.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/base/base_normal_page.dart';
import 'package:localsend_app/pages/home_page_controller.dart';
import 'package:localsend_app/pages/receive_history_page.dart';
import 'package:localsend_app/pages/tabs/receive_tab.dart';
import 'package:localsend_app/pages/tabs/send_tab.dart';
import 'package:localsend_app/pages/tabs/settings_tab.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/util/native/cross_file_converters.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/responsive_builder.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

enum HomeTab {
  receive(FluentIcons.live_24_regular),
  send(FluentIcons.send_24_regular),
  settings(FluentIcons.settings_24_regular),
  history(FluentIcons.history_24_regular);

  const HomeTab(this.icon);

  final IconData icon;

  String get label {
    switch (this) {
      case HomeTab.receive:
        return t.receiveTab.title;
      case HomeTab.send:
        return t.sendTab.title;
      case HomeTab.settings:
        return t.settingsTab.title;
      case HomeTab.history:
        return t.receiveHistoryPage.title;
    }
  }
}

class HomePage extends StatefulWidget {
  final HomeTab initialTab;

  /// It is important for the initializing step
  /// because the first init clears the cache
  final bool appStart;

  const HomePage({
    required this.initialTab,
    required this.appStart,
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with Refena {
  bool _dragAndDropIndicator = false;

  List<NavigationPaneItem> items = [
    PaneItem(
      icon: Icon(HomeTab.receive.icon),
      title: Text(HomeTab.receive.label),
      body: ScaffoldPage(content: ReceiveTab()),
    ),
    PaneItem(
      icon: Icon(HomeTab.send.icon),
      title: Text(HomeTab.send.label),
      body: SendTab(),
    ),
    PaneItem(
      icon: Icon(HomeTab.history.icon),
      title: Text(HomeTab.history.label),
      body: ReceiveHistoryPage(),
    ),
  ];

  @override
  void initState() {
    super.initState();

    ensureRef((ref) async {
      ref.redux(homePageControllerProvider).dispatch(ChangeTabAction(widget.initialTab));
      await postInit(context, ref, widget.appStart);
    });
  }

  @override
  Widget build(BuildContext context) {
    Translations.of(context); // rebuild on locale change
    Routerino.transition = RouterinoTransition.fade();

    final vm = context.watch(homePageControllerProvider);

    return DropTarget(
      onDragEntered: (_) {
        setState(() {
          _dragAndDropIndicator = true;
        });
      },
      onDragExited: (_) {
        setState(() {
          _dragAndDropIndicator = false;
        });
      },
      onDragDone: (event) async {
        if (event.files.length == 1 && Directory(event.files.first.path).existsSync()) {
          // user dropped a directory
          await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddDirectoryAction(event.files.first.path));
        } else {
          // user dropped one or more files
          await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddFilesAction(
                files: event.files,
                converter: CrossFileConverters.convertXFile,
              ));
        }
        if (!context.mounted) return;
        context.popUntil(HomePage);
        vm.changeTab(HomeTab.send);
      },
      child: ResponsiveBuilder(
        builder: (sizingInformation) {
          return Stack(
            children: [
              BaseNormalPage(
                windowLeadingType: WindowLeadingType.appLogo,
                pane: NavigationPane(
                  selected: vm.currentTab.index,
                  onItemPressed: (index) {
                    // Do anything you want to do, such as:
                    // print(NavigationView.of(context).displayMode);
                    // if (index == topIndex) {
                    //   if (displayMode == PaneDisplayMode.open) {
                    //     setState(
                    //         () => this.displayMode = PaneDisplayMode.compact);
                    //   } else if (displayMode == PaneDisplayMode.compact) {
                    //     setState(() => this.displayMode = PaneDisplayMode.open);
                    //   }
                    // }
                  },
                  onChanged: (index) => vm.changeTab(HomeTab.values[index]),
                  displayMode: displayMode(sizingInformation),
                  items: items,
                  footerItems: [
                    PaneItem(
                      icon: Icon(HomeTab.settings.icon),
                      title: Text(HomeTab.settings.label),
                      body: SettingsTab(),
                    ),
                  ],
                ),
              ),
              if (_dragAndDropIndicator)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FluentTheme.of(context).resources.solidBackgroundFillColorBase.withOpacity(0.9),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(FluentIcons.share_48_regular, size: 128),
                      const SizedBox(height: 30),
                      Text(t.sendTab.placeItems, style: FluentTheme.of(context).typography.titleLarge),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  PaneDisplayMode displayMode(SizingInformation sizingInformation) {
    if (sizingInformation.isMobile) {
      return PaneDisplayMode.top;
    } else {
      return PaneDisplayMode.auto;
    }
  }
}
