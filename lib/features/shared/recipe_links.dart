Uri pinterestVideoSearchUri(String title) {
  return Uri.https('www.pinterest.com', '/search/videos/', {
    'q': '$title рецепт',
  });
}
