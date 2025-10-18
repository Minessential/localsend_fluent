import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:collection/collection.dart';
import 'package:common/model/device.dart';
import 'package:common/model/session_status.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/send_mode.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/pages/selected_files_page.dart';
import 'package:localsend_app/pages/tabs/send_tab_vm.dart';
import 'package:localsend_app/pages/troubleshoot_page.dart';
import 'package:localsend_app/provider/animation_provider.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/network/scan_facade.dart';
import 'package:localsend_app/provider/network/send_provider.dart';
import 'package:localsend_app/provider/progress_provider.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/favorites.dart';
import 'package:localsend_app/util/file_size_helper.dart';
import 'package:localsend_app/util/native/file_picker.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/big_button.dart';
import 'package:localsend_app/widget/dialogs/add_file_dialog.dart';
import 'package:localsend_app/widget/dialogs/send_mode_help_dialog.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';
import 'package:localsend_app/widget/fluent/base_pane_body.dart';
import 'package:localsend_app/widget/fluent/custom_icon_label_button.dart';
import 'package:localsend_app/widget/horizontal_clip_list_view.dart';
import 'package:localsend_app/widget/list_tile/device_list_tile.dart';
import 'package:localsend_app/widget/list_tile/device_placeholder_list_tile.dart';
import 'package:localsend_app/widget/opacity_slideshow.dart';
import 'package:localsend_app/widget/responsive_builder.dart';
import 'package:localsend_app/widget/rotating_widget.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

const _horizontalPadding = 15.0;
final _options = FilePickerOption.getOptionsForPlatform();

