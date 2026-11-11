import 'package:flutter_test/flutter_test.dart';
import 'package:norma/features/shared/recipe_links.dart';

void main() {
  test('Pinterest-ссылка ведёт на поиск видео по названию', () {
    final uri = pinterestVideoSearchUri('Салат Оливье');

    expect(uri.host, 'www.pinterest.com');
    expect(uri.path, '/search/videos/');
    expect(uri.queryParameters['q'], 'Салат Оливье рецепт');
  });
}
