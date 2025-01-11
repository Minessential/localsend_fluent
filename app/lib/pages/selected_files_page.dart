import 'dart:convert';

import 'package:common/model/file_type.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/base/base_dialog_page.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/util/file_size_helper.dart';
import 'package:localsend_app/util/native/file_picker.dart';
import 'package:localsend_app/util/native/open_file.dart';
import 'package:localsend_app/util/ui/nav_bar_padding.dart';
import 'package:localsend_app/widget/dialogs/add_file_dialog.dart';
import 'package:localsend_app/widget/dialogs/message_input_dialog.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';
import 'package:localsend_app/widget/fluent/card_ink_well.dart';
import 'package:localsend_app/widget/fluent/custom_icon_label_button.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

final _options = FilePickerOption.getOptionsForPlatform();

class SelectedFilesPage extends StatelessWidget {
  const SelectedFilesPage();

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final selectedFiles = ref.watch(selectedSendingFilesProvider);

    return BaseDialogPage(
      title: t.sendTab.selection.title,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 15)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.sendTab.selection.files(files: selectedFiles.length)),
                        Text(t.sendTab.selection
                            .size(size: selectedFiles.fold(0, (prev, curr) => prev + curr.size).asReadableFileSize)),
                      ],
                    ),
                  ),
                  Button(
                    onPressed: () {
                      ref.redux(selectedSendingFilesProvider).dispatch(ClearSelectionAction());
                      context.popUntilRoot();
                    },
                    child: Text(t.selectedFilesPage.deleteAll),
                  ),
                  SizedBox(width: 15),
                  CustomIconLabelButton(
                    ButtonType.filled,
                    onPressed: () async {
                      if (_options.length == 1) {
                        // open directly
                        await ref.global.dispatchAsync(PickFileAction(
                          option: _options.first,
                          context: context,
                        ));
                        return;
                      }
                      await AddFileDialog.open(
                        context: context,
                        options: _options,
                      );
                    },
                    icon: const Icon(FluentIcons.add),
                    label: Text(t.general.add),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: selectedFiles.length,
                (context, index) {
                  final file = selectedFiles[index];

                  final String? message;
                  if (file.fileType == FileType.text && file.bytes != null) {
                    message = utf8.decode(file.bytes!);
                  } else {
                    message = null;
                  }

                  return CardInkWell(
                    onPressed: file.path != null ? () async => openFile(context, file.fileType, file.path!) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          SmartFileThumbnail.fromCrossFile(file),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message != null ? '"${message.replaceAll('\n', ' ')}"' : file.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                ),
                                Text(file.size.asReadableFileSize, style: FluentTheme.of(context).typography.caption),
                              ],
                            ),
                          ),
                          if (file.fileType == FileType.text && file.bytes != null)
                            Tooltip(
                              message: t.general.edit,
                              child: IconButton(
                                onPressed: () async {
                                  final result = await showDialog<String>(
                                      context: context, builder: (_) => MessageInputDialog(initialText: message));
                                  if (result != null) {
                                    ref
                                        .redux(selectedSendingFilesProvider)
                                        .dispatch(UpdateMessageAction(message: result, index: index));
                                  }
                                },
                                icon: const Icon(FluentIcons.edit),
                              ),
                            ),
                          SizedBox(width: 5),
                          Tooltip(
                            message: t.general.delete,
                            child: IconButton(
                              onPressed: () {
                                final currCount = ref.read(selectedSendingFilesProvider).length;
                                ref.redux(selectedSendingFilesProvider).dispatch(RemoveSelectedFileAction(index));
                                if (currCount == 1) {
                                  context.popUntilRoot();
                                }
                              },
                              icon: const Icon(FluentIcons.delete),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 15 + getNavBarPadding(context))),
        ],
      ),
    );
  }
}
