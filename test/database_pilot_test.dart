import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/data/app_database.dart';
import 'package:norma/core/models/seed_bundle.dart';

void main() {
  test('production seed imports', () async {
    final raw = File('assets/data/seed.json').readAsStringSync();
    final bundle = SeedBundle.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
    final path =
        '${Directory.systemTemp.path}/norma_pilot_${DateTime.now().microsecondsSinceEpoch}.db';
    final db = await AppDatabase.open(path: path);
    await db.seedIfNeeded(bundle);
    final repo = await db.loadRepository();
    expect(repo.recipes, hasLength(10));
    expect(repo.ingredients, hasLength(75));
    await db.close();
    File(path).deleteSync();
  });
}
