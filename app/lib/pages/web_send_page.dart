import 'package:common/util/sleep.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/cross_file.dart';
import 'package:localsend_app/pages/base/base_normal_page.dart';
import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/util/ui/snackbar.dart';
import 'package:localsend_app/widget/dialogs/pin_dialog.dart';
import 'package:localsend_app/widget/dialogs/qr_dialog.dart';
import 'package:localsend_app/widget/dialogs/zoom_dialog.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

enum _ServerState { initializing, running, error, stopping }

class WebSendPage extends StatefulWidget {
  final List<CrossFile> files;

  const WebSendPage(this.files);

  @override
  State<WebSendPage> createState() => _WebSendPageState();
}

class _WebSendPageState extends State<WebSendPage> with Refena {
  _ServerState _stateEnum = _ServerState.initializing;
  bool _encrypted = false;
  String? _initializedError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init(encrypted: false);
    });
  }

  void _init({required bool encrypted}) async {
    final settings = ref.read(settingsProvider);
    final (beforeAutoAccept, beforePin) =
        ref.read(serverProvider.select((state) => (state?.webSendState?.autoAccept, state?.webSendState?.pin)));
    setState(() {
      _stateEnum = _ServerState.initializing;
      _encrypted = encrypted;
      _initializedError = null;
    });
    await sleepAsync(500);
    try {
      await ref.notifier(serverProvider).restartServer(
            alias: settings.alias,
            port: settings.port,
            https: _encrypted,
          );
      await ref.notifier(serverProvider).initializeWebSend(widget.files);
      if (beforeAutoAccept != null) {
        ref.notifier(serverProvider).setWebSendAutoAccept(beforeAutoAccept);
      }
      ref.notifier(serverProvider).setWebSendPin(beforePin);
      setState(() {
        _stateEnum = _ServerState.running;
      });
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _stateEnum = _ServerState.error;
          _initializedError = e.toString();
        });
      }
    }
  }

  /// Web share uses unencrypted http, so we need to revert to the previous state.
  Future<void> _revertServerState() async {
    await ref.notifier(serverProvider).restartServerFromSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return PopScope(
      onPopInvokedWithResult: (_, __) async {
        if (_stateEnum != _ServerState.running) {
          return;
        }

        setState(() {
          _stateEnum = _ServerState.stopping;
        });
        await sleepAsync(250);
        await _revertServerState();
        await sleepAsync(250);

        if (context.mounted) {
          context.pop();
        }
      },
      canPop: false,
      child: BaseNormalPage(
        windowTitle: t.webSharePage.title,
        headerTitle: t.webSharePage.title,
        body: Builder(
          builder: (context) {
            if (_stateEnum != _ServerState.running) {
              return Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_stateEnum == _ServerState.initializing || _stateEnum == _ServerState.stopping) ...[
                    const ProgressRing(),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        _stateEnum == _ServerState.initializing ? t.webSharePage.loading : t.webSharePage.stopping,
                        style: theme.typography.subtitle,
                      ),
                    ),
                  ] else if (_initializedError != null) ...[
                    Icon(FluentIcons.error_circle_48_regular, size: 48, color: Colors.red),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(t.webSharePage.error, style: theme.typography.subtitle),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: SelectableText('_initializedError!', style: theme.typography.bodyLarge),
                    ),
                  ],
                ],
              );
            }

            final serverState = context.watch(serverProvider)!;
            final webSendState = serverState.webSendState!;
            final networkState = context.watch(localIpProvider);

            return ResponsiveListView(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              children: [
                Text(t.webSharePage.openLink(n: networkState.localIps.length), style: theme.typography.subtitle),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...networkState.localIps.map((ip) {
                        final url = '${_encrypted ? 'https' : 'http'}://$ip:${serverState.port}';
                        final urlWithPin = switch (webSendState.pin) {
                          String() => '$url/?pin=${Uri.encodeQueryComponent(webSendState.pin!)}',
                          null => url,
                        };
                        return Padding(
                          padding: const EdgeInsets.all(2),
                          child: Row(
                            children: [
                              SelectableText(url, style: theme.typography.bodyStrong),
                              const SizedBox(width: 15),
                              IconButton(
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: url));
                                  if (context.mounted && checkPlatformIsDesktop()) {
                                    context.showSnackBar(t.general.copiedToClipboard);
                                  }
                                },
                                icon: Icon(FluentIcons.copy_20_regular, size: 16),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (_) => QrDialog(
                                      data: urlWithPin,
                                      label: url,
                                      listenIncomingWebSendRequests: true,
                                      pin: webSendState.pin,
                                    ),
                                  );
                                },
                                icon: Icon(FluentIcons.qr_code_20_regular, size: 16),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (_) => ZoomDialog(
                                      label: url,
                                      pin: webSendState.pin,
                                      listenIncomingWebSendRequests: true,
                                    ),
                                  );
                                },
                                icon: Icon(FluentIcons.tv_20_regular, size: 16),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(t.webSharePage.requests, style: theme.typography.subtitle),
                const SizedBox(height: 10),
                if (webSendState.sessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Text(t.webSharePage.noRequests),
                  ),
                ...webSendState.sessions.entries.map((entry) {
                  final session = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.deviceInfo,
                                style: theme.typography.bodyStrong?.copyWith(
                                  color: session.responseHandler != null ? Colors.warningPrimaryColor : null,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(session.ip, style: theme.typography.body?.copyWith(color: theme.autoGrey)),
                            ],
                          ),
                        ),
                        if (session.responseHandler != null) ...[
                          IconButton(
                            onPressed: () {
                              ref.notifier(serverProvider).declineWebSendRequest(session.sessionId);
                            },
                            icon: const Icon(FluentIcons.dismiss_16_regular, size: 16),
                          ),
                          SizedBox(width: 10),
                          IconButton(
                            onPressed: () {
                              ref.notifier(serverProvider).acceptWebSendRequest(session.sessionId);
                            },
                            icon: const Icon(FluentIcons.checkmark_16_regular, size: 16),
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(t.general.accepted, style: theme.typography.body),
                          ),
                      ]),
                    ),
                  );
                }),
                Checkbox(
                  checked: _encrypted,
                  content: Text(t.webSharePage.encryption, style: theme.typography.bodyStrong),
                  onChanged: (value) {
                    _init(encrypted: value == true);
                  },
                ),
                const SizedBox(height: 5),
                if (_encrypted) ...[
                  Text(
                    t.webSharePage.encryptionHint,
                    style: theme.typography.body?.copyWith(color: Colors.warningPrimaryColor),
                  ),
                  const SizedBox(height: 5),
                ],
                Checkbox(
                  checked: webSendState.autoAccept,
                  content: Text(t.webSharePage.autoAccept, style: theme.typography.bodyStrong),
                  onChanged: (value) {
                    ref.notifier(serverProvider).setWebSendAutoAccept(value == true);
                  },
                ),
                const SizedBox(height: 5),
                Checkbox(
                  checked: webSendState.pin != null,
                  content: Text(t.webSharePage.requirePin, style: theme.typography.bodyStrong),
                  onChanged: (value) async {
                    final currentPIN = webSendState.pin;
                    if (currentPIN != null) {
                      ref.notifier(serverProvider).setWebSendPin(null);
                    } else {
                      final String? newPin = await showDialog<String>(
                        context: context,
                        builder: (_) => const PinDialog(
                          obscureText: false,
                          generateRandom: true,
                        ),
                      );

                      if (newPin != null && newPin.isNotEmpty) {
                        ref.notifier(serverProvider).setWebSendPin(newPin);
                      }
                    }
                  },
                ),
                const SizedBox(height: 5),
                if (webSendState.pin != null)
                  Text(
                    t.webSharePage.pinHint(pin: webSendState.pin!),
                    style: theme.typography.body?.copyWith(color: Colors.warningPrimaryColor),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
