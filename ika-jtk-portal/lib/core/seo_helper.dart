import 'seo_helper_stub.dart'
    if (dart.library.html) 'seo_helper_web.dart' as impl;

class SeoHelper {
  static void update({
    required String title,
    String? description,
    String? tags,
    String? imageUrl,
    String? url,
    String? type,
  }) {
    impl.updateWebSeoMeta(
      title: title,
      description: description,
      tags: tags,
      imageUrl: imageUrl,
      url: url,
      type: type,
    );
  }
}
