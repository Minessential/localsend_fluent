import 'dart:async';

import 'package:collection/collection.dart';
import 'package:common/isolate.dart';
import 'package:common/model/device.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/provider/last_devices.provider.dart';
import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/widget/dialogs/error_dialog.dart';
import 'package:localsend_app/widget/fluent/custom_text_box.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

enum _InputMode {
  hashtag,
  ip;

  String get label {
    return switch (this) {
      _InputMode.hashtag => t.dialogs.addressInput.hashtag,
      _InputMode.ip => t.dialogs.addressInput.ip,
    };
  }
}

/// A dialog to input an hash or address.
/// Pops the dialog with the device if found.
class AddressInputDialog extends StatefulWidget {
  const AddressInputDialog();

  @override
  State<AddressInputDialog> createState() => _AddressInputDialogState();
}

class _AddressInputDialogState extends State<AddressInputDialog> with Refena {
  final _selected = List.generate(_InputMode.values.length, (index) => index == 0);
  _InputMode _mode = _InputMode.hashtag;
  String _input = '';
  bool _fetching = false;
  String? _error;

  Future<void> _submit(List<String> localIps, int port, [String? candidate]) async {
    final List<String> candidates;
    final String input = _input.trim();
    if (candidate != null) {
      candidates = [candidate];
    } else if (_mode == _InputMode.ip) {
      candidates = [input];
    } else {
      candidates = localIps.map((ip) => '${ip.ipPrefix}.$input').toList();
    }

    setState(() {
      _fetching = true;
    });

    final https = ref.read(settingsProvider).https;

    final deviceCompleter = Completer<void>();
    Device? foundDevice;
    String? error;

    final List<Future<Device>> futures = [
      for (final ip in candidates)
        () async {
          try {
            final device =
                await ref.redux(parentIsolateProvider).dispatchAsyncTakeResult(IsolateTargetHttpDiscoveryAction(
                      ip: ip,
                      port: port,
                      https: https,
                    ));
            foundDevice = device;
            deviceCompleter.complete();
            return device;
          } catch (e) {
            error = e.toString();
            rethrow;
          }
        }(),
    ];

    // Wait until,
    // - a device is found
    // - all candidates are checked
    try {
      await Future.any([
        deviceCompleter.future,
        Future.wait(futures),
      ]);
    } catch (_) {}

    if (!mounted) {
      return;
    }

    if (foundDevice != null) {
      ref.redux(lastDevicesProvider).dispatch(AddLastDeviceAction(foundDevice!));
      context.pop(foundDevice);
    } else {
      setState(() {
        _fetching = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localIps = (ref.watch(localIpProvider.select((info) => info.localIps))).uniqueIpPrefix;
    final settings = ref.watch(settingsProvider);
    final lastDevices = ref.watch(lastDevicesProvider);
    final theme = FluentTheme.of(context);

    return ContentDialog(
      title: Text(t.dialogs.addressInput.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 15, children: [
            for (int i = 0; i < _selected.length; i++)
              RadioButton(
                content: Text(_InputMode.values[i].label),
                checked: _selected[i],
                onChanged: (checked) {
                  setState(() {
                    for (int j = 0; j < _selected.length; j++) {
                      _selected[j] = j == i;
                    }
                  });
                  _mode = _InputMode.values[i];
                },
              ),
          ]),
          const SizedBox(height: 15),
          CustomTextBox(
            key: ValueKey('input-$_mode'),
            autofocus: true,
            enabled: !_fetching,
            keyboardType: _mode == _InputMode.hashtag ? TextInputType.number : TextInputType.text,
            prefix: Text(_mode == _InputMode.hashtag ? '# ' : 'IP: '),
            onChanged: (s) {
              setState(() => _input = s);
            },
            onSubmitted: (s) async => _submit(localIps, settings.port),
          ),
          const SizedBox(height: 10),
          if (_mode == _InputMode.hashtag) ...[
            Text(
              '${t.general.example}: 123',
              style: TextStyle(color: theme.autoGrey),
            ),
            if (localIps.length <= 1)
              Text(
                '${t.dialogs.addressInput.ip}: ${localIps.firstOrNull?.ipPrefix ?? '192.168.2'}.$_input',
                style: TextStyle(color: theme.autoGrey),
              )
            else ...[
              Text(
                '${t.dialogs.addressInput.ip}:',
                style: TextStyle(color: theme.autoGrey),
              ),
              for (final ip in localIps)
                Text(
                  '- ${ip.ipPrefix}.$_input',
                  style: TextStyle(color: theme.autoGrey),
                ),
            ],
          ] else ...[
            if (lastDevices.isEmpty)
              Text(
                '${t.general.example}: ${localIps.firstOrNull?.ipPrefix ?? '192.168.2'}.123',
                style: TextStyle(color: theme.autoGrey),
              )
            else
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: t.dialogs.addressInput.recentlyUsed),
                    ...lastDevices.mapIndexed((index, device) {
                      return [
                        if (index != 0) const TextSpan(text: ', '),
                        TextSpan(
                          text: device.ip,
                          style: TextStyle(color: FluentTheme.of(context).accentColor),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async => _submit(localIps, settings.port, device.ip),
                        )
                      ];
                    }).expand((e) => e),
                  ],
                ),
              ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Text(t.general.error, style: TextStyle(color: Colors.warningPrimaryColor)),
                  if (_error != null) ...[
                    const SizedBox(width: 5),
                    IconButton(
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (_) => ErrorDialog(error: _error!),
                        );
                      },
                      icon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(FluentIcons.info_20_regular, color: Colors.warningPrimaryColor, size: 20),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: _fetching ? null : () async => _submit(localIps, settings.port),
          child: Text(t.general.confirm),
        ),
        Button(
          onPressed: () => context.pop(),
          child: Text(t.general.cancel),
        ),
      ],
    );
  }
}

extension on String {
  String get ipPrefix {
    return split('.').take(3).join('.');
  }
}

extension on List<String> {
  List<String> get uniqueIpPrefix {
    final seen = <String>{};
    return where((s) => seen.add(s.ipPrefix)).toList();
  }
}
