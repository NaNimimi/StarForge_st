part of 'portal_app.dart';

class _RebuiltHomePortalPage extends StatelessWidget {
  const _RebuiltHomePortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    return portal.isParent
        ? _buildParent(context, portal)
        : _buildStudent(context, portal);
  }

  Widget _buildStudent(BuildContext context, PortalController portal) {
    final attendance = valueMap(portal.report['attendance']);
    final payment = valueMap(portal.report['payment']);
    final rank = valueMap(portal.report['rank']);
    final lessons = valueRows(portal.dashboard['next_lessons']);
    final homework = valueRows(portal.dashboard['open_homework']);
    final grades = valueRows(portal.dashboard['recent_grades']);
    final rate = (double.tryParse('${attendance['rate']}') ?? 0)
        .clamp(0.0, 1.0)
        .toDouble();
    final openCount =
        valueInt(portal.dashboard['open_homework_count']) ?? homework.length;
    final average = grades.isEmpty
        ? 0.0
        : grades.map(_gradePercentage).reduce((a, b) => a + b) / grades.length;
    return _PortalPage(
      title: 'Bugungi marshrut',
      subtitle: 'Eng muhim darslar, vazifalar va natijalar bir ekranda.',
      section: PortalSection.home,
      trailing: _LiveBadge(
        label: valueText(portal.dashboard, const [
          'group',
        ], fallback: 'Guruh biriktirilmagan'),
        icon: Icons.groups_2_outlined,
      ),
      children: [
        _CockpitHero(
          parent: false,
          name: portal.displayName.split(' ').first,
          contextTitle: valueText(portal.dashboard, const [
            'group',
          ], fallback: 'Mustaqil o‘quvchi'),
          primaryItem: lessons.firstOrNull,
          attentionTitle: openCount == 0
              ? 'Reja toza'
              : '$openCount ta vazifa kutmoqda',
          attentionBody: homework.isEmpty
              ? 'Barcha topshiriqlar nazorat ostida.'
              : '${valueText(homework.first, const ['title'])} · ${_dateLabel(homework.first['due_at'], time: true)}',
        ),
        const SizedBox(height: 16),
        _CockpitMetricStrip(
          items: [
            _CockpitMetricData(
              label: 'Ochiq vazifa',
              value: '$openCount',
              note: homework.isEmpty
                  ? 'Hammasi bajarilgan'
                  : 'Muddatni kuzating',
              icon: Icons.task_alt_rounded,
              color: Sf.primary,
            ),
            _CockpitMetricData(
              label: 'Davomat',
              value: attendance['rate'] == null
                  ? '—'
                  : '${(rate * 100).round()}%',
              note:
                  '${attendance['present'] ?? 0} / ${attendance['of'] ?? 0} dars',
              icon: Icons.how_to_reg_rounded,
              color: Sf.success,
            ),
            _CockpitMetricData(
              label: 'O‘rtacha natija',
              value: grades.isEmpty ? '—' : '${average.round()}%',
              note: rank.isEmpty
                  ? '${grades.length} ta so‘nggi baho'
                  : 'Sinfda ${rank['rank']} / ${rank['of']}',
              icon: Icons.insights_rounded,
              color: Sf.accent,
            ),
            _CockpitMetricData(
              label: 'Oilaviy balans',
              value: _money(
                payment['outstanding_uzs'] ??
                    portal.dashboard['outstanding_uzs'],
              ),
              note: 'Joriy qarzdorlik',
              icon: Icons.account_balance_wallet_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _HomeActionRail(
          title: 'Tezkor o‘tish',
          items: [
            if (portal.can('assignments:read'))
              _HomeActionData(
                label: 'Vazifalar',
                detail: openCount == 0
                    ? 'Yangi vazifa yo‘q'
                    : '$openCount ta ochiq vazifa',
                icon: Icons.assignment_outlined,
                color: Sf.primary,
                section: PortalSection.assignments,
              ),
            if (portal.can('schedule:read'))
              _HomeActionData(
                label: 'Dars jadvali',
                detail: lessons.isEmpty
                    ? 'Bugun dars yo‘q'
                    : '${lessons.length} ta yaqin dars',
                icon: Icons.calendar_month_outlined,
                color: Sf.success,
                section: PortalSection.schedule,
              ),
            if (portal.can('academics:read'))
              _HomeActionData(
                label: 'Natijalar',
                detail: grades.isEmpty
                    ? 'Natija kiritilmagan'
                    : '${grades.length} ta so‘nggi baho',
                icon: Icons.query_stats_rounded,
                color: Sf.accent,
                section: PortalSection.academics,
              ),
            if (portal.can('messaging:read'))
              const _HomeActionData(
                label: 'Ustoz bilan chat',
                detail: 'Savol yoki fayl yuboring',
                icon: Icons.forum_outlined,
                color: Sf.success,
                section: PortalSection.messages,
              ),
          ],
        ),
        const SizedBox(height: 16),
        _CockpitColumns(
          primary: _TodayStack(lessons: lessons, homework: homework),
          secondary: _PerformancePanel(
            title: 'O‘qish pulsi',
            rate: rate,
            ringLabel: 'Davomat',
            ringDetail:
                '${attendance['present'] ?? 0} / ${attendance['of'] ?? 0} darsda qatnashgan.',
            items: [
              for (final grade in grades.take(4))
                _PortalBarDatum(
                  label: valueText(grade, const ['exam'], fallback: 'Natija'),
                  value: _gradePercentage(grade),
                  detail:
                      '${grade['score'] ?? '—'} / ${grade['max_score'] ?? '—'} · ${_dateLabel(grade['exam_date'])}',
                  color: Theme.of(context).colorScheme.primary,
                  icon: Icons.school_outlined,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParent(BuildContext context, PortalController portal) {
    final attendance = valueMap(portal.report['attendance']);
    final payment = valueMap(portal.report['payment']);
    final rank = valueMap(portal.report['rank']);
    final sheet = valueRows(attendance['sheet']);
    final selected = portal.children
        .where((item) => valueInt(item['id']) == portal.selectedStudentId)
        .firstOrNull;
    final outstanding =
        double.tryParse('${payment['outstanding_uzs'] ?? 0}') ?? 0;
    final needsPaymentAttention = outstanding > 0;
    final rate = (double.tryParse('${attendance['rate']}') ?? 0)
        .clamp(0.0, 1.0)
        .toDouble();
    final hasAttendanceEvidence = (valueInt(attendance['of']) ?? 0) > 0;
    final hasPaymentEvidence = payment.containsKey('outstanding_uzs');
    final evidenceComplete = hasAttendanceEvidence && hasPaymentEvidence;
    final needsAttendanceAttention = hasAttendanceEvidence && rate < 0.8;
    final attentionCritical = needsPaymentAttention || needsAttendanceAttention;
    return _PortalPage(
      title: 'Oila nazorat markazi',
      subtitle:
          'Farzandingizning davomat, o‘zlashtirish va moliyaviy holati bir joyda.',
      section: PortalSection.home,
      trailing: MediaQuery.sizeOf(context).width >= 840
          ? null
          : portal.children.length > 1
          ? _ChildContextSelector(portal: portal)
          : _LiveBadge(
              label: valueText(selected ?? const {}, const [
                'full_name',
              ], fallback: 'Farzand'),
              icon: Icons.family_restroom_rounded,
            ),
      children: [
        if (portal.children.isEmpty)
          const _EmptyState(
            icon: Icons.family_restroom_rounded,
            title: 'Farzand biriktirilmagan',
            message:
                'Markaz administratori akkauntni o‘quvchiga bog‘lashi kerak.',
          )
        else ...[
          _CockpitHero(
            parent: true,
            name: valueText(selected ?? const {}, const [
              'full_name',
            ], fallback: 'Farzand'),
            contextTitle:
                '${valueText(selected ?? const {}, const ['student_id'])} · ${valueText(selected ?? const {}, const ['academic_level'], fallback: 'Daraja belgilanmagan')}',
            attentionCritical: attentionCritical,
            attentionKnown: evidenceComplete,
            attentionTitle: needsPaymentAttention
                ? 'To‘lovga e’tibor kerak'
                : needsAttendanceAttention
                ? 'Davomatni kuzatish kerak'
                : evidenceComplete
                ? 'Jiddiy ogohlantirish yo‘q'
                : 'Holat baholanmoqda',
            attentionBody: needsPaymentAttention
                ? '${_money(payment['outstanding_uzs'])} ochiq qarzdorlik mavjud.'
                : needsAttendanceAttention
                ? 'Joriy davomat ${(rate * 100).round()}% — tafsilotlarni tekshiring.'
                : evidenceComplete
                ? 'Davomat va to‘lov ko‘rsatkichlari me’yorda.'
                : 'Xulosa uchun davomat va to‘lov ma’lumotlari yetarli emas.',
          ),
          const SizedBox(height: 16),
          _CockpitMetricStrip(
            items: [
              _CockpitMetricData(
                label: 'Davomat',
                value: attendance['rate'] == null
                    ? '—'
                    : '${(rate * 100).round()}%',
                note: 'Kechikish bilan birga',
                icon: Icons.fact_check_outlined,
                color: Sf.success,
              ),
              _CockpitMetricData(
                label: 'Qatnashgan',
                value:
                    '${attendance['present'] ?? 0} / ${attendance['of'] ?? 0}',
                note: 'Davomat jurnalida',
                icon: Icons.how_to_reg_outlined,
                color: Sf.primary,
              ),
              _CockpitMetricData(
                label: 'Sinfdagi o‘rni',
                value: rank.isEmpty ? '—' : '${rank['rank']} / ${rank['of']}',
                note: rank.isEmpty
                    ? 'Markaz yashirgan'
                    : 'O‘rtacha ${rank['average_pct'] ?? '—'}%',
                icon: Icons.leaderboard_outlined,
                color: Sf.accent,
              ),
              _CockpitMetricData(
                label: 'Ochiq to‘lov',
                value: _money(payment['outstanding_uzs']),
                note: 'Oilaviy balans',
                icon: Icons.payments_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _HomeActionRail(
            title: 'Oila uchun tezkor amallar',
            items: [
              const _HomeActionData(
                label: 'Farzand profili',
                detail: 'Aloqalar va hujjatlar',
                icon: Icons.supervisor_account_outlined,
                color: Sf.primary,
                section: PortalSection.identity,
              ),
              if (portal.can('assignments:read'))
                const _HomeActionData(
                  label: 'Farzand vazifalari',
                  detail: 'Muddat va topshirish holati',
                  icon: Icons.assignment_outlined,
                  color: Sf.warn,
                  section: PortalSection.assignments,
                ),
              if (portal.can('attendance:read'))
                _HomeActionData(
                  label: 'Davomat tafsiloti',
                  detail: '${attendance['present'] ?? 0} ta qatnashuv',
                  icon: Icons.fact_check_outlined,
                  color: Sf.success,
                  section: PortalSection.attendance,
                ),
              if (portal.can('academics:read'))
                const _HomeActionData(
                  label: 'O‘zlashtirish',
                  detail: 'Baholar va dinamika',
                  icon: Icons.insights_outlined,
                  color: Sf.accent,
                  section: PortalSection.academics,
                ),
              if (portal.can('finance:read_own'))
                _HomeActionData(
                  label: 'To‘lovlar',
                  detail: needsPaymentAttention
                      ? 'Ochiq balansni ko‘ring'
                      : 'Qarzdorlik mavjud emas',
                  icon: Icons.account_balance_wallet_outlined,
                  color: needsPaymentAttention
                      ? Theme.of(context).colorScheme.error
                      : Sf.success,
                  section: PortalSection.finance,
                )
              else if (portal.can('messaging:read'))
                const _HomeActionData(
                  label: 'Maktab bilan chat',
                  detail: 'Savol yoki fayl yuboring',
                  icon: Icons.forum_outlined,
                  color: Sf.success,
                  section: PortalSection.messages,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _CockpitColumns(
            primary: _FamilyActivityPanel(rows: sheet),
            secondary: _PerformancePanel(
              title: 'Davomat taqsimoti',
              rate: rate,
              ringLabel: 'Qatnashuv',
              ringDetail:
                  '${attendance['present'] ?? 0} / ${attendance['of'] ?? 0} darsda qatnashgan.',
              items: _attendanceBars(sheet, Theme.of(context).colorScheme),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChildContextSelector extends StatelessWidget {
  const _ChildContextSelector({required this.portal});

  final PortalController portal;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Tanlangan farzand',
    child: Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.family_restroom_rounded,
            size: 17,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: portal.selectedStudentId,
                isExpanded: true,
                icon: portal.selectingStudentId == null
                    ? const Icon(Icons.keyboard_arrow_down_rounded)
                    : const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                items: [
                  for (final child in portal.children)
                    if (valueInt(child['id']) case final id?)
                      DropdownMenuItem(
                        value: id,
                        child: Text(
                          valueText(child, const ['full_name', 'student_id']),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                ],
                onChanged: portal.selectingStudentId != null
                    ? null
                    : (value) {
                        if (value != null) portal.selectChild(value);
                      },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    ),
  );
}

class _CockpitHero extends StatelessWidget {
  const _CockpitHero({
    required this.parent,
    required this.name,
    required this.contextTitle,
    required this.attentionTitle,
    required this.attentionBody,
    this.primaryItem,
    this.attentionCritical = false,
    this.attentionKnown = true,
  });

  final bool parent;
  final String name;
  final String contextTitle;
  final String attentionTitle;
  final String attentionBody;
  final Map<String, Object?>? primaryItem;
  final bool attentionCritical;
  final bool attentionKnown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    final focusAccent = parent && !attentionKnown
        ? Sf.warn
        : parent && !attentionCritical
        ? Sf.successSoft
        : accent;
    final lessonTitle = valueText(primaryItem ?? const {}, const [
      'title',
    ], fallback: 'Bugun boshqa dars yo‘q');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Sf.ink,
            Color.alphaBlend(accent.withValues(alpha: 0.44), Sf.ink),
            Color.alphaBlend(scheme.secondary.withValues(alpha: 0.16), Sf.ink),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                parent ? 'TANLANGAN FARZAND' : 'BUGUN / ${_dashboardDate()}',
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                parent ? name : 'Salom, $name',
                style: Sf.serif(
                  size: compact ? 28 : 31,
                  color: Sf.surface,
                  height: 1.03,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                contextTitle,
                style: const TextStyle(
                  color: Color(0xFFC9C0AF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
          final focus = Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      parent
                          ? !attentionKnown
                                ? Icons.hourglass_top_rounded
                                : attentionCritical
                                ? Icons.priority_high_rounded
                                : Icons.verified_rounded
                          : Icons.bolt_rounded,
                      color: focusAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        parent
                            ? !attentionKnown
                                  ? 'MA’LUMOT KUTILMOQDA'
                                  : attentionCritical
                                  ? 'E’TIBOR MARKAZI'
                                  : 'HOLAT BARQAROR'
                            : 'KEYINGI QADAM',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: focusAccent,
                          fontSize: 9.5,
                          letterSpacing: 1.25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  parent ? attentionTitle : lessonTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Sf.surface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  parent
                      ? attentionBody
                      : primaryItem == null
                      ? attentionBody
                      : '${_dateLabel(primaryItem!['starts_at'], time: true)} · ${valueText(primaryItem!, const ['teacher_name'], fallback: 'Ustoz')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC9C0AF),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [intro, const SizedBox(height: 20), focus],
            );
          }
          return Row(
            children: [
              Expanded(flex: 6, child: intro),
              const SizedBox(width: 28),
              Expanded(flex: 4, child: focus),
            ],
          );
        },
      ),
    );
  }
}

String _dashboardDate() {
  final now = DateTime.now();
  const months = [
    'YAN',
    'FEV',
    'MAR',
    'APR',
    'MAY',
    'IYN',
    'IYL',
    'AVG',
    'SEN',
    'OKT',
    'NOY',
    'DEK',
  ];
  return '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]}';
}

class _CockpitMetricData {
  const _CockpitMetricData({
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String note;
  final IconData icon;
  final Color color;
}

class _CockpitMetricStrip extends StatelessWidget {
  const _CockpitMetricStrip({required this.items});

  final List<_CockpitMetricData> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final count = constraints.maxWidth >= 1000 ? 4 : 2;
      const gap = 10.0;
      final width = (constraints.maxWidth - gap * (count - 1)) / count;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final item in items)
            SizedBox(
              width: width,
              child: _CockpitMetricCard(item: item),
            ),
        ],
      );
    },
  );
}

class _CockpitMetricCard extends StatelessWidget {
  const _CockpitMetricCard({required this.item});

  final _CockpitMetricData item;

  @override
  Widget build(BuildContext context) => _SectionCard(
    padding: const EdgeInsets.all(13),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 17),
            ),
            const Spacer(),
            Icon(Icons.north_east_rounded, size: 15, color: item.color),
          ],
        ),
        const SizedBox(height: 11),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            item.value,
            style: Sf.monoStyle(size: 20, weight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Sf.eyebrow(),
        ),
        const SizedBox(height: 4),
        Text(
          item.note,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _HomeActionData {
  const _HomeActionData({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.section,
  });

  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final PortalSection section;
}

class _HomeActionRail extends StatelessWidget {
  const _HomeActionRail({required this.title, required this.items});

  final String title;
  final List<_HomeActionData> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (MediaQuery.sizeOf(context).width >= 600) ...[
                const SizedBox(width: 12),
                Text(
                  'Kerakli bo‘limga bir bosishda',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth >= 920
                  ? items.length.clamp(1, 4).toInt()
                  : constraints.maxWidth >= 520
                  ? 2
                  : 1;
              const gap = 10.0;
              final width = (constraints.maxWidth - gap * (count - 1)) / count;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: width,
                      child: _HomeActionTile(item: item),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeActionTile extends StatelessWidget {
  const _HomeActionTile({required this.item});

  final _HomeActionData item;

  @override
  Widget build(BuildContext context) => Material(
    color: item.color.withValues(alpha: 0.075),
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () => _PortalNavigationScope.go(context, item.section),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    item.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_outward_rounded, size: 17, color: item.color),
          ],
        ),
      ),
    ),
  );
}

class _CockpitColumns extends StatelessWidget {
  const _CockpitColumns({required this.primary, required this.secondary});

  final Widget primary;
  final Widget secondary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 860) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [primary, const SizedBox(height: 16), secondary],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 11, child: primary),
          const SizedBox(width: 16),
          Expanded(flex: 9, child: secondary),
        ],
      );
    },
  );
}

class _TodayStack extends StatelessWidget {
  const _TodayStack({required this.lessons, required this.homework});

  final List<Map<String, Object?>> lessons;
  final List<Map<String, Object?>> homework;

  @override
  Widget build(BuildContext context) => _SectionCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DensePanelHeader(
          title: 'Bugungi reja',
          meta: '${lessons.length} dars · ${homework.length} vazifa',
          icon: Icons.view_timeline_outlined,
        ),
        const SizedBox(height: 12),
        if (lessons.isEmpty && homework.isEmpty)
          const _CompactEmpty(message: 'Bugungi reja bo‘sh — dam olish vaqti.')
        else ...[
          for (final lesson in lessons.take(3))
            _TimelineRow(
              time: _timeOnly(lesson['starts_at']),
              title: valueText(lesson, const ['title']),
              subtitle:
                  '${valueText(lesson, const ['teacher_name'], fallback: 'Ustoz')} · ${valueText(lesson, const ['room_name'], fallback: 'Xona belgilanmagan')}',
              color: Theme.of(context).colorScheme.primary,
            ),
          for (final task in homework.take(2))
            _TimelineRow(
              time: 'TASK',
              title: valueText(task, const ['title']),
              subtitle: 'Muddat ${_dateLabel(task['due_at'], time: true)}',
              color: Sf.warn,
            ),
        ],
      ],
    ),
  );
}

class _FamilyActivityPanel extends StatelessWidget {
  const _FamilyActivityPanel({required this.rows});

  final List<Map<String, Object?>> rows;

  @override
  Widget build(BuildContext context) => _SectionCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DensePanelHeader(
          title: 'So‘nggi faollik',
          meta: '${rows.length} davomat yozuvi',
          icon: Icons.history_rounded,
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const _CompactEmpty(message: 'Hali yangi davomat yozuvi yo‘q.')
        else
          for (final row in rows.take(5))
            _TimelineRow(
              time: _dateLabel(row['date']).split('.').first,
              title: valueText(row, const ['lesson'], fallback: 'Dars'),
              subtitle: _dateLabel(row['date'], time: true),
              color: switch ('${row['status']}') {
                'present' => Sf.success,
                'late' => Sf.warn,
                _ => Theme.of(context).colorScheme.error,
              },
              trailing: _StatusPill(
                valueText(row, const ['status']),
                positive: row['status'] == 'present',
                warning: row['status'] == 'late',
              ),
            ),
      ],
    ),
  );
}

class _PerformancePanel extends StatelessWidget {
  const _PerformancePanel({
    required this.title,
    required this.rate,
    required this.ringLabel,
    required this.ringDetail,
    required this.items,
  });

  final String title;
  final double rate;
  final String ringLabel;
  final String ringDetail;
  final List<_PortalBarDatum> items;

  @override
  Widget build(BuildContext context) => _SectionCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DensePanelHeader(
          title: title,
          meta: items.isEmpty
              ? 'Yangi ma’lumot kutilmoqda'
              : '${items.length} ko‘rsatkich',
          icon: Icons.donut_small_rounded,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final chart = items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: _CompactEmpty(
                      message: 'Tahlil uchun hali ma’lumot yetarli emas.',
                    ),
                  )
                : _CompactBarChart(items: items.take(4).toList());
            final ring = _InteractiveRingChart(
              value: rate,
              label: ringLabel,
              detail: ringDetail,
              size: 94,
              color: Theme.of(context).colorScheme.primary,
            );
            final enlargedText =
                MediaQuery.textScalerOf(context).scale(1) > 1.3;
            if (constraints.maxWidth < 390 || enlargedText) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.centerLeft, child: ring),
                  const SizedBox(height: 14),
                  chart,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ring,
                const SizedBox(width: 14),
                Expanded(child: chart),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _DensePanelHeader extends StatelessWidget {
  const _DensePanelHeader({
    required this.title,
    required this.meta,
    required this.icon,
  });

  final String title;
  final String meta;
  final IconData icon;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final enlargedText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final titleRow = Row(
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      );
      if (constraints.maxWidth < 420 || enlargedText) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleRow,
            const SizedBox(height: 5),
            Text(meta, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: titleRow),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              meta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
    },
  );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.color,
    this.trailing,
  });

  final String time;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(time, style: Sf.monoStyle(size: 10.5, color: color)),
        ),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    ),
  );
}

