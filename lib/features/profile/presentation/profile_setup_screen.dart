import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/media/cloudinary_image_service.dart';
import '../../home/presentation/home_screen.dart';
import '../data/profile_language_catalog.dart';
import '../data/profession_catalog.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({required this.localeController, super.key});
  final LocaleController localeController;
  @override State<ProfileSetupScreen> createState()=>_ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final name=TextEditingController(), username=TextEditingController(), bio=TextEditingController(),
      city=TextEditingController(), profession=TextEditingController(), travel=TextEditingController(),
      goals=TextEditingController(), interests=TextEditingController();
  bool? usernameAvailable; bool saving=false;
  final ImagePicker _imagePicker=ImagePicker();
  File? profileImage, coverImage;
  String? photoUrl, photoPublicId, coverUrl, coverPublicId;
  String? country, gender, nativeLanguage, learningLanguage, professionKey;
  String languageLevel='beginner'; DateTime? birthDate;
  final Set<String> selectedHobbies={};

  static const countries = <String>[
    'Afghanistan','Albania','Algeria','Andorra','Angola','Antigua and Barbuda','Argentina','Armenia','Australia','Austria','Azerbaijan','Bahamas','Bahrain','Bangladesh','Barbados','Belarus','Belgium','Belize','Benin','Bhutan','Bolivia','Bosnia and Herzegovina','Botswana','Brazil','Brunei','Bulgaria','Burkina Faso','Burundi','Cabo Verde','Cambodia','Cameroon','Canada','Central African Republic','Chad','Chile','China','Colombia','Comoros','Congo','Costa Rica','Croatia','Cuba','Cyprus','Czechia','Denmark','Djibouti','Dominica','Dominican Republic','Ecuador','Egypt','El Salvador','Equatorial Guinea','Eritrea','Estonia','Eswatini','Ethiopia','Fiji','Finland','France','Gabon','Gambia','Georgia','Germany','Ghana','Greece','Grenada','Guatemala','Guinea','Guinea-Bissau','Guyana','Haiti','Honduras','Hungary','Iceland','India','Indonesia','Iran','Iraq','Ireland','Italy','Ivory Coast','Jamaica','Japan','Jordan','Kazakhstan','Kenya','Kiribati','Kuwait','Kyrgyzstan','Laos','Latvia','Lebanon','Lesotho','Liberia','Libya','Liechtenstein','Lithuania','Luxembourg','Madagascar','Malawi','Malaysia','Maldives','Mali','Malta','Marshall Islands','Mauritania','Mauritius','Mexico','Micronesia','Moldova','Monaco','Mongolia','Montenegro','Morocco','Mozambique','Myanmar','Namibia','Nauru','Nepal','Netherlands','New Zealand','Nicaragua','Niger','Nigeria','North Korea','North Macedonia','Norway','Oman','Pakistan','Palau','Palestine','Panama','Papua New Guinea','Paraguay','Peru','Philippines','Poland','Portugal','Qatar','Romania','Russia','Rwanda','Saint Kitts and Nevis','Saint Lucia','Saint Vincent and the Grenadines','Samoa','San Marino','Sao Tome and Principe','Saudi Arabia','Senegal','Serbia','Seychelles','Sierra Leone','Singapore','Slovakia','Slovenia','Solomon Islands','Somalia','South Africa','South Korea','South Sudan','Spain','Sri Lanka','Sudan','Suriname','Sweden','Switzerland','Syria','Tajikistan','Tanzania','Thailand','Timor-Leste','Togo','Tonga','Trinidad and Tobago','Tunisia','Turkey','Turkmenistan','Tuvalu','Uganda','Ukraine','United Arab Emirates','United Kingdom','United States','Uruguay','Uzbekistan','Vanuatu','Vatican City','Venezuela','Vietnam','Yemen','Zambia','Zimbabwe'
  ];

  String get normalizedUsername=>username.text.trim().toLowerCase().replaceFirst('@','');

  Future<String?> choose(String title,List<String> values,{String Function(String)? label,bool showFlags=false}) => showModalBottomSheet<String>(
    context:context,isScrollControlled:true,builder:(ctx)=>SafeArea(child:SizedBox(height:MediaQuery.sizeOf(ctx).height*.72,
    child:Column(children:[Padding(padding:const EdgeInsets.all(16),child:Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800))),
    Expanded(child:ListView.builder(itemCount:values.length,itemBuilder:(_,i)=>ListTile(leading:showFlags?Text(_flagForCountry(values[i]),style:const TextStyle(fontSize:25)):null,title:Text(label?.call(values[i])??values[i]),onTap:()=>Navigator.pop(ctx,values[i]))))]))));

  Future<String?> chooseProfileLanguage(String title) async {
    return showModalBottomSheet<String>(
      context:context,
      isScrollControlled:true,
      useSafeArea:true,
      showDragHandle:true,
      builder:(ctx)=>StatefulBuilder(builder:(ctx,setSheet){
        var query='';
        return StatefulBuilder(builder:(ctx,setInner){
          final filtered=ProfileLanguageCatalog.languages.where((item){
            final q=query.trim().toLowerCase();
            if(q.isEmpty)return true;
            return item.code.toLowerCase().contains(q) ||
                item.englishName.toLowerCase().contains(q) ||
                (item.nativeName??'').toLowerCase().contains(q);
          }).toList();
          return FractionallySizedBox(
            heightFactor:.90,
            child:Column(children:[
              Padding(
                padding:const EdgeInsets.fromLTRB(16,0,16,10),
                child:Text(title,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900)),
              ),
              Padding(
                padding:const EdgeInsets.fromLTRB(14,0,14,10),
                child:TextField(
                  autofocus:false,
                  decoration:InputDecoration(
                    prefixIcon:const Icon(Icons.search_rounded),
                    hintText:_extraText(widget.localeController.locale?.languageCode??'en','searchLanguage'),
                  ),
                  onChanged:(value)=>setInner(()=>query=value),
                ),
              ),
              Expanded(
                child:ListView.builder(
                  keyboardDismissBehavior:ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount:filtered.length,
                  itemBuilder:(_,i){
                    final item=filtered[i];
                    return ListTile(
                      leading:CircleAvatar(child:Text(item.code.toUpperCase(),style:const TextStyle(fontSize:11,fontWeight:FontWeight.w900))),
                      title:Text(item.nativeName??item.englishName,style:const TextStyle(fontWeight:FontWeight.w700)),
                      subtitle:item.nativeName!=null&&item.nativeName!=item.englishName?Text(item.englishName):null,
                      onTap:()=>Navigator.pop(ctx,item.code),
                    );
                  },
                ),
              ),
            ]),
          );
        });
      }),
    );
  }

  Future<String?> chooseProfession(String code) async {
    final values=ProfessionCatalog.options.map((e)=>e.key).toList();
    return choose(
      _profileText(code,'profession'),
      values,
      label:(key)=>ProfessionCatalog.byKey(key)?.label(code)??key,
    );
  }

  Future<void> checkUsername() async {
    if(!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(normalizedUsername)){setState(()=>usernameAvailable=false);return;}
    final d=await FirebaseFirestore.instance.collection('usernames').doc(normalizedUsername).get();
    if(mounted)setState(()=>usernameAvailable=!d.exists||d.data()?['uid']==FirebaseAuth.instance.currentUser?.uid);
  }

  Future<void> pickBirthDate() async {
    final d=await showDatePicker(context:context,initialDate:DateTime(2000),firstDate:DateTime(1900),lastDate:DateTime.now());
    if(d!=null&&mounted)setState(()=>birthDate=d);
  }

  Future<void> pickProfileImage() async {
    final picked=await _imagePicker.pickImage(source:ImageSource.gallery,imageQuality:88,maxWidth:1400);
    if(picked!=null&&mounted)setState(()=>profileImage=File(picked.path));
  }

  Future<void> pickCoverImage() async {
    final picked=await _imagePicker.pickImage(source:ImageSource.gallery,imageQuality:88,maxWidth:2200);
    if(picked!=null&&mounted)setState(()=>coverImage=File(picked.path));
  }

  Future<void> saveProfile() async {
    final user=FirebaseAuth.instance.currentUser;
    final code=widget.localeController.locale?.languageCode??'en';
    if(user==null)return;
    if(name.text.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(_extraText(code,'nameRequired'))));
      return;
    }
    if(!RegExp(r'^[a-z0-9_]{3,20}
      if(profileImage!=null){
        final uploaded=await CloudinaryImageService.uploadImage(profileImage!,folder:'worldvoice/users/${user.uid}/profile');
        photoUrl=uploaded.url; photoPublicId=uploaded.publicId;
      }
      if(coverImage!=null){
        final uploaded=await CloudinaryImageService.uploadImage(coverImage!,folder:'worldvoice/users/${user.uid}/cover');
        coverUrl=uploaded.url; coverPublicId=uploaded.publicId;
      }
      await db.runTransaction((tx)async{
      final handle=db.collection('usernames').doc(normalizedUsername); final old=await tx.get(handle);
      if(old.exists&&old.data()?['uid']!=user.uid)throw StateError('username-taken');
      tx.set(handle,{'uid':user.uid,'createdAt':FieldValue.serverTimestamp()});
      tx.set(db.collection('users').doc(user.uid),{
        'uid':user.uid,'email':user.email,'displayName':name.text.trim(),'username':normalizedUsername,
        'bio':bio.text.trim(),'country':country,'city':city.text.trim(),'gender':gender,
        'photoUrl':photoUrl,'photoPublicId':photoPublicId,'coverUrl':coverUrl,'coverPublicId':coverPublicId,
        'birthDate':birthDate==null?null:Timestamp.fromDate(birthDate!),
        'nativeLanguageCode':nativeLanguage,'nativeLanguage':ProfileLanguageCatalog.englishName(nativeLanguage),
        'learningLanguageCodes':learningLanguage==null?<String>[]:[learningLanguage!],
        'learningLanguages':learningLanguage==null?<String>[]:[ProfileLanguageCatalog.englishName(learningLanguage)],'languageLevel':languageLevel,
        'professionKey':professionKey,'profession':profession.text.trim(),'travel':travel.text.trim(),'learningGoals':goals.text.trim(),
        'interests':selectedHobbies.toList(),'profileCompleted':true,'followersCount':0,'followingCount':0,
        'isVip':false,'isPartner':false,'isVerified':false,'updatedAt':FieldValue.serverTimestamp(),
        'createdAt':FieldValue.serverTimestamp(),
      },SetOptions(merge:true));
    });
    if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor:const Color(0xFF159B62),content:Text(_extraText(code,'saved'),style:const TextStyle(color:Colors.white))));
      await Future<void>.delayed(const Duration(milliseconds:250));
      if(mounted){
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder:(_)=>HomeScreen(localeController:widget.localeController)),
          (route)=>false,
        );
      }
    }
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));
    }finally{if(mounted)setState(()=>saving=false);}
  }

  @override void dispose(){for(final c in [name,username,bio,city,profession,travel,goals,interests]){c.dispose();}super.dispose();}

  @override Widget build(BuildContext context){
    final code=widget.localeController.locale?.languageCode??'en';
    final rtl=const {'ar','ur','fa'}.contains(code); final cs=Theme.of(context).colorScheme;
    String t(String key)=>_profileText(code,key);
    return Directionality(textDirection:rtl?TextDirection.rtl:TextDirection.ltr,child:Scaffold(body:SafeArea(child:ListView(
      padding:const EdgeInsets.fromLTRB(18,16,18,36),children:[
      Text(t('title'),style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),
      const SizedBox(height:18),
      Container(height:150,decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),gradient:LinearGradient(colors:[cs.primary.withValues(alpha:.75),cs.tertiary.withValues(alpha:.45)]),image:coverImage==null?null:DecorationImage(image:FileImage(coverImage!),fit:BoxFit.cover)),
        child:Stack(children:[if(coverImage==null)const Center(child:Icon(Icons.landscape_rounded,size:42)),Positioned(top:8,left:8,child:IconButton.filledTonal(onPressed:pickCoverImage,icon:const Icon(Icons.wallpaper_rounded,size:18)))])),
      Transform.translate(offset:const Offset(0,-28),child:Center(child:Container(width:104,height:104,padding:const EdgeInsets.all(3),decoration:BoxDecoration(shape:BoxShape.circle,color:cs.surface),
        child:CircleAvatar(backgroundColor:cs.surfaceContainerHighest,backgroundImage:profileImage==null?null:FileImage(profileImage!),child:profileImage==null?IconButton(onPressed:pickProfileImage,icon:const Icon(Icons.add_a_photo_rounded,size:26)):Align(alignment:Alignment.bottomRight,child:IconButton.filledTonal(onPressed:pickProfileImage,icon:const Icon(Icons.edit_rounded,size:16))))))),
      _Field(name,t('name'),Icons.badge_outlined),const SizedBox(height:10),
      TextField(controller:username,textDirection:TextDirection.ltr,onChanged:(_)=>setState(()=>usernameAvailable=null),decoration:InputDecoration(labelText:t('username'),hintText:'@username',prefixIcon:const Icon(Icons.alternate_email_rounded,size:20),suffixIcon:IconButton(onPressed:checkUsername,icon:Icon(usernameAvailable==true?Icons.check_circle:usernameAvailable==false?Icons.cancel:Icons.search,size:20,color:usernameAvailable==true?Colors.green:null)))),
      const SizedBox(height:12),
      Stack(alignment:rtl?Alignment.bottomLeft:Alignment.bottomRight,children:[_Field(bio,t('about'),Icons.auto_awesome_rounded,lines:4),Padding(padding:const EdgeInsets.all(6),child:IconButton.filledTonal(onPressed:(){},icon:const Icon(Icons.mic_rounded,size:18)))]),
      const SizedBox(height:12),
      _Tile(Icons.public_rounded,t('country'),country==null?t('chooseCountry'):'${_flagForCountry(country!)}  ${_countryText(code,country!)}',()async{final v=await choose(t('country'),countries,label:(v)=>_countryText(code,v),showFlags:true);if(v!=null)setState(()=>country=v);}),
      _Field(city,t('city'),Icons.location_city_outlined),const SizedBox(height:10),
      _BirthFields(value:birthDate,code:code,onChanged:(d)=>setState(()=>birthDate=d)),
      _GenderPicker(value:gender,code:code,onChanged:(v)=>setState(()=>gender=v)),
      _Tile(Icons.translate_rounded,t('native'),nativeLanguage==null?t('chooseLanguage'):ProfileLanguageCatalog.label(nativeLanguage),()async{final v=await chooseProfileLanguage(t('native'));if(v!=null)setState(()=>nativeLanguage=v);}),
      _Tile(Icons.language_rounded,t('learning'),learningLanguage==null?t('chooseLanguage'):ProfileLanguageCatalog.label(learningLanguage),()async{final v=await chooseProfileLanguage(t('learning'));if(v!=null)setState(()=>learningLanguage=v);}),
      _Tile(Icons.trending_up_rounded,t('level'),_profileText(code,languageLevel),()async{final v=await choose(t('level'),['beginner','intermediate','advanced'],label:(v)=>_profileText(code,v));if(v!=null)setState(()=>languageLevel=v);}),
      _Tile(Icons.favorite_outline_rounded,t('hobbies'),selectedHobbies.isEmpty?t('chooseHobbies'):selectedHobbies.map((e)=>'${_hobbyEmoji(e)} ${_profileText(code,e)}').join(' • '),()async{await _pickHobbies(context,code,selectedHobbies);if(mounted)setState(()=>interests.text=selectedHobbies.join(','));}),
      _Field(goals,t('goals'),Icons.track_changes_rounded,lines:2),const SizedBox(height:10),
      _Tile(Icons.work_outline_rounded,t('profession'),profession.text.trim().isEmpty?_extraText(code,'chooseProfession'):profession.text.trim(),()async{final v=await chooseProfession(code);if(v!=null){setState(()=>professionKey=v);if(v!='other')profession.text=ProfessionCatalog.byKey(v)?.label(code)??v;}}),
      if(professionKey=='other')...[_Field(profession,_extraText(code,'writeProfession'),Icons.edit_outlined),const SizedBox(height:10)],
      _Field(travel,t('travel'),Icons.flight_takeoff_rounded,lines:2),const SizedBox(height:22),
      SizedBox(height:58,child:FilledButton.icon(onPressed:saving?null:saveProfile,icon:saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.rocket_launch_rounded,size:20),label:Text(t('launch'),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17))))
    ]))));
  }
}


