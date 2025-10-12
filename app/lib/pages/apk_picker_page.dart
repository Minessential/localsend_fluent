import 'package:common/model/file_type.dart';
import 'package:device_apps/device_apps.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/base/base_normal_page.dart';
import 'package:localsend_app/provider/apk_provider.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/util/file_size_helper.dart';
import 'package:localsend_app/util/native/cross_file_converters.dart';
import 'package:localsend_app/util/ui/nav_bar_padding.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';
import 'package:localsend_app/widget/fluent/custom_icon_label_button.dart';
import 'package:localsend_app/widget/fluent/custom_text_box.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:localsend_app/widget/sliver/sliver_pinned_header.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class ApkPickerPage extends StatefulWidget {
  const ApkPickerPage({super.key});

  @override
  State<ApkPickerPage> createState() => _ApkPickerPageState();
}

class _ApkPickerPageState extends State<ApkPickerPage> with Refena {
  final _textController = TextEditingController();
  final List<Application> _selectedApps = [];

  Future<void> _pickApp(Application app) async {
    await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddFilesAction(
          files: [app],
          converter: CrossFileConverters.convertApplication,
        ));

    if (mounted) {
      context.pop();
    }
  }

  Future<void> _pickApps(List<Application> apps) async {
    // ignore: discarded_futures

    for (Application app in apps) {
      await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddFilesAction(
            files: [app],
            converter: CrossFileConverters.convertApplication,
          ));
    }

    if (mounted) {
      context.pop();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    ref.dispose(apkSearchParamProvider);
    super.dispose();
  }

  void _appSelection(Application app) {
    setState(() {
      if (_selectedApps.contains(app)) {
        _selectedApps.remove(app);
      } else {
        _selectedApps.add(app);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final apkParams = ref.watch(apkSearchParamProvider);
    final apkAsync = ref.watch(apkProvider);

    return BaseNormalPage(
      windowTitle: t.apkPickerPage.title,
      headerTitle: t.apkPickerPage.title,
      headerSuffix: (_selectedApps.isEmpty)
          ? Container()
          : CustomIconLabelButton(
              ButtonType.filled,
              icon: Icon(FluentIcons.add_16_filled, size: 16),
              label: Text('Add ${_selectedApps.length} ${(_selectedApps.length == 1) ? "App" : "Apps"}'),
              onPressed: () async => await _pickApps(_selectedApps),
            ),
      body: ResponsiveListView.single(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        tabletPadding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            Row(
              children: [
                ToggleSwitch(
                  checked: !apkParams.includeSystemApps,
                  onChanged: (v) {
                    ref
                        .notifier(apkSearchParamProvider)
                        .setState((old) => old.copyWith(includeSystemApps: !old.includeSystemApps));
                  },
                  content: Text(t.apkPickerPage.excludeSystemApps),
                ),
                SizedBox(width: 15),
                ToggleSwitch(
                  checked: apkParams.onlyAppsWithLaunchIntent,
                  onChanged: (v) {
                    ref
                        .notifier(apkSearchParamProvider)
                        .setState((old) => old.copyWith(onlyAppsWithLaunchIntent: !old.onlyAppsWithLaunchIntent));
                  },
                  content: Text(t.apkPickerPage.excludeAppsWithoutLaunchIntent),
                ),
              ],
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 10),
                  ),
                  SliverPinnedHeader(
                    height: 80,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomTextBox(
                            controller: _textController,
                            autofocus: true,
                            onChanged: (s) {
                              ref.notifier(apkSearchParamProvider).setState((old) => old.copyWith(query: s));
                              setState(() {});
                            },
                            suffix: Row(
                              children: [
                                apkParams.query.isNotEmpty
                                    ? IconButton(
                                        onPressed: () {
                                          ref
                                              .notifier(apkSearchParamProvider)
                                              .setState((old) => old.copyWith(query: ''));
                                          _textController.clear();
                                        },
                                        icon: const Icon(FluentIcons.dismiss_12_regular, size: 12),
                                      )
                                    : Text(apkParams.query),
                                const Icon(FluentIcons.search_24_regular),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Text(t.apkPickerPage.apps(n: apkAsync.data?.length ?? 0)),
                        const Spacer(),
                        ToggleSwitch(
                          leadingContent: true,
                          content: Text('Select Multiple Apps'),
                          checked: apkParams.selectMultipleApps,
                          onChanged: (bool newValue) {
                            setState(() {
                              apkParams.selectMultipleApps = !apkParams.selectMultipleApps;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  apkAsync.when(
                    data: (appList) {
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          childCount: appList.length,
                          (context, index) {
                            final app = appList[index];
                            final thumbnail = (app as ApplicationWithIcon).icon;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: IconButton(
                                onPressed: () async =>
                                    (apkParams.selectMultipleApps) ? _appSelection(app) : _pickApp(app),
                                icon: Row(
                                  children: [
                                    MemoryThumbnail(
                                      bytes: thumbnail,
                                      size: 60,
                                      fileType: FileType.apk,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            app.appName,
                                            maxLines: 1,
                                            overflow: TextOverflow.fade,
                                            softWrap: false,
                                          ),
                                          Consumer(
                                            builder: (context, ref) {
                                              final appSize = ref.watch(apkSizeProvider(app.apkFilePath));
                                              final appSizeString = appSize.maybeWhen(
                                                data: (size) => '${size.asReadableFileSize} • ',
                                                orElse: () => '',
                                              );
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '$appSizeString${app.versionName != null ? 'v${app.versionName}' : ''}',
                                                    style: FluentTheme.of(context).typography.caption,
                                                  ),
                                                  Text(
                                                    app.packageName,
                                                    style: FluentTheme.of(context).typography.caption,
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (apkParams.selectMultipleApps)
                                      Icon(
                                        _selectedApps.contains(app)
                                            ? FluentIcons.checkbox_checked_16_regular
                                            : FluentIcons.checkbox_unchecked_16_regular,
                                        color: _selectedApps.contains(app)
                                            ? FluentTheme.of(context).iconTheme.color
                                            : FluentTheme.of(context).autoGrey,
                                      )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    error: (e, st) {
                      return SliverToBoxAdapter(child: Text('Error: $e\n$st'));
                    },
                    loading: () {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: ProgressRing(),
                        ),
                      );
                    },
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: getNavBarPadding(context) + 50),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
