import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/pages/base/base_normal_page.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/fluent/custom_text_box.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';

final _logger = Logger('Init');

/// Shows an alternative app if the initialization failed.
void showInitErrorApp({
  required Object error,
  required StackTrace stackTrace,
}) async {
  _logger.severe('Error during init', error, stackTrace);

  if (checkPlatformIsDesktop()) {
    await WindowManager.instance.ensureInitialized();
    await WindowManager.instance.show();
  }

  runApp(_ErrorApp(
    error: error,
    stackTrace: stackTrace,
  ));
}

class _ErrorApp extends StatefulWidget {
  final Object error;
  final StackTrace stackTrace;

  const _ErrorApp({
    required this.error,
    required this.stackTrace,
  });

  @override
  State<_ErrorApp> createState() => _ErrorAppState();
}

class _ErrorAppState extends State<_ErrorApp> {
  final _controller = TextEditingController();
  String? version;

  @override
  void initState() {
    super.initState();

    _controller.text = 'Error: ${widget.error}\n\n${widget.stackTrace}';
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final info = await PackageInfo.fromPlatform();
      _controller.text =
          'LocalSend ${info.version} (${info.buildNumber})\n\nError: ${widget.error}\n\n${widget.stackTrace}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'LocalSend: Error',
      debugShowCheckedModeBanner: false,
      home: BaseNormalPage(
        windowLeadingType: WindowLeadingType.appLogo,
        windowTitle: 'LocalSend: Error',
        headerTitle: 'LocalSend: Error',
        body: Container(
          padding: const EdgeInsets.all(10.0),
          child: CustomTextBox(
            controller: _controller,
            maxLines: null,
            readOnly: true,
          ),
        ),
      ),
    );
  }
}