class _CompactEmpty extends StatelessWidget {
  const _CompactEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

// Retained for deterministic legacy golden fixtures; connected runtime uses
// [_RebuiltHomePortalPage].
// ignore: unused_element
class _HomePortalPage extends StatelessWidget {
  const _HomePortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    return portal.isParent
        ? _parent(context, portal)
        : _student(context, portal);
  }

  Widget _student(BuildContext context, PortalController portal) {
    final attendanceReport = valueMap(portal.report['attendance']);
    final payment = valueMap(portal.report['payment']);
    final rank = valueMap(portal.report['rank']);
    final upcoming = valueRows(portal.dashboard['next_lessons']);
    final homework = valueRows(portal.dashboard['open_homework']);
    final recentGrades = valueRows(portal.dashboard['recent_grades']);
    final attendanceRate = (double.tryParse('${attendanceReport['rate']}') ?? 0)
        .clamp(0.0, 1.0)
        .toDouble();
    final openHomework =
        valueInt(portal.dashboard['open_homework_count']) ?? homework.length;
    final colors = Theme.of(context).colorScheme;
    return _PortalPage(
      title: 'Salom, ${portal.displayName.split(' ').first}',
      subtitle: 'Bugungi o‘qish holati serverdagi haqiqiy ma’lumotlar asosida.',
      section: PortalSection.home,
      children: [
        _ResponsiveGrid(
          children: [
            _RichMetricCard(
              title: 'Ochiq vazifalar',
              value: '$openHomework',
              icon: Icons.assignment_outlined,
              eyebrow: 'BUGUNGI REJA',
              caption: openHomework == 0
                  ? 'Barcha vazifalar nazorat ostida'
                  : 'Topshirish muddati yaqin ishlar',
              accent: colors.tertiary,
              progress: openHomework == 0 ? 1 : (1 / (openHomework + 1)),
            ),
            _RichMetricCard(
              title: 'Davomat',
              value: attendanceReport['rate'] == null
                  ? '—'
                  : '${(attendanceRate * 100).round()}%',
              icon: Icons.fact_check_outlined,
              eyebrow: '90 KUN',
              caption: 'Kechikishlar ham qatnashgan sifatida hisoblangan',
              accent: Sf.success,
              progress: attendanceRate,
              trend:
                  '${attendanceReport['present'] ?? 0} / ${attendanceReport['of'] ?? 0}',
            ),
            _RichMetricCard(
              title: 'Guruh',
              value: valueText(portal.dashboard, const [
                'group',
              ], fallback: 'Biriktirilmagan'),
              icon: Icons.groups_outlined,
              eyebrow: 'JAMOA',
              caption: 'Joriy o‘quv guruhi',
              accent: colors.primary,
              progress: portal.dashboard['group'] == null ? 0 : 1,
            ),
            _RichMetricCard(
              title: 'Qarzdorlik',
              value: _money(
                payment['outstanding_uzs'] ??
                    portal.dashboard['outstanding_uzs'],
              ),
              icon: Icons.account_balance_wallet_outlined,
              eyebrow: 'MOLIYA',
              caption: 'Oilaviy kabinetdagi joriy hisob',
              accent: colors.error,
            ),
          ],
        ),
        if (attendanceReport.isNotEmpty || recentGrades.isNotEmpty) ...[
          const SizedBox(height: 16),
          _LearningInsightPanel(
            title: 'O‘qish pulsi',
            ringLabel: 'Qatnashuv',
            ringValue: attendanceRate,
            ringDetail:
                '${attendanceReport['present'] ?? 0} / ${attendanceReport['of'] ?? 0} darsda qatnashgan (kechikishlar bilan).',
            items: [
              for (final grade in recentGrades)
                _PortalBarDatum(
                  label: valueText(grade, const ['exam'], fallback: 'Natija'),
                  value: _gradePercentage(grade),
                  detail:
                      '${grade['score'] ?? '—'} / ${grade['max_score'] ?? '—'} · ${_dateLabel(grade['exam_date'])}',
                  color: colors.primary,
                  icon: Icons.school_outlined,
                ),
            ],
            emptyLabel: 'Yangi baholar paydo bo‘lganda fanlar grafigi to‘ladi.',
          ),
        ],
        if (rank.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InlineMessage(
            text:
                'Sinf reytingi: ${rank['rank']} / ${rank['of']} · o‘rtacha ${rank['average_pct']}%',
            error: false,
          ),
        ],
        const SizedBox(height: 24),
        _PageSectionTitle(title: 'Yaqin darslar', count: upcoming.length),
        const SizedBox(height: 10),
        if (upcoming.isEmpty)
          const _EmptyState(
            icon: Icons.event_available_outlined,
            title: 'Yaqin dars yo‘q',
            message: 'Reja yangilanganda darslar shu yerda ko‘rinadi.',
          )
        else
          _SimpleRows(
            rows: upcoming,
            icon: Icons.schedule_rounded,
            title: (row) => valueText(row, const ['title']),
            subtitle: (row) => _dateLabel(row['starts_at'], time: true),
          ),
        const SizedBox(height: 24),
        _PageSectionTitle(title: 'Yaqin vazifalar', count: homework.length),
        const SizedBox(height: 10),
        if (homework.isEmpty)
          const _EmptyState(
            icon: Icons.task_alt_rounded,
            title: 'Ochiq vazifa yo‘q',
            message: 'Hozircha barcha topshiriqlar bajarilgan.',
          )
        else
          _SimpleRows(
            rows: homework,
            icon: Icons.assignment_outlined,
            title: (row) => valueText(row, const ['title']),
            subtitle: (row) =>
                'Muddat: ${_dateLabel(row['due_at'], time: true)}',
          ),
        if (recentGrades.isNotEmpty) ...[
          const SizedBox(height: 24),
          _PageSectionTitle(
            title: 'So‘nggi natijalar',
            count: recentGrades.length,
          ),
          const SizedBox(height: 10),
          _SimpleRows(
            rows: recentGrades,
            icon: Icons.school_outlined,
            title: (row) => valueText(row, const ['exam']),
            subtitle: (row) =>
                '${row['score']} / ${row['max_score']} · ${_dateLabel(row['exam_date'])}',
          ),
        ],
      ],
    );
  }

  Widget _parent(BuildContext context, PortalController portal) {
    final attendance = valueMap(portal.report['attendance']);
    final payment = valueMap(portal.report['payment']);
    final rank = valueMap(portal.report['rank']);
    final sheet = valueRows(attendance['sheet']);
    final attendanceRate = (double.tryParse('${attendance['rate']}') ?? 0)
        .clamp(0.0, 1.0)
        .toDouble();
    final colors = Theme.of(context).colorScheme;
    final selected = portal.children
        .where((item) => valueInt(item['id']) == portal.selectedStudentId)
        .firstOrNull;
    return _PortalPage(
      title: 'Oila nazorati',
      subtitle: 'Farzandingizning o‘qish, davomat va moliyaviy holati.',
      section: PortalSection.home,
      trailing: portal.children.length > 1
          ? DropdownButton<int>(
              value: portal.selectedStudentId,
              items: [
                for (final child in portal.children)
                  if (valueInt(child['id']) case final id?)
                    DropdownMenuItem(
                      value: id,
                      child: Text(
                        valueText(child, const ['full_name', 'student_id']),
                      ),
                    ),
              ],
              onChanged: (value) {
                if (value != null) portal.selectChild(value);
              },
            )
          : null,
      children: [
        if (portal.children.isEmpty)
          const _EmptyState(
            icon: Icons.family_restroom_rounded,
            title: 'Farzand biriktirilmagan',
            message:
                'Markaz administratori ota-ona akkauntini o‘quvchiga biriktirishi kerak.',
          )
        else ...[
          _SectionCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    _initials(
                      valueText(selected ?? const {}, const ['full_name']),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        valueText(selected ?? const {}, const ['full_name']),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${valueText(selected ?? const {}, const ['student_id'])} · ${valueText(selected ?? const {}, const ['academic_level'], fallback: 'Daraja ko‘rsatilmagan')}',
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  valueText(selected ?? const {}, const ['status']),
                  positive: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ResponsiveGrid(
            children: [
              _RichMetricCard(
                title: 'Davomat',
                value: attendance['rate'] == null
                    ? '—'
                    : '${(attendanceRate * 100).round()}%',
                icon: Icons.fact_check_outlined,
                eyebrow: '90 KUNLIK NAZORAT',
                caption: 'Kechikish bilan qatnashilgan darslar',
                accent: Sf.success,
                progress: attendanceRate,
              ),
              _RichMetricCard(
                title: 'Qatnashgan',
                value:
                    '${attendance['present'] ?? 0} / ${attendance['of'] ?? 0}',
                icon: Icons.how_to_reg_outlined,
                eyebrow: 'DARSLAR',
                caption: 'Davomat jurnalidagi real yozuvlar',
                accent: colors.primary,
                progress: attendanceRate,
              ),
              _RichMetricCard(
                title: 'Qarzdorlik',
                value: _money(payment['outstanding_uzs']),
                icon: Icons.payments_outlined,
                eyebrow: 'TO‘LOVLAR',
                caption: 'Ochiq hisoblar bo‘yicha jami',
                accent: colors.error,
              ),
              _RichMetricCard(
                title: 'Sinf o‘rni',
                value: rank.isEmpty
                    ? 'Yashirilgan'
                    : '${rank['rank']} / ${rank['of']}',
                icon: Icons.leaderboard_outlined,
                eyebrow: 'REYTING',
                caption: rank.isEmpty
                    ? 'Markaz reytingni oiladan yashirgan'
                    : 'O‘rtacha ${rank['average_pct'] ?? '—'}%',
                accent: colors.tertiary,
                progress: rank.isEmpty
                    ? null
                    : 1 -
                          ((valueInt(rank['rank']) ?? 1) - 1) /
                              ((valueInt(rank['of']) ?? 1).clamp(1, 999)),
              ),
            ],
          ),
          if (attendance.isNotEmpty) ...[
            const SizedBox(height: 16),
            _LearningInsightPanel(
              title: 'Farzand o‘qish pulsi',
              ringLabel: 'Qatnashuv',
              ringValue: attendanceRate,
              ringDetail:
                  '${attendance['present'] ?? 0} / ${attendance['of'] ?? 0} darsda qatnashgan, kechikish qatnashuvga kiradi.',
              items: _attendanceBars(sheet, colors),
              emptyLabel: 'Davomat taqsimoti uchun hali yozuv yetarli emas.',
            ),
          ],
          const SizedBox(height: 24),
          _PageSectionTitle(title: 'So‘nggi davomat', count: sheet.length),
          const SizedBox(height: 10),
          if (sheet.isEmpty)
            const _EmptyState(
              icon: Icons.event_note_outlined,
              title: 'Davomat yozuvi yo‘q',
              message: 'Yangi belgilashlar shu yerda ko‘rinadi.',
            )
          else
            _SimpleRows(
              rows: sheet,
              icon: Icons.school_outlined,
              title: (row) => valueText(row, const ['lesson']),
              subtitle: (row) => _dateLabel(row['date'], time: true),
              trailing: (row) => _StatusPill(
                valueText(row, const ['status']),
                positive: row['status'] == 'present',
                warning: row['status'] == 'late',
              ),
            ),
        ],
      ],
    );
  }
}

class _LearningInsightPanel extends StatelessWidget {
  const _LearningInsightPanel({
    required this.title,
    required this.ringLabel,
    required this.ringValue,
    required this.ringDetail,
    required this.items,
    required this.emptyLabel,
  });

  final String title;
  final String ringLabel;
  final double ringValue;
  final String ringDetail;
  final List<_PortalBarDatum> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final ring = _InteractiveRingChart(
          value: ringValue,
          label: ringLabel,
          detail: ringDetail,
          color: colors.primary,
          size: constraints.maxWidth < 560 ? 108 : 128,
          centerIcon: Icons.insights_rounded,
        );
        final bars = items.isEmpty
            ? _SectionCard(
                child: SizedBox(
                  height: 130,
                  child: Center(
                    child: Text(
                      emptyLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            : _CompactBarChart(title: title, items: items);
        if (constraints.maxWidth < 720) {
          return Column(children: [ring, const SizedBox(height: 12), bars]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 218, child: ring),
            const SizedBox(width: 12),
            Expanded(child: bars),
          ],
        );
      },
    );
  }
}

double _gradePercentage(Map<String, Object?> grade) {
  final score =
      double.tryParse('${grade['score'] ?? grade['value_raw'] ?? 0}') ?? 0;
  final maximum = double.tryParse('${grade['max_score'] ?? 100}') ?? 100;
  if (maximum <= 0) return 0;
  return (score / maximum * 100).clamp(0, 100).toDouble();
}

List<_PortalBarDatum> _attendanceBars(
  List<Map<String, Object?>> rows,
  ColorScheme colors,
) {
  if (rows.isEmpty) return const [];
  const definitions = [
    ('present', 'O‘z vaqtida', Icons.check_circle_outline_rounded),
    ('late', 'Kechikib keldi', Icons.schedule_rounded),
    ('absent', 'Kelmadi', Icons.cancel_outlined),
    ('excused', 'Sababli', Icons.health_and_safety_outlined),
  ];
  return [
    for (final definition in definitions)
      if (rows.where((row) => row['status'] == definition.$1).length
          case final count when count > 0)
        _PortalBarDatum(
          label: definition.$2,
          value: count / rows.length * 100,
          detail: '$count / ${rows.length} davomat yozuvi',
          color: switch (definition.$1) {
            'present' => Sf.success,
            'late' => Sf.warn,
            'absent' => colors.error,
            _ => colors.tertiary,
          },
          icon: definition.$3,
        ),
  ];
}

class _AssignmentsPortalPage extends StatelessWidget {
  const _AssignmentsPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final submissionByAssignment = latestAssignmentSubmissions(
      portal.submissions,
    );
    final visible = portal.assignments
        .where(
          (item) => const {'published', 'closed'}.contains('${item['status']}'),
        )
        .toList();
    return _PortalPage(
      title: portal.isParent ? 'Farzand vazifalari' : 'Vazifalar',
      subtitle: portal.isParent
          ? 'Topshiriqlar, muddatlar va farzandingizning topshirish holati.'
          : 'Topshiriq tafsilotlari, muddat va serverdagi topshirish holati.',
      section: PortalSection.assignments,
      children: [
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'Jami topshiriq',
              value: '${visible.length}',
              icon: Icons.assignment_outlined,
            ),
            _MetricCard(
              label: 'Topshirilgan',
              value: '${submissionByAssignment.length}',
              icon: Icons.task_alt_rounded,
            ),
            _MetricCard(
              label: 'Baholangan',
              value:
                  '${submissionByAssignment.values.where((item) => valueMap(item['grade'])['graded'] == true).length}',
              icon: Icons.school_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          const _EmptyState(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Vazifa yo‘q',
            message: 'Ustoz yangi vazifa e’lon qilganda shu yerda chiqadi.',
          )
        else
          ...visible.map((assignment) {
            final id = valueInt(assignment['id']);
            final submission = id == null ? null : submissionByAssignment[id];
            final grade = valueMap(submission?['grade']);
            final canSubmit =
                portal.can('assignments:submit') &&
                assignmentAcceptsAnotherSubmission(assignment, submission);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          child: Text(
                            _initials(valueText(assignment, const ['title'])),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                valueText(assignment, const ['title']),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                valueText(assignment, const [
                                  'cohort_name',
                                ], fallback: 'Guruh'),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Muddat: ${_dateLabel(assignment['due_at'], time: true)}',
                              ),
                            ],
                          ),
                        ),
                        _StatusPill(
                          submission == null
                              ? valueText(assignment, const ['status'])
                              : valueText(submission, const ['status']),
                          positive: submission != null,
                        ),
                      ],
                    ),
                    if (valueText(assignment, const [
                      'description',
                    ], fallback: '').isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        valueText(assignment, const [
                          'description',
                        ], fallback: ''),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (grade['graded'] == true) ...[
                      const SizedBox(height: 12),
                      _InlineMessage(
                        text:
                            'Baho: ${grade['score']} / ${assignment['max_score']}\n${valueText(grade, const ['feedback'], fallback: 'Ustoz izoh qoldirmagan.')}',
                        error: false,
                      ),
                    ],
                    if (portal.isStudent) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonalIcon(
                          onPressed:
                              id == null || (submission == null && !canSubmit)
                              ? null
                              : () => showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  builder: (_) => PortalScope(
                                    controller: portal,
                                    child: _AssignmentSubmitSheet(
                                      assignment: assignment,
                                      submission: submission,
                                      allowSubmit: canSubmit,
                                    ),
                                  ),
                                ),
                          icon: Icon(
                            submission == null
                                ? Icons.upload_file_rounded
                                : canSubmit
                                ? Icons.replay_rounded
                                : Icons.visibility_outlined,
                          ),
                          label: Text(
                            submission == null
                                ? 'Topshirish'
                                : canSubmit
                                ? 'Qayta topshirish'
                                : 'Ishni ko‘rish',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _AssignmentSubmitSheet extends StatefulWidget {
  const _AssignmentSubmitSheet({
    required this.assignment,
    required this.allowSubmit,
    this.submission,
  });

  final Map<String, Object?> assignment;
  final Map<String, Object?>? submission;
  final bool allowSubmit;

  @override
  State<_AssignmentSubmitSheet> createState() => _AssignmentSubmitSheetState();
}

class _AssignmentSubmitSheetState extends State<_AssignmentSubmitSheet> {
  late final TextEditingController _text;
  final List<PlatformFile> _files = [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(
      text: valueText(widget.submission ?? const {}, const [
        'text',
      ], fallback: ''),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    setState(() {
      _files
        ..clear()
        ..addAll(result.files.take(5));
    });
  }

  Future<void> _submit() async {
    if (_text.text.trim().isEmpty && _files.isEmpty) {
      setState(() => _error = 'Matn yozing yoki fayl tanlang.');
      return;
    }
    final id = valueInt(widget.assignment['id']);
    if (id == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final portal = PortalScope.read(context);
      final keys = <String>[];
      for (final file in _files) {
        final bytes = file.bytes;
        if (bytes == null) {
          throw ApiException(message: '${file.name} faylini o‘qib bo‘lmadi.');
        }
        keys.add(
          await portal.uploadAssignmentFile(
            filename: file.name,
            contentType: _contentType(file.extension),
            bytes: bytes,
          ),
        );
      }
      await portal.submitAssignment(
        assignmentId: id,
        text: _text.text,
        attachmentKeys: keys,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vazifa serverga topshirildi.')),
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readOnly = !widget.allowSubmit;
    final grade = valueMap(widget.submission?['grade']);
    final aiFeedback = valueText(grade, const ['ai_feedback'], fallback: '');
    final attempt = valueInt(widget.submission?['attempt_number']);
    final maxResubmits = valueInt(widget.assignment['max_resubmits']);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        padding: const EdgeInsets.all(22),
        shrinkWrap: true,
        children: [
          Text(
            valueText(widget.assignment, const ['title']),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            valueText(widget.assignment, const [
              'description',
            ], fallback: 'Tavsif berilmagan.'),
          ),
          if (attempt != null) ...[
            const SizedBox(height: 12),
            _InlineMessage(
              text: maxResubmits == null
                  ? '$attempt-urinish · ${valueText(widget.submission!, const ['status'])}'
                  : '$attempt / ${maxResubmits + 1}-urinish · ${valueText(widget.submission!, const ['status'])}',
              error: false,
            ),
          ],
          const SizedBox(height: 18),
          TextField(
            controller: _text,
            enabled: !readOnly && !_busy,
            minLines: 5,
            maxLines: 10,
            maxLength: 20000,
            decoration: const InputDecoration(
              labelText: 'Javob matni',
              alignLabelWithHint: true,
            ),
          ),
          if (!readOnly) ...[
            OutlinedButton.icon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(
                _files.isEmpty
                    ? 'Fayl biriktirish'
                    : '${_files.length} ta fayl tanlandi',
              ),
            ),
            if (_files.isNotEmpty)
              ..._files.map(
                (file) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(file.name),
                  subtitle: Text('${file.size ~/ 1024} KB'),
                ),
              ),
          ],
          if (grade.isNotEmpty) ...[
            const SizedBox(height: 12),
            if (grade['graded'] == true)
              _InlineMessage(
                text:
                    'Ustoz bahosi: ${grade['score']}\n${valueText(grade, const ['feedback'], fallback: 'Izoh yo‘q')}',
                error: false,
              ),
            if (aiFeedback.isNotEmpty) ...[
              const SizedBox(height: 10),
              _SectionCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI tahlili',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(aiFeedback),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (grade['graded'] != true && aiFeedback.isEmpty)
              const _InlineMessage(text: 'Tekshirilmoqda', error: false),
          ],
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            _InlineMessage(text: error, error: true),
          ],
          const SizedBox(height: 18),
          if (!readOnly)
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                _busy
                    ? 'Yuborilmoqda…'
                    : widget.submission == null
                    ? 'Serverga topshirish'
                    : 'Yangi urinishni topshirish',
              ),
            )
          else
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Yopish'),
            ),
        ],
      ),
    );
  }
}

