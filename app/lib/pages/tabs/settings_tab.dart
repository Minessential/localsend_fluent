import 'dart:io';

import 'package:common/constants.dart';
import 'package:common/model/device.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/color_mode.dart';
import 'package:localsend_app/pages/about/about_page.dart';
import 'package:localsend_app/pages/changelog_page.dart';
import 'package:localsend_app/pages/donation/donation_page.dart';
import 'package:localsend_app/pages/settings/network_interfaces_page.dart';
import 'package:localsend_app/pages/tabs/settings_tab_controller.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/provider/version_provider.dart';
import 'package:localsend_app/util/alias_generator.dart';
import 'package:localsend_app/util/device_type_ext.dart';
import 'package:localsend_app/util/native/macos_channel.dart';
import 'package:localsend_app/util/native/pick_directory_path.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/dialogs/pin_dialog.dart';
import 'package:localsend_app/widget/dialogs/quick_save_from_favorites_notice.dart';
import 'package:localsend_app/widget/dialogs/quick_save_notice.dart';
import 'package:localsend_app/widget/dialogs/text_field_tv.dart';
import 'package:localsend_app/widget/dialogs/text_field_with_actions_dialog.dart';
import 'package:localsend_app/widget/local_send_logo.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab();

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: settingsTabControllerProvider,
      builder: (context, vm) {
        final ref = context.ref;
        final theme = FluentTheme.of(context);
        return ResponsiveListView(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 40),
          children: [
            _SettingsSection(
              title: t.settingsTab.general.title,
              children: [
                _SettingsEntry(
                  label: t.settingsTab.general.brightness,
                  child: ComboBox<ThemeMode>(
                    isExpanded: true,
                    value: vm.settings.theme,
                    items: vm.themeModes.map((theme) {
                      return ComboBoxItem(
                        value: theme,
                        child: Text(theme.humanName),
                      );
                    }).toList(),
                    onChanged: (theme) => vm.onChangeTheme(context, theme!),
                  ),
                ),
                _SettingsEntry(
                  label: t.settingsTab.general.color,
                  child: ComboBox<ColorMode>(
                    isExpanded: true,
                    value: vm.settings.colorMode,
                    items: vm.colorModes.map((colorMode) {
                      return ComboBoxItem(
                        value: colorMode,
                        child: Text(colorMode.humanName),
                      );
                    }).toList(),
                    onChanged: (c) async {
                      await ref.notifier(settingsProvider).setColorMode(c!);
                    },
                  ),
                ),
                _SettingsEntry(
                  label: t.settingsTab.general.language,
                  child: ComboBox<AppLocale>(
                    isExpanded: true,
                    value: vm.settings.locale,
                    placeholder: Text(t.settingsTab.general.languageOptions.system),
                    items: [null, ...AppLocale.values].map((locale) {
                      return ComboBoxItem(
                        value: locale,
                        child: Text(locale?.humanName ?? t.settingsTab.general.languageOptions.system),
                      );
                    }).toList(),
                    onChanged: vm.onChangeLanguage,
                  ),

                  // buttonLabel: vm.settings.locale?.humanName ?? t.settingsTab.general.languageOptions.system,
                  // onTap: () => vm.onTapLanguage(context),
                ),
                if (checkPlatformIsDesktop()) ...[
                  /// Wayland does window position handling, so there's no need for it. See [https://github.com/localsend/localsend/issues/544]
                  if (vm.advanced && checkPlatformIsNotWaylandDesktop())
                    _BooleanEntry(
                      label: defaultTargetPlatform == TargetPlatform.windows
                          ? t.settingsTab.general.saveWindowPlacementWindows
                          : t.settingsTab.general.saveWindowPlacement,
                      value: vm.settings.saveWindowPlacement,
                      onChanged: (b) async {
                        await ref.notifier(settingsProvider).setSaveWindowPlacement(b);
                      },
                    ),
                  if (checkPlatformHasTray()) ...[
                    _BooleanEntry(
                      label: t.settingsTab.general.minimizeToTray,
                      value: vm.settings.minimizeToTray,
                      onChanged: (b) async {
                        await ref.notifier(settingsProvider).setMinimizeToTray(b);
                      },
                    ),
                  ],
                  if (checkPlatformIsDesktop()) ...[
                    _BooleanEntry(
                      label: t.settingsTab.general.launchAtStartup,
                      value: vm.autoStart,
                      onChanged: (_) => vm.onToggleAutoStart(context),
                    ),
                    Visibility(
                      visible: vm.autoStart,
                      maintainAnimation: true,
                      maintainState: true,
                      child: AnimatedOpacity(
                        opacity: vm.autoStart ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: _BooleanEntry(
                          label: t.settingsTab.general.launchMinimized,
                          value: vm.autoStartLaunchHidden,
                          onChanged: (_) => vm.onToggleAutoStartLaunchHidden(context),
                        ),
                      ),
                    ),
                  ],
                  if (vm.advanced && checkPlatform([TargetPlatform.windows])) ...[
                    _BooleanEntry(
                      label: t.settingsTab.general.showInContextMenu,
                      value: vm.showInContextMenu,
                      onChanged: (_) => vm.onToggleShowInContextMenu(context),
                    ),
                  ],
                ],
                _BooleanEntry(
                  label: t.settingsTab.general.animations,
                  value: vm.settings.enableAnimations,
                  onChanged: (b) async {
                    await ref.notifier(settingsProvider).setEnableAnimations(b);
                  },
                ),
              ],
            ),
            _SettingsSection(
              title: t.settingsTab.receive.title,
              children: [
                _BooleanEntry(
                  label: t.settingsTab.receive.quickSave,
                  value: vm.settings.quickSave,
                  onChanged: (b) async {
                    final old = vm.settings.quickSave;
                    await ref.notifier(settingsProvider).setQuickSave(b);
                    if (!old && b && context.mounted) {
                      await QuickSaveNotice.open(context);
                    }
                  },
                ),
                _BooleanEntry(
                  label: t.settingsTab.receive.quickSaveFromFavorites,
                  value: vm.settings.quickSaveFromFavorites,
                  onChanged: (b) async {
                    final old = vm.settings.quickSaveFromFavorites;
                    await ref.notifier(settingsProvider).setQuickSaveFromFavorites(b);
                    if (!old && b && context.mounted) {
                      await QuickSaveFromFavoritesNotice.open(context);
                    }
                  },
                ),
                _BooleanEntry(
                  label: t.settingsTab.receive.requirePin,
                  value: vm.settings.receivePin != null,
                  onChanged: (b) async {
                    final currentPIN = vm.settings.receivePin;
                    if (currentPIN != null) {
                      await ref.notifier(settingsProvider).setReceivePin(null);
                    } else {
                      final String? newPin = await showDialog<String>(
                        context: context,
                        builder: (_) => const PinDialog(
                          obscureText: false,
                          generateRandom: false,
                        ),
                      );
                      if (newPin != null && newPin.isNotEmpty) {
                        await ref.notifier(settingsProvider).setReceivePin(newPin);
                      }
                    }
                  },
                ),
                if (checkPlatformWithFileSystem())
                  _TextIconButtonEntry(
                    label: t.settingsTab.receive.destination,
                    buttonLabel: vm.settings.destination ?? t.settingsTab.receive.downloads,
                    icon: vm.settings.destination == null ? FluentIcons.edit : FluentIcons.cancel,
                    onTap: () async {
                      if (vm.settings.destination != null) {
                        await ref.notifier(settingsProvider).setDestination(null);
                        if (defaultTargetPlatform == TargetPlatform.macOS) {
                          await removeExistingDestinationAccess();
                        }
                        return;
                      }
                      final directory = await pickDirectoryPath();
                      if (directory != null) {
                        if (defaultTargetPlatform == TargetPlatform.macOS) {
                          await persistDestinationFolderAccess(directory);
                        }
                        await ref.notifier(settingsProvider).setDestination(directory);
                      }
                    },
                  ),
                if (checkPlatformWithGallery())
                  _BooleanEntry(
                    label: t.settingsTab.receive.saveToGallery,
                    value: vm.settings.saveToGallery,
                    onChanged: (b) async {
                      await ref.notifier(settingsProvider).setSaveToGallery(b);
                    },
                  ),
                _BooleanEntry(
                  label: t.settingsTab.receive.autoFinish,
                  value: vm.settings.autoFinish,
                  onChanged: (b) async {
                    await ref.notifier(settingsProvider).setAutoFinish(b);
                  },
                ),
                _BooleanEntry(
                  label: t.settingsTab.receive.saveToHistory,
                  value: vm.settings.saveToHistory,
                  onChanged: (b) async {
                    await ref.notifier(settingsProvider).setSaveToHistory(b);
                  },
                ),
              ],
            ),
            if (vm.advanced)
              _SettingsSection(
                title: t.settingsTab.send.title,
                children: [
                  _BooleanEntry(
                    label: t.settingsTab.send.shareViaLinkAutoAccept,
                    value: vm.settings.shareViaLinkAutoAccept,
                    onChanged: (b) async {
                      await ref.notifier(settingsProvider).setShareViaLinkAutoAccept(b);
                    },
                  ),
                ],
              ),
            _SettingsSection(
              title: t.settingsTab.network.title,
              children: [
                AnimatedCrossFade(
                  crossFadeState: vm.serverState != null &&
                          (vm.serverState!.alias != vm.settings.alias ||
                              vm.serverState!.port != vm.settings.port ||
                              vm.serverState!.https != vm.settings.https)
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topLeft,
                  firstChild: Container(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Text(t.settingsTab.network.needRestart, style: TextStyle(color: Colors.warningPrimaryColor)),
                  ),
                ),
                _SettingsEntry(
                  label: '${t.settingsTab.network.server}${vm.serverState == null ? ' (${t.general.offline})' : ''}',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (vm.serverState == null)
                        Tooltip(
                          message: t.general.start,
                          child: IconButton(
                            onPressed: () => vm.onTapStartServer(context),
                            icon: Icon(FluentIcons.play),
                          ),
                        )
                      else
                        Tooltip(
                          message: t.general.restart,
                          child: IconButton(
                            onPressed: () => vm.onTapRestartServer(context),
                            icon: const Icon(FluentIcons.refresh),
                          ),
                        ),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: t.general.stop,
                        child: IconButton(
                          onPressed: vm.serverState == null ? null : vm.onTapStopServer,
                          icon: const Icon(FluentIcons.stop),
                        ),
                      ),
                    ],
                  ),
                ),
                _TextIconButtonEntry(
                  label: t.settingsTab.network.alias,
                  buttonLabel: vm.settings.alias,
                  icon: FluentIcons.edit,
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (context) {
                        return TextFieldWithActionsDialog(
                          name: t.settingsTab.network.alias,
                          controller: vm.aliasController,
                          onChanged: (s) async {
                            await ref.notifier(settingsProvider).setAlias(s);
                          },
                          actions: [
                            Tooltip(
                              message: t.settingsTab.network.generateRandomAlias,
                              child: IconButton(
                                onPressed: () async {
                                  // Generates random alias
                                  final newAlias = generateRandomAlias();

                                  // Update the TextField with the new alias
                                  vm.aliasController.text = newAlias;

                                  // Persist the new alias using the settingsProvider
                                  await ref.notifier(settingsProvider).setAlias(newAlias);
                                },
                                icon: const Icon(FluentIcons.auto_enhance_on),
                              ),
                            ),
                            Tooltip(
                              message: t.settingsTab.network.useSystemName,
                              child: IconButton(
                                onPressed: () async {
                                  // Uses dart.io to find the systems hostname
                                  final newAlias = Platform.localHostname;

                                  vm.aliasController.text = newAlias;
                                  await ref.notifier(settingsProvider).setAlias(newAlias);
                                },
                                icon: const Icon(FluentIcons.system),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                if (vm.advanced)
                  _SettingsEntry(
                    label: t.settingsTab.network.deviceType,
                    child: ComboBox<DeviceType>(
                      value: vm.deviceInfo.deviceType,
                      items: DeviceType.values.map((type) {
                        return ComboBoxItem(
                          value: type,
                          child: Icon(type.icon),
                        );
                      }).toList(),
                      onChanged: (type) async {
                        if (type != null) await ref.notifier(settingsProvider).setDeviceType(type);
                      },
                    ),
                  ),
                if (vm.advanced)
                  _SettingsEntry(
                    label: t.settingsTab.network.deviceModel,
                    child: TextFieldTv(
                      name: t.settingsTab.network.deviceModel,
                      controller: vm.deviceModelController,
                      onChanged: (s) async {
                        await ref.notifier(settingsProvider).setDeviceModel(s);
                      },
                    ),
                  ),
                if (vm.advanced)
                  _SettingsEntry(
                    label: t.settingsTab.network.port,
                    subtitle: vm.settings.port != defaultPort
                        ? t.settingsTab.network.portWarning(defaultPort: defaultPort)
                        : null,
                    child: TextFieldTv(
                      name: t.settingsTab.network.port,
                      controller: vm.portController,
                      onChanged: (s) async {
                        final port = int.tryParse(s);
                        if (port != null) {
                          await ref.notifier(settingsProvider).setPort(port);
                        }
                      },
                    ),
                  ),
                if (vm.advanced)
                  _TextIconButtonEntry(
                    label: t.settingsTab.network.network,
                    buttonLabel: switch (vm.settings.networkWhitelist != null || vm.settings.networkBlacklist != null) {
                      true => t.settingsTab.network.networkOptions.filtered,
                      false => t.settingsTab.network.networkOptions.all,
                    },
                    onTap: () async {
                      await context.push(() => const NetworkInterfacesPage());
                    },
                    icon: FluentIcons.edit,
                  ),
                if (vm.advanced)
                  _SettingsEntry(
                    label: t.settingsTab.network.discoveryTimeout,
                    child: TextFieldTv(
                      name: t.settingsTab.network.discoveryTimeout,
                      controller: vm.timeoutController,
                      onChanged: (s) async {
                        final timeout = int.tryParse(s);
                        if (timeout != null) {
                          await ref.notifier(settingsProvider).setDiscoveryTimeout(timeout);
                        }
                      },
                    ),
                  ),
                if (vm.advanced)
                  _BooleanEntry(
                    label: t.settingsTab.network.encryption,
                    value: vm.settings.https,
                    onChanged: (b) async {
                      final old = vm.settings.https;
                      await ref.notifier(settingsProvider).setHttps(b);
                      if (old && !b && context.mounted) {
                        await displayInfoBar(context, builder: (context, close) {
                          return InfoBar(
                            severity: InfoBarSeverity.warning,
                            isLong: true,
                            title: Text(t.dialogs.encryptionDisabledNotice.title),
                            content: Text(t.dialogs.encryptionDisabledNotice.content),
                          );
                        });
                      }
                    },
                  ),
                if (vm.advanced)
                  _SettingsEntry(
                    label: t.settingsTab.network.multicastGroup,
                    subtitle: vm.settings.multicastGroup != defaultMulticastGroup
                        ? t.settingsTab.network.multicastGroupWarning(defaultMulticast: defaultMulticastGroup)
                        : null,
                    child: TextFieldTv(
                      name: t.settingsTab.network.multicastGroup,
                      controller: vm.multicastController,
                      onChanged: (s) async {
                        await ref.notifier(settingsProvider).setMulticastGroup(s);
                      },
                    ),
                  ),
              ],
            ),
            _SettingsSection(
              title: t.settingsTab.other.title,
              padding: const EdgeInsets.only(bottom: 0),
              children: [
                _BooleanEntry(
                  label: t.settingsTab.advancedSettings,
                  value: vm.advanced,
                  onChanged: (b) async {
                    vm.onTapAdvanced(b == true);
                    await ref.notifier(settingsProvider).setAdvancedSettingsEnabled(b == true);
                  },
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: Expander(
                    headerBackgroundColor: WidgetStatePropertyAll(theme.cardColor),
                    headerShape: (open) {
                      return RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: theme.resources.controlStrokeColorDefault),
                      );
                    },
                    leading: SizedBox(width: 30, height: 30, child: LocalSendLogo(withText: false)),
                    header: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.appName),
                          Text(
                            '© ${DateTime.now().year} Tien Do Nam',
                            textAlign: TextAlign.center,
                            style: theme.typography.caption,
                          ),
                        ],
                      ),
                    ),
                    trailing: ref.watch(versionProvider).maybeWhen(
                          data: (version) => Text(
                            version,
                            textAlign: TextAlign.center,
                          ),
                          orElse: () => null,
                        ),
                    contentPadding: EdgeInsets.zero,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ButtonEntry(
                          label: t.aboutPage.title,
                          icon: FluentIcons.chevron_right_med,
                          toolTip: t.general.open,
                          onTap: () async {
                            await showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const AboutPage(),
                            );
                          },
                        ),
                        _ButtonEntry(
                          label: t.settingsTab.other.support,
                          icon: FluentIcons.chevron_right_med,
                          toolTip: t.settingsTab.other.donate,
                          onTap: () async {
                            await showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const DonationPage(),
                            );
                          },
                        ),
                        _ButtonEntry(
                          label: t.settingsTab.other.privacyPolicy,
                          icon: FluentIcons.open_in_new_window,
                          toolTip: t.general.open,
                          onTap: () async {
                            await launchUrl(
                              Uri.parse('https://localsend.org/privacy'),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                        if (checkPlatform([TargetPlatform.iOS, TargetPlatform.macOS]))
                          _ButtonEntry(
                            label: t.settingsTab.other.termsOfUse,
                            icon: FluentIcons.open_in_new_window,
                            toolTip: t.general.open,
                            onTap: () async {
                              await launchUrl(
                                Uri.parse('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                          ),
                        const SizedBox(height: 20),
                        const LocalSendLogo(withText: true),
                        const SizedBox(height: 5),
                        ref.watch(versionProvider).maybeWhen(
                              data: (version) => Text(
                                'Version: $version',
                                textAlign: TextAlign.center,
                              ),
                              orElse: () => Container(),
                            ),
                        Text(
                          '© ${DateTime.now().year} Tien Do Nam',
                          textAlign: TextAlign.center,
                        ),
                        Center(
                          child: IconButton(
                            onPressed: () async {
                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const ChangelogPage(),
                              );
                            },
                            icon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(FluentIcons.history),
                                const SizedBox(width: 5),
                                Text(t.changelogPage.title),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SettingsEntry extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget child;

  const _SettingsEntry({required this.label, required this.child, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      borderColor: theme.resources.controlStrokeColorDefault,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.typography.bodyStrong?.copyWith(fontWeight: FontWeight.w500)),
                AnimatedCrossFade(
                  crossFadeState: subtitle != null ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topLeft,
                  firstChild: Container(),
                  secondChild: Text(
                    subtitle ?? '',
                    style: theme.typography.caption?.copyWith(
                      color: theme.brightness == Brightness.light
                          ? Colors.warningPrimaryColor
                          : Colors.warningSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(constraints: BoxConstraints(maxWidth: 200), child: child),
        ],
      ),
    );
  }
}

/// A specialized version of [_SettingsEntry].
class _BooleanEntry extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BooleanEntry({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsEntry(
      label: label,
      child: ToggleSwitch(
        onChanged: onChanged,
        checked: value,
        leadingContent: true,
        content: Text(value ? t.settingsTab.toggleSwitch.on : t.settingsTab.toggleSwitch.off),
      ),
    );
  }
}

/// A specialized version of [_SettingsEntry].
class _ButtonEntry extends StatelessWidget {
  final String label;
  final String toolTip;
  final IconData icon;
  final void Function() onTap;

  const _ButtonEntry({
    required this.label,
    required this.toolTip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HyperlinkButton(
      style: ButtonStyle(padding: WidgetStateProperty.all(EdgeInsets.zero)),
      onPressed: onTap,
      child: _SettingsEntry(
        label: label,
        child: Tooltip(
          message: toolTip,
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Icon(
              icon,
              size: FluentTheme.of(context).typography.body?.fontSize,
              color: FluentTheme.of(context).typography.body?.color,
            ),
          ),
        ),
      ),
    );
  }
}

/// A specialized version of [_SettingsEntry].
class _TextIconButtonEntry extends StatelessWidget {
  final String label;
  final String buttonLabel;
  final IconData icon;
  final void Function() onTap;

  const _TextIconButtonEntry({
    required this.label,
    required this.buttonLabel,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return _SettingsEntry(
      label: label,
      child: HyperlinkButton(
        style: ButtonStyle(padding: WidgetStateProperty.all(EdgeInsets.zero)),
        onPressed: onTap,
        child: Card(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Card(
                  backgroundColor: theme.accentColor,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    buttonLabel,
                    style: TextStyle(
                      color: theme.brightness == Brightness.light ? Colors.white : const Color(0xE4000000),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: theme.typography.body?.color, size: theme.typography.body?.fontSize),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsets padding;

  const _SettingsSection({
    required this.title,
    required this.children,
    this.padding = const EdgeInsets.only(bottom: 15),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

extension on ThemeMode {
  String get humanName {
    switch (this) {
      case ThemeMode.system:
        return t.settingsTab.general.brightnessOptions.system;
      case ThemeMode.light:
        return t.settingsTab.general.brightnessOptions.light;
      case ThemeMode.dark:
        return t.settingsTab.general.brightnessOptions.dark;
    }
  }
}

extension on ColorMode {
  String get humanName {
    return switch (this) {
      ColorMode.system => t.settingsTab.general.colorOptions.system,
      ColorMode.localsend => t.appName,
      ColorMode.yellow => t.settingsTab.general.colorOptions.yellow,
      ColorMode.orange => t.settingsTab.general.colorOptions.orange,
      ColorMode.red => t.settingsTab.general.colorOptions.red,
      ColorMode.magenta => t.settingsTab.general.colorOptions.magenta,
      ColorMode.purple => t.settingsTab.general.colorOptions.purple,
      ColorMode.blue => t.settingsTab.general.colorOptions.blue,
      ColorMode.green => t.settingsTab.general.colorOptions.green,
    };
  }
}

extension AppLocaleExt on AppLocale {
  String get humanName {
    return LocaleSettings.instance.translationMap[this]?.locale ?? 'Loading';
  }
}
