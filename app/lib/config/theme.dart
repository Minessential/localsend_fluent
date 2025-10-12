import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/color_mode.dart';
import 'package:localsend_app/provider/device_info_provider.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/util/ui/dynamic_colors.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// On desktop, we need to add additional padding to achieve the same visual appearance as on mobile
double get desktopPaddingFix => checkPlatformIsDesktop() ? 8 : 0;

FluentThemeData getTheme(
  ColorMode colorMode,
  Brightness brightness,
  bool is10footScreen,
  DynamicColors? dynamicColors,
) {
  final accentColor = _determineAccentColor(colorMode, brightness, dynamicColors);

  // https://github.com/localsend/localsend/issues/52
  final String? fontFamily;
  if (checkPlatform([TargetPlatform.windows])) {
    fontFamily = switch (LocaleSettings.currentLocale) {
      AppLocale.ja => 'Yu Gothic UI',
      AppLocale.ko => 'Malgun Gothic',
      AppLocale.zhCn => 'Microsoft YaHei UI',
      AppLocale.zhHk || AppLocale.zhTw => 'Microsoft JhengHei UI',
      _ => 'Segoe UI Variable Display',
    };
  } else {
    fontFamily = null;
  }

  return FluentThemeData(
    accentColor: accentColor,
    brightness: brightness,
    visualDensity: VisualDensity.standard,
    focusTheme: FocusThemeData(
      glowFactor: is10footScreen ? 2.0 : 0.0,
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: Duration(milliseconds: 300),
      showDuration: Duration(milliseconds: 300),
    ),
    resources: brightness.isLight
        ? ResourceDictionary.light().copyWith(systemFillColorAttentionBackground: Color(0xFFf3f3f3))
        : ResourceDictionary.dark().copyWith(systemFillColorAttentionBackground: Color(0xFF202020)),
    buttonTheme: ButtonThemeData(
      defaultButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(brightness.isDark ? Colors.white : null),
        padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 2 + desktopPaddingFix)),
      ),
      filledButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(brightness.isDark ? Colors.white : null),
        padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 2 + desktopPaddingFix)),
      ),
      hyperlinkButtonStyle: ButtonStyle(
        padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 2 + desktopPaddingFix)),
      ),
    ),
    fontFamily: fontFamily,
  );
}

Future<void> updateSystemOverlayStyle(BuildContext context) async {
  final brightness = FluentTheme.of(context).brightness;
  await updateSystemOverlayStyleWithBrightness(brightness);
}

Future<void> updateSystemOverlayStyleWithBrightness(Brightness brightness) async {
  if (checkPlatform([TargetPlatform.android])) {
    // See https://github.com/flutter/flutter/issues/90098
    final darkMode = brightness == Brightness.dark;
    final androidSdkInt = RefenaScope.defaultRef.read(deviceInfoProvider).androidSdkInt ?? 0;
    final bool edgeToEdge = androidSdkInt >= 29;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); // ignore: unawaited_futures

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: brightness == Brightness.light ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: edgeToEdge ? Colors.transparent : (darkMode ? Colors.black : Colors.white),
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: darkMode ? Brightness.light : Brightness.dark,
    ));
  } else {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness: brightness, // iOS
      statusBarColor: Colors.transparent, // Not relevant to this issue
    ));
  }
}

// _determineColorScheme
AccentColor _determineAccentColor(ColorMode mode, Brightness brightness, DynamicColors? dynamicColors) {
  final isLight = brightness == Brightness.light;
  final defaultAccentColor = isLight
      ? Colors.teal.toAccentColor()
      : Colors.teal.toAccentColor(
          darkestFactor: 0.50,
          darkerFactor: 0.40,
          darkFactor: 0.25,
          lightFactor: 0.10,
          lighterFactor: 0.20,
          lightestFactor: 0.30,
        );

  final accentColor = switch (mode) {
    ColorMode.system => isLight ? dynamicColors?.light : dynamicColors?.dark,
    ColorMode.localsend => null,
    ColorMode.yellow => Colors.yellow,
    ColorMode.orange => Colors.orange,
    ColorMode.red => Colors.red,
    ColorMode.magenta => Colors.magenta,
    ColorMode.purple => Colors.purple,
    ColorMode.blue => Colors.blue,
    ColorMode.green => Colors.green,
  };

  return accentColor ?? defaultAccentColor;
}

extension FluentThemeDataExt on FluentThemeData {
  Color get autoGrey => brightness.isLight ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.5);
}

