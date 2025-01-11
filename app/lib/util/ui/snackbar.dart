import 'package:fluent_ui/fluent_ui.dart';

extension SnackbarExt on BuildContext {
  void showSnackBar(String text) async {
    await displayInfoBar(this, duration: Duration(milliseconds: 1800), builder: (_, __) => InfoBar(title: Text(text)));
  }
}