class _SchedulePortalPage extends StatelessWidget {
  const _SchedulePortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final rows = [...portal.lessons]
      ..sort((a, b) => '${a['starts_at']}'.compareTo('${b['starts_at']}'));
    return _PortalPage(
      title: portal.isParent ? 'Oila taqvimi' : 'Dars jadvali',
      subtitle: portal.isParent
          ? 'Farzandingizning darslari, vaqti va xonasi.'
          : 'Bugungi darslar, o‘quv davri va kalendar sinxronizatsiyasi.',
      section: PortalSection.schedule,
      trailing: portal.calendarUrl.isEmpty
          ? null
          : FilledButton.tonalIcon(
              onPressed: () => _launch(context, portal.calendarUrl),
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Kalendarni ulash'),
            ),
      children: [
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'Darslar',
              value: '${rows.length}',
              icon: Icons.event_note_outlined,
            ),
            _MetricCard(
              label: 'O‘quv davrlari',
              value: '${portal.terms.length}',
              icon: Icons.date_range_outlined,
            ),
            _MetricCard(
              label: 'Dars turlari',
              value: '${portal.lessonTypes.length}',
              icon: Icons.category_outlined,
            ),
            _MetricCard(
              label: 'Takroriy rejalar',
              value: '${portal.scheduleRules.length}',
              icon: Icons.repeat_rounded,
            ),
          ],
        ),
        if (portal.timeSlots.isNotEmpty || portal.lessonTypes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DensePanelHeader(
                  title: 'Jadval katalogi',
                  meta:
                      '${portal.timeSlots.length} vaqt · ${portal.lessonTypes.length} tur',
                  icon: Icons.tune_rounded,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final slot in portal.timeSlots)
                      _CatalogPill(
                        icon: Icons.schedule_rounded,
                        label: valueText(slot, const [
                          'name',
                        ], fallback: 'Vaqt oralig‘i'),
                        detail:
                            '${valueText(slot, const ['start_time', 'starts_at'])}–${valueText(slot, const ['end_time', 'ends_at'])}',
                      ),
                    for (final type in portal.lessonTypes)
                      _CatalogPill(
                        icon: Icons.category_outlined,
                        label: valueText(type, const ['name', 'title']),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _PageSectionTitle(title: 'Darslar', count: rows.length),
        const SizedBox(height: 10),
        if (rows.isEmpty)
          const _EmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'Jadval bo‘sh',
            message: 'Hozircha ko‘rinadigan dars mavjud emas.',
          )
        else
          ...rows.map(
            (lesson) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SectionCard(
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(_compactDateLabel(lesson['starts_at'])),
                          Text(
                            _timeOnly(lesson['starts_at']),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            valueText(lesson, const ['title']),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${valueText(lesson, const ['teacher_name'], fallback: 'Ustoz')} · ${valueText(lesson, const ['room_name'], fallback: 'Xona belgilanmagan')}',
                          ),
                          Text(
                            '${_timeOnly(lesson['starts_at'])}–${_timeOnly(lesson['ends_at'])}',
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(
                      valueText(lesson, const ['status']),
                      positive: lesson['status'] == 'scheduled',
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CatalogPill extends StatelessWidget {
  const _CatalogPill({required this.icon, required this.label, this.detail});

  final IconData icon;
  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            detail == null || detail == '—–—' ? label : '$label · $detail',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AttendancePortalPage extends StatelessWidget {
  const _AttendancePortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final summary = portal.attendanceSummary;
    final studentId = portal.selectedStudentId;
    final rows = portal.isParent && studentId != null
        ? portal.attendance
              .where((item) => valueInt(item['student']) == studentId)
              .toList()
        : portal.attendance;
    final timelyRate =
        ((double.tryParse('${summary['percent_present']}') ?? 0) / 100)
            .clamp(0.0, 1.0)
            .toDouble();
    final colors = Theme.of(context).colorScheme;
    return _PortalPage(
      title: portal.isParent ? 'Farzand davomati' : 'Mening davomatim',
      subtitle: 'Joriy davr bo‘yicha belgilangan qatnashuv holatlari.',
      section: PortalSection.attendance,
      children: [
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'O‘z vaqtida',
              value: '${summary['percent_present'] ?? 0}%',
              icon: Icons.donut_large_rounded,
            ),
            _MetricCard(
              label: 'Keldi',
              value: '${summary['present'] ?? 0}',
              icon: Icons.check_circle_outline_rounded,
            ),
            _MetricCard(
              label: 'Kechikdi',
              value: '${summary['late'] ?? 0}',
              icon: Icons.schedule_rounded,
            ),
            _MetricCard(
              label: 'Kelmadi',
              value: '${summary['absent'] ?? 0}',
              icon: Icons.cancel_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _LearningInsightPanel(
          title: 'Davomat taqsimoti',
          ringLabel: 'Vaqtida',
          ringValue: timelyRate,
          ringDetail:
              '${summary['present'] ?? 0} ta darsga o‘z vaqtida kelgan. Kechikish bu ko‘rsatkichka kirmaydi.',
          items: _attendanceBars(rows, colors),
          emptyLabel: 'Davomat yozuvlari kelganda taqsimot shu yerda chiqadi.',
        ),
        const SizedBox(height: 24),
        if (rows.isEmpty)
          const _EmptyState(
            icon: Icons.fact_check_outlined,
            title: 'Davomat yozuvi yo‘q',
            message: 'Ustoz belgilagan yozuvlar shu yerda ko‘rinadi.',
          )
        else
          _SimpleRows(
            rows: rows,
            icon: Icons.school_outlined,
            title: (row) => valueText(row, const ['lesson_title']),
            subtitle: (row) =>
                '${_dateLabel(row['lesson_starts_at'], time: true)} · ${valueText(row, const ['teacher_name'], fallback: 'Ustoz')}',
            trailing: (row) => _StatusPill(
              valueText(row, const ['status']),
              positive: row['status'] == 'present',
              warning: row['status'] == 'late',
            ),
          ),
      ],
    );
  }
}

String _contentType(String? extension) => switch ((extension ?? '')
    .toLowerCase()) {
  'pdf' => 'application/pdf',
  'mp3' => 'audio/mpeg',
  'm4a' => 'audio/mp4',
  'ogg' => 'audio/ogg',
  'opus' => 'audio/opus',
  'wav' => 'audio/wav',
  'webm' => 'audio/webm',
  'png' => 'image/png',
  'jpg' || 'jpeg' => 'image/jpeg',
  'doc' => 'application/msword',
  'docx' =>
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'txt' => 'text/plain',
  _ => 'application/octet-stream',
};

String _timeOnly(Object? raw) {
  final date = DateTime.tryParse('${raw ?? ''}')?.toLocal();
  if (date == null) return '—';
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _PageSectionTitle extends StatelessWidget {
  const _PageSectionTitle({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (count != null) _StatusPill('$count ta'),
      ],
    );
  }
}

class _SimpleRows extends StatelessWidget {
  const _SimpleRows({
    required this.rows,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final List<Map<String, Object?>> rows;
  final IconData icon;
  final String Function(Map<String, Object?>) title;
  final String Function(Map<String, Object?>) subtitle;
  final Widget Function(Map<String, Object?>)? trailing;
  final void Function(Map<String, Object?>)? onTap;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: CircleAvatar(child: Icon(icon, size: 20)),
              title: Text(title(rows[index])),
              subtitle: Text(subtitle(rows[index])),
              trailing: trailing?.call(rows[index]),
              onTap: onTap == null ? null : () => onTap!(rows[index]),
            ),
            if (index != rows.length - 1) const Divider(height: 1, indent: 72),
          ],
        ],
      ),
    );
  }
}

class _AcademicsPortalPage extends StatelessWidget {
  const _AcademicsPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final studentId = portal.selectedStudentId;
    final grades = portal.isParent && studentId != null
        ? portal.grades
              .where((item) => valueInt(item['student']) == studentId)
              .toList()
        : portal.grades;
    final transcripts = portal.isParent && studentId != null
        ? portal.transcripts
              .where((item) => valueInt(item['student']) == studentId)
              .toList()
        : portal.transcripts;
    final selectedChild = portal.children
        .where((item) => valueInt(item['id']) == studentId)
        .firstOrNull;
    final selectedCohortId = portal.isParent
        ? valueInt(selectedChild?['current_cohort'])
        : null;
    final visibleExams = portal.exams
        .where(
          (item) =>
              item['is_published'] == true &&
              (!portal.isParent ||
                  (selectedCohortId != null &&
                      valueInt(item['cohort']) == selectedCohortId)),
        )
        .toList();
    final gradePercentages = [
      for (final grade in grades) _gradePercentage(grade),
    ];
    final gradeAverage = gradePercentages.isEmpty
        ? 0.0
        : gradePercentages.reduce((a, b) => a + b) / gradePercentages.length;
    final colors = Theme.of(context).colorScheme;
    return _PortalPage(
      title: portal.isParent ? 'O‘zlashtirish' : 'Natijalarim',
      subtitle: portal.isParent
          ? 'Farzandingizning e’lon qilingan baholari, imtihonlari va tabeli.'
          : 'Shaxsiy baholar, nazorat ishlari va rasmiy o‘quv tabeli.',
      section: PortalSection.academics,
      trailing: FilledButton.tonalIcon(
        onPressed: studentId == null
            ? null
            : () => _requestTranscript(context, portal),
        icon: const Icon(Icons.description_outlined),
        label: const Text('Tabel so‘rash'),
      ),
      children: [
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'Baholash turlari',
              value: '${portal.examTypes.length}',
              icon: Icons.category_outlined,
            ),
            _MetricCard(
              label: 'Baholar',
              value: '${grades.length}',
              icon: Icons.school_outlined,
            ),
            _MetricCard(
              label: 'Imtihonlar',
              value: '${visibleExams.length}',
              icon: Icons.quiz_outlined,
            ),
            _MetricCard(
              label: 'Tabellar',
              value: '${transcripts.length}',
              icon: Icons.description_outlined,
            ),
          ],
        ),
        if (portal.examTypes.isNotEmpty || portal.subjects.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final subject in portal.subjects)
                  _CatalogPill(
                    icon: Icons.menu_book_outlined,
                    label: valueText(subject, const ['name', 'title']),
                  ),
                for (final type in portal.examTypes)
                  _CatalogPill(
                    icon: Icons.quiz_outlined,
                    label: valueText(type, const ['name', 'title']),
                  ),
              ],
            ),
          ),
        ],
        if (grades.isNotEmpty) ...[
          const SizedBox(height: 18),
          _LearningInsightPanel(
            title: 'Fanlar bo‘yicha o‘zlashtirish',
            ringLabel: 'O‘rtacha',
            ringValue: gradeAverage / 100,
            ringDetail:
                '${grades.length} ta e’lon qilingan baho bo‘yicha o‘rtacha ${gradeAverage.round()}%.',
            items: [
              for (var index = 0; index < grades.length; index++)
                _PortalBarDatum(
                  label: valueText(grades[index], const ['subject_name']),
                  value: gradePercentages[index],
                  detail:
                      'Rasmiy qiymat: ${valueText(grades[index], const ['value_display', 'value_raw'])} · ${_dateLabel(grades[index]['published_at'] ?? grades[index]['computed_at'])}',
                  color: gradePercentages[index] >= 85
                      ? Sf.success
                      : gradePercentages[index] >= 70
                      ? colors.primary
                      : Sf.warn,
                  icon: Icons.menu_book_outlined,
                ),
            ],
            emptyLabel: 'E’lon qilingan baholar hali yo‘q.',
          ),
        ],
        const SizedBox(height: 24),
        _PageSectionTitle(title: 'Yakuniy baholar', count: grades.length),
        const SizedBox(height: 10),
        if (grades.isEmpty)
          const _EmptyState(
            icon: Icons.school_outlined,
            title: 'Baho yo‘q',
            message: 'E’lon qilingan baholar shu yerda ko‘rinadi.',
          )
        else
          _SimpleRows(
            rows: grades,
            icon: Icons.grade_outlined,
            title: (row) => valueText(row, const ['subject_name']),
            subtitle: (row) =>
                'Qiymat: ${valueText(row, const ['value_display', 'value_raw'])} · ${_dateLabel(row['published_at'] ?? row['computed_at'])}',
            trailing: (row) => _StatusPill(
              row['is_published'] == true ? 'E’lon qilingan' : 'Kutilmoqda',
              positive: row['is_published'] == true,
            ),
            onTap: (row) => _showJsonDetail(
              context,
              title: valueText(row, const ['subject_name']),
              fields: {
                'Baho': valueText(row, const ['value_display', 'value_raw']),
                'Tarkib': _readable(row['components']),
                'Hisoblangan': _dateLabel(row['computed_at'], time: true),
              },
            ),
          ),
        const SizedBox(height: 24),
        _PageSectionTitle(title: 'Imtihonlar', count: visibleExams.length),
        const SizedBox(height: 10),
        if (visibleExams.isNotEmpty)
          _SimpleRows(
            rows: visibleExams,
            icon: Icons.quiz_outlined,
            title: (row) => valueText(row, const ['title']),
            subtitle: (row) =>
                '${valueText(row, const ['subject_name'])} · ${_dateLabel(row['exam_date'])} · maksimum ${row['max_score']}',
          )
        else
          const _EmptyState(
            icon: Icons.quiz_outlined,
            title: 'Imtihon e’lon qilinmagan',
            message: 'E’lon qilingan nazorat ishlari shu yerda ko‘rinadi.',
          ),
        const SizedBox(height: 24),
        _PageSectionTitle(title: 'Tabel so‘rovlari', count: transcripts.length),
        const SizedBox(height: 10),
        if (transcripts.isEmpty)
          const _EmptyState(
            icon: Icons.description_outlined,
            title: 'Tabel so‘rovi yo‘q',
            message:
                'Yangi rasmiy tabel yaratish uchun yuqoridagi tugmani bosing.',
          )
        else
          _SimpleRows(
            rows: transcripts,
            icon: Icons.picture_as_pdf_outlined,
            title: (row) => 'Tabel #${row['id']}',
            subtitle: (row) =>
                '${_statusLabel('${row['status']}')} · ${_dateLabel(row['created_at'], time: true)}',
            trailing: (row) {
              final url = '${row['download_url'] ?? ''}';
              return url.isEmpty
                  ? _StatusPill(valueText(row, const ['status']))
                  : IconButton(
                      tooltip: 'Tabelni ochish',
                      onPressed: () => _launch(context, url),
                      icon: const Icon(Icons.open_in_new_rounded),
                    );
            },
          ),
      ],
    );
  }

  Future<void> _requestTranscript(
    BuildContext context,
    PortalController portal,
  ) async {
    final current = portal.terms
        .where((item) => item['is_current'] == true)
        .firstOrNull;
    int? selected = valueInt(current?['id']);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rasmiy tabel'),
          content: DropdownButtonFormField<int?>(
            initialValue: selected,
            decoration: const InputDecoration(labelText: 'O‘quv davri'),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Barcha davrlar'),
              ),
              for (final term in portal.terms)
                if (valueInt(term['id']) case final id?)
                  DropdownMenuItem<int?>(
                    value: id,
                    child: Text(valueText(term, const ['name'])),
                  ),
            ],
            onChanged: (value) => setDialogState(() => selected = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('So‘rash'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true && context.mounted) {
      await _runAction(
        context,
        () => portal.requestTranscript(termId: selected),
        success: 'Tabel yaratish uchun navbatga qo‘yildi.',
      );
    }
  }
}

