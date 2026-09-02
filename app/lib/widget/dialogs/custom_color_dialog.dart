import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:refena_flutter/addons.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class CustomColorDialog extends StatefulWidget {
  final Color initialColor;

  const CustomColorDialog({required this.initialColor});

  @override
  State<CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<CustomColorDialog> {
  late Color _color = widget.initialColor;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: kDefaultContentDialogConstraints.copyWith(maxWidth: 390),
      title: Text(t.settingsTab.general.colorOptions.custom),
      content: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ColorPicker(
          color: _color,
          onChanged: (color) => setState(() => _color = color),
          isAlphaEnabled: false,
          isAlphaSliderVisible: false,
          isAlphaTextInputVisible: false,
        ),
      ),
      actions: [
        Button(
          onPressed: () => context.pop(),
          child: Text(t.general.cancel),
        ),
        FilledButton(
          onPressed: () => context.global.dispatch(NavigateAction.pop(_color)),
          child: Text(t.general.confirm),
        ),
      ],
    );
  }
}