const _pt=<String,List<String>>{
'ar':['أنشئ هويتك في WorldVoice','الاسم','اسم المستخدم الفريد','ماذا عنك؟','الدولة','اختر دولتك','المدينة','اللغة الأم','اللغة التي تتعلمها','اختر اللغة','المستوى','الهوايات والاهتمامات','اختر هواياتك','أهداف التعلم','المهنة / الدراسة','السفر','إطلاق بروفايلي','مبتدئ','متوسط','متقدم','موسيقى','أفلام','رياضة','سفر','ألعاب','قراءة','تصوير','رسم','طبخ','تقنية'],
'en':['Create your WorldVoice identity','Name','Unique username','About you','Country','Choose country','City','Native language','Learning language','Choose language','Level','Interests & hobbies','Choose your hobbies','Learning goals','Profession / study','Travel','Launch my profile','Beginner','Intermediate','Advanced','Music','Movies','Sports','Travel','Gaming','Reading','Photography','Drawing','Cooking','Technology'],
'es':['Crea tu identidad en WorldVoice','Nombre','Nombre de usuario único','Sobre ti','País','Elige país','Ciudad','Idioma nativo','Idioma que aprendes','Elige idioma','Nivel','Intereses y aficiones','Elige tus aficiones','Objetivos de aprendizaje','Profesión / estudios','Viajes','Crear mi perfil','Principiante','Intermedio','Avanzado','Música','Películas','Deportes','Viajes','Videojuegos','Lectura','Fotografía','Dibujo','Cocina','Tecnología'],
'fr':['Créez votre identité WorldVoice','Nom','Nom d’utilisateur unique','À propos de vous','Pays','Choisir un pays','Ville','Langue maternelle','Langue apprise','Choisir une langue','Niveau','Centres d’intérêt et loisirs','Choisissez vos loisirs','Objectifs d’apprentissage','Profession / études','Voyages','Créer mon profil','Débutant','Intermédiaire','Avancé','Musique','Films','Sport','Voyages','Jeux vidéo','Lecture','Photographie','Dessin','Cuisine','Technologie'],
'de':['Erstelle deine WorldVoice-Identität','Name','Eindeutiger Benutzername','Über dich','Land','Land wählen','Stadt','Muttersprache','Lernsprache','Sprache wählen','Niveau','Interessen & Hobbys','Hobbys wählen','Lernziele','Beruf / Studium','Reisen','Profil erstellen','Anfänger','Mittelstufe','Fortgeschritten','Musik','Filme','Sport','Reisen','Gaming','Lesen','Fotografie','Zeichnen','Kochen','Technologie'],
'it':['Crea la tua identità WorldVoice','Nome','Nome utente univoco','Su di te','Paese','Scegli paese','Città','Lingua madre','Lingua studiata','Scegli lingua','Livello','Interessi e hobby','Scegli i tuoi hobby','Obiettivi di apprendimento','Professione / studi','Viaggi','Crea il mio profilo','Principiante','Intermedio','Avanzato','Musica','Film','Sport','Viaggi','Videogiochi','Lettura','Fotografia','Disegno','Cucina','Tecnologia'],
'pt':['Crie sua identidade WorldVoice','Nome','Nome de usuário exclusivo','Sobre você','País','Escolha o país','Cidade','Idioma nativo','Idioma que aprende','Escolha o idioma','Nível','Interesses e hobbies','Escolha seus hobbies','Objetivos de aprendizagem','Profissão / estudos','Viagens','Criar meu perfil','Iniciante','Intermediário','Avançado','Música','Filmes','Esportes','Viagens','Jogos','Leitura','Fotografia','Desenho','Culinária','Tecnologia'],
'tr':['WorldVoice kimliğini oluştur','Ad','Benzersiz kullanıcı adı','Hakkında','Ülke','Ülke seç','Şehir','Ana dil','Öğrenilen dil','Dil seç','Seviye','İlgi alanları ve hobiler','Hobilerini seç','Öğrenme hedefleri','Meslek / eğitim','Seyahat','Profilimi oluştur','Başlangıç','Orta','İleri','Müzik','Filmler','Spor','Seyahat','Oyun','Okuma','Fotoğrafçılık','Çizim','Yemek','Teknoloji'],
'ru':['Создайте профиль WorldVoice','Имя','Уникальное имя пользователя','О себе','Страна','Выберите страну','Город','Родной язык','Изучаемый язык','Выберите язык','Уровень','Интересы и хобби','Выберите хобби','Цели обучения','Работа / учёба','Путешествия','Создать профиль','Начальный','Средний','Продвинутый','Музыка','Фильмы','Спорт','Путешествия','Игры','Чтение','Фотография','Рисование','Кулинария','Технологии'],
'zh':['创建你的 WorldVoice 身份','姓名','唯一用户名','关于你','国家','选择国家','城市','母语','学习语言','选择语言','水平','兴趣爱好','选择爱好','学习目标','职业 / 学业','旅行','创建我的个人资料','初级','中级','高级','音乐','电影','运动','旅行','游戏','阅读','摄影','绘画','烹饪','科技'],
'ja':['WorldVoiceプロフィールを作成','名前','固有のユーザー名','自己紹介','国','国を選択','都市','母語','学習言語','言語を選択','レベル','興味・趣味','趣味を選択','学習目標','職業 / 学業','旅行','プロフィールを作成','初級','中級','上級','音楽','映画','スポーツ','旅行','ゲーム','読書','写真','絵','料理','テクノロジー'],
'ko':['WorldVoice 프로필 만들기','이름','고유 사용자 이름','자기소개','국가','국가 선택','도시','모국어','학습 언어','언어 선택','레벨','관심사 및 취미','취미 선택','학습 목표','직업 / 학업','여행','프로필 만들기','초급','중급','고급','음악','영화','스포츠','여행','게임','독서','사진','그림','요리','기술'],
'ur':['اپنی WorldVoice شناخت بنائیں','نام','منفرد صارف نام','اپنے بارے میں','ملک','ملک منتخب کریں','شہر','مادری زبان','سیکھنے کی زبان','زبان منتخب کریں','سطح','دلچسپیاں اور مشاغل','اپنے مشاغل منتخب کریں','سیکھنے کے اہداف','پیشہ / تعلیم','سفر','میرا پروفائل بنائیں','ابتدائی','درمیانی','اعلیٰ','موسیقی','فلمیں','کھیل','سفر','گیمنگ','مطالعہ','فوٹوگرافی','ڈرائنگ','کھانا پکانا','ٹیکنالوجی'],
'fa':['هویت WorldVoice خود را بسازید','نام','نام کاربری منحصربه‌فرد','درباره شما','کشور','کشور را انتخاب کنید','شهر','زبان مادری','زبان در حال یادگیری','زبان را انتخاب کنید','سطح','علایق و سرگرمی‌ها','سرگرمی‌ها را انتخاب کنید','اهداف یادگیری','شغل / تحصیل','سفر','ساخت پروفایل','مبتدی','متوسط','پیشرفته','موسیقی','فیلم','ورزش','سفر','بازی','مطالعه','عکاسی','نقاشی','آشپزی','فناوری'],
'id':['Buat identitas WorldVoice Anda','Nama','Nama pengguna unik','Tentang Anda','Negara','Pilih negara','Kota','Bahasa ibu','Bahasa yang dipelajari','Pilih bahasa','Tingkat','Minat & hobi','Pilih hobi Anda','Tujuan belajar','Profesi / studi','Perjalanan','Buat profil saya','Pemula','Menengah','Mahir','Musik','Film','Olahraga','Perjalanan','Game','Membaca','Fotografi','Menggambar','Memasak','Teknologi'],
'th':['สร้างโปรไฟล์ WorldVoice','ชื่อ','ชื่อผู้ใช้ไม่ซ้ำ','เกี่ยวกับคุณ','ประเทศ','เลือกประเทศ','เมือง','ภาษาแม่','ภาษาที่เรียน','เลือกภาษา','ระดับ','ความสนใจและงานอดิเรก','เลือกงานอดิเรก','เป้าหมายการเรียน','อาชีพ / การศึกษา','การเดินทาง','สร้างโปรไฟล์','เริ่มต้น','ปานกลาง','ขั้นสูง','ดนตรี','ภาพยนตร์','กีฬา','ท่องเที่ยว','เกม','อ่านหนังสือ','ถ่ายภาพ','วาดภาพ','ทำอาหาร','เทคโนโลยี'],
'hi':['अपनी WorldVoice पहचान बनाएँ','नाम','विशिष्ट यूज़रनेम','अपने बारे में','देश','देश चुनें','शहर','मातृभाषा','सीखी जा रही भाषा','भाषा चुनें','स्तर','रुचियाँ और शौक','अपने शौक चुनें','सीखने के लक्ष्य','पेशा / पढ़ाई','यात्रा','मेरा प्रोफ़ाइल बनाएँ','शुरुआती','मध्यम','उन्नत','संगीत','फ़िल्में','खेल','यात्रा','गेमिंग','पढ़ना','फ़ोटोग्राफ़ी','चित्रकारी','खाना बनाना','तकनीक']
};
const _pk=['title','name','username','about','country','chooseCountry','city','native','learning','chooseLanguage','level','hobbies','chooseHobbies','goals','profession','travel','launch','beginner','intermediate','advanced','music','movies','sports','travel_hobby','gaming','reading','photography','drawing','cooking','technology'];

const _hobbyLabels=<String,Map<String,String>>{
'ar':{
'football':'كرة القدم','basketball':'كرة السلة','volleyball':'الكرة الطائرة','tennis':'التنس','swimming':'السباحة','running':'الجري','gym':'اللياقة والجيم','martialArts':'الفنون القتالية','cycling':'ركوب الدراجات','padel':'البادل','boxing':'الملاكمة','yoga':'اليوغا','hiking':'المشي الجبلي','dancing':'الرقص','singing':'الغناء','writing':'الكتابة','fashion':'الموضة','gardening':'البستنة','cars':'السيارات','nature':'الطبيعة','chess':'الشطرنج','pets':'الحيوانات الأليفة'},
'en':{
'football':'Football','basketball':'Basketball','volleyball':'Volleyball','tennis':'Tennis','swimming':'Swimming','running':'Running','gym':'Fitness & gym','martialArts':'Martial arts','cycling':'Cycling','padel':'Padel','boxing':'Boxing','yoga':'Yoga','hiking':'Hiking','dancing':'Dancing','singing':'Singing','writing':'Writing','fashion':'Fashion','gardening':'Gardening','cars':'Cars','nature':'Nature','chess':'Chess','pets':'Pets'},
'es':{
'football':'Fútbol','basketball':'Baloncesto','volleyball':'Voleibol','tennis':'Tenis','swimming':'Natación','running':'Correr','gym':'Fitness y gimnasio','martialArts':'Artes marciales','cycling':'Ciclismo','padel':'Pádel','boxing':'Boxeo','yoga':'Yoga','hiking':'Senderismo','dancing':'Baile','singing':'Canto','writing':'Escritura','fashion':'Moda','gardening':'Jardinería','cars':'Autos','nature':'Naturaleza','chess':'Ajedrez','pets':'Mascotas'},
'fr':{
'football':'Football','basketball':'Basket-ball','volleyball':'Volley-ball','tennis':'Tennis','swimming':'Natation','running':'Course à pied','gym':'Fitness et salle de sport','martialArts':'Arts martiaux','cycling':'Cyclisme','padel':'Padel','boxing':'Boxe','yoga':'Yoga','hiking':'Randonnée','dancing':'Danse','singing':'Chant','writing':'Écriture','fashion':'Mode','gardening':'Jardinage','cars':'Voitures','nature':'Nature','chess':'Échecs','pets':'Animaux'},
'de':{
'football':'Fußball','basketball':'Basketball','volleyball':'Volleyball','tennis':'Tennis','swimming':'Schwimmen','running':'Laufen','gym':'Fitness & Gym','martialArts':'Kampfsport','cycling':'Radfahren','padel':'Padel','boxing':'Boxen','yoga':'Yoga','hiking':'Wandern','dancing':'Tanzen','singing':'Singen','writing':'Schreiben','fashion':'Mode','gardening':'Gärtnern','cars':'Autos','nature':'Natur','chess':'Schach','pets':'Haustiere'},
'it':{
'football':'Calcio','basketball':'Pallacanestro','volleyball':'Pallavolo','tennis':'Tennis','swimming':'Nuoto','running':'Corsa','gym':'Fitness e palestra','martialArts':'Arti marziali','cycling':'Ciclismo','padel':'Padel','boxing':'Boxe','yoga':'Yoga','hiking':'Escursionismo','dancing':'Danza','singing':'Canto','writing':'Scrittura','fashion':'Moda','gardening':'Giardinaggio','cars':'Auto','nature':'Natura','chess':'Scacchi','pets':'Animali domestici'},
'pt':{
'football':'Futebol','basketball':'Basquete','volleyball':'Vôlei','tennis':'Tênis','swimming':'Natação','running':'Corrida','gym':'Fitness e academia','martialArts':'Artes marciais','cycling':'Ciclismo','padel':'Padel','boxing':'Boxe','yoga':'Yoga','hiking':'Caminhada','dancing':'Dança','singing':'Canto','writing':'Escrita','fashion':'Moda','gardening':'Jardinagem','cars':'Carros','nature':'Natureza','chess':'Xadrez','pets':'Animais de estimação'},
'tr':{
'football':'Futbol','basketball':'Basketbol','volleyball':'Voleybol','tennis':'Tenis','swimming':'Yüzme','running':'Koşu','gym':'Fitness ve spor salonu','martialArts':'Dövüş sanatları','cycling':'Bisiklet','padel':'Padel','boxing':'Boks','yoga':'Yoga','hiking':'Doğa yürüyüşü','dancing':'Dans','singing':'Şarkı söyleme','writing':'Yazma','fashion':'Moda','gardening':'Bahçecilik','cars':'Arabalar','nature':'Doğa','chess':'Satranç','pets':'Evcil hayvanlar'},
'ru':{
'football':'Футбол','basketball':'Баскетбол','volleyball':'Волейбол','tennis':'Теннис','swimming':'Плавание','running':'Бег','gym':'Фитнес и тренажёрный зал','martialArts':'Боевые искусства','cycling':'Велоспорт','padel':'Падел','boxing':'Бокс','yoga':'Йога','hiking':'Пешие походы','dancing':'Танцы','singing':'Пение','writing':'Письмо','fashion':'Мода','gardening':'Садоводство','cars':'Автомобили','nature':'Природа','chess':'Шахматы','pets':'Домашние животные'},
'zh':{
'football':'足球','basketball':'篮球','volleyball':'排球','tennis':'网球','swimming':'游泳','running':'跑步','gym':'健身房','martialArts':'武术','cycling':'骑行','padel':'板式网球','boxing':'拳击','yoga':'瑜伽','hiking':'徒步','dancing':'舞蹈','singing':'唱歌','writing':'写作','fashion':'时尚','gardening':'园艺','cars':'汽车','nature':'自然','chess':'国际象棋','pets':'宠物'},
'ja':{
'football':'サッカー','basketball':'バスケットボール','volleyball':'バレーボール','tennis':'テニス','swimming':'水泳','running':'ランニング','gym':'フィットネス・ジム','martialArts':'武道','cycling':'サイクリング','padel':'パデル','boxing':'ボクシング','yoga':'ヨガ','hiking':'ハイキング','dancing':'ダンス','singing':'歌','writing':'執筆','fashion':'ファッション','gardening':'ガーデニング','cars':'車','nature':'自然','chess':'チェス','pets':'ペット'},
'ko':{
'football':'축구','basketball':'농구','volleyball':'배구','tennis':'테니스','swimming':'수영','running':'달리기','gym':'피트니스·헬스장','martialArts':'무술','cycling':'사이클링','padel':'파델','boxing':'복싱','yoga':'요가','hiking':'하이킹','dancing':'춤','singing':'노래','writing':'글쓰기','fashion':'패션','gardening':'정원 가꾸기','cars':'자동차','nature':'자연','chess':'체스','pets':'반려동물'},
'ur':{
'football':'فٹ بال','basketball':'باسکٹ بال','volleyball':'والی بال','tennis':'ٹینس','swimming':'تیراکی','running':'دوڑ','gym':'فٹنس اور جم','martialArts':'مارشل آرٹس','cycling':'سائیکلنگ','padel':'پیڈل','boxing':'باکسنگ','yoga':'یوگا','hiking':'ہائیکنگ','dancing':'رقص','singing':'گانا','writing':'لکھائی','fashion':'فیشن','gardening':'باغبانی','cars':'گاڑیاں','nature':'فطرت','chess':'شطرنج','pets':'پالتو جانور'},
'fa':{
'football':'فوتبال','basketball':'بسکتبال','volleyball':'والیبال','tennis':'تنیس','swimming':'شنا','running':'دویدن','gym':'تناسب اندام و باشگاه','martialArts':'هنرهای رزمی','cycling':'دوچرخه‌سواری','padel':'پدل','boxing':'بوکس','yoga':'یوگا','hiking':'پیاده‌روی','dancing':'رقص','singing':'آوازخوانی','writing':'نویسندگی','fashion':'مد','gardening':'باغبانی','cars':'خودرو','nature':'طبیعت','chess':'شطرنج','pets':'حیوانات خانگی'},
'id':{
'football':'Sepak bola','basketball':'Bola basket','volleyball':'Bola voli','tennis':'Tenis','swimming':'Renang','running':'Lari','gym':'Kebugaran & gym','martialArts':'Seni bela diri','cycling':'Bersepeda','padel':'Padel','boxing':'Tinju','yoga':'Yoga','hiking':'Mendaki','dancing':'Menari','singing':'Bernyanyi','writing':'Menulis','fashion':'Mode','gardening':'Berkebun','cars':'Mobil','nature':'Alam','chess':'Catur','pets':'Hewan peliharaan'},
'th':{
'football':'ฟุตบอล','basketball':'บาสเกตบอล','volleyball':'วอลเลย์บอล','tennis':'เทนนิส','swimming':'ว่ายน้ำ','running':'วิ่ง','gym':'ฟิตเนสและยิม','martialArts':'ศิลปะการต่อสู้','cycling':'ปั่นจักรยาน','padel':'พาเดล','boxing':'มวย','yoga':'โยคะ','hiking':'เดินป่า','dancing':'เต้นรำ','singing':'ร้องเพลง','writing':'เขียน','fashion':'แฟชั่น','gardening':'ทำสวน','cars':'รถยนต์','nature':'ธรรมชาติ','chess':'หมากรุก','pets':'สัตว์เลี้ยง'},
'hi':{
'football':'फ़ुटबॉल','basketball':'बास्केटबॉल','volleyball':'वॉलीबॉल','tennis':'टेनिस','swimming':'तैराकी','running':'दौड़ना','gym':'फिटनेस और जिम','martialArts':'मार्शल आर्ट्स','cycling':'साइकिलिंग','padel':'पैडल','boxing':'बॉक्सिंग','yoga':'योग','hiking':'हाइकिंग','dancing':'नृत्य','singing':'गायन','writing':'लेखन','fashion':'फैशन','gardening':'बागवानी','cars':'कारें','nature':'प्रकृति','chess':'शतरंज','pets':'पालतू जानवर'},
};