class SendTab extends StatelessWidget {
  const SendTab();

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return ViewModelBuilder(
      provider: (ref) => sendTabVmProvider,
      init: (context) async => context.global.dispatchAsync(SendTabInitAction(context)), // ignore: discarded_futures
      builder: (context, vm) {
        final sizingInformation = SizingInformation(MediaQuery.sizeOf(context).width);
        final buttonWidth = sizingInformation.isDesktop ? BigButton.desktopWidth : BigButton.mobileWidth;
        final ref = context.ref;
        return BasePaneBody.scrollable(
          title: HomeTab.send.label,
          children: [
            const SizedBox(height: 20),
            if (vm.selectedFiles.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
                child: Text(
                  t.sendTab.selection.title,
                  style: theme.typography.subtitle,
                ),
              ),
              HorizontalClipListView(
                outerHorizontalPadding: 15,
                outerVerticalPadding: 10,
                childPadding: 10,
                minChildWidth: buttonWidth,
                children: _options.map((option) {
                  return BigButton(
                    icon: option.icon,
                    label: option.label,
                    filled: false,
                    onTap: () async => ref.global.dispatchAsync(PickFileAction(
                      option: option,
                      context: context,
                    )),
                  );
                }).toList(),
              ),
            ] else ...[
              Card(
                margin: const EdgeInsets.only(bottom: 10, left: _horizontalPadding, right: _horizontalPadding),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 15, top: 5, bottom: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            t.sendTab.selection.title,
                            style: theme.typography.subtitle,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => ref.redux(selectedSendingFilesProvider).dispatch(ClearSelectionAction()),
                            icon: Padding(
                                padding: EdgeInsets.all(3),
                                child: Icon(FluentIcons.dismiss_16_filled, size: 16, color: theme.accentColor)),
                          ),
                          const SizedBox(width: 5),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(t.sendTab.selection.files(files: vm.selectedFiles.length)),
                      Text(t.sendTab.selection
                          .size(size: vm.selectedFiles.fold(0, (prev, curr) => prev + curr.size).asReadableFileSize)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: defaultThumbnailSize,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: vm.selectedFiles.length,
                          itemBuilder: (context, index) {
                            final file = vm.selectedFiles[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: SmartFileThumbnail.fromCrossFile(file),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Button(
                            onPressed: () async {
                              await showDialog(context: context, builder: (_) => const SelectedFilesPage());
                            },
                            child: Text(t.general.edit),
                          ),
                          const SizedBox(width: 15),
                          CustomIconLabelButton(
                            ButtonType.filled,
                            onPressed: () async {
                              if (_options.length == 1) {
                                // open directly
                                await ref.global.dispatchAsync(PickFileAction(
                                  option: _options.first,
                                  context: context,
                                ));
                                return;
                              }
                              await AddFileDialog.open(
                                context: context,
                                options: _options,
                              );
                            },
                            icon: const Icon(FluentIcons.add_16_filled),
                            label: Text(t.general.add),
                          ),
                          const SizedBox(width: 15),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Row(
              children: [
                const SizedBox(width: _horizontalPadding),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(t.sendTab.nearbyDevices, style: theme.typography.subtitle),
                  ),
                ),
                const SizedBox(width: 10),
                _ScanButton(ips: vm.localIps),
                Tooltip(
                  message: t.sendTab.manualSending,
                  child: IconButton(
                    onPressed: () async => vm.onTapAddress(context),
                    icon: const Icon(FluentIcons.target_edit_20_regular, size: 18),
                  ),
                ),
                Tooltip(
                  message: t.dialogs.favoriteDialog.title,
                  child: IconButton(
                    onPressed: () async => await vm.onTapFavorite(context),
                    icon: const Icon(FluentIcons.star_20_regular, size: 18),
                  ),
                ),
                _SendModeButton(onSelect: (mode) async => vm.onTapSendMode(context, mode)),
              ],
            ),
            if (vm.nearbyDevices.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 10, left: _horizontalPadding, right: _horizontalPadding),
                child: Opacity(opacity: 0.5, child: DevicePlaceholderListTile()),
              ),
            ...vm.nearbyDevices.map((device) {
              final favoriteEntry = vm.favoriteDevices.findDevice(device);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10, left: _horizontalPadding, right: _horizontalPadding),
                child: Hero(
                  tag: 'device-${device.ip}',
                  child: vm.sendMode == SendMode.multiple
                      ? _MultiSendDeviceListTile(
                          device: device,
                          isFavorite: favoriteEntry != null,
                          nameOverride: favoriteEntry?.alias,
                          vm: vm,
                        )
                      : DeviceListTile(
                          device: device,
                          isFavorite: favoriteEntry != null,
                          nameOverride: favoriteEntry?.alias,
                          onFavoriteTap: () async => await vm.onToggleFavorite(context, device),
                          onTap: () async => await vm.onTapDevice(context, device),
                        ),
                ),
              );
            }),
            const SizedBox(height: 10),
            Center(
              child: IconButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const TroubleshootPage(),
                  );
                },
                icon: Text(
                  t.troubleshootPage.title,
                  style: TextStyle(color: theme.accentColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
              child: Consumer(
                builder: (context, ref) {
                  final animations = ref.watch(animationProvider);
                  return OpacitySlideshow(
                    durationMillis: 6000,
                    running: animations,
                    children: [
                      Text(
                        t.sendTab.help,
                        style: TextStyle(color: theme.autoGrey),
                        textAlign: TextAlign.center,
                      ),
                      if (checkPlatformCanReceiveShareIntent())
                        Text(
                          t.sendTab.shareIntentInfo,
                          style: TextStyle(color: theme.autoGrey),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 50),
          ],
        );
      },
    );
  }
}

/// A button that opens a popup menu to select [T].
/// This is used for the scan button and the send mode button.
class _CircularPopupButton extends StatelessWidget {
  final String tooltip;
  final List<MenuFlyoutItemBase> items;
  final Widget child;

  const _CircularPopupButton({
    required this.tooltip,
    required this.items,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final itemsController = FlyoutController();

    return FlyoutTarget(
      controller: itemsController,
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          icon: child,
          onPressed: () async {
            await itemsController.showFlyout(
              autoModeConfiguration: FlyoutAutoConfiguration(
                preferredMode: FlyoutPlacementMode.bottomCenter,
              ),
              barrierDismissible: true,
              dismissOnPointerMoveAway: false,
              dismissWithEsc: true,
              // navigatorKey: rootNavigatorKey.currentState,
              builder: (context) => MenuFlyout(items: items),
            );
          },
        ),
      ),
    );
  }
}

/// The scan button that uses [_CircularPopupButton].
class _ScanButton extends StatelessWidget {
  final List<String> ips;

  const _ScanButton({required this.ips});

  @override
  Widget build(BuildContext context) {
    final (scanningFavorites, scanningIps) =
        context.ref.watch(nearbyDevicesProvider.select((s) => (s.runningFavoriteScan, s.runningIps)));
    final animations = context.ref.watch(animationProvider);

    final spinning = (scanningFavorites || scanningIps.isNotEmpty) && animations;
    final iconColor = !animations && scanningIps.isNotEmpty ? Colors.warningPrimaryColor : null;

    if (ips.length <= StartSmartScan.maxInterfaces) {
      return Tooltip(
        message: t.sendTab.scan,
        child: IconButton(
          onPressed: () async {
            context.redux(nearbyDevicesProvider).dispatch(ClearFoundDevicesAction());
            await context.global.dispatchAsync(StartSmartScan(forceLegacy: true));
          },
          icon: RotatingWidget(
            duration: const Duration(seconds: 2),
            spinning: spinning,
            reverse: false,
            child: Icon(FluentIcons.arrow_sync_20_regular, size: 18, color: iconColor),
          ),
        ),
      );
    }

    return _CircularPopupButton(
      tooltip: t.sendTab.scan,
      items: ips
          .map(
            (ip) => MenuFlyoutItem(
              leading: _RotatingSyncIcon(ip),
              text: Text(ip),
              onPressed: () async {
                context.redux(nearbyDevicesProvider).dispatch(ClearFoundDevicesAction());
                await context.global.dispatchAsync(StartLegacySubnetScan(subnets: [ip]));
              },
            ),
          )
          .toList(),
      child: RotatingWidget(
        duration: const Duration(seconds: 2),
        spinning: spinning,
        reverse: false,
        child: Icon(FluentIcons.arrow_sync_20_regular, size: 18, color: iconColor),
      ),
    );
  }
}

/// A separate widget, so it gets the latest data from provider.
class _RotatingSyncIcon extends StatelessWidget {
  final String ip;

