import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/base/base_normal_page.dart';
import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/util/ui/snackbar.dart';
import 'package:localsend_app/widget/dialogs/qr_dialog.dart';
import 'package:localsend_app/widget/dialogs/zoom_dialog.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:localsend_isolates/util/sleep.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

enum _ServerState { initializing, running, error, stopping }

/// Lets web browsers upload files to this device.
/// Incoming requests are not listed here because they open the receive page
/// like any other incoming request.
class WebReceivePage extends StatefulWidget {
  const WebReceivePage();

  @override
  State<WebReceivePage> createState() => _WebReceivePageState();
}

class _WebReceivePageState extends State<WebReceivePage> with Refena {
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
    setState(() {
      _stateEnum = _ServerState.initializing;
      _encrypted = encrypted;
      _initializedError = null;
    });
    await sleepAsync(500);
    try {
      await ref
          .notifier(serverProvider)
          .restartServer(
            alias: settings.alias,
            port: settings.port,
            https: _encrypted,
            webUpload: true,
          );
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

  /// Web receive uses unencrypted http by default, so we need to revert to the previous state.
  Future<void> _revertServerState() async {
    await ref.notifier(serverProvider).restartServerFromSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return PopScope(
      onPopInvokedWithResult: (_, _) async {
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
        windowTitle: t.webReceivePage.title,
        headerTitle: t.webReceivePage.title,
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
                      child: SelectableText(_initializedError!, style: theme.typography.bodyLarge),
                    ),
                  ],
                ],
              );
            }

            final serverState = context.watch(serverProvider);
            if (serverState == null) {
              // the server is restarting
              return const Center(child: ProgressRing());
            }
            final networkState = context.watch(localIpProvider);
            final settings = context.watch(settingsProvider);

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
                        return Padding(
                          padding: const EdgeInsets.all(2),
                          child: Row(
                            children: [
                              Expanded(child: SelectableText(url, style: theme.typography.bodyStrong)),
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
                                      data: url,
                                      label: url,
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
                  checked: settings.receiveViaLinkAutoAccept,
                  content: Text(t.webSharePage.autoAccept, style: theme.typography.bodyStrong),
                  onChanged: (value) async {
                    await ref.notifier(settingsProvider).setReceiveViaLinkAutoAccept(value == true);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