String _profileText(String code,String key){
  final hobby=_hobbyLabels[code]?[key]??_hobbyLabels['en']?[key];
  if(hobby!=null)return hobby;
  final i=_pk.indexOf(key);
  final a=_pt[code]??_pt['en']!;
  return i<0?key:a[i];
}

String _hobbyEmoji(String key){
  const icons=<String,String>{
    'music':'🎵','movies':'🎬','football':'⚽','basketball':'🏀','volleyball':'🏐','tennis':'🎾',
    'swimming':'🏊','running':'🏃','gym':'🏋️','martialArts':'🥋','cycling':'🚴','padel':'🏓',
    'boxing':'🥊','yoga':'🧘','hiking':'🥾','travel_hobby':'✈️','gaming':'🎮','reading':'📚',
    'photography':'📷','drawing':'🎨','cooking':'🍳','technology':'💻','dancing':'💃',
    'singing':'🎤','writing':'✍️','fashion':'👗','gardening':'🌱','cars':'🏎️','nature':'🌿',
    'chess':'♟️','pets':'🐾',
  };
  return icons[key]??'✨';
}

Future<void> _pickHobbies(BuildContext context,String code,Set<String> selected) async{
  const keys=[
    'music','movies','football','basketball','volleyball','tennis','swimming','running','gym',
    'martialArts','cycling','padel','boxing','yoga','hiking','travel_hobby','gaming','reading',
    'photography','drawing','cooking','technology','dancing','singing','writing','fashion',
    'gardening','cars','nature','chess','pets'
  ];
  await showModalBottomSheet(
    context:context,
    isScrollControlled:true,
    useSafeArea:true,
    showDragHandle:true,
    builder:(ctx)=>StatefulBuilder(builder:(ctx,setSheet){
      final cs=Theme.of(ctx).colorScheme;
      return FractionallySizedBox(
        heightFactor:.90,
        child:Column(children:[
          Padding(
            padding:const EdgeInsets.fromLTRB(18,2,18,12),
            child:Row(children:[
              Expanded(child:Text(_profileText(code,'hobbies'),style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900))),
              FilledButton.tonalIcon(
                onPressed:()=>Navigator.pop(ctx),
                icon:const Icon(Icons.check_rounded,size:20),
                label:Text('${selected.length}'),
              ),
            ]),
          ),
          Expanded(
            child:ListView.separated(
              padding:const EdgeInsets.fromLTRB(12,0,12,24),
              itemCount:keys.length,
              separatorBuilder:(_,__)=>const SizedBox(height:4),
              itemBuilder:(_,i){
                final k=keys[i];
                final checked=selected.contains(k);
                return Material(
                  color:checked?cs.primaryContainer.withValues(alpha:.35):Colors.transparent,
                  borderRadius:BorderRadius.circular(16),
                  child:ListTile(
                    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
                    leading:CircleAvatar(
                      backgroundColor:checked?cs.primaryContainer:cs.surfaceContainerHighest,
                      child:Text(_hobbyEmoji(k),style:const TextStyle(fontSize:21)),
                    ),
                    title:Text(_profileText(code,k),style:TextStyle(fontWeight:checked?FontWeight.w800:FontWeight.w600)),
                    trailing:Icon(
                      checked?Icons.check_circle_rounded:Icons.circle_outlined,
                      color:checked?cs.primary:cs.outline,
                    ),
                    onTap:()=>setSheet((){
                      checked?selected.remove(k):selected.add(k);
                    }),
                  ),
                );
              },
            ),
          ),
        ]),
      );
    }),
  );
}

class _Field extends StatelessWidget{
  const _Field(this.controller,this.label,this.icon,{this.lines=1}); final TextEditingController controller;final String label;final IconData icon;final int lines;
  @override Widget build(BuildContext context)=>TextField(controller:controller,maxLines:lines,decoration:InputDecoration(labelText:label,prefixIcon:Icon(icon,size:19)));
}
class _Tile extends StatelessWidget{
  const _Tile(this.icon,this.title,this.subtitle,this.tap);final IconData icon;final String title,subtitle;final VoidCallback tap;
  @override Widget build(BuildContext context)=>Card(margin:const EdgeInsets.only(bottom:10),child:ListTile(dense:true,contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:5),leading:CircleAvatar(radius:17,child:Icon(icon,size:18)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right_rounded,size:20),onTap:tap));
}

String _flagForCountry(String country) {
  const codes=<String,String>{
'Afghanistan':'AF','Albania':'AL','Algeria':'DZ','Andorra':'AD','Angola':'AO','Antigua and Barbuda':'AG','Argentina':'AR','Armenia':'AM','Australia':'AU','Austria':'AT','Azerbaijan':'AZ','Bahamas':'BS','Bahrain':'BH','Bangladesh':'BD','Barbados':'BB','Belarus':'BY','Belgium':'BE','Belize':'BZ','Benin':'BJ','Bhutan':'BT','Bolivia':'BO','Bosnia and Herzegovina':'BA','Botswana':'BW','Brazil':'BR','Brunei':'BN','Bulgaria':'BG','Burkina Faso':'BF','Burundi':'BI','Cabo Verde':'CV','Cambodia':'KH','Cameroon':'CM','Canada':'CA','Central African Republic':'CF','Chad':'TD','Chile':'CL','China':'CN','Colombia':'CO','Comoros':'KM','Congo':'CG','Costa Rica':'CR','Croatia':'HR','Cuba':'CU','Cyprus':'CY','Czechia':'CZ','Denmark':'DK','Djibouti':'DJ','Dominica':'DM','Dominican Republic':'DO','Ecuador':'EC','Egypt':'EG','El Salvador':'SV','Equatorial Guinea':'GQ','Eritrea':'ER','Estonia':'EE','Eswatini':'SZ','Ethiopia':'ET','Fiji':'FJ','Finland':'FI','France':'FR','Gabon':'GA','Gambia':'GM','Georgia':'GE','Germany':'DE','Ghana':'GH','Greece':'GR','Grenada':'GD','Guatemala':'GT','Guinea':'GN','Guinea-Bissau':'GW','Guyana':'GY','Haiti':'HT','Honduras':'HN','Hungary':'HU','Iceland':'IS','India':'IN','Indonesia':'ID','Iran':'IR','Iraq':'IQ','Ireland':'IE','Italy':'IT','Ivory Coast':'CI','Jamaica':'JM','Japan':'JP','Jordan':'JO','Kazakhstan':'KZ','Kenya':'KE','Kiribati':'KI','Kuwait':'KW','Kyrgyzstan':'KG','Laos':'LA','Latvia':'LV','Lebanon':'LB','Lesotho':'LS','Liberia':'LR','Libya':'LY','Liechtenstein':'LI','Lithuania':'LT','Luxembourg':'LU','Madagascar':'MG','Malawi':'MW','Malaysia':'MY','Maldives':'MV','Mali':'ML','Malta':'MT','Marshall Islands':'MH','Mauritania':'MR','Mauritius':'MU','Mexico':'MX','Micronesia':'FM','Moldova':'MD','Monaco':'MC','Mongolia':'MN','Montenegro':'ME','Morocco':'MA','Mozambique':'MZ','Myanmar':'MM','Namibia':'NA','Nauru':'NR','Nepal':'NP','Netherlands':'NL','New Zealand':'NZ','Nicaragua':'NI','Niger':'NE','Nigeria':'NG','North Korea':'KP','North Macedonia':'MK','Norway':'NO','Oman':'OM','Pakistan':'PK','Palau':'PW','Palestine':'PS','Panama':'PA','Papua New Guinea':'PG','Paraguay':'PY','Peru':'PE','Philippines':'PH','Poland':'PL','Portugal':'PT','Qatar':'QA','Romania':'RO','Russia':'RU','Rwanda':'RW','Saint Kitts and Nevis':'KN','Saint Lucia':'LC','Saint Vincent and the Grenadines':'VC','Samoa':'WS','San Marino':'SM','Sao Tome and Principe':'ST','Saudi Arabia':'SA','Senegal':'SN','Serbia':'RS','Seychelles':'SC','Sierra Leone':'SL','Singapore':'SG','Slovakia':'SK','Slovenia':'SI','Solomon Islands':'SB','Somalia':'SO','South Africa':'ZA','South Korea':'KR','South Sudan':'SS','Spain':'ES','Sri Lanka':'LK','Sudan':'SD','Suriname':'SR','Sweden':'SE','Switzerland':'CH','Syria':'SY','Tajikistan':'TJ','Tanzania':'TZ','Thailand':'TH','Timor-Leste':'TL','Togo':'TG','Tonga':'TO','Trinidad and Tobago':'TT','Tunisia':'TN','Turkey':'TR','Turkmenistan':'TM','Tuvalu':'TV','Uganda':'UG','Ukraine':'UA','United Arab Emirates':'AE','United Kingdom':'GB','United States':'US','Uruguay':'UY','Uzbekistan':'UZ','Vanuatu':'VU','Vatican City':'VA','Venezuela':'VE','Vietnam':'VN','Yemen':'YE','Zambia':'ZM','Zimbabwe':'ZW'};
  final code=codes[country]; if(code==null)return '🌐';
  return String.fromCharCodes(code.codeUnits.map((c)=>0x1F1E6+c-65));
}

class _BirthFields extends StatefulWidget {
  const _BirthFields({required this.value,required this.code,required this.onChanged});
  final DateTime? value; final String code; final ValueChanged<DateTime?> onChanged;
  @override State<_BirthFields> createState()=>_BirthFieldsState();
}
class _BirthFieldsState extends State<_BirthFields>{
  late final day=TextEditingController(text:widget.value?.day.toString()??'');
  late final month=TextEditingController(text:widget.value?.month.toString()??'');
  late final year=TextEditingController(text:widget.value?.year.toString()??'');
  void update(){final d=int.tryParse(day.text),m=int.tryParse(month.text),y=int.tryParse(year.text);if(d!=null&&m!=null&&y!=null){try{final v=DateTime(y,m,d);if(v.year==y&&v.month==m&&v.day==d&&v.isBefore(DateTime.now()))widget.onChanged(v);else widget.onChanged(null);}catch(_){widget.onChanged(null);}}}
  @override void dispose(){day.dispose();month.dispose();year.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(_extraText(widget.code,'birthDate'),style:const TextStyle(fontWeight:FontWeight.w800)),
    const SizedBox(height:8),
    Row(children:[
      Expanded(child:DropdownButtonFormField<int>(initialValue:int.tryParse(day.text),decoration:InputDecoration(labelText:_extraText(widget.code,'day')),items:List.generate(31,(i)=>DropdownMenuItem(value:i+1,child:Text('${i+1}'))),onChanged:(v){day.text=v?.toString()??'';update();})),
      const SizedBox(width:8),
      Expanded(child:DropdownButtonFormField<int>(initialValue:int.tryParse(month.text),decoration:InputDecoration(labelText:_extraText(widget.code,'month')),items:List.generate(12,(i)=>DropdownMenuItem(value:i+1,child:Text('${i+1}'))),onChanged:(v){month.text=v?.toString()??'';update();})),
      const SizedBox(width:8),
      Expanded(child:DropdownButtonFormField<int>(initialValue:int.tryParse(year.text),decoration:InputDecoration(labelText:_extraText(widget.code,'year')),items:List.generate(DateTime.now().year-1900,(i){final y=DateTime.now().year-i;return DropdownMenuItem(value:y,child:Text('$y'));}),onChanged:(v){year.text=v?.toString()??'';update();})),
    ]),const SizedBox(height:10)]);
}
class _GenderPicker extends StatelessWidget{
  const _GenderPicker({required this.value,required this.code,required this.onChanged});
  final String? value;final String code;final ValueChanged<String> onChanged;
  @override Widget build(BuildContext context)=>Card(margin:const EdgeInsets.only(bottom:10),child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[
    Text(_extraText(code,'gender'),style:const TextStyle(fontWeight:FontWeight.w800)),const Spacer(),
    IconButton.filledTonal(onPressed:()=>onChanged('male'),tooltip:_extraText(code,'male'),icon:Icon(Icons.male_rounded,color:Colors.blue,size:25),style:IconButton.styleFrom(side:value=='male'?const BorderSide(width:2):null)),
    const SizedBox(width:8),
    IconButton.filledTonal(onPressed:()=>onChanged('female'),tooltip:_extraText(code,'female'),icon:Icon(Icons.female_rounded,color:Colors.pink,size:25),style:IconButton.styleFrom(side:value=='female'?const BorderSide(width:2):null)),
    const SizedBox(width:8),
    IconButton.outlined(onPressed:()=>onChanged('prefer_not_to_say'),tooltip:_extraText(code,'prefer'),icon:const Icon(Icons.remove_rounded,size:22)),
  ])));
}

