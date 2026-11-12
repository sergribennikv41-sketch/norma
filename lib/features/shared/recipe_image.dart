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
    this.cacheWidth,
    this.cacheHeight,
    this.fallbackImage,
  });

  final String? image;
  final MealType? mealType;
  final double? width;
  final double? height;
  final double borderRadius;
  final String? label;
  final int? cacheWidth;
  final int? cacheHeight;
  final String? fallbackImage;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() {
      return _Placeholder(mealType: mealType, label: label);
    }

    Widget buildImage(String path, {bool allowFallback = true}) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return Image.network(
          path,
          fit: BoxFit.cover,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          filterQuality: FilterQuality.medium,
          headers: const {'Referer': 'https://www.russianfood.com/'},
          errorBuilder: (context, error, stackTrace) {
            final fallback = fallbackImage;
            if (allowFallback &&
                fallback != null &&
                fallback.isNotEmpty &&
                fallback != path) {
              return buildImage(fallback, allowFallback: false);
            }
            return placeholder();
          },
        );
      }
      if (path.startsWith('assets/')) {
        return Image.asset(
          path,
          fit: BoxFit.cover,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => placeholder(),
        );
      }
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => placeholder(),
      );
    }

    final path = image;
    final fallback = fallbackImage;
    final Widget child;
    if (path != null && path.isNotEmpty) {
      child = buildImage(path);
    } else if (fallback != null && fallback.isNotEmpty) {
      child = buildImage(fallback, allowFallback: false);
    } else {
      child = placeholder();
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
