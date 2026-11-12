import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(
    scheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F7D55),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF2F7D55),
          onPrimary: const Color(0xFFF8FFF8),
          primaryContainer: const Color(0xFFE2EFE5),
          onPrimaryContainer: const Color(0xFF173A2C),
          secondary: const Color(0xFFB86B3C),
          onSecondary: const Color(0xFFFFFFFF),
          secondaryContainer: const Color(0xFFF6E3D5),
          onSecondaryContainer: const Color(0xFF4E2E1D),
          surface: const Color(0xFFFFFDF9),
          onSurface: const Color(0xFF1D2A23),
          surfaceContainerLowest: const Color(0xFFF7F3EC),
          surfaceContainerLow: const Color(0xFFFBF8F2),
          surfaceContainer: const Color(0xFFFFFDF9),
          surfaceContainerHigh: const Color(0xFFF1ECE2),
          surfaceContainerHighest: const Color(0xFFEAE4D8),
          onSurfaceVariant: const Color(0xFF718077),
          outline: const Color(0xFFCFC4B3),
          outlineVariant: const Color(0xFFE1DACD),
          error: const Color(0xFFB3261E),
        ),
    dark: false,
  );

  static ThemeData get dark => _build(
    scheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFC9F56A),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFC9F56A),
          onPrimary: const Color(0xFF10170E),
          primaryContainer: const Color(0xFF27361F),
          onPrimaryContainer: const Color(0xFFEDF5EE),
          secondary: const Color(0xFF7ED0A5),
          onSecondary: const Color(0xFF0B1A12),
          secondaryContainer: const Color(0xFF1D3527),
          onSecondaryContainer: const Color(0xFFD7F7E1),
          surface: const Color(0xFF151C17),
          onSurface: const Color(0xFFEDF5EE),
          surfaceContainerLowest: const Color(0xFF0E1310),
          surfaceContainerLow: const Color(0xFF111813),
          surfaceContainer: const Color(0xFF151C17),
          surfaceContainerHigh: const Color(0xFF1D2620),
          surfaceContainerHighest: const Color(0xFF263128),
          onSurfaceVariant: const Color(0xFF8A9B8E),
          outline: const Color(0xFF3A4A3C),
          outlineVariant: const Color(0xFF253127),
          error: const Color(0xFFFFB4AB),
          onError: const Color(0xFF690005),
        ),
    dark: true,
  );

  static ThemeData _build({required ColorScheme scheme, required bool dark}) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'GolosText',
    );
    final textTheme = base.textTheme.copyWith(
      displayLarge: _display(base.textTheme.displayLarge),
      displayMedium: _display(base.textTheme.displayMedium),
      displaySmall: _display(base.textTheme.displaySmall),
      headlineLarge: _display(base.textTheme.headlineLarge),
      headlineMedium: _display(base.textTheme.headlineMedium),
      headlineSmall: _display(base.textTheme.headlineSmall),
      titleLarge: _display(base.textTheme.titleLarge),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.5),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
      bodySmall: base.textTheme.bodySmall?.copyWith(height: 1.4),
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Unbounded',
          fontSize: 19,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: TextStyle(
          color: scheme.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: const TextStyle(
            fontFamily: 'GolosText',
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
          minimumSize: const Size(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: const TextStyle(
            fontFamily: 'GolosText',
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'GolosText',
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        collapsedIconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        collapsedTextColor: scheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.primary : null,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 5,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(scheme.primary),
        trackColor: WidgetStatePropertyAll(scheme.primaryContainer),
        trackOutlineColor: WidgetStatePropertyAll(scheme.outlineVariant),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark
            ? scheme.surfaceContainerHighest
            : const Color(0xFF1D2A23),
        contentTextStyle: TextStyle(
          color: dark ? scheme.onSurface : const Color(0xFFF8FFF8),
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          scheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        radius: const Radius.circular(999),
      ),
    );
  }

  static TextStyle? _display(TextStyle? style) {
    return style?.copyWith(
      fontFamily: 'Unbounded',
      fontWeight: FontWeight.w600,
      letterSpacing: -1.1,
      height: 1.12,
    );
  }
}
