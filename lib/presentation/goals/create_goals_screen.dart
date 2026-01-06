import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../application/goal/goal_bloc.dart';
import '../../application/goal/goal_event.dart';
import '../../application/goal/goal_state.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../infrastucture/models/goals/goal.dart';

class CreateGoalScreen extends StatefulWidget {
  final Goal? goalToEdit;
  const CreateGoalScreen({Key? key, this.goalToEdit}) : super(key: key);

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Health';
  String _selectedFrequency = 'daily';
  int _targetCount = 1;
  String _selectedColor = '#4CAF50';
  String _selectedIcon = 'fitness';

  final List<String> _categories = [
    'Health',
    'Fitness',
    'Learning',
    'Work',
    'Personal',
    'Hobbies',
    'Social',
    'Spiritual',
  ];

  final List<String> _frequencies = ['daily', 'weekly', 'monthly'];

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Green', 'value': '#4CAF50'},
    {'name': 'Blue', 'value': '#2196F3'},
    {'name': 'Purple', 'value': '#9C27B0'},
    {'name': 'Orange', 'value': '#FF9800'},
    {'name': 'Red', 'value': '#F44336'},
    {'name': 'Pink', 'value': '#E91E63'},
    {'name': 'Teal', 'value': '#009688'},
    {'name': 'Indigo', 'value': '#3F51B5'},
  ];

  final List<Map<String, dynamic>> _icons = [
    {'name': 'Fitness', 'value': 'fitness', 'icon': Icons.fitness_center},
    {'name': 'Book', 'value': 'book', 'icon': Icons.book},
    {'name': 'Water', 'value': 'water', 'icon': Icons.local_drink},
    {
      'name': 'Meditation',
      'value': 'meditation',
      'icon': Icons.self_improvement,
    },
    {'name': 'Work', 'value': 'work', 'icon': Icons.work},
    {'name': 'Health', 'value': 'health', 'icon': Icons.health_and_safety},
    {'name': 'Education', 'value': 'education', 'icon': Icons.school},
    {'name': 'Hobby', 'value': 'hobby', 'icon': Icons.palette},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleCreateGoal() {
    print('🔵 Create Goal button clicked');

    // Debug form validation step by step
    print('🔵 Checking form state...');
    final formState = _formKey.currentState;
    print('📋 Form state: $formState');

    if (formState == null) {
      print('❌ Form state is null!');
      return;
    }

    print('🔵 Calling form validation...');
    final isValid = formState.validate();
    print('📋 Form validation result: $isValid');

    // Debug individual field values
    print('📋 Title: "${_titleController.text}"');
    print('📋 Title trimmed: "${_titleController.text.trim()}"');
    print('📋 Title length: ${_titleController.text.trim().length}');
    print('📋 Description: "${_descriptionController.text}"');
    print('📋 Category: $_selectedCategory');
    print('📋 Frequency: $_selectedFrequency');
    print('📋 Target count: $_targetCount');
    print('📋 Color: $_selectedColor');
    print('📋 Icon: $_selectedIcon');

    if (isValid) {
      print('✅ Form validation passed');

      try {
        print('🔵 Attempting to get GoalBloc...');
        final goalBloc = context.read<GoalBloc>();
        print('✅ GoalBloc found: $goalBloc');

        print('🔵 Creating CreateGoal event...');
        final createGoalEvent = CreateGoal(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          color: _selectedColor,
          icon: _selectedIcon,
          targetFrequency: _selectedFrequency,
          targetCount: _targetCount,
        );
        print('✅ CreateGoal event created: $createGoalEvent');

        print('🔵 Adding event to GoalBloc...');
        goalBloc.add(createGoalEvent);
        print('✅ Goal creation event sent successfully');

        // Listen to bloc state changes
        print('🔵 Current GoalBloc state: ${goalBloc.state}');
      } catch (e, stackTrace) {
        print('❌ Error creating goal: $e');
        print('📋 Stack trace: $stackTrace');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Goal service not available: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('❌ Form validation failed');
      print('🔍 Check the form fields above for validation errors');
    }
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.deepPurple;
    }
  }

  // Helper method to provide GoalBloc if not available in context
  Widget _buildWithGoalBloc(BuildContext context) {
    // Try to access GoalBloc from context first
    try {
      context.read<GoalBloc>();
      // If successful, use the existing GoalBloc
      return _buildScreen(context);
    } catch (e) {
      // If GoalBloc is not found, provide our own instance
      print('⚠️ GoalBloc not found in context, creating new instance: $e');

      try {
        // Try to create GoalBloc from GetIt
        final goalBloc = GetIt.instance<GoalBloc>();
        return BlocProvider<GoalBloc>.value(
          value: goalBloc,
          child: _buildScreen(context),
        );
      } catch (createError) {
        print('❌ Failed to create GoalBloc: $createError');
        // If we can't create GoalBloc, show error screen
        return _buildErrorScreen();
      }
    }
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Goal')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Goal service is not available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Please restart the app and try again',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Goal'), elevation: 0),
      body: BlocConsumer<GoalBloc, GoalState>(
        listener: (context, state) {
          if (state is GoalCreated) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Goal created successfully! 🎉'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is GoalError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is GoalValidationError) {
            final generalError = state.fieldErrors['general'];
            if (generalError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(generalError),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is GoalActionLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Goal Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _titleController,
                              labelText: 'Goal Title',
                              hintText: 'e.g., Exercise daily, Read 30 minutes',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty)
                                  return 'Please enter a goal title';
                                if (value.trim().length < 3)
                                  return 'Title must be at least 3 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _descriptionController,
                              labelText: 'Description (Optional)',
                              hintText: 'Add more details about your goal',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _categories.map((category) {
                                    final isSelected =
                                        _selectedCategory == category;
                                    return ChoiceChip(
                                      label: Text(category),
                                      selected: isSelected,
                                      onSelected:
                                          (selected) => setState(
                                            () => _selectedCategory = category,
                                          ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Frequency Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Frequency',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedFrequency,
                                    decoration: const InputDecoration(
                                      labelText: 'How often',
                                      border: OutlineInputBorder(),
                                    ),
                                    items:
                                        _frequencies.map((frequency) {
                                          return DropdownMenuItem(
                                            value: frequency,
                                            child: Text(frequency.capitalize()),
                                          );
                                        }).toList(),
                                    onChanged:
                                        (value) => setState(
                                          () => _selectedFrequency = value!,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: _targetCount,
                                    decoration: const InputDecoration(
                                      labelText: 'Times per period',
                                      border: OutlineInputBorder(),
                                    ),
                                    items:
                                        List.generate(
                                          10,
                                          (index) => index + 1,
                                        ).map((count) {
                                          return DropdownMenuItem(
                                            value: count,
                                            child: Text(
                                              '$count time${count > 1 ? 's' : ''}',
                                            ),
                                          );
                                        }).toList(),
                                    onChanged:
                                        (value) => setState(
                                          () => _targetCount = value!,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Appearance Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Appearance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Color Selection
                            const Text(
                              'Color:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _colors.map((colorData) {
                                    final isSelected =
                                        _selectedColor == colorData['value'];
                                    final color = _getColorFromHex(
                                      colorData['value'],
                                    );
                                    return GestureDetector(
                                      onTap:
                                          () => setState(
                                            () =>
                                                _selectedColor =
                                                    colorData['value'],
                                          ),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border:
                                              isSelected
                                                  ? Border.all(
                                                    color: Colors.black,
                                                    width: 3,
                                                  )
                                                  : null,
                                        ),
                                        child:
                                            isSelected
                                                ? const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                )
                                                : null,
                                      ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // Icon Selection
                            const Text(
                              'Icon:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _icons.map((iconData) {
                                    final isSelected =
                                        _selectedIcon == iconData['value'];
                                    return GestureDetector(
                                      onTap:
                                          () => setState(
                                            () =>
                                                _selectedIcon =
                                                    iconData['value'],
                                          ),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? _getColorFromHex(
                                                    _selectedColor,
                                                  ).withOpacity(0.2)
                                                  : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border:
                                              isSelected
                                                  ? Border.all(
                                                    color: _getColorFromHex(
                                                      _selectedColor,
                                                    ),
                                                    width: 2,
                                                  )
                                                  : Border.all(
                                                    color: Colors.grey[300]!,
                                                  ),
                                        ),
                                        child: Icon(
                                          iconData['icon'],
                                          color:
                                              isSelected
                                                  ? _getColorFromHex(
                                                    _selectedColor,
                                                  )
                                                  : Colors.grey[600],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Create Button
                    CustomButton(
                      text: 'Create Goal',
                      onPressed: isLoading ? null : _handleCreateGoal,
                      isLoading: isLoading,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildWithGoalBloc(context);
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
