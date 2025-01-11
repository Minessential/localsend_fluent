
import 'package:fluent_ui/fluent_ui.dart';

class LoadingDialog extends StatelessWidget {
  const LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: Center(
        child: ProgressRing(),
      ),
    );
  }
}
