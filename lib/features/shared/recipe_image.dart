import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/models/enums.dart';

class RecipeImage extends StatelessWidget {
  const RecipeImage({
    super.key,
    this.image,
    this.mealType,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.label,
  });

  final String? image;
  final MealType? mealType;
  final double? width;
  final double? height;
  final double borderRadius;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final path = image;
    final Widget child;
    if (path == null || path.isEmpty) {
      child = _Placeholder(mealType: mealType, label: label);
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      child = Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _Placeholder(mealType: mealType, label: label),
      );
    } else if (path.startsWith('assets/')) {
      child = Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _Placeholder(mealType: mealType, label: label),
      );
    } else {
      child = Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _Placeholder(mealType: mealType, label: label),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.mealType, this.label});

  final MealType? mealType;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, colors) = switch (mealType) {
      MealType.breakfast => (
        Icons.free_breakfast_outlined,
        [scheme.secondaryContainer, scheme.tertiaryContainer],
      ),
      MealType.lunch => (
        Icons.lunch_dining_outlined,
        [scheme.primaryContainer, scheme.secondaryContainer],
      ),
      MealType.dinner => (
        Icons.dinner_dining_outlined,
        [scheme.tertiaryContainer, scheme.primaryContainer],
      ),
      MealType.snack => (
        Icons.emoji_food_beverage_outlined,
        [scheme.surfaceContainerHigh, scheme.secondaryContainer],
      ),
      null => (
        Icons.restaurant_outlined,
        [scheme.surfaceContainerHigh, scheme.surfaceContainerHighest],
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: Icon(icon, color: scheme.onPrimaryContainer, size: 28)),
          if (label != null && label!.isNotEmpty)
            Positioned(
              left: 5,
              right: 5,
              bottom: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
