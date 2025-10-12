import 'package:common/isolate.dart';
import 'package:common/model/device.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/favorite_device.dart';
import 'package:localsend_app/provider/favorites_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/widget/dialogs/error_dialog.dart';
import 'package:localsend_app/widget/fluent/custom_text_box.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

/// A dialog to add or edit a favorite device.
class FavoriteEditDialog extends StatefulWidget {
  final FavoriteDevice? favorite;
  final Device? prefilledDevice;

  const FavoriteEditDialog({
    this.favorite,
    this.prefilledDevice,
  });

  @override
  State<FavoriteEditDialog> createState() => _FavoriteEditDialogState();
}

class _FavoriteEditDialogState extends State<FavoriteEditDialog> with Refena {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  final _aliasController = TextEditingController();
  bool _fetching = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _ipController.text = widget.prefilledDevice?.ip ?? widget.favorite?.ip ?? '';
    _aliasController.text = widget.prefilledDevice?.alias ?? widget.favorite?.alias ?? '';

    ensureRef((ref) {
      _portController.text = widget.prefilledDevice?.port.toString() ??
          widget.favorite?.port.toString() ??
          ref.read(settingsProvider).port.toString();
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(
          widget.favorite != null ? t.dialogs.favoriteEditDialog.titleEdit : t.dialogs.favoriteEditDialog.titleAdd),
      content: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.dialogs.favoriteEditDialog.name),
            const SizedBox(height: 5),
            CustomTextBox(
              controller: _aliasController,
              placeholder: t.dialogs.favoriteEditDialog.auto,
              enabled: !_fetching,
            ),
            const SizedBox(height: 16),
            Text(t.dialogs.favoriteEditDialog.ip),
            const SizedBox(height: 5),
            CustomTextBox(
              controller: _ipController,
              autofocus: widget.favorite == null && widget.prefilledDevice == null,
              enabled: !_fetching,
            ),
            const SizedBox(height: 16),
            Text(t.dialogs.favoriteEditDialog.port),
            const SizedBox(height: 5),
            CustomTextBox(
              controller: _portController,
              enabled: !_fetching,
              keyboardType: TextInputType.number,
            ),
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
                        icon: Icon(FluentIcons.info_20_regular, color: Colors.warningPrimaryColor, size: 20),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _fetching
              ? null
              : () async {
                  if (_ipController.text.isEmpty) {
                    return;
                  }

                  if (_portController.text.isEmpty) {
                    return;
                  }

                  if (widget.favorite != null) {
                    // Update existing favorite
                    final existingFavorite = widget.favorite!;
                    final trimmedNewAlias = _aliasController.text.trim();
                    if (trimmedNewAlias.isEmpty) {
                      return;
                    }

                    await ref.redux(favoritesProvider).dispatchAsync(UpdateFavoriteAction(existingFavorite.copyWith(
                          ip: _ipController.text,
                          port: int.parse(_portController.text),
                          alias: trimmedNewAlias,
                          customAlias: existingFavorite.customAlias || trimmedNewAlias != existingFavorite.alias,
                        )));
                    if (context.mounted) context.pop();
                  } else {
                    // Add new favorite
                    final ip = _ipController.text;
                    final port = int.parse(_portController.text);
                    final https = ref.read(settingsProvider).https;
                    setState(() {
                      _fetching = true;
                    });

                    try {
                      final result = await ref
                          .redux(parentIsolateProvider)
                          .dispatchAsyncTakeResult(IsolateTargetHttpDiscoveryAction(
                            ip: ip,
                            port: port,
                            https: https,
                          ));

                      final name = _aliasController.text.trim();

                      await ref.redux(favoritesProvider).dispatchAsync(AddFavoriteAction(FavoriteDevice.fromValues(
                            fingerprint: result.fingerprint,
                            ip: _ipController.text,
                            port: int.parse(_portController.text),
                            alias: name.isEmpty ? result.alias : name,
                          )));

                      if (context.mounted) {
                        context.pop();
                      }
                    } catch (e) {
                      setState(() {
                        _fetching = false;
                        _error = e.toString();
                      });
                    }
                  }
                },
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
