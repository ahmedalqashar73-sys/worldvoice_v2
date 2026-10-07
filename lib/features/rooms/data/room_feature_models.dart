import 'package:cloud_firestore/cloud_firestore.dart';

class RoomFeatureState {
  const RoomFeatureState({
    required this.roomLevel,
    required this.roomXp,
    required this.themeId,
    this.backgroundUrl,
    required this.boardWriteEnabled,
    required this.isPrivate,
    required this.vipOnly,
    required this.musicPlaying,
    required this.screenShareActive,
    this.screenSharerUid,
    this.boardMediaId,
    this.musicTitle,
    this.musicUrl,
    this.quizQuestion,
    this.quizOptions = const <String>[],
    this.quizCorrectIndex,
    this.quizRevealed = false,
    this.quizPracticeOnly = false,
    this.quizWinners = const <Map<String, dynamic>>[],
  });

  final int roomLevel;
  final int roomXp;
  final String themeId;
  final String? backgroundUrl;
  final bool boardWriteEnabled;
  final bool isPrivate;
  final bool vipOnly;
  final bool musicPlaying;
  final bool screenShareActive;
  final int? screenSharerUid;
  final String? boardMediaId;
  final String? musicTitle;
  final String? musicUrl;
  final String? quizQuestion;
  final List<String> quizOptions;
  final int? quizCorrectIndex;
  final bool quizRevealed;
  final bool quizPracticeOnly;
  final List<Map<String, dynamic>> quizWinners;

  factory RoomFeatureState.fromData(Map<String, dynamic> data) {
    final quiz = data['quiz'];
    final quizData = quiz is Map
        ? Map<String, dynamic>.from(quiz)
        : const <String, dynamic>{};

    return RoomFeatureState(
      roomLevel: (data['roomLevel'] as num?)?.toInt() ?? 1,
      roomXp: (data['roomXp'] as num?)?.toInt() ?? 0,
      themeId: (data['themeId'] ?? 'wv_bg_06').toString(),
      backgroundUrl: data['backgroundUrl']?.toString(),
      boardWriteEnabled: data['boardWriteEnabled'] != false,
      isPrivate: data['isPrivate'] == true,
      vipOnly: data['vipOnly'] == true,
      musicPlaying: data['musicPlaying'] == true,
      boardMediaId: data['boardMediaId']?.toString(),
      screenShareActive: data['screenShareActive'] == true,
      screenSharerUid: (data['screenSharerUid'] as num?)?.toInt(),
      musicTitle: data['musicTitle']?.toString(),
      musicUrl: data['musicUrl']?.toString(),
      quizQuestion: quizData['question']?.toString(),
      quizOptions: (quizData['options'] as List?)
              ?.map((value) => value.toString())
              .toList() ??
          const <String>[],
      quizCorrectIndex: (quizData['correctIndex'] as num?)?.toInt(),
      quizRevealed: quizData['revealed'] == true,
      quizPracticeOnly: quizData['practiceOnly'] == true,
      quizWinners: (quizData['winners'] as List?)
              ?.whereType<Map>()
              .map((value) => Map<String, dynamic>.from(value))
              .toList(growable: false) ??
          const <Map<String, dynamic>>[],
    );
  }
}

class RoomGiftEvent {
  const RoomGiftEvent({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.recipientName,
    required this.giftId,
    required this.points,
    this.animationUrl,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String recipientName;
  final String giftId;
  final int points;
  final String? animationUrl;
  final DateTime? createdAt;

  factory RoomGiftEvent.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final raw = data['createdAt'];
    return RoomGiftEvent(
      id: doc.id,
      senderId: (data['senderId'] ?? '').toString(),
      senderName: (data['senderName'] ?? '').toString(),
      recipientId: (data['recipientId'] ?? '').toString(),
      recipientName: (data['recipientName'] ?? '').toString(),
      giftId: (data['giftId'] ?? 'gift').toString(),
      points: (data['points'] as num?)?.toInt() ?? 0,
      animationUrl: data['animationUrl']?.toString(),
      createdAt: raw is Timestamp ? raw.toDate() : null,
    );
  }
}


class RoomGiftCatalogItem {
  const RoomGiftCatalogItem({
    required this.id,
    required this.name,
    required this.priceCoins,
    required this.active,
    this.category,
    this.emoji,
    this.animationUrl,
    this.previewUrl,
    this.nameAr,
    this.effectType,
  });

