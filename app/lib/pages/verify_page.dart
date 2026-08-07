import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/base/base_normal_page.dart';
import 'package:localsend_app/provider/security_provider.dart';
import 'package:localsend_app/util/fingerprint_alphabet.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:refena_flutter/refena_flutter.dart';

class CombinedFingerprint {
  final String combined;
  final List<IconData> icons;

  CombinedFingerprint({
    required this.combined,
    required this.icons,
  });

  factory CombinedFingerprint.load(BuildContext context, String fingerprint) {
    final myFingerprint = context.read(securityProvider.select((s) => s.certificateHash));
    final fingerprints = [myFingerprint, fingerprint]..sort();
    final combined = fingerprints.join();
    final icons = fingerprintToIcons(combined);
    return CombinedFingerprint(
      combined: combined,
      icons: icons,
    );
  }
}

enum VerifyMode {
  icons,
  raw,
}

/// Verifies the identity of a discovered device by comparing the fingerprints
/// of both sides.
class VerifyPage extends StatefulWidget {
  final CombinedFingerprint fingerprint;

  const VerifyPage({required this.fingerprint});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  VerifyMode _mode = VerifyMode.icons;

  @override
  Widget build(BuildContext context) {
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
                  checked: _mode == VerifyMode.icons,
                  icon: FluentIcons.apps_16_regular,
                  label: t.verifyPage.icons,
                  onPressed: () => setState(() => _mode = VerifyMode.icons),
                ),
                const SizedBox(width: 8),
                _ModeButton(
                  checked: _mode == VerifyMode.raw,
                  icon: FluentIcons.code_16_regular,
                  label: t.verifyPage.raw,
                  onPressed: () => setState(() => _mode = VerifyMode.raw),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          VerifyWidget(
            mode: _mode,
            fingerprint: widget.fingerprint,
          ),
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

class VerifyWidget extends StatelessWidget {
  final VerifyMode mode;
  final CombinedFingerprint fingerprint;

  const VerifyWidget({
    required this.mode,
    required this.fingerprint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        switch (mode) {
          VerifyMode.icons => Center(
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
                    for (final icon in fingerprint.icons) Icon(icon, size: 32),
                  ],
                ),
              ),
            ),
          ),
          VerifyMode.raw => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Card(
                padding: const EdgeInsets.all(20),
                child: SelectableText(fingerprint.combined),
              ),
            ),
          ),
        },
      ],
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
