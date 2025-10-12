import 'package:fluent_ui/fluent_ui.dart';

class UniversalScrollView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final double spacing;
  const UniversalScrollView({super.key, this.controller, this.spacing = 0, required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        controller: controller,
        physics: const BouncingScrollPhysics(),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1024),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: spacing, children: children),
          ),
        ),
      ),
    );
  }
}
