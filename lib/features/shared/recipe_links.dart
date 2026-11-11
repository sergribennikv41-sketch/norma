Uri pinterestSearchUri(String title) {
  return Uri.https('www.pinterest.com', '/search/pins/', {
    'q': '$title рецепт',
  });
}

Uri youtubeSearchUri(String title) {
  return Uri.https('www.youtube.com', '/results', {
    'search_query': '$title рецепт',
  });
}

Uri rutubeSearchUri(String title) {
  return Uri.https('rutube.ru', '/search/', {'query': '$title рецепт'});
}

Uri vkVideoSearchUri(String title) {
  return Uri.https('vk.com', '/video', {'q': '$title рецепт'});
}
