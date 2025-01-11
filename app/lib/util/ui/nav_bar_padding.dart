
import 'package:flutter/widgets.dart';

/// Since we use edge-to-edge mode on Android, the widgets may be hidden behind the navigation bar.
double getNavBarPadding(BuildContext context) {
  return MediaQuery.of(context).padding.bottom;
}