const _extra=<String,List<String>>{
'ar':['تاريخ الميلاد','اليوم','الشهر','السنة','الجنس','ذكر','أنثى','أفضل عدم الإجابة','تم حفظ البروفايل بنجاح ✓','ابحث عن لغة...','اختر المهنة / الدراسة','اكتب مهنتك','اكتب الاسم أولًا','اسم المستخدم يجب أن يكون 3-20 أحرف إنجليزية أو أرقام أو _','اسم المستخدم مستخدم بالفعل'],
'en':['Date of birth','Day','Month','Year','Gender','Male','Female','Prefer not to say','Profile saved successfully ✓','Search languages...','Choose profession / study','Write your profession','Enter your name first','Username must be 3-20 letters, numbers, or _','Username is already taken'],
'es':['Fecha de nacimiento','Día','Mes','Año','Género','Hombre','Mujer','Prefiero no responder','Perfil guardado correctamente ✓','Buscar idiomas...','Elegir profesión / estudios','Escribe tu profesión','Escribe tu nombre primero','El usuario debe tener 3-20 letras, números o _','El nombre de usuario ya está en uso'],
'fr':['Date de naissance','Jour','Mois','Année','Genre','Homme','Femme','Je préfère ne pas répondre','Profil enregistré ✓','Rechercher une langue...','Choisir profession / études','Écrivez votre profession','Entrez d’abord votre nom','Le nom d’utilisateur doit contenir 3 à 20 lettres, chiffres ou _','Ce nom d’utilisateur est déjà pris'],
'de':['Geburtsdatum','Tag','Monat','Jahr','Geschlecht','Männlich','Weiblich','Keine Angabe','Profil erfolgreich gespeichert ✓','Sprachen suchen...','Beruf / Studium wählen','Beruf eingeben','Bitte zuerst den Namen eingeben','Benutzername: 3–20 Buchstaben, Zahlen oder _','Benutzername ist bereits vergeben'],
'it':['Data di nascita','Giorno','Mese','Anno','Genere','Maschio','Femmina','Preferisco non rispondere','Profilo salvato ✓','Cerca lingue...','Scegli professione / studi','Scrivi la tua professione','Inserisci prima il nome','Il nome utente deve avere 3-20 lettere, numeri o _','Nome utente già utilizzato'],
'pt':['Data de nascimento','Dia','Mês','Ano','Gênero','Masculino','Feminino','Prefiro não responder','Perfil salvo ✓','Pesquisar idiomas...','Escolher profissão / estudos','Escreva sua profissão','Digite seu nome primeiro','O usuário deve ter 3-20 letras, números ou _','Nome de usuário já está em uso'],
'tr':['Doğum tarihi','Gün','Ay','Yıl','Cinsiyet','Erkek','Kadın','Yanıtlamak istemiyorum','Profil kaydedildi ✓','Dil ara...','Meslek / eğitim seç','Mesleğini yaz','Önce adını gir','Kullanıcı adı 3-20 harf, rakam veya _ olmalı','Kullanıcı adı zaten alınmış'],
'ru':['Дата рождения','День','Месяц','Год','Пол','Мужской','Женский','Предпочитаю не отвечать','Профиль сохранён ✓','Поиск языков...','Выбрать профессию / учёбу','Укажите профессию','Сначала введите имя','Имя пользователя: 3–20 букв, цифр или _','Имя пользователя уже занято'],
'zh':['出生日期','日','月','年','性别','男','女','不愿回答','个人资料已保存 ✓','搜索语言...','选择职业 / 学业','填写职业','请先输入姓名','用户名必须为3-20个字母、数字或_','用户名已被使用'],
'ja':['生年月日','日','月','年','性別','男性','女性','回答しない','プロフィールを保存しました ✓','言語を検索...','職業 / 学業を選択','職業を入力','先に名前を入力してください','ユーザー名は3〜20文字の英数字または_','そのユーザー名は使用されています'],
'ko':['생년월일','일','월','년','성별','남성','여성','응답하지 않음','프로필이 저장되었습니다 ✓','언어 검색...','직업 / 학업 선택','직업 입력','먼저 이름을 입력하세요','사용자 이름은 3-20자의 영문, 숫자 또는 _','이미 사용 중인 사용자 이름입니다'],
'ur':['تاریخ پیدائش','دن','مہینہ','سال','جنس','مرد','عورت','جواب نہیں دینا چاہتا','پروفائل محفوظ ہوگیا ✓','زبان تلاش کریں...','پیشہ / تعلیم منتخب کریں','اپنا پیشہ لکھیں','پہلے نام درج کریں','صارف نام 3-20 حروف، اعداد یا _ ہونا چاہیے','یہ صارف نام پہلے سے استعمال میں ہے'],
'fa':['تاریخ تولد','روز','ماه','سال','جنسیت','مرد','زن','ترجیح می‌دهم پاسخ ندهم','پروفایل ذخیره شد ✓','جستجوی زبان...','انتخاب شغل / تحصیل','شغل خود را بنویسید','ابتدا نام را وارد کنید','نام کاربری باید ۳ تا ۲۰ حرف، عدد یا _ باشد','این نام کاربری قبلاً استفاده شده است'],
'id':['Tanggal lahir','Hari','Bulan','Tahun','Jenis kelamin','Pria','Wanita','Memilih tidak menjawab','Profil berhasil disimpan ✓','Cari bahasa...','Pilih profesi / studi','Tulis profesi Anda','Masukkan nama terlebih dahulu','Nama pengguna harus 3-20 huruf, angka, atau _','Nama pengguna sudah digunakan'],
'th':['วันเกิด','วัน','เดือน','ปี','เพศ','ชาย','หญิง','ไม่ประสงค์ตอบ','บันทึกโปรไฟล์แล้ว ✓','ค้นหาภาษา...','เลือกอาชีพ / การศึกษา','เขียนอาชีพของคุณ','กรอกชื่อก่อน','ชื่อผู้ใช้ต้องมี 3-20 ตัวอักษร ตัวเลข หรือ _','ชื่อผู้ใช้นี้ถูกใช้แล้ว'],
'hi':['जन्म तिथि','दिन','महीना','वर्ष','लिंग','पुरुष','महिला','उत्तर नहीं देना चाहता','प्रोफ़ाइल सहेजी गई ✓','भाषा खोजें...','पेशा / पढ़ाई चुनें','अपना पेशा लिखें','पहले नाम दर्ज करें','यूज़रनेम 3-20 अक्षर, अंक या _ होना चाहिए','यह यूज़रनेम पहले से उपयोग में है']
};
const _extraKeys=['birthDate','day','month','year','gender','male','female','prefer','saved','searchLanguage','chooseProfession','writeProfession','nameRequired','usernameRequired','usernameTaken'];
String _extraText(String code,String key){final i=_extraKeys.indexOf(key);final a=_extra[code]??_extra['en']!;return i<0?key:a[i];}

