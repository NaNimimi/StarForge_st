import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'screens.dart';
import 'theme.dart';
import 'widgets.dart';

// ─────────────────────────── GRADES ───────────────────────────

class GradesScreen extends StatefulWidget {
  final AppRole role;

  const GradesScreen({super.key, required this.role});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _subject = 'Barchasi';
  String _period = 'Chorak';
  bool _newestFirst = true;
  double _nextScore = 90;

  static const _grades = [
    _GradeRecord(
      id: 'g1',
      title: 'Kvadrat tenglamalar testi',
      subject: 'Algebra',
      score: 94,
      maxScore: 100,
      date: '24 Iyul',
      teacher: 'Nigora Karimova',
      feedback:
          'Yechim bosqichlari aniq. Tekshiruvni ham yozishda davom eting.',
    ),
    _GradeRecord(
      id: 'g2',
      title: 'Uchburchaklar nazorat ishi',
      subject: 'Geometriya',
      score: 82,
      maxScore: 100,
      date: '21 Iyul',
      teacher: 'Bobur Aliyev',
      feedback: 'Isbotning ikkinchi qadamida asosni ko‘rsatish kerak.',
    ),
    _GradeRecord(
      id: 'g3',
      title: 'Unit 8 vocabulary',
      subject: 'Ingliz tili',
      score: 88,
      maxScore: 100,
      date: '18 Iyul',
      teacher: 'Aziz Tursunov',
      feedback: 'Yangi so‘zlar yaxshi o‘zlashtirilgan.',
    ),
    _GradeRecord(
      id: 'g4',
      title: 'Funksiyalar mustaqil ishi',
      subject: 'Algebra',
      score: 86,
      maxScore: 100,
      date: '15 Iyul',
      teacher: 'Nigora Karimova',
      feedback: 'Grafikdagi nuqtalarni aniqroq belgilang.',
    ),
    _GradeRecord(
      id: 'g5',
      title: 'Speaking practice',
      subject: 'Ingliz tili',
      score: 91,
      maxScore: 100,
      date: '11 Iyul',
      teacher: 'Aziz Tursunov',
      feedback: 'Talaffuz va gap tuzilishi juda yaxshi.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final periodGrades = switch (_period) {
      'Hafta' => _grades.take(2).toList(),
      'Oy' => _grades.take(4).toList(),
      _ => _grades,
    };
    final visible = periodGrades.where((grade) {
      final query = _query.trim().toLowerCase();
      final queryMatches =
          query.isEmpty ||
          '${grade.title} ${grade.subject} ${grade.teacher}'
              .toLowerCase()
              .contains(query);
      final subjectMatches =
          _subject == 'Barchasi' || grade.subject == _subject;
      return queryMatches && subjectMatches;
    }).toList();
    if (!_newestFirst) {
      final reversed = visible.reversed.toList();
      visible
        ..clear()
        ..addAll(reversed);
    }

    final average =
        periodGrades.map((grade) => grade.percent).reduce((a, b) => a + b) /
        periodGrades.length;
    final highest = periodGrades
        .map((grade) => grade.percent)
        .reduce((a, b) => a > b ? a : b);
    final projected =
        (average * periodGrades.length + _nextScore) /
        (periodGrades.length + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: widget.role == AppRole.parent
              ? 'Akmal · 9-B'
              : 'Mening baholarim',
          title: const Text('Baholar'),
          sub: 'Natijalar, ustoz izohlari va keyingi baho prognozi',
          right: SoftButton(
            'Hisobotni nusxalash',
            icon: Icons.copy_all_rounded,
            primary: true,
            onTap: () =>
                _copyReport(context, average, highest, periodGrades.length),
          ),
        ),
        SfGrid(
          minTile: 145,
          children: [
            KpiCard(
              label: 'O‘rtacha',
              value: '${average.round()}%',
              valueColor: Sf.success,
              icon: Icons.analytics_rounded,
            ),
            KpiCard(
              label: 'Eng yuqori',
              value: '${highest.round()}%',
              valueColor: Sf.primary,
              icon: Icons.emoji_events_rounded,
            ),
            KpiCard(
              label: 'Baholangan ish',
              value: '${periodGrades.length}',
              valueColor: Sf.accentInk,
              icon: Icons.fact_check_rounded,
            ),
            KpiCard(
              label: 'Prognoz',
              value: '${projected.round()}%',
              valueColor: projected >= average ? Sf.success : Sf.warn,
              icon: Icons.auto_graph_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Izlash va saralash',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Nazorat ishi, fan yoki ustoz...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Izlashni tozalash',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final period in const ['Hafta', 'Oy', 'Chorak'])
                    ChoiceChip(
                      label: Text(period),
                      selected: _period == period,
                      onSelected: (_) => setState(() => _period = period),
                    ),
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<String>(
                      initialValue: _subject,
                      isExpanded: true,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Fan',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Barchasi',
                          child: Text('Barcha fanlar'),
                        ),
                        DropdownMenuItem(
                          value: 'Algebra',
                          child: Text('Algebra'),
                        ),
                        DropdownMenuItem(
                          value: 'Geometriya',
                          child: Text('Geometriya'),
                        ),
                        DropdownMenuItem(
                          value: 'Ingliz tili',
                          child: Text('Ingliz tili'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _subject = value ?? _subject),
                    ),
                  ),
                  FilterChip(
                    selected: !_newestFirst,
                    avatar: Icon(
                      _newestFirst
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 18,
                    ),
                    label: Text(_newestFirst ? 'Yangi avval' : 'Eski avval'),
                    onSelected: (_) =>
                        setState(() => _newestFirst = !_newestFirst),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SfTwoCol(
          breakpoint: 1040,
          leftFlex: 15,
          rightFlex: 9,
          left: SectionCard(
            title: 'Baholar · ${visible.length}',
            bodyPadding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: visible.isEmpty
                ? _GradesEmpty(
                    onReset: () {
                      _searchController.clear();
                      setState(() {
                        _query = '';
                        _subject = 'Barchasi';
                      });
                    },
                  )
                : Column(
                    children: [
                      for (var index = 0; index < visible.length; index++)
                        _GradeTile(
                          grade: visible[index],
                          last: index == visible.length - 1,
                          onTap: () => _showGrade(context, visible[index]),
                        ),
                    ],
                  ),
          ),
          right: SfCol([
            const _GradeTrendCard(),
            SectionCard(
              title: 'Keyingi baho prognozi',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Keyingi ish: ${_nextScore.round()}%',
                    textAlign: TextAlign.center,
                    style: Sf.monoStyle(size: 22, weight: FontWeight.w700),
                  ),
                  Slider(
                    value: _nextScore,
                    min: 50,
                    max: 100,
                    divisions: 10,
                    label: '${_nextScore.round()}%',
                    onChanged: (value) => setState(() => _nextScore = value),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: projected >= average
                          ? Sf.successSoft
                          : Sf.warnSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      'Yangi o‘rtacha: ${projected.toStringAsFixed(1)}%',
                      textAlign: TextAlign.center,
                      style: Sf.t(
                        size: 13,
                        weight: FontWeight.w800,
                        color: projected >= average ? Sf.success : Sf.warn,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    projected >= 90
                        ? 'Maqsadga yetish uchun shu natijani saqlang.'
                        : '90% maqsad uchun Algebra va Geometriya xatolarini takrorlang.',
                    style: Sf.t(size: 11.5, color: Sf.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Future<void> _copyReport(
    BuildContext context,
    double average,
    double highest,
    int count,
  ) async {
    await Clipboard.setData(
      ClipboardData(
        text:
            'StarForge EDU · Akmal baholari\n'
            '$_period o‘rtachasi: ${average.toStringAsFixed(1)}%\n'
            'Eng yuqori: ${highest.round()}%\n'
            'Baholangan ishlar: $count',
      ),
    );
    if (context.mounted) {
      sfToast(context, 'Baholar hisoboti nusxalandi', tone: Sf.success);
    }
  }

  Future<void> _showGrade(BuildContext context, _GradeRecord grade) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(grade.title),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Pill(grade.subject, tone: Tone.primary),
                  Pill(grade.date, tone: Tone.neutral),
                  Pill(
                    '${grade.score}/${grade.maxScore}',
                    tone: grade.percent >= 85 ? Tone.success : Tone.warn,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Ustoz izohi',
                style: Sf.t(size: 12.5, weight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '“${grade.feedback}”',
                style: Sf.serif(size: 16, height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(grade.teacher, style: Sf.t(size: 11.5, color: Sf.muted)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Yopish'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              sfToast(
                context,
                'Ustozga savol uchun xabar tayyorlandi',
                tone: Sf.success,
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Savol berish'),
          ),
        ],
      ),
    );
  }
}

class _GradeRecord {
  final String id;
  final String title;
  final String subject;
  final int score;
  final int maxScore;
  final String date;
  final String teacher;
  final String feedback;

  const _GradeRecord({
    required this.id,
    required this.title,
    required this.subject,
    required this.score,
    required this.maxScore,
    required this.date,
    required this.teacher,
    required this.feedback,
  });

  double get percent => score / maxScore * 100;
}

class _GradeTile extends StatelessWidget {
  final _GradeRecord grade;
  final bool last;
  final VoidCallback onTap;

  const _GradeTile({
    required this.grade,
    required this.last,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = grade.percent >= 90
        ? Sf.success
        : grade.percent >= 80
        ? Sf.warn
        : Sf.danger;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: Sf.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                '${grade.percent.round()}',
                style: Sf.monoStyle(
                  size: 16,
                  weight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Sf.t(size: 13.5, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${grade.subject} · ${grade.date} · ${grade.teacher}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Sf.t(size: 10.5, color: Sf.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Sf.muted),
          ],
        ),
      ),
    );
  }
}

class _GradesEmpty extends StatelessWidget {
  final VoidCallback onReset;

  const _GradesEmpty({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 42, color: Sf.muted2),
          const SizedBox(height: 8),
          Text(
            'Mos baho topilmadi',
            style: Sf.t(size: 13.5, weight: FontWeight.w700),
          ),
          TextButton(
            onPressed: onReset,
            child: const Text('Filtrlarni tozalash'),
          ),
        ],
      ),
    );
  }
}

class _GradeTrendCard extends StatelessWidget {
  const _GradeTrendCard();

  @override
  Widget build(BuildContext context) {
    const values = [78, 84, 86, 88, 94];
    return SectionCard(
      title: 'So‘nggi 5 natija',
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var index = 0; index < values.length; index++)
              Expanded(
                child: Semantics(
                  label: '${index + 1}-natija ${values[index]} foiz',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${values[index]}',
                          style: Sf.monoStyle(
                            size: 10,
                            weight: FontWeight.w600,
                            color: Sf.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: values[index] * 0.9,
                          decoration: BoxDecoration(
                            color: index == values.length - 1
                                ? Sf.success
                                : Sf.primarySoft,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(7),
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
      ),
    );
  }
}

// ─────────────────────────── CALENDAR ───────────────────────────

class CalendarScreen extends StatefulWidget {
  final AppRole role;

  const CalendarScreen({super.key, required this.role});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime(2026, 7);
  DateTime _selectedDate = DateTime(2026, 7, 25);
  String _category = 'Barchasi';
  bool _personalOnly = false;

  static final _schoolEvents = [
    _CalendarItem(
      id: 'event-algebra-test',
      title: 'Algebra nazorat ishi',
      category: 'Imtihon',
      date: DateTime(2026, 7, 28),
      time: '09:00',
      location: 'Xona 304',
      color: Sf.danger,
      description: 'Kvadrat tenglamalar va funksiyalar mavzusi.',
    ),
    _CalendarItem(
      id: 'event-olympiad',
      title: 'Matematika olimpiadasi',
      category: 'Tadbir',
      date: DateTime(2026, 7, 30),
      time: '14:00',
      location: 'Akt zal',
      color: Sf.accent,
      description: 'Maktab bosqichi. Ro‘yxatdan o‘tish 29 Iyulgacha.',
    ),
    _CalendarItem(
      id: 'event-parent-meeting',
      title: 'Ota-onalar uchrashuvi',
      category: 'Uchrashuv',
      date: DateTime(2026, 7, 31),
      time: '18:30',
      location: 'Online',
      color: Sf.primary,
      description: 'Chorak natijalari va keyingi o‘quv rejasi.',
    ),
    _CalendarItem(
      id: 'event-english-quiz',
      title: 'English Unit 8 quiz',
      category: 'Imtihon',
      date: DateTime(2026, 8, 3),
      time: '11:30',
      location: 'Xona 112',
      color: Sf.success,
      description: 'Vocabulary, listening va speaking.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final allEvents = [
      ..._schoolEvents,
      for (final event in state.personalEvents)
        _CalendarItem(
          id: event.id,
          title: event.title,
          category: event.category,
          date: event.date,
          time: event.time,
          location: 'Shaxsiy',
          color: Sf.ai,
          description: event.notes,
          isPersonal: true,
        ),
    ];
    final filtered = allEvents.where((event) {
      final categoryMatches =
          _category == 'Barchasi' || event.category == _category;
      final personalMatches = !_personalOnly || event.isPersonal;
      return categoryMatches && personalMatches;
    }).toList();
    final selectedEvents =
        filtered
            .where((event) => DateUtils.isSameDay(event.date, _selectedDate))
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));
    final today = DateUtils.dateOnly(DateTime.now());
    final upcoming =
        allEvents.where((event) => !event.date.isBefore(today)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: widget.role == AppRole.parent
              ? 'Oila taqvimi'
              : 'Mening rejam',
          title: const Text('Taqvim'),
          sub:
              '${allEvents.length} ta voqea · ${state.calendarReminders.length} ta eslatma',
          right: SoftButton(
            'Shaxsiy voqea',
            icon: Icons.add_rounded,
            primary: true,
            onTap: () => _addEvent(context, state, allEvents),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton.outlined(
              tooltip: 'Oldingi oy',
              onPressed: () => _shiftMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            OutlinedButton(
              onPressed: () => setState(() {
                _month = DateTime(2026, 7);
                _selectedDate = DateTime(2026, 7, 25);
              }),
              child: Text('${_monthName(_month.month)} ${_month.year}'),
            ),
            IconButton.outlined(
              tooltip: 'Keyingi oy',
              onPressed: () => _shiftMonth(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            for (final category in const [
              'Barchasi',
              'Imtihon',
              'Tadbir',
              'Uchrashuv',
            ])
              ChoiceChip(
                label: Text(category),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              ),
            FilterChip(
              selected: _personalOnly,
              avatar: const Icon(Icons.person_rounded, size: 18),
              label: const Text('Faqat shaxsiy'),
              onSelected: (value) => setState(() => _personalOnly = value),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SfTwoCol(
          breakpoint: 980,
          leftFlex: 14,
          rightFlex: 10,
          left: SectionCard(
            title: '${_monthName(_month.month)} taqvimi',
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 430) {
                  return _CompactDatePicker(
                    month: _month,
                    selected: _selectedDate,
                    events: filtered,
                    onSelected: (date) => setState(() => _selectedDate = date),
                  );
                }
                return _MonthGrid(
                  month: _month,
                  selected: _selectedDate,
                  events: filtered,
                  onSelected: (date) => setState(() => _selectedDate = date),
                );
              },
            ),
          ),
          right: SfCol([
            SectionCard(
              title:
                  '${_selectedDate.day} ${_monthName(_selectedDate.month)} · ${selectedEvents.length}',
              child: selectedEvents.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.event_available_rounded,
                            size: 42,
                            color: Sf.success,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bu kunda voqea yo‘q',
                            style: Sf.t(size: 13.5, weight: FontWeight.w700),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                _addEvent(context, state, allEvents),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Voqea qo‘shish'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        for (
                          var index = 0;
                          index < selectedEvents.length;
                          index++
                        )
                          _CalendarEventTile(
                            event: selectedEvents[index],
                            reminded: state.calendarReminders.contains(
                              selectedEvents[index].id,
                            ),
                            last: index == selectedEvents.length - 1,
                            onTap: () => _showEvent(
                              context,
                              selectedEvents[index],
                              state,
                            ),
                          ),
                      ],
                    ),
            ),
            if (upcoming.isNotEmpty)
              _ExamCountdownCard(
                days: upcoming.first.date.difference(today).inDays,
                title: upcoming.first.title,
                dateLabel:
                    '${upcoming.first.date.day} ${_monthName(upcoming.first.date.month)} · ${upcoming.first.time}',
              ),
          ]),
        ),
      ],
    );
  }

  void _shiftMonth(int delta) {
    final month = DateTime(_month.year, _month.month + delta);
    setState(() {
      _month = month;
      _selectedDate = DateTime(month.year, month.month);
    });
  }

  Future<void> _addEvent(
    BuildContext context,
    AppState state,
    List<_CalendarItem> existing,
  ) async {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    var category = 'Shaxsiy';
    var time = '17:00';
    var date = _selectedDate;
    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Shaxsiy voqea qo‘shish'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Voqea nomi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: category,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Tur',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Shaxsiy',
                              child: Text('Shaxsiy'),
                            ),
                            DropdownMenuItem(
                              value: 'Tayyorgarlik',
                              child: Text('Tayyorgarlik'),
                            ),
                            DropdownMenuItem(
                              value: 'Uchrashuv',
                              child: Text('Uchrashuv'),
                            ),
                          ],
                          onChanged: (value) => setDialogState(
                            () => category = value ?? category,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: time,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Vaqt',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '09:00',
                              child: Text('09:00'),
                            ),
                            DropdownMenuItem(
                              value: '14:00',
                              child: Text('14:00'),
                            ),
                            DropdownMenuItem(
                              value: '17:00',
                              child: Text('17:00'),
                            ),
                            DropdownMenuItem(
                              value: '19:00',
                              child: Text('19:00'),
                            ),
                          ],
                          onChanged: (value) =>
                              setDialogState(() => time = value ?? time),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2026, 1),
                        lastDate: DateTime(2027, 12, 31),
                      );
                      if (picked != null && context.mounted) {
                        setDialogState(() => date = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: Text(
                      '${date.day} ${_monthName(date.month)} ${date.year}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Izoh',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.length < 3) {
                  sfToast(
                    context,
                    'Nom kamida 3 ta belgidan iborat bo‘lsin',
                    tone: Sf.warn,
                  );
                  return;
                }
                final conflict = existing.any(
                  (event) =>
                      DateUtils.isSameDay(event.date, date) &&
                      event.time == time,
                );
                if (conflict) {
                  sfToast(
                    context,
                    'Bu vaqtda boshqa voqea bor',
                    sub: 'Boshqa vaqtni tanlang.',
                    tone: Sf.danger,
                  );
                  return;
                }
                state.addPersonalEvent(
                  PersonalCalendarEvent(
                    id: 'personal-event-${DateTime.now().millisecondsSinceEpoch}',
                    title: title,
                    category: category,
                    date: date,
                    time: time,
                    notes: notesController.text.trim(),
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
    notesController.dispose();
    if (added == true && context.mounted) {
      setState(() {
        _month = DateTime(date.year, date.month);
        _selectedDate = date;
      });
      sfToast(context, 'Shaxsiy voqea qo‘shildi', tone: Sf.success);
    }
  }

  Future<void> _showEvent(
    BuildContext context,
    _CalendarItem event,
    AppState state,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Sf.surface,
      builder: (sheetContext) => ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final reminded = state.calendarReminders.contains(event.id);
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: event.color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.event_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: Sf.t(size: 19, weight: FontWeight.w800),
                          ),
                          Text(
                            '${event.date.day} ${_monthName(event.date.month)} · ${event.time}',
                            style: Sf.t(size: 12, color: Sf.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(event.description, style: Sf.t(size: 13, height: 1.45)),
                const SizedBox(height: 8),
                Text(
                  event.location,
                  style: Sf.t(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: event.color,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: reminded,
                  onChanged: (_) {
                    state.toggleCalendarReminder(event.id);
                    sfToast(
                      context,
                      reminded ? 'Eslatma o‘chirildi' : 'Eslatma yoqildi',
                      tone: reminded ? Sf.muted : Sf.success,
                    );
                  },
                  title: const Text('Eslatma'),
                  subtitle: const Text('Voqeadan 30 daqiqa oldin'),
                ),
                if (event.isPersonal)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Voqeani o‘chirish'),
                          content: Text('“${event.title}” o‘chirilsinmi?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Bekor qilish'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: Sf.danger,
                              ),
                              child: const Text('O‘chirish'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        state.removePersonalEvent(event.id);
                        Navigator.pop(sheetContext);
                        sfToast(
                          context,
                          'Shaxsiy voqea o‘chirildi',
                          tone: Sf.danger,
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Shaxsiy voqeani o‘chirish'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CalendarItem {
  final String id;
  final String title;
  final String category;
  final DateTime date;
  final String time;
  final String location;
  final Color color;
  final String description;
  final bool isPersonal;

  const _CalendarItem({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.time,
    required this.location,
    required this.color,
    required this.description,
    this.isPersonal = false,
  });
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final List<_CalendarItem> events;
  final ValueChanged<DateTime> onSelected;

  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.events,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const weekdays = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    final first = DateTime(month.year, month.month);
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final offset = first.weekday - 1;
    final cells = ((offset + days + 6) ~/ 7) * 7;
    return Column(
      children: [
        Row(
          children: [
            for (final day in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: Sf.t(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: Sf.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 54,
          ),
          itemCount: cells,
          itemBuilder: (context, index) {
            final day = index - offset + 1;
            if (day < 1 || day > days) return const SizedBox();
            final date = DateTime(month.year, month.month, day);
            final dayEvents = events.where(
              (event) => DateUtils.isSameDay(event.date, date),
            );
            final isSelected = DateUtils.isSameDay(date, selected);
            return Padding(
              padding: const EdgeInsets.all(2),
              child: Material(
                color: isSelected ? Sf.primary : Sf.surface2,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => onSelected(date),
                  borderRadius: BorderRadius.circular(10),
                  child: Semantics(
                    selected: isSelected,
                    label: '$day, ${dayEvents.length} ta voqea',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: Sf.monoStyle(
                            size: 11,
                            weight: FontWeight.w700,
                            color: isSelected ? Colors.white : Sf.ink,
                          ),
                        ),
                        if (dayEvents.isNotEmpty)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : dayEvents.first.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CompactDatePicker extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final List<_CalendarItem> events;
  final ValueChanged<DateTime> onSelected;

  const _CompactDatePicker({
    required this.month,
    required this.selected,
    required this.events,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final date = DateTime(month.year, month.month, index + 1);
          final selectedDay = DateUtils.isSameDay(date, selected);
          final hasEvent = events.any(
            (event) => DateUtils.isSameDay(event.date, date),
          );
          return Material(
            color: selectedDay ? Sf.primary : Sf.surface2,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => onSelected(date),
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 52,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${index + 1}',
                      style: Sf.monoStyle(
                        size: 15,
                        weight: FontWeight.w700,
                        color: selectedDay ? Colors.white : Sf.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      hasEvent ? Icons.circle : Icons.circle_outlined,
                      size: 7,
                      color: selectedDay ? Colors.white : Sf.accent,
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
}

class _CalendarEventTile extends StatelessWidget {
  final _CalendarItem event;
  final bool reminded;
  final bool last;
  final VoidCallback onTap;

  const _CalendarEventTile({
    required this.event,
    required this.reminded,
    required this.last,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: Sf.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: event.color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                event.time,
                style: Sf.monoStyle(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: event.color,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Sf.t(size: 12.5, weight: FontWeight.w700),
                  ),
                  Text(
                    '${event.category} · ${event.location}',
                    style: Sf.t(size: 10.5, color: Sf.muted),
                  ),
                ],
              ),
            ),
            if (reminded)
              const Icon(
                Icons.notifications_active_rounded,
                size: 18,
                color: Sf.success,
              ),
            const Icon(Icons.chevron_right_rounded, color: Sf.muted),
          ],
        ),
      ),
    );
  }
}

class _ExamCountdownCard extends StatelessWidget {
  final int days;
  final String title;
  final String dateLabel;

  const _ExamCountdownCard({
    required this.days,
    required this.title,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Keyingi muhim voqea',
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Sf.dangerSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$days',
              style: Sf.monoStyle(
                size: 24,
                weight: FontWeight.w700,
                color: Sf.danger,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Sf.t(size: 13.5, weight: FontWeight.w800)),
                Text(
                  days == 0 ? 'Bugun · $dateLabel' : '$days kun · $dateLabel',
                  style: Sf.t(size: 11.5, color: Sf.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── ANNOUNCEMENTS ───────────────────────────

class AnnouncementsScreen extends StatefulWidget {
  final AppRole role;

  const AnnouncementsScreen({super.key, required this.role});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'Barchasi';
  bool _pinnedOnly = false;

  static const _announcements = [
    _Announcement(
      id: 'announcement-olympiad',
      title: 'Matematika olimpiadasiga ro‘yxatdan o‘tish',
      body:
          'Maktab bosqichi 30 Iyul kuni soat 14:00 da bo‘lib o‘tadi. Ishtirok etish uchun 29 Iyulgacha ustozga yozing.',
      category: 'Tanlov',
      author: 'Nigora Karimova',
      date: 'Bugun · 10:15',
      icon: Icons.emoji_events_rounded,
      color: Sf.accent,
      important: true,
    ),
    _Announcement(
      id: 'announcement-meeting',
      title: 'Ota-onalar uchrashuvi',
      body:
          '31 Iyul soat 18:30 da online uchrashuv. Havola tadbirdan 30 daqiqa oldin yuboriladi.',
      category: 'Uchrashuv',
      author: 'StarForge ma’muriyati',
      date: 'Kecha · 16:40',
      icon: Icons.groups_rounded,
      color: Sf.primary,
      important: true,
    ),
    _Announcement(
      id: 'announcement-library',
      title: 'Yangi elektron kutubxona materiallari',
      body: 'Algebra va ingliz tili bo‘yicha 12 ta yangi material qo‘shildi.',
      category: 'Yangilik',
      author: 'O‘quv bo‘limi',
      date: '23 Iyul',
      icon: Icons.local_library_rounded,
      color: Sf.success,
    ),
    _Announcement(
      id: 'announcement-welcome',
      title: 'StarForge yozgi jadvali',
      body:
          'Iyul–Avgust oylarida darslar yangilangan yozgi jadval asosida o‘tkaziladi.',
      category: 'Jadval',
      author: 'StarForge ma’muriyati',
      date: '20 Iyul',
      icon: Icons.calendar_month_rounded,
      color: Sf.warn,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final unread = _announcements
        .where((item) => !state.readAnnouncements.contains(item.id))
        .length;
    final visible =
        _announcements.where((item) {
          final query = _query.trim().toLowerCase();
          final queryMatches =
              query.isEmpty ||
              '${item.title} ${item.body} ${item.author}'
                  .toLowerCase()
                  .contains(query);
          final categoryMatches =
              _category == 'Barchasi' || item.category == _category;
          final pinnedMatches =
              !_pinnedOnly || state.pinnedAnnouncements.contains(item.id);
          return queryMatches && categoryMatches && pinnedMatches;
        }).toList()..sort((a, b) {
          final aPinned = state.pinnedAnnouncements.contains(a.id);
          final bPinned = state.pinnedAnnouncements.contains(b.id);
          if (aPinned == bPinned) return 0;
          return aPinned ? -1 : 1;
        });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: widget.role == AppRole.parent
              ? 'Oila uchun'
              : 'Maktab hayoti',
          title: const Text('E’lonlar'),
          sub: '$unread ta o‘qilmagan · ${_announcements.length} ta jami',
          right: SoftButton(
            'Barchasini o‘qish',
            icon: Icons.done_all_rounded,
            onTap: unread == 0
                ? () => sfToast(
                    context,
                    'Barcha e’lonlar o‘qilgan',
                    tone: Sf.success,
                  )
                : () {
                    state.markAllAnnouncementsRead(
                      _announcements.map((item) => item.id),
                    );
                    sfToast(
                      context,
                      'Barcha e’lonlar o‘qildi',
                      tone: Sf.success,
                    );
                  },
          ),
        ),
        SectionCard(
          title: 'Izlash va filtrlash',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'E’lon nomi yoki matni...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Izlashni tozalash',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in const [
                    'Barchasi',
                    'Tanlov',
                    'Uchrashuv',
                    'Yangilik',
                    'Jadval',
                  ])
                    ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  FilterChip(
                    selected: _pinnedOnly,
                    avatar: const Icon(Icons.push_pin_rounded, size: 18),
                    label: const Text('Mahkamlangan'),
                    onSelected: (value) => setState(() => _pinnedOnly = value),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'E’lonlar · ${visible.length}',
          bodyPadding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: visible.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.campaign_outlined,
                        size: 44,
                        color: Sf.muted2,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mos e’lon topilmadi',
                        style: Sf.t(size: 13.5, weight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _category = 'Barchasi';
                            _pinnedOnly = false;
                          });
                        },
                        child: const Text('Filtrlarni tozalash'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (var index = 0; index < visible.length; index++)
                      _AnnouncementTile(
                        item: visible[index],
                        read: state.readAnnouncements.contains(
                          visible[index].id,
                        ),
                        pinned: state.pinnedAnnouncements.contains(
                          visible[index].id,
                        ),
                        last: index == visible.length - 1,
                        onPin: () =>
                            state.togglePinnedAnnouncement(visible[index].id),
                        onOpen: () =>
                            _showAnnouncement(context, visible[index], state),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _showAnnouncement(
    BuildContext context,
    _Announcement item,
    AppState state,
  ) {
    state.markAnnouncementRead(item.id);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(item.icon, color: item.color),
            const SizedBox(width: 9),
            Expanded(child: Text(item.title)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Pill(item.category, tone: Tone.primary),
                  if (item.important)
                    const Pill('Muhim', tone: Tone.danger, dot: true),
                ],
              ),
              const SizedBox(height: 15),
              Text(item.body, style: Sf.t(size: 13.5, height: 1.5)),
              const SizedBox(height: 13),
              Text(
                '${item.author} · ${item.date}',
                style: Sf.t(size: 11.5, color: Sf.muted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: '${item.title}\n\n${item.body}'),
              );
              if (context.mounted) {
                sfToast(context, 'E’lon nusxalandi', tone: Sf.success);
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Nusxalash'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tushundim'),
          ),
        ],
      ),
    );
  }
}

class _Announcement {
  final String id;
  final String title;
  final String body;
  final String category;
  final String author;
  final String date;
  final IconData icon;
  final Color color;
  final bool important;

  const _Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.author,
    required this.date,
    required this.icon,
    required this.color,
    this.important = false,
  });
}

class _AnnouncementTile extends StatelessWidget {
  final _Announcement item;
  final bool read;
  final bool pinned;
  final bool last;
  final VoidCallback onPin;
  final VoidCallback onOpen;

  const _AnnouncementTile({
    required this.item,
    required this.read,
    required this.pinned,
    required this.last,
    required this.onPin,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: read
            ? Colors.transparent
            : Sf.primarySoft.withValues(alpha: 0.2),
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Sf.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(item.icon, color: item.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (!read) ...[
                                const Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: Sf.primary,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Sf.t(
                                    size: 13.5,
                                    weight: read
                                        ? FontWeight.w600
                                        : FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.category} · ${item.author} · ${item.date}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Sf.t(size: 10.5, color: Sf.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: pinned ? 'Mahkamlashni bekor qilish' : 'Mahkamlash',
            onPressed: onPin,
            icon: Icon(
              pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: pinned ? Sf.primary : Sf.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── SUPPORT ───────────────────────────

class SupportScreen extends StatefulWidget {
  final AppRole role;

  const SupportScreen({super.key, required this.role});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'Barchasi';
  int _rating = 0;

  static const _faqs = [
    _Faq(
      question: 'Vazifani qanday yuboraman?',
      answer:
          'Vazifalar bo‘limida topshiriqni oching, “Yechimni biriktirish” tugmasini bosing va “Bajarildi” holatini tanlang.',
      category: 'Vazifalar',
    ),
    _Faq(
      question: 'Davomatdagi xatoni kimga yozaman?',
      answer:
          'Davomat yozuvini oching. Ota-ona rolida sabab yuborish mumkin; boshqa xatolar uchun ustozga Xabarlar orqali yozing.',
      category: 'Davomat',
    ),
    _Faq(
      question: 'To‘lov ikki marta yechiladimi?',
      answer:
          'Demo to‘lov bir marta qabul qilinadi. Production tizimda server idempotency key va provider callback tekshiruvi majburiy.',
      category: 'To‘lov',
    ),
    _Faq(
      question: 'AI javobini to‘liq ishonchli deb bo‘ladimi?',
      answer:
          'Yo‘q. AI yordamchi vosita. Muhim topshiriq, formula va xulosalarni ustoz yoki ishonchli manba bilan tekshiring.',
      category: 'AI',
    ),
    _Faq(
      question: 'Matnni kattalashtirish mumkinmi?',
      answer:
          'Sozlamalar → Qulaylik va maxfiylik bo‘limida “Katta matn”ni yoqing. Ilova tizim masshtabini ham saqlaydi.',
      category: 'Sozlamalar',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final visible = _faqs.where((faq) {
      final query = _query.trim().toLowerCase();
      final queryMatches =
          query.isEmpty ||
          '${faq.question} ${faq.answer}'.toLowerCase().contains(query);
      final categoryMatches =
          _category == 'Barchasi' || faq.category == _category;
      return queryMatches && categoryMatches;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: widget.role == AppRole.parent ? 'Ota-ona yordami' : 'Yordam',
          title: const Text('Yordam markazi'),
          sub: 'FAQ, diagnostika va murojaatlar',
          right: SoftButton(
            'Murojaat yuborish',
            icon: Icons.support_agent_rounded,
            primary: true,
            onTap: () => _createTicket(context, state),
          ),
        ),
        SfTwoCol(
          breakpoint: 1040,
          leftFlex: 14,
          rightFlex: 10,
          left: SfCol([
            SectionCard(
              title: 'Ko‘p so‘raladigan savollar',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Savol yoki kalit so‘z...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Izlashni tozalash',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final category in const [
                        'Barchasi',
                        'Vazifalar',
                        'Davomat',
                        'To‘lov',
                        'AI',
                        'Sozlamalar',
                      ])
                        ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          onSelected: (_) =>
                              setState(() => _category = category),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.help_outline_rounded,
                            size: 42,
                            color: Sf.muted2,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mos javob topilmadi',
                            style: Sf.t(size: 13.5, weight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: () => _createTicket(context, state),
                            child: const Text('Murojaat yuborish'),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final faq in visible)
                      Material(
                        color: Colors.transparent,
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(
                            left: 8,
                            right: 8,
                            bottom: 14,
                          ),
                          title: Text(
                            faq.question,
                            style: Sf.t(size: 13, weight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            faq.category,
                            style: Sf.t(size: 10.5, color: Sf.muted),
                          ),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                faq.answer,
                                style: Sf.t(
                                  size: 12.5,
                                  height: 1.45,
                                  color: Sf.ink2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
            SectionCard(
              title: 'Yordam sifatini baholang',
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      for (var value = 1; value <= 5; value++)
                        IconButton(
                          tooltip: '$value baho',
                          onPressed: () {
                            setState(() => _rating = value);
                            sfToast(
                              context,
                              'Rahmat! $value/5 baho qabul qilindi',
                              tone: Sf.success,
                            );
                          },
                          icon: Icon(
                            value <= _rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: value <= _rating ? Sf.accent : Sf.muted,
                          ),
                        ),
                    ],
                  ),
                  if (_rating > 0)
                    Text(
                      'Sizning bahoyingiz: $_rating/5',
                      style: Sf.t(
                        size: 12,
                        weight: FontWeight.w700,
                        color: Sf.success,
                      ),
                    ),
                ],
              ),
            ),
          ]),
          right: SfCol([
            SectionCard(
              title: 'Tezkor diagnostika',
              child: Column(
                children: [
                  const _DiagnosticRow(
                    label: 'Ilova holati',
                    value: 'Ishlamoqda',
                    tone: Tone.success,
                  ),
                  const _DiagnosticRow(
                    label: 'Ma’lumot rejimi',
                    value: 'Demo · seans',
                    tone: Tone.warn,
                  ),
                  const _DiagnosticRow(
                    label: 'Platforma',
                    value: 'Flutter',
                    tone: Tone.primary,
                    last: true,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _copyDiagnostics(context),
                    icon: const Icon(Icons.content_copy_rounded),
                    label: const Text('Diagnostikani nusxalash'),
                  ),
                ],
              ),
            ),
            SectionCard(
              title: 'Murojaatlar · ${state.supportTickets.length}',
              action: IconButton(
                tooltip: 'Yangi murojaat',
                onPressed: () => _createTicket(context, state),
                icon: const Icon(Icons.add_rounded),
              ),
              child: state.supportTickets.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.mark_email_read_outlined,
                            size: 40,
                            color: Sf.muted2,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hozircha murojaat yo‘q',
                            style: Sf.t(size: 13, weight: FontWeight.w700),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        for (
                          var index = 0;
                          index < state.supportTickets.length;
                          index++
                        )
                          _TicketTile(
                            ticket: state.supportTickets[index],
                            last: index == state.supportTickets.length - 1,
                            onCopy: () => _copyTicket(
                              context,
                              state.supportTickets[index],
                            ),
                          ),
                      ],
                    ),
            ),
          ]),
        ),
      ],
    );
  }

  Future<void> _createTicket(BuildContext context, AppState state) async {
    final messageController = TextEditingController();
    var topic = 'Texnik muammo';
    var priority = 'Oddiy';
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yordamga murojaat'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: topic,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Mavzu',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Texnik muammo',
                        child: Text('Texnik muammo'),
                      ),
                      DropdownMenuItem(
                        value: 'Ma’lumot xatosi',
                        child: Text('Ma’lumot xatosi'),
                      ),
                      DropdownMenuItem(
                        value: 'To‘lov savoli',
                        child: Text('To‘lov savoli'),
                      ),
                      DropdownMenuItem(value: 'Taklif', child: Text('Taklif')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => topic = value ?? topic),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Oddiy', label: Text('Oddiy')),
                      ButtonSegment(value: 'Muhim', label: Text('Muhim')),
                    ],
                    selected: {priority},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) =>
                        setDialogState(() => priority = value.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    autofocus: true,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Muammoni tasvirlang',
                      hintText: 'Nima bo‘ldi va qaysi ekranda?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Bekor qilish'),
            ),
            FilledButton.icon(
              onPressed: () {
                final message = messageController.text.trim();
                if (message.length < 10) {
                  sfToast(
                    context,
                    'Kamida 10 ta belgi bilan tushuntiring',
                    tone: Sf.warn,
                  );
                  return;
                }
                state.createSupportTicket(
                  SupportTicket(
                    id: 'SF-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
                    topic: topic,
                    message: message,
                    priority: priority,
                    createdAt: DateTime.now(),
                  ),
                );
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Yuborish'),
            ),
          ],
        ),
      ),
    );
    messageController.dispose();
    if (created == true && context.mounted) {
      sfToast(
        context,
        'Murojaat qabul qilindi',
        sub: state.supportTickets.first.id,
        tone: Sf.success,
      );
    }
  }

  Future<void> _copyDiagnostics(BuildContext context) async {
    const diagnostics =
        'StarForge EDU diagnostics\n'
        'Mode: demo/session\n'
        'Framework: Flutter\n'
        'Role state: local\n'
        'PII: not included';
    await Clipboard.setData(const ClipboardData(text: diagnostics));
    if (context.mounted) {
      sfToast(context, 'Diagnostika nusxalandi', tone: Sf.success);
    }
  }

  Future<void> _copyTicket(BuildContext context, SupportTicket ticket) async {
    await Clipboard.setData(
      ClipboardData(
        text:
            '${ticket.id}\n${ticket.topic}\n${ticket.priority}\n${ticket.status}',
      ),
    );
    if (context.mounted) {
      sfToast(context, 'Murojaat raqami nusxalandi', tone: Sf.success);
    }
  }
}

class _Faq {
  final String question;
  final String answer;
  final String category;

  const _Faq({
    required this.question,
    required this.answer,
    required this.category,
  });
}

class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;
  final Tone tone;
  final bool last;

  const _DiagnosticRow({
    required this.label,
    required this.value,
    required this.tone,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Sf.border)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Sf.t(size: 12.5))),
          Pill(value, tone: tone, dot: true),
        ],
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final SupportTicket ticket;
  final bool last;
  final VoidCallback onCopy;

  const _TicketTile({
    required this.ticket,
    required this.last,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Sf.border)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Sf.successSoft,
            foregroundColor: Sf.success,
            child: Icon(Icons.support_agent_rounded),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.topic,
                  style: Sf.t(size: 12.5, weight: FontWeight.w700),
                ),
                Text(
                  '${ticket.id} · ${ticket.status}',
                  style: Sf.t(size: 10.5, color: Sf.muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Raqamni nusxalash',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }
}

String _monthName(int month) => const [
  '',
  'Yanvar',
  'Fevral',
  'Mart',
  'Aprel',
  'May',
  'Iyun',
  'Iyul',
  'Avgust',
  'Sentabr',
  'Oktabr',
  'Noyabr',
  'Dekabr',
][month];
