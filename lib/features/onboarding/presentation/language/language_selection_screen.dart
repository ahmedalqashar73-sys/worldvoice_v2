import 'package:flutter/material.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../../../core/localization/supported_language.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({
    required this.controller,
    super.key,
  });

  final LocaleController controller;

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.controller.locale?.languageCode ?? 'en';
    final query = _query.trim().toLowerCase();
    final languages = SupportedLanguages.all.where((language) {
      if (query.isEmpty) return true;
      return language.nativeName.toLowerCase().contains(query) ||
          language.englishName.toLowerCase().contains(query) ||
          language.code.contains(query);
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.language_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Choose your language',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                        ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'You can change this anytime in WorldVoice settings.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65),
                        ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: 'Search languages',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: languages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 7),
                itemBuilder: (context, index) {
                  final language = languages[index];
                  final isSelected = language.code == selected;
                  return Material(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: .10)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => widget.controller.select(language.code),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    language.nativeName,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  if (language.nativeName != language.englishName) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      language.englishName,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: .55),
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: isSelected
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      key: const ValueKey('selected'),
                                      color: Theme.of(context).colorScheme.primary,
                                    )
                                  : const SizedBox(
                                      key: ValueKey('empty'),
                                      width: 24,
                                      height: 24,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