String _countryText(String code,String country){if(code=='en')return country;return _countryNames[code]?[country]??country;}
const Map<String,Map<String,String>> _countryNames={
'ar':{"Afghanistan":"أفغانستان","Albania":"ألبانيا","Algeria":"الجزائر","Andorra":"أندورا","Angola":"أنغولا","Antigua and Barbuda":"أنتيغوا وباربودا","Argentina":"الأرجنتين","Armenia":"أرمينيا","Australia":"أستراليا","Austria":"النمسا","Azerbaijan":"أذربيجان","Bahamas":"جزر البهاما","Bahrain":"البحرين","Bangladesh":"بنغلاديش","Barbados":"بربادوس","Belarus":"بيلاروس","Belgium":"بلجيكا","Belize":"بليز","Benin":"بنين","Bhutan":"بوتان","Bolivia":"بوليفيا","Bosnia and Herzegovina":"البوسنة والهرسك","Botswana":"بوتسوانا","Brazil":"البرازيل","Brunei":"بروناي","Bulgaria":"بلغاريا","Burkina Faso":"بوركينا فاسو","Burundi":"بوروندي","Cabo Verde":"الرأس الأخضر","Cambodia":"كمبوديا","Cameroon":"الكاميرون","Canada":"كندا","Central African Republic":"جمهورية أفريقيا الوسطى","Chad":"تشاد","Chile":"تشيلي","China":"الصين","Colombia":"كولومبيا","Comoros":"جزر القمر","Congo":"الكونغو","Costa Rica":"كوستاريكا","Croatia":"كرواتيا","Cuba":"كوبا","Cyprus":"قبرص","Czechia":"التشيك","Denmark":"الدنمارك","Djibouti":"جيبوتي","Dominica":"دومينيكا","Dominican Republic":"جمهورية الدومينيكان","Ecuador":"الإكوادور","Egypt":"مصر","El Salvador":"السلفادور","Equatorial Guinea":"غينيا الاستوائية","Eritrea":"إريتريا","Estonia":"إستونيا","Eswatini":"إسواتيني","Ethiopia":"إثيوبيا","Fiji":"فيجي","Finland":"فنلندا","France":"فرنسا","Gabon":"الغابون","Gambia":"غامبيا","Georgia":"جورجيا","Germany":"ألمانيا","Ghana":"غانا","Greece":"اليونان","Grenada":"غرينادا","Guatemala":"غواتيمالا","Guinea":"غينيا","Guinea-Bissau":"غينيا بيساو","Guyana":"غيانا","Haiti":"هايتي","Honduras":"هندوراس","Hungary":"المجر","Iceland":"آيسلندا","India":"الهند","Indonesia":"إندونيسيا","Iran":"إيران","Iraq":"العراق","Ireland":"أيرلندا","Italy":"إيطاليا","Ivory Coast":"ساحل العاج","Jamaica":"جامايكا","Japan":"اليابان","Jordan":"الأردن","Kazakhstan":"كازاخستان","Kenya":"كينيا","Kiribati":"كيريباتي","Kuwait":"الكويت","Kyrgyzstan":"قيرغيزستان","Laos":"لاوس","Latvia":"لاتفيا","Lebanon":"لبنان","Lesotho":"ليسوتو","Liberia":"ليبيريا","Libya":"ليبيا","Liechtenstein":"ليختنشتاين","Lithuania":"ليتوانيا","Luxembourg":"لوكسمبورغ","Madagascar":"مدغشقر","Malawi":"مالاوي","Malaysia":"ماليزيا","Maldives":"المالديف","Mali":"مالي","Malta":"مالطا","Marshall Islands":"جزر مارشال","Mauritania":"موريتانيا","Mauritius":"موريشيوس","Mexico":"المكسيك","Micronesia":"ميكرونيزيا","Moldova":"مولدوفا","Monaco":"موناكو","Mongolia":"منغوليا","Montenegro":"الجبل الأسود","Morocco":"المغرب","Mozambique":"موزمبيق","Myanmar":"ميانمار","Namibia":"ناميبيا","Nauru":"ناورو","Nepal":"نيبال","Netherlands":"هولندا","New Zealand":"نيوزيلندا","Nicaragua":"نيكاراغوا","Niger":"النيجر","Nigeria":"نيجيريا","North Korea":"كوريا الشمالية","North Macedonia":"مقدونيا الشمالية","Norway":"النرويج","Oman":"عُمان","Pakistan":"باكستان","Palau":"بالاو","Palestine":"فلسطين","Panama":"بنما","Papua New Guinea":"بابوا غينيا الجديدة","Paraguay":"باراغواي","Peru":"بيرو","Philippines":"الفلبين","Poland":"بولندا","Portugal":"البرتغال","Qatar":"قطر","Romania":"رومانيا","Russia":"روسيا","Rwanda":"رواندا","Saint Kitts and Nevis":"سانت كيتس ونيفيس","Saint Lucia":"سانت لوسيا","Saint Vincent and the Grenadines":"سانت فنسنت والغرينادين","Samoa":"ساموا","San Marino":"سان مارينو","Sao Tome and Principe":"ساو تومي وبرينسيب","Saudi Arabia":"السعودية","Senegal":"السنغال","Serbia":"صربيا","Seychelles":"سيشل","Sierra Leone":"سيراليون","Singapore":"سنغافورة","Slovakia":"سلوفاكيا","Slovenia":"سلوفينيا","Solomon Islands":"جزر سليمان","Somalia":"الصومال","South Africa":"جنوب أفريقيا","South Korea":"كوريا الجنوبية","South Sudan":"جنوب السودان","Spain":"إسبانيا","Sri Lanka":"سريلانكا","Sudan":"السودان","Suriname":"سورينام","Sweden":"السويد","Switzerland":"سويسرا","Syria":"سوريا","Taiwan":"تايوان","Tajikistan":"طاجيكستان","Tanzania":"تنزانيا","Thailand":"تايلاند","Timor-Leste":"تيمور الشرقية","Togo":"توغو","Tonga":"تونغا","Trinidad and Tobago":"ترينيداد وتوباغو","Tunisia":"تونس","Turkey":"تركيا","Turkmenistan":"تركمانستان","Tuvalu":"توفالو","Uganda":"أوغندا","Ukraine":"أوكرانيا","United Arab Emirates":"الإمارات العربية المتحدة","United Kingdom":"المملكة المتحدة","United States":"الولايات المتحدة","Uruguay":"أوروغواي","Uzbekistan":"أوزبكستان","Vanuatu":"فانواتو","Vatican City":"الفاتيكان","Venezuela":"فنزويلا","Vietnam":"فيتنام","Yemen":"اليمن","Zambia":"زامبيا","Zimbabwe":"زيمبابوي"},
'fr':{"Yemen":"Yémen","Saudi Arabia":"Arabie saoudite","United Arab Emirates":"Émirats arabes unis","Egypt":"Égypte","Germany":"Allemagne","Spain":"Espagne","Italy":"Italie","China":"Chine","Japan":"Japon","South Korea":"Corée du Sud","United States":"États-Unis","United Kingdom":"Royaume-Uni"},
'es':{"Yemen":"Yemen","Saudi Arabia":"Arabia Saudita","United Arab Emirates":"Emiratos Árabes Unidos","Egypt":"Egipto","Germany":"Alemania","France":"Francia","United States":"Estados Unidos","United Kingdom":"Reino Unido"},
'de':{"Yemen":"Jemen","Saudi Arabia":"Saudi-Arabien","United Arab Emirates":"Vereinigte Arabische Emirate","Egypt":"Ägypten","France":"Frankreich","United States":"Vereinigte Staaten","United Kingdom":"Vereinigtes Königreich"},
'it':{"Yemen":"Yemen","Saudi Arabia":"Arabia Saudita","United Arab Emirates":"Emirati Arabi Uniti","Egypt":"Egitto","Germany":"Germania","United States":"Stati Uniti","United Kingdom":"Regno Unito"},
'pt':{"Yemen":"Iêmen","Saudi Arabia":"Arábia Saudita","United Arab Emirates":"Emirados Árabes Unidos","Egypt":"Egito","Germany":"Alemanha","United States":"Estados Unidos","United Kingdom":"Reino Unido"},
'tr':{"Yemen":"Yemen","Saudi Arabia":"Suudi Arabistan","United Arab Emirates":"Birleşik Arap Emirlikleri","Egypt":"Mısır","Germany":"Almanya","United States":"Amerika Birleşik Devletleri","United Kingdom":"Birleşik Krallık"},
'ru':{"Yemen":"Йемен","Saudi Arabia":"Саудовская Аравия","United Arab Emirates":"ОАЭ","Egypt":"Египет","Germany":"Германия","United States":"США","United Kingdom":"Великобритания"},
'zh':{"Yemen":"也门","Saudi Arabia":"沙特阿拉伯","United Arab Emirates":"阿拉伯联合酋长国","Egypt":"埃及","Germany":"德国","France":"法国","United States":"美国","United Kingdom":"英国"},
'ja':{"Yemen":"イエメン","Saudi Arabia":"サウジアラビア","United Arab Emirates":"アラブ首長国連邦","Egypt":"エジプト","Germany":"ドイツ","United States":"アメリカ合衆国","United Kingdom":"イギリス"},
'ko':{"Yemen":"예멘","Saudi Arabia":"사우디아라비아","United Arab Emirates":"아랍에미리트","Egypt":"이집트","Germany":"독일","United States":"미국","United Kingdom":"영국"},
'ur':{"Yemen":"یمن","Saudi Arabia":"سعودی عرب","United Arab Emirates":"متحدہ عرب امارات","Egypt":"مصر","Germany":"جرمنی","United States":"امریکہ","United Kingdom":"برطانیہ"},
'fa':{"Yemen":"یمن","Saudi Arabia":"عربستان سعودی","United Arab Emirates":"امارات متحده عربی","Egypt":"مصر","Germany":"آلمان","United States":"ایالات متحده","United Kingdom":"بریتانیا"},
'id':{"Yemen":"Yaman","Saudi Arabia":"Arab Saudi","United Arab Emirates":"Uni Emirat Arab","Egypt":"Mesir","Germany":"Jerman","United States":"Amerika Serikat","United Kingdom":"Britania Raya"},
'th':{"Yemen":"เยเมน","Saudi Arabia":"ซาอุดีอาระเบีย","United Arab Emirates":"สหรัฐอาหรับเอมิเรตส์","Egypt":"อียิปต์","Germany":"เยอรมนี","United States":"สหรัฐอเมริกา","United Kingdom":"สหราชอาณาจักร"},
'hi':{"Yemen":"यमन","Saudi Arabia":"सऊदी अरब","United Arab Emirates":"संयुक्त अरब अमीरात","Egypt":"मिस्र","Germany":"जर्मनी","United States":"संयुक्त राज्य अमेरिका","United Kingdom":"यूनाइटेड किंगडम"},
};


).hasMatch(normalizedUsername)){
      setState(()=>usernameAvailable=false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(_extraText(code,'usernameRequired'))));
      return;
    }
    final usernameDoc=await FirebaseFirestore.instance.collection('usernames').doc(normalizedUsername).get();
    if(usernameDoc.exists&&usernameDoc.data()?['uid']!=user.uid){
      if(mounted)setState(()=>usernameAvailable=false);
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(_extraText(code,'usernameTaken'))));
      return;
    }
    if(mounted)setState(()=>usernameAvailable=true);
    setState(()=>saving=true); final db=FirebaseFirestore.instance;
    try{
      if(profileImage!=null){
        final uploaded=await CloudinaryImageService.uploadImage(profileImage!,folder:'worldvoice/users/${user.uid}/profile');
        photoUrl=uploaded.url; photoPublicId=uploaded.publicId;
      }
      if(coverImage!=null){
        final uploaded=await CloudinaryImageService.uploadImage(coverImage!,folder:'worldvoice/users/${user.uid}/cover');
        coverUrl=uploaded.url; coverPublicId=uploaded.publicId;
      }
      await db.runTransaction((tx)async{
      final handle=db.collection('usernames').doc(normalizedUsername); final old=await tx.get(handle);
      if(old.exists&&old.data()?['uid']!=user.uid)throw StateError('username-taken');
      tx.set(handle,{'uid':user.uid,'createdAt':FieldValue.serverTimestamp()});
      tx.set(db.collection('users').doc(user.uid),{
        'uid':user.uid,'email':user.email,'displayName':name.text.trim(),'username':normalizedUsername,
        'bio':bio.text.trim(),'country':country,'city':city.text.trim(),'gender':gender,
        'photoUrl':photoUrl,'photoPublicId':photoPublicId,'coverUrl':coverUrl,'coverPublicId':coverPublicId,
        'birthDate':birthDate==null?null:Timestamp.fromDate(birthDate!),'nativeLanguage':nativeLanguage,
        'learningLanguages':learningLanguage==null?<String>[]:[learningLanguage],'languageLevel':languageLevel,
        'profession':profession.text.trim(),'travel':travel.text.trim(),'learningGoals':goals.text.trim(),
        'interests':selectedHobbies.toList(),'profileCompleted':true,'followersCount':0,'followingCount':0,
        'isVip':false,'isPartner':false,'isVerified':false,'updatedAt':FieldValue.serverTimestamp(),
        'createdAt':FieldValue.serverTimestamp(),
      },SetOptions(merge:true));
    });
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor:const Color(0xFF159B62),content:Text(_extraText(widget.localeController.locale?.languageCode??'en','saved'),style:const TextStyle(color:Colors.white))));
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));
    }finally{if(mounted)setState(()=>saving=false);}
  }

  @override void dispose(){for(final c in [name,username,bio,city,profession,travel,goals,interests]){c.dispose();}super.dispose();}

  @override Widget build(BuildContext context){
    final code=widget.localeController.locale?.languageCode??'en';
    final rtl=const {'ar','ur','fa'}.contains(code); final cs=Theme.of(context).colorScheme;
    String t(String key)=>_profileText(code,key);
    return Directionality(textDirection:rtl?TextDirection.rtl:TextDirection.ltr,child:Scaffold(body:SafeArea(child:ListView(
      padding:const EdgeInsets.fromLTRB(18,16,18,36),children:[
      Text(t('title'),style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),
      const SizedBox(height:18),
      Container(height:150,decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),gradient:LinearGradient(colors:[cs.primary.withValues(alpha:.75),cs.tertiary.withValues(alpha:.45)]),image:coverImage==null?null:DecorationImage(image:FileImage(coverImage!),fit:BoxFit.cover)),
        child:Stack(children:[if(coverImage==null)const Center(child:Icon(Icons.landscape_rounded,size:42)),Positioned(top:8,left:8,child:IconButton.filledTonal(onPressed:pickCoverImage,icon:const Icon(Icons.wallpaper_rounded,size:18)))])),
      Transform.translate(offset:const Offset(0,-28),child:Center(child:Container(width:104,height:104,padding:const EdgeInsets.all(3),decoration:BoxDecoration(shape:BoxShape.circle,color:cs.surface),
        child:CircleAvatar(backgroundColor:cs.surfaceContainerHighest,backgroundImage:profileImage==null?null:FileImage(profileImage!),child:profileImage==null?IconButton(onPressed:pickProfileImage,icon:const Icon(Icons.add_a_photo_rounded,size:26)):Align(alignment:Alignment.bottomRight,child:IconButton.filledTonal(onPressed:pickProfileImage,icon:const Icon(Icons.edit_rounded,size:16))))))),
      _Field(name,t('name'),Icons.badge_outlined),const SizedBox(height:10),
      TextField(controller:username,textDirection:TextDirection.ltr,onChanged:(_)=>setState(()=>usernameAvailable=null),decoration:InputDecoration(labelText:t('username'),hintText:'@username',prefixIcon:const Icon(Icons.alternate_email_rounded,size:20),suffixIcon:IconButton(onPressed:checkUsername,icon:Icon(usernameAvailable==true?Icons.check_circle:usernameAvailable==false?Icons.cancel:Icons.search,size:20,color:usernameAvailable==true?Colors.green:null)))),
      const SizedBox(height:12),
      Stack(alignment:rtl?Alignment.bottomLeft:Alignment.bottomRight,children:[_Field(bio,t('about'),Icons.auto_awesome_rounded,lines:4),Padding(padding:const EdgeInsets.all(6),child:IconButton.filledTonal(onPressed:(){},icon:const Icon(Icons.mic_rounded,size:18)))]),
      const SizedBox(height:12),
      _Tile(Icons.public_rounded,t('country'),country==null?t('chooseCountry'):'${_flagForCountry(country!)}  ${_countryText(code,country!)}',()async{final v=await choose(t('country'),countries,label:(v)=>_countryText(code,v),showFlags:true);if(v!=null)setState(()=>country=v);}),
      _Field(city,t('city'),Icons.location_city_outlined),const SizedBox(height:10),
      _BirthFields(value:birthDate,code:code,onChanged:(d)=>setState(()=>birthDate=d)),
      _GenderPicker(value:gender,code:code,onChanged:(v)=>setState(()=>gender=v)),
      _Tile(Icons.translate_rounded,t('native'),nativeLanguage==null?t('chooseLanguage'):_languageText(code,nativeLanguage!),()async{final v=await choose(t('native'),languages,label:(v)=>_languageText(code,v));if(v!=null)setState(()=>nativeLanguage=v);}),
      _Tile(Icons.language_rounded,t('learning'),learningLanguage==null?t('chooseLanguage'):_languageText(code,learningLanguage!),()async{final v=await choose(t('learning'),languages,label:(v)=>_languageText(code,v));if(v!=null)setState(()=>learningLanguage=v);}),
      _Tile(Icons.trending_up_rounded,t('level'),_profileText(code,languageLevel),()async{final v=await choose(t('level'),['beginner','intermediate','advanced'],label:(v)=>_profileText(code,v));if(v!=null)setState(()=>languageLevel=v);}),
      _Tile(Icons.favorite_outline_rounded,t('hobbies'),selectedHobbies.isEmpty?t('chooseHobbies'):selectedHobbies.map((e)=>'${_hobbyEmoji(e)} ${_profileText(code,e)}').join(' • '),()async{await _pickHobbies(context,code,selectedHobbies);if(mounted)setState(()=>interests.text=selectedHobbies.join(','));}),
      _Field(goals,t('goals'),Icons.track_changes_rounded,lines:2),const SizedBox(height:10),
      _Field(profession,t('profession'),Icons.work_outline_rounded),const SizedBox(height:10),
      _Field(travel,t('travel'),Icons.flight_takeoff_rounded,lines:2),const SizedBox(height:22),
      SizedBox(height:58,child:FilledButton.icon(onPressed:saving?null:saveProfile,icon:saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.rocket_launch_rounded,size:20),label:Text(t('launch'),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17))))
    ]))));
  }
}


const _pt=<String,List<String>>{
'ar':['أنشئ هويتك في WorldVoice','الاسم','اسم المستخدم الفريد','ماذا عنك؟','الدولة','اختر دولتك','المدينة','اللغة الأم','اللغة التي تتعلمها','اختر اللغة','المستوى','الهوايات والاهتمامات','اختر هواياتك','أهداف التعلم','المهنة / الدراسة','السفر','إطلاق بروفايلي','مبتدئ','متوسط','متقدم','موسيقى','أفلام','رياضة','سفر','ألعاب','قراءة','تصوير','رسم','طبخ','تقنية'],
'en':['Create your WorldVoice identity','Name','Unique username','About you','Country','Choose country','City','Native language','Learning language','Choose language','Level','Interests & hobbies','Choose your hobbies','Learning goals','Profession / study','Travel','Launch my profile','Beginner','Intermediate','Advanced','Music','Movies','Sports','Travel','Gaming','Reading','Photography','Drawing','Cooking','Technology'],
'es':['Crea tu identidad en WorldVoice','Nombre','Nombre de usuario único','Sobre ti','País','Elige país','Ciudad','Idioma nativo','Idioma que aprendes','Elige idioma','Nivel','Intereses y aficiones','Elige tus aficiones','Objetivos de aprendizaje','Profesión / estudios','Viajes','Crear mi perfil','Principiante','Intermedio','Avanzado','Música','Películas','Deportes','Viajes','Videojuegos','Lectura','Fotografía','Dibujo','Cocina','Tecnología'],
'fr':['Créez votre identité WorldVoice','Nom','Nom d’utilisateur unique','À propos de vous','Pays','Choisir un pays','Ville','Langue maternelle','Langue apprise','Choisir une langue','Niveau','Centres d’intérêt et loisirs','Choisissez vos loisirs','Objectifs d’apprentissage','Profession / études','Voyages','Créer mon profil','Débutant','Intermédiaire','Avancé','Musique','Films','Sport','Voyages','Jeux vidéo','Lecture','Photographie','Dessin','Cuisine','Technologie'],
'de':['Erstelle deine WorldVoice-Identität','Name','Eindeutiger Benutzername','Über dich','Land','Land wählen','Stadt','Muttersprache','Lernsprache','Sprache wählen','Niveau','Interessen & Hobbys','Hobbys wählen','Lernziele','Beruf / Studium','Reisen','Profil erstellen','Anfänger','Mittelstufe','Fortgeschritten','Musik','Filme','Sport','Reisen','Gaming','Lesen','Fotografie','Zeichnen','Kochen','Technologie'],
'it':['Crea la tua identità WorldVoice','Nome','Nome utente univoco','Su di te','Paese','Scegli paese','Città','Lingua madre','Lingua studiata','Scegli lingua','Livello','Interessi e hobby','Scegli i tuoi hobby','Obiettivi di apprendimento','Professione / studi','Viaggi','Crea il mio profilo','Principiante','Intermedio','Avanzato','Musica','Film','Sport','Viaggi','Videogiochi','Lettura','Fotografia','Disegno','Cucina','Tecnologia'],
'pt':['Crie sua identidade WorldVoice','Nome','Nome de usuário exclusivo','Sobre você','País','Escolha o país','Cidade','Idioma nativo','Idioma que aprende','Escolha o idioma','Nível','Interesses e hobbies','Escolha seus hobbies','Objetivos de aprendizagem','Profissão / estudos','Viagens','Criar meu perfil','Iniciante','Intermediário','Avançado','Música','Filmes','Esportes','Viagens','Jogos','Leitura','Fotografia','Desenho','Culinária','Tecnologia'],
'tr':['WorldVoice kimliğini oluştur','Ad','Benzersiz kullanıcı adı','Hakkında','Ülke','Ülke seç','Şehir','Ana dil','Öğrenilen dil','Dil seç','Seviye','İlgi alanları ve hobiler','Hobilerini seç','Öğrenme hedefleri','Meslek / eğitim','Seyahat','Profilimi oluştur','Başlangıç','Orta','İleri','Müzik','Filmler','Spor','Seyahat','Oyun','Okuma','Fotoğrafçılık','Çizim','Yemek','Teknoloji'],
'ru':['Создайте профиль WorldVoice','Имя','Уникальное имя пользователя','О себе','Страна','Выберите страну','Город','Родной язык','Изучаемый язык','Выберите язык','Уровень','Интересы и хобби','Выберите хобби','Цели обучения','Работа / учёба','Путешествия','Создать профиль','Начальный','Средний','Продвинутый','Музыка','Фильмы','Спорт','Путешествия','Игры','Чтение','Фотография','Рисование','Кулинария','Технологии'],
'zh':['创建你的 WorldVoice 身份','姓名','唯一用户名','关于你','国家','选择国家','城市','母语','学习语言','选择语言','水平','兴趣爱好','选择爱好','学习目标','职业 / 学业','旅行','创建我的个人资料','初级','中级','高级','音乐','电影','运动','旅行','游戏','阅读','摄影','绘画','烹饪','科技'],
'ja':['WorldVoiceプロフィールを作成','名前','固有のユーザー名','自己紹介','国','国を選択','都市','母語','学習言語','言語を選択','レベル','興味・趣味','趣味を選択','学習目標','職業 / 学業','旅行','プロフィールを作成','初級','中級','上級','音楽','映画','スポーツ','旅行','ゲーム','読書','写真','絵','料理','テクノロジー'],
'ko':['WorldVoice 프로필 만들기','이름','고유 사용자 이름','자기소개','국가','국가 선택','도시','모국어','학습 언어','언어 선택','레벨','관심사 및 취미','취미 선택','학습 목표','직업 / 학업','여행','프로필 만들기','초급','중급','고급','음악','영화','스포츠','여행','게임','독서','사진','그림','요리','기술'],
'ur':['اپنی WorldVoice شناخت بنائیں','نام','منفرد صارف نام','اپنے بارے میں','ملک','ملک منتخب کریں','شہر','مادری زبان','سیکھنے کی زبان','زبان منتخب کریں','سطح','دلچسپیاں اور مشاغل','اپنے مشاغل منتخب کریں','سیکھنے کے اہداف','پیشہ / تعلیم','سفر','میرا پروفائل بنائیں','ابتدائی','درمیانی','اعلیٰ','موسیقی','فلمیں','کھیل','سفر','گیمنگ','مطالعہ','فوٹوگرافی','ڈرائنگ','کھانا پکانا','ٹیکنالوجی'],
'fa':['هویت WorldVoice خود را بسازید','نام','نام کاربری منحصربه‌فرد','درباره شما','کشور','کشور را انتخاب کنید','شهر','زبان مادری','زبان در حال یادگیری','زبان را انتخاب کنید','سطح','علایق و سرگرمی‌ها','سرگرمی‌ها را انتخاب کنید','اهداف یادگیری','شغل / تحصیل','سفر','ساخت پروفایل','مبتدی','متوسط','پیشرفته','موسیقی','فیلم','ورزش','سفر','بازی','مطالعه','عکاسی','نقاشی','آشپزی','فناوری'],
'id':['Buat identitas WorldVoice Anda','Nama','Nama pengguna unik','Tentang Anda','Negara','Pilih negara','Kota','Bahasa ibu','Bahasa yang dipelajari','Pilih bahasa','Tingkat','Minat & hobi','Pilih hobi Anda','Tujuan belajar','Profesi / studi','Perjalanan','Buat profil saya','Pemula','Menengah','Mahir','Musik','Film','Olahraga','Perjalanan','Game','Membaca','Fotografi','Menggambar','Memasak','Teknologi'],
'th':['สร้างโปรไฟล์ WorldVoice','ชื่อ','ชื่อผู้ใช้ไม่ซ้ำ','เกี่ยวกับคุณ','ประเทศ','เลือกประเทศ','เมือง','ภาษาแม่','ภาษาที่เรียน','เลือกภาษา','ระดับ','ความสนใจและงานอดิเรก','เลือกงานอดิเรก','เป้าหมายการเรียน','อาชีพ / การศึกษา','การเดินทาง','สร้างโปรไฟล์','เริ่มต้น','ปานกลาง','ขั้นสูง','ดนตรี','ภาพยนตร์','กีฬา','ท่องเที่ยว','เกม','อ่านหนังสือ','ถ่ายภาพ','วาดภาพ','ทำอาหาร','เทคโนโลยี'],
'hi':['अपनी WorldVoice पहचान बनाएँ','नाम','विशिष्ट यूज़रनेम','अपने बारे में','देश','देश चुनें','शहर','मातृभाषा','सीखी जा रही भाषा','भाषा चुनें','स्तर','रुचियाँ और शौक','अपने शौक चुनें','सीखने के लक्ष्य','पेशा / पढ़ाई','यात्रा','मेरा प्रोफ़ाइल बनाएँ','शुरुआती','मध्यम','उन्नत','संगीत','फ़िल्में','खेल','यात्रा','गेमिंग','पढ़ना','फ़ोटोग्राफ़ी','चित्रकारी','खाना बनाना','तकनीक']
};
const _pk=['title','name','username','about','country','chooseCountry','city','native','learning','chooseLanguage','level','hobbies','chooseHobbies','goals','profession','travel','launch','beginner','intermediate','advanced','music','movies','sports','travel_hobby','gaming','reading','photography','drawing','cooking','technology'];

