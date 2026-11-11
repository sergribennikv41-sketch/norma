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
  });

  final String? image;
  final MealType? mealType;
  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final path = image;
    final Widget child;
    if (path == null || path.isEmpty) {
      child = _Placeholder(mealType: mealType);
    } else if (path.startsWith('assets/')) {
      child = Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _Placeholder(mealType: mealType),
      );
    } else {
      child = Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _Placeholder(mealType: mealType),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.mealType});

  final MealType? mealType;

  @override
  Widget build(BuildContext context) {
    final (icon, colors) = switch (mealType) {
      MealType.breakfast => (
        Icons.free_breakfast_outlined,
        const [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
      ),
      MealType.lunch => (
        Icons.lunch_dining_outlined,
        const [Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
      ),
      MealType.dinner => (
        Icons.dinner_dining_outlined,
        const [Color(0xFFB2DFDB), Color(0xFF80CBC4)],
      ),
      MealType.snack => (
        Icons.emoji_food_beverage_outlined,
        const [Color(0xFFD1C4E9), Color(0xFFB39DDB)],
      ),
      null => (
        Icons.restaurant_outlined,
        const [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
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
      child: Center(
        child: Icon(icon, color: const Color(0xFF2E7D32), size: 28),
      ),
    );
  }
}
