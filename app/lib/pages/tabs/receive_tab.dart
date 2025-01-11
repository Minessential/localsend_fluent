import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/pages/home_page_controller.dart';
import 'package:localsend_app/pages/tabs/receive_tab_vm.dart';
import 'package:localsend_app/provider/animation_provider.dart';
import 'package:localsend_app/util/ip_helper.dart';
import 'package:localsend_app/widget/animations/initial_fade_transition.dart';
import 'package:localsend_app/widget/column_list_view.dart';
import 'package:localsend_app/widget/local_send_logo.dart';
import 'package:localsend_app/widget/rotating_widget.dart';
import 'package:refena_flutter/refena_flutter.dart';

enum _QuickSaveMode {
  off,
  favorites,
  on,
}

class ReceiveTab extends StatelessWidget {
  const ReceiveTab();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch(receiveTabVmProvider);

    return Stack(
      children: [
        Center(
          child: ColumnListView(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InitialFadeTransition(
                      duration: const Duration(milliseconds: 300),
                      delay: const Duration(milliseconds: 200),
                      child: Consumer(builder: (context, ref) {
                        final animations = ref.watch(animationProvider);
                        final activeTab = ref.watch(homePageControllerProvider.select((state) => state.currentTab));
                        return RotatingWidget(
                          duration: const Duration(seconds: 15),
                          spinning: vm.serverState != null && animations && activeTab == HomeTab.receive,
                          child: const LocalSendLogo(withText: false),
                        );
                      }),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(vm.serverState?.alias ?? vm.aliasSettings, style: const TextStyle(fontSize: 48)),
                    ),
                    InitialFadeTransition(
                      duration: const Duration(milliseconds: 300),
                      delay: const Duration(milliseconds: 500),
                      child: Text(
                        vm.serverState == null
                            ? t.general.offline
                            : vm.localIps.map((ip) => '#${ip.visualId}').toSet().join(' '),
                        style: const TextStyle(fontSize: 24),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: Column(
                    children: [
                      Text(t.general.quickSave),
                      const SizedBox(height: 10),
                      ComboBox<_QuickSaveMode>(
                        items: [
                          ComboBoxItem(
                            value: _QuickSaveMode.off,
                            child: Text(t.receiveTab.quickSave.off),
                          ),
                          ComboBoxItem(
                            value: _QuickSaveMode.favorites,
                            child: Text(t.receiveTab.quickSave.favorites),
                          ),
                          ComboBoxItem(
                            value: _QuickSaveMode.on,
                            child: Text(t.receiveTab.quickSave.on),
                          ),
                        ],
                        value: !vm.quickSaveSettings && !vm.quickSaveFromFavoritesSettings
                            ? _QuickSaveMode.off
                            : vm.quickSaveFromFavoritesSettings
                                ? _QuickSaveMode.favorites
                                : _QuickSaveMode.on,
                        onChanged: (selection) async {
                          if (selection == _QuickSaveMode.off) {
                            await vm.onSetQuickSave(context, false);
                            if (context.mounted) {
                              await vm.onSetQuickSaveFromFavorites(context, false);
                            }
                          } else if (selection == _QuickSaveMode.favorites) {
                            await vm.onSetQuickSave(context, false);
                            if (context.mounted) {
                              await vm.onSetQuickSaveFromFavorites(context, true);
                            }
                          } else if (selection == _QuickSaveMode.on) {
                            await vm.onSetQuickSaveFromFavorites(context, false);
                            if (context.mounted) {
                              await vm.onSetQuickSave(context, true);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 55),
            ],
          ),
        ),
        _InfoBox(vm),
        _CornerButtons(
          showAdvanced: vm.showAdvanced,
          showHistoryButton: vm.showHistoryButton,
          toggleAdvanced: vm.toggleAdvanced,
        ),
      ],
    );
  }
}

class _CornerButtons extends StatelessWidget {
  final bool showAdvanced;
  final bool showHistoryButton;
  final Future<void> Function() toggleAdvanced;

  const _CornerButtons({
    required this.showAdvanced,
    required this.showHistoryButton,
    required this.toggleAdvanced,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: IconButton(
          key: const ValueKey('info-btn'),
          onPressed: toggleAdvanced,
          icon: const Icon(FluentIcons.info, size: 20.0),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final ReceiveTabVm vm;

  const _InfoBox(this.vm);

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      crossFadeState: vm.showAdvanced ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
      firstChild: Container(),
      secondChild: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Table(
                columnWidths: const {
                  0: IntrinsicColumnWidth(),
                  1: IntrinsicColumnWidth(),
                  2: IntrinsicColumnWidth(),
                },
                children: [
                  TableRow(
                    children: [
                      Text(t.receiveTab.infoBox.alias),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(right: 30),
                        child: SelectableText(vm.serverState?.alias ?? '-'),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Text(t.receiveTab.infoBox.ip),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (vm.localIps.isEmpty) Text(t.general.unknown),
                          ...vm.localIps.map((ip) => SelectableText(ip)),
                        ],
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Text(t.receiveTab.infoBox.port),
                      const SizedBox(width: 10),
                      SelectableText(vm.serverState?.port.toString() ?? '-'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
