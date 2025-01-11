import 'package:dynamic_color/dynamic_color.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:refena_flutter/refena_flutter.dart';

class DynamicColors {
  final AccentColor light;
  final AccentColor dark;

  const DynamicColors({
    required this.light,
    required this.dark,
  });
}

final dynamicColorsProvider =
    Provider<DynamicColors?>((ref) => throw 'not initialized');

/// Returns the dynamic colors.
/// A copy of the dynamic_color_plugin implementation to retrieve the dynamic colors without a widget.
/// We need to replace [PlatformException] with a generic exception because on Windows 7 it is somehow not a [PlatformException].
Future<DynamicColors?> getDynamicColors() async {
  try {
    final accentColor = await DynamicColorPlugin.getAccentColor();
    if (accentColor != null) {
      debugPrint('dynamic_color: Accent color detected.');
      return DynamicColors(
        light: accentColor.toAccentColor(),
        dark: accentColor.toAccentColor(
          darkestFactor: 0.50,
          darkerFactor: 0.40,
          darkFactor: 0.25,
          lightFactor: 0.10,
          lighterFactor: 0.20,
          lightestFactor: 0.30,
        ),
      );
    }
  } catch (e) {
    debugPrint('dynamic_color: Failed to obtain accent color.');
  }

  return null;
}