/// Get background color for cards
WidgetStateProperty<Color> getCardBackgroundColor(FluentThemeData theme) {
  return WidgetStateProperty.resolveWith<Color>((states) {
    final color = theme.resources.cardBackgroundFillColorDefault;
    if (states.contains(WidgetState.hovered)) {
      return color.withValues(alpha: 0.1);
    }
    if (states.contains(WidgetState.pressed)) {
      return color.withValues(alpha: 0.2);
    }
    return color;
  });
}

extension ResourceDictionaryExt on ResourceDictionary {
  /// Copy the current [ResourceDictionary] with the provided values.
  /// can access by `FluentTheme.of(context).resources.copyWith(...)`
  ResourceDictionary copyWith({
    Color? textFillColorPrimary,
    Color? textFillColorSecondary,
    Color? textFillColorTertiary,
    Color? textFillColorDisabled,
    Color? textFillColorInverse,
    Color? accentTextFillColorDisabled,
    Color? textOnAccentFillColorSelectedText,
    Color? textOnAccentFillColorPrimary,
    Color? textOnAccentFillColorSecondary,
    Color? textOnAccentFillColorDisabled,
    Color? controlFillColorDefault,
    Color? controlFillColorSecondary,
    Color? controlFillColorTertiary,
    Color? controlFillColorDisabled,
    Color? controlFillColorTransparent,
    Color? controlFillColorInputActive,
    Color? controlStrongFillColorDefault,
    Color? controlStrongFillColorDisabled,
    Color? controlSolidFillColorDefault,
    Color? subtleFillColorTransparent,
    Color? subtleFillColorSecondary,
    Color? subtleFillColorTertiary,
    Color? subtleFillColorDisabled,
    Color? controlAltFillColorTransparent,
    Color? controlAltFillColorSecondary,
    Color? controlAltFillColorTertiary,
    Color? controlAltFillColorQuarternary,
    Color? controlAltFillColorDisabled,
    Color? controlOnImageFillColorDefault,
    Color? controlOnImageFillColorSecondary,
    Color? controlOnImageFillColorTertiary,
    Color? controlOnImageFillColorDisabled,
    Color? accentFillColorDisabled,
    Color? controlStrokeColorDefault,
    Color? controlStrokeColorSecondary,
    Color? controlStrokeColorOnAccentDefault,
    Color? controlStrokeColorOnAccentSecondary,
    Color? controlStrokeColorOnAccentTertiary,
    Color? controlStrokeColorOnAccentDisabled,
    Color? controlStrokeColorForStrongFillWhenOnImage,
    Color? cardStrokeColorDefault,
    Color? cardStrokeColorDefaultSolid,
    Color? controlStrongStrokeColorDefault,
    Color? controlStrongStrokeColorDisabled,
    Color? surfaceStrokeColorDefault,
    Color? surfaceStrokeColorFlyout,
    Color? surfaceStrokeColorInverse,
    Color? dividerStrokeColorDefault,
    Color? focusStrokeColorOuter,
    Color? focusStrokeColorInner,
    Color? cardBackgroundFillColorDefault,
    Color? cardBackgroundFillColorSecondary,
    Color? smokeFillColorDefault,
    Color? layerFillColorDefault,
    Color? layerFillColorAlt,
    Color? layerOnAcrylicFillColorDefault,
    Color? layerOnAccentAcrylicFillColorDefault,
    Color? layerOnMicaBaseAltFillColorDefault,
    Color? layerOnMicaBaseAltFillColorSecondary,
    Color? layerOnMicaBaseAltFillColorTertiary,
    Color? layerOnMicaBaseAltFillColorTransparent,
    Color? solidBackgroundFillColorBase,
    Color? solidBackgroundFillColorSecondary,
    Color? solidBackgroundFillColorTertiary,
    Color? solidBackgroundFillColorQuarternary,
    Color? solidBackgroundFillColorTransparent,
    Color? solidBackgroundFillColorBaseAlt,
    Color? systemFillColorSuccess,
    Color? systemFillColorCaution,
    Color? systemFillColorCritical,
    Color? systemFillColorNeutral,
    Color? systemFillColorSolidNeutral,
    Color? systemFillColorAttentionBackground,
    Color? systemFillColorSuccessBackground,
    Color? systemFillColorCautionBackground,
    Color? systemFillColorCriticalBackground,
    Color? systemFillColorNeutralBackground,
    Color? systemFillColorSolidAttentionBackground,
    Color? systemFillColorSolidNeutralBackground,
  }) {
    return ResourceDictionary.raw(
      textFillColorPrimary: textFillColorPrimary ?? this.textFillColorPrimary,
      textFillColorSecondary: textFillColorSecondary ?? this.textFillColorSecondary,
      textFillColorTertiary: textFillColorTertiary ?? this.textFillColorTertiary,
      textFillColorDisabled: textFillColorDisabled ?? this.textFillColorDisabled,
      textFillColorInverse: textFillColorInverse ?? this.textFillColorInverse,
      accentTextFillColorDisabled: accentTextFillColorDisabled ?? this.accentTextFillColorDisabled,
      textOnAccentFillColorSelectedText: textOnAccentFillColorSelectedText ?? this.textOnAccentFillColorSelectedText,
      textOnAccentFillColorPrimary: textOnAccentFillColorPrimary ?? this.textOnAccentFillColorPrimary,
      textOnAccentFillColorSecondary: textOnAccentFillColorSecondary ?? this.textOnAccentFillColorSecondary,
      textOnAccentFillColorDisabled: textOnAccentFillColorDisabled ?? this.textOnAccentFillColorDisabled,
      controlFillColorDefault: controlFillColorDefault ?? this.controlFillColorDefault,
      controlFillColorSecondary: controlFillColorSecondary ?? this.controlFillColorSecondary,
      controlFillColorTertiary: controlFillColorTertiary ?? this.controlFillColorTertiary,
      controlFillColorDisabled: controlFillColorDisabled ?? this.controlFillColorDisabled,
      controlFillColorTransparent: controlFillColorTransparent ?? this.controlFillColorTransparent,
      controlFillColorInputActive: controlFillColorInputActive ?? this.controlFillColorInputActive,
      controlStrongFillColorDefault: controlStrongFillColorDefault ?? this.controlStrongFillColorDefault,
      controlStrongFillColorDisabled: controlStrongFillColorDisabled ?? this.controlStrongFillColorDisabled,
      controlSolidFillColorDefault: controlSolidFillColorDefault ?? this.controlSolidFillColorDefault,
      subtleFillColorTransparent: subtleFillColorTransparent ?? this.subtleFillColorTransparent,
      subtleFillColorSecondary: subtleFillColorSecondary ?? this.subtleFillColorSecondary,
      subtleFillColorTertiary: subtleFillColorTertiary ?? this.subtleFillColorTertiary,
      subtleFillColorDisabled: subtleFillColorDisabled ?? this.subtleFillColorDisabled,
      controlAltFillColorTransparent: controlAltFillColorTransparent ?? this.controlAltFillColorTransparent,
      controlAltFillColorSecondary: controlAltFillColorSecondary ?? this.controlAltFillColorSecondary,
      controlAltFillColorTertiary: controlAltFillColorTertiary ?? this.controlAltFillColorTertiary,
      controlAltFillColorQuarternary: controlAltFillColorQuarternary ?? this.controlAltFillColorQuarternary,
      controlAltFillColorDisabled: controlAltFillColorDisabled ?? this.controlAltFillColorDisabled,
      controlOnImageFillColorDefault: controlOnImageFillColorDefault ?? this.controlOnImageFillColorDefault,
      controlOnImageFillColorSecondary: controlOnImageFillColorSecondary ?? this.controlOnImageFillColorSecondary,
      controlOnImageFillColorTertiary: controlOnImageFillColorTertiary ?? this.controlOnImageFillColorTertiary,
      controlOnImageFillColorDisabled: controlOnImageFillColorDisabled ?? this.controlOnImageFillColorDisabled,
      accentFillColorDisabled: accentFillColorDisabled ?? this.accentFillColorDisabled,
      controlStrokeColorDefault: controlStrokeColorDefault ?? this.controlStrokeColorDefault,
      controlStrokeColorSecondary: controlStrokeColorSecondary ?? this.controlStrokeColorSecondary,
      controlStrokeColorOnAccentDefault: controlStrokeColorOnAccentDefault ?? this.controlStrokeColorOnAccentDefault,
      controlStrokeColorOnAccentSecondary:
          controlStrokeColorOnAccentSecondary ?? this.controlStrokeColorOnAccentSecondary,
      controlStrokeColorOnAccentTertiary: controlStrokeColorOnAccentTertiary ?? this.controlStrokeColorOnAccentTertiary,
      controlStrokeColorOnAccentDisabled: controlStrokeColorOnAccentDisabled ?? this.controlStrokeColorOnAccentDisabled,
      controlStrokeColorForStrongFillWhenOnImage:
          controlStrokeColorForStrongFillWhenOnImage ?? this.controlStrokeColorForStrongFillWhenOnImage,
      cardStrokeColorDefault: cardStrokeColorDefault ?? this.cardStrokeColorDefault,
      cardStrokeColorDefaultSolid: cardStrokeColorDefaultSolid ?? this.cardStrokeColorDefaultSolid,
      controlStrongStrokeColorDefault: controlStrongStrokeColorDefault ?? this.controlStrongStrokeColorDefault,
      controlStrongStrokeColorDisabled: controlStrongStrokeColorDisabled ?? this.controlStrongStrokeColorDisabled,
      surfaceStrokeColorDefault: surfaceStrokeColorDefault ?? this.surfaceStrokeColorDefault,
      surfaceStrokeColorFlyout: surfaceStrokeColorFlyout ?? this.surfaceStrokeColorFlyout,
      surfaceStrokeColorInverse: surfaceStrokeColorInverse ?? this.surfaceStrokeColorInverse,
      dividerStrokeColorDefault: dividerStrokeColorDefault ?? this.dividerStrokeColorDefault,
      focusStrokeColorOuter: focusStrokeColorOuter ?? this.focusStrokeColorOuter,
      focusStrokeColorInner: focusStrokeColorInner ?? this.focusStrokeColorInner,
      cardBackgroundFillColorDefault: cardBackgroundFillColorDefault ?? this.cardBackgroundFillColorDefault,
      cardBackgroundFillColorSecondary: cardBackgroundFillColorSecondary ?? this.cardBackgroundFillColorSecondary,
      smokeFillColorDefault: smokeFillColorDefault ?? this.smokeFillColorDefault,
      layerFillColorDefault: layerFillColorDefault ?? this.layerFillColorDefault,
      layerFillColorAlt: layerFillColorAlt ?? this.layerFillColorAlt,
      layerOnAcrylicFillColorDefault: layerOnAcrylicFillColorDefault ?? this.layerOnAcrylicFillColorDefault,
      layerOnAccentAcrylicFillColorDefault:
          layerOnAccentAcrylicFillColorDefault ?? this.layerOnAccentAcrylicFillColorDefault,
      layerOnMicaBaseAltFillColorDefault: layerOnMicaBaseAltFillColorDefault ?? this.layerOnMicaBaseAltFillColorDefault,
      layerOnMicaBaseAltFillColorSecondary:
          layerOnMicaBaseAltFillColorSecondary ?? this.layerOnMicaBaseAltFillColorSecondary,
      layerOnMicaBaseAltFillColorTertiary:
          layerOnMicaBaseAltFillColorTertiary ?? this.layerOnMicaBaseAltFillColorTertiary,
      layerOnMicaBaseAltFillColorTransparent:
          layerOnMicaBaseAltFillColorTransparent ?? this.layerOnMicaBaseAltFillColorTransparent,
      solidBackgroundFillColorBase: solidBackgroundFillColorBase ?? this.solidBackgroundFillColorBase,
      solidBackgroundFillColorSecondary: solidBackgroundFillColorSecondary ?? this.solidBackgroundFillColorSecondary,
      solidBackgroundFillColorTertiary: solidBackgroundFillColorTertiary ?? this.solidBackgroundFillColorTertiary,
      solidBackgroundFillColorQuarternary:
          solidBackgroundFillColorQuarternary ?? this.solidBackgroundFillColorQuarternary,
      solidBackgroundFillColorTransparent:
          solidBackgroundFillColorTransparent ?? this.solidBackgroundFillColorTransparent,
      solidBackgroundFillColorBaseAlt: solidBackgroundFillColorBaseAlt ?? this.solidBackgroundFillColorBaseAlt,
      systemFillColorSuccess: systemFillColorSuccess ?? this.systemFillColorSuccess,
      systemFillColorCaution: systemFillColorCaution ?? this.systemFillColorCaution,
      systemFillColorCritical: systemFillColorCritical ?? this.systemFillColorCritical,
      systemFillColorNeutral: systemFillColorNeutral ?? this.systemFillColorNeutral,
      systemFillColorSolidNeutral: systemFillColorSolidNeutral ?? this.systemFillColorSolidNeutral,
      systemFillColorAttentionBackground: systemFillColorAttentionBackground ?? this.systemFillColorAttentionBackground,
      systemFillColorSuccessBackground: systemFillColorSuccessBackground ?? this.systemFillColorSuccessBackground,
      systemFillColorCautionBackground: systemFillColorCautionBackground ?? this.systemFillColorCautionBackground,
      systemFillColorCriticalBackground: systemFillColorCriticalBackground ?? this.systemFillColorCriticalBackground,
      systemFillColorNeutralBackground: systemFillColorNeutralBackground ?? this.systemFillColorNeutralBackground,
      systemFillColorSolidAttentionBackground:
          systemFillColorSolidAttentionBackground ?? this.systemFillColorSolidAttentionBackground,
      systemFillColorSolidNeutralBackground:
          systemFillColorSolidNeutralBackground ?? this.systemFillColorSolidNeutralBackground,
    );
  }
}
