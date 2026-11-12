import 'package:flutter/material.dart';

import '../../core/models/retail.dart';
import '../../core/models/user_profile.dart';
import '../../core/price/price_lookup.dart';
import '../../core/theme/theme_controller.dart';

enum HomeSection { plan, catalog, shopping, profile }

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.section,
    required this.profile,
    required this.onSelect,
    required this.onEditProfile,
  });

  final HomeSection section;
  final UserProfile profile;
  final ValueChanged<HomeSection> onSelect;
  final VoidCallback onEditProfile;

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
    final border = dark ? const Color(0xFF253127) : const Color(0x33FFFFFF);

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
              _NavItem(
                icon: Icons.calendar_month_outlined,
                label: 'Рацион',
                selected: section == HomeSection.plan,
                muted: muted,
                foreground: foreground,
                activeBackground: activeBackground,
                activeForeground: activeForeground,
                onTap: () => onSelect(HomeSection.plan),
              ),
              _NavItem(
                icon: Icons.menu_book_outlined,
                label: 'Каталог',
                selected: section == HomeSection.catalog,
                muted: muted,
                foreground: foreground,
                activeBackground: activeBackground,
                activeForeground: activeForeground,
                onTap: () => onSelect(HomeSection.catalog),
              ),
              _NavItem(
                icon: Icons.shopping_bag_outlined,
                label: 'Покупки',
                selected: section == HomeSection.shopping,
                muted: muted,
                foreground: foreground,
                activeBackground: activeBackground,
                activeForeground: activeForeground,
                onTap: () => onSelect(HomeSection.shopping),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Профиль',
                selected: section == HomeSection.profile,
                muted: muted,
                foreground: foreground,
                activeBackground: activeBackground,
                activeForeground: activeForeground,
                onTap: () => onSelect(HomeSection.profile),
              ),
              const SizedBox(height: 28),
              const _SidebarThemeSwitch(),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0xFF111813)
                      : const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ваш профиль',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.goal.label} · ${profile.mealsPerDay} приёма пищи\n'
                      '${retailCityById(profile.cityId).name}',
                      style: TextStyle(color: muted, fontSize: 11, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: onEditProfile,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: foreground,
                        side: BorderSide(color: border),
                        minimumSize: const Size.fromHeight(34),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Настроить профиль'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        color: selected ? activeBackground : Colors.transparent,
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
      child: Row(
        children: [
          Expanded(
            child: _ThemeOption(
              label: 'Светлая',
              active: !dark,
              background: active,
              foreground: activeText,
              muted: muted,
              onTap: () => controller.setMode(ThemeMode.light),
            ),
          ),
          Expanded(
            child: _ThemeOption(
              label: 'Тёмная',
              active: dark,
              background: active,
              foreground: activeText,
              muted: muted,
              onTap: () => controller.setMode(ThemeMode.dark),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.active,
    required this.background,
    required this.foreground,
    required this.muted,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color background;
  final Color foreground;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: active ? background : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? foreground : muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
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
