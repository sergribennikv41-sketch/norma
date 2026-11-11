import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/seed_bundle.dart';

Future<SeedBundle> loadSeedBundle() async {
  final raw = await rootBundle.loadString('assets/data/seed.json');
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw const FormatException('Некорректный seed-файл');
  }
  return SeedBundle.fromJson(Map<String, dynamic>.from(decoded));
}
