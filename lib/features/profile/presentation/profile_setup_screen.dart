import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({required this.localeController, super.key});
  final LocaleController localeController;
  @override State<ProfileSetupScreen> createState()=>_ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final name=TextEditingController(), username=TextEditingController(), bio=TextEditingController(),
      city=TextEditingController(), profession=TextEditingController(), travel=TextEditingController(),
      goals=TextEditingController(), interests=TextEditingController();
  bool? usernameAvailable; bool saving=false; bool cityVisible=true;
  String? country, gender, nativeLanguage, learningLanguage;
  String languageLevel='beginner'; DateTime? birthDate;

  static const languages=<String>['Arabic','Chinese','English','French','German','Hindi','Indonesian','Italian','Japanese','Korean','Persian','Portuguese','Russian','Spanish','Thai','Turkish','Urdu'];
  static const countries = <String>[
    'Afghanistan','Albania','Algeria','Andorra','Angola','Antigua and Barbuda','Argentina','Armenia','Australia','Austria','Azerbaijan','Bahamas','Bahrain','Bangladesh','Barbados','Belarus','Belgium','Belize','Benin','Bhutan','Bolivia','Bosnia and Herzegovina','Botswana','Brazil','Brunei','Bulgaria','Burkina Faso','Burundi','Cabo Verde','Cambodia','Cameroon','Canada','Central African Republic','Chad','Chile','China','Colombia','Comoros','Congo','Costa Rica','Croatia','Cuba','Cyprus','Czechia','Denmark','Djibouti','Dominica','Dominican Republic','Ecuador','Egypt','El Salvador','Equatorial Guinea','Eritrea','Estonia','Eswatini','Ethiopia','Fiji','Finland','France','Gabon','Gambia','Georgia','Germany','Ghana','Greece','Grenada','Guatemala','Guinea','Guinea-Bissau','Guyana','Haiti','Honduras','Hungary','Iceland','India','Indonesia','Iran','Iraq','Ireland','Israel','Italy','Ivory Coast','Jamaica','Japan','Jordan','Kazakhstan','Kenya','Kiribati','Kuwait','Kyrgyzstan','Laos','Latvia','Lebanon','Lesotho','Liberia','Libya','Liechtenstein','Lithuania','Luxembourg','Madagascar','Malawi','Malaysia','Maldives','Mali','Malta','Marshall Islands','Mauritania','Mauritius','Mexico','Micronesia','Moldova','Monaco','Mongolia','Montenegro','Morocco','Mozambique','Myanmar','Namibia','Nauru','Nepal','Netherlands','New Zealand','Nicaragua','Niger','Nigeria','North Korea','North Macedonia','Norway','Oman','Pakistan','Palau','Palestine','Panama','Papua New Guinea','Paraguay','Peru','Philippines','Poland','Portugal','Qatar','Romania','Russia','Rwanda','Saint Kitts and Nevis','Saint Lucia','Saint Vincent and the Grenadines','Samoa','San Marino','Sao Tome and Principe','Saudi Arabia','Senegal','Serbia','Seychelles','Sierra Leone','Singapore','Slovakia','Slovenia','Solomon Islands','Somalia','South Africa','South Korea','South Sudan','Spain','Sri Lanka','Sudan','Suriname','Sweden','Switzerland','Syria','Tajikistan','Tanzania','Thailand','Timor-Leste','Togo','Tonga','Trinidad and Tobago','Tunisia','Turkey','Turkmenistan','Tuvalu','Uganda','Ukraine','United Arab Emirates','United Kingdom','United States','Uruguay','Uzbekistan','Vanuatu','Vatican City','Venezuela','Vietnam','Yemen','Zambia','Zimbabwe'
  ];

  String get normalizedUsername=>username.text.trim().toLowerCase().replaceFirst('@','');

  Future<String?> choose(String title,List<String> values) => showModalBottomSheet<String>(
    context:context,isScrollControlled:true,builder:(ctx)=>SafeArea(child:SizedBox(height:MediaQuery.sizeOf(ctx).height*.72,
    child:Column(children:[Padding(padding:const EdgeInsets.all(16),child:Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800))),
    Expanded(child:ListView.builder(itemCount:values.length,itemBuilder:(_,i)=>ListTile(title:Text(values[i]),onTap:()=>Navigator.pop(ctx,values[i]))))]))));

  Future<void> checkUsername() async {
    if(!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(normalizedUsername)){setState(()=>usernameAvailable=false);return;}
    final d=await FirebaseFirestore.instance.collection('usernames').doc(normalizedUsername).get();
    if(mounted)setState(()=>usernameAvailable=!d.exists||d.data()?['uid']==FirebaseAuth.instance.currentUser?.uid);
  }

  Future<void> pickBirthDate() async {
    final d=await showDatePicker(context:context,initialDate:DateTime(2000),firstDate:DateTime(1900),lastDate:DateTime.now());
    if(d!=null&&mounted)setState(()=>birthDate=d);
  }

  Future<void> saveProfile() async {
    final user=FirebaseAuth.instance.currentUser;
    if(user==null||name.text.trim().isEmpty||usernameAvailable!=true)return;
    setState(()=>saving=true); final db=FirebaseFirestore.instance;
    try{await db.runTransaction((tx)async{
      final handle=db.collection('usernames').doc(normalizedUsername); final old=await tx.get(handle);
      if(old.exists&&old.data()?['uid']!=user.uid)throw StateError('username-taken');
      tx.set(handle,{'uid':user.uid,'createdAt':FieldValue.serverTimestamp()});
      tx.set(db.collection('users').doc(user.uid),{
        'uid':user.uid,'email':user.email,'displayName':name.text.trim(),'username':normalizedUsername,
        'bio':bio.text.trim(),'country':country,'city':city.text.trim(),'cityVisible':cityVisible,'gender':gender,
        'birthDate':birthDate==null?null:Timestamp.fromDate(birthDate!),'nativeLanguage':nativeLanguage,
        'learningLanguages':learningLanguage==null?<String>[]:[learningLanguage],'languageLevel':languageLevel,
        'profession':profession.text.trim(),'travel':travel.text.trim(),'learningGoals':goals.text.trim(),
        'interests':interests.text.trim(),'profileCompleted':true,'followersCount':0,'followingCount':0,
        'isVip':false,'isPartner':false,'isVerified':false,'updatedAt':FieldValue.serverTimestamp(),
        'createdAt':FieldValue.serverTimestamp(),
      },SetOptions(merge:true));
    });
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor:Color(0xFF159B62),content:Text('تم حفظ البروفايل بنجاح ✓',style:TextStyle(color:Colors.white))));
    }finally{if(mounted)setState(()=>saving=false);}
  }

  @override void dispose(){for(final c in [name,username,bio,city,profession,travel,goals,interests]){c.dispose();}super.dispose();}

  @override Widget build(BuildContext context){
    final rtl=const {'ar','ur','fa'}.contains(widget.localeController.locale?.languageCode); final cs=Theme.of(context).colorScheme;
    String genderLabel=gender=='male'?(rtl?'ذكر':'Male'):gender=='female'?(rtl?'أنثى':'Female'):gender=='prefer_not_to_say'?(rtl?'أفضل عدم الإجابة':'Prefer not to say'):(rtl?'اختر الجنس':'Choose gender');
    return Directionality(textDirection:rtl?TextDirection.rtl:TextDirection.ltr,child:Scaffold(body:SafeArea(child:ListView(
      padding:const EdgeInsets.fromLTRB(18,16,18,36),children:[
      Text(rtl?'أنشئ هويتك في WorldVoice':'Create your WorldVoice identity',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),
      const SizedBox(height:18),
      Container(height:150,decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),gradient:LinearGradient(colors:[cs.primary.withValues(alpha:.75),cs.tertiary.withValues(alpha:.45)])),
        child:Stack(children:[const Center(child:Icon(Icons.landscape_rounded,size:42)),Positioned(top:8,left:8,child:IconButton.filledTonal(onPressed:(){},icon:const Icon(Icons.wallpaper_rounded,size:18)))])),
      Transform.translate(offset:const Offset(0,-28),child:Center(child:Container(width:104,height:104,padding:const EdgeInsets.all(3),decoration:BoxDecoration(shape:BoxShape.circle,color:cs.surface),
        child:CircleAvatar(backgroundColor:cs.surfaceContainerHighest,child:IconButton(onPressed:(){},icon:const Icon(Icons.add_a_photo_rounded,size:26)))))),
      _Field(name,rtl?'الاسم':'Name',Icons.badge_outlined),const SizedBox(height:10),
      TextField(controller:username,textDirection:TextDirection.ltr,onChanged:(_)=>setState(()=>usernameAvailable=null),decoration:InputDecoration(labelText:rtl?'اسم المستخدم الفريد':'Unique username',hintText:'@username',prefixIcon:const Icon(Icons.alternate_email_rounded,size:20),suffixIcon:IconButton(onPressed:checkUsername,icon:Icon(usernameAvailable==true?Icons.check_circle:usernameAvailable==false?Icons.cancel:Icons.search,size:20,color:usernameAvailable==true?Colors.green:null)))),
      const SizedBox(height:12),
      Stack(alignment:rtl?Alignment.bottomLeft:Alignment.bottomRight,children:[_Field(bio,rtl?'ماذا عنك؟':'About you',Icons.auto_awesome_rounded,lines:4),Padding(padding:const EdgeInsets.all(6),child:IconButton.filledTonal(onPressed:(){},icon:const Icon(Icons.mic_rounded,size:18)))]),
      const SizedBox(height:12),
      _Tile(Icons.public_rounded,rtl?'الدولة':'Country',country??(rtl?'اختر دولتك':'Choose country'),()async{final v=await choose(rtl?'الدولة':'Country',countries);if(v!=null)setState(()=>country=v);}),
      _Field(city,rtl?'المدينة':'City',Icons.location_city_outlined),SwitchListTile(value:cityVisible,onChanged:(v)=>setState(()=>cityVisible=v),title:Text(rtl?'إظهار المدينة في البروفايل':'Show city on profile'),secondary:const Icon(Icons.visibility_outlined,size:20)),
      _Tile(Icons.cake_outlined,rtl?'تاريخ الميلاد':'Date of birth',birthDate==null?(rtl?'اليوم / الشهر / السنة':'Day / month / year'):'${birthDate!.day} / ${birthDate!.month} / ${birthDate!.year}',pickBirthDate),
      _Tile(Icons.person_outline,rtl?'الجنس':'Gender',genderLabel,()async{final v=await choose(rtl?'الجنس':'Gender',[rtl?'ذكر':'Male',rtl?'أنثى':'Female',rtl?'أفضل عدم الإجابة':'Prefer not to say']);if(v!=null)setState(()=>gender=v==(rtl?'ذكر':'Male')?'male':v==(rtl?'أنثى':'Female')?'female':'prefer_not_to_say');}),
      _Tile(Icons.translate_rounded,rtl?'اللغة الأم':'Native language',nativeLanguage??(rtl?'اختر اللغة':'Choose language'),()async{final v=await choose(rtl?'اللغة الأم':'Native language',languages);if(v!=null)setState(()=>nativeLanguage=v);}),
      _Tile(Icons.language_rounded,rtl?'اللغة التي تتعلمها':'Learning language',learningLanguage??(rtl?'اختر اللغة':'Choose language'),()async{final v=await choose(rtl?'لغة التعلم':'Learning language',languages);if(v!=null)setState(()=>learningLanguage=v);}),
      _Tile(Icons.trending_up_rounded,rtl?'المستوى':'Level',languageLevel,()async{final v=await choose(rtl?'المستوى':'Level',['beginner','intermediate','advanced']);if(v!=null)setState(()=>languageLevel=v);}),
      _Field(interests,rtl?'الهوايات والاهتمامات':'Interests & hobbies',Icons.favorite_outline_rounded,lines:2),const SizedBox(height:10),
      _Field(goals,rtl?'أهداف التعلم':'Learning goals',Icons.track_changes_rounded,lines:2),const SizedBox(height:10),
      _Field(profession,rtl?'المهنة / الدراسة':'Profession / study',Icons.work_outline_rounded),const SizedBox(height:10),
      _Field(travel,rtl?'السفر':'Travel',Icons.flight_takeoff_rounded,lines:2),const SizedBox(height:22),
      SizedBox(height:58,child:FilledButton.icon(onPressed:saving?null:saveProfile,icon:saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.rocket_launch_rounded,size:20),label:Text(rtl?'إطلاق بروفايلي':'Launch my profile',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17))))
    ]))));
  }
}

class _Field extends StatelessWidget{
  const _Field(this.controller,this.label,this.icon,{this.lines=1}); final TextEditingController controller;final String label;final IconData icon;final int lines;
  @override Widget build(BuildContext context)=>TextField(controller:controller,maxLines:lines,decoration:InputDecoration(labelText:label,prefixIcon:Icon(icon,size:19)));
}
class _Tile extends StatelessWidget{
  const _Tile(this.icon,this.title,this.subtitle,this.tap);final IconData icon;final String title,subtitle;final VoidCallback tap;
  @override Widget build(BuildContext context)=>Card(margin:const EdgeInsets.only(bottom:10),child:ListTile(dense:true,contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:5),leading:CircleAvatar(radius:17,child:Icon(icon,size:18)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right_rounded,size:20),onTap:tap));
}