  const _RotatingSyncIcon(this.ip);

  @override
  Widget build(BuildContext context) {
    final scanningIps = context.ref.watch(nearbyDevicesProvider.select((s) => s.runningIps));
    return RotatingWidget(
      duration: const Duration(seconds: 2),
      spinning: scanningIps.contains(ip),
      reverse: false,
      child: const Icon(FluentIcons.arrow_sync_20_regular, size: 18),
    );
  }
}

class _SendModeButton extends StatelessWidget {
  final void Function(SendMode mode) onSelect;

  const _SendModeButton({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref) {
      return _CircularPopupButton(
        tooltip: t.sendTab.sendMode,
        items: [
          ...SendMode.values.map(
            (e) => RadioMenuFlyoutItem<SendMode>(
              text: Text(e.humanName),
              value: e,
              groupValue: ref.watch(settingsProvider.select((s) => s.sendMode)),
              onChanged: (v) {
                context.popUntil(HomePage);
                onSelect(v);
              },
            ),
          ),
          const MenuFlyoutSeparator(),
          MenuFlyoutItem(
            leading: Icon(FluentIcons.question_circle_16_regular, size: 16),
            text: Text(t.sendTab.sendModeHelp),
            onPressed: () async {
              await showDialog(context: context, builder: (_) => const SendModeHelpDialog());
            },
          ),
        ],
        child: Icon(FluentIcons.settings_20_regular, size: 18),
      );
    });
  }
}

extension on SendMode {
  String get humanName {
    switch (this) {
      case SendMode.single:
        return t.sendTab.sendModes.single;
      case SendMode.multiple:
        return t.sendTab.sendModes.multiple;
      case SendMode.link:
        return t.sendTab.sendModes.link;
    }
  }
}

/// An advanced list tile which shows the progress of the file transfer.
class _MultiSendDeviceListTile extends StatelessWidget {
  final Device device;
  final bool isFavorite;
  final String? nameOverride;
  final SendTabVm vm;

  const _MultiSendDeviceListTile({
    required this.device,
    required this.isFavorite,
    required this.nameOverride,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final session = ref.watch(sendProvider).values.firstWhereOrNull((s) => s.target.ip == device.ip);
    final double? progress;
    if (session != null) {
      final files = session.files.values.where((f) => f.token != null);
      final progressNotifier = ref.watch(progressProvider);
      final currBytes = files.fold<int>(
          0,
          (prev, curr) =>
              prev +
              ((progressNotifier.getProgress(sessionId: session.sessionId, fileId: curr.file.id) * curr.file.size)
                  .round()));
      final totalBytes = files.fold<int>(0, (prev, curr) => prev + curr.file.size);
      progress = totalBytes == 0 ? 0 : currBytes / totalBytes;
    } else {
      progress = null;
    }
    return DeviceListTile(
      device: device,
      info: session?.status.humanString,
      progress: progress,
      isFavorite: isFavorite,
      nameOverride: nameOverride,
      onFavoriteTap: device.ip == null ? null : () async => await vm.onToggleFavorite(context, device),
      onTap: () async => await vm.onTapDeviceMultiSend(context, device),
    );
  }
}

extension on SessionStatus {
  String? get humanString {
    switch (this) {
      case SessionStatus.waiting:
        return t.sendPage.waiting;
      case SessionStatus.recipientBusy:
        return t.sendPage.busy;
      case SessionStatus.declined:
        return t.sendPage.rejected;
      case SessionStatus.tooManyAttempts:
        return t.sendPage.tooManyAttempts;
      case SessionStatus.sending:
        return null;
      case SessionStatus.finished:
        return t.general.finished;
      case SessionStatus.finishedWithErrors:
        return t.progressPage.total.title.finishedError;
      case SessionStatus.canceledBySender:
        return t.progressPage.total.title.canceledSender;
      case SessionStatus.canceledByReceiver:
        return t.progressPage.total.title.canceledReceiver;
    }
  }
}
