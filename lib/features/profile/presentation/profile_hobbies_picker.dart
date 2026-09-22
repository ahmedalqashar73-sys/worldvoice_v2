import 'package:flutter/material.dart';

const profileHobbyKeys = <String>[
  'music',
  'movies',
  'football',
  'basketball',
  'volleyball',
  'tennis',
  'swimming',
  'running',
  'gym',
  'martialArts',
  'cycling',
  'padel',
  'boxing',
  'yoga',
  'hiking',
  'travel_hobby',
  'gaming',
  'reading',
  'photography',
  'drawing',
  'cooking',
  'technology',
  'dancing',
  'singing',
  'writing',
  'fashion',
  'gardening',
  'cars',
  'nature',
  'chess',
  'pets',
];

String profileHobbyEmoji(String key) {
  const icons = <String, String>{
    'music':'🎵',
    'movies':'🎬',
    'football':'⚽',
    'basketball':'🏀',
    'volleyball':'🏐',
    'tennis':'🎾',
    'swimming':'🏊',
    'running':'🏃',
    'gym':'🏋️',
    'martialArts':'🥋',
    'cycling':'🚴',
    'padel':'🏓',
    'boxing':'🥊',
    'yoga':'🧘',
    'hiking':'🥾',
    'travel_hobby':'✈️',
    'gaming':'🎮',
    'reading':'📚',
    'photography':'📷',
    'drawing':'🎨',
    'cooking':'🍳',
    'technology':'💻',
    'dancing':'💃',
    'singing':'🎤',
    'writing':'✍️',
    'fashion':'👗',
    'gardening':'🌱',
    'cars':'🏎️',
    'nature':'🌿',
    'chess':'♟️',
    'pets':'🐾',
  };
  return icons[key] ?? '✨';
}

Future<void> pickProfileHobbies(
  BuildContext context,
  Set<String> selected, {
  required String Function(String key) labelFor,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheet) {
        final colors = Theme.of(sheetContext).colorScheme;
        return FractionallySizedBox(
          heightFactor: .90,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 2, 18, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        labelFor('hobbies'),
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: Text('${selected.length}'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: profileHobbyKeys.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, index) {
                    final key = profileHobbyKeys[index];
                    final checked = selected.contains(key);
                    return Material(
                      color: checked
                          ? colors.primaryContainer.withValues(alpha: .35)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: checked
                              ? colors.primaryContainer
                              : colors.surfaceContainerHighest,
                          child: Text(
                            profileHobbyEmoji(key),
                            style: const TextStyle(fontSize: 21),
                          ),
                        ),
                        title: Text(
                          labelFor(key),
                          style: TextStyle(
                            fontWeight:
                                checked ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(
                          checked
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: checked ? colors.primary : colors.outline,
                        ),
                        onTap: () {
                          setSheet(() {
                            if (checked) {
                              selected.remove(key);
                            } else {
                              selected.add(key);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
