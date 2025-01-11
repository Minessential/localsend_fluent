import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/receive_history_entry.dart';
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
import 'package:localsend_app/widget/fluent/card_ink_well.dart';
import 'package:localsend_app/widget/fluent/custom_icon_label_button.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
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

    return ResponsiveListView(
      padding: const EdgeInsets.all(20),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 15),
              CustomIconLabelButton(
                ButtonType.filled,
                onPressed: checkPlatform([TargetPlatform.iOS])
                    ? null
                    : () async {
                        final destination =
                            // ignore: use_build_context_synchronously
                            context.read(settingsProvider).destination ?? await getDefaultDestinationDirectory();
                        await openFolder(folderPath: destination);
                      },
                icon: const Icon(FluentIcons.folder),
                label: Text(t.receiveHistoryPage.openFolder),
              ),
              const SizedBox(width: 20),
              CustomIconLabelButton(
                ButtonType.filled,
                onPressed: entries.isEmpty
                    ? null
                    : () async {
                        final result = await showDialog(
                          context: context,
                          builder: (_) => const HistoryClearDialog(),
                        );

                        if (context.mounted && result == true) {
                          await context.redux(receiveHistoryProvider).dispatchAsync(RemoveAllHistoryEntriesAction());
                        }
                      },
                icon: const Icon(FluentIcons.delete),
                label: Text(t.receiveHistoryPage.deleteHistory),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
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

  FlyoutTarget _popupMenuButton(ReceiveHistoryEntry entry) {
    final menuController = FlyoutController();

    return FlyoutTarget(
      controller: menuController,
      child: IconButton(
        icon: Icon(FluentIcons.more_vertical),
        onPressed: () async {
          await menuController.showFlyout(
            autoModeConfiguration: FlyoutAutoConfiguration(preferredMode: FlyoutPlacementMode.topRight),
            barrierDismissible: true,
            dismissOnPointerMoveAway: false,
            dismissWithEsc: true,
            builder: (context) {
              return MenuFlyout(
                items: (entry.path != null ? _optionsAll : _optionsWithoutOpen).map((e) {
                  final label = e.label;
                  late final IconData icon;
                  Future<void> Function()? onPressed;
                  switch (e) {
                    case _EntryOption.open:
                      icon = FluentIcons.open_file;
                      onPressed = () => _openFile(context, entry, context.redux(receiveHistoryProvider));
                      break;
                    case _EntryOption.showInFolder:
                      icon = FluentIcons.open_folder_horizontal;
                      if (entry.path != null) {
                        onPressed = () =>
                            openFolder(folderPath: File(entry.path!).parent.path, fileName: path.basename(entry.path!));
                      }
                      break;
                    case _EntryOption.info:
                      icon = FluentIcons.info;
                      // ignore: use_build_context_synchronously
                      onPressed = () => showDialog(context: context, builder: (_) => FileInfoDialog(entry: entry));
                      break;
                    case _EntryOption.delete:
                      icon = FluentIcons.delete;
                      // ignore: use_build_context_synchronously
                      onPressed =
                          () => context.redux(receiveHistoryProvider).dispatchAsync(RemoveHistoryEntryAction(entry.id));
                      break;
                  }
                  return MenuFlyoutItem(
                    leading: Icon(icon),
                    text: Text(label),
                    onPressed: () async {
                      await onPressed?.call();
                      if (context.mounted) Flyout.of(context).close;
                    },
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
