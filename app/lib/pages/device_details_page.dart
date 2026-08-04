import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:intl/intl.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/favorite_device.dart';
import 'package:localsend_app/pages/base/base_normal_page.dart';
import 'package:localsend_app/pages/verify_page.dart';
import 'package:localsend_app/provider/favorites_provider.dart';
import 'package:localsend_app/util/favorites.dart';
import 'package:localsend_app/widget/dialogs/favorite_delete_dialog.dart';
import 'package:localsend_app/widget/dialogs/favorite_edit_dialog.dart';
import 'package:localsend_app/widget/fluent/custom_icon_label_button.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:localsend_isolates/isolate.dart';
import 'package:localsend_isolates/model/device.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

final _timeFormat = DateFormat.jm(LocaleSettings.currentLocale.languageTag);

/// Shows the general information of a discovered device and
/// the log of its retained discovery confirmations.
class DeviceDetailsPage extends StatefulWidget {
  final Device device;

  const DeviceDetailsPage({required this.device});

  @override
  State<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> with Refena {
  List<DeviceLog> _logs = const [];

  @override
  void initState() {
    super.initState();

    ensureRef((ref) async {
      final logs = await ref
          .redux(parentIsolateProvider)
          .dispatchAsyncTakeResult(IsolateDiscoveryDeviceLogsAction(fingerprint: widget.device.fingerprint));
      if (mounted) {
        setState(() => _logs = logs);
      }
    });
  }

  Future<void> _toggleFavorite(FavoriteDevice? favoriteEntry) async {
    if (favoriteEntry != null) {
      final result = await showDialog<bool>(
        context: context,
        builder: (_) => FavoriteDeleteDialog(favoriteEntry),
      );
      if (result == true) {
        await ref.redux(favoritesProvider).dispatchAsync(RemoveFavoriteAction(deviceFingerprint: widget.device.fingerprint));
      }
    } else {
      await showDialog(
        context: context,
        builder: (_) => FavoriteEditDialog(prefilledDevice: widget.device),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final favoriteEntry = ref.watch(favoritesProvider).findDevice(device);
    final theme = FluentTheme.of(context);
    final infoEntries = {
      t.deviceDetailsPage.info.name: device.alias,
      if (device.ip != null) t.deviceDetailsPage.info.address: '${device.ip}:${device.port}',
    }.entries.toList();

    return BaseNormalPage(
      windowTitle: t.deviceDetailsPage.title,
      headerTitle: t.deviceDetailsPage.title,
      body: ResponsiveListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        tabletPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              CustomIconLabelButton(
                ButtonType.outlined,
                icon: Icon(favoriteEntry != null ? FluentIcons.star_20_filled : FluentIcons.star_20_regular, size: 18),
                label: Text(t.deviceDetailsPage.favorite),
                onPressed: () async => await _toggleFavorite(favoriteEntry),
              ),
              CustomIconLabelButton(
                ButtonType.outlined,
                icon: const Icon(FluentIcons.shield_checkmark_20_regular, size: 18),
                label: Text(t.deviceDetailsPage.verify),
                onPressed: () async => await context.push(() => VerifyPage(device: device)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < infoEntries.length; index++) ...[
                  _InfoRow(label: infoEntries[index].key, value: infoEntries[index].value),
                  if (index < infoEntries.length - 1) const Divider(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(t.deviceDetailsPage.logs.title, style: theme.typography.subtitle),
          const SizedBox(height: 12),
          if (_logs.isEmpty)
            Text(t.deviceDetailsPage.logs.empty, style: TextStyle(color: theme.resources.textFillColorSecondary))
          else
            Card(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0; index < _logs.length; index++) ...[
                    _LogRow(log: _logs[index]),
                    if (index < _logs.length - 1) const Divider(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: TextStyle(color: theme.resources.textFillColorSecondary)),
          ),
          const SizedBox(width: 16),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final DeviceLog log;

  const _LogRow({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(FluentIcons.clock_16_regular, size: 16, color: theme.resources.textFillColorSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(_timeFormat.format(log.timestamp), style: TextStyle(color: theme.resources.textFillColorSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(log.description)),
        ],
      ),
    );
  }
}

extension on DeviceLog {
  String get description {
    final protocol = channel.https ? 'HTTPS' : 'HTTP';
    return switch (kind) {
      DeviceLogKind.discovered => t.deviceDetailsPage.logs.discovered(protocol: protocol, host: channel.host),
      DeviceLogKind.updated => t.deviceDetailsPage.logs.updated(protocol: protocol, host: channel.host),
    };
  }
}
