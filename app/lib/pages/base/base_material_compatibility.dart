import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as m;
import 'package:localsend_app/widget/fluent/window_buttons.dart';
import 'package:window_manager/window_manager.dart';

class BaseMaterialCompatibility extends StatelessWidget {
  final Widget body;
  final bool needMaterialApp;

  const BaseMaterialCompatibility({super.key, required this.body, this.needMaterialApp = false});

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    return NavigationView(
      appBar: NavigationAppBar(
        title: () {
          if (kIsWeb) return null;
          return DragToMoveArea(child: Container());
        }(),
        leading: needMaterialApp
            ? IconButton(
                icon: const Icon(FluentIcons.arrow_left_20_regular, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : const SizedBox.shrink(),
        actions: const WindowButtons(),
      ),
      content: needMaterialApp
          ? m.MaterialApp(
              theme: m.ThemeData(
                colorScheme: m.ColorScheme.fromSeed(
                  brightness: fTheme.brightness,
                  seedColor: fTheme.accentColor,
                ),
                brightness: fTheme.brightness,
              ),
              home: body,
            )
          : m.Material(
              child: m.Theme(
                data: m.ThemeData(
                  colorScheme: m.ColorScheme.fromSeed(
                    brightness: fTheme.brightness,
                    seedColor: fTheme.accentColor,
                  ),
                  brightness: fTheme.brightness,
                ),
                child: body,
              ),
            ),
    );
  }
}
