import 'dart:async';
import 'dart:typed_data';

import 'package:common/model/dto/file_dto.dart';
import 'package:common/model/file_status.dart';
import 'package:common/model/session_status.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/base/base_normal_page.dart';
import 'package:localsend_app/provider/network/send_provider.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/progress_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/file_size_helper.dart';
import 'package:localsend_app/util/file_speed_helper.dart';
import 'package:localsend_app/util/native/open_file.dart';
import 'package:localsend_app/util/native/open_folder.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/util/native/taskbar_helper.dart';
import 'package:localsend_app/util/ui/nav_bar_padding.dart';
import 'package:localsend_app/widget/custom_progress_bar.dart';
import 'package:localsend_app/widget/dialogs/cancel_session_dialog.dart';
import 'package:localsend_app/widget/dialogs/error_dialog.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';
import 'package:localsend_app/widget/fluent/card_ink_well.dart';
import 'package:localsend_app/widget/fluent/custom_icon_label_button.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class ProgressPage extends StatefulWidget {
  final bool showAppBar;
  final bool closeSessionOnClose;
  final String sessionId;

  const ProgressPage({
    required this.showAppBar,
    required this.closeSessionOnClose,
    required this.sessionId,
  });

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> with Refena {
  int _totalBytes = double.maxFinite.toInt();
  int _lastRemainingTimeUpdate = 0; // millis since epoch
  String? _remainingTime;
  List<FileDto> _files = []; // also contains declined files (files without token)
  Set<String> _selectedFiles = {};
  SessionStatus? _lastStatus;

  // If [autoFinish] is enabled, we wait a few seconds before automatically closing the session.
  int _finishCounter = 3;
  Timer? _finishTimer;
  Timer? _wakelockPlusTimer;

  bool _advanced = false;

  @override
  void initState() {
    super.initState();

    // init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        unawaited(WakelockPlus.enable());
      } catch (_) {}

      // Periodically call WakelockPlus.enable() to keep the screen awake
      _wakelockPlusTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        try {
          unawaited(WakelockPlus.enable());
        } catch (_) {}
      });

      if (ref.read(settingsProvider).autoFinish) {
        _finishTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          final finished = ref.read(serverProvider)?.session?.files.values.map((e) => e.status).isFinishedOrSkipped ??
              ref.read(sendProvider)[widget.sessionId]?.files.values.map((e) => e.status).isFinishedOrSkipped ??
              true;
          if (finished) {
            if (_finishCounter == 1) {
              timer.cancel();
              _exit(closeSession: true);
            } else {
              setState(() {
                _finishCounter--;
              });
            }
          }
        });
      }

      setState(() {
        final receiveSession = ref.read(serverProvider)?.session;
        if (receiveSession != null) {
          _files = receiveSession.files.values.map((f) => f.file).toList();

          // We previously used f.token != null here, but this may not work on very fast networks.
          _selectedFiles =
              receiveSession.files.values.where((f) => f.status != FileStatus.skipped).map((f) => f.file.id).toSet();
        } else {
          final sendSession = ref.read(sendProvider)[widget.sessionId];
          if (sendSession != null) {
            _files = sendSession.files.values.map((f) => f.file).toList();
            _selectedFiles =
                sendSession.files.values.where((f) => f.status != FileStatus.skipped).map((f) => f.file.id).toSet();
          }
        }

        _totalBytes = _files.where((f) => _selectedFiles.contains(f.id)).fold(0, (prev, curr) => prev + curr.size);
      });
    });
  }

  void _exit({required bool closeSession}) async {
    final receiveSession = ref.read(serverProvider.select((s) => s?.session));
    final sendSession = ref.read(sendProvider)[widget.sessionId];
    final SessionStatus? status = receiveSession?.status ?? sendSession?.status;
    final keepSession =
        !closeSession && (status == SessionStatus.sending || status == SessionStatus.finishedWithErrors);
    final result = status == null || keepSession || await _askCancelConfirmation(status);

    if (result && mounted) {
      // ignore: unawaited_futures
      context.popUntilRoot();
    }
  }

  Future<bool> _askCancelConfirmation(SessionStatus status) async {
    final bool result = switch (status == SessionStatus.sending) {
      true => await CancelSessionDialog.open(context),
      false => true,
    };
    if (result) {
      final receiveSession = ref.read(serverProvider)?.session;
      final sendState = ref.read(sendProvider)[widget.sessionId];

      if (receiveSession != null) {
        if (receiveSession.status == SessionStatus.sending) {
          ref.notifier(serverProvider).cancelSession();
        } else {
          ref.notifier(serverProvider).closeSession();
        }
      } else if (sendState != null) {
        if (sendState.status == SessionStatus.sending) {
          ref.notifier(sendProvider).cancelSession(widget.sessionId);
        } else {
          ref.notifier(sendProvider).closeSession(widget.sessionId);
        }
      }
    }
    return result;
  }

  @override
  void dispose() {
    super.dispose();
    _finishTimer?.cancel();
    _wakelockPlusTimer?.cancel();
    TaskbarHelper.clearProgressBar(); // ignore: discarded_futures
    try {
      WakelockPlus.disable(); // ignore: discarded_futures
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final progressNotifier = ref.watch(progressProvider);
    final currBytes = _files.fold<int>(
        0,
        (prev, curr) =>
            prev + ((progressNotifier.getProgress(sessionId: widget.sessionId, fileId: curr.id) * curr.size).round()));

    final receiveSession = ref.watch(serverProvider.select((s) => s?.session));
    final sendSession = ref.watch(sendProvider)[widget.sessionId];

    final SessionStatus? status = receiveSession?.status ?? sendSession?.status;

    if (status == SessionStatus.sending) {
      // ignore: discarded_futures
      TaskbarHelper.setProgressBar(currBytes, _totalBytes);
    } else if (status != _lastStatus) {
      _lastStatus = status;
      // ignore: discarded_futures
      TaskbarHelper.visualizeStatus(status);
    }

    if (status == null) {
      return BaseNormalPage(body: Container());
    }

    final title = receiveSession != null ? t.progressPage.titleReceiving : t.progressPage.titleSending;
    final startTime = receiveSession?.startTime ?? sendSession?.startTime;
    final endTime = receiveSession?.endTime ?? sendSession?.endTime;
    final int? speedInBytes;
    if (startTime != null && currBytes >= 500 * 1024) {
      speedInBytes =
          getFileSpeed(start: startTime, end: endTime ?? DateTime.now().millisecondsSinceEpoch, bytes: currBytes);

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastRemainingTimeUpdate >= 1000) {
        _remainingTime = getRemainingTime(bytesPerSeconds: speedInBytes, remainingBytes: _totalBytes - currBytes);
        _lastRemainingTimeUpdate = now;
      }
    } else {
      speedInBytes = null;
    }

    final fileStatusMap = receiveSession?.files.map((k, f) => MapEntry(k, f.status)) ??
        sendSession!.files.map((k, f) => MapEntry(k, f.status));
    final finishedCount = fileStatusMap.values.where((s) => s == FileStatus.finished).length;
    final theme = FluentTheme.of(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Already popped.
          // Because the user cannot pop this page, we can safely assume that all sessions are closed if they should be.
          return;
        }
        _exit(closeSession: widget.closeSessionOnClose);
      },
      canPop: false,
      child: BaseNormalPage(
        headerTitle: widget.showAppBar ? title : null,
        body: Column(children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 150 + getNavBarPadding(context),
                left: 15,
                right: 15,
              ),
              itemCount: _files.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  // title
                  if (widget.showAppBar) {
                    return Container();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.typography.title),
                        if (checkPlatformWithFileSystem() && receiveSession != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${t.settingsTab.receive.destination}: ',
                                    style: TextStyle(color: theme.autoGrey),
                                  ),
                                  TextSpan(
                                    text: receiveSession.destinationDirectory,
                                    style: TextStyle(
                                      color: checkPlatform([TargetPlatform.iOS]) ? theme.autoGrey : theme.accentColor,
                                    ),
                                    recognizer: checkPlatform([TargetPlatform.iOS])
                                        ? null
                                        : (TapGestureRecognizer()
                                          ..onTap = () async {
                                            await openFolder(folderPath: receiveSession.destinationDirectory);
                                          }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                if (index == 1) {
                  // error card
                  final errorMessage = sendSession?.errorMessage;
                  if (errorMessage == null) {
                    return Container();
                  }

                  return SelectableText(errorMessage, style: TextStyle(color: Colors.warningPrimaryColor));
                }

                final file = _files[index - 2];
                final String fileName = receiveSession?.files[file.id]?.desiredName ?? file.fileName;

                final fileStatus = fileStatusMap[file.id]!;
                final savedToGallery = receiveSession?.files[file.id]?.savedToGallery ?? false;

                final String? filePath;
                if (receiveSession != null && fileStatus == FileStatus.finished && !savedToGallery) {
                  filePath = receiveSession.files[file.id]!.path;
                } else if (sendSession != null) {
                  filePath = sendSession.files[file.id]!.path;
                } else {
                  filePath = null;
                }

                final String? errorMessage;
                if (receiveSession != null) {
                  errorMessage = receiveSession.files[file.id]!.errorMessage;
                } else if (sendSession != null) {
                  errorMessage = sendSession.files[file.id]!.errorMessage;
                } else {
                  errorMessage = null;
                }

                final Uint8List? thumbnail;
                final AssetEntity? asset;
                if (sendSession != null) {
                  thumbnail = sendSession.files[file.id]!.thumbnail;
                  asset = sendSession.files[file.id]!.asset;
                } else {
                  thumbnail = null;
                  asset = null;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: CardInkWell(
                    padding: EdgeInsets.all(10),
                    onPressed: filePath != null && receiveSession != null
                        ? () async => openFile(context, file.fileType, filePath!)
                        : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SmartFileThumbnail(
                          bytes: thumbnail,
                          asset: asset,
                          path: filePath,
                          fileType: file.fileType,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      fileName,
                                      style: const TextStyle(fontSize: 16, height: 1),
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                    ),
                                  ),
                                  Text(
                                    ' (${file.size.asReadableFileSize})',
                                    style: const TextStyle(fontSize: 16, height: 1),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (fileStatus == FileStatus.sending)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: CustomProgressBar(
                                    progress:
                                        progressNotifier.getProgress(sessionId: widget.sessionId, fileId: file.id) *
                                            100,
                                  ),
                                )
                              else
                                Row(children: [
                                  Flexible(
                                    child: Text(
                                      savedToGallery ? t.progressPage.savedToGallery : fileStatus.label,
                                      style: TextStyle(color: fileStatus.getColor(context), height: 1),
                                    ),
                                  ),
                                  if (errorMessage != null) ...[
                                    const SizedBox(width: 5),
                                    IconButton(
                                      onPressed: () async {
                                        await showDialog(
                                          context: context,
                                          builder: (_) => ErrorDialog(error: errorMessage!),
                                        );
                                      },
                                      icon: Icon(FluentIcons.info, color: Colors.warningPrimaryColor, size: 15),
                                    ),
                                  ],
                                ]),
                            ],
                          ),
                        ),
                        if (sendSession != null && fileStatus == FileStatus.failed)
                          Tooltip(
                            message: t.progressPage.retry,
                            child: IconButton(
                              icon: const Icon(FluentIcons.refresh),
                              onPressed: () async {
                                await ref.notifier(sendProvider).sendFile(
                                      sessionId: widget.sessionId,
                                      isolateIndex: 0,
                                      file: sendSession.files[file.id]!,
                                      isRetry: true,
                                    );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15, bottom: 5, top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          status.getLabel(remainingTime: _remainingTime ?? '-'),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 10),
                        CustomProgressBar(progress: _totalBytes == 0 ? 0 : 100 * currBytes / _totalBytes),
                        AnimatedCrossFade(
                          crossFadeState: _advanced ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                          alignment: Alignment.topLeft,
                          firstChild: Container(),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.progressPage.total.count(curr: finishedCount, n: _selectedFiles.length)),
                                Text(t.progressPage.total.size(
                                  curr: currBytes.asReadableFileSize,
                                  n: _totalBytes == double.maxFinite.toInt() ? '-' : _totalBytes.asReadableFileSize,
                                )),
                                if (speedInBytes != null)
                                  Text(t.progressPage.total.speed(speed: speedInBytes.asReadableFileSize)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CustomIconLabelButton(
                              ButtonType.inkwell,
                              onPressed: () {
                                setState(() => _advanced = !_advanced);
                              },
                              icon: Icon(
                                _advanced ? FluentIcons.chevron_up_med : FluentIcons.chevron_down_med,
                                size: 10,
                              ),
                              label: Text(_advanced ? t.general.hide : t.general.advanced),
                            ),
                            SizedBox(width: 10),
                            CustomIconLabelButton(
                              ButtonType.filled,
                              onPressed: () => _exit(closeSession: true),
                              icon: Icon(
                                  status == SessionStatus.sending
                                      ? FluentIcons.chrome_close
                                      : FluentIcons.accept_medium,
                                  size: 10),
                              label: Text(
                                status == SessionStatus.sending
                                    ? t.general.cancel
                                    : _finishTimer != null
                                        ? '${t.general.done} ($_finishCounter)'
                                        : t.general.done,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

extension on FileStatus {
  String get label {
    switch (this) {
      case FileStatus.queue:
        return t.general.queue;
      case FileStatus.skipped:
        return t.general.skipped;
      case FileStatus.sending:
        return ''; // progress bar will be showed here
      case FileStatus.failed:
        return t.general.error;
      case FileStatus.finished:
        return t.general.done;
    }
  }

  Color getColor(BuildContext context) {
    final theme = FluentTheme.of(context);
    switch (this) {
      case FileStatus.queue:
        return theme.accentColor;
      case FileStatus.skipped:
        return theme.autoGrey;
      case FileStatus.sending:
        return theme.accentColor;
      case FileStatus.failed:
        return Colors.warningPrimaryColor;
      case FileStatus.finished:
        return theme.accentColor;
    }
  }
}

extension on SessionStatus {
  String getLabel({required String remainingTime}) {
    switch (this) {
      case SessionStatus.sending:
        return t.progressPage.total.title.sending(
          time: remainingTime,
        );
      case SessionStatus.finished:
        return t.general.finished;
      case SessionStatus.finishedWithErrors:
        return t.progressPage.total.title.finishedError;
      case SessionStatus.canceledBySender:
        return t.progressPage.total.title.canceledSender;
      case SessionStatus.canceledByReceiver:
        return t.progressPage.total.title.canceledReceiver;
      default:
        return '';
    }
  }
}
