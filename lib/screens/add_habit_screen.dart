import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../widgets/neu_box.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? editHabit;
  const AddHabitScreen({super.key, this.editHabit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _category = 'General';
  String _frequency = 'daily';
  int _target = 1;
  int _iconIndex = 0; // index into kIcons
  int _colorValue = 0xFF6C63FF;
  String? _reminderTime;
  late DateTime _startDate;

  static const _colors = [
    0xFF6C63FF, 0xFF4CAF50, 0xFFFF5722, 0xFF2196F3,
    0xFFE91E63, 0xFFFF9800, 0xFF9C27B0, 0xFF00BCD4,
    0xFF795548, 0xFF607D8B,
  ];

  bool get isEditing => widget.editHabit != null;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    if (isEditing) {
      final h = widget.editHabit!;
      _titleCtrl.text = h.title;
      _descCtrl.text = h.description;
      _category = h.category;
      _frequency = h.frequency;
      _target = h.target;
      _iconIndex =
          kIcons.indexWhere((ic) => ic.codePoint == h.icon);
      if (_iconIndex < 0) _iconIndex = 0;
      _colorValue = h.colorValue;
      _reminderTime = h.reminderTime;
      _startDate = h.startDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReminder() async {
    final initial = _reminderTime != null
        ? TimeOfDay(
            hour: int.parse(_reminderTime!.split(':')[0]),
            minute: int.parse(_reminderTime!.split(':')[1]),
          )
        : const TimeOfDay(hour: 8, minute: 0);
    final picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        _reminderTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final habit = Habit(
      id: isEditing ? widget.editHabit!.id : const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      frequency: _frequency,
      target: _frequency == 'weekly' ? _target : 1,
      startDate: _startDate,
      reminderTime: _reminderTime,
      colorValue: _colorValue,
      icon: kIcons[_iconIndex].codePoint,
      currentStreak: isEditing ? widget.editHabit!.currentStreak : 0,
      longestStreak: isEditing ? widget.editHabit!.longestStreak : 0,
      lastCompletedDate:
          isEditing ? widget.editHabit!.lastCompletedDate : null,
    );

    final provider = context.read<HabitProvider>();
    try {
      if (isEditing) {
        await provider.updateHabit(habit);
      } else {
        await provider.addHabit(habit);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save habit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Color(_colorValue);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Habit' : 'New Habit',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: NeuColors.textPrimary(isDark)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: NeuButton(
              onTap: _save,
              borderRadius: 10,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              depth: 4,
              child: Text(
                'Save',
                style: TextStyle(
                    color: NeuColors.primary,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Appearance ────────────────────────────────────────────────
            _SectionLabel('Appearance', isDark),
            const SizedBox(height: 12),
            Row(
              children: [
                NeuButton(
                  onTap: _showIconPicker,
                  borderRadius: 18,
                  padding: const EdgeInsets.all(18),
                  depth: 5,
                  child: Icon(kIcons[_iconIndex],
                      color: accentColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _colors.map((c) {
                      final selected = c == _colorValue;
                      return GestureDetector(
                        onTap: () => setState(() => _colorValue = c),
                        child: NeuBox(
                          style: selected
                              ? NeuStyle.pressed
                              : NeuStyle.raised,
                          borderRadius: 12,
                          depth: 4,
                          width: selected ? 34 : 30,
                          height: selected ? 34 : 30,
                          child: Center(
                            child: Container(
                              width: selected ? 20 : 16,
                              height: selected ? 20 : 16,
                              decoration: BoxDecoration(
                                color: Color(c),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Title ─────────────────────────────────────────────────────
            _SectionLabel('Title *', isDark),
            const SizedBox(height: 10),
            _NeuTextField(
              controller: _titleCtrl,
              hint: 'e.g. Drink 8 glasses of water',
              validator: (v) {
                final title = v?.trim() ?? '';
                if (title.isEmpty) return 'Title is required';

                final duplicate = provider.habits.any(
                  (h) =>
                      h.id != widget.editHabit?.id &&
                      h.title.trim().toLowerCase() == title.toLowerCase(),
                );
                if (duplicate) {
                  return 'A habit with this name already exists';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 18),

            // ── Description ───────────────────────────────────────────────
            _SectionLabel('Description (optional)', isDark),
            const SizedBox(height: 10),
            _NeuTextField(
              controller: _descCtrl,
              hint: 'Why this habit matters to you…',
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 18),

            // ── Category ──────────────────────────────────────────────────
            _SectionLabel('Category', isDark),
            const SizedBox(height: 10),
            _NeuDropdown<String>(
              value: _category,
              items: kCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 18),

            // ── Frequency ─────────────────────────────────────────────────
            _SectionLabel('Frequency', isDark),
            const SizedBox(height: 10),
            Row(
              children: [
                _FreqButton(
                  label: 'Daily',
                  icon: Icons.today_outlined,
                  isSelected: _frequency == 'daily',
                  onTap: () => setState(() => _frequency = 'daily'),
                ),
                const SizedBox(width: 12),
                _FreqButton(
                  label: 'Weekly',
                  icon: Icons.date_range_outlined,
                  isSelected: _frequency == 'weekly',
                  onTap: () => setState(() => _frequency = 'weekly'),
                ),
              ],
            ),
            if (_frequency == 'weekly') ...[
              const SizedBox(height: 18),
              _SectionLabel('Times per week', isDark),
              const SizedBox(height: 10),
              NeuBox(
                style: NeuStyle.raised,
                borderRadius: 14,
                depth: 5,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    NeuButton(
                      onTap:
                          _target > 1 ? () => setState(() => _target--) : null,
                      borderRadius: 10,
                      padding: const EdgeInsets.all(10),
                      depth: 4,
                      child: Icon(Icons.remove_rounded,
                          color: _target > 1
                              ? NeuColors.primary
                              : NeuColors.textSecondary(isDark)),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        '$_target',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: NeuColors.textPrimary(isDark),
                        ),
                      ),
                    ),
                    NeuButton(
                      onTap:
                          _target < 7 ? () => setState(() => _target++) : null,
                      borderRadius: 10,
                      padding: const EdgeInsets.all(10),
                      depth: 4,
                      child: Icon(Icons.add_rounded,
                          color: _target < 7
                              ? NeuColors.primary
                              : NeuColors.textSecondary(isDark)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            // ── Start Date ────────────────────────────────────────────────
            _SectionLabel('Start Date', isDark),
            const SizedBox(height: 10),
            NeuButton(
              onTap: _pickStartDate,
              borderRadius: 14,
              depth: 5,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      color: NeuColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    style: TextStyle(
                        color: NeuColors.textPrimary(isDark),
                        fontSize: 15),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right,
                      color: NeuColors.textSecondary(isDark)),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Reminder ──────────────────────────────────────────────────
            _SectionLabel('Daily Reminder', isDark),
            const SizedBox(height: 10),
            NeuButton(
              onTap: _pickReminder,
              borderRadius: 14,
              depth: 5,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    _reminderTime != null
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_none_outlined,
                    color: _reminderTime != null
                        ? NeuColors.primary
                        : NeuColors.textSecondary(isDark),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _reminderTime != null
                        ? 'At $_reminderTime'
                        : 'No reminder',
                    style: TextStyle(
                        color: NeuColors.textPrimary(isDark),
                        fontSize: 15),
                  ),
                  const Spacer(),
                  if (_reminderTime != null)
                    GestureDetector(
                      onTap: () => setState(() => _reminderTime = null),
                      child: Icon(Icons.close_rounded,
                          color: NeuColors.textSecondary(isDark),
                          size: 18),
                    )
                  else
                    Icon(Icons.chevron_right,
                        color: NeuColors.textSecondary(isDark)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Save Button ───────────────────────────────────────────────
            NeuButton(
              onTap: _save,
              borderRadius: 16,
              depth: 6,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  isEditing ? 'Save Changes' : 'Create Habit',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: NeuColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showIconPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pick an icon',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: NeuColors.textPrimary(isDark)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(kIcons.length, (i) {
                final selected = i == _iconIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _iconIndex = i);
                    Navigator.pop(context);
                  },
                  child: NeuBox(
                    style: selected ? NeuStyle.pressed : NeuStyle.raised,
                    borderRadius: 14,
                    depth: 4,
                    width: 52,
                    height: 52,
                    child: Icon(
                      kIcons[i],
                      color: selected
                          ? Color(_colorValue)
                          : NeuColors.textSecondary(isDark),
                      size: 24,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _FreqButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FreqButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: NeuButton(
        onTap: onTap,
        isActive: isSelected,
        borderRadius: 14,
        depth: 5,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: isSelected
                    ? NeuColors.primary
                    : NeuColors.textSecondary(isDark)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? NeuColors.primary
                    : NeuColors.textSecondary(isDark),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeuTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const _NeuTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NeuBox(
      style: NeuStyle.pressed,
      borderRadius: 14,
      depth: 4,
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        style: TextStyle(color: NeuColors.textPrimary(isDark)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: NeuColors.textSecondary(isDark)
                  .withValues(alpha: 0.6)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _NeuDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _NeuDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NeuBox(
      style: NeuStyle.pressed,
      borderRadius: 14,
      depth: 4,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: NeuColors.background(isDark),
          style: TextStyle(
              color: NeuColors.textPrimary(isDark), fontSize: 15),
          icon: Icon(Icons.expand_more_rounded,
              color: NeuColors.textSecondary(isDark)),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, this.isDark);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: NeuColors.textSecondary(isDark),
          letterSpacing: 0.3,
        ),
      );
}
