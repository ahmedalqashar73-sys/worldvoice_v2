import 'package:flutter/material.dart';

enum ChatBubbleTier { classic, premium, royal, vip }

@immutable
class ChatBubbleDesign {
  const ChatBubbleDesign({
    required this.id, required this.name, required this.nameAr,
    required this.tier, required this.primary, required this.secondary,
    required this.accent, required this.icon,
  });
  final String id, name, nameAr;
  final ChatBubbleTier tier;
  final Color primary, secondary, accent;
  final IconData icon;
  bool get isVip => tier == ChatBubbleTier.vip;
  String get inventoryId => 'bubble__$id';
  String storeId(int? days) =>
      'bubble__${id}__${days == null ? "permanent" : days}';
  int price(int? days) => switch (tier) {
    ChatBubbleTier.classic => switch (days) {7 => 25, 30 => 80, _ => 600},
    ChatBubbleTier.premium => switch (days) {7 => 60, 30 => 180, _ => 1500},
    ChatBubbleTier.royal => switch (days) {7 => 120, 30 => 360, _ => 3000},
    ChatBubbleTier.vip => 0,
  };
}

abstract final class WorldVoiceChatBubbles {
  static const String freeId = 'free';
  static const List<ChatBubbleDesign> designs = [
    ChatBubbleDesign(id:'emerald',name:'Soft Emerald',nameAr:'الزمرد الناعم',
      tier:ChatBubbleTier.classic,primary:Color(0xFF08694D),secondary:Color(0xFF12382E),
      accent:Color(0xFFF4D678),icon:Icons.eco_rounded),
    ChatBubbleDesign(id:'ocean',name:'Ocean Blue',nameAr:'أمواج المحيط',
      tier:ChatBubbleTier.classic,primary:Color(0xFF0A64B1),secondary:Color(0xFF172C59),
      accent:Color(0xFF8BE4FE),icon:Icons.water_rounded),
    ChatBubbleDesign(id:'rose',name:'Rose Pearl',nameAr:'لؤلؤة الورد',
      tier:ChatBubbleTier.classic,primary:Color(0xFFBA508D),secondary:Color(0xFF61254D),
      accent:Color(0xFFFFC8E7),icon:Icons.local_florist_rounded),
    ChatBubbleDesign(id:'moonlight',name:'Moonlight',nameAr:'ضوء القمر',
      tier:ChatBubbleTier.classic,primary:Color(0xFF3D4D9B),secondary:Color(0xFF1F244B),
      accent:Color(0xFFC7D7FF),icon:Icons.nightlight_round),
    ChatBubbleDesign(id:'sakura',name:'Sakura Bloom',nameAr:'زهور الساكورا',
      tier:ChatBubbleTier.premium,primary:Color(0xFFDC6FA4),secondary:Color(0xFF943C7D),
      accent:Color(0xFFFFD6E8),icon:Icons.filter_vintage_rounded),
    ChatBubbleDesign(id:'galaxy',name:'Galaxy Dream',nameAr:'مجرة الأحلام',
      tier:ChatBubbleTier.premium,primary:Color(0xFF6E49B9),secondary:Color(0xFF272D75),
      accent:Color(0xFFCBC6FF),icon:Icons.auto_awesome_rounded),
    ChatBubbleDesign(id:'butterfly',name:'Golden Butterfly',nameAr:'الفراشة الذهبية',
      tier:ChatBubbleTier.premium,primary:Color(0xFF90601C),secondary:Color(0xFF40351A),
      accent:Color(0xFFFBE29B),icon:Icons.flutter_dash_rounded),
    ChatBubbleDesign(id:'cat',name:'Little Cat',nameAr:'القطة اللطيفة',
      tier:ChatBubbleTier.premium,primary:Color(0xFFDF7CAB),secondary:Color(0xFF7D486F),
      accent:Color(0xFFFFE3F3),icon:Icons.pets_rounded),
    ChatBubbleDesign(id:'dragon',name:'Royal Dragon',nameAr:'التنين الملكي',
      tier:ChatBubbleTier.royal,primary:Color(0xFF883B23),secondary:Color(0xFF3D211D),
      accent:Color(0xFFFFD171),icon:Icons.local_fire_department_rounded),
    ChatBubbleDesign(id:'phoenix',name:'Phoenix Fire',nameAr:'لهيب الفينيق',
      tier:ChatBubbleTier.royal,primary:Color(0xFFC2501B),secondary:Color(0xFF56231E),
      accent:Color(0xFFFFE092),icon:Icons.whatshot_rounded),
    ChatBubbleDesign(id:'socotra',name:'Socotra Legend',nameAr:'أسطورة سقطرى',
      tier:ChatBubbleTier.royal,primary:Color(0xFF167C60),secondary:Color(0xFF24443B),
      accent:Color(0xFFE6B878),icon:Icons.park_rounded),
    ChatBubbleDesign(id:'crown',name:'World Crown',nameAr:'التاج العالمي',
      tier:ChatBubbleTier.royal,primary:Color(0xFF664F95),secondary:Color(0xFF36264D),
      accent:Color(0xFFF9DB8D),icon:Icons.workspace_premium_rounded),
    ChatBubbleDesign(id:'vip_gold',name:'VIP Golden Voice',nameAr:'صوت VIP الذهبي',
      tier:ChatBubbleTier.vip,primary:Color(0xFF14724F),secondary:Color(0xFF103629),
      accent:Color(0xFFFFDB77),icon:Icons.mic_rounded),
    ChatBubbleDesign(id:'vip_galaxy',name:'VIP Galaxy',nameAr:'مجرة VIP',
      tier:ChatBubbleTier.vip,primary:Color(0xFF7149BD),secondary:Color(0xFF28235D),
      accent:Color(0xFFE0B9FF),icon:Icons.stars_rounded),
    ChatBubbleDesign(id:'vip_sakura',name:'VIP Sakura',nameAr:'ساكورا VIP',
      tier:ChatBubbleTier.vip,primary:Color(0xFFD86AA2),secondary:Color(0xFF80295F),
      accent:Color(0xFFFFD5EA),icon:Icons.spa_rounded),
  ];
  static ChatBubbleDesign? find(String? id) {
    if (id == null || id == freeId) return null;
    for (final design in designs) {
      if (design.id == id) return design;
    }
    return null;
  }
  static String tierName(ChatBubbleTier tier, {required bool ar}) =>
    switch(tier) {
      ChatBubbleTier.classic => ar ? 'كلاسيك' : 'Classic',
      ChatBubbleTier.premium => ar ? 'بريميوم' : 'Premium',
      ChatBubbleTier.royal => ar ? 'ملكي' : 'Royal',
      ChatBubbleTier.vip => 'VIP',
    };
}