class _ContentPortalPage extends StatefulWidget {
  const _ContentPortalPage();

  @override
  State<_ContentPortalPage> createState() => _ContentPortalPageState();
}

class _ContentPortalPageState extends State<_ContentPortalPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    return _PortalPage(
      title: 'O‘quv materiallari',
      subtitle:
          'Sizga ochilgan kutubxonalar, kurslar, dars fayllari va maqolalar.',
      section: PortalSection.content,
      children: [
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: 0,
              label: Text('Materiallar'),
              icon: Icon(Icons.article_outlined),
            ),
            ButtonSegment(
              value: 1,
              label: Text('Fayllar'),
              icon: Icon(Icons.folder_outlined),
            ),
            ButtonSegment(
              value: 2,
              label: Text('Kurslar'),
              icon: Icon(Icons.library_books_outlined),
            ),
          ],
          selected: {_tab},
          onSelectionChanged: (value) => setState(() => _tab = value.first),
        ),
        const SizedBox(height: 18),
        if (_tab == 0) _materials(context, portal),
        if (_tab == 1) _files(context, portal),
        if (_tab == 2) _courses(context, portal),
      ],
    );
  }

  Widget _materials(BuildContext context, PortalController portal) {
    if (portal.materials.isEmpty) {
      return const _EmptyState(
        icon: Icons.article_outlined,
        title: 'Material yo‘q',
        message: 'Nashr qilingan o‘quv materiallari shu yerda ko‘rinadi.',
      );
    }
    return Column(
      children: [
        for (final material in portal.materials)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SectionCard(
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 10),
                leading: const CircleAvatar(
                  child: Icon(Icons.auto_stories_outlined),
                ),
                title: Text(valueText(material, const ['title'])),
                subtitle: Text(
                  '${valueText(material, const ['library_name'], fallback: 'Kutubxona')} · ${valueText(material, const ['topic'], fallback: 'Mavzu ko‘rsatilmagan')}',
                ),
                trailing: _StatusPill(
                  valueText(material, const ['status']),
                  positive: material['status'] == 'published',
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      valueText(material, const [
                        'body',
                      ], fallback: 'Material matni berilmagan.'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _files(BuildContext context, PortalController portal) {
    if (portal.files.isEmpty && portal.folders.isEmpty) {
      return const _EmptyState(
        icon: Icons.folder_open_outlined,
        title: 'Fayl yo‘q',
        message: 'Tasdiqlangan fayllar shu yerda ko‘rinadi.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (portal.folders.isNotEmpty)
          _SectionCard(
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final folder in portal.folders)
                  _CatalogPill(
                    icon: Icons.folder_outlined,
                    label: valueText(folder, const ['name', 'title']),
                  ),
              ],
            ),
          ),
        if (portal.folders.isNotEmpty && portal.files.isNotEmpty)
          const SizedBox(height: 10),
        if (portal.files.isEmpty)
          const _CompactEmpty(message: 'Bu papkalarda hozircha fayl yo‘q.')
        else
          _SimpleRows(
            rows: portal.files,
            icon: Icons.insert_drive_file_outlined,
            title: (row) => valueText(row, const ['title']),
            subtitle: (row) =>
                '${valueText(row, const ['lesson_title', 'folder_name'], fallback: 'Material')} · ${_fileSize(row['size_bytes'])}',
            trailing: (row) => row['is_downloadable'] == true
                ? IconButton(
                    tooltip: 'Faylni ochish',
                    onPressed: () async {
                      final id = valueInt(row['id']);
                      if (id == null) return;
                      try {
                        final url = await portal.contentDownloadUrl(id);
                        if (context.mounted) await _launch(context, url);
                      } on Object catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_errorText(error))),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.download_outlined),
                  )
                : const Tooltip(
                    message: 'Yuklab olish yopiq',
                    child: Icon(Icons.lock_outline_rounded),
                  ),
            onTap: (row) {
              final id = valueInt(row['id']);
              if (id != null) {
                unawaited(portal.trackContentView(id));
                unawaited(
                  _showJsonDetail(
                    context,
                    title: valueText(row, const ['title']),
                    fields: {
                      'Dars yoki papka': valueText(row, const [
                        'lesson_title',
                        'folder_name',
                      ], fallback: 'Material'),
                      'Turi': valueText(row, const ['content_type']),
                      'Hajmi': _fileSize(row['size_bytes']),
                      'Versiya': '${row['version'] ?? 1}',
                      'Holat': _statusLabel('${row['status']}'),
                    },
                  ),
                );
              }
            },
          ),
      ],
    );
  }

  Widget _courses(BuildContext context, PortalController portal) {
    if (portal.libraries.isEmpty && portal.courses.isEmpty) {
      return const _EmptyState(
        icon: Icons.library_books_outlined,
        title: 'Kutubxona yo‘q',
        message: 'Sizga ochilgan kurslar shu yerda ko‘rinadi.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (portal.libraries.isNotEmpty) ...[
          _SectionCard(
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final library in portal.libraries)
                  _CatalogPill(
                    icon: Icons.local_library_outlined,
                    label: valueText(library, const ['name', 'title']),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'Kutubxonalar',
              value: '${portal.libraries.length}',
              icon: Icons.local_library_outlined,
            ),
            _MetricCard(
              label: 'Kurslar',
              value: '${portal.courses.length}',
              icon: Icons.menu_book_outlined,
            ),
            _MetricCard(
              label: 'Modullar',
              value: '${portal.modules.length}',
              icon: Icons.view_module_outlined,
            ),
            _MetricCard(
              label: 'Darslar',
              value: '${portal.contentLessons.length}',
              icon: Icons.play_lesson_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (portal.courses.isNotEmpty)
          _SimpleRows(
            rows: portal.courses,
            icon: Icons.menu_book_outlined,
            title: (row) => valueText(row, const ['title']),
            subtitle: (row) =>
                '${valueText(row, const ['library_name'])} · ${valueText(row, const ['subject_name'])}',
            onTap: (course) {
              final courseId = valueInt(course['id']);
              final modules = portal.modules
                  .where((item) => valueInt(item['course']) == courseId)
                  .toList();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => _CourseSheet(
                  course: course,
                  modules: modules,
                  lessons: portal.contentLessons,
                ),
              );
            },
          ),
      ],
    );
  }
}

class _CourseSheet extends StatelessWidget {
  const _CourseSheet({
    required this.course,
    required this.modules,
    required this.lessons,
  });

  final Map<String, Object?> course;
  final List<Map<String, Object?>> modules;
  final List<Map<String, Object?>> lessons;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Text(
            valueText(course, const ['title']),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            valueText(course, const [
              'description',
            ], fallback: 'Kurs tavsifi berilmagan.'),
          ),
          const SizedBox(height: 20),
          if (modules.isEmpty)
            const _EmptyState(
              icon: Icons.view_module_outlined,
              title: 'Modul yo‘q',
              message: 'Kurs hali to‘ldirilmagan.',
            )
          else
            for (final module in modules)
              ExpansionTile(
                title: Text(valueText(module, const ['title'])),
                children: [
                  for (final lesson in lessons.where(
                    (item) =>
                        valueInt(item['module']) == valueInt(module['id']),
                  ))
                    ListTile(
                      leading: const Icon(Icons.play_lesson_outlined),
                      title: Text(valueText(lesson, const ['title'])),
                      subtitle: Text(
                        valueText(lesson, const ['description'], fallback: ''),
                      ),
                    ),
                ],
              ),
        ],
      ),
    );
  }
}

String _fileSize(Object? raw) {
  final bytes = valueInt(raw);
  if (bytes == null) return '—';
  if (bytes >= 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024).ceil()} KB';
}

Future<void> _launch(BuildContext context, String rawUrl) async {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null ||
      !const {'http', 'https', 'webcal'}.contains(uri.scheme.toLowerCase()) ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Havolani ochib bo‘lmadi.')));
    }
  }
}

String _readable(Object? value) {
  if (value == null) return '—';
  if (value is List) return value.map(_readable).join(', ');
  if (value is Map) {
    return value.entries
        .map((entry) => '${entry.key}: ${_readable(entry.value)}')
        .join('\n');
  }
  final text = '$value'.trim();
  return text.isEmpty ? '—' : text;
}

Future<void> _showJsonDetail(
  BuildContext context, {
  required String title,
  required Map<String, String> fields,
}) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(title),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final field in fields.entries) ...[
            Text(field.key, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 3),
            Text(field.value),
            const SizedBox(height: 14),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Yopish'),
      ),
    ],
  ),
);

class _AiPortalPage extends StatelessWidget {
  const _AiPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final budget = portal.aiBudget;
    final usage = portal.aiUsage;
    final requests = portal.aiRequests;
    final totalRequests =
        valueInt(
          usage['total_requests'] ??
              usage['request_count'] ??
              usage['requests'],
        ) ??
        requests.length;
    final totalTokens =
        valueInt(
          usage['total_tokens'] ?? usage['tokens'] ?? usage['token_count'],
        ) ??
        0;
    final remaining =
        budget['remaining'] ??
        budget['remaining_budget'] ??
        budget['available'] ??
        budget['balance'];
    final spent =
        budget['spent'] ??
        budget['used'] ??
        usage['total_cost'] ??
        usage['cost'];
    return _PortalPage(
      title: portal.isParent ? 'AI nazorat tahlili' : 'AI o‘qish yordamchisi',
      subtitle: portal.isParent
          ? 'Server qayd etgan AI so‘rovlari va foydalanish holati.'
          : 'O‘qish jarayonida bajarilgan AI so‘rovlari va ularning holati.',
      section: PortalSection.ai,
      trailing: const _LiveBadge(
        label: 'SERVER AI',
        icon: Icons.auto_awesome_rounded,
      ),
      children: [
        _AiInsightCard(parent: portal.isParent, requests: requests),
        const SizedBox(height: 12),
        _ResponsiveGrid(
          minWidth: 170,
          children: [
            _MetricCard(
              label: 'AI so‘rovlari',
              value: '$totalRequests',
              icon: Icons.chat_bubble_outline_rounded,
            ),
            _MetricCard(
              label: 'Tokenlar',
              value: totalTokens == 0 ? '—' : '$totalTokens',
              icon: Icons.data_usage_rounded,
            ),
            _MetricCard(
              label: 'Qolgan limit',
              value: remaining == null ? '—' : '$remaining',
              icon: Icons.speed_rounded,
            ),
            _MetricCard(
              label: 'Sarflangan',
              value: spent == null ? '—' : '$spent',
              icon: Icons.payments_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DensePanelHeader(
                title: 'So‘rovlar tarixi',
                meta: '${requests.length} ta yozuv',
                icon: Icons.history_rounded,
              ),
              const SizedBox(height: 10),
              if (requests.isEmpty)
                const _CompactEmpty(
                  message: 'Serverda AI so‘rovlari hali qayd etilmagan.',
                )
              else
                for (final request in requests.take(30))
                  _AiRequestTile(request: request),
            ],
          ),
        ),
      ],
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({required this.parent, required this.requests});

  final bool parent;
  final List<Map<String, Object?>> requests;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [colors.secondaryContainer, colors.surfaceContainerHigh]
              : const [Sf.aiBg1, Sf.aiBg2],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Sf.aiBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final icon = Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Sf.ai.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 21,
              color: Sf.ai,
            ),
          );
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                parent ? 'Oila uchun AI signallari' : 'Shaxsiy AI faoliyati',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Sf.ai,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                requests.isEmpty
                    ? 'AI xulosasi uchun serverda hali yetarli so‘rov tarixi yo‘q.'
                    : 'Oxirgi ${requests.length} ta AI so‘rovi serverdan olindi. Har bir holat quyida ko‘rsatilgan.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Sf.accentInk,
                  height: 1.4,
                ),
              ),
            ],
          );
          if (constraints.maxWidth < 430) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [icon, const SizedBox(height: 10), copy],
            );
          }
          return Row(
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(child: copy),
              Icon(Icons.arrow_forward_rounded, color: colors.tertiary),
            ],
          );
        },
      ),
    );
  }
}

class _AiRequestTile extends StatelessWidget {
  const _AiRequestTile({required this.request});

  final Map<String, Object?> request;

  @override
  Widget build(BuildContext context) {
    final status = valueText(request, const [
      'status',
      'state',
    ], fallback: 'unknown');
    final positive = const {
      'completed',
      'success',
      'succeeded',
      'done',
    }.contains(status.toLowerCase());
    final pending = const {
      'pending',
      'queued',
      'processing',
      'running',
    }.contains(status.toLowerCase());
    final title = valueText(request, const [
      'title',
      'purpose',
      'request_type',
      'kind',
      'prompt',
    ], fallback: 'AI so‘rovi');
    final detail = valueText(request, const [
      'model',
      'provider',
      'response_summary',
      'error_message',
    ], fallback: 'Server so‘rovi');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Sf.ai.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              size: 18,
              color: Sf.ai,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  '$detail · ${_dateLabel(request['created_at'], time: true)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusPill(status, positive: positive, warning: pending),
        ],
      ),
    );
  }
}

class _RebuiltMessagesPortalPage extends StatefulWidget {
  const _RebuiltMessagesPortalPage();

  @override
  State<_RebuiltMessagesPortalPage> createState() =>
      _RebuiltMessagesPortalPageState();
}

