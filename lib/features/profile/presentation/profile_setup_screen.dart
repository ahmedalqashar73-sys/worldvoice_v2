import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/localization/locale_controller.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({required this.localeController, super.key});
  final LocaleController localeController;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final name = TextEditingController();
  final username = TextEditingController();
  final bio = TextEditingController();
  final city = TextEditingController();
  final profession = TextEditingController();
  final travel = TextEditingController();
  final learningGoal = TextEditingController();
  final hobbies = TextEditingController();
  String? nativeLanguage;
  String? learningLanguage;
  String languageLevel = 'beginner';
  bool cityVisible = true;
  final city = TextEditingController();
  final profession = TextEditingController();
  final travel = TextEditingController();
  final learningGoals = TextEditingController();
  final interests = TextEditingController();
  final nativeLanguage = TextEditingController();
  final learningLanguage = TextEditingController();
  String languageLevel = 'beginner';
  bool? usernameAvailable;
  bool saving = false;
  String? country;
  String? gender;
  String? nativeLanguage;
  String? learningLanguage;
  String languageLevel = 'beginner';
  final city = TextEditingController();
  final profession = TextEditingController();
  final travel = TextEditingController();
  final goals = TextEditingController();
  final interests = TextEditingController();
  DateTime? birthDate;
  XFile? profileImage;
  XFile? coverImage;
  final city = TextEditingController();
  final job = TextEditingController();
  final travel = TextEditingController();
  final goals = TextEditingController();
  final hobbies = TextEditingController();
  String nativeLanguage = '';
  String learningLanguage = '';
  String languageLevel = 'beginner';
  String? nativeLanguage;
  String? learningLanguage;
  String languageLevel = 'beginner';
  final city = TextEditingController();
  final profession = TextEditingController();
  final travel = TextEditingController();
  final learningGoals = TextEditingController();
  final interests = TextEditingController();

  static const languages = <String>['Arabic','Chinese','English','French','German','Hindi','Indonesian','Italian','Japanese','Korean','Persian','Portuguese','Russian','Spanish','Thai','Turkish','Urdu'];

  static const countries = <String>[
    'Afghanistan','Albania','Algeria','Andorra','Angola','Antigua and Barbuda','Argentina','Armenia','Australia','Austria','Azerbaijan','Bahamas','Bahrain','Bangladesh','Barbados','Belarus','Belgium','Belize','Benin','Bhutan','Bolivia','Bosnia and Herzegovina','Botswana','Brazil','Brunei','Bulgaria','Burkina Faso','Burundi','Cabo Verde','Cambodia','Cameroon','Canada','Central African Republic','Chad','Chile','China','Colombia','Comoros','Congo','Costa Rica','Croatia','Cuba','Cyprus','Czechia','Denmark','Djibouti','Dominica','Dominican Republic','Ecuador','Egypt','El Salvador','Equatorial Guinea','Eritrea','Estonia','Eswatini','Ethiopia','Fiji','Finland','France','Gabon','Gambia','Georgia','Germany','Ghana','Greece','Grenada','Guatemala','Guinea','Guinea-Bissau','Guyana','Haiti','Honduras','Hungary','Iceland','India','Indonesia','Iran','Iraq','Ireland','Israel','Italy','Ivory Coast','Jamaica','Japan','Jordan','Kazakhstan','Kenya','Kiribati','Kuwait','Kyrgyzstan','Laos','Latvia','Lebanon','Lesotho','Liberia','Libya','Liechtenstein','Lithuania','Luxembourg','Madagascar','Malawi','Malaysia','Maldives','Mali','Malta','Marshall Islands','Mauritania','Mauritius','Mexico','Micronesia','Moldova','Monaco','Mongolia','Montenegro','Morocco','Mozambique','Myanmar','Namibia','Nauru','Nepal','Netherlands','New Zealand','Nicaragua','Niger','Nigeria','North Korea','North Macedonia','Norway','Oman','Pakistan','Palau','Palestine','Panama','Papua New Guinea','Paraguay','Peru','Philippines','Poland','Portugal','Qatar','Romania','Russia','Rwanda','Saint Kitts and Nevis','Saint Lucia','Saint Vincent and the Grenadines','Samoa','San Marino','Sao Tome and Principe','Saudi Arabia','Senegal','Serbia','Seychelles','Sierra Leone','Singapore','Slovakia','Slovenia','Solomon Islands','Somalia','South Africa','South Korea','South Sudan','Spain','Sri Lanka','Sudan','Suriname','Sweden','Switzerland','Syria','Tajikistan','Tanzania','Thailand','Timor-Leste','Togo','Tonga','Trinidad and Tobago','Tunisia','Turkey','Turkmenistan','Tuvalu','Uganda','Ukraine','United Arab Emirates','United Kingdom','United States','Uruguay','Uzbekistan','Vanuatu','Vatican City','Venezuela','Vietnam','Yemen','Zambia','Zimbabwe'
  ];

  Future<void> pickImage(bool cover) async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (image != null && mounted) setState(() => cover ? coverImage = image : profileImage = image);
  }

  Future<void> editText(String title, TextEditingController controller, {int lines = 1}) async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(title, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        TextField(controller: controller, maxLines: lines, autofocus: true),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('حفظ'))),
      ]),
    ));
    if (mounted) setState(() {});
  }

  Future<void> pickLanguage() async {
    const languages = ['Arabic','Chinese','English','French','German','Hindi','Indonesian','Italian','Japanese','Korean','Persian','Portuguese','Russian','Spanish','Thai','Turkish','Urdu'];
    final v = await showModalBottomSheet<String>(context: context, builder: (ctx) => SafeArea(child: ListView(children: languages.map((e)=>ListTile(title:Text(e), onTap:()=>Navigator.pop(ctx,e))).toList())));
    if(v != null && mounted) setState(()=>learningLanguage=v);
  }

  Future<void> pickBirthDate() async {
    final value = await showDatePicker(context: context, initialDate: DateTime(2000,1,1), firstDate: DateTime(1900), lastDate: DateTime.now());
    if (value != null && mounted) setState(() => birthDate = value);
  }

  Future<String?> pickFromList(String title, List<String> values) => showModalBottomSheet<String>(context: context, isScrollControlled: true, builder: (ctx) => SafeArea(child: SizedBox(height: MediaQuery.sizeOf(ctx).height * .7, child: Column(children: [Padding(padding: const EdgeInsets.all(16), child: Text(title, style: const TextStyle(fontSize:20,fontWeight:FontWeight.bold))), Expanded(child: ListView.builder(itemCount: values.length, itemBuilder: (_,i)=>ListTile(title: Text(values[i]), onTap:()=>Navigator.pop(ctx,values[i]))))]))));

  Future<void> pickCountry() async {
    final value = await showModalBottomSheet<String>(context: context, isScrollControlled: true, builder: (ctx) => SafeArea(child: SizedBox(height: MediaQuery.sizeOf(ctx).height * .78, child: ListView.builder(itemCount: countries.length, itemBuilder: (_, i) => ListTile(title: Text(countries[i]), onTap: () => Navigator.pop(ctx, countries[i]))))));
    if (value != null && mounted) setState(() => country = value);
  }

  String get normalizedUsername =>
      username.text.trim().toLowerCase().replaceFirst('@', '');

  Future<void> checkUsername() async {
    final value = normalizedUsername;
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(value)) {
      setState(() => usernameAvailable = false);
      return;
    }
    final doc =
        await FirebaseFirestore.instance.collection('usernames').doc(value).get();
    if (mounted) {
      setState(() => usernameAvailable = !doc.exists ||
          doc.data()?['uid'] == FirebaseAuth.instance.currentUser?.uid);
    }
  }

  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || name.text.trim().isEmpty || usernameAvailable != true) {
      return;
    }
    setState(() => saving = true);
    final db = FirebaseFirestore.instance;
    try {
      await db.runTransaction((tx) async {
        final handle = db.collection('usernames').doc(normalizedUsername);
        final existing = await tx.get(handle);
        if (existing.exists && existing.data()?['uid'] != user.uid) {
          throw StateError('username-taken');
        }
        tx.set(handle, {
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.set(db.collection('users').doc(user.uid), {
          'uid': user.uid,
          'email': user.email,
          'displayName': name.text.trim(),
          'username': normalizedUsername,
          'bio': bio.text.trim(),
          'city': city.text.trim(),
          'cityVisible': cityVisible,
          'profession': profession.text.trim(),
          'travel': travel.text.trim(),
          'learningGoal': learningGoal.text.trim(),
          'hobbies': hobbies.text.trim(),
          'nativeLanguage': nativeLanguage,
          'learningLanguages': learningLanguage == null ? <String>[] : [learningLanguage],
          'languageLevel': languageLevel,
          'photoUrl': user.photoURL,
          'coverUrl': null,
          'voiceBioUrl': null,
          'city': city.text.trim(),
          'profession': profession.text.trim(),
          'travel': travel.text.trim(),
          'learningGoals': learningGoals.text.trim(),
          'interests': interests.text.trim(),
          'nativeLanguage': nativeLanguage.text.trim(),
          'learningLanguage': learningLanguage.text.trim(),
          'languageLevel': languageLevel,
          'country': country,
          'city': city.text.trim(),
          'gender': gender,
          'nativeLanguage': nativeLanguage,
          'learningLanguages': learningLanguage == null ? <String>[] : [learningLanguage],
          'languageLevel': languageLevel,
          'profession': profession.text.trim(),
          'travel': travel.text.trim(),
          'learningGoals': learningGoals.text.trim(),
          'interests': interests.text.trim(),
          'birthDate': birthDate == null ? null : Timestamp.fromDate(birthDate!),
          'city': city.text.trim(), 'job': job.text.trim(), 'travel': travel.text.trim(),
          'learningGoals': goals.text.trim(), 'hobbies': hobbies.text.trim(),
          'nativeLanguage': nativeLanguage, 'learningLanguages': learningLanguage.isEmpty ? <String>[] : [learningLanguage],
          'languageLevel': languageLevel,
          'profileImageLocalName': profileImage?.name, 'coverImageLocalName': coverImage?.name,
          'profileCompleted': true,
          'followersCount': 0,
          'followingCount': 0,
          'isVip': false,
          'isPartner': false,
          'isVerified': false,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF159B62),
          content: Text('تم حفظ البروفايل بنجاح ✓',
              style: TextStyle(color: Colors.white)),
        ));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _editText(TextEditingController controller, String title, {int maxLines = 1}) async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20,20,20,MediaQuery.viewInsetsOf(ctx).bottom+20),
      child: Column(mainAxisSize: MainAxisSize.min, children:[
        Text(title, style: const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        const SizedBox(height:14),
        TextField(controller: controller, maxLines:maxLines, autofocus:true),
        const SizedBox(height:14),
        SizedBox(width:double.infinity, child:FilledButton(onPressed:(){Navigator.pop(ctx); setState((){});}, child:const Text('حفظ'))),
      ]),
    ));
  }

  Future<void> _editLanguages(bool rtl) async {
    await showModalBottomSheet<void>(context: context, isScrollControlled:true, builder:(ctx)=>Padding(
      padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.viewInsetsOf(ctx).bottom+20),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        Text(rtl?'اللغات والمستوى':'Languages & level',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        TextField(controller:nativeLanguage,decoration:InputDecoration(labelText:rtl?'اللغة الأم':'Native language')),
        TextField(controller:learningLanguage,decoration:InputDecoration(labelText:rtl?'اللغة التي تتعلمها':'Learning language')),
        DropdownButtonFormField<String>(initialValue:languageLevel,items:[
          DropdownMenuItem(value:'beginner',child:Text(rtl?'مبتدئ':'Beginner')),
          DropdownMenuItem(value:'intermediate',child:Text(rtl?'متوسط':'Intermediate')),
          DropdownMenuItem(value:'advanced',child:Text(rtl?'متقدم':'Advanced')),
        ],onChanged:(v)=>languageLevel=v??languageLevel),
        const SizedBox(height:14),
        SizedBox(width:double.infinity,child:FilledButton(onPressed:(){Navigator.pop(ctx);setState((){});},child:Text(rtl?'حفظ':'Save'))),
      ]),
    ));
  }

  Future<void> _editWorkTravel(bool rtl) async {
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,builder:(ctx)=>Padding(
      padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.viewInsetsOf(ctx).bottom+20),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:profession,decoration:InputDecoration(labelText:rtl?'المهنة / الدراسة':'Profession / study')),
        const SizedBox(height:10),
        TextField(controller:travel,maxLines:2,decoration:InputDecoration(labelText:rtl?'السفر':'Travel')),
        const SizedBox(height:14),
        SizedBox(width:double.infinity,child:FilledButton(onPressed:(){Navigator.pop(ctx);setState((){});},child:Text(rtl?'حفظ':'Save'))),
      ]),
    ));
  }

  Future<void> _editText(String title, TextEditingController controller) async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (ctx) => Padding(padding: EdgeInsets.fromLTRB(20,20,20,MediaQuery.viewInsetsOf(ctx).bottom+20), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(title, style: const TextStyle(fontSize:20,fontWeight:FontWeight.w800)), const SizedBox(height:14), TextField(controller: controller, maxLines: 3, autofocus: true), const SizedBox(height:14), SizedBox(width: double.infinity, child: FilledButton(onPressed: () { Navigator.pop(ctx); setState(() {}); }, child: const Text('حفظ')))])));
  }

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    bio.dispose();
    city.dispose(); job.dispose(); travel.dispose(); goals.dispose(); hobbies.dispose();
    city.dispose();
    profession.dispose();
    travel.dispose();
    learningGoal.dispose();
    hobbies.dispose();
    city.dispose();
    profession.dispose();
    travel.dispose();
    learningGoals.dispose();
    interests.dispose();
    nativeLanguage.dispose();
    learningLanguage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = const {'ar', 'ur', 'fa'}
        .contains(widget.localeController.locale?.languageCode);
    final scheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(rtl ? 'أنشئ هويتك في WorldVoice' : 'Create your WorldVoice identity',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              Container(height: 145, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [scheme.primary.withValues(alpha: .7), scheme.tertiary.withValues(alpha: .45)])), child: Stack(children: [Positioned(top: 10, left: 10, child: IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.wallpaper_rounded, size: 20))), const Center(child: Icon(Icons.landscape_rounded, size: 48))])),
              const SizedBox(height: 16),
              GestureDetector(onTap: () => pickImage(true), child: Container(height: 110, decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: scheme.surfaceContainerHighest), child: Center(child: Text(coverImage == null ? (rtl ? 'إضافة خلفية البروفايل' : 'Add profile cover') : (rtl ? 'تم اختيار الخلفية ✓' : 'Cover selected ✓'))))),
              const SizedBox(height: 14),
              Center(child: GestureDetector(onTap: () => pickImage(false), child: Container(
                width: 124, height: 124,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [scheme.primary, scheme.tertiary])),
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(backgroundColor: scheme.surfaceContainerHighest, child: Icon(profileImage == null ? Icons.person_rounded : Icons.check_rounded, size: 62)),
              ))),
              const SizedBox(height: 28),
              _Field(controller: name, label: rtl ? 'الاسم' : 'Name', icon: Icons.badge_outlined),
              const SizedBox(height: 14),
              TextField(
                controller: username,
                textDirection: TextDirection.ltr,
                onChanged: (_) => setState(() => usernameAvailable = null),
                decoration: InputDecoration(
                  labelText: rtl ? 'اسم المستخدم الفريد' : 'Unique username',
                  hintText: '@username',
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  suffixIcon: IconButton(
                    onPressed: checkUsername,
                    icon: Icon(
                      usernameAvailable == true ? Icons.check_circle_rounded :
                      usernameAvailable == false ? Icons.cancel_rounded : Icons.search_rounded,
                      color: usernameAvailable == true ? Colors.green : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(rtl ? '3–20 حرفًا: إنجليزي، أرقام و _. لا يمكن تكراره.' : '3–20 characters: letters, numbers and _. Must be unique.'),
              const SizedBox(height: 18),
              _Field(controller: bio, label: rtl ? 'ماذا عنك؟' : 'About you', icon: Icons.auto_awesome_rounded, maxLines: 3),
              Align(
                alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(rtl ? 'تسجيل الصوت سيكون الخطوة التالية.' : 'Voice recording is the next step.'))),
                  icon: const Icon(Icons.mic_rounded, size: 18),
                  label: Text(rtl ? 'تسجيل صوت' : 'Record voice'),
                ),
              ),
              const SizedBox(height: 12),
              _PremiumTile(icon: Icons.language_rounded, title: rtl ? 'اللغات والمستوى' : 'Languages & level', subtitle: rtl ? 'أضف لغتك الأم واللغة التي تتعلمها' : 'Add your native and learning languages', onTap: () => _editLanguages(rtl)),
              _PremiumTile(icon: Icons.public_rounded, title: rtl ? 'الدولة والمدينة' : 'Country & city', subtitle: [country, city.text.trim()].whereType<String>().where((e)=>e.isNotEmpty).join(' • ').isEmpty ? (rtl ? 'اختر الدولة والمدينة' : 'Choose country & city') : [country, city.text.trim()].whereType<String>().where((e)=>e.isNotEmpty).join(' • '), onTap: () async { await pickCountry(); if (mounted) await _editText(city, rtl ? 'المدينة' : 'City'); }),
              _PremiumTile(icon: Icons.cake_outlined, title: rtl ? 'تاريخ الميلاد' : 'Date of birth', subtitle: birthDate == null ? (rtl ? 'اليوم / الشهر / السنة' : 'Day / month / year') : '${birthDate!.day} / ${birthDate!.month} / ${birthDate!.year}', onTap: pickBirthDate),
              _PremiumTile(icon: Icons.person_outline_rounded, title: rtl ? 'الجنس' : 'Gender', subtitle: gender ?? (rtl ? 'ذكر • أنثى • أفضل عدم الإجابة' : 'Male • Female • Prefer not to say'), onTap: () async { final v = await showModalBottomSheet<String>(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(title: Text(rtl ? 'ذكر' : 'Male'), onTap:()=>Navigator.pop(ctx,'male')), ListTile(title: Text(rtl ? 'أنثى' : 'Female'), onTap:()=>Navigator.pop(ctx,'female')), ListTile(title: Text(rtl ? 'أفضل عدم الإجابة' : 'Prefer not to say'), onTap:()=>Navigator.pop(ctx,'prefer_not_to_say'))]))); if(v != null && mounted) setState(()=>gender=v); }),
              _PremiumTile(icon: Icons.favorite_outline_rounded, title: rtl ? 'الهوايات والاهتمامات' : 'Interests & hobbies', subtitle: interests.text.isEmpty ? (rtl ? 'للمطابقة اللغوية الذكية' : 'For smarter matching') : interests.text, onTap: ()=>_editText(interests, rtl ? 'الهوايات والاهتمامات' : 'Interests & hobbies', maxLines: 3)),
              _PremiumTile(icon: Icons.track_changes_rounded, title: rtl ? 'أهداف التعلم' : 'Learning goals', subtitle: learningGoals.text.isEmpty ? (rtl ? 'حدد ما تريد تحقيقه' : 'Define what you want to achieve') : learningGoals.text, onTap: ()=>_editText(learningGoals, rtl ? 'أهداف التعلم' : 'Learning goals', maxLines: 3)),
              _PremiumTile(icon: Icons.work_outline_rounded, title: rtl ? 'المهنة والسفر' : 'Work & travel', subtitle: rtl ? 'أضف مهنتك وتجارب السفر' : 'Add your work and travel', onTap: ()=>_editWorkTravel(rtl)),
              const SizedBox(height: 24),
              SizedBox(
                height: 58,
                child: FilledButton.icon(
                  onPressed: saving ? null : saveProfile,
                  icon: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.rocket_launch_rounded),
                  label: Text(rtl ? 'إطلاق بروفايلي' : 'Launch my profile',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, required this.icon, this.maxLines = 1});
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      );
}

class _PremiumTile extends StatelessWidget {
  const _PremiumTile({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 11),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          leading: CircleAvatar(radius: 18, child: Icon(icon, size: 19)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      );
}
