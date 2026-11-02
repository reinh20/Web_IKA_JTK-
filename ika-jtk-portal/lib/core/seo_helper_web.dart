// ignore: deprecated_member_use
import 'dart:html' as html;

void updateWebSeoMeta({
  required String title,
  String? description,
  String? tags,
  String? imageUrl,
  String? url,
  String? type,
}) {
  try {
    final pageTitle = '$title | IKA JTK';
    html.document.title = pageTitle;

    void setMeta(String attrName, String attrVal, String? content) {
      if (content == null || content.isEmpty) return;
      var el = html.document.querySelector('meta[$attrName="$attrVal"]');
      if (el == null) {
        el = html.MetaElement()..setAttribute(attrName, attrVal);
        html.document.head?.append(el);
      }
      el.setAttribute('content', content);
    }

    void setCanonical(String? targetUrl) {
      if (targetUrl == null || targetUrl.isEmpty) return;
      var el = html.document.querySelector('link[rel="canonical"]');
      if (el == null) {
        el = html.LinkElement()
          ..setAttribute('rel', 'canonical')
          ..setAttribute('href', targetUrl);
        html.document.head?.append(el);
      } else {
        el.setAttribute('href', targetUrl);
      }
    }

    final effectiveUrl = url ?? html.window.location.href;
    final effectiveImage = (imageUrl != null && imageUrl.isNotEmpty)
        ? imageUrl
        : 'icons/Icon-512.png';
    final effectiveType = type ?? 'website';

    // Standard SEO
    setMeta('name', 'keywords', tags);
    setMeta('name', 'description', description);

    // Open Graph
    setMeta('property', 'og:title', title);
    setMeta('property', 'og:description', description);
    setMeta('property', 'og:image', effectiveImage);
    setMeta('property', 'og:url', effectiveUrl);
    setMeta('property', 'og:type', effectiveType);
    setMeta('property', 'og:site_name', 'IKA JTK POLBAN');
    setMeta('property', 'og:tags', tags);
    setMeta('property', 'article:tag', tags);

    // Twitter Cards
    setMeta('name', 'twitter:card', 'summary_large_image');
    setMeta('name', 'twitter:title', title);
    setMeta('name', 'twitter:description', description);
    setMeta('name', 'twitter:image', effectiveImage);

    // Canonical link tag
    setCanonical(effectiveUrl);
  } catch (_) {
    // Ignore if not in browser environment
  }
}
