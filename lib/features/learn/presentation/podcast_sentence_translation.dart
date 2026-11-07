import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../profile/data/profile_language_catalog.dart';
import '../../rooms/data/room_backend_config.dart';

/// Resolve the learner's mother tongue from their profile, including
/// profiles saved before nativeLanguageCode was introduced. No Firestore
/// document is modified when reading legacy fields.
String podcastNativeLanguageFromProfile(
    Map<String, dynamic>? profile, String fallback) {
  final storedCode =
      (profile?['nativeLanguageCode'] as String? ?? '').trim().toLowerCase()
          .replaceAll('_', '-');
  if (RegExp(r'^[a-z]{2,3}(-[a-z0-9]{2,8})?$').hasMatch(storedCode)) {
    return storedCode;
  }
  final oldName =
      (profile?['nativeLanguage'] as String? ?? '').trim().toLowerCase();
  if (oldName.isNotEmpty) {
    for (final language in ProfileLanguageCatalog.languages) {
      if (oldName == language.code ||
          oldName == language.englishName.toLowerCase() ||
          oldName == language.nativeName?.toLowerCase()) {
        return language.code;
      }
    }
  }
  return fallback;
}

/// Keep the original words intact while exposing a separate translate
/// action for each sentence, even when one transcript cue contains several.
List<String> podcastReadingSentences(String text) {
  final sentences = text.trim()
      .split(RegExp(r'(?<=[.!?。！？])\s+'))
      .where((part) => part.trim().isNotEmpty)
      .map((part) => part.trim())
      .toList(growable: false);
  return sentences.isEmpty ? <String>[text] : sentences;
}

/// A single, opt-in translation for a podcast sentence. Never translates
/// the entire episode, controls playback, or claims approved audio alignment.
class PodcastSentenceTranslation extends StatefulWidget {
  const PodcastSentenceTranslation({
    super.key,
    required this.text,
    this.arabicDraft,
    this.sourceLanguage = 'en',
    this.original,
    this.nativeLanguageResolver,
    this.translationOverride,
  });

  final String text;
  final String? arabicDraft;
  final String sourceLanguage;
  /// Optional English sentence shown beside the translation icon.
  final Widget? original;
  /// Optional translation seams for deterministic widget testing.
  final Future<String> Function()? nativeLanguageResolver;
  final Future<String> Function(String text, String language)? translationOverride;

  @override
  State<PodcastSentenceTranslation> createState() =>
      _PodcastSentenceTranslationState();
}

