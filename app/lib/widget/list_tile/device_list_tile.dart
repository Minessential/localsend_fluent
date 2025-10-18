import 'package:common/model/device.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/util/device_type_ext.dart';
import 'package:localsend_app/util/ip_helper.dart';
import 'package:localsend_app/widget/custom_progress_bar.dart';
import 'package:localsend_app/widget/device_bage.dart';
import 'package:localsend_app/widget/list_tile/custom_list_tile.dart';

class DeviceListTile extends StatelessWidget {
  final Device device;
  final bool isFavorite;

  /// If not null, this name is used instead of [Device.alias].
  /// This is the case when the device is marked as favorite.
  final String? nameOverride;

  final String? info;
  final double? progress;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  const DeviceListTile({
    required this.device,
    this.isFavorite = false,
    this.nameOverride,
    this.info,
    this.progress,
    this.onTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = Color.lerp(FluentTheme.of(context).accentColor, Colors.white, 0.3)!;
    return CustomListTile(
      icon: Icon(device.deviceType.icon, size: 46),
      title: Text(nameOverride ?? device.alias, style: const TextStyle(fontSize: 20)),
      trailing: onFavoriteTap != null
          ? IconButton(
              icon: Icon(isFavorite ? FluentIcons.star_20_filled : FluentIcons.star_20_regular, size: 18),
              onPressed: onFavoriteTap,
            )
          : null,
      subTitle: Wrap(
        runSpacing: 10,
        spacing: 10,
        children: [
          if (info != null)
            Text(info!, style: TextStyle(color: FluentTheme.of(context).autoGrey))
          else if (progress != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: CustomProgressBar(progress: progress! * 100),
            )
          else ...[
            if (device.ip != null)
              DeviceBadge(
                backgroundColor: badgeColor,
                foregroundColor: FluentTheme.of(context).resources.textFillColorPrimary,
                label: 'LAN • HTTP',
              )
            else
              DeviceBadge(
                backgroundColor: badgeColor,
                foregroundColor: FluentTheme.of(context).resources.textFillColorPrimary,
                label: 'WebRTC',
              ),
            if (device.deviceModel != null)
              DeviceBadge(
                backgroundColor: badgeColor,
                foregroundColor: FluentTheme.of(context).resources.textFillColorPrimary,
                label: device.deviceModel!,
              ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