const _hobbyLabels=<String,Map<String,String>>{
'ar':{
'football':'كرة القدم','basketball':'كرة السلة','volleyball':'الكرة الطائرة','tennis':'التنس','swimming':'السباحة','running':'الجري','gym':'اللياقة والجيم','martialArts':'الفنون القتالية','cycling':'ركوب الدراجات','padel':'البادل','boxing':'الملاكمة','yoga':'اليوغا','hiking':'المشي الجبلي','dancing':'الرقص','singing':'الغناء','writing':'الكتابة','fashion':'الموضة','gardening':'البستنة','cars':'السيارات','nature':'الطبيعة','chess':'الشطرنج','pets':'الحيوانات الأليفة'},
'en':{
'football':'Football','basketball':'Basketball','volleyball':'Volleyball','tennis':'Tennis','swimming':'Swimming','running':'Running','gym':'Fitness & gym','martialArts':'Martial arts','cycling':'Cycling','padel':'Padel','boxing':'Boxing','yoga':'Yoga','hiking':'Hiking','dancing':'Dancing','singing':'Singing','writing':'Writing','fashion':'Fashion','gardening':'Gardening','cars':'Cars','nature':'Nature','chess':'Chess','pets':'Pets'},
'es':{
'football':'Fútbol','basketball':'Baloncesto','volleyball':'Voleibol','tennis':'Tenis','swimming':'Natación','running':'Correr','gym':'Fitness y gimnasio','martialArts':'Artes marciales','cycling':'Ciclismo','padel':'Pádel','boxing':'Boxeo','yoga':'Yoga','hiking':'Senderismo','dancing':'Baile','singing':'Canto','writing':'Escritura','fashion':'Moda','gardening':'Jardinería','cars':'Autos','nature':'Naturaleza','chess':'Ajedrez','pets':'Mascotas'},
'fr':{
'football':'Football','basketball':'Basket-ball','volleyball':'Volley-ball','tennis':'Tennis','swimming':'Natation','running':'Course à pied','gym':'Fitness et salle de sport','martialArts':'Arts martiaux','cycling':'Cyclisme','padel':'Padel','boxing':'Boxe','yoga':'Yoga','hiking':'Randonnée','dancing':'Danse','singing':'Chant','writing':'Écriture','fashion':'Mode','gardening':'Jardinage','cars':'Voitures','nature':'Nature','chess':'Échecs','pets':'Animaux'},
'de':{
'football':'Fußball','basketball':'Basketball','volleyball':'Volleyball','tennis':'Tennis','swimming':'Schwimmen','running':'Laufen','gym':'Fitness & Gym','martialArts':'Kampfsport','cycling':'Radfahren','padel':'Padel','boxing':'Boxen','yoga':'Yoga','hiking':'Wandern','dancing':'Tanzen','singing':'Singen','writing':'Schreiben','fashion':'Mode','gardening':'Gärtnern','cars':'Autos','nature':'Natur','chess':'Schach','pets':'Haustiere'},
'it':{
'football':'Calcio','basketball':'Pallacanestro','volleyball':'Pallavolo','tennis':'Tennis','swimming':'Nuoto','running':'Corsa','gym':'Fitness e palestra','martialArts':'Arti marziali','cycling':'Ciclismo','padel':'Padel','boxing':'Boxe','yoga':'Yoga','hiking':'Escursionismo','dancing':'Danza','singing':'Canto','writing':'Scrittura','fashion':'Moda','gardening':'Giardinaggio','cars':'Auto','nature':'Natura','chess':'Scacchi','pets':'Animali domestici'},
'pt':{
'football':'Futebol','basketball':'Basquete','volleyball':'Vôlei','tennis':'Tênis','swimming':'Natação','running':'Corrida','gym':'Fitness e academia','martialArts':'Artes marciais','cycling':'Ciclismo','padel':'Padel','boxing':'Boxe','yoga':'Yoga','hiking':'Caminhada','dancing':'Dança','singing':'Canto','writing':'Escrita','fashion':'Moda','gardening':'Jardinagem','cars':'Carros','nature':'Natureza','chess':'Xadrez','pets':'Animais de estimação'},
'tr':{
'football':'Futbol','basketball':'Basketbol','volleyball':'Voleybol','tennis':'Tenis','swimming':'Yüzme','running':'Koşu','gym':'Fitness ve spor salonu','martialArts':'Dövüş sanatları','cycling':'Bisiklet','padel':'Padel','boxing':'Boks','yoga':'Yoga','hiking':'Doğa yürüyüşü','dancing':'Dans','singing':'Şarkı söyleme','writing':'Yazma','fashion':'Moda','gardening':'Bahçecilik','cars':'Arabalar','nature':'Doğa','chess':'Satranç','pets':'Evcil hayvanlar'},
'ru':{
'football':'Футбол','basketball':'Баскетбол','volleyball':'Волейбол','tennis':'Теннис','swimming':'Плавание','running':'Бег','gym':'Фитнес и тренажёрный зал','martialArts':'Боевые искусства','cycling':'Велоспорт','padel':'Падел','boxing':'Бокс','yoga':'Йога','hiking':'Пешие походы','dancing':'Танцы','singing':'Пение','writing':'Письмо','fashion':'Мода','gardening':'Садоводство','cars':'Автомобили','nature':'Природа','chess':'Шахматы','pets':'Домашние животные'},
'zh':{
'football':'足球','basketball':'篮球','volleyball':'排球','tennis':'网球','swimming':'游泳','running':'跑步','gym':'健身房','martialArts':'武术','cycling':'骑行','padel':'板式网球','boxing':'拳击','yoga':'瑜伽','hiking':'徒步','dancing':'舞蹈','singing':'唱歌','writing':'写作','fashion':'时尚','gardening':'园艺','cars':'汽车','nature':'自然','chess':'国际象棋','pets':'宠物'},
'ja':{
'football':'サッカー','basketball':'バスケットボール','volleyball':'バレーボール','tennis':'テニス','swimming':'水泳','running':'ランニング','gym':'フィットネス・ジム','martialArts':'武道','cycling':'サイクリング','padel':'パデル','boxing':'ボクシング','yoga':'ヨガ','hiking':'ハイキング','dancing':'ダンス','singing':'歌','writing':'執筆','fashion':'ファッション','gardening':'ガーデニング','cars':'車','nature':'自然','chess':'チェス','pets':'ペット'},
'ko':{
'football':'축구','basketball':'농구','volleyball':'배구','tennis':'테니스','swimming':'수영','running':'달리기','gym':'피트니스·헬스장','martialArts':'무술','cycling':'사이클링','padel':'파델','boxing':'복싱','yoga':'요가','hiking':'하이킹','dancing':'춤','singing':'노래','writing':'글쓰기','fashion':'패션','gardening':'정원 가꾸기','cars':'자동차','nature':'자연','chess':'체스','pets':'반려동물'},
'ur':{
'football':'فٹ بال','basketball':'باسکٹ بال','volleyball':'والی بال','tennis':'ٹینس','swimming':'تیراکی','running':'دوڑ','gym':'فٹنس اور جم','martialArts':'مارشل آرٹس','cycling':'سائیکلنگ','padel':'پیڈل','boxing':'باکسنگ','yoga':'یوگا','hiking':'ہائیکنگ','dancing':'رقص','singing':'گانا','writing':'لکھائی','fashion':'فیشن','gardening':'باغبانی','cars':'گاڑیاں','nature':'فطرت','chess':'شطرنج','pets':'پالتو جانور'},
'fa':{
'football':'فوتبال','basketball':'بسکتبال','volleyball':'والیبال','tennis':'تنیس','swimming':'شنا','running':'دویدن','gym':'تناسب اندام و باشگاه','martialArts':'هنرهای رزمی','cycling':'دوچرخه‌سواری','padel':'پدل','boxing':'بوکس','yoga':'یوگا','hiking':'پیاده‌روی','dancing':'رقص','singing':'آوازخوانی','writing':'نویسندگی','fashion':'مد','gardening':'باغبانی','cars':'خودرو','nature':'طبیعت','chess':'شطرنج','pets':'حیوانات خانگی'},
'id':{
'football':'Sepak bola','basketball':'Bola basket','volleyball':'Bola voli','tennis':'Tenis','swimming':'Renang','running':'Lari','gym':'Kebugaran & gym','martialArts':'Seni bela diri','cycling':'Bersepeda','padel':'Padel','boxing':'Tinju','yoga':'Yoga','hiking':'Mendaki','dancing':'Menari','singing':'Bernyanyi','writing':'Menulis','fashion':'Mode','gardening':'Berkebun','cars':'Mobil','nature':'Alam','chess':'Catur','pets':'Hewan peliharaan'},
'th':{
'football':'ฟุตบอล','basketball':'บาสเกตบอล','volleyball':'วอลเลย์บอล','tennis':'เทนนิส','swimming':'ว่ายน้ำ','running':'วิ่ง','gym':'ฟิตเนสและยิม','martialArts':'ศิลปะการต่อสู้','cycling':'ปั่นจักรยาน','padel':'พาเดล','boxing':'มวย','yoga':'โยคะ','hiking':'เดินป่า','dancing':'เต้นรำ','singing':'ร้องเพลง','writing':'เขียน','fashion':'แฟชั่น','gardening':'ทำสวน','cars':'รถยนต์','nature':'ธรรมชาติ','chess':'หมากรุก','pets':'สัตว์เลี้ยง'},
'hi':{
'football':'फ़ुटबॉल','basketball':'बास्केटबॉल','volleyball':'वॉलीबॉल','tennis':'टेनिस','swimming':'तैराकी','running':'दौड़ना','gym':'फिटनेस और जिम','martialArts':'मार्शल आर्ट्स','cycling':'साइकिलिंग','padel':'पैडल','boxing':'बॉक्सिंग','yoga':'योग','hiking':'हाइकिंग','dancing':'नृत्य','singing':'गायन','writing':'लेखन','fashion':'फैशन','gardening':'बागवानी','cars':'कारें','nature':'प्रकृति','chess':'शतरंज','pets':'पालतू जानवर'},
};

String _profileText(String code,String key){
  final hobby=_hobbyLabels[code]?[key]??_hobbyLabels['en']?[key];
  if(hobby!=null)return hobby;
  final i=_pk.indexOf(key);
  final a=_pt[code]??_pt['en']!;
  return i<0?key:a[i];
}

String _hobbyEmoji(String key){
  const icons=<String,String>{
    'music':'🎵','movies':'🎬','football':'⚽','basketball':'🏀','volleyball':'🏐','tennis':'🎾',
    'swimming':'🏊','running':'🏃','gym':'🏋️','martialArts':'🥋','cycling':'🚴','padel':'🏓',
    'boxing':'🥊','yoga':'🧘','hiking':'🥾','travel_hobby':'✈️','gaming':'🎮','reading':'📚',
    'photography':'📷','drawing':'🎨','cooking':'🍳','technology':'💻','dancing':'💃',
    'singing':'🎤','writing':'✍️','fashion':'👗','gardening':'🌱','cars':'🏎️','nature':'🌿',
    'chess':'♟️','pets':'🐾',
  };
  return icons[key]??'✨';
}

Future<void> _pickHobbies(BuildContext context,String code,Set<String> selected) async{
  const keys=[
    'music','movies','football','basketball','volleyball','tennis','swimming','running','gym',
    'martialArts','cycling','padel','boxing','yoga','hiking','travel_hobby','gaming','reading',
    'photography','drawing','cooking','technology','dancing','singing','writing','fashion',
    'gardening','cars','nature','chess','pets'
  ];
  await showModalBottomSheet(
    context:context,
    isScrollControlled:true,
    useSafeArea:true,
    showDragHandle:true,
    builder:(ctx)=>StatefulBuilder(builder:(ctx,setSheet){
      final cs=Theme.of(ctx).colorScheme;
      return FractionallySizedBox(
        heightFactor:.90,
        child:Column(children:[
          Padding(
            padding:const EdgeInsets.fromLTRB(18,2,18,12),
            child:Row(children:[
              Expanded(child:Text(_profileText(code,'hobbies'),style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900))),
              FilledButton.tonalIcon(
                onPressed:()=>Navigator.pop(ctx),
                icon:const Icon(Icons.check_rounded,size:20),
                label:Text('${selected.length}'),
              ),
            ]),
          ),
          Expanded(
            child:ListView.separated(
              padding:const EdgeInsets.fromLTRB(12,0,12,24),
              itemCount:keys.length,
              separatorBuilder:(_,__)=>const SizedBox(height:4),
              itemBuilder:(_,i){
                final k=keys[i];
                final checked=selected.contains(k);
                return Material(
                  color:checked?cs.primaryContainer.withValues(alpha:.35):Colors.transparent,
                  borderRadius:BorderRadius.circular(16),
                  child:ListTile(
                    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
                    leading:CircleAvatar(
                      backgroundColor:checked?cs.primaryContainer:cs.surfaceContainerHighest,
                      child:Text(_hobbyEmoji(k),style:const TextStyle(fontSize:21)),
                    ),
                    title:Text(_profileText(code,k),style:TextStyle(fontWeight:checked?FontWeight.w800:FontWeight.w600)),
                    trailing:Icon(
                      checked?Icons.check_circle_rounded:Icons.circle_outlined,
                      color:checked?cs.primary:cs.outline,
                    ),
                    onTap:()=>setSheet((){
                      checked?selected.remove(k):selected.add(k);
                    }),
                  ),
                );
              },
            ),
          ),
        ]),
      );
    }),
  );
}