  final String id;
  final String name;
  final int priceCoins;
  final bool active;
  final String? category;
  final String? emoji;
  final String? animationUrl;
  final String? previewUrl;
  final String? nameAr;
  final String? effectType;

  String localizedName(bool ar) =>
      ar && nameAr?.isNotEmpty == true ? nameAr! : name;

  /// Only a backend-published Firestore item can ever be active.
  /// Local design previews have no payment authority.
  factory RoomGiftCatalogItem.preview(Map<String, dynamic> data) {
    return RoomGiftCatalogItem(
      id: data['id'].toString(),
      name: data['name'].toString(),
      nameAr: data['nameAr']?.toString(),
      priceCoins: (data['priceCoins'] as num).toInt(),
      active: false,
      category: 'classic_1_50',
      emoji: data['emoji']?.toString(),
      effectType: data['effectType']?.toString(),
      previewUrl: data['previewUrl']?.toString(),
    );
  }

  factory RoomGiftCatalogItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return RoomGiftCatalogItem(
      // Unified store IDs are type-prefixed; keep the legacy gift ID used
      // by existing animations and the backend /gift/send contract.
      id: (data['legacyId'] ??
          (doc.id.startsWith('gift__') ? doc.id.substring('gift__'.length)
              : doc.id)).toString(),
      name: (data['name'] ?? doc.id).toString(),
      priceCoins: (data['priceCoins'] as num?)?.toInt() ?? 0,
      active: data['active'] == true,
      category: data['category']?.toString(),
      emoji: data['emoji']?.toString(),
      animationUrl: data['animationUrl']?.toString(),
      previewUrl: data['previewUrl']?.toString(),
      nameAr: data['nameAr']?.toString(),
      effectType: data['effectType']?.toString(),
    );
  }
}

 
/// Free, short-lived tester animation notice. This is NOT a paid gift event;
/// it never represents coins, diamonds, XP or gift delivery.
class RoomGiftPreview {
  const RoomGiftPreview({
    required this.id,
    required this.nonce,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.recipientName,
    required this.giftId,
    required this.sentAt,
  });

  final String id;
  final String nonce;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String recipientName;
  final String giftId;
  final DateTime? sentAt;

  String get eventKey => '$id:$nonce';

  factory RoomGiftPreview.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final time = data['sentAt'];
    return RoomGiftPreview(
      id: doc.id,
      nonce: (data['nonce'] ?? '').toString(),
      senderId: (data['senderId'] ?? '').toString(),
      senderName: (data['senderName'] ?? '').toString(),
      recipientId: (data['recipientId'] ?? '').toString(),
      recipientName: (data['recipientName'] ?? '').toString(),
      giftId: (data['giftId'] ?? '').toString(),
      sentAt: time is Timestamp ? time.toDate() : null,
    );
  }

  RoomGiftEvent toVisualEvent() => RoomGiftEvent(
    id: eventKey,
    senderId: senderId,
    senderName: senderName,
    recipientId: recipientId,
    recipientName: recipientName,
    giftId: giftId,
    points: 0,
    createdAt: sentAt,
  );
}


/// Legacy-rule fallback for voice/Live room friend demos. This is plain room
/// chat transport only; unlike /gifts it has no financial authority. Explicit
/// v1 marker and strict parser prevent accidentally treating ordinary chat
/// messages or fake paid gift claims as a demo.
class RoomGiftPreviewChatCodec {
  RoomGiftPreviewChatCodec._();

  static final RegExp _pattern = RegExp(
    r'^WV_FREE_GIFT_PREVIEW:v1:(classic_[a-z_]{1,60}):'
    r'([A-Za-z0-9_-]{1,128}):([0-9a-f]{24})$',
  );

  static String encode({
    required String giftId,
    required String recipientId,
    required String nonce,
  }) {
    final value = 'WV_FREE_GIFT_PREVIEW:v1:$giftId:$recipientId:$nonce';
    if (!_pattern.hasMatch(value)) throw ArgumentError('Invalid demo marker');
    return value;
  }

  static ({String giftId, String recipientId, String nonce})?
      decode(String text) {
    final match = _pattern.firstMatch(text);
    if (match == null) return null;
    return (
      giftId: match.group(1)!,
      recipientId: match.group(2)!,
      nonce: match.group(3)!,
    );
  }
}
