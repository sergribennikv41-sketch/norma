import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/retail.dart';

enum PriceLookupStatus { loading, found, notFound, failed }

class PriceLookupItem {
  const PriceLookupItem({required this.id, required this.name});

  final String id;
  final String name;
}

class PriceQuote {
  const PriceQuote({
    required this.ingredientId,
    required this.storeId,
    required this.price,
    required this.title,
    this.unit,
    this.url,
  });

  final String ingredientId;
  final String storeId;
  final double price;
  final String title;
  final String? unit;
  final String? url;
}

class PriceLookupState {
  const PriceLookupState._({required this.status, this.quote, this.message});

  const PriceLookupState.loading() : this._(status: PriceLookupStatus.loading);

  const PriceLookupState.found(PriceQuote quote)
    : this._(status: PriceLookupStatus.found, quote: quote);

  const PriceLookupState.notFound()
    : this._(status: PriceLookupStatus.notFound);

  const PriceLookupState.failed([String? message])
    : this._(status: PriceLookupStatus.failed, message: message);

  final PriceLookupStatus status;
  final PriceQuote? quote;
  final String? message;
}

class PriceLookupEvent {
  const PriceLookupEvent({required this.ingredientId, required this.state});

  final String ingredientId;
  final PriceLookupState state;
}

abstract class PriceLookupService {
  Stream<PriceLookupEvent> lookup({
    required String cityId,
    required String storeId,
    required List<PriceLookupItem> items,
  });

  void clearCache();
}

class ProcessPriceLookupService implements PriceLookupService {
  ProcessPriceLookupService({this.timeout = const Duration(minutes: 2)});

  final Duration timeout;
  final Map<String, PriceQuote> _cache = {};

  @override
  Stream<PriceLookupEvent> lookup({
    required String cityId,
    required String storeId,
    required List<PriceLookupItem> items,
  }) async* {
    final pending = <PriceLookupItem>[];
    for (final item in items) {
      final cached = _cache[_cacheKey(cityId, storeId, item.id)];
      if (cached != null) {
        yield PriceLookupEvent(
          ingredientId: item.id,
          state: PriceLookupState.found(cached),
        );
      } else {
        pending.add(item);
      }
    }
    if (pending.isEmpty) {
      return;
    }

    final script = _findScript();
    if (script == null) {
      for (final item in pending) {
        yield PriceLookupEvent(
          ingredientId: item.id,
          state: const PriceLookupState.failed('Обработчик цен не найден'),
        );
      }
      return;
    }

    Process process;
    try {
      process = await _startProcess(script, cityId, storeId);
    } on ProcessException catch (error) {
      for (final item in pending) {
        yield PriceLookupEvent(
          ingredientId: item.id,
          state: PriceLookupState.failed(
            'Не удалось запустить обработчик: ${error.message}',
          ),
        );
      }
      return;
    }

    final resolved = <String>{};
    final timer = Timer(timeout, () {
      process.kill();
    });
    unawaited(process.stderr.drain<void>());

    process.stdin.write(
      jsonEncode({
        'items': [
          for (final item in pending) {'id': item.id, 'name': item.name},
        ],
      }),
    );
    await process.stdin.close();

    try {
      final lines = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in lines) {
        if (line.trim().isEmpty) {
          continue;
        }
        final event = _eventFromLine(line, cityId, storeId);
        if (event == null) {
          continue;
        }
        resolved.add(event.ingredientId);
        yield event;
      }
      await process.exitCode;
    } finally {
      timer.cancel();
    }

    for (final item in pending) {
      if (resolved.contains(item.id)) {
        continue;
      }
      yield PriceLookupEvent(
        ingredientId: item.id,
        state: const PriceLookupState.failed('Нет ответа от магазина'),
      );
    }
  }

  @override
  void clearCache() {
    _cache.clear();
  }

  PriceLookupEvent? _eventFromLine(String line, String cityId, String storeId) {
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map) {
        return null;
      }
      final map = Map<String, dynamic>.from(decoded);
      final id = map['id'];
      if (id is! String || id.isEmpty) {
        return null;
      }
      final status = map['status'];
      if (status == 'found') {
        final price = map['price'];
        if (price is! num || price <= 0) {
          return PriceLookupEvent(
            ingredientId: id,
            state: const PriceLookupState.notFound(),
          );
        }
        final quote = PriceQuote(
          ingredientId: id,
          storeId: storeId,
          price: price.toDouble(),
          title: map['title'] is String ? map['title'] as String : '',
          unit: map['unit'] is String ? map['unit'] as String : null,
          url: map['url'] is String ? map['url'] as String : null,
        );
        _cache[_cacheKey(cityId, storeId, id)] = quote;
        return PriceLookupEvent(
          ingredientId: id,
          state: PriceLookupState.found(quote),
        );
      }
      if (status == 'failed') {
        return PriceLookupEvent(
          ingredientId: id,
          state: PriceLookupState.failed(
            map['message'] is String ? map['message'] as String : null,
          ),
        );
      }
      return PriceLookupEvent(
        ingredientId: id,
        state: const PriceLookupState.notFound(),
      );
    } catch (_) {
      return null;
    }
  }

  String _cacheKey(String cityId, String storeId, String ingredientId) {
    return '$cityId|$storeId|$ingredientId';
  }

  Future<Process> _startProcess(
    String script,
    String cityId,
    String storeId,
  ) async {
    final city = retailCityById(cityId).name;
    final args = ['-3', script, '--store', storeId, '--city', city];
    try {
      return await Process.start('py', args, runInShell: Platform.isWindows);
    } on ProcessException {
      return Process.start('python', args, runInShell: Platform.isWindows);
    }
  }

  String? _findScript() {
    final executableDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = [
      p.join('tool', 'price_lookup.py'),
      p.join(executableDir, 'price_lookup.py'),
      p.join(executableDir, 'tool', 'price_lookup.py'),
    ];
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }
    return null;
  }
}
