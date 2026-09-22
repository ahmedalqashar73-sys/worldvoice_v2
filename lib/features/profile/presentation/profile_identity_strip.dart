import 'package:flutter/material.dart';

class ProfileIdentityStrip extends StatelessWidget {
  const ProfileIdentityStrip({
    required this.code,
    this.country,
    this.gender,
    this.birthDate,
    this.nativeLanguage,
    super.key,
  });

  final String code;
  final String? country;
  final String? gender;
  final DateTime? birthDate;
  final String? nativeLanguage;

  @override
  Widget build(BuildContext context) {
    final age = birthDate == null ? null : _ageFromBirthDate(birthDate!);
    final items = <Widget>[];

    if (country?.isNotEmpty == true) {
      items.add(
        _IdentityChip(
          leadingText: countryFlag(country!),
          text: country!,
        ),
      );
    }

    if (age != null && age >= 0) {
      items.add(
        _IdentityChip(
          icon: Icons.cake_outlined,
          text: code == 'ar' ? '$age سنة' : '$age',
        ),
      );
    }

    if (gender == 'male') {
      items.add(
        _IdentityChip(
          icon: Icons.male_rounded,
          text: code == 'ar'
              ? 'ذكر'
              : code == 'es'
                  ? 'Hombre'
                  : 'Male',
        ),
      );
    } else if (gender == 'female') {
      items.add(
        _IdentityChip(
          icon: Icons.female_rounded,
          text: code == 'ar'
              ? 'أنثى'
              : code == 'es'
                  ? 'Mujer'
                  : 'Female',
        ),
      );
    }

    if (nativeLanguage?.isNotEmpty == true) {
      items.add(
        _IdentityChip(
          icon: Icons.translate_rounded,
          text: nativeLanguage!,
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items,
      ),
    );
  }
}

class _IdentityChip extends StatelessWidget {
  const _IdentityChip({
    required this.text,
    this.icon,
    this.leadingText,
  });

  final String text;
  final IconData? icon;
  final String? leadingText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingText != null) ...[
            Text(leadingText!, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 17, color: colors.primary),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

int _ageFromBirthDate(DateTime birthDate) {
  final now = DateTime.now();
  var age = now.year - birthDate.year;
  final birthdayNotReached =
      now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day);
  if (birthdayNotReached) age--;
  return age;
}

String countryFlag(String country) {
  const codes = <String, String>{
    'Afghanistan':'AF','Albania':'AL','Algeria':'DZ','Andorra':'AD',
    'Angola':'AO','Antigua and Barbuda':'AG','Argentina':'AR','Armenia':'AM',
    'Australia':'AU','Austria':'AT','Azerbaijan':'AZ','Bahamas':'BS',
    'Bahrain':'BH','Bangladesh':'BD','Barbados':'BB','Belarus':'BY',
    'Belgium':'BE','Belize':'BZ','Benin':'BJ','Bhutan':'BT','Bolivia':'BO',
    'Bosnia and Herzegovina':'BA','Botswana':'BW','Brazil':'BR','Brunei':'BN',
    'Bulgaria':'BG','Burkina Faso':'BF','Burundi':'BI','Cabo Verde':'CV',
    'Cambodia':'KH','Cameroon':'CM','Canada':'CA',
    'Central African Republic':'CF','Chad':'TD','Chile':'CL','China':'CN',
    'Colombia':'CO','Comoros':'KM','Congo':'CG','Costa Rica':'CR',
    'Croatia':'HR','Cuba':'CU','Cyprus':'CY','Czechia':'CZ','Denmark':'DK',
    'Djibouti':'DJ','Dominica':'DM','Dominican Republic':'DO','Ecuador':'EC',
    'Egypt':'EG','El Salvador':'SV','Equatorial Guinea':'GQ','Eritrea':'ER',
    'Estonia':'EE','Eswatini':'SZ','Ethiopia':'ET','Fiji':'FJ','Finland':'FI',
    'France':'FR','Gabon':'GA','Gambia':'GM','Georgia':'GE','Germany':'DE',
    'Ghana':'GH','Greece':'GR','Grenada':'GD','Guatemala':'GT','Guinea':'GN',
    'Guinea-Bissau':'GW','Guyana':'GY','Haiti':'HT','Honduras':'HN',
    'Hungary':'HU','Iceland':'IS','India':'IN','Indonesia':'ID','Iran':'IR',
    'Iraq':'IQ','Ireland':'IE','Italy':'IT','Ivory Coast':'CI','Jamaica':'JM',
    'Japan':'JP','Jordan':'JO','Kazakhstan':'KZ','Kenya':'KE','Kiribati':'KI',
    'Kuwait':'KW','Kyrgyzstan':'KG','Laos':'LA','Latvia':'LV','Lebanon':'LB',
    'Lesotho':'LS','Liberia':'LR','Libya':'LY','Liechtenstein':'LI',
    'Lithuania':'LT','Luxembourg':'LU','Madagascar':'MG','Malawi':'MW',
    'Malaysia':'MY','Maldives':'MV','Mali':'ML','Malta':'MT',
    'Marshall Islands':'MH','Mauritania':'MR','Mauritius':'MU','Mexico':'MX',
    'Micronesia':'FM','Moldova':'MD','Monaco':'MC','Mongolia':'MN',
    'Montenegro':'ME','Morocco':'MA','Mozambique':'MZ','Myanmar':'MM',
    'Namibia':'NA','Nauru':'NR','Nepal':'NP','Netherlands':'NL',
    'New Zealand':'NZ','Nicaragua':'NI','Niger':'NE','Nigeria':'NG',
    'North Korea':'KP','North Macedonia':'MK','Norway':'NO','Oman':'OM',
    'Pakistan':'PK','Palau':'PW','Palestine':'PS','Panama':'PA',
    'Papua New Guinea':'PG','Paraguay':'PY','Peru':'PE','Philippines':'PH',
    'Poland':'PL','Portugal':'PT','Qatar':'QA','Romania':'RO','Russia':'RU',
    'Rwanda':'RW','Saint Kitts and Nevis':'KN','Saint Lucia':'LC',
    'Saint Vincent and the Grenadines':'VC','Samoa':'WS','San Marino':'SM',
    'Sao Tome and Principe':'ST','Saudi Arabia':'SA','Senegal':'SN',
    'Serbia':'RS','Seychelles':'SC','Sierra Leone':'SL','Singapore':'SG',
    'Slovakia':'SK','Slovenia':'SI','Solomon Islands':'SB','Somalia':'SO',
    'South Africa':'ZA','South Korea':'KR','South Sudan':'SS','Spain':'ES',
    'Sri Lanka':'LK','Sudan':'SD','Suriname':'SR','Sweden':'SE',
    'Switzerland':'CH','Syria':'SY','Tajikistan':'TJ','Tanzania':'TZ',
    'Thailand':'TH','Timor-Leste':'TL','Togo':'TG','Tonga':'TO',
    'Trinidad and Tobago':'TT','Tunisia':'TN','Turkey':'TR',
    'Turkmenistan':'TM','Tuvalu':'TV','Uganda':'UG','Ukraine':'UA',
    'United Arab Emirates':'AE','United Kingdom':'GB','United States':'US',
    'Uruguay':'UY','Uzbekistan':'UZ','Vanuatu':'VU','Vatican City':'VA',
    'Venezuela':'VE','Vietnam':'VN','Yemen':'YE','Zambia':'ZM','Zimbabwe':'ZW',
  };

  final iso = codes[country];
  if (iso == null) return '🌐';
  return String.fromCharCodes(
    iso.codeUnits.map((unit) => 0x1F1E6 + unit - 65),
  );
}
