import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/receive_history_entry.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/pages/receive_page.dart';
import 'package:localsend_app/pages/receive_page_controller.dart';
import 'package:localsend_app/provider/receive_history_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/file_size_helper.dart';
import 'package:localsend_app/util/native/directories.dart';
import 'package:localsend_app/util/native/open_file.dart';
import 'package:localsend_app/util/native/open_folder.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/dialogs/file_info_dialog.dart';
import 'package:localsend_app/widget/dialogs/history_clear_dialog.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';
import 'package:localsend_app/widget/fluent/base_pane_body.dart';
import 'package:localsend_app/widget/fluent/card_ink_well.dart';
import 'package:path/path.dart' as path;
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

enum _EntryOption {
  open,
  showInFolder,
  info,
  delete;

  String get label {
    return switch (this) {
      _EntryOption.open => t.receiveHistoryPage.entryActions.open,
      _EntryOption.showInFolder => t.receiveHistoryPage.entryActions.showInFolder,
      _EntryOption.info => t.receiveHistoryPage.entryActions.info,
      _EntryOption.delete => t.receiveHistoryPage.entryActions.deleteFromHistory,
    };
  }
}

const _optionsAll = _EntryOption.values;
final _optionsWithoutOpen = [_EntryOption.info, _EntryOption.delete];

class ReceiveHistoryPage extends StatelessWidget {
  const ReceiveHistoryPage({super.key});

  Future<void> _openFile(
    BuildContext context,
    ReceiveHistoryEntry entry,
    Dispatcher<ReceiveHistoryService, List<ReceiveHistoryEntry>> dispatcher,
  ) async {
    if (entry.path != null) {
      await openFile(
        context,
        entry.fileType,
        entry.path!,
        onDeleteTap: () => dispatcher.dispatchAsync(RemoveHistoryEntryAction(entry.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch(receiveHistoryProvider);
    final theme = FluentTheme.of(context);

    return BasePaneBody.scrollable(
      title: HomeTab.history.label,
      titleActions: [
        if (!checkPlatform([TargetPlatform.iOS]))
          Tooltip(
            message: t.receiveHistoryPage.openFolder,
            child: IconButton(
              icon: const Icon(FluentIcons.folder_open_24_regular, size: 24.0),
              onPressed: () async {
                final destination =
                    // ignore: use_build_context_synchronously
                    context.read(settingsProvider).destination ?? await getDefaultDestinationDirectory();
                await openFolder(folderPath: destination);
              },
            ),
          ),
        const SizedBox(width: 16),
        if (entries.isNotEmpty)
          Tooltip(
            message: t.receiveHistoryPage.deleteHistory,
            child: IconButton(
              icon: const Icon(FluentIcons.delete_24_regular, size: 24.0),
              onPressed: () async {
                final result = await showDialog(
                  context: context,
                  builder: (_) => const HistoryClearDialog(),
                );

                if (context.mounted && result == true) {
                  await context.redux(receiveHistoryProvider).dispatchAsync(RemoveAllHistoryEntriesAction());
                }
              },
            ),
          ),
      ],
      children: [
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Center(child: Text(t.receiveHistoryPage.empty, style: FluentTheme.of(context).typography.title)),
          )
        else
          ...entries.map((entry) {
            return CardInkWell(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              onPressed: entry.path != null || entry.isMessage
                  ? () async {
                      if (entry.isMessage) {
                        context
                            .redux(receivePageControllerProvider)
                            .dispatch(InitReceivePageFromHistoryMessageAction(entry: entry));
                        // ignore: unawaited_futures
                        context.push(() => const ReceivePage());
                        return;
                      }

                      await _openFile(context, entry, context.redux(receiveHistoryProvider));
                    }
                  : null,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FilePathThumbnail(
                      path: entry.path,
                      fileType: entry.fileType,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            entry.fileName,
                            style: const TextStyle(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                          ),
                          // const SizedBox(height: 6),
                          Text(
                            '${entry.timestampString} - ${entry.fileSize.asReadableFileSize} - ${entry.senderAlias}',
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: theme.typography.caption
                                ?.copyWith(color: theme.typography.caption?.color?.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _popupMenuButton(entry),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _popupMenuButton(ReceiveHistoryEntry entry) {
    final menuController = FlyoutController();
    return Builder(builder: (context) {
      return FlyoutTarget(
        controller: menuController,
        child: IconButton(
          icon: Icon(FluentIcons.more_vertical_24_regular),
          onPressed: () async {
            await menuController.showFlyout(
              autoModeConfiguration: FlyoutAutoConfiguration(preferredMode: FlyoutPlacementMode.topRight),
              barrierDismissible: true,
              dismissOnPointerMoveAway: false,
              dismissWithEsc: true,
              builder: (ctx) {
                return MenuFlyout(
                  items: (entry.path != null ? _optionsAll : _optionsWithoutOpen).map((e) {
                    final label = e.label;
                    late final IconData icon;
                    Future<void> Function()? onPressed;
                    switch (e) {
                      case _EntryOption.open:
                        icon = FluentIcons.open_20_regular;
                        onPressed = () => _openFile(context, entry, context.redux(receiveHistoryProvider));
                        break;
                      case _EntryOption.showInFolder:
                        icon = FluentIcons.open_folder_20_regular;
                        if (entry.path != null) {
                          onPressed = () => openFolder(
                              folderPath: File(entry.path!).parent.path, fileName: path.basename(entry.path!));
                        }
                        break;
                      case _EntryOption.info:
                        icon = FluentIcons.info_20_regular;
                        // ignore: use_build_context_synchronously
                        onPressed = () => showDialog(context: context, builder: (_) => FileInfoDialog(entry: entry));
                        break;
                      case _EntryOption.delete:
                        icon = FluentIcons.delete_20_regular;
                        // ignore: use_build_context_synchronously
                        onPressed = () =>
                            context.redux(receiveHistoryProvider).dispatchAsync(RemoveHistoryEntryAction(entry.id));
                        break;
                    }
                    return MenuFlyoutItem(
                      leading: Icon(icon),
                      text: Text(label),
                      onPressed: () async {
                        await onPressed?.call();
                        if (ctx.mounted) Flyout.of(ctx).close;
                      },
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      );
    });
  }
}
