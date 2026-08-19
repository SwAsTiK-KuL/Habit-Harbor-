import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../application/goal/goal_bloc.dart';
import '../../application/goal/goal_event.dart';
import '../../application/goal/goal_state.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../domain/entities/goals/goal_reminder.dart';
import '../../infrastucture/models/goals/goal.dart';

class CreateGoalScreen extends StatefulWidget {
  final Goal? goalToEdit;
  const CreateGoalScreen({Key? key, this.goalToEdit}) : super(key: key);

  /// ✅ Preferred entry point — shows this as a modal bottom sheet
  /// matching the mockup (dimmed background, rounded-top sheet),
  /// instead of a full-screen pushed route.
  static Future<void> show(BuildContext context, {Goal? goalToEdit}) {
    final goalBloc = context.read<GoalBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => BlocProvider.value(
            value: goalBloc,
            child: CreateGoalScreen(goalToEdit: goalToEdit),
          ),
    );
  }

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  static const Color kAccent = Color(0xFF5B3DF5);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Health';
  String _selectedFrequency = 'daily';
  int _targetCount = 1;
  String _selectedColor = '#4CAF50';
  String _selectedIcon = 'fitness';

  List<GoalReminder> _reminders = [];

  final List<String> _categories = [
    'Fitness',
    'Health',
    'Mindfulness',
    'Learning',
    'Work',
    'Personal',
    'Hobbies',
    'Social',
    'Spiritual',
    'Finance',
    'Nutrition',
    'Sleep',
  ];

  final List<String> _frequencies = ['daily', 'weekly', 'monthly'];

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Violet', 'value': '#9C27B0'},
    {'name': 'Sky', 'value': '#2196F3'},
    {'name': 'Emerald', 'value': '#4CAF50'},
    {'name': 'Amber', 'value': '#FF9800'},
    {'name': 'Rose', 'value': '#F44336'},
    {'name': 'Pink', 'value': '#E91E63'},
    {'name': 'Teal', 'value': '#009688'},
    {'name': 'Indigo', 'value': '#3F51B5'},
    {'name': 'Cyan', 'value': '#00BCD4'},
    {'name': 'Lime', 'value': '#8BC34A'},
    {'name': 'Gold', 'value': '#FFC107'},
    {'name': 'Coral', 'value': '#FF5722'},
  ];

  // ✅ All 18 icons kept — flattened into a single scrollable row
  // (mockup shows one row, not the old 3-tab grouping) so every
  // icon option is still selectable, just presented more compactly.
  final List<Map<String, dynamic>> _icons = [
    {'name': 'Fitness', 'value': 'fitness', 'icon': Icons.fitness_center},
    {'name': 'Run', 'value': 'run', 'icon': Icons.directions_run},
    {'name': 'Yoga', 'value': 'meditation', 'icon': Icons.self_improvement},
    {'name': 'Heart', 'value': 'heart', 'icon': Icons.favorite},
    {'name': 'Water', 'value': 'water', 'icon': Icons.local_drink},
    {'name': 'Sleep', 'value': 'sleep', 'icon': Icons.bedtime},
    {'name': 'Book', 'value': 'book', 'icon': Icons.menu_book},
    {'name': 'Study', 'value': 'study', 'icon': Icons.school},
    {'name': 'Work', 'value': 'work', 'icon': Icons.work},
    {'name': 'Code', 'value': 'code', 'icon': Icons.code},
    {'name': 'Write', 'value': 'write', 'icon': Icons.edit_note},
    {'name': 'Research', 'value': 'research', 'icon': Icons.science},
    {'name': 'Star', 'value': 'star', 'icon': Icons.star},
    {'name': 'Music', 'value': 'music', 'icon': Icons.music_note},
    {'name': 'Finance', 'value': 'finance', 'icon': Icons.savings},
    {'name': 'Travel', 'value': 'travel', 'icon': Icons.flight},
    {'name': 'Nature', 'value': 'nature', 'icon': Icons.park},
    {'name': 'Social', 'value': 'social', 'icon': Icons.people},
  ];

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showClassicSnackbar(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Color iconColor = Colors.green,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withOpacity(0.07)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleCreateGoal() {
    if (_formKey.currentState?.validate() != true) return;
    try {
      context.read<GoalBloc>().add(
        CreateGoal(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          color: _selectedColor,
          icon: _selectedIcon,
          targetFrequency: _selectedFrequency,
          targetCount: _targetCount,
        ),
      );
    } catch (e) {
      _showClassicSnackbar(
        context,
        title: 'Error',
        subtitle: e.toString(),
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red,
      );
    }
  }

  String _generateReminderId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  void _addReminder() {
    if (_reminders.length >= 5) return;
    setState(() {
      _reminders.add(
        GoalReminder(
          id: _generateReminderId(),
          time: '08:00',
          label: '',
          enabled: true,
        ),
      );
    });
  }

  void _deleteReminder(int index) => setState(() => _reminders.removeAt(index));

  void _toggleReminder(int index, bool val) {
    setState(() {
      final r = _reminders[index];
      _reminders[index] = GoalReminder(
        id: r.id,
        time: r.time,
        label: r.label,
        enabled: val,
      );
    });
  }

  Future<void> _pickReminderTime(int index) async {
    final r = _reminders[index];
    final parts = r.time.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final timeStr =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      _reminders[index] = GoalReminder(
        id: r.id,
        time: timeStr,
        label: r.label,
        enabled: r.enabled,
      );
    });
  }

  void _updateReminderLabel(int index, String val) {
    final r = _reminders[index];
    _reminders[index] = GoalReminder(
      id: r.id,
      time: r.time,
      label: val,
      enabled: r.enabled,
    );
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xff')));
    } catch (_) {
      return kAccent;
    }
  }

  IconData _getSelectedIconData() {
    for (final icon in _icons) {
      if (icon['value'] == _selectedIcon) return icon['icon'] as IconData;
    }
    return Icons.star;
  }

  Widget _buildWithGoalBloc(BuildContext context) {
    try {
      context.read<GoalBloc>();
      return _buildSheet(context);
    } catch (_) {
      try {
        final goalBloc = GetIt.instance<GoalBloc>();
        return BlocProvider<GoalBloc>.value(
          value: goalBloc,
          child: _buildSheet(context),
        );
      } catch (_) {
        return _buildErrorSheet();
      }
    }
  }

  Widget _buildErrorSheet() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 12),
            Text(
              'Goal service is not available',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  // ── Main sheet ──────────────────────────────────────────────────────────
  Widget _buildSheet(BuildContext context) {
    final accent = _getColorFromHex(_selectedColor);

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: BlocConsumer<GoalBloc, GoalState>(
          listener: (context, state) {
            if (state is GoalCreated) {
              Navigator.pop(context);
              final active = _reminders.where((r) => r.enabled).length;
              _showClassicSnackbar(
                context,
                title: 'Goal Created!',
                subtitle:
                    active > 0
                        ? 'Added with $active active reminder${active > 1 ? 's' : ''}'
                        : 'Your new habit has been added',
                icon: Icons.check_rounded,
                iconColor: Colors.green,
              );
              if (_reminders.isNotEmpty) {
                context.read<GoalBloc>().add(
                  UpdateGoalReminders(
                    goalId: state.goal.id,
                    reminders: _reminders,
                  ),
                );
              }
            } else if (state is GoalError) {
              _showClassicSnackbar(
                context,
                title: 'Something went wrong',
                subtitle: state.message,
                icon: Icons.error_outline_rounded,
                iconColor: Colors.red,
              );
            } else if (state is GoalValidationError) {
              final err = state.fieldErrors['general'];
              if (err != null) {
                _showClassicSnackbar(
                  context,
                  title: 'Validation Error',
                  subtitle: err,
                  icon: Icons.warning_amber_rounded,
                  iconColor: Colors.orange,
                );
              }
            }
          },
          builder: (context, state) {
            final isLoading = state is GoalActionLoading;

            return SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: const [
                        Text(
                          'New Goal',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Title ──
                            _sectionLabel('Title'),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: _titleController,
                              labelText: '',
                              hintText: 'e.g. Evening Walk',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a goal title';
                                }
                                if (value.trim().length < 3) {
                                  return 'Title must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // ── Description (kept, optional — not in mockup but preserved) ──
                            CustomTextField(
                              controller: _descriptionController,
                              labelText: '',
                              hintText: 'Description (optional)',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 22),

                            // ── Category ──
                            _sectionLabel('Category'),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 38,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _categories.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  final cat = _categories[i];
                                  final isSelected = _selectedCategory == cat;
                                  return GestureDetector(
                                    onTap:
                                        () => setState(
                                          () => _selectedCategory = cat,
                                        ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? kAccent
                                                : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        cat,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.black54,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 22),

                            // ── Icon (all 18 kept, single scrollable row) ──
                            _sectionLabel('Icon'),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 52,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _icons.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(width: 10),
                                itemBuilder: (_, i) {
                                  final iconData = _icons[i];
                                  final isSelected =
                                      _selectedIcon == iconData['value'];
                                  return GestureDetector(
                                    onTap:
                                        () => setState(
                                          () =>
                                              _selectedIcon =
                                                  iconData['value'] as String,
                                        ),
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? kAccent.withOpacity(0.12)
                                                : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(14),
                                        border:
                                            isSelected
                                                ? Border.all(
                                                  color: kAccent,
                                                  width: 2,
                                                )
                                                : null,
                                      ),
                                      child: Icon(
                                        iconData['icon'] as IconData,
                                        color:
                                            isSelected
                                                ? kAccent
                                                : Colors.grey[500],
                                        size: 24,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 22),

                            // ── Color ──
                            _sectionLabel('Color'),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 40,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _colors.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(width: 10),
                                itemBuilder: (_, i) {
                                  final c = _colors[i];
                                  final isSelected =
                                      _selectedColor == c['value'];
                                  final col = _getColorFromHex(
                                    c['value'] as String,
                                  );
                                  return GestureDetector(
                                    onTap:
                                        () => setState(
                                          () =>
                                              _selectedColor =
                                                  c['value'] as String,
                                        ),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: col,
                                        shape: BoxShape.circle,
                                        border:
                                            isSelected
                                                ? Border.all(
                                                  color: Colors.black87,
                                                  width: 2.5,
                                                )
                                                : null,
                                      ),
                                      child:
                                          isSelected
                                              ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              )
                                              : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 22),

                            // ── Frequency (kept — not in mockup, preserved) ──
                            _sectionLabel('Frequency'),
                            const SizedBox(height: 10),
                            Row(
                              children:
                                  _frequencies.map((freq) {
                                    final isSelected =
                                        _selectedFrequency == freq;
                                    return Expanded(
                                      child: GestureDetector(
                                        onTap:
                                            () => setState(
                                              () => _selectedFrequency = freq,
                                            ),
                                        child: Container(
                                          margin: EdgeInsets.only(
                                            right:
                                                freq != _frequencies.last
                                                    ? 8
                                                    : 0,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 11,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? kAccent
                                                    : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            freq[0].toUpperCase() +
                                                freq.substring(1),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                      : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Text(
                                  'Times per period',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    if (_targetCount > 1)
                                      setState(() => _targetCount--);
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: kAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      size: 16,
                                      color: kAccent,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '$_targetCount',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (_targetCount < 20)
                                      setState(() => _targetCount++);
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: kAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 16,
                                      color: kAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),

                            // ── Reminders (kept — not in mockup, preserved) ──
                            _sectionLabel('Reminders'),
                            const SizedBox(height: 10),
                            ..._reminders.asMap().entries.map((entry) {
                              final i = entry.key;
                              final r = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          r.enabled
                                              ? kAccent.withOpacity(0.25)
                                              : Colors.grey[200]!,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Transform.scale(
                                        scale: 0.85,
                                        child: Switch(
                                          value: r.enabled,
                                          activeColor: kAccent,
                                          onChanged:
                                              (val) => _toggleReminder(i, val),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _pickReminderTime(i),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: kAccent.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 12,
                                                color: kAccent,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                r.time,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: kAccent,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          decoration: const InputDecoration(
                                            hintText: 'Label (optional)',
                                            border: InputBorder.none,
                                            isDense: true,
                                            hintStyle: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black38,
                                            ),
                                          ),
                                          style: const TextStyle(fontSize: 13),
                                          onChanged:
                                              (val) =>
                                                  _updateReminderLabel(i, val),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _deleteReminder(i),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            if (_reminders.length < 5)
                              GestureDetector(
                                onTap: _addReminder,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: kAccent.withOpacity(0.35),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    color: kAccent.withOpacity(0.04),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add, size: 16, color: kAccent),
                                      const SizedBox(width: 6),
                                      Text(
                                        _reminders.isEmpty
                                            ? 'Add Reminder'
                                            : 'Add Another Reminder',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: kAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 28),

                            // ── Save Goal button ──
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleCreateGoal,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kAccent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child:
                                    isLoading
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Text(
                                          'Save Goal',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _buildWithGoalBloc(context);
}
