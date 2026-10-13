import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/life_task.dart';
import '../services/task_store.dart';
import '../theme/app_theme.dart';
import 'task_editor_screen.dart';

enum _TaskFilter { all, attention, completed }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.taskStore,
  });

  final TaskStore taskStore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _TaskFilter _filter = _TaskFilter.all;
  TaskCategory? _categoryFilter;
  String _search = '';

  @override
  void initState() {
    super.initState();
    widget.taskStore.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    widget.taskStore.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  List<LifeTask> get _visibleTasks {
    final tasks = widget.taskStore.tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(_search) ||
          task.note.toLowerCase().contains(_search);
      final matchesCategory =
          _categoryFilter == null || task.category == _categoryFilter;
      final matchesFilter = switch (_filter) {
        _TaskFilter.all => true,
        _TaskFilter.attention => !task.isCompleted,
        _TaskFilter.completed => task.isCompleted,
      };

      return matchesSearch && matchesCategory && matchesFilter;
    }).toList();

    tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return a.dueDate.compareTo(b.dueDate);
    });

    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.taskStore.tasks;
    final overdue = tasks.where((task) => task.isOverdue).length;
    final dueSoon = tasks.where((task) => task.isDueSoon).length;
    final completed = tasks.where((task) => task.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.loop_rounded, color: AppTheme.teal, size: 28),
            SizedBox(width: 9),
            Text(
              'LifeLoop',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reset filters',
            onPressed: () => setState(() {
              _filter = _TaskFilter.all;
              _categoryFilter = null;
              _search = '';
            }),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WelcomePanel(
                      overdue: overdue,
                      dueSoon: dueSoon,
                      completed: completed,
                      total: tasks.length,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your life, in good order.',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontSize: 25,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Small check-ins now can prevent bigger headaches later.',
                      style: TextStyle(color: AppTheme.muted, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      onChanged: (value) =>
                          setState(() => _search = value.toLowerCase().trim()),
                      decoration: const InputDecoration(
                        hintText: 'Search your reminders',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FilterChips(
                      selected: _filter,
                      onChanged: (value) => setState(() => _filter = value),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _CategoryChip(
                            label: 'Everything',
                            selected: _categoryFilter == null,
                            onTap: () =>
                                setState(() => _categoryFilter = null),
                          ),
                          ...TaskCategory.values.map(
                            (category) => _CategoryChip(
                              label: category.label,
                              selected: _categoryFilter == category,
                              color: category.color,
                              onTap: () => setState(
                                () => _categoryFilter =
                                    _categoryFilter == category ? null : category,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          'On your radar',
                          style: TextStyle(
                            color: AppTheme.ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_visibleTasks.length} items',
                          style: const TextStyle(color: AppTheme.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (_visibleTasks.isEmpty)
              const SliverToBoxAdapter(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList.separated(
                  itemCount: _visibleTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _TaskCard(task: _visibleTasks[index], store: widget.taskStore),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskEditorScreen(store: widget.taskStore),
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add reminder'),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({
    required this.overdue,
    required this.dueSoon,
    required this.completed,
    required this.total,
  });

  final int overdue;
  final int dueSoon;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final completion = total == 0 ? 0.0 : completed / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR LIFE MAINTENANCE RADAR',
                      style: TextStyle(
                        color: Color(0xFFB9E5D8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      overdue == 0
                          ? 'You’re right on track.'
                          : '$overdue ${overdue == 1 ? 'thing needs' : 'things need'} attention.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: Color(0xFFB9E5D8),
                  size: 29,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _MiniMetric(value: '$overdue', label: 'Overdue', color: const Color(0xFFFFB5A7)),
              const SizedBox(width: 22),
              _MiniMetric(value: '$dueSoon', label: 'Due this week', color: const Color(0xFFFFD68A)),
              const SizedBox(width: 22),
              _MiniMetric(value: '$completed', label: 'Completed', color: const Color(0xFFB9E5D8)),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFB9E5D8)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completed of $total reminders completed',
            style: const TextStyle(color: Color(0xFFD1E2DE), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFD1E2DE), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onChanged,
  });

  final _TaskFilter selected;
  final ValueChanged<_TaskFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          label: 'All',
          selected: selected == _TaskFilter.all,
          onTap: () => onChanged(_TaskFilter.all),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Needs attention',
          selected: selected == _TaskFilter.attention,
          onTap: () => onChanged(_TaskFilter.attention),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Done',
          selected: selected == _TaskFilter.completed,
          onTap: () => onChanged(_TaskFilter.completed),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 7),
          decoration: BoxDecoration(
            color: selected ? AppTheme.ink : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? (color ?? AppTheme.teal) : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.store,
  });

  final LifeTask task;
  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    final dateText = task.isOverdue
        ? 'Overdue · ${DateFormat('MMM d').format(task.dueDate)}'
        : task.isDueToday
            ? 'Due today'
            : 'Due ${DateFormat('MMM d').format(task.dueDate)}';

    final dateColor = task.isOverdue
        ? const Color(0xFFC64F43)
        : task.isDueSoon
            ? const Color(0xFFB47B24)
            : AppTheme.muted;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFC64F43),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete reminder?'),
          content: Text('“${task.title}” will be removed from LifeLoop.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
      onDismissed: (_) => store.delete(task.id),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskEditorScreen(store: store, task: task),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: task.isOverdue
                  ? const Color(0xFFF2C9C3)
                  : Colors.black.withValues(alpha: 0.035),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => store.toggleComplete(task),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: task.isCompleted ? AppTheme.teal : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isCompleted ? AppTheme.teal : const Color(0xFFB8C4C0),
                      width: 1.6,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
                      : null,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(task.category.icon, color: task.category.color, size: 15),
                        const SizedBox(width: 5),
                        Text(
                          task.category.label.toUpperCase(),
                          style: TextStyle(
                            color: task.category.color,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        if (task.repeatEveryDays > 0) ...[
                          const SizedBox(width: 7),
                          const Icon(Icons.repeat_rounded, size: 13, color: AppTheme.muted),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      task.title,
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (task.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      task.isCompleted ? 'Completed' : dateText,
                      style: TextStyle(
                        color: task.isCompleted ? AppTheme.teal : dateColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0BCB7)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 25, 30, 70),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFDDECE6),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: AppTheme.teal,
              size: 35,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nothing on your radar.',
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Try another filter or add a reminder for something future-you will thank you for.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}
