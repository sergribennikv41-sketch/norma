import 'package:flutter/material.dart';

import '../../core/theme/theme_controller.dart';

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeControllerScope.maybeOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      onPressed: controller == null ? null : () => controller.toggle(),
      tooltip: dark ? 'Светлая тема' : 'Тёмная тема',
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}
