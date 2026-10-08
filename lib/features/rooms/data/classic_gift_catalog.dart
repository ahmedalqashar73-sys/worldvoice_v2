import 'dart:convert';

import 'package:flutter/services.dart';

import 'room_feature_models.dart';

/// One approved presentation catalog shared by chat, Live and voice rooms.
/// These records are previews, NOT purchasable or spendable inventory.
class ClassicGiftCatalog {
  ClassicGiftCatalog._();

  static const assetPath = 'assets/gifts/classic_premium_1_50.json';
  static Future<List<RoomGiftCatalogItem>>? _cached;

  static Future<List<RoomGiftCatalogItem>> load() =>
      _cached ??= rootBundle.loadString(assetPath).then(parse);

  static List<RoomGiftCatalogItem> parse(String json) {
    final data = jsonDecode(json);
    if (data is! Map<String, dynamic> || data['catalogId'] != 'classic_1_50' ||
        data['gifts'] is! List) {
      throw const FormatException('Invalid classic gift catalog');
    }
    final raw = data['gifts'] as List;
    if (raw.length != 30) {
      throw const FormatException('The approved tier must contain 30 gifts');
    }
    final seen = <String>{};
    var previous = 0;
    final result = <RoomGiftCatalogItem>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid gift entry');
      }
      final gift = RoomGiftCatalogItem.preview(entry);
      if (!gift.id.startsWith('classic_') ||
          !RegExp(r'^[a-z0-9_]+$').hasMatch(gift.id) ||
          !seen.add(gift.id) ||
          gift.name.isEmpty || gift.nameAr?.isNotEmpty != true ||
          gift.emoji?.isNotEmpty != true ||
          gift.effectType?.isNotEmpty != true ||
          gift.priceCoins < 1 || gift.priceCoins > 50 ||
          gift.priceCoins < previous) {
        throw const FormatException('Invalid approved classic gift design');
      }
      previous = gift.priceCoins;
      result.add(gift);
    }
    return List<RoomGiftCatalogItem>.unmodifiable(result);
  }

  /// Remote server data is authoritative for activation and prices;
  /// local metadata can enrich preview art, never unlock spending.
  static List<RoomGiftCatalogItem> merge({
    required List<RoomGiftCatalogItem> previews,
    required List<RoomGiftCatalogItem> published,
  }) {
    final remoteById = {for (final item in published) item.id: item};
    final merged = <RoomGiftCatalogItem>[];
    for (final preview in previews) {
      final server = remoteById.remove(preview.id);
      merged.add(RoomGiftCatalogItem(
        id: preview.id,
        name: preview.name,
        nameAr: preview.nameAr,
        priceCoins: server?.priceCoins ?? preview.priceCoins,
        active: server?.active == true,
        category: preview.category,
        emoji: preview.emoji,
        effectType: preview.effectType,
        previewUrl: server?.previewUrl ?? preview.previewUrl,
        animationUrl: server?.animationUrl,
      ));
    }
    // Existing active gifts cannot silently disappear after this rollout.
    merged.addAll(remoteById.values.where(
      (gift) => gift.active && gift.priceCoins >= 1 && gift.priceCoins <= 50,
    ));
    return List<RoomGiftCatalogItem>.unmodifiable(merged);
  }
}
