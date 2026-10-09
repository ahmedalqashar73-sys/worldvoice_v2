import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Use a compatible rendition only for Cloudinary video delivery URLs.
String? compatibleBoardVideoUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || uri.host != 'res.cloudinary.com' || !uri.path.contains('/video/upload/')) return null;
  return uri.replace(path: uri.path.replaceFirst('/video/upload/', '/video/upload/f_mp4,vc_h264,ac_aac/')).toString();
}

class BoardMediaError extends StatefulWidget {
  const BoardMediaError({required this.url, required this.error, this.onRetry, super.key});
  final String url;
  final String error;
  final VoidCallback? onRetry;
  @override
  State<BoardMediaError> createState() => _BoardMediaErrorState();
}
class _BoardMediaErrorState extends State<BoardMediaError> {
  late final Future<String> _details = _loadDetails();
  Future<String> _loadDetails() async {
    try {
      final response = await http.head(Uri.parse(widget.url)).timeout(const Duration(seconds: 12));
      final providerError = response.headers['x-cld-error'] ?? '';
      return 'HTTP ${response.statusCode}\n$providerError\n${widget.error}';
    } catch (_) { return widget.error; }
  }
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Center(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(ar ? 'تعذر تحميل الملف' : 'Could not load media'),
      Wrap(alignment: WrapAlignment.center, children: [
        if (widget.onRetry != null) TextButton(onPressed: widget.onRetry, child: Text(ar ? 'إعادة المحاولة' : 'Retry')),
        TextButton(onPressed: () async {
          final details = await _details;
          if (!context.mounted) return;
          await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
            title: Text(ar ? 'تفاصيل تحميل الملف' : 'Media loading details'),
            content: SingleChildScrollView(child: SelectableText(details)),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ar ? 'إغلاق' : 'Close'))]));
        }, child: Text(ar ? 'التفاصيل' : 'Details')),
      ]),
    ])));
  }
}