class _Field extends StatelessWidget{
  const _Field(this.controller,this.label,this.icon,{this.lines=1}); final TextEditingController controller;final String label;final IconData icon;final int lines;
  @override Widget build(BuildContext context)=>TextField(controller:controller,maxLines:lines,decoration:InputDecoration(labelText:label,prefixIcon:Icon(icon,size:19)));
}
class _Tile extends StatelessWidget{
  const _Tile(this.icon,this.title,this.subtitle,this.tap);final IconData icon;final String title,subtitle;final VoidCallback tap;
  @override Widget build(BuildContext context)=>Card(margin:const EdgeInsets.only(bottom:10),child:ListTile(dense:true,contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:5),leading:CircleAvatar(radius:17,child:Icon(icon,size:18)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right_rounded,size:20),onTap:tap));
}

String _flagForCountry(String country) {
  const codes=<String,String>{
'Afghanistan':'AF','Albania':'AL','Algeria':'DZ','Andorra':'AD','Angola':'AO','Antigua and Barbuda':'AG','Argentina':'AR','Armenia':'AM','Australia':'AU','Austria':'AT','Azerbaijan':'AZ','Bahamas':'BS','Bahrain':'BH','Bangladesh':'BD','Barbados':'BB','Belarus':'BY','Belgium':'BE','Belize':'BZ','Benin':'BJ','Bhutan':'BT','Bolivia':'BO','Bosnia and Herzegovina':'BA','Botswana':'BW','Brazil':'BR','Brunei':'BN','Bulgaria':'BG','Burkina Faso':'BF','Burundi':'BI','Cabo Verde':'CV','Cambodia':'KH','Cameroon':'CM','Canada':'CA','Central African Republic':'CF','Chad':'TD','Chile':'CL','China':'CN','Colombia':'CO','Comoros':'KM','Congo':'CG','Costa Rica':'CR','Croatia':'HR','Cuba':'CU','Cyprus':'CY','Czechia':'CZ','Denmark':'DK','Djibouti':'DJ','Dominica':'DM','Dominican Republic':'DO','Ecuador':'EC','Egypt':'EG','El Salvador':'SV','Equatorial Guinea':'GQ','Eritrea':'ER','Estonia':'EE','Eswatini':'SZ','Ethiopia':'ET','Fiji':'FJ','Finland':'FI','France':'FR','Gabon':'GA','Gambia':'GM','Georgia':'GE','Germany':'DE','Ghana':'GH','Greece':'GR','Grenada':'GD','Guatemala':'GT','Guinea':'GN','Guinea-Bissau':'GW','Guyana':'GY','Haiti':'HT','Honduras':'HN','Hungary':'HU','Iceland':'IS','India':'IN','Indonesia':'ID','Iran':'IR','Iraq':'IQ','Ireland':'IE','Italy':'IT','Ivory Coast':'CI','Jamaica':'JM','Japan':'JP','Jordan':'JO','Kazakhstan':'KZ','Kenya':'KE','Kiribati':'KI','Kuwait':'KW','Kyrgyzstan':'KG','Laos':'LA','Latvia':'LV','Lebanon':'LB','Lesotho':'LS','Liberia':'LR','Libya':'LY','Liechtenstein':'LI','Lithuania':'LT','Luxembourg':'LU','Madagascar':'MG','Malawi':'MW','Malaysia':'MY','Maldives':'MV','Mali':'ML','Malta':'MT','Marshall Islands':'MH','Mauritania':'MR','Mauritius':'MU','Mexico':'MX','Micronesia':'FM','Moldova':'MD','Monaco':'MC','Mongolia':'MN','Montenegro':'ME','Morocco':'MA','Mozambique':'MZ','Myanmar':'MM','Namibia':'NA','Nauru':'NR','Nepal':'NP','Netherlands':'NL','New Zealand':'NZ','Nicaragua':'NI','Niger':'NE','Nigeria':'NG','North Korea':'KP','North Macedonia':'MK','Norway':'NO','Oman':'OM','Pakistan':'PK','Palau':'PW','Palestine':'PS','Panama':'PA','Papua New Guinea':'PG','Paraguay':'PY','Peru':'PE','Philippines':'PH','Poland':'PL','Portugal':'PT','Qatar':'QA','Romania':'RO','Russia':'RU','Rwanda':'RW','Saint Kitts and Nevis':'KN','Saint Lucia':'LC','Saint Vincent and the Grenadines':'VC','Samoa':'WS','San Marino':'SM','Sao Tome and Principe':'ST','Saudi Arabia':'SA','Senegal':'SN','Serbia':'RS','Seychelles':'SC','Sierra Leone':'SL','Singapore':'SG','Slovakia':'SK','Slovenia':'SI','Solomon Islands':'SB','Somalia':'SO','South Africa':'ZA','South Korea':'KR','South Sudan':'SS','Spain':'ES','Sri Lanka':'LK','Sudan':'SD','Suriname':'SR','Sweden':'SE','Switzerland':'CH','Syria':'SY','Tajikistan':'TJ','Tanzania':'TZ','Thailand':'TH','Timor-Leste':'TL','Togo':'TG','Tonga':'TO','Trinidad and Tobago':'TT','Tunisia':'TN','Turkey':'TR','Turkmenistan':'TM','Tuvalu':'TV','Uganda':'UG','Ukraine':'UA','United Arab Emirates':'AE','United Kingdom':'GB','United States':'US','Uruguay':'UY','Uzbekistan':'UZ','Vanuatu':'VU','Vatican City':'VA','Venezuela':'VE','Vietnam':'VN','Yemen':'YE','Zambia':'ZM','Zimbabwe':'ZW'};
  final code=codes[country]; if(code==null)return '🌐';
  return String.fromCharCodes(code.codeUnits.map((c)=>0x1F1E6+c-65));
}

class _BirthFields extends StatefulWidget {
  const _BirthFields({required this.value,required this.code,required this.onChanged});
  final DateTime? value; final String code; final ValueChanged<DateTime?> onChanged;
  @override State<_BirthFields> createState()=>_BirthFieldsState();
}
class _BirthFieldsState extends State<_BirthFields>{
  late final day=TextEditingController(text:widget.value?.day.toString()??'');
  late final month=TextEditingController(text:widget.value?.month.toString()??'');
  late final year=TextEditingController(text:widget.value?.year.toString()??'');
  void update(){final d=int.tryParse(day.text),m=int.tryParse(month.text),y=int.tryParse(year.text);if(d!=null&&m!=null&&y!=null){try{final v=DateTime(y,m,d);if(v.year==y&&v.month==m&&v.day==d&&v.isBefore(DateTime.now()))widget.onChanged(v);else widget.onChanged(null);}catch(_){widget.onChanged(null);}}}
  @override void dispose(){day.dispose();month.dispose();year.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(_extraText(widget.code,'birthDate'),style:const TextStyle(fontWeight:FontWeight.w800)),
    const SizedBox(height:8),
    Row(children:[
      Expanded(child:DropdownButtonFormField<int>(initialValue:int.tryParse(day.text),decoration:InputDecoration(labelText:_extraText(widget.code,'day')),items:List.generate(31,(i)=>DropdownMenuItem(value:i+1,child:Text('${i+1}'))),onChanged:(v){day.text=v?.toString()??'';update();})),
      const SizedBox(width:8),
      Expanded(child:DropdownButtonFormField<int>(initialValue:int.tryParse(month.text),decoration:InputDecoration(labelText:_extraText(widget.code,'month')),items:List.generate(12,(i)=>DropdownMenuItem(value:i+1,child:Text('${i+1}'))),onChanged:(v){month.text=v?.toString()??'';update();})),
      const SizedBox(width:8),
      Expanded(child:DropdownButtonFormField<int>(initialValue:int.tryParse(year.text),decoration:InputDecoration(labelText:_extraText(widget.code,'year')),items:List.generate(DateTime.now().year-1900,(i){final y=DateTime.now().year-i;return DropdownMenuItem(value:y,child:Text('$y'));}),onChanged:(v){year.text=v?.toString()??'';update();})),
    ]),const SizedBox(height:10)]);
}
class _GenderPicker extends StatelessWidget{
  const _GenderPicker({required this.value,required this.code,required this.onChanged});
  final String? value;final String code;final ValueChanged<String> onChanged;
  @override Widget build(BuildContext context)=>Card(margin:const EdgeInsets.only(bottom:10),child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[
    Text(_extraText(code,'gender'),style:const TextStyle(fontWeight:FontWeight.w800)),const Spacer(),
    IconButton.filledTonal(onPressed:()=>onChanged('male'),tooltip:_extraText(code,'male'),icon:Icon(Icons.male_rounded,color:Colors.blue,size:25),style:IconButton.styleFrom(side:value=='male'?const BorderSide(width:2):null)),
    const SizedBox(width:8),
    IconButton.filledTonal(onPressed:()=>onChanged('female'),tooltip:_extraText(code,'female'),icon:Icon(Icons.female_rounded,color:Colors.pink,size:25),style:IconButton.styleFrom(side:value=='female'?const BorderSide(width:2):null)),
    const SizedBox(width:8),
    IconButton.outlined(onPressed:()=>onChanged('prefer_not_to_say'),tooltip:_extraText(code,'prefer'),icon:const Icon(Icons.remove_rounded,size:22)),
  ])));
}

const _extra=<String,List<String>>{
'ar':['تاريخ الميلاد','اليوم','الشهر','السنة','الجنس','ذكر','أنثى','أفضل عدم الإجابة','تم حفظ البروفايل بنجاح ✓'],
'en':['Date of birth','Day','Month','Year','Gender','Male','Female','Prefer not to say','Profile saved successfully ✓'],
'es':['Fecha de nacimiento','Día','Mes','Año','Género','Hombre','Mujer','Prefiero no responder','Perfil guardado correctamente ✓'],
'fr':['Date de naissance','Jour','Mois','Année','Genre','Homme','Femme','Je préfère ne pas répondre','Profil enregistré ✓'],
'de':['Geburtsdatum','Tag','Monat','Jahr','Geschlecht','Männlich','Weiblich','Keine Angabe','Profil erfolgreich gespeichert ✓'],
'it':['Data di nascita','Giorno','Mese','Anno','Genere','Maschio','Femmina','Preferisco non rispondere','Profilo salvato ✓'],
'pt':['Data de nascimento','Dia','Mês','Ano','Gênero','Masculino','Feminino','Prefiro não responder','Perfil salvo ✓'],
'tr':['Doğum tarihi','Gün','Ay','Yıl','Cinsiyet','Erkek','Kadın','Yanıtlamak istemiyorum','Profil kaydedildi ✓'],
'ru':['Дата рождения','День','Месяц','Год','Пол','Мужской','Женский','Предпочитаю не отвечать','Профиль сохранён ✓'],
'zh':['出生日期','日','月','年','性别','男','女','不愿回答','个人资料已保存 ✓'],
'ja':['生年月日','日','月','年','性別','男性','女性','回答しない','プロフィールを保存しました ✓'],
'ko':['생년월일','일','월','년','성별','남성','여성','응답하지 않음','프로필이 저장되었습니다 ✓'],
'ur':['تاریخ پیدائش','دن','مہینہ','سال','جنس','مرد','عورت','جواب نہیں دینا چاہتا','پروفائل محفوظ ہوگیا ✓'],
'fa':['تاریخ تولد','روز','ماه','سال','جنسیت','مرد','زن','ترجیح می‌دهم پاسخ ندهم','پروفایل ذخیره شد ✓'],
'id':['Tanggal lahir','Hari','Bulan','Tahun','Jenis kelamin','Pria','Wanita','Memilih tidak menjawab','Profil berhasil disimpan ✓'],
'th':['วันเกิด','วัน','เดือน','ปี','เพศ','ชาย','หญิง','ไม่ประสงค์ตอบ','บันทึกโปรไฟล์แล้ว ✓'],
'hi':['जन्म तिथि','दिन','महीना','वर्ष','लिंग','पुरुष','महिला','उत्तर नहीं देना चाहता','प्रोफ़ाइल सहेजी गई ✓']
};
const _extraKeys=['birthDate','day','month','year','gender','male','female','prefer','saved'];
String _extraText(String code,String key){final i=_extraKeys.indexOf(key);final a=_extra[code]??_extra['en']!;return i<0?key:a[i];}

