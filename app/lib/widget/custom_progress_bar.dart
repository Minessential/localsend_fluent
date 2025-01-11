import 'package:fluent_ui/fluent_ui.dart';

class CustomProgressBar extends StatelessWidget {
  final double? progress;
  final double borderRadius;
  final Color? color;

  const CustomProgressBar({required this.progress, this.borderRadius = 10, this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ProgressBar(value: progress),
    );
  }
}
