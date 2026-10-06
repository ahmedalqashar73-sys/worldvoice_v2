import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../../profile/presentation/public_profile_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({required this.localeController, super.key});

  final LocaleController localeController;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late Future<_DiscoverData> _data = _load();

  Future<_DiscoverData> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in to use Discover.');
    }

    final db = FirebaseFirestore.instance;
    final meSnapshot = await db.collection('users').doc(user.uid).get();
    final meData = meSnapshot.data() ?? const <String, dynamic>{};
    final me = _DiscoverProfile.fromFirestore(user.uid, meData);

    final usersSnapshot = await db.collection('users').limit(100).get();
    final candidates = usersSnapshot.docs
        .where((doc) => doc.id != user.uid)
        .map((doc) => _DiscoverProfile.fromFirestore(doc.id, doc.data()))
        .where((profile) => profile.hasIdentity)
        .toList(growable: false);

    final matches = candidates
        .map((profile) => _DiscoverMatch.fromProfiles(me, profile))
        .where((match) => match.relevanceScore > 0)
        .toList(growable: false)
      ..sort((a, b) {
        final score = b.relevanceScore.compareTo(a.relevanceScore);
        if (score != 0) return score;
        if (a.profile.isOnline != b.profile.isOnline) {
          return a.profile.isOnline ? -1 : 1;
        }
        return a.profile.displayName
            .toLowerCase()
            .compareTo(b.profile.displayName.toLowerCase());
      });

    return _DiscoverData(
      me: me,
      allMatches: matches,
      bestMatches: matches.take(20).toList(growable: false),
      nativeSpeakers: matches
          .where((match) => match.nativeForMyLearning)
          .take(20)
          .toList(growable: false),
      exchangePartners: matches
          .where((match) => match.languageExchange)
          .take(20)
          .toList(growable: false),
      sharedInterests: matches
          .where((match) => match.sharedInterests.isNotEmpty)
          .take(20)
          .toList(growable: false),
      learningTogether: matches
          .where((match) => match.sharedLearningLanguages.isNotEmpty)
          .take(20)
          .toList(growable: false),
      onlineNow: matches
          .where((match) => match.profile.isOnline)
          .take(20)
          .toList(growable: false),
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _data = next);
    await next;
  }

  void _openProfile(_DiscoverProfile profile) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicProfileScreen(
          userId: profile.uid,
          localeController: widget.localeController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.localeController.locale?.languageCode ?? 'en';
    final rtl = const {'ar', 'ur', 'fa'}.contains(code);
    final ar = code == 'ar';

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<_DiscoverData>(
            future: _data,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 220),
                    Center(child: CircularProgressIndicator()),
                  ],
                );
              }

              if (snapshot.hasError) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(22),
                  children: [
                    const SizedBox(height: 140),
                    Icon(
                      Icons.travel_explore_rounded,
                      size: 58,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ar
                          ? 'تعذر تحميل الأشخاص المقترحين الآن.'
                          : 'Could not load Discover suggestions right now.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: FilledButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                      ),
                    ),
                  ],
                );
              }

              final data = snapshot.data!;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ar ? 'اكتشف' : 'Discover',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        tooltip: ar ? 'تحديث' : 'Refresh',
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _discoverSubtitle(data.me, ar),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: .68),
                        ),
                  ),
                  const SizedBox(height: 18),
                  if (data.allMatches.isEmpty)
                    _EmptyDiscover(isArabic: ar)
                  else ...[
                    _DiscoverSection(
                      title: ar ? 'أفضل تطابق لك' : 'Best matches for you',
                      subtitle: ar
                          ? 'حسب اللغة، الاهتمامات، والهوايات المشتركة.'
                          : 'Based on language, shared interests, and profile fit.',
                      matches: data.bestMatches,
                      isArabic: ar,
                      onOpen: _openProfile,
                    ),
                    _DiscoverSection(
                      title: ar
                          ? 'متحدثون أصليون بلغتك المستهدفة'
                          : 'Native speakers for your target language',
                      subtitle: ar
                          ? 'أشخاص لغتهم الأم إحدى اللغات التي تتعلمها.'
                          : 'People whose native language is one you are learning.',
                      matches: data.nativeSpeakers,
                      isArabic: ar,
                      onOpen: _openProfile,
                    ),
                    _DiscoverSection(
                      title: ar ? 'تبادل لغوي مناسب' : 'Language exchange',
                      subtitle: ar
                          ? 'هم يتكلمون ما تتعلمه، ويتعلمون لغتك الأم.'
                          : 'They speak what you learn and learn your native language.',
                      matches: data.exchangePartners,
                      isArabic: ar,
                      onOpen: _openProfile,
                    ),
                    _DiscoverSection(
                      title: ar ? 'نفس اهتماماتك' : 'People with your interests',
                      subtitle: ar
                          ? 'أشخاص يشاركونك نفس الهوايات والاهتمامات.'
                          : 'People who share your hobbies and interests.',
                      matches: data.sharedInterests,
                      isArabic: ar,
                      onOpen: _openProfile,
                    ),
                    _DiscoverSection(
                      title: ar ? 'يتعلمون نفس لغتك' : 'Learning with you',
                      subtitle: ar
                          ? 'أشخاص يتعلمون نفس اللغات التي تتعلمها.'
                          : 'People learning the same languages as you.',
                      matches: data.learningTogether,
                      isArabic: ar,
                      onOpen: _openProfile,
                    ),
                    _DiscoverSection(
                      title: ar ? 'متصلون الآن' : 'Online now',
                      subtitle: ar
                          ? 'أشخاص مناسبون لك ومتصلون الآن.'
                          : 'Relevant people who are online right now.',
                      matches: data.onlineNow,
                      isArabic: ar,
                      onOpen: _openProfile,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _discoverSubtitle(_DiscoverProfile me, bool ar) {
    final target = me.learningLanguages.isEmpty
        ? null
        : me.learningLanguages.take(2).join(' • ');
    final interests =
        me.interests.isEmpty ? null : me.interests.take(2).join(' • ');

    if (ar) {
      if (target != null && interests != null) {
        return 'نرشّح لك أشخاصًا يناسبون تعلم $target واهتماماتك مثل $interests.';
      }
      if (target != null) {
        return 'نرشّح لك أشخاصًا مناسبين للغات التي تتعلمها: $target.';
      }
      return 'أكمل لغاتك واهتماماتك في البروفايل لتحصل على اقتراحات أدق.';
    }

    if (target != null && interests != null) {
      return 'People matched to $target and interests like $interests.';
    }
    if (target != null) {
      return 'People matched to the languages you are learning: $target.';
    }
    return 'Add languages and interests to your profile for better matches.';
  }
}

class _DiscoverSection extends StatelessWidget {
  const _DiscoverSection({
    required this.title,
    required this.subtitle,
    required this.matches,
    required this.isArabic,
    required this.onOpen,
  });

  final String title;
  final String subtitle;
  final List<_DiscoverMatch> matches;
  final bool isArabic;
  final ValueChanged<_DiscoverProfile> onOpen;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: .64),
                ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 238,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: matches.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final match = matches[index];
                return SizedBox(
                  width: 176,
                  child: _DiscoverPersonCard(
                    match: match,
                    isArabic: isArabic,
                    onTap: () => onOpen(match.profile),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverPersonCard extends StatelessWidget {
  const _DiscoverPersonCard({
    required this.match,
    required this.isArabic,
    required this.onTap,
  });

  final _DiscoverMatch match;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final profile = match.profile;
    final photo = profile.photoUrl.trim();
    final reasons = match.reasonLabels(isArabic);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: .45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 13, 12, 11),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundImage:
                        photo.isEmpty ? null : NetworkImage(photo),
                    child: photo.isEmpty
                        ? const Icon(Icons.person_rounded, size: 36)
                        : null,
                  ),
                  if (profile.isOnline)
                    PositionedDirectional(
                      end: 1,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                profile.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              if (profile.username.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '@${profile.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 7),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isArabic
                      ? 'تطابق ${match.matchPercent}%'
                      : '${match.matchPercent}% match',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              for (final reason in reasons.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    reason,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onTap,
                  child: Text(isArabic ? 'عرض البروفايل' : 'View profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDiscover extends StatelessWidget {
  const _EmptyDiscover({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 80, 12, 30),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(
            isArabic
                ? 'لا توجد اقتراحات كافية الآن.'
                : 'Not enough Discover matches yet.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 7),
          Text(
            isArabic
                ? 'أضف لغتك الأم، اللغات التي تتعلمها، واهتماماتك في البروفايل لتحصل على أشخاص أنسب لك.'
                : 'Add your native language, learning languages, and interests for better matches.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DiscoverData {
  const _DiscoverData({
    required this.me,
    required this.allMatches,
    required this.bestMatches,
    required this.nativeSpeakers,
    required this.exchangePartners,
    required this.sharedInterests,
    required this.learningTogether,
    required this.onlineNow,
  });

  final _DiscoverProfile me;
  final List<_DiscoverMatch> allMatches;
  final List<_DiscoverMatch> bestMatches;
  final List<_DiscoverMatch> nativeSpeakers;
  final List<_DiscoverMatch> exchangePartners;
  final List<_DiscoverMatch> sharedInterests;
  final List<_DiscoverMatch> learningTogether;
  final List<_DiscoverMatch> onlineNow;
}

class _DiscoverProfile {
  const _DiscoverProfile({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.photoUrl,
    required this.country,
    required this.nativeLanguage,
    required this.learningLanguages,
    required this.interests,
    required this.isOnline,
  });

  final String uid;
  final String displayName;
  final String username;
  final String photoUrl;
  final String country;
  final String nativeLanguage;
  final List<String> learningLanguages;
  final List<String> interests;
  final bool isOnline;

  bool get hasIdentity => displayName.isNotEmpty || username.isNotEmpty;

  factory _DiscoverProfile.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    List<String> stringList(Object? value) {
      if (value is! List) return const <String>[];
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    return _DiscoverProfile(
      uid: uid,
      displayName:
          (data['displayName'] ?? data['name'] ?? 'WorldVoice').toString().trim(),
      username: (data['username'] ?? '').toString().trim(),
      photoUrl: (data['photoUrl'] ?? '').toString().trim(),
      country: (data['country'] ?? '').toString().trim(),
      nativeLanguage: (data['nativeLanguage'] ?? '').toString().trim(),
      learningLanguages: stringList(data['learningLanguages']),
      interests: stringList(data['interests']),
      isOnline: data['isOnline'] == true,
    );
  }
}

class _DiscoverMatch {
  const _DiscoverMatch({
    required this.profile,
    required this.relevanceScore,
    required this.matchPercent,
    required this.nativeForMyLearning,
    required this.languageExchange,
    required this.sharedInterests,
    required this.sharedLearningLanguages,
  });

  final _DiscoverProfile profile;
  final int relevanceScore;
  final int matchPercent;
  final bool nativeForMyLearning;
  final bool languageExchange;
  final List<String> sharedInterests;
  final List<String> sharedLearningLanguages;

  factory _DiscoverMatch.fromProfiles(
    _DiscoverProfile me,
    _DiscoverProfile other,
  ) {
    final myLearning = me.learningLanguages.map(_normalize).toSet();
    final otherLearning = other.learningLanguages.map(_normalize).toSet();
    final myInterests = me.interests.map(_normalize).toSet();
    final otherInterests = other.interests.map(_normalize).toSet();
    final myNative = _normalize(me.nativeLanguage);
    final otherNative = _normalize(other.nativeLanguage);

    final nativeForMyLearning =
        otherNative.isNotEmpty && myLearning.contains(otherNative);
    final learnsMyNative =
        myNative.isNotEmpty && otherLearning.contains(myNative);
    final languageExchange = nativeForMyLearning && learnsMyNative;

    final sharedInterestKeys = myInterests.intersection(otherInterests);
    final sharedLearningKeys = myLearning.intersection(otherLearning);

    String originalFor(String key, List<String> values) {
      for (final value in values) {
        if (_normalize(value) == key) return value;
      }
      return '';
    }

    final sharedInterests = <String>[];
    for (final key in sharedInterestKeys) {
      final value = originalFor(key, other.interests);
      if (value.isNotEmpty) sharedInterests.add(value);
    }

    final sharedLearningLanguages = <String>[];
    for (final key in sharedLearningKeys) {
      final value = originalFor(key, other.learningLanguages);
      if (value.isNotEmpty) sharedLearningLanguages.add(value);
    }

    var score = 0;
    if (nativeForMyLearning) score += 45;
    if (learnsMyNative) score += 28;
    if (languageExchange) score += 18;

    final interestPoints = sharedInterests.length * 8;
    score += interestPoints > 24 ? 24 : interestPoints;

    final learningPoints = sharedLearningLanguages.length * 7;
    score += learningPoints > 14 ? 14 : learningPoints;

    if (other.isOnline) score += 5;

    var percent = score <= 0 ? 0 : 42 + score ~/ 2;
    if (percent > 99) percent = 99;
    if (percent > 0 && percent < 45) percent = 45;

    return _DiscoverMatch(
      profile: other,
      relevanceScore: score,
      matchPercent: percent,
      nativeForMyLearning: nativeForMyLearning,
      languageExchange: languageExchange,
      sharedInterests: sharedInterests,
      sharedLearningLanguages: sharedLearningLanguages,
    );
  }

  List<String> reasonLabels(bool ar) {
    final labels = <String>[];
    if (languageExchange) {
      labels.add(ar ? 'تبادل لغوي ممتاز' : 'Great language exchange');
    } else if (nativeForMyLearning) {
      labels.add(ar ? 'متحدث أصلي للغتك' : 'Native speaker for your target');
    }

    if (sharedInterests.isNotEmpty) {
      final text = sharedInterests.take(2).join(' • ');
      labels.add(
        ar ? 'اهتمامات مشتركة: $text' : 'Shared interests: $text',
      );
    }

    if (sharedLearningLanguages.isNotEmpty) {
      final text = sharedLearningLanguages.take(2).join(' • ');
      labels.add(ar ? 'تتعلمون: $text' : 'Both learning: $text');
    }

    if (profile.isOnline) {
      labels.add(ar ? 'متصل الآن' : 'Online now');
    }

    if (labels.isEmpty && profile.country.isNotEmpty) {
      labels.add(profile.country);
    }

    return labels;
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
