import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/base/base_normal_page.dart';
import 'package:localsend_app/provider/security_provider.dart';
import 'package:localsend_app/util/fingerprint_alphabet.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:localsend_isolates/model/device.dart';
import 'package:refena_flutter/refena_flutter.dart';

enum _VerifyMode {
  icons,
  raw,
}

/// Verifies the identity of a discovered device by comparing the fingerprints
/// of both sides.
class VerifyPage extends StatefulWidget {
  final Device device;

  const VerifyPage({required this.device});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  _VerifyMode _mode = _VerifyMode.icons;

  @override
  Widget build(BuildContext context) {
    final myFingerprint = context.ref.watch(securityProvider.select((s) => s.certificateHash));
    final fingerprints = [myFingerprint, widget.device.fingerprint]..sort();
    final combined = fingerprints.join();
    return BaseNormalPage(
      windowTitle: t.verifyPage.title,
      headerTitle: t.verifyPage.title,
      body: ResponsiveListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        tabletPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModeButton(
                  checked: _mode == _VerifyMode.icons,
                  icon: FluentIcons.apps_16_regular,
                  label: t.verifyPage.icons,
                  onPressed: () => setState(() => _mode = _VerifyMode.icons),
                ),
                const SizedBox(width: 8),
                _ModeButton(
                  checked: _mode == _VerifyMode.raw,
                  icon: FluentIcons.code_16_regular,
                  label: t.verifyPage.raw,
                  onPressed: () => setState(() => _mode = _VerifyMode.raw),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          switch (_mode) {
            _VerifyMode.icons => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 304),
                child: Card(
                  padding: const EdgeInsets.all(24),
                  child: GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final icon in fingerprintToIcons(combined)) Center(child: Icon(icon, size: 32)),
                    ],
                  ),
                ),
              ),
            ),
            _VerifyMode.raw => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Card(
                  padding: const EdgeInsets.all(20),
                  child: SelectableText(combined, style: const TextStyle(fontFamily: 'RobotoMono', height: 1.6)),
                ),
              ),
            ),
          },
          const SizedBox(height: 20),
          Center(
            child: Text(
              t.verifyPage.question,
              textAlign: TextAlign.center,
              style: FluentTheme.of(context).typography.bodyStrong?.copyWith(color: FluentTheme.of(context).resources.textFillColorSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final bool checked;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ModeButton({required this.checked, required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: ToggleButton(
        checked: checked,
        onChanged: (_) => onPressed(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