class _PodcastSentenceTranslationState
    extends State<PodcastSentenceTranslation> {
  static final Map<String, String> _memoryCache = {};
  static final Map<String, Future<String?>> _languageCache = {};
  static final Map<String, DateTime> _languageCacheAt = {};
  bool _visible = false;
  bool _loading = false;
  String? _translation;
  String? _error;
  String? _target;
  int _generation = 0;

  static Future<String> _nativeLanguage(String fallback) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return fallback;
    final now = DateTime.now();
    var cached = _languageCache[user.uid];
    final last = _languageCacheAt[user.uid];
    // A profile edit can change the language while the app remains open.
    if (cached == null || last == null ||
        now.difference(last) > const Duration(seconds: 30)) {
      cached = () async {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users').doc(user.uid).get();
          return podcastNativeLanguageFromProfile(doc.data(), '');
        } catch (_) {
          return null;
        }
      }();
      _languageCache[user.uid] = cached;
      _languageCacheAt[user.uid] = now;
    }
    final code = await cached;
    if (code == null || code.isEmpty) {
      _languageCache.remove(user.uid);
      _languageCacheAt.remove(user.uid);
      return fallback;
    }
    return code;
  }

  Future<void> _toggle() async {
    if (_visible) {
      setState(() => _visible = false);
      return;
    }
    final generation = ++_generation;
    setState(() {
      _visible = true;
      _loading = true;
      _error = null;
    });
    try {
      final fallback = Localizations.localeOf(context).languageCode;
      final target = await (widget.nativeLanguageResolver?.call() ??
          _nativeLanguage(fallback));
      if (!mounted || generation != _generation) return;
      final cacheKey = jsonEncode([target, widget.text]);
      String translated;
      if (target == widget.sourceLanguage) {
        translated = widget.text;
      } else if (target == 'ar' &&
          (widget.arabicDraft?.trim().isNotEmpty ?? false)) {
        translated = widget.arabicDraft!.trim();
      } else if (widget.translationOverride != null) {
        translated = await widget.translationOverride!(widget.text, target);
      } else if (_memoryCache.containsKey(cacheKey)) {
        translated = _memoryCache[cacheKey]!;
      } else {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw StateError('Sign in to translate.');
        final token = await user.getIdToken();
        if (token == null || token.isEmpty) {
          throw StateError('Sign in to translate.');
        }
        final base = Uri.parse(RoomBackendConfig.socialBaseUrl);
        if (base.scheme != 'https' || !base.hasAuthority ||
            base.userInfo.isNotEmpty) {
          throw StateError('Translation service not configured.');
        }
        final path = base.path.replaceFirst(RegExp(r'/$'), '');
        final url = base.replace(
          path: '$path/podcast/translate',
          query: null,
          fragment: null,
        );
        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'text': widget.text,
            'targetLanguageCode': target,
            'sourceLanguageCode': widget.sourceLanguage,
          }),
        ).timeout(const Duration(seconds: 35));
        final data = jsonDecode(response.body);
        if (response.statusCode != 200 ||
            data is! Map<String, dynamic> ||
            data['ok'] != true) {
          throw StateError('Translation is temporarily unavailable.');
        }
        translated = (data['translation'] as String? ?? '').trim();
        if (translated.isEmpty) {
          throw StateError('Translation is temporarily unavailable.');
        }
        _memoryCache[cacheKey] = translated;
        if (_memoryCache.length > 500) {
          _memoryCache.remove(_memoryCache.keys.first);
        }
      }
      if (!mounted || generation != _generation) return;
      setState(() {
        _target = target;
        _translation = translated;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = 'Translation unavailable. Tap to retry.';
      });
    }
  }

  @override
  void didUpdateWidget(covariant PodcastSentenceTranslation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.sourceLanguage != widget.sourceLanguage) {
      _generation++;
      _visible = false;
      _translation = null;
      _target = null;
      _loading = false;
      _error = null;
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final rtl = const {'ar', 'fa', 'ur', 'he', 'ps', 'sd'}
        .contains(_target?.split('-').first);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.original != null)
              Expanded(child: widget.original!),
            IconButton(
              key: const ValueKey('podcast-translate-sentence'),
              tooltip: ar ? 'ترجمة هذه الجملة إلى لغتي الأم'
                  : 'Translate this sentence to my native language',
              icon: Icon(_visible
                  ? Icons.translate_rounded : Icons.g_translate_rounded,
                  size: 20),
              color: _visible ? const Color(0xFF20845C) : null,
              constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
              padding: const EdgeInsets.all(5),
              onPressed: _loading ? null : _toggle,
            ),
          ],
        ),
        if (_visible && _loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_visible && _error != null)
          TextButton(
            onPressed: _toggleRetry,
            child: Text(ar ? 'الترجمة غير متاحة، اضغط للمحاولة مجددًا'
                : _error!),
          ),
        if (_visible && _translation != null && !_loading) ...[
          Text(
            _translation!,
            key: const ValueKey('podcast-single-translation'),
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
              fontSize: 14,
            ),
          ),
          if (_target != widget.sourceLanguage)
            Text(
              ar ? 'ترجمة أولية · $_target'
                  : 'Draft translation · $_target',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
        ],
      ],
    );
  }

  void _toggleRetry() {
    setState(() => _visible = false);
    _toggle();
  }
}

/// Preserve required third-party credit without a large provider banner.
class PodcastSourceInfo extends StatelessWidget {
  const PodcastSourceInfo({
    super.key,
    required this.source,
    required this.url,
  });

  final String source;
  final String url;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return ExpansionTile(
      key: const ValueKey('podcast-source-details'),
      tilePadding: EdgeInsets.zero,
      leading: const Icon(Icons.info_outline_rounded, size: 18),
      title: Text(ar ? 'معلومات التسجيل' : 'Recording information',
          style: const TextStyle(fontSize: 12)),
      children: [
        Text(ar
            ? 'التسجيل الأصلي: $source. WorldVoice غير تابع للناشر.'
            : 'Original recording: $source. WorldVoice is not affiliated with the publisher.',
            style: const TextStyle(fontSize: 12)),
        TextButton.icon(
          onPressed: () => launchUrl(Uri.parse(url),
              mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: Text(ar ? 'صفحة التسجيل الأصلي' : 'Original recording page'),
        ),
      ],
    );
  }
}
