import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/widget/dialogs/custom_bottom_sheet.dart';
import 'package:localsend_app/widget/fluent/custom_icon_label_button.dart';
import 'package:routerino/routerino.dart';
import 'package:system_settings_2/system_settings_2.dart';

class IosLocalNetworkDialog extends StatelessWidget {
  const IosLocalNetworkDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      title: t.dialogs.localNetworkUnauthorized.title,
      description: t.dialogs.localNetworkUnauthorized.description,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CustomIconLabelButton(
            ButtonType.filled,
            onPressed: () async => SystemSettings.app(),
            icon: const Icon(FluentIcons.settings_16_regular, size: 10),
            label: Text(t.dialogs.localNetworkUnauthorized.gotoSettings),
          ),
          Button(
            onPressed: () => context.pop(),
            child: Text(t.general.close),
          ),
        ],
      ),
    );
  }
}
