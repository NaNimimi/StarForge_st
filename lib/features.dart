import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'screens.dart';
import 'theme.dart';
import 'widgets.dart';

// ─────────────────────────── HOMEWORK ───────────────────────────

enum _TaskFilter { active, today, overdue, completed, all }

class HomeworkScreen extends StatefulWidget {
  final AppRole role;

  const HomeworkScreen({super.key, required this.role});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final _searchController = TextEditingController();
  _TaskFilter _filter = _TaskFilter.active;
  String _subject = 'Barchasi';
  String _query = '';

  List<StudyTask> get _assignedTasks {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    DateTime at(DateTime day, int hour) =>
        DateTime(day.year, day.month, day.day, hour);
    return [
      StudyTask(
        id: 'algebra-equations',
        title: 'Kvadrat tenglamalar · 1–12 misol',
        subject: 'Algebra',
        dueLabel: 'Bugun · 20:00',
        dueAt: at(today, 20),
        minutes: 35,
      ),
      StudyTask(
        id: 'geometry-proof',
        title: 'Uchburchaklar tengligi isboti',
        subject: 'Geometriya',
        dueLabel: 'Ertaga · 18:00',
        dueAt: at(today.add(const Duration(days: 1)), 18),
        minutes: 25,
      ),
      StudyTask(
        id: 'english-words',
        title: 'Unit 8 · 20 ta yangi so‘z',
        subject: 'Ingliz tili',
        dueLabel: '26 Iyul · 17:00',
        dueAt: at(today.add(const Duration(days: 1)), 17),
        minutes: 20,
      ),
      StudyTask(
        id: 'algebra-review',
        title: 'Nazorat ishi xatolarini tuzatish',
        subject: 'Algebra',
        dueLabel: 'Kecha · 19:00',
        dueAt: at(today.subtract(const Duration(days: 1)), 19),
        minutes: 30,
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final allTasks = [..._assignedTasks, ...state.personalTasks]
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    final visible = allTasks.where((task) => _matches(task, state)).toList();
    final completed = allTasks
        .where((task) => state.completedTasks.contains(task.id))
        .length;
    final active = allTasks.length - completed;
    final overdue = allTasks
        .where(
          (task) =>
              task.dueAt.isBefore(DateTime.now()) &&
              !state.completedTasks.contains(task.id),
        )
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: widget.role == AppRole.parent
              ? 'Akmal · vazifalar'
              : 'Mening rejam',
          title: const Text('Vazifalar'),
          sub: '$active ta faol · $overdue ta muddati o‘tgan',
          right: widget.role == AppRole.student
              ? SoftButton(
                  'Shaxsiy vazifa',
                  icon: Icons.add_rounded,
                  primary: true,
                  onTap: () => _showAddTask(context, state),
                )
              : SoftButton(
                  'Eslatish',
                  icon: Icons.notifications_active_rounded,
                  onTap: () => sfToast(
                    context,
                    'Akmalga eslatma yuborildi',
                    tone: Sf.success,
                  ),
                ),
        ),
        SfGrid(
          minTile: 145,
          children: [
            KpiCard(
              label: 'Faol',
              value: '$active',
              valueColor: Sf.primary,
              icon: Icons.assignment_rounded,
            ),
            KpiCard(
              label: 'Bajarilgan',
              value: '$completed',
              valueColor: Sf.success,
              icon: Icons.task_alt_rounded,
            ),
            KpiCard(
              label: 'Kechikkan',
              value: '$overdue',
              valueColor: overdue == 0 ? Sf.success : Sf.danger,
              icon: Icons.schedule_rounded,
            ),
            const KpiCard(
              label: 'Taxminiy vaqt',
              value: '110 min',
              valueColor: Sf.accentInk,
              icon: Icons.timer_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SfTwoCol(
          breakpoint: 1050,
          leftFlex: 16,
          rightFlex: 8,
          left: SfCol([
            _TaskToolbar(
              controller: _searchController,
              query: _query,
              filter: _filter,
              subject: _subject,
              onQueryChanged: (value) => setState(() => _query = value),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              onFilterChanged: (value) => setState(() => _filter = value),
              onSubjectChanged: (value) => setState(() => _subject = value),
            ),
            SectionCard(
              title: 'Topshiriqlar · ${visible.length}',
              bodyPadding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: visible.isEmpty
                  ? _TaskEmpty(
                      onReset: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                          _filter = _TaskFilter.all;
                          _subject = 'Barchasi';
                        });
                      },
                    )
                  : Column(
                      children: [
                        for (var index = 0; index < visible.length; index++)
                          _TaskTile(
                            task: visible[index],
                            completed: state.completedTasks.contains(
                              visible[index].id,
                            ),
                            isOverdue: _isOverdue(visible[index], state),
                            isParent: widget.role == AppRole.parent,
                            last: index == visible.length - 1,
                            onToggle: () {
                              state.toggleTask(visible[index].id);
                              sfToast(
                                context,
                                state.completedTasks.contains(visible[index].id)
                                    ? 'Vazifa bajarildi'
                                    : 'Vazifa qayta ochildi',
                                sub: visible[index].title,
                                tone:
                                    state.completedTasks.contains(
                                      visible[index].id,
                                    )
                                    ? Sf.success
                                    : Sf.warn,
                              );
                            },
                            onOpen: () => _showTaskDetails(
                              context,
                              visible[index],
                              state,
                            ),
                            onDelete: visible[index].isPersonal
                                ? () => _confirmDelete(
                                    context,
                                    visible[index],
                                    state,
                                  )
                                : null,
                          ),
                      ],
                    ),
            ),
          ]),
          right: const SfCol([StudyTimerCard(), _HomeworkTips()]),
        ),
      ],
    );
  }

  bool _matches(StudyTask task, AppState state) {
    final completed = state.completedTasks.contains(task.id);
    final query = _query.trim().toLowerCase();
    if (query.isNotEmpty &&
        !'${task.title} ${task.subject}'.toLowerCase().contains(query)) {
      return false;
    }
    if (_subject != 'Barchasi' && task.subject != _subject) return false;
    return switch (_filter) {
      _TaskFilter.active => !completed,
      _TaskFilter.today => DateUtils.isSameDay(task.dueAt, DateTime.now()),
      _TaskFilter.overdue => _isOverdue(task, state),
      _TaskFilter.completed => completed,
      _TaskFilter.all => true,
    };
  }

  bool _isOverdue(StudyTask task, AppState state) =>
      task.dueAt.isBefore(DateTime.now()) &&
      !state.completedTasks.contains(task.id);

  Future<void> _showAddTask(BuildContext context, AppState state) async {
    final titleController = TextEditingController();
    var subject = 'Algebra';
    var minutes = 25.0;
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Sf.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: SizedBox(
                  width: 44,
                  child: Divider(thickness: 4, color: Sf.borderStrong),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Shaxsiy vazifa qo‘shish',
                style: Sf.t(size: 20, weight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Vazifa nomi',
                  hintText: 'Masalan: formulalarni takrorlash',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: subject,
                decoration: const InputDecoration(
                  labelText: 'Fan',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Algebra', child: Text('Algebra')),
                  DropdownMenuItem(
                    value: 'Geometriya',
                    child: Text('Geometriya'),
                  ),
                  DropdownMenuItem(
                    value: 'Ingliz tili',
                    child: Text('Ingliz tili'),
                  ),
                  DropdownMenuItem(value: 'Mustaqil', child: Text('Mustaqil')),
                ],
                onChanged: (value) =>
                    setSheetState(() => subject = value ?? subject),
              ),
              const SizedBox(height: 16),
              Text(
                'Rejalashtirilgan vaqt: ${minutes.round()} daqiqa',
                style: Sf.t(size: 13, weight: FontWeight.w700),
              ),
              Slider(
                value: minutes,
                min: 10,
                max: 90,
                divisions: 16,
                label: '${minutes.round()} min',
                onChanged: (value) => setSheetState(() => minutes = value),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {
                  if (titleController.text.trim().length < 3) {
                    sfToast(
                      context,
                      'Nom kamida 3 ta belgidan iborat bo‘lsin',
                      tone: Sf.warn,
                    );
                    return;
                  }
                  state.addPersonalTask(
                    StudyTask(
                      id: 'personal-${DateTime.now().millisecondsSinceEpoch}',
                      title: titleController.text.trim(),
                      subject: subject,
                      dueLabel: 'Bugun · shaxsiy',
                      dueAt: DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                        22,
                      ),
                      minutes: minutes.round(),
                      isPersonal: true,
                    ),
                  );
                  Navigator.pop(sheetContext, true);
                },
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Rejaga qo‘shish'),
              ),
            ],
          ),
        ),
      ),
    );
    titleController.dispose();
    if (added == true && context.mounted) {
      sfToast(context, 'Shaxsiy vazifa qo‘shildi', tone: Sf.success);
    }
  }

  Future<void> _showTaskDetails(
    BuildContext context,
    StudyTask task,
    AppState state,
  ) async {
    var attached = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final completed = state.completedTasks.contains(task.id);
          return AlertDialog(
            title: Text(task.title),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Pill(task.subject, tone: Tone.primary),
                      Pill(
                        task.dueLabel,
                        tone: _isOverdue(task, state) ? Tone.danger : Tone.warn,
                      ),
                      Pill('${task.minutes} daqiqa', tone: Tone.neutral),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Bajarish tartibi',
                    style: Sf.t(size: 13, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (final step in const [
                    'Mavzuni qisqa takrorlang',
                    'Yechimni bosqichma-bosqich yozing',
                    'Javobni tekshirib, ishni yuboring',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                            color: Sf.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(step, style: Sf.t(size: 12.5))),
                        ],
                      ),
                    ),
                  if (widget.role == AppRole.student) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        setDialogState(() => attached = !attached);
                        sfToast(
                          context,
                          attached
                              ? 'Yechim rasmi biriktirildi'
                              : 'Biriktirma olib tashlandi',
                          tone: attached ? Sf.success : Sf.muted,
                        );
                      },
                      icon: Icon(
                        attached
                            ? Icons.attachment_rounded
                            : Icons.add_photo_alternate_outlined,
                      ),
                      label: Text(
                        attached
                            ? 'yechim.jpg biriktirilgan'
                            : 'Yechimni biriktirish',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Yopish'),
              ),
              FilledButton.icon(
                onPressed: widget.role == AppRole.parent
                    ? null
                    : () {
                        state.toggleTask(task.id);
                        Navigator.pop(dialogContext);
                        sfToast(
                          context,
                          completed
                              ? 'Vazifa qayta ochildi'
                              : 'Vazifa bajarildi',
                          tone: completed ? Sf.warn : Sf.success,
                        );
                      },
                icon: Icon(
                  completed ? Icons.replay_rounded : Icons.task_alt_rounded,
                ),
                label: Text(completed ? 'Qayta ochish' : 'Bajarildi'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    StudyTask task,
    AppState state,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vazifani o‘chirish'),
        content: Text('“${task.title}” rejadan olib tashlansinmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Sf.danger),
            child: const Text('O‘chirish'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      state.removePersonalTask(task.id);
      if (context.mounted) {
        sfToast(context, 'Shaxsiy vazifa o‘chirildi', tone: Sf.danger);
      }
    }
  }
}

class _TaskToolbar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final _TaskFilter filter;
  final String subject;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final ValueChanged<_TaskFilter> onFilterChanged;
  final ValueChanged<String> onSubjectChanged;

  const _TaskToolbar({
    required this.controller,
    required this.query,
    required this.filter,
    required this.subject,
    required this.onQueryChanged,
    required this.onClear,
    required this.onFilterChanged,
    required this.onSubjectChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Saralash va izlash',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Vazifa yoki fan nomi...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Izlashni tozalash',
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Sf.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Sf.border),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final item in const [
                (_TaskFilter.active, 'Faol'),
                (_TaskFilter.today, 'Bugun'),
                (_TaskFilter.overdue, 'Kechikkan'),
                (_TaskFilter.completed, 'Bajarilgan'),
                (_TaskFilter.all, 'Barchasi'),
              ])
                ChoiceChip(
                  label: Text(item.$2),
                  selected: filter == item.$1,
                  onSelected: (_) => onFilterChanged(item.$1),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: subject,
            isDense: true,
            decoration: const InputDecoration(
              labelText: 'Fan bo‘yicha',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Barchasi', child: Text('Barcha fanlar')),
              DropdownMenuItem(value: 'Algebra', child: Text('Algebra')),
              DropdownMenuItem(value: 'Geometriya', child: Text('Geometriya')),
              DropdownMenuItem(
                value: 'Ingliz tili',
                child: Text('Ingliz tili'),
              ),
              DropdownMenuItem(value: 'Mustaqil', child: Text('Mustaqil')),
            ],
            onChanged: (value) {
              if (value != null) onSubjectChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final StudyTask task;
  final bool completed;
  final bool isOverdue;
  final bool isParent;
  final bool last;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  const _TaskTile({
    required this.task,
    required this.completed,
    required this.isOverdue,
    required this.isParent,
    required this.last,
    required this.onToggle,
    required this.onOpen,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Sf.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            label: completed ? 'Bajarilgan vazifa' : 'Bajarilmagan vazifa',
            child: Checkbox(
              value: completed,
              onChanged: isParent ? null : (_) => onToggle(),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Sf.t(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: completed ? Sf.muted : Sf.ink,
                          ).copyWith(
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 7,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          task.subject,
                          style: Sf.t(size: 11, color: Sf.muted),
                        ),
                        Pill(
                          completed ? 'Bajarildi' : task.dueLabel,
                          tone: completed
                              ? Tone.success
                              : isOverdue
                              ? Tone.danger
                              : Tone.warn,
                          dot: true,
                        ),
                        Text(
                          '${task.minutes} min',
                          style: Sf.monoStyle(
                            size: 10.5,
                            weight: FontWeight.w400,
                            color: Sf.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Shaxsiy vazifani o‘chirish',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Sf.danger,
              ),
            )
          else
            IconButton(
              tooltip: 'Vazifa tafsilotlari',
              onPressed: onOpen,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
        ],
      ),
    );
  }
}

class _TaskEmpty extends StatelessWidget {
  final VoidCallback onReset;

  const _TaskEmpty({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Column(
        children: [
          const Icon(Icons.task_alt_rounded, size: 44, color: Sf.success),
          const SizedBox(height: 10),
          Text(
            'Bu filtrda vazifa topilmadi',
            style: Sf.t(size: 14, weight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Filtrlarni tozalab, barcha vazifalarni ko‘ring.',
            textAlign: TextAlign.center,
            style: Sf.t(size: 12, color: Sf.muted),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onReset,
            child: const Text('Filtrlarni tozalash'),
          ),
        ],
      ),
    );
  }
}

class StudyTimerCard extends StatefulWidget {
  const StudyTimerCard({super.key});

  @override
  State<StudyTimerCard> createState() => _StudyTimerCardState();
}

class _StudyTimerCardState extends State<StudyTimerCard> {
  Timer? _timer;
  int _durationMinutes = 25;
  int _secondsLeft = 25 * 60;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
          _running = false;
        });
        sfToast(
          context,
          'Fokus seansi yakunlandi!',
          sub: 'Endi 5 daqiqa dam oling.',
          tone: Sf.success,
        );
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _secondsLeft = _durationMinutes * 60;
    });
  }

  void _setDuration(int value) {
    _timer?.cancel();
    setState(() {
      _durationMinutes = value;
      _secondsLeft = value * 60;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    final progress = _secondsLeft / (_durationMinutes * 60);
    return SectionCard(
      title: 'Fokus taymeri',
      child: Column(
        children: [
          Semantics(
            label: '$minutes daqiqa $seconds soniya qoldi',
            child: SizedBox(
              width: 154,
              height: 154,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 142,
                    height: 142,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 9,
                      backgroundColor: Sf.surface2,
                      color: _running ? Sf.accent : Sf.primary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$minutes:$seconds',
                        style: Sf.monoStyle(size: 27, weight: FontWeight.w700),
                      ),
                      Text(
                        _running ? 'DIQQATNI JAMLANG' : 'TAYYOR',
                        style: Sf.eyebrow(
                          color: _running ? Sf.accentInk : Sf.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 15, label: Text('15')),
              ButtonSegment(value: 25, label: Text('25')),
              ButtonSegment(value: 45, label: Text('45')),
            ],
            selected: {_durationMinutes},
            onSelectionChanged: _running
                ? null
                : (value) => _setDuration(value.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _secondsLeft == 0 ? _reset : _toggle,
                icon: Icon(
                  _secondsLeft == 0
                      ? Icons.replay_rounded
                      : _running
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(
                  _secondsLeft == 0
                      ? 'Qayta'
                      : _running
                      ? 'Pauza'
                      : 'Boshlash',
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Taymerni tiklash',
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeworkTips extends StatelessWidget {
  const _HomeworkTips();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Bugungi tavsiya',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AiBadge(label: 'O‘qish rejasi'),
          const SizedBox(height: 10),
          Text(
            'Avval 35 daqiqalik Algebra vazifasini bajaring, so‘ng 5 daqiqa dam oling.',
            style: Sf.serif(size: 15, height: 1.4),
          ),
          const SizedBox(height: 12),
          for (final tip in const [
            'Telefonni ovozsiz rejimga qo‘ying',
            'Murakkab savollarni belgilab boring',
            'Oxirida javoblarni tekshiring',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  const Icon(Icons.check_rounded, size: 17, color: Sf.success),
                  const SizedBox(width: 7),
                  Expanded(child: Text(tip, style: Sf.t(size: 12))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────── PROGRESS & GOALS ───────────────────────────

class ProgressScreen extends StatefulWidget {
  final AppRole role;

  const ProgressScreen({super.key, required this.role});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _period = 'Bu hafta';
  bool _showClassComparison = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isParent = widget.role == AppRole.parent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: isParent ? 'Akmal · 9-B' : 'Mening o‘sishim',
          title: Text(isParent ? 'Haftalik hisobot' : 'Natijalarim'),
          sub: 'Fanlar, o‘qish va shaxsiy maqsadlar',
          right: SoftButton(
            'Ulashish',
            icon: Icons.ios_share_rounded,
            primary: true,
            onTap: () => _copySummary(context),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String>(
                initialValue: _period,
                decoration: const InputDecoration(
                  labelText: 'Davr',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'Bu hafta', child: Text('Bu hafta')),
                  DropdownMenuItem(value: 'Bu oy', child: Text('Bu oy')),
                  DropdownMenuItem(value: 'Chorak', child: Text('Chorak')),
                ],
                onChanged: (value) =>
                    setState(() => _period = value ?? _period),
              ),
            ),
            FilterChip(
              selected: _showClassComparison,
              avatar: const Icon(Icons.groups_rounded, size: 18),
              label: const Text('Sinf o‘rtachasi bilan'),
              onSelected: (value) =>
                  setState(() => _showClassComparison = value),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SfGrid(
          minTile: 145,
          children: [
            KpiCard(
              label: 'O‘rtacha natija',
              value: '88%',
              valueColor: Sf.success,
              icon: Icons.trending_up_rounded,
            ),
            KpiCard(
              label: 'Bajarilgan vazifa',
              value: '9/11',
              valueColor: Sf.primary,
              icon: Icons.task_alt_rounded,
            ),
            KpiCard(
              label: 'Fokus vaqti',
              value: '3.4 soat',
              valueColor: Sf.accentInk,
              icon: Icons.timer_rounded,
            ),
            KpiCard(
              label: 'Faol kunlar',
              value: '6 kun',
              valueColor: Sf.success,
              icon: Icons.local_fire_department_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SfTwoCol(
          breakpoint: 1080,
          leftFlex: 13,
          rightFlex: 11,
          left: SfCol([
            _SubjectProgressCard(showComparison: _showClassComparison),
            const _WeeklyActivityCard(),
          ]),
          right: SfCol([
            SectionCard(
              title: 'Maqsadlar · ${state.goals.length}',
              action: TextButton.icon(
                onPressed: () => _addGoal(context, state),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text('Qo‘shish'),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < state.goals.length; index++)
                    _GoalTile(
                      goal: state.goals[index],
                      last: index == state.goals.length - 1,
                      onUpdate: () =>
                          _updateGoal(context, state.goals[index], state),
                    ),
                ],
              ),
            ),
            _InsightCard(isParent: isParent),
          ]),
        ),
      ],
    );
  }

  Future<void> _copySummary(BuildContext context) async {
    const summary =
        'StarForge EDU · Akmalning haftalik hisoboti\n'
        'O‘rtacha natija: 88%\n'
        'Vazifalar: 9/11\n'
        'Davomat: 96%\n'
        'Fokus vaqti: 3.4 soat';
    await Clipboard.setData(const ClipboardData(text: summary));
    if (context.mounted) {
      sfToast(
        context,
        'Hisobot nusxalandi',
        sub: 'Endi uni istalgan joyga yuborishingiz mumkin.',
        tone: Sf.success,
      );
    }
  }

  Future<void> _addGoal(BuildContext context, AppState state) async {
    final titleController = TextEditingController();
    final targetController = TextEditingController(text: '100');
    var subject = 'Algebra';
    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yangi maqsad'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Maqsad',
                    hintText: 'Masalan: 10 ta test ishlash',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: subject,
                  decoration: const InputDecoration(
                    labelText: 'Yo‘nalish',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Algebra', child: Text('Algebra')),
                    DropdownMenuItem(
                      value: 'Geometriya',
                      child: Text('Geometriya'),
                    ),
                    DropdownMenuItem(
                      value: 'Ingliz tili',
                      child: Text('Ingliz tili'),
                    ),
                    DropdownMenuItem(
                      value: 'Mustaqil o‘qish',
                      child: Text('Mustaqil o‘qish'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => subject = value ?? subject),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Maqsad qiymati',
                    suffixText: 'ball/min',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () {
                final target = int.tryParse(targetController.text);
                if (titleController.text.trim().length < 3 ||
                    target == null ||
                    target <= 0) {
                  sfToast(
                    context,
                    'Maqsad va qiymatni to‘g‘ri kiriting',
                    tone: Sf.warn,
                  );
                  return;
                }
                state.addGoal(
                  StudyGoal(
                    id: 'goal-${DateTime.now().millisecondsSinceEpoch}',
                    title: titleController.text.trim(),
                    subject: subject,
                    current: 0,
                    target: target,
                  ),
                );
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Qo‘shish'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    targetController.dispose();
    if (added == true && context.mounted) {
      sfToast(context, 'Yangi maqsad qo‘shildi', tone: Sf.success);
    }
  }

  Future<void> _updateGoal(
    BuildContext context,
    StudyGoal goal,
    AppState state,
  ) async {
    var value = goal.current.toDouble();
    final changed = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Natijani yangilash'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  goal.title,
                  style: Sf.t(size: 13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Text(
                  '${value.round()} / ${goal.target}',
                  textAlign: TextAlign.center,
                  style: Sf.monoStyle(size: 27, weight: FontWeight.w700),
                ),
                Slider(
                  value: value.clamp(0, goal.target.toDouble()),
                  min: 0,
                  max: goal.target.toDouble(),
                  divisions: goal.target.clamp(1, 100),
                  label: '${value.round()}',
                  onChanged: (next) => setDialogState(() => value = next),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, value.round()),
              child: const Text('Saqlash'),
            ),
          ],
        ),
      ),
    );
    if (changed != null) {
      state.updateGoal(goal.id, changed);
      if (context.mounted) {
        sfToast(context, 'Maqsad yangilandi', tone: Sf.success);
      }
    }
  }
}

class _SubjectProgressCard extends StatelessWidget {
  final bool showComparison;

  const _SubjectProgressCard({required this.showComparison});

  @override
  Widget build(BuildContext context) {
    const data = [
      ('Algebra', 0.92, 0.78, Sf.primary),
      ('Geometriya', 0.84, 0.76, Sf.accent),
      ('Ingliz tili', 0.88, 0.81, Sf.success),
    ];
    return SectionCard(
      title: 'Fanlar bo‘yicha natija',
      child: Column(
        children: [
          for (var index = 0; index < data.length; index++)
            Padding(
              padding: EdgeInsets.only(
                top: index == 0 ? 5 : 14,
                bottom: index == data.length - 1 ? 8 : 0,
              ),
              child: _ProgressBarRow(
                label: data[index].$1,
                value: data[index].$2,
                comparison: showComparison ? data[index].$3 : null,
                color: data[index].$4,
              ),
            ),
          if (showComparison)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Container(width: 18, height: 5, color: Sf.muted2),
                  const SizedBox(width: 7),
                  Text(
                    'Sinf o‘rtachasi',
                    style: Sf.t(size: 10.5, color: Sf.muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressBarRow extends StatelessWidget {
  final String label;
  final double value;
  final double? comparison;
  final Color color;

  const _ProgressBarRow({
    required this.label,
    required this.value,
    required this.comparison,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label natijasi ${(value * 100).round()} foiz',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Sf.t(size: 13, weight: FontWeight.w700),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: Sf.monoStyle(
                  size: 13,
                  weight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: Sf.surface2,
                  color: color,
                ),
              ),
              if (comparison != null)
                FractionallySizedBox(
                  widthFactor: comparison,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(width: 3, height: 10, color: Sf.ink2),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard();

  @override
  Widget build(BuildContext context) {
    const values = [32.0, 45.0, 20.0, 58.0, 48.0, 70.0, 36.0];
    const days = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    return SectionCard(
      title: '7 kunlik faollik · daqiqa',
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var index = 0; index < values.length; index++)
              Expanded(
                child: Semantics(
                  label: '${days[index]} ${values[index].round()} daqiqa',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${values[index].round()}',
                          style: Sf.monoStyle(
                            size: 9.5,
                            weight: FontWeight.w500,
                            color: Sf.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          height: values[index],
                          decoration: BoxDecoration(
                            color: index == 5 ? Sf.primary : Sf.accentSoft,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          days[index],
                          style: Sf.t(size: 10, color: Sf.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final StudyGoal goal;
  final bool last;
  final VoidCallback onUpdate;

  const _GoalTile({
    required this.goal,
    required this.last,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final completed = goal.current >= goal.target;
    return InkWell(
      onTap: onUpdate,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: Sf.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  completed ? Icons.emoji_events_rounded : Icons.flag_rounded,
                  size: 20,
                  color: completed ? Sf.accent : Sf.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    goal.title,
                    style: Sf.t(size: 12.5, weight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${goal.current}/${goal.target}',
                  style: Sf.monoStyle(
                    size: 11,
                    weight: FontWeight.w600,
                    color: completed ? Sf.success : Sf.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 7,
                backgroundColor: Sf.surface2,
                color: completed ? Sf.success : Sf.primary,
              ),
            ),
            const SizedBox(height: 5),
            Text(goal.subject, style: Sf.t(size: 10.5, color: Sf.muted)),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final bool isParent;

  const _InsightCard({required this.isParent});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: isParent ? 'Ota-ona uchun xulosa' : 'Haftalik xulosa',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AiBadge(label: 'Tahlil'),
          const SizedBox(height: 10),
          Text(
            isParent
                ? 'Akmal Algebra bo‘yicha kuchli o‘sdi. Geometriyada ikki vazifani vaqtida yakunlashiga yordam kerak.'
                : 'Algebra natijangiz 8 foizga oshdi. Geometriya uchun haftada yana ikki fokus seansi qo‘shing.',
            style: Sf.serif(size: 15, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Sf.successSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: Sf.success,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'O‘tgan haftaga nisbatan +6%',
                    style: Sf.t(
                      size: 12,
                      weight: FontWeight.w700,
                      color: Sf.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
