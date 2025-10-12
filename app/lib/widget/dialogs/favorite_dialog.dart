import 'package:common/isolate.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/favorite_device.dart';
import 'package:localsend_app/provider/favorites_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/widget/dialogs/error_dialog.dart';
import 'package:localsend_app/widget/dialogs/favorite_delete_dialog.dart';
import 'package:localsend_app/widget/dialogs/favorite_edit_dialog.dart';
import 'package:localsend_app/widget/fluent/card_ink_well.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

/// A dialog showing a list of favorites
class FavoritesDialog extends StatefulWidget {
  const FavoritesDialog();

  @override
  State<FavoritesDialog> createState() => _FavoritesDialogState();
}

class _FavoritesDialogState extends State<FavoritesDialog> with Refena {
  bool _fetching = false;
  String? _error;

  /// Checks if the device is reachable and pops the dialog with the result if it is.
  Future<void> _checkConnectionToDevice(FavoriteDevice favorite) async {
    setState(() {
      _fetching = true;
    });

    final https = ref.read(settingsProvider).https;

    try {
      final result = await ref.redux(parentIsolateProvider).dispatchAsyncTakeResult(IsolateTargetHttpDiscoveryAction(
            ip: favorite.ip,
            port: favorite.port,
            https: https,
          ));

      if (mounted) {
        context.pop(result);
      }
    } catch (e) {
      setState(() {
        _fetching = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _showDeviceDialog([FavoriteDevice? favorite]) async {
    await showDialog(context: context, builder: (_) => FavoriteEditDialog(favorite: favorite));
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);

    return ContentDialog(
      title: Text(t.dialogs.favoriteDialog.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (favorites.isEmpty)
            Text(
              t.dialogs.favoriteDialog.noFavorites,
              style: TextStyle(color: FluentTheme.of(context).autoGrey),
            ),
          for (final favorite in favorites)
            CardInkWell(
              onPressed: _fetching ? null : () async => await _checkConnectionToDevice(favorite),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: Text('${favorite.alias}\n(${favorite.ip})', textAlign: TextAlign.left)),
                    Tooltip(
                      message: t.general.edit,
                      child: IconButton(
                        onPressed: _fetching ? null : () async => await _showDeviceDialog(favorite),
                        icon: const Icon(FluentIcons.edit_20_regular, size: 18),
                      ),
                    ),
                    SizedBox(width: 5),
                    Tooltip(
                      message: t.general.delete,
                      child: IconButton(
                        onPressed: _fetching
                            ? null
                            : () async {
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => FavoriteDeleteDialog(favorite),
                                );

                                if (context.mounted && result == true) {
                                  await context.ref
                                      .redux(favoritesProvider)
                                      .dispatchAsync(RemoveFavoriteAction(deviceFingerprint: favorite.fingerprint));
                                }
                              },
                        icon: const Icon(FluentIcons.delete_20_regular, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
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
      actions: [
        FilledButton(
          onPressed: _showDeviceDialog,
          child: Text(t.dialogs.favoriteDialog.addFavorite),
        ),
        Button(
          onPressed: () => context.pop(),
          child: Text(t.general.cancel),
        ),
      ],
    );
  }
}
