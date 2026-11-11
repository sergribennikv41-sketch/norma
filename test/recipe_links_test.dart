import 'package:flutter_test/flutter_test.dart';
import 'package:norma/features/shared/recipe_links.dart';

void main() {
  test('Pinterest-ссылка ведёт на поиск по названию', () {
    final uri = pinterestSearchUri('Салат Оливье');

    expect(uri.host, 'www.pinterest.com');
    expect(uri.path, '/search/pins/');
    expect(uri.queryParameters['q'], 'Салат Оливье рецепт');
  });

  test('ссылки на видео содержат поисковый запрос', () {
    expect(youtubeSearchUri('Борщ').host, 'www.youtube.com');
    expect(
      youtubeSearchUri('Борщ').queryParameters['search_query'],
      'Борщ рецепт',
    );
    expect(rutubeSearchUri('Борщ').queryParameters['query'], 'Борщ рецепт');
    expect(vkVideoSearchUri('Борщ').queryParameters['q'], 'Борщ рецепт');
  });
}
