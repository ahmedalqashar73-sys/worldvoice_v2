import 'package:flutter/material.dart';

import '../data/room_mode.dart';

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({
    super.key,
    required this.isArabic,
    required this.languageOptions,
    required this.initialLanguage,
    required this.giftLevel,
  });

  final bool isArabic;
  final List<String> languageOptions;
  final String initialLanguage;
  final int giftLevel;

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final TextEditingController _nameController = TextEditingController();
  late String _language;
  bool _showTeacherAiSeat = false;
  bool _isPrivate = false;
  bool _vipOnly = false;
  RoomMode _mode = RoomMode.chat;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _language = widget.languageOptions.contains(widget.initialLanguage)
        ? widget.initialLanguage
        : widget.languageOptions.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    String label(String ar, String en) => widget.isArabic ? ar : en;
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(label('إنشاء غرفة', 'Create a room')),
          leading: IconButton(
            tooltip: label('إغلاق', 'Close'),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Text(
                      label(
                        'مساحة لصوتك وأفكارك',
                        'A space for your voice and ideas',
                      ),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label(
                        'اختر موضوعًا ووضعًا، وابدأ اللقاء.',
                        'Choose a topic and mode, then start your room.',
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      maxLength: 40,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: label(
                          'عن ماذا ستتحدث؟',
                          'What will you talk about?',
                        ),
                        prefixIcon: const Icon(Icons.edit_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? label('اكتب اسم الغرفة أولًا', 'Enter a room name')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _language,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: label('لغة الغرفة', 'Room language'),
                        prefixIcon: const Icon(Icons.language_rounded),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final code in widget.languageOptions)
                          DropdownMenuItem(
                            value: code,
                            child: Text(_languageLabel(code)),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _language = value);
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      label('وضع الغرفة', 'Room mode'),
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns =
                            constraints.maxWidth < 320 ||
                                MediaQuery.textScalerOf(context).scale(16) > 24
                            ? 1
                            : 2;
                        final width =
                            (constraints.maxWidth - (columns - 1) * 12) /
                            columns;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final mode in RoomMode.values)
                              SizedBox(
                                width: width,
                                child: Semantics(
                                  selected: _mode == mode,
                                  child: Material(
                                    color: _mode == mode
                                        ? colors.primaryContainer
                                        : colors.surfaceContainerHighest,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      side: BorderSide(
                                        color: _mode == mode
                                            ? colors.primary
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () => setState(() => _mode = mode),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              mode.icon,
                                              color: _mode == mode
                                                  ? colors.onPrimaryContainer
                                                  : colors.onSurface,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              mode.label(widget.isArabic),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              mode.description(widget.isArabic),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          SwitchListTile(
                            secondary: const Icon(Icons.smart_toy_outlined),
                            title: Text(
                              label('أستاذ الذكاء الاصطناعي', 'Teacher AI'),
                            ),
                            subtitle: Text(
                              label(
                                'إظهار مقعد المساعد داخل الغرفة',
                                'Show the assistant seat in your room',
                              ),
                            ),
                            value: _showTeacherAiSeat,
                            onChanged: (value) =>
                                setState(() => _showTeacherAiSeat = value),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            secondary: const Icon(Icons.lock_outline_rounded),
                            title: Text(label('غرفة خاصة', 'Private room')),
                            subtitle: Text(
                              widget.giftLevel >= 14
                                  ? label(
                                      'الدخول بكود خاص',
                                      'Join using a private code',
                                    )
                                  : label(
                                      'تتطلب مستوى الهدايا 14',
                                      'Requires Gift Level 14',
                                    ),
                            ),
                            value: _isPrivate,
                            onChanged: widget.giftLevel >= 14
                                ? (value) => setState(() => _isPrivate = value)
                                : null,
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            secondary: const Icon(
                              Icons.workspace_premium_outlined,
                            ),
                            title: Text(
                              label('لأعضاء VIP فقط', 'VIP members only'),
                            ),
                            value: _vipOnly,
                            onChanged: (value) =>
                                setState(() => _vipOnly = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(18),
                      ),
                      icon: const Icon(Icons.mic_rounded),
                      label: Text(
                        label('بدء الغرفة الصوتية', 'Start voice room'),
                      ),
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        FocusScope.of(context).unfocus();
                        Navigator.pop(
                          context,
                          CreateRoomResult(
                            name: _nameController.text.trim(),
                            languageCode: _language,
                            mode: _mode,
                            showTeacherAiSeat: _showTeacherAiSeat,
                            isPrivate: _isPrivate,
                            vipOnly: _vipOnly,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CreateRoomResult {
  final RoomMode mode;
  const CreateRoomResult({
    required this.mode,
    required this.name,
    required this.languageCode,
    required this.showTeacherAiSeat,
    required this.isPrivate,
    required this.vipOnly,
  });

  final String name;
  final String languageCode;
  final bool showTeacherAiSeat;
  final bool isPrivate;
  final bool vipOnly;
}

String _languageLabel(String code) {
  const names = <String, String>{
    'ar': 'العربية',
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'pt': 'Português',
    'tr': 'Türkçe',
    'ru': 'Русский',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'ur': 'اردو',
    'fa': 'فارسی',
    'id': 'Indonesia',
    'th': 'ไทย',
    'hi': 'हिन्दी',
  };

  return names[code.toLowerCase()] ?? code.toUpperCase();
}
