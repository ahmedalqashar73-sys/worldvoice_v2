import 'package:flutter/material.dart';

enum RoomMode {
  chat(
    Icons.forum_outlined,
    'دردشة',
    'Chat',
    'حوار صوتي ومشاركة رسائل',
    'Voice conversation and messages',
  ),
  board(
    Icons.draw_outlined,
    'سبورة تفاعلية',
    'Whiteboard',
    'اكتب وارسم مع المشاركين',
    'Write and draw together',
  ),
  lesson(
    Icons.school_outlined,
    'شرح ودروس',
    'Lesson',
    'سبورة يكتب عليها المضيف',
    'A host-led teaching board',
  ),
  quiz(
    Icons.quiz_outlined,
    'مسابقات Quiz',
    'Quiz',
    'أسئلة وتنافس داخل الغرفة',
    'Questions and room competition',
  );

  const RoomMode(
    this.icon,
    this.ar,
    this.en,
    this.descriptionAr,
    this.descriptionEn,
  );
  final IconData icon;
  final String ar;
  final String en;
  final String descriptionAr;
  final String descriptionEn;
  String label(bool isArabic) => isArabic ? ar : en;
  String description(bool isArabic) => isArabic ? descriptionAr : descriptionEn;
}
