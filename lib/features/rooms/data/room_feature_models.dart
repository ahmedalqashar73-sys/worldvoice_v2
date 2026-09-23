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
    this.musicTitle,
    this.musicUrl,
    this.quizQuestion,
    this.quizOptions = const <String>[],
    this.quizCorrectIndex,
    this.quizRevealed = false,
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
  final String? musicTitle;
  final String? musicUrl;
  final String? quizQuestion;
  final List<String> quizOptions;
  final int? quizCorrectIndex;
  final bool quizRevealed;
  final List<Map<String, dynamic>> quizWinners;

  factory RoomFeatureState.fromData(Map<String, dynamic> data) {
    final quiz = data['quiz'];
    final quizData = quiz is Map
        ? Map<String, dynamic>.from(quiz)
        : const <String, dynamic>{};

    return RoomFeatureState(
      roomLevel: (data['roomLevel'] as num?)?.toInt() ?? 1,
      roomXp: (data['roomXp'] as num?)?.toInt() ?? 0,
      themeId: (data['themeId'] ?? 'royalPurple').toString(),
      backgroundUrl: data['backgroundUrl']?.toString(),
      boardWriteEnabled: data['boardWriteEnabled'] != false,
      isPrivate: data['isPrivate'] == true,
      vipOnly: data['vipOnly'] == true,
      musicPlaying: data['musicPlaying'] == true,
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
  });

  final String id;
  final String name;
  final int priceCoins;
  final bool active;
  final String? category;
  final String? emoji;
  final String? animationUrl;

  factory RoomGiftCatalogItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return RoomGiftCatalogItem(
      id: doc.id,
      name: (data['name'] ?? doc.id).toString(),
      priceCoins: (data['priceCoins'] as num?)?.toInt() ?? 0,
      active: data['active'] == true,
      category: data['category']?.toString(),
      emoji: data['emoji']?.toString(),
      animationUrl: data['animationUrl']?.toString(),
    );
  }
}