class _RebuiltMessagesPortalPageState
    extends State<_RebuiltMessagesPortalPage> {
  final _search = TextEditingController();
  String _filter = 'all';
  int? _selectedThreadId;
  bool _refreshing = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final query = _search.text.trim().toLowerCase();
    final threads = portal.threads.where((thread) {
      final unread = valueInt(thread['unread_count']) ?? 0;
      if (_filter == 'unread' && unread == 0) return false;
      if (_filter == 'muted' && thread['notifications_muted'] != true) {
        return false;
      }
      if (query.isEmpty) return true;
      return portal.threadTitle(thread).toLowerCase().contains(query) ||
          valueText(thread, const [
            'subject',
          ], fallback: '').toLowerCase().contains(query);
    }).toList();
    final selectedId = threads
        .where((item) => valueInt(item['id']) == _selectedThreadId)
        .map((item) => valueInt(item['id']))
        .firstOrNull;
    final effectiveId = selectedId ?? valueInt(threads.firstOrNull?['id']);
    final desktop = MediaQuery.sizeOf(context).width >= 1100;
    if (!desktop) {
      final availableHeight = (MediaQuery.sizeOf(context).height - 230).clamp(
        280.0,
        760.0,
      );
      return _PortalPage(
        title: portal.isParent ? 'Maktab bilan chat' : 'Chat',
        subtitle: 'Shaxsiy va guruh suhbatlari.',
        section: PortalSection.messages,
        trailing: FilledButton.icon(
          onPressed: portal.contacts.isEmpty || !portal.can('messaging:write')
              ? null
              : () => _startConversation(portal),
          icon: const Icon(Icons.edit_square),
          label: const Text('Yangi'),
        ),
        children: [
          _SectionCard(
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: availableHeight,
              child: _WorkspaceConversationList(
                portal: portal,
                threads: threads,
                search: _search,
                filter: _filter,
                selectedId: null,
                onSearch: () => setState(() {}),
                onFilter: (value) => setState(() => _filter = value),
                onOpen: (thread) =>
                    _openMobileThread(portal, valueInt(thread['id'])),
              ),
            ),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorkspaceHeader(
            portal: portal,
            refreshing: _refreshing,
            onRefresh: _refreshing ? null : () => _refreshThreads(portal),
            onNewConversation:
                portal.contacts.isEmpty || !portal.can('messaging:write')
                ? null
                : () => _startConversation(portal),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 340,
                    child: _WorkspaceConversationList(
                      portal: portal,
                      threads: threads,
                      search: _search,
                      filter: _filter,
                      selectedId: effectiveId,
                      onSearch: () => setState(() {}),
                      onFilter: (value) => setState(() => _filter = value),
                      onOpen: (thread) => setState(
                        () => _selectedThreadId = valueInt(thread['id']),
                      ),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: effectiveId == null
                        ? const _WorkspaceWelcome()
                        : _ThreadScreen(
                            key: ValueKey(effectiveId),
                            threadId: effectiveId,
                            embedded: true,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshThreads(PortalController portal) async {
    setState(() => _refreshing = true);
    try {
      await portal.refresh(PortalSection.messages);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _openMobileThread(PortalController portal, int? id) {
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PortalScope(
          controller: portal,
          child: _ThreadScreen(threadId: id),
        ),
      ),
    );
  }

  Future<void> _startConversation(PortalController portal) async {
    if (!portal.can('messaging:write')) return;
    final selected = <int>{};
    final contactSearch = TextEditingController();
    final subject = TextEditingController();
    final body = TextEditingController();
    var contactQuery = '';
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            18,
            22,
            22 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Yangi suhbat',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Yopish',
                      onPressed: () => Navigator.pop(sheetContext, false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  selected.isEmpty
                      ? 'Maktab kontaktlaridan qabul qiluvchini tanlang.'
                      : '${selected.length} ta qabul qiluvchi tanlandi.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: contactSearch,
                  onChanged: (value) => setSheetState(
                    () => contactQuery = value.trim().toLowerCase(),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Kontaktni qidirish',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final contact in portal.contacts)
                          if (contactQuery.isEmpty ||
                              '${contact['display_name']} ${contact['username']} ${contact['role_label']}'
                                  .toLowerCase()
                                  .contains(contactQuery))
                            if (valueInt(contact['user_id'] ?? contact['id'])
                                case final id?)
                              CheckboxListTile(
                                value: selected.contains(id),
                                secondary: CircleAvatar(
                                  child: Text(
                                    _initials(
                                      valueText(contact, const [
                                        'display_name',
                                      ]),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  valueText(contact, const [
                                    'display_name',
                                    'username',
                                  ]),
                                ),
                                subtitle: Text(
                                  '${valueText(contact, const ['role_label'])}${contact['is_online'] == true ? ' · online' : ''}',
                                ),
                                onChanged: (checked) => setSheetState(() {
                                  if (checked == true) {
                                    selected.add(id);
                                  } else {
                                    selected.remove(id);
                                  }
                                }),
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: subject,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: const InputDecoration(labelText: 'Mavzu'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: body,
                  onChanged: (_) => setSheetState(() {}),
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Birinchi xabar',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed:
                      selected.isEmpty ||
                          (subject.text.trim().isEmpty &&
                              body.text.trim().isEmpty)
                      ? null
                      : () => Navigator.pop(sheetContext, true),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Suhbatni boshlash'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      if (accepted == true && selected.isNotEmpty && mounted) {
        final id = await portal.createThread(
          participantIds: selected.toList(),
          subject: subject.text,
          firstBody: body.text,
        );
        if (mounted && id > 0) setState(() => _selectedThreadId = id);
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      contactSearch.dispose();
      subject.dispose();
      body.dispose();
    }
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.portal,
    required this.refreshing,
    this.onRefresh,
    this.onNewConversation,
  });

  final PortalController portal;
  final bool refreshing;
  final VoidCallback? onRefresh;
  final VoidCallback? onNewConversation;

  @override
  Widget build(BuildContext context) {
    final unread = portal.threads.fold<int>(
      0,
      (total, item) => total + (valueInt(item['unread_count']) ?? 0),
    );
    final online = portal.contacts
        .where((contact) => contact['is_online'] == true)
        .length;
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.forum_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  portal.isParent ? 'Maktab bilan aloqa' : 'Suhbatlar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  unread == 0
                      ? 'Barcha xabarlar o‘qilgan'
                      : '$unread ta yangi xabar',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _WorkspaceStat(
            value: '${portal.threads.length}',
            label: 'suhbat',
            icon: Icons.chat_bubble_outline_rounded,
          ),
          const SizedBox(width: 8),
          _WorkspaceStat(
            value: '$online',
            label: 'online',
            icon: Icons.circle,
            positive: true,
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: 'Suhbatlarni yangilash',
            onPressed: onRefresh,
            icon: refreshing
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onNewConversation,
            icon: const Icon(Icons.edit_square, size: 18),
            label: const Text('Yangi suhbat'),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceStat extends StatelessWidget {
  const _WorkspaceStat({
    required this.value,
    required this.label,
    required this.icon,
    this.positive = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: icon == Icons.circle ? 8 : 16,
          color: positive ? Sf.success : Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _WorkspaceConversationList extends StatelessWidget {
  const _WorkspaceConversationList({
    required this.portal,
    required this.threads,
    required this.search,
    required this.filter,
    required this.selectedId,
    required this.onSearch,
    required this.onFilter,
    required this.onOpen,
  });

  final PortalController portal;
  final List<Map<String, Object?>> threads;
  final TextEditingController search;
  final String filter;
  final int? selectedId;
  final VoidCallback onSearch;
  final ValueChanged<String> onFilter;
  final ValueChanged<Map<String, Object?>> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final unread = portal.threads.fold<int>(
      0,
      (total, item) => total + (valueInt(item['unread_count']) ?? 0),
    );
    return ColoredBox(
      color: colors.surfaceContainerLowest,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 9),
            child: TextField(
              key: const ValueKey('message-thread-search'),
              controller: search,
              onChanged: (_) => onSearch(),
              decoration: InputDecoration(
                hintText: 'Suhbatlarni qidirish',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Qidiruvni tozalash',
                        onPressed: () {
                          search.clear();
                          onSearch();
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                _WorkspaceFilter(
                  label: 'Barchasi',
                  selected: filter == 'all',
                  onTap: () => onFilter('all'),
                ),
                const SizedBox(width: 6),
                _WorkspaceFilter(
                  label: unread == 0 ? 'Yangi' : 'Yangi · $unread',
                  selected: filter == 'unread',
                  onTap: () => onFilter('unread'),
                ),
                const SizedBox(width: 6),
                _WorkspaceFilter(
                  label: 'Ovozsiz',
                  selected: filter == 'muted',
                  onTap: () => onFilter('muted'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 2, 15, 9),
            child: Row(
              children: [
                Text(
                  filter == 'all'
                      ? 'SO‘NGGI SUHBATLAR'
                      : filter == 'unread'
                      ? 'O‘QILMAGANLAR'
                      : 'OVOZSIZ SUHBATLAR',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const Spacer(),
                Text(
                  '${threads.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Expanded(
            child: threads.isEmpty
                ? _WorkspaceEmpty(
                    filtered: search.text.trim().isNotEmpty || filter != 'all',
                  )
                : ListView.builder(
                    key: const ValueKey('message-thread-list'),
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
                    itemCount: threads.length,
                    itemBuilder: (context, index) {
                      final thread = threads[index];
                      final id = valueInt(thread['id']);
                      final cached = id == null ? null : portal.messages[id];
                      return _WorkspaceConversationTile(
                        key: ValueKey('message-thread-${id ?? index}'),
                        portal: portal,
                        thread: thread,
                        contact: _threadContact(portal, thread),
                        latestMessage: cached?.lastOrNull,
                        selected: id == selectedId,
                        onTap: () => onOpen(thread),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceFilter extends StatelessWidget {
  const _WorkspaceFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: selected ? Colors.white : null,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

class _WorkspaceConversationTile extends StatelessWidget {
  const _WorkspaceConversationTile({
    super.key,
    required this.portal,
    required this.thread,
    required this.contact,
    required this.latestMessage,
    required this.selected,
    required this.onTap,
  });

  final PortalController portal;
  final Map<String, Object?> thread;
  final Map<String, Object?> contact;
  final Map<String, Object?>? latestMessage;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = _workspaceThreadTitle(portal, thread);
    final unread = valueInt(thread['unread_count']) ?? 0;
    final muted = thread['notifications_muted'] == true;
    final online = contact['is_online'] == true;
    final participants = thread['participants'] is List
        ? (thread['participants'] as List).length
        : 0;
    final attachment = latestMessage?['attachments'];
    final hasAttachment = attachment is List && attachment.isNotEmpty;
    final mine =
        valueInt(latestMessage?['sender']) == portal.messagingSelfUserId;
    final latestBody = valueText(latestMessage ?? const {}, const [
      'body',
    ], fallback: '');
    final subject = valueText(thread, const [
      'subject',
    ], fallback: participants > 2 ? 'Guruh suhbati' : 'Shaxsiy suhbat');
    final preview = latestBody.isNotEmpty
        ? latestBody
        : hasAttachment
        ? _isAudioAttachment('${attachment.first}')
              ? 'Ovozli xabar'
              : 'Biriktirilgan fayl'
        : subject;
    final time = _dateLabel(
      thread['last_message_at'] ?? thread['created_at'],
      time: true,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Semantics(
        button: true,
        selected: selected,
        label: '$title. $preview${unread > 0 ? '. $unread ta yangi' : ''}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.fromLTRB(9, 10, 10, 10),
            decoration: BoxDecoration(
              color: selected
                  ? colors.primaryContainer.withValues(alpha: 0.72)
                  : unread > 0
                  ? colors.surface
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected
                    ? colors.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
              ),
              boxShadow: unread > 0 && !selected
                  ? [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.035),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? colors.primary
                            : colors.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: participants > 2
                          ? Icon(
                              Icons.groups_2_rounded,
                              color: selected
                                  ? colors.onPrimary
                                  : colors.onSurfaceVariant,
                              size: 22,
                            )
                          : Text(
                              _initials(title),
                              style: TextStyle(
                                color: selected
                                    ? colors.onPrimary
                                    : colors.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                    if (online)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: Sf.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? colors.primaryContainer
                                  : colors.surfaceContainerLowest,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: unread > 0
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                  ),
                            ),
                          ),
                          Text(
                            time,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: unread > 0
                                      ? colors.primary
                                      : colors.onSurfaceVariant,
                                  fontWeight: unread > 0
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (muted) ...[
                            Icon(
                              Icons.volume_off_rounded,
                              size: 14,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (latestMessage != null && mine) ...[
                            Icon(
                              Icons.done_all_rounded,
                              size: 15,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (hasAttachment) ...[
                            Icon(
                              _isAudioAttachment('${attachment.first}')
                                  ? Icons.mic_rounded
                                  : Icons.attach_file_rounded,
                              size: 14,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 3),
                          ],
                          Expanded(
                            child: Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: unread > 0
                                        ? colors.onSurface
                                        : colors.onSurfaceVariant,
                                    fontWeight: unread > 0
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              constraints: const BoxConstraints(minWidth: 22),
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                unread > 99 ? '99+' : '$unread',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceWelcome extends StatelessWidget {
  const _WorkspaceWelcome();

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.mark_chat_unread_outlined,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Suhbatni tanlang',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 7),
            Text(
              'Xabarlar, ovoz va fayllar faqat suhbat ishtirokchilariga ko‘rinadi.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            const _LiveBadge(
              label: 'Yopiq maktab kanali',
              icon: Icons.lock_outline_rounded,
            ),
          ],
        ),
      ),
    ),
  );
}

class _WorkspaceEmpty extends StatelessWidget {
  const _WorkspaceEmpty({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              filtered ? Icons.search_off_rounded : Icons.forum_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            filtered ? 'Suhbat topilmadi' : 'Hozircha suhbat yo‘q',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 5),
          Text(
            filtered
                ? 'Qidiruv yoki filtrni o‘zgartiring.'
                : 'Yangi suhbat orqali maktab kontaktiga yozing.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _MessagesPortalPage extends StatefulWidget {
  const _MessagesPortalPage();

  @override
  State<_MessagesPortalPage> createState() => _MessagesPortalPageState();
}

class _MessagesPortalPageState extends State<_MessagesPortalPage> {
  final _search = TextEditingController();
  String _filter = 'all';
  int? _selectedThreadId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final query = _search.text.trim().toLowerCase();
    final visibleThreads = portal.threads.where((thread) {
      if (_filter == 'unread' && (valueInt(thread['unread_count']) ?? 0) == 0) {
        return false;
      }
      if (_filter == 'muted' && thread['notifications_muted'] != true) {
        return false;
      }
      if (query.isEmpty) return true;
      return portal.threadTitle(thread).toLowerCase().contains(query) ||
          valueText(thread, const [
            'subject',
          ], fallback: '').toLowerCase().contains(query);
    }).toList();
    final online = portal.contacts
        .where((item) => item['is_online'] == true)
        .length;
    final unread = portal.threads.fold<int>(
      0,
      (total, item) => total + (valueInt(item['unread_count']) ?? 0),
    );
    final desktop = MediaQuery.sizeOf(context).width >= 1180;
    final selectedId =
        visibleThreads.any(
          (thread) => valueInt(thread['id']) == _selectedThreadId,
        )
        ? _selectedThreadId
        : visibleThreads.firstOrNull == null
        ? null
        : valueInt(visibleThreads.first['id']);

    void openThread(Map<String, Object?> thread) {
      final id = valueInt(thread['id']);
      if (id == null) return;
      if (desktop) {
        setState(() => _selectedThreadId = id);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PortalScope(
            controller: portal,
            child: _ThreadScreen(threadId: id),
          ),
        ),
      );
    }

    return _PortalPage(
      title: portal.isParent ? 'Maktab bilan chat' : 'Chat',
      subtitle: portal.isParent
          ? 'Ustozlar va markaz xodimlari bilan xavfsiz oilaviy muloqot.'
          : 'Ustozlar bilan tezkor, himoyalangan va faylli muloqot.',
      section: PortalSection.messages,
      trailing: FilledButton.tonalIcon(
        onPressed: portal.contacts.isEmpty
            ? null
            : () => _newConversation(context, portal),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Yangi suhbat'),
      ),
      children: [
        _MessengerOverview(
          conversations: portal.threads.length,
          contacts: portal.contacts.length,
          online: online,
          unread: unread,
        ),
        const SizedBox(height: 12),
        if (desktop)
          Container(
            height: (MediaQuery.sizeOf(context).height - 320).clamp(
              360.0,
              690.0,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.shadow.withValues(alpha: 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 350,
                  child: _ConversationBrowser(
                    portal: portal,
                    threads: visibleThreads,
                    search: _search,
                    filter: _filter,
                    unread: unread,
                    selectedThreadId: selectedId,
                    fill: true,
                    onChanged: () => setState(() {}),
                    onFilter: (value) => setState(() => _filter = value),
                    onOpen: openThread,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(
                  child: selectedId == null
                      ? const _ChatWelcomePane()
                      : _ThreadScreen(
                          key: ValueKey(selectedId),
                          threadId: selectedId,
                          embedded: true,
                        ),
                ),
              ],
            ),
          )
        else
          _SectionCard(
            padding: EdgeInsets.zero,
            child: _ConversationBrowser(
              portal: portal,
              threads: visibleThreads,
              search: _search,
              filter: _filter,
              unread: unread,
              selectedThreadId: null,
              fill: false,
              onChanged: () => setState(() {}),
              onFilter: (value) => setState(() => _filter = value),
              onOpen: openThread,
            ),
          ),
      ],
    );
  }

  Future<void> _newConversation(
    BuildContext context,
    PortalController portal,
  ) async {
    final selected = <int>{};
    final subject = TextEditingController();
    final body = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yangi suhbat'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Qabul qiluvchilar',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 230),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final contact in portal.contacts)
                          if (valueInt(contact['user_id'] ?? contact['id'])
                              case final id?)
                            CheckboxListTile(
                              value: selected.contains(id),
                              secondary: CircleAvatar(
                                child: Text(
                                  _initials(
                                    valueText(contact, const ['display_name']),
                                  ),
                                ),
                              ),
                              title: Text(
                                valueText(contact, const [
                                  'display_name',
                                  'username',
                                ]),
                              ),
                              subtitle: Text(
                                '${valueText(contact, const ['role_label'])}${contact['is_online'] == true ? ' · online' : ''}',
                              ),
                              onChanged: (checked) => setDialogState(() {
                                if (checked == true) {
                                  selected.add(id);
                                } else {
                                  selected.remove(id);
                                }
                              }),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subject,
                    decoration: const InputDecoration(labelText: 'Mavzu'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: body,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Birinchi xabar',
                      alignLabelWithHint: true,
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
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Boshlash'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || selected.isEmpty || !context.mounted) {
      subject.dispose();
      body.dispose();
      return;
    }
    try {
      final id = await portal.createThread(
        participantIds: selected.toList(),
        subject: subject.text,
        firstBody: body.text,
      );
      if (context.mounted && id > 0) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PortalScope(
              controller: portal,
              child: _ThreadScreen(threadId: id),
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      subject.dispose();
      body.dispose();
    }
  }
}

class _ConversationBrowser extends StatelessWidget {
  const _ConversationBrowser({
    required this.portal,
    required this.threads,
    required this.search,
    required this.filter,
    required this.unread,
    required this.selectedThreadId,
    required this.fill,
    required this.onChanged,
    required this.onFilter,
    required this.onOpen,
  });

  final PortalController portal;
  final List<Map<String, Object?>> threads;
  final TextEditingController search;
  final String filter;
  final int unread;
  final int? selectedThreadId;
  final bool fill;
  final VoidCallback onChanged;
  final ValueChanged<String> onFilter;
  final ValueChanged<Map<String, Object?>> onOpen;

  @override
  Widget build(BuildContext context) {
    final list = threads.isEmpty
        ? _ChatEmptyPane(
            filtered: search.text.trim().isNotEmpty || filter != 'all',
          )
        : ListView.separated(
            shrinkWrap: !fill,
            physics: fill ? null : const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
            itemCount: threads.length,
            separatorBuilder: (_, _) => const SizedBox(height: 2),
            itemBuilder: (context, index) {
              final thread = threads[index];
              final threadId = valueInt(thread['id']);
              final cachedRows = threadId == null
                  ? null
                  : portal.messages[threadId];
              final latest = cachedRows?.lastOrNull;
              return _ConversationTile(
                thread: thread,
                title: portal.threadTitle(thread),
                contact: _threadContact(portal, thread),
                latestMessage: latest,
                selfUserId: portal.messagingSelfUserId,
                selected: threadId == selectedThreadId,
                onTap: () => onOpen(thread),
              );
            },
          );
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: search,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                hintText: 'Suhbatlarni qidirish',
                prefixIcon: const Icon(Icons.search_rounded, size: 21),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Tozalash',
                        onPressed: () {
                          search.clear();
                          onChanged();
                        },
                        icon: const Icon(Icons.close_rounded, size: 19),
                      ),
                isDense: true,
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _ChatFilterChip(
                  label: 'Barchasi',
                  selected: filter == 'all',
                  onTap: () => onFilter('all'),
                ),
                const SizedBox(width: 7),
                _ChatFilterChip(
                  label: 'O‘qilmagan',
                  count: unread,
                  selected: filter == 'unread',
                  onTap: () => onFilter('unread'),
                ),
                const SizedBox(width: 7),
                _ChatFilterChip(
                  label: 'Ovozsiz',
                  icon: Icons.volume_off_outlined,
                  selected: filter == 'muted',
                  onTap: () => onFilter('muted'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          if (fill) Expanded(child: list) else list,
        ],
      ),
    );
  }
}

class _ChatFilterChip extends StatelessWidget {
  const _ChatFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count = 0,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int count;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 16,
              color: selected ? colors.onPrimary : colors.onSurfaceVariant,
            ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? colors.onPrimary.withValues(alpha: 0.18)
                    : colors.primary,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? colors.onPrimary : colors.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
      labelStyle: TextStyle(
        color: selected ? colors.onPrimary : colors.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      ),
      backgroundColor: selected ? colors.primary : colors.surfaceContainerHigh,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      onPressed: onTap,
    );
  }
}

class _ChatEmptyPane extends StatelessWidget {
  const _ChatEmptyPane({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filtered ? Icons.search_off_rounded : Icons.forum_outlined,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            filtered ? 'Suhbat topilmadi' : 'Hozircha suhbat yo‘q',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            filtered
                ? 'Qidiruv yoki filtrni o‘zgartiring.'
                : 'Yuqoridagi tugma orqali maktab kontaktiga yozing.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _ChatWelcomePane extends StatelessWidget {
  const _ChatWelcomePane();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceContainerLowest,
            colors.primaryContainer.withValues(alpha: 0.42),
          ],
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 330),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: colors.primaryContainer,
                child: Icon(
                  Icons.mark_chat_unread_rounded,
                  size: 32,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Suhbatni tanlang',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 7),
              Text(
                'Xabarlar faqat suhbat ishtirokchilariga ko‘rinadi. Tarix o‘zgartirilmaydi.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessengerOverview extends StatelessWidget {
  const _MessengerOverview({
    required this.conversations,
    required this.contacts,
    required this.online,
    required this.unread,
  });

  final int conversations;
  final int contacts;
  final int online;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer,
            colors.tertiaryContainer.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(Icons.forum_rounded, color: colors.onPrimary, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unread == 0
                      ? 'Barcha xabarlar o‘qilgan'
                      : '$unread ta yangi xabar bor',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Maktab bilan yopiq va xavfsiz aloqa',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 7,
              runSpacing: 7,
              children: [
                _MessengerStat(
                  label: 'suhbat',
                  value: '$conversations',
                  icon: Icons.chat_bubble_outline_rounded,
                ),
                _MessengerStat(
                  label: 'kontakt',
                  value: '$contacts',
                  icon: Icons.people_outline_rounded,
                ),
                _MessengerStat(
                  label: 'online',
                  value: '$online',
                  icon: Icons.circle,
                  positive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessengerStat extends StatelessWidget {
  const _MessengerStat({
    required this.label,
    required this.value,
    required this.icon,
    this.positive = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: icon == Icons.circle ? 9 : 16,
            color: positive ? Sf.success : colors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.thread,
    required this.title,
    required this.contact,
    required this.latestMessage,
    required this.selfUserId,
    required this.selected,
    required this.onTap,
  });

  final Map<String, Object?> thread;
  final Map<String, Object?> contact;
  final Map<String, Object?>? latestMessage;
  final int? selfUserId;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = valueInt(thread['unread_count']) ?? 0;
    final online = contact['is_online'] == true;
    final participants = thread['participants'] is List
        ? (thread['participants'] as List).length
        : 0;
    final latestBody = valueText(latestMessage ?? const {}, const [
      'body',
    ], fallback: '');
    final latestAttachments = latestMessage?['attachments'];
    final hasLatestAttachment =
        latestAttachments is List && latestAttachments.isNotEmpty;
    final subject = valueText(thread, const [
      'subject',
    ], fallback: participants > 2 ? 'Guruh suhbati' : 'Shaxsiy suhbat');
    final preview = latestBody.isNotEmpty
        ? latestBody
        : hasLatestAttachment
        ? 'Biriktirilgan fayl'
        : subject;
    final mine = valueInt(latestMessage?['sender']) == selfUserId;
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryContainer.withValues(alpha: 0.68)
              : count > 0
              ? colors.surfaceContainerHigh.withValues(alpha: 0.55)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.primary,
                        colors.tertiary.withValues(alpha: 0.86),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: participants > 2
                      ? Icon(
                          Icons.groups_2_rounded,
                          color: colors.onPrimary,
                          size: 23,
                        )
                      : Text(
                          _initials(title),
                          style: TextStyle(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                if (online)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: Sf.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? colors.primaryContainer
                              : colors.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: count > 0
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                        ),
                      ),
                      Text(
                        _dateLabel(
                          thread['last_message_at'] ?? thread['created_at'],
                          time: true,
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: count > 0
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          fontWeight: count > 0
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (thread['notifications_muted'] == true) ...[
                        Icon(
                          Icons.volume_off_rounded,
                          size: 15,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (latestMessage != null && mine) ...[
                        Icon(
                          Icons.done_all_rounded,
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (hasLatestAttachment) ...[
                        Icon(
                          _isAudioAttachment('${latestAttachments.first}')
                              ? Icons.mic_rounded
                              : Icons.attach_file_rounded,
                          size: 15,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 3),
                      ],
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: count > 0
                                    ? colors.onSurface
                                    : colors.onSurfaceVariant,
                                fontWeight: count > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                        ),
                      ),
                      if (count > 0)
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                    ],
                  ),
                  if (latestMessage == null && contact.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      valueText(contact, const ['role_label']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _workspaceThreadTitle(
  PortalController portal,
  Map<String, Object?> thread,
) {
  final participants = thread['participants'];
  final subject = valueText(thread, const ['subject'], fallback: '');
  if (participants is List && participants.length > 2) {
    return subject.isNotEmpty ? subject : 'Guruh suhbati';
  }
  return portal.threadTitle(thread);
}

Map<String, Object?> _threadContact(
  PortalController portal,
  Map<String, Object?> thread,
) {
  final participants = thread['participants'];
  if (participants is List) {
    for (final raw in participants) {
      if (raw is! Map) continue;
      final id = valueInt(raw['user']);
      if (id == null || id == portal.messagingSelfUserId) continue;
      return portal.contacts
              .where((item) => valueInt(item['user_id'] ?? item['id']) == id)
              .firstOrNull ??
          const {};
    }
  }
  return const {};
}

class _ThreadScreen extends StatefulWidget {
  const _ThreadScreen({
    super.key,
    required this.threadId,
    this.embedded = false,
  });

  final int threadId;
  final bool embedded;

  @override
  State<_ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<_ThreadScreen> {
  final _composer = TextEditingController();
  final _messageSearch = TextEditingController();
  final List<PlatformFile> _pendingFiles = [];
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _recordTimer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  bool _sending = false;
  bool _searching = false;
  bool _recording = false;
  bool _preparingVoice = false;
  bool _loadingMessages = true;
  Object? _loadError;
  String _sendingProgress = '';
  Duration _recordDuration = Duration.zero;
  double _recordLevel = 0;
  String _voiceExtension = 'webm';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_loadCurrentMessages());
      }
    });
  }

  Future<void> _loadCurrentMessages({bool force = false}) async {
    final portal = PortalScope.read(context);
    if (mounted) {
      setState(() {
        _loadingMessages = true;
        _loadError = null;
      });
    }
    try {
      await portal.loadMessages(widget.threadId, force: force);
      final controllerError = portal.messageErrors[widget.threadId];
      if (controllerError != null && mounted) {
        setState(() => _loadError = controllerError);
        if (portal.messages.containsKey(widget.threadId)) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(controllerError)));
        }
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _loadError = error);
        if (portal.messages.containsKey(widget.threadId)) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_errorText(error))));
        }
      }
    } finally {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    unawaited(_amplitudeSubscription?.cancel());
    unawaited(_recorder.dispose());
    _composer.dispose();
    _messageSearch.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null || !mounted) return;
    final remaining = 10 - _pendingFiles.length;
    setState(() {
      _pendingFiles.addAll(result.files.take(remaining));
    });
    if (result.files.length > remaining && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitta xabarga ko‘pi bilan 10 ta fayl.')),
      );
    }
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'ogg', 'opus', 'wav', 'webm'],
      withData: true,
    );
    if (result == null || !mounted) return;
    setState(() {
      if (_pendingFiles.length < 10) _pendingFiles.add(result.files.single);
    });
  }

  Future<void> _startVoiceRecording() async {
    if (_sending || _recording || _preparingVoice) return;
    setState(() => _preparingVoice = true);
    try {
      if (!await _recorder.hasPermission()) {
        throw const ApiException(
          message: 'Ovoz yozish uchun mikrofon ruxsatini bering.',
          code: 'microphone_permission_denied',
        );
      }
      final opusSupported = await _recorder.isEncoderSupported(
        AudioEncoder.opus,
      );
      _voiceExtension = opusSupported ? 'webm' : 'wav';
      await _recorder.start(
        RecordConfig(
          encoder: opusSupported ? AudioEncoder.opus : AudioEncoder.wav,
          bitRate: 64000,
          sampleRate: 48000,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: '',
      );
      _recordDuration = Duration.zero;
      _recordLevel = 0;
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _recordDuration += const Duration(seconds: 1));
        }
      });
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((amplitude) {
            if (!mounted) return;
            final normalized = ((amplitude.current + 60) / 60)
                .clamp(0.0, 1.0)
                .toDouble();
            setState(() => _recordLevel = normalized);
          });
      if (mounted) setState(() => _recording = true);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      if (mounted) setState(() => _preparingVoice = false);
    }
  }

  Future<void> _finishVoiceRecording({required bool discard}) async {
    if (!_recording) return;
    final duration = _recordDuration;
    _recordTimer?.cancel();
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    setState(() {
      _recording = false;
      _preparingVoice = true;
      _recordLevel = 0;
    });
    try {
      if (discard) {
        await _recorder.cancel();
        return;
      }
      final path = await _recorder.stop();
      if (path == null || path.isEmpty) {
        throw const ApiException(
          message: 'Ovozli xabarni saqlab bo‘lmadi.',
          code: 'voice_recording_failed',
        );
      }
      final bytes = await readRecordedFileBytes(path);
      final seconds = duration.inSeconds.clamp(1, 599);
      final filename =
          'voice-${seconds}s-${DateTime.now().millisecondsSinceEpoch}.$_voiceExtension';
      final file = PlatformFile(
        name: filename,
        size: bytes.length,
        bytes: bytes,
      );
      if (mounted) {
        setState(() {
          if (_pendingFiles.length < 10) _pendingFiles.add(file);
        });
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _preparingVoice = false;
          _recordDuration = Duration.zero;
        });
      }
    }
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if ((text.isEmpty && _pendingFiles.isEmpty) || _sending) return;
    setState(() => _sending = true);
    try {
      final portal = PortalScope.read(context);
      final attachments = <String>[];
      for (var index = 0; index < _pendingFiles.length; index++) {
        final file = _pendingFiles[index];
        if (mounted) {
          setState(
            () => _sendingProgress =
                '${index + 1}/${_pendingFiles.length} fayl yuklanmoqda',
          );
        }
        final bytes = file.bytes;
        if (bytes == null) {
          throw ApiException(message: '${file.name} faylini o‘qib bo‘lmadi.');
        }
        attachments.add(
          await portal.uploadMessageFile(
            filename: file.name,
            contentType: _contentType(file.extension),
            bytes: bytes,
          ),
        );
      }
      if (mounted) setState(() => _sendingProgress = 'Xabar yuborilmoqda');
      await portal.sendMessage(widget.threadId, text, attachments: attachments);
      _composer.clear();
      _pendingFiles.clear();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _sendingProgress = '';
        });
      }
    }
  }

  Future<void> _showAttachmentPicker() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: Text(
                  'Xabarga biriktirish',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _AttachmentChoice(
                icon: Icons.insert_drive_file_outlined,
                title: 'Hujjat yoki rasm',
                subtitle: 'Qurilmadan 10 tagacha fayl tanlang',
                onTap: () => Navigator.pop(context, 'files'),
              ),
              const SizedBox(height: 8),
              _AttachmentChoice(
                icon: Icons.audio_file_outlined,
                title: 'Tayyor audio',
                subtitle: 'MP3, M4A, OGG, WAV yoki WEBM',
                onTap: () => Navigator.pop(context, 'audio'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'files') await _pickFiles();
    if (choice == 'audio') await _pickAudioFile();
  }

  void _insertEmoji(String emoji) {
    final selection = _composer.selection;
    final start = selection.isValid ? selection.start : _composer.text.length;
    final end = selection.isValid ? selection.end : _composer.text.length;
    _composer.value = TextEditingValue(
      text: _composer.text.replaceRange(start, end, emoji),
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  Future<void> _showEmojiPicker() async {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final emoji = wide
        ? await showDialog<String>(
            context: context,
            builder: (context) => const Dialog(
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: 440,
                height: 430,
                child: _EmojiPickerContent(),
              ),
            ),
          )
        : await showModalBottomSheet<String>(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (context) => const SafeArea(
              child: SizedBox(height: 410, child: _EmojiPickerContent()),
            ),
          );
    if (emoji != null && mounted) _insertEmoji(emoji);
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final thread = portal.threads
        .where((item) => valueInt(item['id']) == widget.threadId)
        .firstOrNull;
    final contact = _threadContact(portal, thread ?? const {});
    final allRows = portal.messages[widget.threadId];
    final effectiveLoadError =
        _loadError ?? portal.messageErrors[widget.threadId];
    final query = _messageSearch.text.trim().toLowerCase();
    final rows = allRows
        ?.where(
          (message) =>
              query.isEmpty ||
              valueText(message, const [
                'body',
              ], fallback: '').toLowerCase().contains(query),
        )
        .toList();
    rows?.sort(
      (left, right) =>
          '${left['created_at']}'.compareTo('${right['created_at']}'),
    );
    final self = portal.messagingSelfUserId;
    final participants = thread?['participants'] is List
        ? (thread!['participants'] as List).length
        : 0;
    final title = _workspaceThreadTitle(portal, thread ?? const {});
    final subject = valueText(thread ?? const {}, const [
      'subject',
    ], fallback: '');
    final canWrite = portal.can('messaging:write');
    final colors = Theme.of(context).colorScheme;
    final narrowHeader = MediaQuery.sizeOf(context).width < 430;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        key: const ValueKey('family-chat-header'),
        automaticallyImplyLeading: false,
        toolbarHeight: 62,
        shape: Border(bottom: BorderSide(color: colors.outlineVariant)),
        leading: widget.embedded
            ? null
            : IconButton(
                tooltip: 'Suhbatlarga qaytish',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: colors.surface,
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  child: Text(
                    _initials(title),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                if (contact['is_online'] == true)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: Sf.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(
                    contact['is_online'] == true
                        ? 'online'
                        : participants > 2
                        ? '$participants ishtirokchi'
                        : valueText(contact, const [
                            'role_label',
                          ], fallback: 'Maktab kontakti'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: contact['is_online'] == true
                          ? Sf.success
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _searching ? 'Qidiruvni yopish' : 'Suhbat ichida qidirish',
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _messageSearch.clear();
            }),
            icon: Icon(
              _searching ? Icons.search_off_rounded : Icons.search_rounded,
            ),
          ),
          if (!narrowHeader)
            IconButton(
              tooltip: 'Yangilash',
              onPressed: _loadingMessages
                  ? null
                  : () => _loadCurrentMessages(force: true),
              icon: _loadingMessages
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          if (!narrowHeader)
            IconButton(
              tooltip: thread?['notifications_muted'] == true
                  ? 'Bildirishnomani yoqish'
                  : 'Ovozsiz qilish',
              onPressed: thread == null
                  ? null
                  : () => _runAction(
                      context,
                      () => portal.setThreadMuted(
                        widget.threadId,
                        thread['notifications_muted'] != true,
                      ),
                      success: thread['notifications_muted'] == true
                          ? 'Bildirishnomalar yoqildi.'
                          : 'Suhbat ovozsiz qilindi.',
                    ),
              icon: Icon(
                thread?['notifications_muted'] == true
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_outlined,
              ),
            ),
          if (narrowHeader)
            PopupMenuButton<String>(
              tooltip: 'Suhbat amallari',
              onSelected: (value) {
                if (value == 'refresh') {
                  _loadCurrentMessages(force: true);
                  return;
                }
                if (value == 'mute' && thread != null) {
                  _runAction(
                    context,
                    () => portal.setThreadMuted(
                      widget.threadId,
                      thread['notifications_muted'] != true,
                    ),
                    success: thread['notifications_muted'] == true
                        ? 'Bildirishnomalar yoqildi.'
                        : 'Suhbat ovozsiz qilindi.',
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: ListTile(
                    leading: Icon(Icons.refresh_rounded),
                    title: Text('Yangilash'),
                  ),
                ),
                PopupMenuItem(
                  value: 'mute',
                  enabled: thread != null,
                  child: ListTile(
                    leading: Icon(
                      thread?['notifications_muted'] == true
                          ? Icons.notifications_outlined
                          : Icons.notifications_off_outlined,
                    ),
                    title: Text(
                      thread?['notifications_muted'] == true
                          ? 'Bildirishnomani yoqish'
                          : 'Ovozsiz qilish',
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (_searching)
            Container(
              key: const ValueKey('family-chat-search-header'),
              color: colors.surface,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('family-chat-message-search'),
                      controller: _messageSearch,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        hintText: 'Xabar matnini qidiring',
                        isDense: true,
                        suffixIcon: _messageSearch.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _messageSearch.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      query.isEmpty ? '—' : '${rows?.length ?? 0} ta',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (subject.isNotEmpty && subject != title)
            Container(
              height: 37,
              color: colors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.tag_rounded, size: 16, color: colors.primary),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'yopiq kanal',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ChatBackgroundPainter(
                      color: colors.primary.withValues(alpha: 0.055),
                    ),
                  ),
                ),
                if (allRows == null && effectiveLoadError != null)
                  _MessageErrorPane(
                    error: effectiveLoadError,
                    onRetry: () => _loadCurrentMessages(force: true),
                  )
                else if (rows == null)
                  const _MessageLoadingPane()
                else if (rows.isEmpty)
                  _MessageEmptyPane(searching: query.isNotEmpty)
                else
                  ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                    itemCount: rows.length,
                    itemBuilder: (context, reverseIndex) {
                      final messageIndex = rows.length - reverseIndex - 1;
                      final message = rows[messageIndex];
                      final sender = valueInt(message['sender']);
                      final mine = sender == self;
                      final currentDay = _dateLabel(message['created_at']);
                      final previous = messageIndex > 0
                          ? rows[messageIndex - 1]
                          : null;
                      final next = messageIndex + 1 < rows.length
                          ? rows[messageIndex + 1]
                          : null;
                      final previousDay = previous == null
                          ? null
                          : _dateLabel(previous['created_at']);
                      final nextDay = next == null
                          ? null
                          : _dateLabel(next['created_at']);
                      final firstInGroup =
                          previous == null ||
                          valueInt(previous['sender']) != sender ||
                          previousDay != currentDay;
                      final lastInGroup =
                          next == null ||
                          valueInt(next['sender']) != sender ||
                          nextDay != currentDay;
                      final senderContact = portal.contacts
                          .where(
                            (item) =>
                                valueInt(item['user_id'] ?? item['id']) ==
                                sender,
                          )
                          .firstOrNull;
                      return _MessageBubble(
                        message: message,
                        mine: mine,
                        showDate:
                            messageIndex == 0 || currentDay != previousDay,
                        firstInGroup: firstInGroup,
                        lastInGroup: lastInGroup,
                        senderName: mine
                            ? portal.displayName
                            : valueText(senderContact ?? const {}, const [
                                'display_name',
                                'username',
                              ], fallback: 'Maktab vakili'),
                        readByOther: mine
                            ? _messageReadByOther(
                                thread: thread,
                                message: message,
                                selfUserId: self,
                              )
                            : false,
                        onAttachment: (key) => _runAction(context, () async {
                          final url = await portal.messageAttachmentDownloadUrl(
                            widget.threadId,
                            key,
                          );
                          if (context.mounted) await _launch(context, url);
                        }, success: 'Fayl ochildi.'),
                      );
                    },
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Material(
              elevation: 0,
              color: colors.surface,
              shape: Border(top: BorderSide(color: colors.outlineVariant)),
              child: canWrite
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_sendingProgress.isNotEmpty) ...[
                            Row(
                              children: [
                                const SizedBox.square(
                                  dimension: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _sendingProgress,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                          ],
                          if (_pendingFiles.isNotEmpty) ...[
                            Row(
                              children: [
                                Text(
                                  'TAYYOR FAYLLAR',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_pendingFiles.length}/10',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 50,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _pendingFiles.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 7),
                                itemBuilder: (context, index) =>
                                    _PendingFileChip(
                                      file: _pendingFiles[index],
                                      onRemove: _sending
                                          ? null
                                          : () => setState(
                                              () =>
                                                  _pendingFiles.removeAt(index),
                                            ),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 7),
                          ],
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (_recording) ...[
                                IconButton(
                                  tooltip: 'Yozuvni bekor qilish',
                                  onPressed: () =>
                                      _finishVoiceRecording(discard: true),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                ),
                                Expanded(
                                  child: _VoiceRecordingBar(
                                    duration: _recordDuration,
                                    level: _recordLevel,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  tooltip: 'Yozuvni tayyorlash',
                                  onPressed: () =>
                                      _finishVoiceRecording(discard: false),
                                  icon: const Icon(Icons.check_rounded),
                                ),
                              ] else ...[
                                IconButton.filledTonal(
                                  tooltip: 'Fayl biriktirish',
                                  onPressed: _sending || _preparingVoice
                                      ? null
                                      : _showAttachmentPicker,
                                  icon: const Icon(Icons.attach_file_rounded),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: colors.outlineVariant.withValues(
                                          alpha: 0.72,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          tooltip: 'Emoji tanlash',
                                          onPressed: _showEmojiPicker,
                                          icon: const Icon(
                                            Icons
                                                .sentiment_satisfied_alt_rounded,
                                          ),
                                        ),
                                        Expanded(
                                          child: TextField(
                                            key: const ValueKey(
                                              'family-chat-composer',
                                            ),
                                            controller: _composer,
                                            onChanged: (_) => setState(() {}),
                                            minLines: 1,
                                            maxLines: 6,
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                            textInputAction:
                                                TextInputAction.newline,
                                            decoration: const InputDecoration(
                                              hintText: 'Xabar yozing…',
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              filled: false,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: 13,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_composer.text.trim().isEmpty &&
                                    _pendingFiles.isEmpty)
                                  IconButton.filled(
                                    tooltip: 'Ovozli xabar yozish',
                                    onPressed: _sending || _preparingVoice
                                        ? null
                                        : _startVoiceRecording,
                                    icon: _preparingVoice
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.mic_rounded),
                                  )
                                else
                                  IconButton.filled(
                                    tooltip: 'Xabar yuborish',
                                    onPressed: _sending || _preparingVoice
                                        ? null
                                        : _send,
                                    icon: _sending
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.send_rounded),
                                  ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    )
                  : const _ReadOnlyChatBar(),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceRecordingBar extends StatelessWidget {
  const _VoiceRecordingBar({required this.duration, required this.level});

  final Duration duration;
  final double level;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: colors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$minutes:$seconds',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var index = 0; index < 18; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 3,
                    height:
                        5 +
                        23 * (((index % 4) + 1) / 4) * (0.22 + level * 0.78),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Ovoz yozilmoqda',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _AttachmentChoice extends StatelessWidget {
  const _AttachmentChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class _ReadOnlyChatBar extends StatelessWidget {
  const _ReadOnlyChatBar();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 19,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bu suhbat faqat o‘qish uchun ochilgan.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}

bool _messageReadByOther({
  required Map<String, Object?>? thread,
  required Map<String, Object?> message,
  required int? selfUserId,
}) {
  final createdAt = DateTime.tryParse('${message['created_at'] ?? ''}');
  final participants = thread?['participants'];
  if (createdAt == null || participants is! List) return false;
  for (final raw in participants) {
    if (raw is! Map || valueInt(raw['user']) == selfUserId) continue;
    final lastReadAt = DateTime.tryParse('${raw['last_read_at'] ?? ''}');
    if (lastReadAt != null && !lastReadAt.isBefore(createdAt)) return true;
  }
  return false;
}

bool _isAudioAttachment(String key) {
  final normalized = key.toLowerCase().split('?').first;
  return const [
    '.mp3',
    '.m4a',
    '.aac',
    '.ogg',
    '.opus',
    '.wav',
    '.webm',
  ].any(normalized.endsWith);
}

String _attachmentDisplayName(String key) {
  final name = Uri.decodeComponent(key.split('?').first.split('/').last);
  final withoutGrantPrefix = name.replaceFirst(
    RegExp(r'^[0-9a-f]{8,}-', caseSensitive: false),
    '',
  );
  return withoutGrantPrefix.isEmpty ? 'Biriktirilgan fayl' : withoutGrantPrefix;
}

String _voiceDurationLabel(String key) {
  final match = RegExp(r'voice-(\d+)s-').firstMatch(key.toLowerCase());
  final totalSeconds = int.tryParse(match?.group(1) ?? '');
  if (totalSeconds == null) return 'Ovozli xabar';
  final minutes = (totalSeconds ~/ 60).toString();
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return 'Ovozli xabar · $minutes:$seconds';
}

IconData _attachmentIcon(String key) {
  final normalized = key.toLowerCase().split('?').first;
  if (_isAudioAttachment(key)) return Icons.graphic_eq_rounded;
  if (normalized.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
  if (normalized.endsWith('.png') ||
      normalized.endsWith('.jpg') ||
      normalized.endsWith('.jpeg')) {
    return Icons.image_outlined;
  }
  if (normalized.endsWith('.doc') || normalized.endsWith('.docx')) {
    return Icons.description_outlined;
  }
  return Icons.insert_drive_file_outlined;
}

class _PendingFileChip extends StatelessWidget {
  const _PendingFileChip({required this.file, required this.onRemove});

  final PlatformFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.fromLTRB(9, 6, 4, 6),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _attachmentIcon(file.name),
              size: 19,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _fileSize(file.size),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Olib tashlash',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _EmojiPickerContent extends StatelessWidget {
  const _EmojiPickerContent();

  static const _popular = [
    '👍',
    '❤️',
    '😊',
    '😂',
    '👏',
    '🎉',
    '🙏',
    '🔥',
    '✨',
    '💯',
    '✅',
    '🤝',
    '💪',
    '👌',
    '🙌',
    '🌟',
    '🤩',
    '🥳',
    '😍',
    '🤗',
    '💙',
    '💜',
    '🤍',
    '😁',
    '😉',
    '😎',
    '🤔',
    '😅',
    '🙂',
    '😇',
    '🫶',
    '👋',
  ];
  static const _faces = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '🥹',
    '😅',
    '😂',
    '🤣',
    '😊',
    '😌',
    '😉',
    '🙃',
    '🙂',
    '🥰',
    '😍',
    '🤩',
    '😘',
    '😋',
    '😛',
    '🤪',
    '🤓',
    '🧐',
    '🤔',
    '🫡',
    '🤗',
    '🤭',
    '🫢',
    '😶',
    '😐',
    '😴',
    '🥱',
    '😔',
    '😕',
    '🫤',
    '😟',
    '🥺',
    '😢',
    '😭',
    '😤',
  ];
  static const _school = [
    '📚',
    '📖',
    '✏️',
    '📝',
    '🎓',
    '🏫',
    '🧠',
    '💡',
    '📌',
    '📎',
    '📐',
    '📏',
    '🔬',
    '🧪',
    '💻',
    '🎨',
    '🏆',
    '🥇',
    '⭐',
    '🚀',
    '⏰',
    '📅',
    '🔔',
    '📣',
    '✅',
    '❗',
    '❓',
    '➡️',
    '⬆️',
    '💬',
    '📨',
    '🎯',
  ];

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Emoji tanlang',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Yopish',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.schedule_rounded), text: 'Mashhur'),
            Tab(icon: Icon(Icons.mood_rounded), text: 'Kayfiyat'),
            Tab(icon: Icon(Icons.school_rounded), text: 'O‘qish'),
          ],
        ),
        const Expanded(
          child: TabBarView(
            children: [
              _EmojiGrid(emojis: _popular),
              _EmojiGrid(emojis: _faces),
              _EmojiGrid(emojis: _school),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({required this.emojis});

  final List<String> emojis;

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(14),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 58,
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
    ),
    itemCount: emojis.length,
    itemBuilder: (context, index) => InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () => Navigator.pop(context, emojis[index]),
      child: Center(
        child: Text(emojis[index], style: const TextStyle(fontSize: 27)),
      ),
    ),
  );
}

class _MessageLoadingPane extends StatelessWidget {
  const _MessageLoadingPane();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'Xabarlar yuklanmoqda…',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MessageErrorPane extends StatelessWidget {
  const _MessageErrorPane({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 38,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Xabarlar ochilmadi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            error is String ? error as String : _errorText(error),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 15),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Qayta urinish'),
          ),
        ],
      ),
    ),
  );
}

class _MessageEmptyPane extends StatelessWidget {
  const _MessageEmptyPane({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.all(22),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off_rounded : Icons.waving_hand_rounded,
              size: 38,
              color: colors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              searching ? 'Mos xabar topilmadi' : 'Suhbatni boshlang',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              searching
                  ? 'Boshqa so‘z bilan qidirib ko‘ring.'
                  : 'Savol yozing yoki vazifaga tegishli fayl yuboring.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBackgroundPainter extends CustomPainter {
  const _ChatBackgroundPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = color;
    final line = Paint()
      ..color = color
      ..strokeWidth = 1.15
      ..style = PaintingStyle.stroke;
    const step = 54.0;
    for (var y = 18.0; y < size.height; y += step) {
      for (var x = 18.0; x < size.width; x += step) {
        final shiftedX = x + (((y / step).round().isEven) ? 0 : step / 2);
        canvas.drawCircle(Offset(shiftedX, y), 2, dot);
        if (((x + y) / step).round().isEven) {
          canvas.drawArc(
            Rect.fromCircle(center: Offset(shiftedX + 12, y + 12), radius: 5),
            0.2,
            2.25,
            false,
            line,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChatBackgroundPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.showDate,
    required this.firstInGroup,
    required this.lastInGroup,
    required this.senderName,
    required this.readByOther,
    required this.onAttachment,
  });

  final Map<String, Object?> message;
  final bool mine;
  final bool showDate;
  final bool firstInGroup;
  final bool lastInGroup;
  final String senderName;
  final bool readByOther;
  final ValueChanged<String> onAttachment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final body = valueText(message, const ['body'], fallback: '');
    final rawAttachments = message['attachments'];
    final attachments = rawAttachments is List
        ? rawAttachments
              .map((item) => '$item')
              .where((item) => item.isNotEmpty)
              .toList()
        : const <String>[];
    final foreground = mine ? colors.onPrimary : colors.onSurface;
    final bubbleColor = mine ? colors.primary : colors.surface;
    final maxBubbleWidth = (MediaQuery.sizeOf(context).width * 0.76)
        .clamp(220.0, 560.0)
        .toDouble();
    return Column(
      children: [
        if (showDate)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: colors.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.04),
                    blurRadius: 9,
                  ),
                ],
              ),
              child: Text(
                _dateLabel(message['created_at']),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            child: GestureDetector(
              onLongPress: body.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: body));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Xabar nusxalandi.')),
                        );
                      }
                    },
              child: Container(
                margin: EdgeInsets.only(bottom: lastInGroup ? 9 : 2),
                padding: const EdgeInsets.fromLTRB(13, 9, 9, 6),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  border: Border.all(
                    color: mine ? colors.primary : colors.outlineVariant,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(!mine && !firstInGroup ? 7 : 15),
                    topRight: Radius.circular(mine && !firstInGroup ? 7 : 15),
                    bottomLeft: Radius.circular(!mine && lastInGroup ? 4 : 15),
                    bottomRight: Radius.circular(mine && lastInGroup ? 4 : 15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!mine && firstInGroup) ...[
                      Text(
                        senderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 3),
                    ],
                    if (body.isNotEmpty)
                      SelectableText(
                        body,
                        style: TextStyle(color: foreground, height: 1.35),
                      ),
                    for (final key in attachments) ...[
                      if (body.isNotEmpty || key != attachments.first)
                        const SizedBox(height: 8),
                      _MessageAttachmentTile(
                        keyName: key,
                        mine: mine,
                        onTap: () => onAttachment(key),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _timeOnly(message['created_at']),
                          style: Sf.monoStyle(
                            size: 8.5,
                            weight: FontWeight.w500,
                            color: foreground.withValues(alpha: 0.72),
                          ),
                        ),
                        if (mine) ...[
                          const SizedBox(width: 3),
                          Tooltip(
                            message: readByOther ? 'O‘qilgan' : 'Yuborilgan',
                            child: Icon(
                              readByOther
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                              size: 16,
                              color: readByOther
                                  ? (mine ? colors.onPrimary : colors.primary)
                                  : foreground.withValues(alpha: 0.68),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageAttachmentTile extends StatelessWidget {
  const _MessageAttachmentTile({
    required this.keyName,
    required this.mine,
    required this.onTap,
  });

  final String keyName;
  final bool mine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final audio = _isAudioAttachment(keyName);
    final foreground = mine ? colors.onPrimary : colors.onSurfaceVariant;
    return Material(
      color: mine
          ? colors.surface.withValues(alpha: 0.18)
          : colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: audio ? 230 : 190),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    audio ? Icons.play_arrow_rounded : _attachmentIcon(keyName),
                    color: colors.onPrimary,
                    size: audio ? 25 : 21,
                  ),
                ),
                const SizedBox(width: 9),
                if (audio) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            for (final height in const [
                              5.0,
                              11.0,
                              17.0,
                              8.0,
                              14.0,
                              20.0,
                              10.0,
                              16.0,
                              7.0,
                              13.0,
                              18.0,
                              9.0,
                            ])
                              Container(
                                width: 2.5,
                                height: height,
                                margin: const EdgeInsets.only(right: 2.5),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_voiceDurationLabel(keyName)} · ochish',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(color: foreground),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _attachmentDisplayName(keyName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          'Ochish uchun bosing',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(color: foreground),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Icon(Icons.download_rounded, color: foreground, size: 19),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsPortalPage extends StatelessWidget {
  const _NotificationsPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final unread = portal.unreadNotificationCount;
    return _PortalPage(
      title: portal.isParent ? 'Muhim xabarlar' : 'Bildirishnomalar',
      subtitle: portal.isParent
          ? 'Davomat, baho, to‘lov va markazdan kelgan oilaviy yangiliklar.'
          : 'Vazifa, dars, baho va akkaunt bo‘yicha shaxsiy yangiliklar.',
      section: PortalSection.notifications,
      trailing: unread == 0
          ? null
          : TextButton.icon(
              onPressed: () => _runAction(
                context,
                portal.markAllNotificationsRead,
                success: 'Barcha bildirishnomalar o‘qildi.',
              ),
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Hammasini o‘qish'),
            ),
      children: [
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'Yuklangan xabarlar',
              value: '${portal.notifications.length}',
              icon: Icons.notifications_outlined,
            ),
            _MetricCard(
              label: 'Yangi',
              value: '$unread',
              icon: Icons.mark_email_unread_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (portal.notifications.isEmpty)
          const _EmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'Bildirishnoma yo‘q',
            message: 'Yangi voqealar shu yerda ko‘rinadi.',
          )
        else
          _SimpleRows(
            rows: portal.notifications,
            icon: Icons.notifications_outlined,
            title: (row) =>
                valueText(row, const ['title'], fallback: 'Bildirishnoma'),
            subtitle: (row) =>
                '${valueText(row, const ['body'], fallback: '')}\n${_dateLabel(row['created_at'], time: true)}',
            trailing: (row) => row['read_at'] == null
                ? const Badge(child: Icon(Icons.circle, size: 12))
                : const Icon(Icons.done_all_rounded),
            onTap: (row) {
              final id = valueInt(row['id']);
              if (id != null && row['read_at'] == null) {
                unawaited(
                  _runAction(
                    context,
                    () => portal.markNotificationRead(id),
                    success: 'O‘qildi.',
                  ),
                );
              }
              final destination = _notificationDestination(row, portal);
              if (destination != null) {
                _PortalNavigationScope.go(context, destination);
                return;
              }
              _showJsonDetail(
                context,
                title: valueText(row, const [
                  'title',
                ], fallback: 'Bildirishnoma'),
                fields: {
                  'Xabar': valueText(row, const ['body'], fallback: ''),
                  'Turi': valueText(row, const ['event_type']),
                  'Vaqt': _dateLabel(row['created_at'], time: true),
                },
              );
            },
          ),
        if (portal.notificationPreferences.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _PageSectionTitle(title: 'Bildirishnoma sozlamalari'),
          const SizedBox(height: 10),
          _NotificationPreferences(rows: portal.notificationPreferences),
        ],
      ],
    );
  }
}

PortalSection? _notificationDestination(
  Map<String, Object?> notification,
  PortalController portal,
) {
  final payload = <String, dynamic>{
    for (final entry in notification.entries) entry.key: entry.value,
  };
  final nested = notification['data'] ?? notification['payload'];
  if (nested is Map) {
    for (final entry in nested.entries) {
      payload['${entry.key}'] = entry.value;
    }
  }
  final eventType = valueText(notification, const [
    'event_type',
    'type',
  ], fallback: '');
  if (eventType.isNotEmpty) payload.putIfAbsent('resource', () => eventType);
  final route = notificationRouteFromPayload(payload);
  return switch (route) {
    'messages' when portal.can('messaging:read') => PortalSection.messages,
    'assignments' when portal.can('assignments:read') =>
      PortalSection.assignments,
    'schedule' ||
    'calendar' when portal.can('schedule:read') => PortalSection.schedule,
    'attendance' when portal.can('attendance:read') => PortalSection.attendance,
    'academics' ||
    'grades' ||
    'exams' when portal.can('academics:read') => PortalSection.academics,
    'content' ||
    'courses' ||
    'materials' when portal.can('content:read') => PortalSection.content,
    'ai' || 'assistant' when portal.can('ai:read') => PortalSection.ai,
    'forms' when portal.can('forms:read') => PortalSection.forms,
    'achievements' when portal.can('achievements:read') =>
      PortalSection.achievements,
    'discipline' ||
    'rules' ||
    'penalties' when portal.can('penalty:read') => PortalSection.discipline,
    'finance' ||
    'payments' when portal.can('finance:read_own') => PortalSection.finance,
    'cards' || 'wallet' when portal.can('card:read') => PortalSection.cards,
    'account' => PortalSection.account,
    'students' || 'parents' || 'identity' => PortalSection.identity,
    _ => null,
  };
}

class _NotificationPreferences extends StatefulWidget {
  const _NotificationPreferences({required this.rows});

  final List<Map<String, Object?>> rows;

  @override
  State<_NotificationPreferences> createState() =>
      _NotificationPreferencesState();
}

class _NotificationPreferencesState extends State<_NotificationPreferences> {
  late List<Map<String, Object?>> _rows;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _rows = [
      for (final row in widget.rows) {...row},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < _rows.length; index++)
            SwitchListTile(
              value: _rows[index]['enabled'] == true,
              title: Text(_statusLabel('${_rows[index]['event_type']}')),
              subtitle: Text(switch ('${_rows[index]['channel']}'
                  .toLowerCase()) {
                'push' || 'in_app' => 'Ilova ichida',
                'email' => 'Elektron pochta',
                'sms' => 'SMS',
                _ => 'Bildirishnoma kanali',
              }),
              onChanged: _busy
                  ? null
                  : (value) async {
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() {
                        _rows[index]['enabled'] = value;
                        _busy = true;
                      });
                      try {
                        await PortalScope.read(
                          context,
                        ).saveNotificationPreferences(_rows);
                      } on Object catch (error) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(_errorText(error))),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
            ),
        ],
      ),
    );
  }
}

class _FormsPortalPage extends StatelessWidget {
  const _FormsPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    return _PortalPage(
      title: 'So‘rovnomalar',
      subtitle: 'Sizga yuborilgan ochiq shakllar va so‘rovlar.',
      section: PortalSection.forms,
      children: [
        if (portal.forms.isEmpty)
          const _EmptyState(
            icon: Icons.dynamic_form_outlined,
            title: 'Ochiq so‘rovnoma yo‘q',
            message: 'Markaz yangi so‘rov yuborganda shu yerda ko‘rinadi.',
          )
        else
          _SimpleRows(
            rows: portal.forms,
            icon: Icons.assignment_outlined,
            title: (row) => valueText(row, const ['title']),
            subtitle: (row) =>
                '${valueText(row, const ['description'], fallback: 'Tavsifsiz')} · ${valueRows(row['form_fields']).length} savol',
            trailing: (row) => const Icon(Icons.chevron_right_rounded),
            onTap: (row) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PortalScope(
                  controller: portal,
                  child: _FormFillScreen(form: row),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FormFillScreen extends StatefulWidget {
  const _FormFillScreen({required this.form});

  final Map<String, Object?> form;

  @override
  State<_FormFillScreen> createState() => _FormFillScreenState();
}

class _FormFillScreenState extends State<_FormFillScreen> {
  final Map<int, Object?> _answers = {};
  final Map<int, TextEditingController> _controllers = {};
  bool _busy = false;
  String? _error;

  List<Map<String, Object?>> get fields =>
      valueRows(widget.form['form_fields']);

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(int id) =>
      _controllers.putIfAbsent(id, TextEditingController.new);

  TextEditingController? _controllerFor(Map<String, Object?> field) {
    final id = valueInt(field['id']);
    final type = '${field['field_type']}';
    if (id == null ||
        !const {'text', 'textarea', 'number', 'date'}.contains(type)) {
      return null;
    }
    return _controller(id);
  }

  Object? _answerFor(Map<String, Object?> field) {
    final id = valueInt(field['id']);
    return id == null ? null : _answers[id];
  }

  Future<void> _submit() async {
    for (final field in fields) {
      final id = valueInt(field['id']);
      if (id == null || field['required'] != true) continue;
      final value = _answers[id] ?? _controllers[id]?.text;
      if (value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is List && value.isEmpty)) {
        setState(
          () => _error =
              '“${valueText(field, const ['label'])}” savoliga javob bering.',
        );
        return;
      }
    }
    final formId = valueInt(widget.form['id']);
    if (formId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final payload = <Map<String, Object?>>[];
      for (final field in fields) {
        final id = valueInt(field['id']);
        if (id == null) continue;
        Object? value = _answers[id];
        if (_controllers[id] case final controller?) {
          value = switch ('${field['field_type']}') {
            'number' => num.tryParse(controller.text),
            _ => controller.text.trim(),
          };
        }
        if (value != null && value != '') {
          payload.add({'field': id, 'value': value});
        }
      }
      await PortalScope.read(context).submitForm(formId, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Javob serverga yuborildi.')),
      );
      Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(valueText(widget.form, const ['title']))),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                valueText(widget.form, const ['description'], fallback: ''),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (widget.form['is_anonymous'] == true) ...[
                const SizedBox(height: 12),
                const _InlineMessage(
                  text:
                      'Bu anonim so‘rovnoma. Ismingiz javobga biriktirilmaydi.',
                  error: false,
                ),
              ],
              const SizedBox(height: 20),
              for (final field in fields) ...[
                _FormFieldEditor(
                  field: field,
                  controller: _controllerFor(field),
                  value: _answerFor(field),
                  onChanged: (value) {
                    final id = valueInt(field['id']);
                    if (id != null) setState(() => _answers[id] = value);
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (_error case final error?)
                _InlineMessage(text: error, error: true),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(_busy ? 'Yuborilmoqda…' : 'Javobni yuborish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormFieldEditor extends StatelessWidget {
  const _FormFieldEditor({
    required this.field,
    required this.controller,
    required this.value,
    required this.onChanged,
  });

  final Map<String, Object?> field;
  final TextEditingController? controller;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final type = '${field['field_type']}';
    final label =
        '${valueText(field, const ['label'])}${field['required'] == true ? ' *' : ''}';
    final options = field['options'] is List
        ? List<Object?>.from(field['options']! as List)
        : const <Object?>[];
    if (type == 'boolean') {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: Text(valueText(field, const ['help_text'], fallback: '')),
        value: value == true,
        onChanged: onChanged,
      );
    }
    if (type == 'single_choice') {
      return DropdownButtonFormField<String>(
        initialValue: value?.toString(),
        decoration: InputDecoration(
          labelText: label,
          helperText: valueText(field, const ['help_text'], fallback: ''),
        ),
        items: [
          for (final option in options)
            DropdownMenuItem(value: '$option', child: Text('$option')),
        ],
        onChanged: onChanged,
      );
    }
    if (type == 'multi_choice') {
      final selected = value is List
          ? (value as List).map((item) => '$item').toSet()
          : <String>{};
      return _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            for (final option in options)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: selected.contains('$option'),
                title: Text('$option'),
                onChanged: (checked) {
                  final next = <String>{...selected};
                  if (checked == true) {
                    next.add('$option');
                  } else {
                    next.remove('$option');
                  }
                  onChanged(next.toList());
                },
              ),
          ],
        ),
      );
    }
    if (type == 'rating') {
      return _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: [
                for (var index = 1; index <= 5; index++)
                  ButtonSegment(value: index, label: Text('$index')),
              ],
              selected: value is int ? {value! as int} : const <int>{},
              emptySelectionAllowed: true,
              onSelectionChanged: (selection) =>
                  onChanged(selection.firstOrNull),
            ),
          ],
        ),
      );
    }
    if (type == 'date') {
      return TextField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          final now = DateTime.now();
          final current = DateTime.tryParse(controller?.text ?? '');
          final selected = await showDatePicker(
            context: context,
            initialDate: current ?? now,
            firstDate: DateTime(now.year - 100),
            lastDate: DateTime(now.year + 10),
          );
          if (selected == null) return;
          final formatted =
              '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
          controller?.text = formatted;
          onChanged(formatted);
        },
        decoration: InputDecoration(
          labelText: label,
          helperText: valueText(field, const ['help_text'], fallback: ''),
          hintText: 'YYYY-MM-DD',
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
      );
    }
    return TextField(
      controller: controller,
      minLines: type == 'textarea' ? 4 : 1,
      maxLines: type == 'textarea' ? 8 : 1,
      keyboardType: type == 'number'
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        helperText: valueText(field, const ['help_text'], fallback: ''),
        alignLabelWithHint: type == 'textarea',
      ),
    );
  }
}

class _AchievementsPortalPage extends StatelessWidget {
  const _AchievementsPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final studentId = portal.selectedStudentId;
    final rows = portal.isParent && studentId != null
        ? portal.achievementGrants
              .where((item) => valueInt(item['student']) == studentId)
              .toList()
        : portal.achievementGrants;
    return _PortalPage(
      title: portal.isParent ? 'Farzand yutuqlari' : 'Mening yutuqlarim',
      subtitle: 'Markaz tasdiqlagan va o‘quvchiga berilgan yutuqlar devori.',
      section: PortalSection.achievements,
      children: [
        if (rows.isEmpty)
          const _EmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'Yutuq hali yo‘q',
            message: 'Yangi mukofot berilganda shu yerda ko‘rinadi.',
          )
        else
          _ResponsiveGrid(
            minWidth: 270,
            children: [
              for (final grant in rows)
                Builder(
                  builder: (context) {
                    final detail = valueMap(grant['achievement_detail']);
                    return _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                valueText(detail, const [
                                  'emoji',
                                ], fallback: '🏆'),
                                style: const TextStyle(fontSize: 36),
                              ),
                              const Spacer(),
                              _StatusPill(
                                valueText(detail, const ['status']),
                                positive: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            valueText(detail, const ['name']),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            valueText(detail, const [
                              'description',
                            ], fallback: 'Tavsif berilmagan.'),
                          ),
                          if (valueText(grant, const [
                            'note',
                          ], fallback: '').isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Izoh: ${grant['note']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            'Berilgan: ${_dateLabel(grant['granted_at'])}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class _DisciplinePortalPage extends StatelessWidget {
  const _DisciplinePortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final studentId = portal.selectedStudentId;
    final penalties = portal.isParent && studentId != null
        ? portal.penalties
              .where((item) => valueInt(item['student']) == studentId)
              .toList()
        : portal.penalties;
    return _PortalPage(
      title: 'Qoidalar va intizom',
      subtitle:
          'Sizga tegishli ichki qoidalar, tasdiqlashlar va intizom yozuvlari.',
      section: PortalSection.discipline,
      children: [
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'Qoidalar',
              value: '${portal.rules.length}',
              icon: Icons.menu_book_outlined,
            ),
            _MetricCard(
              label: 'Tasdiqlanmagan',
              value: '${portal.pendingRules.length}',
              icon: Icons.pending_actions_outlined,
            ),
            _MetricCard(
              label: 'Intizom yozuvlari',
              value: '${penalties.length}',
              icon: Icons.gavel_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _PageSectionTitle(
          title: 'Menga tegishli qoidalar',
          count: portal.rules.length,
        ),
        const SizedBox(height: 10),
        if (portal.rules.isEmpty)
          const _EmptyState(
            icon: Icons.rule_outlined,
            title: 'Qoida yo‘q',
            message: 'Faol qoidalar shu yerda ko‘rinadi.',
          )
        else
          ...portal.rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SectionCard(
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(valueText(rule, const ['title'])),
                  subtitle: Text('Versiya ${rule['version']}'),
                  trailing: rule['acknowledged'] == true
                      ? const _StatusPill('Tasdiqlangan', positive: true)
                      : const _StatusPill('Tasdiqlash kerak', warning: true),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(valueText(rule, const ['body'])),
                    ),
                    if (rule['acknowledged'] != true) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _withId(
                            rule['id'],
                            (id) => _runAction(
                              context,
                              () => portal.acknowledgeRule(id),
                              success:
                                  'Qoida bilan tanishganingiz tasdiqlandi.',
                            ),
                          ),
                          icon: const Icon(Icons.verified_outlined),
                          label: const Text('Tanishdim'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        _PageSectionTitle(title: 'Intizom yozuvlari', count: penalties.length),
        const SizedBox(height: 10),
        if (penalties.isEmpty)
          const _EmptyState(
            icon: Icons.verified_user_outlined,
            title: 'Intizom yozuvi yo‘q',
            message: 'Faol yoki bekor qilingan yozuvlar mavjud emas.',
          )
        else
          _SimpleRows(
            rows: penalties,
            icon: Icons.gavel_outlined,
            title: (row) => valueText(row, const ['reason']),
            subtitle: (row) =>
                '${row['points']} ball · ${_dateLabel(row['issued_at'], time: true)}',
            trailing: (row) => _StatusPill(
              valueText(row, const ['status']),
              positive: row['status'] == 'waived',
            ),
            onTap: (row) => _showJsonDetail(
              context,
              title: 'Intizom yozuvi #${row['id']}',
              fields: {
                'Sabab': valueText(row, const ['reason']),
                'Ball': '${row['points']}',
                'Holat': _statusLabel('${row['status']}'),
                'Berilgan': _dateLabel(row['issued_at'], time: true),
                if (row['waived_at'] != null)
                  'Bekor qilingan': _dateLabel(row['waived_at'], time: true),
                if (row['waive_reason'] != null)
                  'Bekor qilish sababi': '${row['waive_reason']}',
              },
            ),
          ),
      ],
    );
  }
}

class _FinancePortalPage extends StatelessWidget {
  const _FinancePortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final invoices = valueRows(portal.outstanding['invoices']);
    final overdue = invoices
        .where((item) => item['status'] == 'overdue')
        .length;
    return _PortalPage(
      title: 'To‘lov holati',
      subtitle:
          'Farzandingiz bo‘yicha hisob-fakturalar va qolgan qarzdorlik. Bu kabinet pul yechmaydi.',
      section: PortalSection.finance,
      children: [
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'Jami qarzdorlik',
              value: _money(portal.outstanding['outstanding_uzs']),
              icon: Icons.account_balance_wallet_outlined,
            ),
            _MetricCard(
              label: 'Hisob-fakturalar',
              value: '${invoices.length}',
              icon: Icons.receipt_long_outlined,
            ),
            _MetricCard(
              label: 'Muddati o‘tgan',
              value: '$overdue',
              icon: Icons.warning_amber_rounded,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _InlineMessage(
          text:
              'Bu kabinet balansni kuzatish uchun mo‘ljallangan. To‘lovni amalga oshirish yoki kvitansiyani aniqlashtirish uchun markaz bilan bog‘laning.',
          error: false,
        ),
        const SizedBox(height: 24),
        if (invoices.isEmpty)
          const _EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Hisob-faktura yo‘q',
            message: 'Yangi hisob chiqarilganda shu yerda ko‘rinadi.',
          )
        else
          _SimpleRows(
            rows: invoices,
            icon: Icons.receipt_long_outlined,
            title: (row) => valueText(row, const [
              'fee_schedule_name',
              'number',
            ], fallback: 'Hisob-faktura'),
            subtitle: (row) =>
                '${valueText(row, const ['number'])} · muddat ${_dateLabel(row['due_date'])} · ${_money(row['total_uzs'])}',
            trailing: (row) => _StatusPill(
              valueText(row, const ['status']),
              positive: row['status'] == 'paid',
              warning: row['status'] == 'overdue',
            ),
            onTap: (row) => _showJsonDetail(
              context,
              title: valueText(row, const [
                'number',
              ], fallback: 'Hisob-faktura'),
              fields: {
                'Xizmat': valueText(row, const [
                  'fee_schedule_name',
                ], fallback: 'Ta’lim xizmati'),
                'Davr': valueText(row, const ['period']),
                'Summa': _money(row['total_uzs']),
                'Holat': _statusLabel('${row['status']}'),
                'Chiqarilgan': _dateLabel(row['issue_date']),
                'Muddat': _dateLabel(row['due_date']),
                'Qatorlar': _readable(row['lines']),
              },
            ),
          ),
      ],
    );
  }
}

class _CardsPortalPage extends StatelessWidget {
  const _CardsPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final walletData = valueMap(portal.wallet['wallet']);
    final transactions = valueRows(portal.wallet['transactions']);
    String typeName(Object? id) {
      final type = portal.cardTypes
          .where((item) => valueInt(item['id']) == valueInt(id))
          .firstOrNull;
      return valueText(type ?? const {}, const [
        'name',
      ], fallback: 'O‘quvchi kartasi');
    }

    return _PortalPage(
      title: 'Karta va hamyon',
      subtitle:
          'O‘zingizga tegishli karta va markaz ichidagi saqlangan mablag‘.',
      section: PortalSection.cards,
      children: [
        _ResponsiveGrid(
          children: [
            _MetricCard(
              label: 'Hamyon balansi',
              value: _money(walletData['balance_uzs']),
              icon: Icons.account_balance_wallet_outlined,
            ),
            _MetricCard(
              label: 'Faol kartalar',
              value:
                  '${portal.cards.where((item) => item['is_active'] == true).length}',
              icon: Icons.credit_card_outlined,
            ),
            _MetricCard(
              label: 'Operatsiyalar',
              value: '${transactions.length}',
              icon: Icons.receipt_long_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _PageSectionTitle(
          title: 'Mening kartalarim',
          count: portal.cards.length,
        ),
        const SizedBox(height: 10),
        if (portal.cards.isEmpty)
          const _EmptyState(
            icon: Icons.credit_card_off_outlined,
            title: 'Karta berilmagan',
            message: 'Markaz karta chiqarganda shu yerda ko‘rinadi.',
          )
        else
          _ResponsiveGrid(
            minWidth: 280,
            children: [
              for (final card in portal.cards)
                Container(
                  height: 174,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.tertiary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                            ),
                            const Spacer(),
                            Text(
                              card['is_active'] == true ? 'FAOL' : 'YOPILGAN',
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          typeName(card['card_type']),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          valueText(card, const ['code']),
                          style: const TextStyle(
                            fontFamily: Sf.mono,
                            fontSize: 20,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Berilgan: ${_dateLabel(card['issued_at'])}'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 24),
        _PageSectionTitle(title: 'Hamyon tarixi', count: transactions.length),
        const SizedBox(height: 10),
        if (transactions.isEmpty)
          const _EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Operatsiya yo‘q',
            message: 'Hamyon harakatlari shu yerda ko‘rinadi.',
          )
        else
          _SimpleRows(
            rows: transactions,
            icon: Icons.payments_outlined,
            title: (row) =>
                '${row['kind'] == 'credit' || row['kind'] == 'topup' ? '+' : '−'} ${_money(row['amount_uzs'])}',
            subtitle: (row) =>
                '${valueText(row, const ['note'], fallback: 'Hamyon operatsiyasi')} · ${_dateLabel(row['created_at'], time: true)}',
            trailing: (row) => Text(
              _money(row['balance_after_uzs']),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
      ],
    );
  }
}

class _AccountPortalPage extends StatelessWidget {
  const _AccountPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final app = AppScope.of(context);
    return _PortalPage(
      title: 'Profil va xavfsizlik',
      subtitle: 'Shaxsiy ma’lumotlar, qurilmalar, parol va ilova ko‘rinishi.',
      section: PortalSection.account,
      children: [
        _SectionCard(child: _AccountIdentityHeader(portal: portal)),
        const SizedBox(height: 24),
        const _PageSectionTitle(title: 'Ilova ko‘rinishi'),
        const SizedBox(height: 10),
        _SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Qorong‘i rejim'),
                value: app.darkMode,
                onChanged: app.setDarkMode,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.text_increase_rounded),
                title: const Text('Katta matn'),
                value: app.largeText,
                onChanged: app.setLargeText,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.contrast_rounded),
                title: const Text('Yuqori kontrast'),
                value: app.highContrast,
                onChanged: app.setHighContrast,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.motion_photos_off_outlined),
                title: const Text('Animatsiyani kamaytirish'),
                value: app.reduceMotion,
                onChanged: app.setReduceMotion,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: _PageSectionTitle(title: 'Faol qurilmalar')),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PortalScope(
                    controller: portal,
                    child: const _PasswordChangeScreen(),
                  ),
                ),
              ),
              icon: const Icon(Icons.password_rounded),
              label: const Text('Parolni almashtirish'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (portal.devices.isEmpty)
          const _EmptyState(
            icon: Icons.devices_other_outlined,
            title: 'Qurilma ro‘yxati bo‘sh',
            message: 'Ro‘yxatdan o‘tgan qurilmalar shu yerda ko‘rinadi.',
          )
        else
          _SimpleRows(
            rows: portal.devices,
            icon: Icons.devices_outlined,
            title: (row) => valueText(row, const [
              'name',
              'platform',
            ], fallback: 'Faol qurilma'),
            subtitle: (row) =>
                '${valueText(row, const ['platform'])} · oxirgi faollik ${_dateLabel(row['last_seen_at'], time: true)}',
            trailing: (row) => IconButton(
              tooltip: 'Qurilmani chiqarish',
              onPressed: _withId(
                row['id'],
                (id) => _confirmDeviceRevoke(context, portal, id),
              ),
              icon: const Icon(Icons.logout_rounded),
            ),
          ),
        const SizedBox(height: 24),
        _SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ExpansionTile(
                leading: const Icon(Icons.support_agent_rounded),
                title: const Text('Yordam uchun texnik ma’lumot'),
                subtitle: const Text(
                  'Faqat markaz mutaxassisi so‘raganda oching',
                ),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectableText(
                    portal.baseUrl,
                    style: const TextStyle(fontFamily: Sf.mono, fontSize: 12),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: portal.logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Akkauntdan chiqish'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeviceRevoke(
    BuildContext context,
    PortalController portal,
    int id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Qurilmani chiqarish'),
        content: const Text('Bu qurilmadagi faol sessiya bekor qilinadi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Chiqarish'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _runAction(
        context,
        () => portal.revokeDevice(id),
        success: 'Qurilma chiqarildi.',
      );
    }
  }
}

class _AccountIdentityHeader extends StatelessWidget {
  const _AccountIdentityHeader({required this.portal});

  final PortalController portal;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 30,
      child: Text(_initials(portal.displayName)),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(portal.displayName, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '${portal.isParent ? 'Ota-ona' : 'O‘quvchi'} · ${valueText(portal.profile, const ['username'])}',
        ),
        Text(
          valueText(portal.profile, const [
            'phone',
            'email',
          ], fallback: 'Aloqa ma’lumoti yo‘q'),
        ),
      ],
    );
    final edit = FilledButton.tonalIcon(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PortalScope(
            controller: portal,
            child: const _ProfileEditScreen(),
          ),
        ),
      ),
      icon: const Icon(Icons.edit_outlined),
      label: const Text('Tahrirlash'),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 460) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatar,
                  const SizedBox(width: 12),
                  Expanded(child: details),
                ],
              ),
              const SizedBox(height: 12),
              edit,
            ],
          );
        }
        return Row(
          children: [
            avatar,
            const SizedBox(width: 16),
            Expanded(child: details),
            const SizedBox(width: 12),
            edit,
          ],
        );
      },
    );
  }
}

class _ProfileEditScreen extends StatefulWidget {
  const _ProfileEditScreen();

  @override
  State<_ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<_ProfileEditScreen> {
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _middle;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = PortalScope.read(context).profile;
    _first = TextEditingController(
      text: valueText(profile, const ['first_name'], fallback: ''),
    );
    _last = TextEditingController(
      text: valueText(profile, const ['last_name'], fallback: ''),
    );
    _middle = TextEditingController(
      text: valueText(profile, const ['middle_name'], fallback: ''),
    );
    _phone = TextEditingController(
      text: valueText(profile, const ['phone'], fallback: ''),
    );
    _email = TextEditingController(
      text: valueText(profile, const ['email'], fallback: ''),
    );
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _middle.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await PortalScope.read(context).updateProfile({
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        'middle_name': _middle.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil saqlandi.')));
      Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilni tahrirlash')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _first,
                decoration: const InputDecoration(labelText: 'Ism'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _last,
                decoration: const InputDecoration(labelText: 'Familiya'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _middle,
                decoration: const InputDecoration(labelText: 'Otasining ismi'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefon'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: 14),
                _InlineMessage(text: error, error: true),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Saqlanmoqda…' : 'Saqlash'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordChangeScreen extends StatefulWidget {
  const _PasswordChangeScreen();

  @override
  State<_PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<_PasswordChangeScreen> {
  final _old = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _old.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_next.text.length < 8 || _next.text != _confirm.text) {
      setState(() => _error = 'Yangi parollar mos emas yoki 8 belgidan qisqa.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await PortalScope.read(
        context,
      ).changePassword(oldPassword: _old.text, newPassword: _next.text);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Parol yangilandi.')));
      Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parolni almashtirish')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _old,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Hozirgi parol'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _next,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Yangi parol'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yangi parolni takrorlang',
                ),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: 14),
                _InlineMessage(text: error, error: true),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Yangilanmoqda…' : 'Parolni yangilash'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

VoidCallback? _withId(Object? raw, void Function(int) action) {
  final id = valueInt(raw);
  return id == null ? null : () => action(id);
}