String _countryText(String code,String country){if(code=='en')return country;return _countryNames[code]?[country]??country;}
const Map<String,Map<String,String>> _countryNames={
'ar':{"Afghanistan":"أفغانستان","Albania":"ألبانيا","Algeria":"الجزائر","Andorra":"أندورا","Angola":"أنغولا","Antigua and Barbuda":"أنتيغوا وباربودا","Argentina":"الأرجنتين","Armenia":"أرمينيا","Australia":"أستراليا","Austria":"النمسا","Azerbaijan":"أذربيجان","Bahamas":"جزر البهاما","Bahrain":"البحرين","Bangladesh":"بنغلاديش","Barbados":"بربادوس","Belarus":"بيلاروس","Belgium":"بلجيكا","Belize":"بليز","Benin":"بنين","Bhutan":"بوتان","Bolivia":"بوليفيا","Bosnia and Herzegovina":"البوسنة والهرسك","Botswana":"بوتسوانا","Brazil":"البرازيل","Brunei":"بروناي","Bulgaria":"بلغاريا","Burkina Faso":"بوركينا فاسو","Burundi":"بوروندي","Cabo Verde":"الرأس الأخضر","Cambodia":"كمبوديا","Cameroon":"الكاميرون","Canada":"كندا","Central African Republic":"جمهورية أفريقيا الوسطى","Chad":"تشاد","Chile":"تشيلي","China":"الصين","Colombia":"كولومبيا","Comoros":"جزر القمر","Congo":"الكونغو","Costa Rica":"كوستاريكا","Croatia":"كرواتيا","Cuba":"كوبا","Cyprus":"قبرص","Czechia":"التشيك","Denmark":"الدنمارك","Djibouti":"جيبوتي","Dominica":"دومينيكا","Dominican Republic":"جمهورية الدومينيكان","Ecuador":"الإكوادور","Egypt":"مصر","El Salvador":"السلفادور","Equatorial Guinea":"غينيا الاستوائية","Eritrea":"إريتريا","Estonia":"إستونيا","Eswatini":"إسواتيني","Ethiopia":"إثيوبيا","Fiji":"فيجي","Finland":"فنلندا","France":"فرنسا","Gabon":"الغابون","Gambia":"غامبيا","Georgia":"جورجيا","Germany":"ألمانيا","Ghana":"غانا","Greece":"اليونان","Grenada":"غرينادا","Guatemala":"غواتيمالا","Guinea":"غينيا","Guinea-Bissau":"غينيا بيساو","Guyana":"غيانا","Haiti":"هايتي","Honduras":"هندوراس","Hungary":"المجر","Iceland":"آيسلندا","India":"الهند","Indonesia":"إندونيسيا","Iran":"إيران","Iraq":"العراق","Ireland":"أيرلندا","Italy":"إيطاليا","Ivory Coast":"ساحل العاج","Jamaica":"جامايكا","Japan":"اليابان","Jordan":"الأردن","Kazakhstan":"كازاخستان","Kenya":"كينيا","Kiribati":"كيريباتي","Kuwait":"الكويت","Kyrgyzstan":"قيرغيزستان","Laos":"لاوس","Latvia":"لاتفيا","Lebanon":"لبنان","Lesotho":"ليسوتو","Liberia":"ليبيريا","Libya":"ليبيا","Liechtenstein":"ليختنشتاين","Lithuania":"ليتوانيا","Luxembourg":"لوكسمبورغ","Madagascar":"مدغشقر","Malawi":"مالاوي","Malaysia":"ماليزيا","Maldives":"المالديف","Mali":"مالي","Malta":"مالطا","Marshall Islands":"جزر مارشال","Mauritania":"موريتانيا","Mauritius":"موريشيوس","Mexico":"المكسيك","Micronesia":"ميكرونيزيا","Moldova":"مولدوفا","Monaco":"موناكو","Mongolia":"منغوليا","Montenegro":"الجبل الأسود","Morocco":"المغرب","Mozambique":"موزمبيق","Myanmar":"ميانمار","Namibia":"ناميبيا","Nauru":"ناورو","Nepal":"نيبال","Netherlands":"هولندا","New Zealand":"نيوزيلندا","Nicaragua":"نيكاراغوا","Niger":"النيجر","Nigeria":"نيجيريا","North Korea":"كوريا الشمالية","North Macedonia":"مقدونيا الشمالية","Norway":"النرويج","Oman":"عُمان","Pakistan":"باكستان","Palau":"بالاو","Palestine":"فلسطين","Panama":"بنما","Papua New Guinea":"بابوا غينيا الجديدة","Paraguay":"باراغواي","Peru":"بيرو","Philippines":"الفلبين","Poland":"بولندا","Portugal":"البرتغال","Qatar":"قطر","Romania":"رومانيا","Russia":"روسيا","Rwanda":"رواندا","Saint Kitts and Nevis":"سانت كيتس ونيفيس","Saint Lucia":"سانت لوسيا","Saint Vincent and the Grenadines":"سانت فنسنت والغرينادين","Samoa":"ساموا","San Marino":"سان مارينو","Sao Tome and Principe":"ساو تومي وبرينسيب","Saudi Arabia":"السعودية","Senegal":"السنغال","Serbia":"صربيا","Seychelles":"سيشل","Sierra Leone":"سيراليون","Singapore":"سنغافورة","Slovakia":"سلوفاكيا","Slovenia":"سلوفينيا","Solomon Islands":"جزر سليمان","Somalia":"الصومال","South Africa":"جنوب أفريقيا","South Korea":"كوريا الجنوبية","South Sudan":"جنوب السودان","Spain":"إسبانيا","Sri Lanka":"سريلانكا","Sudan":"السودان","Suriname":"سورينام","Sweden":"السويد","Switzerland":"سويسرا","Syria":"سوريا","Taiwan":"تايوان","Tajikistan":"طاجيكستان","Tanzania":"تنزانيا","Thailand":"تايلاند","Timor-Leste":"تيمور الشرقية","Togo":"توغو","Tonga":"تونغا","Trinidad and Tobago":"ترينيداد وتوباغو","Tunisia":"تونس","Turkey":"تركيا","Turkmenistan":"تركمانستان","Tuvalu":"توفالو","Uganda":"أوغندا","Ukraine":"أوكرانيا","United Arab Emirates":"الإمارات العربية المتحدة","United Kingdom":"المملكة المتحدة","United States":"الولايات المتحدة","Uruguay":"أوروغواي","Uzbekistan":"أوزبكستان","Vanuatu":"فانواتو","Vatican City":"الفاتيكان","Venezuela":"فنزويلا","Vietnam":"فيتنام","Yemen":"اليمن","Zambia":"زامبيا","Zimbabwe":"زيمبابوي"},
'fr':{"Yemen":"Yémen","Saudi Arabia":"Arabie saoudite","United Arab Emirates":"Émirats arabes unis","Egypt":"Égypte","Germany":"Allemagne","Spain":"Espagne","Italy":"Italie","China":"Chine","Japan":"Japon","South Korea":"Corée du Sud","United States":"États-Unis","United Kingdom":"Royaume-Uni"},
'es':{"Yemen":"Yemen","Saudi Arabia":"Arabia Saudita","United Arab Emirates":"Emiratos Árabes Unidos","Egypt":"Egipto","Germany":"Alemania","France":"Francia","United States":"Estados Unidos","United Kingdom":"Reino Unido"},
'de':{"Yemen":"Jemen","Saudi Arabia":"Saudi-Arabien","United Arab Emirates":"Vereinigte Arabische Emirate","Egypt":"Ägypten","France":"Frankreich","United States":"Vereinigte Staaten","United Kingdom":"Vereinigtes Königreich"},
'it':{"Yemen":"Yemen","Saudi Arabia":"Arabia Saudita","United Arab Emirates":"Emirati Arabi Uniti","Egypt":"Egitto","Germany":"Germania","United States":"Stati Uniti","United Kingdom":"Regno Unito"},
'pt':{"Yemen":"Iêmen","Saudi Arabia":"Arábia Saudita","United Arab Emirates":"Emirados Árabes Unidos","Egypt":"Egito","Germany":"Alemanha","United States":"Estados Unidos","United Kingdom":"Reino Unido"},
'tr':{"Yemen":"Yemen","Saudi Arabia":"Suudi Arabistan","United Arab Emirates":"Birleşik Arap Emirlikleri","Egypt":"Mısır","Germany":"Almanya","United States":"Amerika Birleşik Devletleri","United Kingdom":"Birleşik Krallık"},
'ru':{"Yemen":"Йемен","Saudi Arabia":"Саудовская Аравия","United Arab Emirates":"ОАЭ","Egypt":"Египет","Germany":"Германия","United States":"США","United Kingdom":"Великобритания"},
'zh':{"Yemen":"也门","Saudi Arabia":"沙特阿拉伯","United Arab Emirates":"阿拉伯联合酋长国","Egypt":"埃及","Germany":"德国","France":"法国","United States":"美国","United Kingdom":"英国"},
'ja':{"Yemen":"イエメン","Saudi Arabia":"サウジアラビア","United Arab Emirates":"アラブ首長国連邦","Egypt":"エジプト","Germany":"ドイツ","United States":"アメリカ合衆国","United Kingdom":"イギリス"},
'ko':{"Yemen":"예멘","Saudi Arabia":"사우디아라비아","United Arab Emirates":"아랍에미리트","Egypt":"이집트","Germany":"독일","United States":"미국","United Kingdom":"영국"},
'ur':{"Yemen":"یمن","Saudi Arabia":"سعودی عرب","United Arab Emirates":"متحدہ عرب امارات","Egypt":"مصر","Germany":"جرمنی","United States":"امریکہ","United Kingdom":"برطانیہ"},
'fa':{"Yemen":"یمن","Saudi Arabia":"عربستان سعودی","United Arab Emirates":"امارات متحده عربی","Egypt":"مصر","Germany":"آلمان","United States":"ایالات متحده","United Kingdom":"بریتانیا"},
'id':{"Yemen":"Yaman","Saudi Arabia":"Arab Saudi","United Arab Emirates":"Uni Emirat Arab","Egypt":"Mesir","Germany":"Jerman","United States":"Amerika Serikat","United Kingdom":"Britania Raya"},
'th':{"Yemen":"เยเมน","Saudi Arabia":"ซาอุดีอาระเบีย","United Arab Emirates":"สหรัฐอาหรับเอมิเรตส์","Egypt":"อียิปต์","Germany":"เยอรมนี","United States":"สหรัฐอเมริกา","United Kingdom":"สหราชอาณาจักร"},
'hi':{"Yemen":"यमन","Saudi Arabia":"सऊदी अरब","United Arab Emirates":"संयुक्त अरब अमीरात","Egypt":"मिस्र","Germany":"जर्मनी","United States":"संयुक्त राज्य अमेरिका","United Kingdom":"यूनाइटेड किंगडम"},
};

const _languageNames=<String,Map<String,String>>{
'ar':{'Arabic':'العربية','Chinese':'الصينية','English':'الإنجليزية','French':'الفرنسية','German':'الألمانية','Hindi':'الهندية','Indonesian':'الإندونيسية','Italian':'الإيطالية','Japanese':'اليابانية','Korean':'الكورية','Persian':'الفارسية','Portuguese':'البرتغالية','Russian':'الروسية','Spanish':'الإسبانية','Thai':'التايلاندية','Turkish':'التركية','Urdu':'الأردية'},
'fr':{'Arabic':'Arabe','Chinese':'Chinois','English':'Anglais','French':'Français','German':'Allemand','Hindi':'Hindi','Indonesian':'Indonésien','Italian':'Italien','Japanese':'Japonais','Korean':'Coréen','Persian':'Persan','Portuguese':'Portugais','Russian':'Russe','Spanish':'Espagnol','Thai':'Thaï','Turkish':'Turc','Urdu':'Ourdou'},
'es':{'Arabic':'Árabe','Chinese':'Chino','English':'Inglés','French':'Francés','German':'Alemán','Hindi':'Hindi','Indonesian':'Indonesio','Italian':'Italiano','Japanese':'Japonés','Korean':'Coreano','Persian':'Persa','Portuguese':'Portugués','Russian':'Ruso','Spanish':'Español','Thai':'Tailandés','Turkish':'Turco','Urdu':'Urdu'},
'de':{'Arabic':'Arabisch','Chinese':'Chinesisch','English':'Englisch','French':'Französisch','German':'Deutsch','Hindi':'Hindi','Indonesian':'Indonesisch','Italian':'Italienisch','Japanese':'Japanisch','Korean':'Koreanisch','Persian':'Persisch','Portuguese':'Portugiesisch','Russian':'Russisch','Spanish':'Spanisch','Thai':'Thailändisch','Turkish':'Türkisch','Urdu':'Urdu'},
'it':{'Arabic':'Arabo','Chinese':'Cinese','English':'Inglese','French':'Francese','German':'Tedesco','Hindi':'Hindi','Indonesian':'Indonesiano','Italian':'Italiano','Japanese':'Giapponese','Korean':'Coreano','Persian':'Persiano','Portuguese':'Portoghese','Russian':'Russo','Spanish':'Spagnolo','Thai':'Thailandese','Turkish':'Turco','Urdu':'Urdu'},
'pt':{'Arabic':'Árabe','Chinese':'Chinês','English':'Inglês','French':'Francês','German':'Alemão','Hindi':'Hindi','Indonesian':'Indonésio','Italian':'Italiano','Japanese':'Japonês','Korean':'Coreano','Persian':'Persa','Portuguese':'Português','Russian':'Russo','Spanish':'Espanhol','Thai':'Tailandês','Turkish':'Turco','Urdu':'Urdu'},
'tr':{'Arabic':'Arapça','Chinese':'Çince','English':'İngilizce','French':'Fransızca','German':'Almanca','Hindi':'Hintçe','Indonesian':'Endonezce','Italian':'İtalyanca','Japanese':'Japonca','Korean':'Korece','Persian':'Farsça','Portuguese':'Portekizce','Russian':'Rusça','Spanish':'İspanyolca','Thai':'Tayca','Turkish':'Türkçe','Urdu':'Urduca'},
'ru':{'Arabic':'Арабский','Chinese':'Китайский','English':'Английский','French':'Французский','German':'Немецкий','Hindi':'Хинди','Indonesian':'Индонезийский','Italian':'Итальянский','Japanese':'Японский','Korean':'Корейский','Persian':'Персидский','Portuguese':'Португальский','Russian':'Русский','Spanish':'Испанский','Thai':'Тайский','Turkish':'Турецкий','Urdu':'Урду'},
'zh':{'Arabic':'阿拉伯语','Chinese':'中文','English':'英语','French':'法语','German':'德语','Hindi':'印地语','Indonesian':'印度尼西亚语','Italian':'意大利语','Japanese':'日语','Korean':'韩语','Persian':'波斯语','Portuguese':'葡萄牙语','Russian':'俄语','Spanish':'西班牙语','Thai':'泰语','Turkish':'土耳其语','Urdu':'乌尔都语'},
'ja':{'Arabic':'アラビア語','Chinese':'中国語','English':'英語','French':'フランス語','German':'ドイツ語','Hindi':'ヒンディー語','Indonesian':'インドネシア語','Italian':'イタリア語','Japanese':'日本語','Korean':'韓国語','Persian':'ペルシア語','Portuguese':'ポルトガル語','Russian':'ロシア語','Spanish':'スペイン語','Thai':'タイ語','Turkish':'トルコ語','Urdu':'ウルドゥー語'},
'ko':{'Arabic':'아랍어','Chinese':'중국어','English':'영어','French':'프랑스어','German':'독일어','Hindi':'힌디어','Indonesian':'인도네시아어','Italian':'이탈리아어','Japanese':'일본어','Korean':'한국어','Persian':'페르시아어','Portuguese':'포르투갈어','Russian':'러시아어','Spanish':'스페인어','Thai':'태국어','Turkish':'터키어','Urdu':'우르두어'},
'ur':{'Arabic':'عربی','Chinese':'چینی','English':'انگریزی','French':'فرانسیسی','German':'جرمن','Hindi':'ہندی','Indonesian':'انڈونیشیائی','Italian':'اطالوی','Japanese':'جاپانی','Korean':'کوریائی','Persian':'فارسی','Portuguese':'پرتگالی','Russian':'روسی','Spanish':'ہسپانوی','Thai':'تھائی','Turkish':'ترکی','Urdu':'اردو'},
'fa':{'Arabic':'عربی','Chinese':'چینی','English':'انگلیسی','French':'فرانسوی','German':'آلمانی','Hindi':'هندی','Indonesian':'اندونزیایی','Italian':'ایتالیایی','Japanese':'ژاپنی','Korean':'کره‌ای','Persian':'فارسی','Portuguese':'پرتغالی','Russian':'روسی','Spanish':'اسپانیایی','Thai':'تایلندی','Turkish':'ترکی','Urdu':'اردو'},
'id':{'Arabic':'Arab','Chinese':'Mandarin','English':'Inggris','French':'Prancis','German':'Jerman','Hindi':'Hindi','Indonesian':'Indonesia','Italian':'Italia','Japanese':'Jepang','Korean':'Korea','Persian':'Persia','Portuguese':'Portugis','Russian':'Rusia','Spanish':'Spanyol','Thai':'Thai','Turkish':'Turki','Urdu':'Urdu'},
'th':{'Arabic':'อาหรับ','Chinese':'จีน','English':'อังกฤษ','French':'ฝรั่งเศส','German':'เยอรมัน','Hindi':'ฮินดี','Indonesian':'อินโดนีเซีย','Italian':'อิตาลี','Japanese':'ญี่ปุ่น','Korean':'เกาหลี','Persian':'เปอร์เซีย','Portuguese':'โปรตุเกส','Russian':'รัสเซีย','Spanish':'สเปน','Thai':'ไทย','Turkish':'ตุรกี','Urdu':'อูรดู'},
'hi':{'Arabic':'अरबी','Chinese':'चीनी','English':'अंग्रेज़ी','French':'फ़्रेंच','German':'जर्मन','Hindi':'हिंदी','Indonesian':'इंडोनेशियाई','Italian':'इतालवी','Japanese':'जापानी','Korean':'कोरियाई','Persian':'फ़ारसी','Portuguese':'पुर्तगाली','Russian':'रूसी','Spanish':'स्पेनिश','Thai':'थाई','Turkish':'तुर्की','Urdu':'उर्दू'},
};
String _languageText(String code,String value)=>_languageNames[code]?[value]??value;
