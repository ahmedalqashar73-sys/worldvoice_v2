import 'dart:convert';

import 'package:flutter/services.dart';

import 'room_feature_models.dart';

/// The single WorldVoice gift presentation catalog shared by chat, Live and
/// voice rooms. Local records provide names/art/prices for presentation only;
/// paid delivery is still authorized by the backend store item.
class ClassicGiftCatalog {
  ClassicGiftCatalog._();

  static const assetPath = 'assets/gifts/worldvoice_gifts.json';
  static const approvedIdPattern = r'^wv_gift_[0-9]{3}$';
  static const int giftCount = 54;
  static Future<List<RoomGiftCatalogItem>>? _cached;

  static Future<List<RoomGiftCatalogItem>> load() =>
      _cached ??= rootBundle.loadString(assetPath).then(parse);

  static int tierForPrice(int price) {
    if (price >= 1 && price <= 150) return 1;
    if (price >= 151 && price <= 1000) return 2;
    if (price >= 1001 && price <= 5000) return 3;
    return 0;
  }

  static List<RoomGiftCatalogItem> parse(String json) {
    final data = jsonDecode(json);
    if (data is! Map<String, dynamic> ||
        data['catalogId'] != 'worldvoice_gifts_v1' ||
        data['gifts'] is! List) {
      throw const FormatException('Invalid WorldVoice gift catalog');
    }

    final raw = data['gifts'] as List;
    if (raw.length != giftCount) {
      throw const FormatException('WorldVoice catalog must contain 54 gifts');
    }

    final seen = <String>{};
    final tierCounts = <int, int>{1: 0, 2: 0, 3: 0};
    var previousSort = 0;
    final result = <RoomGiftCatalogItem>[];

    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid gift entry');
      }
      final gift = RoomGiftCatalogItem.preview(entry);
      final sortOrder = (entry['sortOrder'] as num?)?.toInt() ?? 0;
      final tier = (entry['tier'] as num?)?.toInt() ?? 0;
      final expectedTier = tierForPrice(gift.priceCoins);

      if (!RegExp(approvedIdPattern).hasMatch(gift.id) ||
          !seen.add(gift.id) ||
          gift.name.trim().isEmpty ||
          gift.nameAr?.trim().isNotEmpty != true ||
          gift.emoji?.trim().isNotEmpty != true ||
          gift.effectType?.trim().isNotEmpty != true ||
          expectedTier == 0 ||
          tier != expectedTier ||
          sortOrder <= previousSort) {
        throw const FormatException('Invalid approved WorldVoice gift design');
      }

      previousSort = sortOrder;
      tierCounts[tier] = (tierCounts[tier] ?? 0) + 1;
      result.add(gift);
    }

    if (tierCounts[1] != 30 || tierCounts[2] != 15 || tierCounts[3] != 9) {
      throw const FormatException('Invalid WorldVoice gift tier counts');
    }

    return List<RoomGiftCatalogItem>.unmodifiable(result);
  }

  /// Only IDs present in the bundled approved pack are ever returned.
  /// Stale/legacy Firestore gift documents are intentionally ignored so they
  /// cannot reappear in the store after this catalog replacement.
  static List<RoomGiftCatalogItem> merge({
    required List<RoomGiftCatalogItem> previews,
    required List<RoomGiftCatalogItem> published,
  }) {
    final remoteById = {
      for (final item in published)
        if (RegExp(approvedIdPattern).hasMatch(item.id)) item.id: item,
    };

    return List<RoomGiftCatalogItem>.unmodifiable(
      previews.map((preview) {
        final server = remoteById[preview.id];
        final priceMatches =
            server != null && server.priceCoins == preview.priceCoins;
        return RoomGiftCatalogItem(
          id: preview.id,
          name: preview.name,
          nameAr: preview.nameAr,
          priceCoins: preview.priceCoins,
          active: server?.active == true && priceMatches,
          category: preview.category,
          emoji: preview.emoji,
          effectType: preview.effectType,
          previewUrl: null,
          animationUrl: server?.animationUrl,
        );
      }),
    );
  }
}
