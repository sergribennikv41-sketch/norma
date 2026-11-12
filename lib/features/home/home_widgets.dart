import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/models/retail.dart';
import '../../core/models/user_profile.dart';
import '../../core/price/price_lookup.dart';
import '../../core/theme/theme_controller.dart';

enum HomeSection { plan, catalog, shopping, profile }

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key, required this.section, required this.onSelect});

  final HomeSection section;
  final ValueChanged<HomeSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF0A0F0B) : const Color(0xFF173A2C);
    final muted = dark ? const Color(0xFF7E9182) : const Color(0xFFA3B9AB);
    final activeBackground = dark
        ? const Color(0xFFC9F56A)
        : const Color(0xFFD8F0DF);
    final activeForeground = dark
        ? const Color(0xFF10170E)
        : const Color(0xFF173A2C);
    const foreground = Color(0xFFF1F7EF);

    return Container(
      width: 248,
      color: background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xFFC9F56A)
                            : const Color(0xFFD8F0DF),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'н',
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: activeForeground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'норма',
                      style: TextStyle(
                        fontFamily: 'Unbounded',
                        color: foreground,
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'ПРИЛОЖЕНИЕ',
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 9),
              _SidebarNav(
                section: section,
                onSelect: onSelect,
                muted: muted,
                foreground: foreground,
                activeBackground: activeBackground,
                activeForeground: activeForeground,
              ),
              const SizedBox(height: 28),
              const _SidebarThemeSwitch(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNav extends StatelessWidget {
  const _SidebarNav({
    required this.section,
    required this.onSelect,
    required this.muted,
    required this.foreground,
    required this.activeBackground,
    required this.activeForeground,
  });

  static const _items = [
    (HomeSection.plan, Icons.calendar_month_outlined, 'Рацион'),
    (HomeSection.catalog, Icons.menu_book_outlined, 'Каталог'),
    (HomeSection.shopping, Icons.shopping_bag_outlined, 'Покупки'),
    (HomeSection.profile, Icons.person_outline, 'Профиль'),
  ];
  static const _height = 46.0;

  final HomeSection section;
  final ValueChanged<HomeSection> onSelect;
  final Color muted;
  final Color foreground;
  final Color activeBackground;
  final Color activeForeground;

  @override
  Widget build(BuildContext context) {
    final index = _items.indexWhere((item) => item.$1 == section);
    final safeIndex = index < 0 ? 0 : index;
    return SizedBox(
      height: _items.length * _height,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeOutCubic,
            top: safeIndex * _height + 5,
            left: 4,
            right: 4,
            height: 34,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: activeBackground.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: activeBackground.withValues(alpha: 0.22),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            top: safeIndex * _height,
            left: 0,
            right: 0,
            height: 40,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          activeBackground.withValues(alpha: 0.92),
                          activeBackground.withValues(alpha: 0.68),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: activeBackground.withValues(alpha: 0.28),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              for (final item in _items)
                _NavItem(
                  icon: item.$2,
                  label: item.$3,
                  selected: section == item.$1,
                  muted: muted,
                  foreground: foreground,
                  activeBackground: activeBackground,
                  activeForeground: activeForeground,
                  onTap: () => onSelect(item.$1),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.muted,
    required this.foreground,
    required this.activeBackground,
    required this.activeForeground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color muted;
  final Color foreground;
  final Color activeBackground;
  final Color activeForeground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? activeForeground : muted,
                ),
                const SizedBox(width: 11),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? activeForeground : muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarThemeSwitch extends StatelessWidget {
  const _SidebarThemeSwitch();

  @override
  Widget build(BuildContext context) {
    final controller = ThemeControllerScope.maybeOf(context);
    if (controller == null) {
      return const SizedBox.shrink();
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF111813) : const Color(0x14FFFFFF);
    final active = dark ? const Color(0xFFC9F56A) : const Color(0xFFD8F0DF);
    final activeText = dark ? const Color(0xFF10170E) : const Color(0xFF173A2C);
    final muted = dark ? const Color(0xFF7E9182) : const Color(0xFFA3B9AB);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: SizedBox(
        height: 30,
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              alignment: dark ? Alignment.centerRight : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              active.withValues(alpha: 0.92),
                              active.withValues(alpha: 0.68),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: active.withValues(alpha: 0.26),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _ThemeOption(
                    label: 'Светлая',
                    active: !dark,
                    foreground: activeText,
                    muted: muted,
                    onTap: () => controller.setMode(ThemeMode.light),
                  ),
                ),
                Expanded(
                  child: _ThemeOption(
                    label: 'Тёмная',
                    active: dark,
                    foreground: activeText,
                    muted: muted,
                    onTap: () => controller.setMode(ThemeMode.dark),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.active,
    required this.foreground,
    required this.muted,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color foreground;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(
            color: active ? foreground : muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class StoreChip extends StatelessWidget {
  const StoreChip({super.key, required this.profile, this.compact = false});

  final UserProfile profile;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '${storeChainById(profile.storeId).name} · '
            '${retailCityById(profile.cityId).name}',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.value,
    required this.label,
    required this.caption,
    this.size = 142,
    this.strokeWidth = 11,
  });

  final double value;
  final String label;
  final String caption;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value.clamp(0, 1),
              strokeWidth: strokeWidth,
              backgroundColor: scheme.surfaceContainerHighest,
              color: scheme.primary,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: size > 120 ? 26 : 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1.2,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                caption.toUpperCase(),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MacroTile extends StatelessWidget {
  const MacroTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PriceBadge extends StatelessWidget {
  const PriceBadge({super.key, required this.state});

  final PriceLookupState? state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = state;
    if (current == null) {
      return const SizedBox(width: 66);
    }
    return SizedBox(
      width: 66,
      child: Align(
        alignment: Alignment.centerRight,
        child: switch (current.status) {
          PriceLookupStatus.loading => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          PriceLookupStatus.found => Tooltip(
            message: [
              current.quote?.title ?? '',
              if (current.quote?.unit != null) current.quote!.unit!,
            ].where((item) => item.isNotEmpty).join(' · '),
            child: Text(
              '${current.quote!.price.round()} ₽',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PriceLookupStatus.notFound => Tooltip(
            message: 'Цена не найдена',
            child: Icon(
              Icons.remove_circle_outline,
              size: 17,
              color: scheme.outline,
            ),
          ),
          PriceLookupStatus.failed => Tooltip(
            message: current.message ?? 'Не удалось получить цену',
            child: Icon(Icons.error_outline, size: 17, color: scheme.error),
          ),
        },
      ),
    );
  }
}

class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.style,
  });

  final String text;
  final String query;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final normalizedText = _normalize(text);
    final normalizedQuery = _normalize(query.trim());
    if (normalizedQuery.isEmpty || !normalizedText.contains(normalizedQuery)) {
      return Text(text, style: style);
    }
    final spans = <TextSpan>[];
    var start = 0;
    while (start < text.length) {
      final index = normalizedText.indexOf(normalizedQuery, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + normalizedQuery.length),
          style: TextStyle(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = index + normalizedQuery.length;
    }
    return Text.rich(TextSpan(style: style, children: spans));
  }
}

String normalizeSearch(String value) => _normalize(value);

String _normalize(String value) {
  return value.toLowerCase().replaceAll('ё', 'е');
}

String pluralRu(int count, String one, String few, String many) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) {
    return one;
  }
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return few;
  }
  return many;
}
