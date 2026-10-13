import 'package:flutter/material.dart';

import '../models/life_task.dart';
import '../services/task_store.dart';
import '../theme/app_theme.dart';

class TaskEditorScreen extends StatefulWidget {
  const TaskEditorScreen({
    super.key,
    required this.store,
    this.task,
  });

  final TaskStore store;
  final LifeTask? task;

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;

  late TaskCategory _category;
  late DateTime _dueDate;
  late int _repeatDays;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _noteController = TextEditingController(text: task?.note ?? '');
    _category = task?.category ?? TaskCategory.home;
    _dueDate = task?.dueDate ?? DateTime.now();
    _repeatDays = task?.repeatEveryDays ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit reminder' : 'New reminder'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.ink,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.loop_rounded, color: Color(0xFFB9E5D8), size: 30),
                    SizedBox(height: 12),
                    Text(
                      'Make future-you’s life easier.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Capture the small maintenance jobs before they become big problems.',
                      style: TextStyle(color: Color(0xFFD1E2DE), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _FieldLabel('What needs doing?'),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'e.g. Replace air filter',
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Give this reminder a name.'
                        : null,
              ),
              const SizedBox(height: 18),
              const _FieldLabel('Helpful note (optional)'),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Anything to remember before you start?',
                ),
              ),
              const SizedBox(height: 18),
              const _FieldLabel('Life area'),
              DropdownButtonFormField<TaskCategory>(
                value: _category,
                decoration: const InputDecoration(),
                items: TaskCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(category.icon, color: category.color, size: 19),
                            const SizedBox(width: 10),
                            Text(category.label),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 18),
              const _FieldLabel('When is it due?'),
              OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(
                  '${_dueDate.month}/${_dueDate.day}/${_dueDate.year}',
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(16),
                  foregroundColor: AppTheme.ink,
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                ),
              ),
              const SizedBox(height: 18),
              const _FieldLabel('Repeat'),
              DropdownButtonFormField<int>(
                value: _repeatDays,
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('One-time reminder')),
                  DropdownMenuItem(value: 7, child: Text('Every week')),
                  DropdownMenuItem(value: 30, child: Text('Every 30 days')),
                  DropdownMenuItem(value: 90, child: Text('Every 90 days')),
                  DropdownMenuItem(value: 180, child: Text('Every 6 months')),
                  DropdownMenuItem(value: 365, child: Text('Every year')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _repeatDays = value);
                },
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
                child: Text(_isEditing ? 'Save changes' : 'Create reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() => _dueDate = selected);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final oldTask = widget.task;
    final task = LifeTask(
      id: oldTask?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      note: _noteController.text.trim(),
      category: _category,
      dueDate: DateTime(_dueDate.year, _dueDate.month, _dueDate.day),
      repeatEveryDays: _repeatDays,
      isCompleted: oldTask?.isCompleted ?? false,
      completedAt: oldTask?.completedAt,
    );

    if (oldTask == null) {
      await widget.store.add(task);
    } else {
      await widget.store.update(task);
    }

    if (mounted) Navigator.of(context).pop();
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
