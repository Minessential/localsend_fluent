import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/base/base_normal_page.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/selection/selected_receiving_files_provider.dart';
import 'package:localsend_app/util/file_size_helper.dart';
import 'package:localsend_app/util/file_type_ext.dart';
import 'package:localsend_app/util/native/pick_directory_path.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/custom_dropdown_button.dart';
import 'package:localsend_app/widget/dialogs/file_name_input_dialog.dart';
import 'package:localsend_app/widget/dialogs/quick_actions_dialog.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:refena_flutter/refena_flutter.dart';

class ReceiveOptionsPage extends StatelessWidget {
  const ReceiveOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final receiveSession = ref.watch(serverProvider.select((s) => s?.session));
    if (receiveSession == null) {
      return BaseNormalPage(body: Container());
    }
    final selectState = ref.watch(selectedReceivingFilesProvider);
    final theme = FluentTheme.of(context);

    return BaseNormalPage(
      windowTitle: t.receiveOptionsPage.title,
      headerTitle: t.receiveOptionsPage.title,
      body: ResponsiveListView(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        tabletPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          Row(
            children: [
              Text(t.receiveOptionsPage.destination, style: theme.typography.subtitle),
              if (checkPlatformWithFileSystem())
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: IconButton(
                    onPressed: () async {
                      final directory = await pickDirectoryPath();
                      if (directory != null) {
                        ref.notifier(serverProvider).setSessionDestinationDir(directory);
                      }
                    },
                    icon: const Icon(FluentIcons.edit_16_regular, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(checkPlatformWithFileSystem() ? receiveSession.destinationDirectory : t.receiveOptionsPage.appDirectory),
          if (checkPlatformWithGallery())
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(t.receiveOptionsPage.saveToGallery, style: theme.typography.subtitle),
                const SizedBox(height: 10),
                Row(children: [
                  CustomDropdownButton<bool>(
                    value: receiveSession.saveToGallery,
                    expanded: false,
                    items: [false, true].map((b) {
                      return ComboBoxItem(
                        value: b,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 80),
                          child: Text(b ? t.general.on : t.general.off, textAlign: TextAlign.start),
                        ),
                      );
                    }).toList(),
                    onChanged: (b) => ref.notifier(serverProvider).setSessionSaveToGallery(b),
                  ),
                  if (receiveSession.containsDirectories && !receiveSession.saveToGallery) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(t.receiveOptionsPage.saveToGalleryOff, style: TextStyle(color: theme.autoGrey)),
                    ),
                  ]
                ]),
              ],
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(t.general.files, style: theme.typography.subtitle),
              const SizedBox(width: 10),
              Tooltip(
                message: t.dialogs.quickActions.title,
                child: IconButton(
                  onPressed: () async {
                    await showDialog(context: context, builder: (_) => const QuickActionsDialog());
                  },
                  icon: const Icon(FluentIcons.lightbulb_16_regular, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: t.general.reset,
                child: IconButton(
                  onPressed: () async {
                    ref
                        .notifier(selectedReceivingFilesProvider)
                        .setFiles(receiveSession.files.values.map((f) => f.file).toList());
                  },
                  icon: const Icon(FluentIcons.arrow_undo_16_regular, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ...receiveSession.files.values.map((file) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(file.file.fileType.icon, size: 46),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectState[file.file.id] ?? file.file.fileName,
                          style: const TextStyle(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                        SizedBox(height: 5),
                        Text(
                          '${!selectState.containsKey(file.file.id) ? t.general.skipped : (selectState[file.file.id] == file.file.fileName ? t.general.unchanged : t.general.renamed)} - ${file.file.size.asReadableFileSize}',
                          style: TextStyle(
                            color: !selectState.containsKey(file.file.id)
                                ? theme.autoGrey
                                : (selectState[file.file.id] == file.file.fileName
                                    ? theme.resources.textFillColorPrimary
                                    : Colors.orange),
                          ),
                        )
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: t.general.edit,
                        child: IconButton(
                          onPressed: selectState[file.file.id] == null
                              ? null
                              : () async {
                                  final result = await showDialog<String>(
                                    context: context,
                                    builder: (_) => FileNameInputDialog(
                                      originalName: file.file.fileName,
                                      initialName: selectState[file.file.id]!,
                                    ),
                                  );
                                  if (result != null) {
                                    ref.notifier(selectedReceivingFilesProvider).rename(file.file.id, result);
                                  }
                                },
                          icon: const Icon(FluentIcons.edit_16_regular, size: 16),
                        ),
                      ),
                      SizedBox(width: 10),
                      Checkbox(
                        checked: selectState.containsKey(file.file.id),
                        onChanged: (selected) {
                          if (selected == true) {
                            ref.notifier(selectedReceivingFilesProvider).select(file.file);
                          } else {
                            ref.notifier(selectedReceivingFilesProvider).unselect(file.file.id);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
