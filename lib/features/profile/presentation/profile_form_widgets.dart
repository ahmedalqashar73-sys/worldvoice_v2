import 'package:flutter/material.dart';

class ProfileTextField extends StatelessWidget {
  const ProfileTextField(
    this.controller,
    this.label,
    this.icon, {
    this.lines = 1,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
      ),
    );
  }
}

class ProfilePickerTile extends StatelessWidget {
  const ProfilePickerTile(
    this.icon,
    this.title,
    this.subtitle,
    this.onTap, {
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 5,
        ),
        leading: CircleAvatar(
          radius: 17,
          child: Icon(icon, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }
}

class ProfileBirthFields extends StatefulWidget {
  const ProfileBirthFields({
    required this.value,
    required this.title,
    required this.dayLabel,
    required this.monthLabel,
    required this.yearLabel,
    required this.onChanged,
    super.key,
  });

  final DateTime? value;
  final String title;
  final String dayLabel;
  final String monthLabel;
  final String yearLabel;
  final ValueChanged<DateTime?> onChanged;

  @override
  State<ProfileBirthFields> createState() => _ProfileBirthFieldsState();
}

class _ProfileBirthFieldsState extends State<ProfileBirthFields> {
  late final day =
      TextEditingController(text: widget.value?.day.toString() ?? '');
  late final month =
      TextEditingController(text: widget.value?.month.toString() ?? '');
  late final year =
      TextEditingController(text: widget.value?.year.toString() ?? '');

  @override
  void didUpdateWidget(covariant ProfileBirthFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      day.text = widget.value?.day.toString() ?? '';
      month.text = widget.value?.month.toString() ?? '';
      year.text = widget.value?.year.toString() ?? '';
    }
  }

  void _update() {
    final d = int.tryParse(day.text);
    final m = int.tryParse(month.text);
    final y = int.tryParse(year.text);
    if (d == null || m == null || y == null) {
      widget.onChanged(null);
      return;
    }

    try {
      final value = DateTime(y, m, d);
      final valid = value.year == y &&
          value.month == m &&
          value.day == d &&
          value.isBefore(DateTime.now());
      widget.onChanged(valid ? value : null);
    } catch (_) {
      widget.onChanged(null);
    }
  }

  @override
  void dispose() {
    day.dispose();
    month.dispose();
    year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: int.tryParse(day.text),
                decoration: InputDecoration(labelText: widget.dayLabel),
                items: List.generate(
                  31,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  day.text = value?.toString() ?? '';
                  _update();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: int.tryParse(month.text),
                decoration: InputDecoration(labelText: widget.monthLabel),
                items: List.generate(
                  12,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  month.text = value?.toString() ?? '';
                  _update();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: int.tryParse(year.text),
                decoration: InputDecoration(labelText: widget.yearLabel),
                items: List.generate(
                  DateTime.now().year - 1900,
                  (index) {
                    final value = DateTime.now().year - index;
                    return DropdownMenuItem(
                      value: value,
                      child: Text('$value'),
                    );
                  },
                ),
                onChanged: (value) {
                  year.text = value?.toString() ?? '';
                  _update();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class ProfileGenderPicker extends StatelessWidget {
  const ProfileGenderPicker({
    required this.value,
    required this.title,
    required this.maleLabel,
    required this.femaleLabel,
    required this.preferNotToSayLabel,
    required this.onChanged,
    super.key,
  });

  final String? value;
  final String title;
  final String maleLabel;
  final String femaleLabel;
  final String preferNotToSayLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            IconButton.filledTonal(
              onPressed: () => onChanged('male'),
              tooltip: maleLabel,
              icon: const Icon(
                Icons.male_rounded,
                color: Colors.blue,
                size: 25,
              ),
              style: IconButton.styleFrom(
                side: value == 'male' ? const BorderSide(width: 2) : null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => onChanged('female'),
              tooltip: femaleLabel,
              icon: const Icon(
                Icons.female_rounded,
                color: Colors.pink,
                size: 25,
              ),
              style: IconButton.styleFrom(
                side: value == 'female' ? const BorderSide(width: 2) : null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: () => onChanged('prefer_not_to_say'),
              tooltip: preferNotToSayLabel,
              icon: const Icon(Icons.remove_rounded, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
