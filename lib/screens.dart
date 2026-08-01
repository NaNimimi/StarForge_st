import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_state.dart';
import 'theme.dart';
import 'widgets.dart';

typedef NavCb = void Function(String id);

enum AppRole { parent, student }

const _student = 'Akbarov Akmal';
const _parent = 'Akbarova Dilnoza';

// ─────────────────────────── HOME (Bugun) — student ───────────────────────────
class HomeScreen extends StatelessWidget {
  final NavCb onNav;
  const HomeScreen({super.key, required this.onNav});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: 'Shanba · 25 Iyul',
          title: greetingTitle('Akmal'),
          sub: 'Bugun 3 ta darsing bor',
          right: SoftButton(
            'Ustozga',
            icon: Icons.chat_bubble_rounded,
            primary: true,
            bg: Sf.accent,
            onTap: () => onNav('messages'),
          ),
        ),
        const SfGrid(
          minTile: 150,
          children: [
            KpiCard(
              label: 'Davomat',
              value: '96%',
              valueColor: Sf.success,
              icon: Icons.check_rounded,
            ),
            KpiCard(
              label: 'Mening kartalarim',
              value: '↑12',
              valueColor: Sf.goldUp,
              icon: Icons.star_rounded,
            ),
            KpiCard(label: 'Down', value: '↓1', valueColor: Sf.danger),
            KpiCard(label: 'O‘rin · sinf', value: '#2', valueColor: Sf.accent),
          ],
        ),
        const SizedBox(height: 18),
        SfTwoCol(
          left: SfCol([
            _Hero(
              onNav: onNav,
              eyebrow: 'KEYINGI DARS · 14 DAQIQADA',
              colors: const [Sf.accent, Color(0xFF9C6E14)],
              btn2Label: 'Materiallar',
              btn2Target: 'materials',
            ),
            _RecentCards(onNav: onNav, title: 'So‘nggi kartalarim'),
          ]),
          right: SfCol([
            _AiPreviewCard(onNav: onNav),
            const _TodayScheduleCard(),
          ]),
        ),
      ],
    );
  }
}

/// Horizontal strip of the three most recent star cards.
class _RecentCards extends StatelessWidget {
  final NavCb onNav;
  final String title;
  const _RecentCards({required this.onNav, required this.title});
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      action: _MoreLink(onTap: () => onNav('cards')),
      child: SizedBox(
        height: 320 * 0.62 + 6,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 2),
          children: const [
            StarCard(
              up: true,
              scale: 0.62,
              recipient: 'Akbarov A.',
              reason: 'Mustaqil yechim',
              issuer: 'N.K.',
              when: '09:42',
              typeName: 'Yulduz',
            ),
            SizedBox(width: 10),
            StarCard(
              up: true,
              scale: 0.62,
              recipient: 'Akbarov A.',
              reason: 'Aktivlik',
              issuer: 'N.K.',
              when: 'Du',
              typeName: 'Aktivlik',
            ),
            SizedBox(width: 10),
            StarCard(
              up: false,
              scale: 0.62,
              recipient: 'Akbarov A.',
              reason: 'Uy ishi',
              issuer: 'N.K.',
              when: '15 Iyul',
              typeName: 'Ogohl.',
            ),
          ],
        ),
      ),
    );
  }
}

/// AI repetitor preview (student home right column).
class _AiPreviewCard extends StatelessWidget {
  final NavCb onNav;
  const _AiPreviewCard({required this.onNav});
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'AI repetitor',
      child: InkWell(
        onTap: () => onNav('ai'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: AiBadge(),
            ),
            Text(
              '“Kvadrat tenglamalarni mashq qilaylik. 3 ta misol tayyorladim — boshlaymizmi?”',
              style: Sf.serif(size: 15, color: Sf.ink, height: 1.35),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: Sf.ink,
                borderRadius: BorderRadius.circular(9),
                child: InkWell(
                  onTap: () => onNav('ai'),
                  borderRadius: BorderRadius.circular(9),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    child: Text(
                      'Boshlash',
                      style: Sf.t(
                        size: 12,
                        weight: FontWeight.w700,
                        color: Sf.bg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

/// Today's three lessons (shared by both roles' home right column).
class _TodayScheduleCard extends StatelessWidget {
  const _TodayScheduleCard();
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Bugungi jadval',
      child: Column(
        children: [
          for (final r in const [
            ['09:00', 'Algebra', 'now'],
            ['10:00', 'Geometriya', ''],
            ['11:30', 'Ingliz tili', ''],
          ])
            _ScheduleRow(
              time: r[0],
              subject: r[1],
              now: r[2] == 'now',
              last: r[0] == '11:30',
            ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final NavCb onNav;
  final String eyebrow;
  final List<Color> colors;
  final String btn1Label, btn1Target, btn2Label, btn2Target;
  const _Hero({
    required this.onNav,
    this.eyebrow = 'KEYINGI DARS · 14 DAQIQADA',
    this.colors = const [Sf.accent, Color(0xFF9C6E14)],
    this.btn1Label = 'To‘liq jadval',
    this.btn1Target = 'schedule',
    this.btn2Label = 'Materiallar',
    this.btn2Target = 'materials',
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -34,
            child: Opacity(
              opacity: 0.16,
              child: SfStar(size: 150, color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: Sf.t(
                  size: 11,
                  weight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Algebra · 9-B',
                style: Sf.t(
                  size: 26,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '09:00–09:45 · Xona 304 · Nigora Karimova',
                style: Sf.t(
                  size: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroBtn(btn1Label, onTap: () => onNav(btn1Target)),
                  _HeroBtn(
                    btn2Label,
                    ghost: true,
                    onTap: () => onNav(btn2Target),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBtn extends StatelessWidget {
  final String label;
  final bool ghost;
  final VoidCallback onTap;
  const _HeroBtn(this.label, {this.ghost = false, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: ghost ? Colors.transparent : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: ghost ? Border.all(color: Colors.white54) : null,
          ),
          child: Text(
            label,
            style: Sf.t(
              size: 13,
              weight: FontWeight.w700,
              color: ghost ? Colors.white : Sf.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String time, subject;
  final bool now, last;
  const _ScheduleRow({
    required this.time,
    required this.subject,
    required this.now,
    required this.last,
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
          SizedBox(
            width: 48,
            child: Text(
              time,
              style: Sf.monoStyle(
                size: 12.5,
                weight: FontWeight.w600,
                color: Sf.ink2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subject,
              style: Sf.t(size: 13, weight: FontWeight.w600),
            ),
          ),
          if (now) const Pill('Hozir', tone: Tone.primary),
        ],
      ),
    );
  }
}

class _MoreLink extends StatelessWidget {
  final VoidCallback onTap;
  const _MoreLink({required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Hammasini ko‘rish',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            'Hammasi ›',
            style: Sf.t(size: 12, weight: FontWeight.w600, color: Sf.primary),
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────── GROUPS (Guruhlarim) ───────────────────────────
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const groups = [
      ['9-B Algebra', 'Nigora Karimova', 94, Sf.primary],
      ['10-V Geometriya', 'Bobur Aliyev', 88, Sf.accent],
      ['Ingliz B2', 'Aziz Tursunov', 92, Sf.success],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          eyebrow: '9-B · 14 yosh',
          title: Text('Guruhlarim'),
          sub: '3 ta guruh',
        ),
        SfGrid(
          minTile: 280,
          children: [
            for (final g in groups)
              _GroupTile(
                name: g[0] as String,
                teacher: g[1] as String,
                att: g[2] as int,
                color: g[3] as Color,
              ),
          ],
        ),
      ],
    );
  }
}

class _GroupTile extends StatelessWidget {
  final String name, teacher;
  final int att;
  final Color color;
  const _GroupTile({
    required this.name,
    required this.teacher,
    required this.att,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Sf.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _showDetails(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Sf.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SfStar(size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Sf.t(size: 14.5, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Avatar(teacher, size: 15),
                        const SizedBox(width: 5),
                        Text(teacher, style: Sf.t(size: 11.5, color: Sf.muted)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$att%',
                    style: Sf.monoStyle(
                      size: 15,
                      weight: FontWeight.w700,
                      color: att >= 92 ? Sf.success : Sf.warn,
                    ),
                  ),
                  Text(
                    'DAVOMAT',
                    style: Sf.t(size: 9, color: Sf.muted, letterSpacing: 0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Sf.surface,
      builder: (sheetContext) => Padding(
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
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const SfStar(size: 22, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Sf.t(size: 19, weight: FontWeight.w800),
                      ),
                      Text(
                        '$att% davomat · haftasiga 2 dars',
                        style: Sf.t(size: 12, color: Sf.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Avatar(teacher, size: 42),
              title: Text(
                teacher,
                style: Sf.t(size: 13.5, weight: FontWeight.w700),
              ),
              subtitle: const Text('Fan o‘qituvchisi'),
              trailing: const Icon(Icons.chat_bubble_outline_rounded),
              onTap: () => sfToast(
                context,
                'Xabarlar bo‘limidan ustozga yozing',
                tone: Sf.primary,
              ),
            ),
            const Divider(color: Sf.border),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.assignment_rounded, color: Sf.primary),
              title: Text('2 ta faol vazifa'),
              subtitle: Text('Eng yaqin muddat: bugun 20:00'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.folder_rounded, color: Sf.accent),
              title: Text('4 ta yangi material'),
              subtitle: Text('Oxirgi yangilanish: bugun'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                sfToast(context, 'Guruh kuzatuvga qo‘shildi', tone: Sf.success);
              },
              icon: const Icon(Icons.notifications_active_rounded),
              label: const Text('Guruh yangiliklarini kuzatish'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── ATTENDANCE (Davomatim) ───────────────────────────
class AttendanceScreen extends StatefulWidget {
  final AppRole role;
  const AttendanceScreen({super.key, this.role = AppRole.student});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _status = 'Barchasi';
  String _subject = 'Barchasi';
  final Set<String> _explained = <String>{};

  static const _entries = [
    _AttendanceEntry('25 Iyul', 'Algebra', 'present', '09:00', 'a1'),
    _AttendanceEntry('24 Iyul', 'Geometriya', 'present', '10:00', 'a2'),
    _AttendanceEntry('23 Iyul', 'Ingliz tili', 'late', '11:37', 'a3'),
    _AttendanceEntry('22 Iyul', 'Algebra', 'present', '09:00', 'a4'),
    _AttendanceEntry('21 Iyul', 'Geometriya', 'present', '10:00', 'a5'),
    _AttendanceEntry('18 Iyul', 'Algebra', 'absent', '—', 'a6'),
    _AttendanceEntry('17 Iyul', 'Ingliz tili', 'present', '11:30', 'a7'),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _entries.where((entry) {
      final statusMatch = _status == 'Barchasi' || entry.status == _status;
      final subjectMatch = _subject == 'Barchasi' || entry.subject == _subject;
      return statusMatch && subjectMatch;
    }).toList();
    Tone tn(String s) =>
        s == 'present' ? Tone.success : (s == 'late' ? Tone.warn : Tone.danger);
    String lbl(String s) =>
        s == 'present' ? 'Bor' : (s == 'late' ? 'Kechikdi' : 'Yo‘q');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: widget.role == AppRole.parent
              ? 'Akmal · 9-B'
              : 'Mening davomatim',
          title: const Text('Davomat'),
          sub: 'Oxirgi 30 kun · 96% ishtirok',
          right: widget.role == AppRole.parent
              ? SoftButton(
                  'Yo‘qlik sababini yozish',
                  icon: Icons.note_add_rounded,
                  primary: true,
                  onTap: () => _explainAbsence(context),
                )
              : null,
        ),
        const SfGrid(
          minTile: 150,
          children: [
            KpiCard(label: 'Ishtirok', value: '96%', valueColor: Sf.success),
            KpiCard(label: 'Kechikish', value: '2', valueColor: Sf.warn),
            KpiCard(label: 'Sababsiz', value: '1', valueColor: Sf.danger),
            KpiCard(label: 'Jami dars', value: '48'),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Filtr va trend',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 7,
                runSpacing: 7,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final status in const [
                    ('Barchasi', 'Barchasi'),
                    ('present', 'Bor'),
                    ('late', 'Kechikdi'),
                    ('absent', 'Yo‘q'),
                  ])
                    ChoiceChip(
                      label: Text(status.$2),
                      selected: _status == status.$1,
                      onSelected: (_) => setState(() => _status = status.$1),
                    ),
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<String>(
                      initialValue: _subject,
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
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: const LinearProgressIndicator(
                        value: 0.96,
                        minHeight: 9,
                        backgroundColor: Sf.surface2,
                        color: Sf.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Me’yor ≥ 90%',
                    style: Sf.t(
                      size: 11,
                      weight: FontWeight.w700,
                      color: Sf.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Kunlik tarix · ${visible.length}',
          child: visible.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.event_busy_rounded,
                        size: 42,
                        color: Sf.muted2,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bu filtrda yozuv yo‘q',
                        style: Sf.t(size: 13.5, weight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _status = 'Barchasi';
                          _subject = 'Barchasi';
                        }),
                        child: const Text('Filtrlarni tozalash'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < visible.length; i++)
                      InkWell(
                        onTap: () => _showAttendanceDetail(context, visible[i]),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            border: i < visible.length - 1
                                ? const Border(
                                    bottom: BorderSide(color: Sf.border),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 70,
                                child: Text(
                                  visible[i].date,
                                  style: Sf.monoStyle(
                                    size: 12.5,
                                    weight: FontWeight.w400,
                                    color: Sf.muted,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${visible[i].subject} · 9-B',
                                      style: Sf.t(
                                        size: 13,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      visible[i].status == 'late'
                                          ? 'Keldi: ${visible[i].time}'
                                          : 'Dars: ${visible[i].time}',
                                      style: Sf.t(size: 10.5, color: Sf.muted),
                                    ),
                                  ],
                                ),
                              ),
                              if (_explained.contains(visible[i].id))
                                const Padding(
                                  padding: EdgeInsets.only(right: 7),
                                  child: Pill(
                                    'Izoh yuborildi',
                                    tone: Tone.primary,
                                  ),
                                ),
                              Pill(
                                lbl(visible[i].status),
                                tone: tn(visible[i].status),
                                dot: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _explainAbsence(BuildContext context) async {
    final controller = TextEditingController();
    var reason = 'Salomatlik';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yo‘qlik sababini yuborish'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  decoration: const InputDecoration(
                    labelText: 'Sabab',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Salomatlik',
                      child: Text('Salomatlik'),
                    ),
                    DropdownMenuItem(
                      value: 'Oilaviy sabab',
                      child: Text('Oilaviy sabab'),
                    ),
                    DropdownMenuItem(value: 'Boshqa', child: Text('Boshqa')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => reason = value ?? reason),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Qo‘shimcha izoh',
                    hintText: 'Ustoz uchun qisqa ma’lumot',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => sfToast(
                    context,
                    'Ma’lumotnoma biriktirildi',
                    tone: Sf.success,
                  ),
                  icon: const Icon(Icons.attach_file_rounded),
                  label: const Text('Hujjat biriktirish'),
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
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Yuborish'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (submitted == true) {
      setState(() => _explained.add('a6'));
      if (context.mounted) {
        sfToast(
          context,
          'Sabab ustozga yuborildi',
          sub: reason,
          tone: Sf.success,
        );
      }
    }
  }

  Future<void> _showAttendanceDetail(
    BuildContext context,
    _AttendanceEntry entry,
  ) {
    final label = switch (entry.status) {
      'present' => 'Darsda qatnashgan',
      'late' => '7 daqiqa kechikkan',
      _ => 'Darsda qatnashmagan',
    };
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${entry.subject} · ${entry.date}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Sf.t(size: 14, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Belgilagan: Nigora Karimova · ${entry.time}',
              style: Sf.t(size: 12, color: Sf.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Yopish'),
          ),
          if (widget.role == AppRole.parent && entry.status == 'absent')
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _explainAbsence(context);
              },
              child: const Text('Sabab yozish'),
            ),
        ],
      ),
    );
  }
}

class _AttendanceEntry {
  final String date;
  final String subject;
  final String status;
  final String time;
  final String id;

  const _AttendanceEntry(
    this.date,
    this.subject,
    this.status,
    this.time,
    this.id,
  );
}

// ─────────────────────────── CARDS (Kartalarim) ───────────────────────────
class CardsScreen extends StatefulWidget {
  final AppRole role;
  const CardsScreen({super.key, this.role = AppRole.student});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  String _filter = 'Barchasi';
  String _subject = 'Barchasi';

  static const _cards = <_Achievement>[
    _Achievement(
      'Yulduz karta',
      true,
      'Mustaqil yechim · 3-misol',
      '25 Iyul',
      'Algebra',
      'Nigora Karimova',
    ),
    _Achievement(
      'Aktivlik',
      true,
      'Sinfdoshlarga yordam',
      '23 Iyul',
      'Geometriya',
      'Bobur Aliyev',
    ),
    _Achievement(
      'Yulduz karta',
      true,
      'Toza daftar',
      '19 Iyul',
      'Algebra',
      'Nigora Karimova',
    ),
    _Achievement(
      'Ogohlantirish',
      false,
      'Uy ishi tayyor emas',
      '15 Iyul',
      'Ingliz tili',
      'Aziz Tursunov',
    ),
    _Achievement(
      'Yulduz karta',
      true,
      'Olimpiada 2-bosqich',
      '12 Iyul',
      'Algebra',
      'Nigora Karimova',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _cards.where((card) {
      final typeMatch =
          _filter == 'Barchasi' ||
          (_filter == 'Up' && card.up) ||
          (_filter == 'Down' && !card.up);
      final subjectMatch = _subject == 'Barchasi' || card.subject == _subject;
      return typeMatch && subjectMatch;
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: widget.role == AppRole.parent
              ? 'Akmal · 9-B'
              : 'Mening yutuqlarim',
          title: const Text('Kartalar'),
          sub: '12 Up · 1 Down · bu oy',
          right: SoftButton(
            'Natijani ulashish',
            icon: Icons.ios_share_rounded,
            onTap: () => _share(context),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Sf.surface,
            border: Border.all(color: Sf.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 26,
            runSpacing: 18,
            children: const [
              StarCard(
                up: true,
                scale: 1.0,
                recipient: 'Akbarov Akmal',
                reason: 'Mustaqil yechim · 3-misol',
                issuer: 'N. Karimova',
                when: '25.07 · 09:42',
                typeName: 'Yulduz karta',
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CardStat(value: '↑12', label: 'Up karta', color: Sf.goldUp),
                  SizedBox(width: 22),
                  _CardStat(value: '↓1', label: 'Down karta', color: Sf.danger),
                  SizedBox(width: 22),
                  _CardStat(
                    value: '#2',
                    label: 'Sinfda o‘rin',
                    color: Sf.accent,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Filtrlash',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final filter in const ['Barchasi', 'Up', 'Down'])
                ChoiceChip(
                  label: Text(filter),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  initialValue: _subject,
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
                    DropdownMenuItem(value: 'Algebra', child: Text('Algebra')),
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Karta tarixi · ${visible.length}',
          child: visible.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.filter_alt_off_rounded,
                        size: 40,
                        color: Sf.muted2,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bu filtrda karta yo‘q',
                        style: Sf.t(size: 13.5, weight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _filter = 'Barchasi';
                          _subject = 'Barchasi';
                        }),
                        child: const Text('Filtrlarni tozalash'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < visible.length; i++)
                      _CardHistoryRow(
                        title: visible[i].title,
                        up: visible[i].up,
                        reason: visible[i].reason,
                        date: visible[i].date,
                        last: i == visible.length - 1,
                        onTap: () => _showDetails(context, visible[i]),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _share(BuildContext context) async {
    await Clipboard.setData(
      const ClipboardData(
        text:
            'StarForge EDU · Akmalning Iyul natijasi: 12 ta Up karta, 1 ta ogohlantirish, sinfda #2.',
      ),
    );
    if (context.mounted) {
      sfToast(context, 'Natija nusxalandi', tone: Sf.success);
    }
  }

  Future<void> _showDetails(BuildContext context, _Achievement card) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(card.title),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Pill(
                    card.up ? 'Up karta' : 'Ogohlantirish',
                    tone: card.up ? Tone.success : Tone.danger,
                  ),
                  Pill(card.subject, tone: Tone.neutral),
                  Pill(card.date, tone: Tone.neutral),
                ],
              ),
              const SizedBox(height: 16),
              Text('“${card.reason}”', style: Sf.serif(size: 17, height: 1.4)),
              const SizedBox(height: 12),
              Text(
                'Bergan ustoz: ${card.teacher}',
                style: Sf.t(size: 12, color: Sf.muted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Yopish'),
          ),
          if (!card.up)
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                sfToast(
                  context,
                  'Izoh so‘rovi ustozga yuborildi',
                  tone: Sf.success,
                );
              },
              icon: const Icon(Icons.help_outline_rounded),
              label: const Text('Izoh so‘rash'),
            ),
        ],
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _CardStat({
    required this.value,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Sf.monoStyle(size: 28, weight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 3),
        Text(
          label.toUpperCase(),
          style: Sf.t(
            size: 10,
            weight: FontWeight.w600,
            color: Sf.muted,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _CardHistoryRow extends StatelessWidget {
  final String title, reason, date;
  final bool up, last;
  final VoidCallback onTap;
  const _CardHistoryRow({
    required this.title,
    required this.up,
    required this.reason,
    required this.date,
    required this.last,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
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
              width: 26,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: up
                      ? const [Color(0xFFF6E0AC), Color(0xFFE9C272)]
                      : const [Color(0xFFF0C9BE), Color(0xFFD88A75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x1A000000)),
              ),
              child: SfStar(
                size: 11,
                color: up ? const Color(0xFF7A4F0E) : const Color(0xFF5C1A0C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Sf.t(
                      size: 13,
                      weight: FontWeight.w700,
                      color: up ? Sf.ink : Sf.danger,
                    ),
                  ),
                  Text(
                    '“$reason”',
                    style: Sf.t(
                      size: 11.5,
                      color: Sf.muted,
                      style: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              date,
              style: Sf.monoStyle(
                size: 11,
                weight: FontWeight.w400,
                color: Sf.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Achievement {
  final String title;
  final bool up;
  final String reason;
  final String date;
  final String subject;
  final String teacher;

  const _Achievement(
    this.title,
    this.up,
    this.reason,
    this.date,
    this.subject,
    this.teacher,
  );
}

// ─────────────────────────── MATERIALS (Materiallar) ───────────────────────────
class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _type = 'Barchasi';
  bool _favoritesOnly = false;

  static const _files = [
    _MaterialItem(
      id: 'quadratic-pdf',
      name: 'Kvadrat tenglama.pdf',
      meta: 'PDF · 8 bet · 2.4 MB',
      type: 'PDF',
      subject: 'Algebra',
      icon: Icons.picture_as_pdf_rounded,
      color: Sf.danger,
    ),
    _MaterialItem(
      id: 'functions-video',
      name: 'Funksiyalar.mp4',
      meta: 'Video · 6:42 · 18 MB',
      type: 'Video',
      subject: 'Algebra',
      icon: Icons.play_circle_fill_rounded,
      color: Sf.primary,
    ),
    _MaterialItem(
      id: 'exercises-doc',
      name: 'Mashqlar.docx',
      meta: 'DOCX · 12 bet · 860 KB',
      type: 'Hujjat',
      subject: 'Geometriya',
      icon: Icons.description_rounded,
      color: Sf.accent,
    ),
    _MaterialItem(
      id: 'english-audio',
      name: 'Unit 8 listening.mp3',
      meta: 'Audio · 4:18 · 5.1 MB',
      type: 'Audio',
      subject: 'Ingliz tili',
      icon: Icons.headphones_rounded,
      color: Sf.success,
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
    final visible = _files.where((file) {
      final matchesQuery = '${file.name} ${file.subject}'
          .toLowerCase()
          .contains(_query.trim().toLowerCase());
      final matchesType = _type == 'Barchasi' || file.type == _type;
      final matchesFavorite =
          !_favoritesOnly || state.favoriteMaterials.contains(file.id);
      return matchesQuery && matchesType && matchesFavorite;
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: '9-B Algebra',
          title: const Text('Materiallar'),
          sub:
              '${visible.length} ta fayl · ${state.downloadedMaterials.length} ta offline',
          right: FilterChip(
            selected: _favoritesOnly,
            avatar: const Icon(Icons.star_rounded, size: 18),
            label: const Text('Saralanganlar'),
            onSelected: (value) => setState(() => _favoritesOnly = value),
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
                  hintText: 'Fayl yoki fan nomi...',
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
                  for (final type in const [
                    'Barchasi',
                    'PDF',
                    'Video',
                    'Hujjat',
                    'Audio',
                  ])
                    ChoiceChip(
                      label: Text(type),
                      selected: _type == type,
                      onSelected: (_) => setState(() => _type = type),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Fayllar · ${visible.length}',
          bodyPadding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: visible.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.folder_off_rounded,
                        size: 44,
                        color: Sf.muted2,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Mos material topilmadi',
                        style: Sf.t(size: 14, weight: FontWeight.w800),
                      ),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _type = 'Barchasi';
                            _favoritesOnly = false;
                          });
                        },
                        child: const Text('Filtrlarni tozalash'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < visible.length; i++)
                      InkWell(
                        onTap: () => _preview(context, visible[i]),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            border: i < visible.length - 1
                                ? const Border(
                                    bottom: BorderSide(color: Sf.border),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: visible[i].color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  visible[i].icon,
                                  size: 19,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      visible[i].name,
                                      style: Sf.t(
                                        size: 13,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${visible[i].subject} · ${visible[i].meta}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Sf.monoStyle(
                                        size: 10.5,
                                        weight: FontWeight.w400,
                                        color: Sf.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip:
                                    state.favoriteMaterials.contains(
                                      visible[i].id,
                                    )
                                    ? 'Saralanganlardan olib tashlash'
                                    : 'Saralanganlarga qo‘shish',
                                onPressed: () =>
                                    state.toggleFavoriteMaterial(visible[i].id),
                                icon: Icon(
                                  state.favoriteMaterials.contains(
                                        visible[i].id,
                                      )
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color:
                                      state.favoriteMaterials.contains(
                                        visible[i].id,
                                      )
                                      ? Sf.accent
                                      : Sf.muted,
                                ),
                              ),
                              IconButton(
                                tooltip:
                                    state.downloadedMaterials.contains(
                                      visible[i].id,
                                    )
                                    ? 'Offline fayl tayyor'
                                    : 'Offline yuklab olish',
                                onPressed:
                                    state.downloadedMaterials.contains(
                                      visible[i].id,
                                    )
                                    ? () => sfToast(
                                        context,
                                        'Fayl offline rejimda tayyor',
                                        tone: Sf.success,
                                      )
                                    : () =>
                                          _download(context, visible[i], state),
                                icon: Icon(
                                  state.downloadedMaterials.contains(
                                        visible[i].id,
                                      )
                                      ? Icons.offline_pin_rounded
                                      : Icons.download_rounded,
                                  color:
                                      state.downloadedMaterials.contains(
                                        visible[i].id,
                                      )
                                      ? Sf.success
                                      : Sf.ink2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _download(
    BuildContext context,
    _MaterialItem file,
    AppState state,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '${file.name} yuklanmoqda...',
                style: Sf.t(size: 13, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!context.mounted) return;
    Navigator.pop(context);
    state.markMaterialDownloaded(file.id);
    sfToast(context, 'Offline saqlandi', sub: file.name, tone: Sf.success);
  }

  Future<void> _preview(BuildContext context, _MaterialItem file) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(file.name),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 210,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: file.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Sf.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(file.icon, size: 56, color: file.color),
                    const SizedBox(height: 12),
                    Text(
                      file.type == 'Video'
                          ? 'Video ko‘rishga tayyor'
                          : file.type == 'Audio'
                          ? 'Audio tinglashga tayyor'
                          : 'Hujjatning demo ko‘rinishi',
                      style: Sf.t(size: 13, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${file.subject} · ${file.meta}',
                style: Sf.t(size: 12, color: Sf.muted),
              ),
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
              sfToast(context, 'Ko‘rish boshlandi', tone: file.color);
            },
            icon: Icon(
              file.type == 'Video' || file.type == 'Audio'
                  ? Icons.play_arrow_rounded
                  : Icons.open_in_new_rounded,
            ),
            label: Text(
              file.type == 'Video' || file.type == 'Audio'
                  ? 'Boshlash'
                  : 'Ochish',
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialItem {
  final String id;
  final String name;
  final String meta;
  final String type;
  final String subject;
  final IconData icon;
  final Color color;

  const _MaterialItem({
    required this.id,
    required this.name,
    required this.meta,
    required this.type,
    required this.subject,
    required this.icon,
    required this.color,
  });
}

// ─────────────────────────── SCHEDULE (Jadval) ───────────────────────────
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _weekOffset = 0;
  bool _agendaView = false;
  int _selectedDay = 1;

  static const _lessons = [
    _Lesson(
      id: 'mon-algebra',
      day: 0,
      time: '09:00',
      subject: 'Algebra',
      room: '304',
      teacher: 'Nigora Karimova',
      color: Sf.primary,
    ),
    _Lesson(
      id: 'tue-algebra',
      day: 1,
      time: '09:00',
      subject: 'Algebra',
      room: '304',
      teacher: 'Nigora Karimova',
      color: Sf.primary,
    ),
    _Lesson(
      id: 'tue-geometry',
      day: 1,
      time: '10:00',
      subject: 'Geometriya',
      room: '207',
      teacher: 'Bobur Aliyev',
      color: Sf.accent,
    ),
    _Lesson(
      id: 'wed-english',
      day: 2,
      time: '11:30',
      subject: 'Ingliz tili',
      room: '112',
      teacher: 'Aziz Tursunov',
      color: Sf.success,
    ),
    _Lesson(
      id: 'thu-algebra',
      day: 3,
      time: '09:00',
      subject: 'Algebra',
      room: '304',
      teacher: 'Nigora Karimova',
      color: Sf.primary,
    ),
    _Lesson(
      id: 'fri-geometry',
      day: 4,
      time: '10:00',
      subject: 'Geometriya',
      room: '207',
      teacher: 'Bobur Aliyev',
      color: Sf.accent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: _weekOffset == 0
              ? 'Bu hafta'
              : _weekOffset < 0
              ? 'Oldingi hafta'
              : 'Keyingi hafta',
          title: const Text('Jadval'),
          sub: '9-B · 6 ta dars · ${state.lessonReminders.length} ta eslatma',
          right: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.calendar_view_week_rounded),
                label: Text('Hafta'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.view_agenda_rounded),
                label: Text('Ro‘yxat'),
              ),
            ],
            selected: {_agendaView},
            showSelectedIcon: false,
            onSelectionChanged: (value) =>
                setState(() => _agendaView = value.first),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton.outlined(
              tooltip: 'Oldingi hafta',
              onPressed: () => setState(() => _weekOffset--),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            OutlinedButton(
              onPressed: () => setState(() => _weekOffset = 0),
              child: Text(_weekLabel()),
            ),
            IconButton.outlined(
              tooltip: 'Keyingi hafta',
              onPressed: () => setState(() => _weekOffset++),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            if (_weekOffset != 0)
              TextButton(
                onPressed: () => setState(() => _weekOffset = 0),
                child: const Text('Bugungi haftaga qaytish'),
              ),
          ],
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: _agendaView ? 'Kun tartibi' : 'Haftalik ko‘rinish',
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_agendaView || constraints.maxWidth < 600) {
                return _AgendaSchedule(
                  lessons: _lessons,
                  selectedDay: _selectedDay,
                  onDayChanged: (value) => setState(() => _selectedDay = value),
                  onOpen: (lesson) => _showLesson(context, lesson, state),
                );
              }
              return _WeekSchedule(
                lessons: _lessons,
                onOpen: (lesson) => _showLesson(context, lesson, state),
              );
            },
          ),
        ),
      ],
    );
  }

  String _weekLabel() {
    final monday = DateTime.now()
        .subtract(Duration(days: DateTime.now().weekday - 1))
        .add(Duration(days: _weekOffset * 7));
    final friday = monday.add(const Duration(days: 4));
    return '${monday.day}–${friday.day} ${_monthName(friday.month)}';
  }

  Future<void> _showLesson(
    BuildContext context,
    _Lesson lesson,
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
          final reminded = state.lessonReminders.contains(lesson.id);
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
                        color: lesson.color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.subject,
                            style: Sf.t(size: 20, weight: FontWeight.w800),
                          ),
                          Text(
                            '${lesson.time}–${_endTime(lesson.time)} · xona ${lesson.room}',
                            style: Sf.t(size: 12, color: Sf.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Avatar(lesson.teacher, size: 42),
                  title: Text(
                    lesson.teacher,
                    style: Sf.t(size: 13.5, weight: FontWeight.w700),
                  ),
                  subtitle: const Text('Fan o‘qituvchisi'),
                  trailing: IconButton(
                    tooltip: 'Ustozga yozish',
                    onPressed: () => sfToast(
                      context,
                      'Xabarlar bo‘limidan ustozga yozishingiz mumkin',
                      tone: Sf.primary,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: reminded,
                  onChanged: (_) {
                    state.toggleLessonReminder(lesson.id);
                    sfToast(
                      context,
                      reminded
                          ? 'Eslatma o‘chirildi'
                          : '15 daqiqa oldin eslatadi',
                      tone: reminded ? Sf.muted : Sf.success,
                    );
                  },
                  title: const Text('Dars eslatmasi'),
                  subtitle: const Text('Boshlanishidan 15 daqiqa oldin'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => sfToast(
                    context,
                    'Taqvim hodisasi tayyorlandi',
                    sub: '${lesson.subject} · ${lesson.time}',
                    tone: Sf.success,
                  ),
                  icon: const Icon(Icons.event_available_rounded),
                  label: const Text('Taqvimga qo‘shish'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WeekSchedule extends StatelessWidget {
  final List<_Lesson> lessons;
  final ValueChanged<_Lesson> onOpen;

  const _WeekSchedule({required this.lessons, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    const days = ['Du', 'Se', 'Ch', 'Pa', 'Ju'];
    const slots = ['09:00', '10:00', '11:30'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var day = 0; day < days.length; day++)
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    days[day],
                    style: Sf.t(
                      size: 11,
                      weight: FontWeight.w700,
                      color: Sf.muted,
                    ),
                  ),
                ),
                for (final slot in slots)
                  _LessonCell(
                    lesson: _findLesson(lessons, day, slot),
                    onOpen: onOpen,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LessonCell extends StatelessWidget {
  final _Lesson? lesson;
  final ValueChanged<_Lesson> onOpen;

  const _LessonCell({required this.lesson, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      margin: const EdgeInsets.fromLTRB(3, 0, 3, 6),
      child: lesson == null
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: Sf.surface2.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
            )
          : Material(
              color: lesson!.color,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => onOpen(lesson!),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 6,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lesson!.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Sf.t(
                          size: 10.5,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        lesson!.time,
                        style: Sf.monoStyle(
                          size: 9,
                          weight: FontWeight.w500,
                          color: Colors.white,
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

class _AgendaSchedule extends StatelessWidget {
  final List<_Lesson> lessons;
  final int selectedDay;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<_Lesson> onOpen;

  const _AgendaSchedule({
    required this.lessons,
    required this.selectedDay,
    required this.onDayChanged,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    const days = ['Du', 'Se', 'Ch', 'Pa', 'Ju'];
    final visible = lessons
        .where((lesson) => lesson.day == selectedDay)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<int>(
            segments: [
              for (var index = 0; index < days.length; index++)
                ButtonSegment(value: index, label: Text(days[index])),
            ],
            selected: {selectedDay},
            showSelectedIcon: false,
            onSelectionChanged: (value) => onDayChanged(value.first),
          ),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                const Icon(
                  Icons.event_available_rounded,
                  color: Sf.success,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bu kunda dars yo‘q',
                  style: Sf.t(size: 13.5, weight: FontWeight.w700),
                ),
              ],
            ),
          )
        else
          for (var index = 0; index < visible.length; index++)
            Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: visible[index].color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    visible[index].time,
                    style: Sf.monoStyle(
                      size: 9.5,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                title: Text(
                  visible[index].subject,
                  style: Sf.t(size: 13.5, weight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Xona ${visible[index].room} · ${visible[index].teacher}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onOpen(visible[index]),
              ),
            ),
      ],
    );
  }
}

class _Lesson {
  final String id;
  final int day;
  final String time;
  final String subject;
  final String room;
  final String teacher;
  final Color color;

  const _Lesson({
    required this.id,
    required this.day,
    required this.time,
    required this.subject,
    required this.room,
    required this.teacher,
    required this.color,
  });
}

_Lesson? _findLesson(List<_Lesson> lessons, int day, String time) {
  for (final lesson in lessons) {
    if (lesson.day == day && lesson.time == time) return lesson;
  }
  return null;
}

String _endTime(String start) => switch (start) {
  '09:00' => '09:45',
  '10:00' => '10:45',
  '11:30' => '12:15',
  _ => start,
};

String _monthName(int month) => const [
  '',
  'Yan',
  'Fev',
  'Mar',
  'Apr',
  'May',
  'Iyun',
  'Iyul',
  'Avg',
  'Sen',
  'Okt',
  'Noy',
  'Dek',
][month];

// ─────────────────────────── MESSAGES (Xabarlar) ───────────────────────────
class MessagesScreen extends StatefulWidget {
  final AppRole role;
  const MessagesScreen({super.key, this.role = AppRole.student});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _ctrl = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  int _activeContact = 0;
  bool _searchVisible = false;
  bool _muted = false;
  String _messageQuery = '';

  static const _contacts = [
    _ChatContact(
      name: 'Nigora Karimova',
      subject: 'Matematika',
      unread: 2,
      color: Sf.primary,
    ),
    _ChatContact(
      name: 'Bobur Aliyev',
      subject: 'Geometriya',
      unread: 0,
      color: Sf.accent,
    ),
    _ChatContact(
      name: 'Aziz Tursunov',
      subject: 'Ingliz tili',
      unread: 1,
      color: Sf.success,
    ),
  ];

  late final Map<int, List<_Msg>> _threads;

  @override
  void initState() {
    super.initState();
    _threads = {
      0: [
        _Msg("Assalomu alaykum! Akmal bugun a'lo ishladi 🌟", false, '09:48'),
        _Msg(
          widget.role == AppRole.parent
              ? 'Rahmat ustoz! Juda xursandmiz.'
              : 'Rahmat ustoz! Keyingi misollarni ham ishlayman.',
          true,
          '10:02',
          delivered: true,
        ),
        _Msg('Uy ishini ertaga tekshiramiz.', false, '10:05'),
      ],
      1: [
        _Msg(
          'Uchburchaklar mavzusi uchun yangi mashq yukladim.',
          false,
          'Kecha',
        ),
      ],
      2: [
        _Msg('Unit 8 listening topshirig‘ini esdan chiqarmang.', false, 'Du'),
      ],
    };
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<_Msg> get _messages => _threads[_activeContact]!;

  void _send([String? preset]) {
    if (preset != null) _ctrl.text = preset;
    final t = _ctrl.text.trim();
    if (t.isEmpty) {
      sfToast(context, 'Xabar bo‘sh', tone: Sf.warn);
      return;
    }
    setState(() {
      _messages.add(_Msg(t, true, _currentTime(), delivered: true));
      _ctrl.clear();
    });
    _scrollToBottom();
    sfToast(context, 'Xabar yuborildi', tone: Sf.success);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _selectContact(int index) {
    setState(() {
      _activeContact = index;
      _messageQuery = '';
      _searchController.clear();
    });
    _scrollToBottom();
  }

  Future<void> _attach() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Sf.surface,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Biriktirma yuborish',
              style: Sf.t(size: 18, weight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            for (final item in const [
              (Icons.photo_camera_rounded, 'Rasm', 'yechim.jpg'),
              (Icons.insert_drive_file_rounded, 'Hujjat', 'vazifa.pdf'),
              (Icons.mic_rounded, 'Ovozli xabar', 'audio.m4a'),
            ])
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Sf.primarySoft,
                  foregroundColor: Sf.primary,
                  child: Icon(item.$1),
                ),
                title: Text(item.$2),
                subtitle: Text(item.$3),
                onTap: () => Navigator.pop(sheetContext, item.$3),
              ),
          ],
        ),
      ),
    );
    if (type == null || !mounted) return;
    setState(() {
      _messages.add(
        _Msg(
          'Biriktirma',
          true,
          _currentTime(),
          delivered: true,
          attachment: type,
        ),
      );
    });
    _scrollToBottom();
    if (mounted) {
      sfToast(context, 'Biriktirma yuborildi', sub: type, tone: Sf.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = _contacts[_activeContact];
    final visibleMessages = _messages.where((message) {
      final query = _messageQuery.trim().toLowerCase();
      return query.isEmpty ||
          '${message.text} ${message.attachment ?? ''}'.toLowerCase().contains(
            query,
          );
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: widget.role == AppRole.parent ? 'Ota-ona' : 'O‘quvchi',
          title: const Text('Xabarlar'),
          sub:
              '3 ta suhbat · ${_contacts.fold<int>(0, (sum, c) => sum + c.unread)} ta yangi',
          right: SoftButton(
            'Yangi suhbat',
            icon: Icons.add_comment_rounded,
            primary: true,
            onTap: () => sfToast(
              context,
              'Ustozni ro‘yxatdan tanlang',
              tone: Sf.primary,
            ),
          ),
        ),
        Container(
          height: 590,
          decoration: BoxDecoration(
            color: Sf.surface,
            border: Border.all(color: Sf.border),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                if (constraints.maxWidth >= 760)
                  SizedBox(
                    width: 250,
                    child: _ConversationList(
                      contacts: _contacts,
                      active: _activeContact,
                      onSelect: _selectContact,
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _ChatHeader(
                        contact: contact,
                        contacts: _contacts,
                        compact: constraints.maxWidth < 760,
                        muted: _muted,
                        searchVisible: _searchVisible,
                        onSelect: _selectContact,
                        onToggleSearch: () =>
                            setState(() => _searchVisible = !_searchVisible),
                        onToggleMute: () {
                          setState(() => _muted = !_muted);
                          sfToast(
                            context,
                            _muted
                                ? 'Suhbat ovozsiz qilindi'
                                : 'Bildirishnomalar yoqildi',
                            tone: _muted ? Sf.muted : Sf.success,
                          );
                        },
                      ),
                      if (_searchVisible)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (value) =>
                                setState(() => _messageQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Suhbatdan izlash...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: IconButton(
                                tooltip: 'Izlashni yopish',
                                onPressed: () => setState(() {
                                  _searchVisible = false;
                                  _messageQuery = '';
                                  _searchController.clear();
                                }),
                                icon: const Icon(Icons.close_rounded),
                              ),
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Container(
                          color: Sf.bg,
                          child: visibleMessages.isEmpty
                              ? Center(
                                  child: Text(
                                    'Mos xabar topilmadi',
                                    style: Sf.t(color: Sf.muted),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: visibleMessages.length,
                                  itemBuilder: (_, index) =>
                                      _Bubble(visibleMessages[index]),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final reply
                                in widget.role == AppRole.parent
                                    ? const [
                                        'Rahmat, ustoz',
                                        'Tushunarli',
                                        'Bugun ko‘rib chiqamiz',
                                      ]
                                    : const [
                                        'Tushundim, ustoz',
                                        'Rahmat',
                                        'Savolim bor',
                                      ])
                              ActionChip(
                                label: Text(reply),
                                onPressed: () => _send(reply),
                              ),
                          ],
                        ),
                      ),
                      _ChatInput(
                        controller: _ctrl,
                        onSend: _send,
                        onAttach: _attach,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Msg {
  final String text;
  final bool out;
  final String time;
  final String? lead; // serif-italic lead word for incoming bubbles
  final bool delivered;
  final String? attachment;
  _Msg(
    this.text,
    this.out,
    this.time, {
    this.lead,
    this.delivered = false,
    this.attachment,
  });
}

class _ChatContact {
  final String name;
  final String subject;
  final int unread;
  final Color color;

  const _ChatContact({
    required this.name,
    required this.subject,
    required this.unread,
    required this.color,
  });
}

class _ConversationList extends StatelessWidget {
  final List<_ChatContact> contacts;
  final int active;
  final ValueChanged<int> onSelect;

  const _ConversationList({
    required this.contacts,
    required this.active,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Sf.surface,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Sf.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Suhbatlar',
                style: Sf.t(size: 14, weight: FontWeight.w800),
              ),
            ),
            const Divider(height: 1, color: Sf.border),
            Expanded(
              child: ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return ListTile(
                    selected: active == index,
                    selectedTileColor: Sf.primarySoft.withValues(alpha: 0.45),
                    minTileHeight: 72,
                    leading: Avatar(
                      contact.name,
                      size: 40,
                      color: contact.color,
                    ),
                    title: Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Sf.t(size: 12.5, weight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      contact.subject,
                      style: Sf.t(size: 10.5, color: Sf.muted),
                    ),
                    trailing: contact.unread == 0
                        ? null
                        : Badge(label: Text('${contact.unread}')),
                    onTap: () => onSelect(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final _ChatContact contact;
  final List<_ChatContact> contacts;
  final bool compact;
  final bool muted;
  final bool searchVisible;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggleSearch;
  final VoidCallback onToggleMute;

  const _ChatHeader({
    required this.contact,
    required this.contacts,
    required this.compact,
    required this.muted,
    required this.searchVisible,
    required this.onSelect,
    required this.onToggleSearch,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: const BoxDecoration(
        color: Sf.surface,
        border: Border(bottom: BorderSide(color: Sf.border)),
      ),
      child: Row(
        children: [
          if (compact)
            PopupMenuButton<int>(
              tooltip: 'Suhbatni tanlash',
              onSelected: onSelect,
              itemBuilder: (_) => [
                for (var index = 0; index < contacts.length; index++)
                  PopupMenuItem(
                    value: index,
                    child: Row(
                      children: [
                        Avatar(
                          contacts[index].name,
                          size: 30,
                          color: contacts[index].color,
                        ),
                        const SizedBox(width: 9),
                        Expanded(child: Text(contacts[index].name)),
                      ],
                    ),
                  ),
              ],
              child: Avatar(contact.name, size: 40, color: contact.color),
            )
          else
            Avatar(contact.name, size: 40, color: contact.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Sf.t(size: 13.5, weight: FontWeight.w700),
                ),
                Text(
                  '● onlayn · ${contact.subject}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Sf.t(size: 10.5, color: Sf.success),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: searchVisible ? 'Izlashni yopish' : 'Suhbatdan izlash',
            onPressed: onToggleSearch,
            icon: Icon(
              searchVisible ? Icons.search_off_rounded : Icons.search_rounded,
            ),
          ),
          IconButton(
            tooltip: muted ? 'Bildirishnomani yoqish' : 'Ovozsiz qilish',
            onPressed: onToggleMute,
            icon: Icon(
              muted
                  ? Icons.notifications_off_rounded
                  : Icons.notifications_active_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Msg m;
  const _Bubble(this.m);
  @override
  Widget build(BuildContext context) {
    final baseStyle = Sf.t(
      size: 13.5,
      height: 1.4,
      color: m.out ? Colors.white : Sf.ink,
    );
    final Widget body = (m.lead != null && !m.out)
        ? RichText(
            text: TextSpan(
              style: baseStyle,
              children: [
                TextSpan(
                  text: m.lead,
                  style: Sf.serif(size: 15, color: Sf.ink),
                ),
                TextSpan(text: ' ${m.text}'),
              ],
            ),
          )
        : Text(m.text, style: baseStyle);
    return LayoutBuilder(
      builder: (ctx, c) {
        return Align(
          alignment: m.out ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            constraints: BoxConstraints(maxWidth: c.maxWidth * 0.76),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: BoxDecoration(
              color: m.out ? Sf.primary : Sf.surface,
              border: m.out ? null : Border.all(color: Sf.border),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(m.out ? 16 : 4),
                bottomRight: Radius.circular(m.out ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (m.attachment != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: m.out
                          ? Colors.white.withValues(alpha: 0.16)
                          : Sf.surface2,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_file_rounded,
                          size: 17,
                          color: m.out ? Colors.white : Sf.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            m.attachment!,
                            overflow: TextOverflow.ellipsis,
                            style: Sf.t(
                              size: 11.5,
                              weight: FontWeight.w700,
                              color: m.out ? Colors.white : Sf.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (m.text != 'Biriktirma') body,
                if (m.time.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        m.time,
                        style: Sf.t(
                          size: 9,
                          color: m.out ? Colors.white : Sf.muted,
                        ),
                      ),
                      if (m.out && m.delivered) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.done_all_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onAttach;
  const _ChatInput({
    required this.controller,
    required this.onSend,
    this.onAttach,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Sf.border)),
      ),
      child: Row(
        children: [
          if (onAttach != null) ...[
            IconButton(
              tooltip: 'Fayl biriktirish',
              onPressed: onAttach,
              icon: const Icon(Icons.attach_file_rounded),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSend(),
              style: Sf.t(size: 13.5),
              decoration: InputDecoration(
                hintText: 'Xabar yozing...',
                hintStyle: Sf.t(size: 13.5, color: Sf.muted),
                filled: true,
                fillColor: Sf.surface2,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Sf.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Sf.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Sf.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Xabar yuborish',
            child: Material(
              color: Sf.primary,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onSend,
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _currentTime() {
  final now = DateTime.now();
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

// ─────────────────────────── AI repetitor ───────────────────────────
class AiScreen extends StatefulWidget {
  const AiScreen({super.key});
  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _ctrl = TextEditingController();
  final _scrollController = ScrollController();
  String _subject = 'Algebra';
  String _level = 'Bosqichma-bosqich';
  bool _thinking = false;
  bool _quizVisible = false;
  int? _quizAnswer;
  int _generation = 0;
  final List<_Msg> _msgs = [
    _Msg('Kvadrat tenglamani qanday yechaman?', true, ''),
    _Msg(
      'Diskriminant formulasidan boshlaymiz: D = b² − 4ac. Keling, birga misol yechamiz: x² − 5x + 6 = 0',
      false,
      '',
      lead: 'Oson!',
    ),
    _Msg('D = 25 − 24 = 1', true, ''),
    _Msg(
      'Aynan to‘g‘ri! 🎯 Endi ildizlarni toping: x = (5 ± 1) / 2',
      false,
      '',
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ask([String? preset]) async {
    if (preset != null) _ctrl.text = preset;
    final t = _ctrl.text.trim();
    if (t.isEmpty) {
      sfToast(context, 'Savol yozing', tone: Sf.warn);
      return;
    }
    if (_thinking) return;
    final request = ++_generation;
    setState(() {
      _msgs.add(_Msg(t, true, ''));
      _ctrl.clear();
      _thinking = true;
      _quizVisible = false;
      _quizAnswer = null;
    });
    _scrollToBottom();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || request != _generation) return;
    setState(() {
      _thinking = false;
      _msgs.add(_Msg(_responseFor(t), false, '', lead: 'Birga yechamiz!'));
    });
    _scrollToBottom();
  }

  String _responseFor(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('misol')) {
      return _level == 'Qisqa javob'
          ? 'Yangi misol: 2x² − 7x + 3 = 0. D = 25, ildizlar 3 va 0.5.'
          : 'Yangi misol: 2x² − 7x + 3 = 0. Avval a=2, b=−7, c=3 ni ajrating. So‘ng D=b²−4ac ni hisoblang. D qiymatini o‘zingiz topib ko‘ring.';
    }
    if (lower.contains('tushuntir')) {
      return 'Diskriminant ildizlar sonini ko‘rsatadi: D>0 bo‘lsa 2 ta, D=0 bo‘lsa 1 ta, D<0 bo‘lsa haqiqiy ildiz yo‘q. Bu qoida kvadrat tenglamaning grafik bilan x-o‘qini nechta nuqtada kesishiga bog‘liq.';
    }
    return '$_subject bo‘yicha savolni uch qismga ajratamiz: berilganlar, kerakli formula va tekshiruv. Avval qaysi qiymatlar ma’lum ekanini yozing; men keyingi qadamni tekshiraman.';
  }

  void _quickAction(String action) {
    switch (action) {
      case 'Yana misol':
        _ask('Yana bitta misol ber');
      case 'Tushuntir':
        _ask('Buni boshqacha tushuntir');
      case 'Test qil':
        setState(() {
          _quizVisible = true;
          _quizAnswer = null;
        });
        _scrollToBottom();
    }
  }

  void _answerQuiz(int answer) {
    if (_quizAnswer != null) return;
    setState(() {
      _quizAnswer = answer;
      _msgs.add(
        _Msg(
          answer == 1
              ? 'To‘g‘ri! D = 5² − 4·1·6 = 1. Ajoyib natija 🎯'
              : 'Yana tekshirib ko‘ring: D = b² − 4ac = 25 − 24.',
          false,
          '',
        ),
      );
    });
    _scrollToBottom();
  }

  void _cancelGeneration() {
    if (!_thinking) return;
    _generation++;
    setState(() => _thinking = false);
    sfToast(context, 'Javob yaratish to‘xtatildi', tone: Sf.warn);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('AI tarixini tozalash'),
        content: const Text(
          'Joriy seansdagi savol va javoblar o‘chiriladi. Bu amalni bekor qilib bo‘lmaydi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Sf.danger),
            child: const Text('Tozalash'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _generation++;
      setState(() {
        _thinking = false;
        _quizVisible = false;
        _quizAnswer = null;
        _msgs
          ..clear()
          ..add(
            _Msg(
              'Salom! Mavzuni tanlang va savolingizni yozing. Men tayyor javob bermasdan, bosqichma-bosqich yordam beraman.',
              false,
              '',
            ),
          );
      });
      if (mounted) {
        sfToast(context, 'AI tarixi tozalandi', tone: Sf.success);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: 'AI repetitor',
          title: RichText(
            text: TextSpan(
              style: Sf.t(
                size: 30,
                weight: FontWeight.w800,
                color: Sf.ink,
                letterSpacing: -0.9,
                height: 1.05,
              ),
              children: [
                const TextSpan(text: 'AI '),
                TextSpan(
                  text: 'repetitor',
                  style: Sf.serif(size: 30, color: Sf.ink),
                ),
              ],
            ),
          ),
          sub: 'Maslahatlarni muhim topshiriqlarda ustoz bilan tekshiring',
          right: SoftButton(
            'Tarixni tozalash',
            icon: Icons.delete_sweep_outlined,
            onTap: _clearHistory,
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<String>(
                initialValue: _subject,
                isDense: true,
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
                ],
                onChanged: (value) =>
                    setState(() => _subject = value ?? _subject),
              ),
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Qisqa javob', label: Text('Qisqa')),
                ButtonSegment(
                  value: 'Bosqichma-bosqich',
                  label: Text('Bosqichli'),
                ),
              ],
              selected: {_level},
              showSelectedIcon: false,
              onSelectionChanged: (value) =>
                  setState(() => _level = value.first),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 590,
          decoration: BoxDecoration(
            color: Sf.surface,
            border: Border.all(color: Sf.border),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  color: Sf.bg,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: Sf.aiBg1,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: Sf.aiBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 19,
                              color: Sf.ai,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Shaxsiy ma’lumot, parol yoki to‘lov ma’lumotini AI chatiga yozmang.',
                                style: Sf.t(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: Sf.ai,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final m in _msgs) _Bubble(m),
                      if (_thinking)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: Sf.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Sf.border),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 9),
                                Text('Javob tayyorlanmoqda...'),
                              ],
                            ),
                          ),
                        ),
                      if (_quizVisible)
                        _AiQuizCard(answer: _quizAnswer, onAnswer: _answerQuiz),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in const [
                      'Yana misol',
                      'Tushuntir',
                      'Test qil',
                    ])
                      Builder(
                        builder: (ctx) =>
                            _Chip(p, onTap: () => _quickAction(p)),
                      ),
                  ],
                ),
              ),
              if (_thinking)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: OutlinedButton.icon(
                    onPressed: _cancelGeneration,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Javobni to‘xtatish'),
                  ),
                ),
              _ChatInput(controller: _ctrl, onSend: _ask),
            ],
          ),
        ),
      ],
    );
  }
}

class _AiQuizCard extends StatelessWidget {
  final int? answer;
  final ValueChanged<int> onAnswer;

  const _AiQuizCard({required this.answer, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    const options = ['−1', '1', '25', '49'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Sf.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Sf.aiBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AiBadge(label: 'Mini-test'),
          const SizedBox(height: 10),
          Text(
            'x² − 5x + 6 = 0 tenglama uchun diskriminant nechaga teng?',
            style: Sf.t(size: 13, weight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < options.length; index++)
                ChoiceChip(
                  label: Text(options[index]),
                  selected: answer == index,
                  onSelected: answer == null ? (_) => onAnswer(index) : null,
                ),
            ],
          ),
          if (answer != null) ...[
            const SizedBox(height: 9),
            Text(
              answer == 1
                  ? 'To‘g‘ri javob!'
                  : 'Javob 1. Formulani yana bir marta hisoblang.',
              style: Sf.t(
                size: 11.5,
                weight: FontWeight.w700,
                color: answer == 1 ? Sf.success : Sf.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Chip(this.label, {required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Sf.aiBg1,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Sf.aiBorder),
          ),
          child: Text(
            label,
            style: Sf.t(size: 12, weight: FontWeight.w600, color: Sf.ai),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── SETTINGS (Sozlamalar) ───────────────────────────
class SettingsScreen extends StatefulWidget {
  final AppRole role;
  const SettingsScreen({super.key, this.role = AppRole.student});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isP = widget.role == AppRole.parent;
    final roleKey = widget.role.name;
    final who = state.profileNames[roleKey] ?? (isP ? _parent : _student);
    final sub = isP ? 'Akmalning ota-onasi · 9-B' : '9-B · 14 yosh';
    final accent = isP ? Sf.primary : Sf.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: isP ? 'Ota-ona' : 'O‘quvchi',
          title: const Text('Sozlamalar'),
          sub: who,
          right: SoftButton(
            'Maxfiylik',
            icon: Icons.privacy_tip_rounded,
            primary: true,
            onTap: () => _showPrivacy(context),
          ),
        ),
        SfGrid(
          minTile: 300,
          children: [
            SectionCard(
              title: 'Profil',
              child: LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: 13,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Avatar(who, size: 52, color: accent),
                    SizedBox(
                      width: constraints.maxWidth < 330
                          ? constraints.maxWidth - 70
                          : constraints.maxWidth - 165,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            who,
                            style: Sf.t(size: 15, weight: FontWeight.w800),
                          ),
                          Text(sub, style: Sf.t(size: 12, color: Sf.muted)),
                        ],
                      ),
                    ),
                    SoftButton(
                      'Tahrir',
                      icon: Icons.edit_rounded,
                      onTap: () => _editProfile(context, state, roleKey, who),
                    ),
                  ],
                ),
              ),
            ),
            SectionCard(
              title: 'Bildirishnomalar',
              child: Column(
                children: [
                  for (final r in const [
                    ['push', 'Push xabarlar'],
                    ['att', 'Davomat'],
                    ['card', 'Yangi kartalar'],
                    ['pay', 'To‘lov eslatmasi'],
                    ['homework', 'Vazifa muddatlari'],
                    ['messages', 'Yangi xabarlar'],
                  ])
                    if (isP || r[0] != 'pay')
                      _ToggleRow(
                        label: r[1],
                        value: state.notificationPreferences[r[0]]!,
                        last: r[0] == 'messages',
                        onChanged: (v) {
                          state.setNotificationPreference(r[0], v);
                          sfToast(
                            context,
                            v ? 'Yoqildi' : 'O‘chirildi',
                            tone: v ? Sf.success : Sf.muted,
                          );
                        },
                      ),
                ],
              ),
            ),
            SectionCard(
              title: 'Qulaylik va maxfiylik',
              child: Column(
                children: [
                  _ToggleRow(
                    label: 'Katta matn (+15%)',
                    value: state.largeText,
                    last: false,
                    onChanged: state.setLargeText,
                  ),
                  _ToggleRow(
                    label: 'Animatsiyani kamaytirish',
                    value: state.reduceMotion,
                    last: !isP,
                    onChanged: state.setReduceMotion,
                  ),
                  if (isP)
                    _ToggleRow(
                      label: 'Summalarni yashirish',
                      value: state.hideAmounts,
                      last: true,
                      onChanged: state.setHideAmounts,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _resetDemo(context, state),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Sf.borderStrong),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.restart_alt_rounded,
                    size: 18,
                    color: Sf.danger,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Demo holatini tiklash',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Sf.t(
                        size: 13,
                        weight: FontWeight.w600,
                        color: Sf.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    AppState state,
    String roleKey,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Profil nomini tahrirlash'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Ism va familiya',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () {
              final next = controller.text.trim();
              if (next.length < 3) {
                sfToast(
                  context,
                  'Ism kamida 3 ta belgidan iborat bo‘lsin',
                  tone: Sf.warn,
                );
                return;
              }
              Navigator.pop(dialogContext, next);
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) {
      state.setProfileName(roleKey, value);
      if (context.mounted) {
        sfToast(context, 'Profil yangilandi', tone: Sf.success);
      }
    }
  }

  Future<void> _showPrivacy(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Sf.surface,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maxfiylik va AI xavfsizligi',
              style: Sf.t(size: 20, weight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            for (final item in const [
              (
                Icons.child_care_rounded,
                'Bola ma’lumotlari',
                'Bu demo ma’lumotlari qurilmada, joriy seans davomida saqlanadi.',
              ),
              (
                Icons.auto_awesome_rounded,
                'AI javoblari',
                'AI tavsiyalarini muhim topshiriqlarda ustoz bilan tekshiring.',
              ),
              (
                Icons.lock_outline_rounded,
                'Production talabi',
                'Haqiqiy tizim server sessiyasi, ota-ona roziligi va RBAC talab qiladi.',
              ),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Sf.primarySoft,
                  foregroundColor: Sf.primary,
                  child: Icon(item.$1),
                ),
                title: Text(
                  item.$2,
                  style: Sf.t(size: 13.5, weight: FontWeight.w700),
                ),
                subtitle: Text(
                  item.$3,
                  style: Sf.t(size: 11.5, color: Sf.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetDemo(BuildContext context, AppState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Demo holatini tiklash'),
        content: const Text(
          'Shaxsiy vazifalar, yuklab olingan fayllar, eslatmalar va seans sozlamalari boshlang‘ich holatga qaytadi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Sf.danger),
            child: const Text('Tiklash'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      state.resetDemoSession();
      if (context.mounted) {
        sfToast(context, 'Demo holati tiklandi', tone: Sf.success);
      }
    }
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value, last;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.last,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Sf.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Sf.t(size: 13)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Sf.primary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════ PARENT (Ota-ona) screens ═══════════════════════

// ─────────────────────────── PARENT HOME (Bosh sahifa) ───────────────────────────
class ParentHomeScreen extends StatelessWidget {
  final NavCb onNav;
  const ParentHomeScreen({super.key, required this.onNav});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: 'Shanba · 25 Iyul',
          title: greetingTitle('Dilnoza'),
          sub: 'Farzandingiz · Akmal bugun maktabda',
          right: SoftButton(
            'Ustozga yozish',
            icon: Icons.chat_bubble_rounded,
            primary: true,
            onTap: () => onNav('messages'),
          ),
        ),
        const SfGrid(
          minTile: 150,
          children: [
            KpiCard(
              label: 'Davomat',
              value: '96%',
              valueColor: Sf.success,
              icon: Icons.check_rounded,
            ),
            KpiCard(
              label: 'Up kartalar',
              value: '↑12',
              valueColor: Sf.goldUp,
              icon: Icons.star_rounded,
            ),
            KpiCard(label: 'Down', value: '↓1', valueColor: Sf.danger),
            KpiCard(
              label: 'Keyingi to‘lov',
              value: '30 Iyul',
              valueColor: Sf.warn,
              icon: Icons.trending_up_rounded,
            ),
          ],
        ),
        const SizedBox(height: 18),
        SfTwoCol(
          left: SfCol([
            _Hero(
              onNav: onNav,
              eyebrow: 'FARZANDINGIZ · HOZIR',
              colors: const [Sf.primary, Color(0xFF8B3E23)],
              btn1Label: 'To‘liq jadval',
              btn1Target: 'schedule',
              btn2Label: 'Davomat tarixi',
              btn2Target: 'attendance',
            ),
            _RecentCards(onNav: onNav, title: 'Akmalning so‘nggi kartalari'),
          ]),
          right: SfCol([
            _PaymentCard(onNav: onNav),
            _MessagePreviewCard(onNav: onNav),
            const _TodayScheduleCard(),
          ]),
        ),
      ],
    );
  }
}

/// "Ustozdan xabar" preview (parent home right column).
class _MessagePreviewCard extends StatelessWidget {
  final NavCb onNav;
  const _MessagePreviewCard({required this.onNav});
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Ustozdan xabar',
      child: InkWell(
        onTap: () => onNav('messages'),
        child: Row(
          children: [
            const Avatar('Nigora Karimova', size: 36),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nigora Karimova',
                    style: Sf.t(size: 12.5, weight: FontWeight.w700),
                  ),
                  Text(
                    '"Akmal bugun a\'lo ishladi!"',
                    style: Sf.t(size: 11.5, color: Sf.muted),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Sf.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '2',
                style: Sf.t(
                  size: 11,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final NavCb onNav;
  const _PaymentCard({required this.onNav});
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onNav('payments'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Sf.warn, Color(0xFF885A15)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 7,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'KEYINGI TO‘LOV',
                    style: Sf.t(
                      size: 11,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x4D000000),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '5 kun qoldi',
                      style: Sf.t(
                        size: 11,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                state.hideAmounts ? '••• ••• so‘m' : money(600000),
                style: Sf.monoStyle(
                  size: 26,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Avgust oyi · 9-B Algebra · 30.07 gacha',
                style: Sf.t(
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 14),
              Builder(
                builder: (ctx) => Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    onTap: () => onNav('payments'),
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      alignment: Alignment.center,
                      child: Text(
                        'To‘lovlarni ochish',
                        style: Sf.t(
                          size: 14,
                          weight: FontWeight.w800,
                          color: Sf.warn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── FARZANDIM (child) ───────────────────────────
class ChildScreen extends StatelessWidget {
  final NavCb onNav;
  const ChildScreen({super.key, required this.onNav});
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final studentName = state.profileNames['student'] ?? 'Akbarov Akmal';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: 'Farzandim',
          title: Text(studentName),
          sub: '9-B · 14 yosh · o‘quvchi profili',
          right: Builder(
            builder: (ctx) => SoftButton(
              'Ustozga',
              icon: Icons.chat_bubble_rounded,
              primary: true,
              onTap: () => onNav('messages'),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Sf.surface,
            border: Border.all(color: Sf.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Avatar(studentName, size: 72, color: Sf.primary),
                SizedBox(
                  width: constraints.maxWidth < 420
                      ? constraints.maxWidth
                      : constraints.maxWidth - 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: Sf.t(size: 20, weight: FontWeight.w800),
                      ),
                      Text(
                        '9-B Algebra · Nigora Karimova',
                        style: Sf.t(size: 12.5, color: Sf.muted),
                      ),
                      const SizedBox(height: 8),
                      const Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Pill('96% davomat', tone: Tone.success),
                          Pill('#2 sinfda', tone: Tone.accent),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const SfGrid(
          minTile: 150,
          children: [
            KpiCard(label: 'Davomat', value: '96%', valueColor: Sf.success),
            KpiCard(label: 'Up karta', value: '↑12', valueColor: Sf.goldUp),
            KpiCard(label: 'Down', value: '↓1', valueColor: Sf.danger),
            KpiCard(label: 'Guruh', value: '3'),
          ],
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Ustozning izohi',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '“Akmal — sinfning eng kuchli o‘quvchilaridan. Kvadrat tenglamalarni tez o‘zlashtirdi. Olimpiadaga tayyorlamoqchiman.”',
              style: Sf.serif(size: 16, color: Sf.ink, height: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Yaqin reja',
          child: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Sf.warnSoft,
                    foregroundColor: Sf.warn,
                    child: Icon(Icons.assignment_late_rounded),
                  ),
                  title: Text(
                    '2 ta faol vazifa',
                    style: Sf.t(size: 13.5, weight: FontWeight.w700),
                  ),
                  subtitle: const Text('Eng yaqin muddat: bugun 20:00'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => onNav('homework'),
                ),
              ),
              const Divider(color: Sf.border),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Sf.successSoft,
                    foregroundColor: Sf.success,
                    child: Icon(Icons.insights_rounded),
                  ),
                  title: Text(
                    'Haftalik natija +6%',
                    style: Sf.t(size: 13.5, weight: FontWeight.w700),
                  ),
                  subtitle: const Text('Algebra bo‘yicha eng yaxshi o‘sish'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => onNav('progress'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── TO‘LOVLAR (payments) ───────────────────────────
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  String _method = 'Click';
  String _filter = 'Barchasi';
  bool _processing = false;

  static const _history = [
    _PaymentEntry('Iyul', 'Click', true, '7 Iyul', 'SF-240701'),
    _PaymentEntry('Iyun', 'Payme', true, '4 Iyun', 'SF-240604'),
    _PaymentEntry('May', 'Naqd', true, '6 May', 'SF-240506'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final entries =
        [
          if (state.paymentCompleted)
            _PaymentEntry(
              'Avgust',
              state.paymentMethod ?? _method,
              true,
              'Bugun',
              state.receiptNumber ?? 'SF-DEMO',
            )
          else
            const _PaymentEntry('Avgust', '—', false, '30 Iyul', '—'),
          ..._history,
        ].where((entry) {
          if (_filter == 'To‘langan') return entry.paid;
          if (_filter == 'Kutilmoqda') return !entry.paid;
          return true;
        }).toList();
    final amount = state.hideAmounts ? '••• ••• so‘m' : money(600000);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: 'Akmal · 9-B Algebra',
          title: const Text('To‘lovlar'),
          sub: state.paymentCompleted
              ? 'Avgust oyi to‘lovi qabul qilindi'
              : 'To‘lov tarixi va keyingi to‘lov',
          right: SoftButton(
            state.paymentCompleted ? 'Kvitansiya' : 'To‘lash',
            icon: state.paymentCompleted
                ? Icons.receipt_long_rounded
                : Icons.lock_rounded,
            primary: true,
            onTap: () => state.paymentCompleted
                ? _showReceipt(context, state)
                : _confirmPayment(context, state),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Sf.surface,
            border: Border.all(color: Sf.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (ctx, c) {
              final info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.paymentCompleted
                        ? 'TO‘LOV QABUL QILINDI · AVGUST'
                        : 'KEYINGI TO‘LOV · AVGUST',
                    style: Sf.eyebrow(
                      color: state.paymentCompleted ? Sf.success : Sf.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    amount,
                    style: Sf.monoStyle(
                      size: 30,
                      weight: FontWeight.w700,
                      color: state.paymentCompleted ? Sf.success : Sf.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    state.paymentCompleted
                        ? '${state.receiptNumber} · Bugun'
                        : '30.07.2026 gacha · 5 kun qoldi',
                    style: Sf.t(size: 12, color: Sf.muted),
                  ),
                ],
              );
              final methods = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in const ['Click', 'Payme', 'Uzcard'])
                    _PayMethod(
                      m,
                      selected: _method == m,
                      enabled: !state.paymentCompleted && !_processing,
                      onTap: () => setState(() => _method = m),
                    ),
                ],
              );
              if (c.maxWidth >= 520) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 16),
                    methods,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [info, const SizedBox(height: 16), methods],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (!state.paymentCompleted) ...[
          FilledButton.icon(
            onPressed: _processing
                ? null
                : () => _confirmPayment(context, state),
            icon: _processing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.verified_user_rounded),
            label: Text(
              _processing
                  ? 'Tekshirilmoqda...'
                  : '$_method orqali $amount to‘lash',
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Sf.successSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Sf.success.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Sf.success, size: 30),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'To‘lov ikki marta yechilmaydi. Yangi to‘lov keyingi hisob davrida ochiladi.',
                    style: Sf.t(
                      size: 12,
                      weight: FontWeight.w700,
                      color: Sf.success,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showReceipt(context, state),
                  child: const Text('Ko‘rish'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SectionCard(
          title: 'To‘lov tarixi · ${entries.length}',
          action: PopupMenuButton<String>(
            tooltip: 'Tarixni filtrlash',
            initialValue: _filter,
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (_) => [
              for (final value in const ['Barchasi', 'To‘langan', 'Kutilmoqda'])
                PopupMenuItem(value: value, child: Text(value)),
            ],
            child: Pill(_filter, tone: Tone.neutral),
          ),
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++)
                InkWell(
                  onTap: entries[i].paid
                      ? () => _showHistoryReceipt(context, entries[i], state)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      border: i < entries.length - 1
                          ? const Border(bottom: BorderSide(color: Sf.border))
                          : null,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text(
                            entries[i].month,
                            style: Sf.t(size: 13, weight: FontWeight.w700),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  amount,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Sf.monoStyle(
                                    size: 12.5,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  entries[i].method,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Sf.t(size: 11, color: Sf.muted),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entries[i].date,
                          style: Sf.monoStyle(
                            size: 11,
                            weight: FontWeight.w400,
                            color: Sf.muted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Pill(
                          entries[i].paid ? 'To‘langan' : 'Kutilmoqda',
                          tone: entries[i].paid ? Tone.success : Tone.warn,
                          dot: true,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmPayment(BuildContext context, AppState state) async {
    if (_processing || state.paymentCompleted) {
      if (state.paymentCompleted) {
        _showReceipt(context, state);
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('To‘lovni tasdiqlash'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PaymentSummaryRow(label: 'O‘quvchi', value: 'Akbarov Akmal'),
              const _PaymentSummaryRow(label: 'Davr', value: 'Avgust 2026'),
              _PaymentSummaryRow(label: 'Usul', value: _method),
              _PaymentSummaryRow(
                label: 'Summa',
                value: state.hideAmounts ? 'Yashirilgan' : money(600000),
                strong: true,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Sf.warnSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Demo: haqiqiy mablag‘ yechilmaydi. Production versiyada summa serverda qayta tekshirilishi va payment callback idempotent bo‘lishi shart.',
                  style: Sf.t(
                    size: 11,
                    color: Sf.warn,
                    weight: FontWeight.w700,
                  ),
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
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.lock_rounded),
            label: const Text('Tasdiqlash'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || !context.mounted) return;
    state.completePayment(_method);
    setState(() => _processing = false);
    sfToast(
      context,
      'Demo to‘lov muvaffaqiyatli',
      sub: state.receiptNumber,
      tone: Sf.success,
    );
  }

  Future<void> _showReceipt(BuildContext context, AppState state) {
    return _receiptDialog(
      context,
      number: state.receiptNumber ?? 'SF-DEMO',
      method: state.paymentMethod ?? _method,
      hidden: state.hideAmounts,
    );
  }

  Future<void> _showHistoryReceipt(
    BuildContext context,
    _PaymentEntry entry,
    AppState state,
  ) {
    return _receiptDialog(
      context,
      number: entry.receipt,
      method: entry.method,
      hidden: state.hideAmounts,
    );
  }

  Future<void> _receiptDialog(
    BuildContext context, {
    required String number,
    required String method,
    required bool hidden,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Sf.success),
            SizedBox(width: 9),
            Text('Kvitansiya'),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hidden ? '••• ••• so‘m' : money(600000),
                style: Sf.monoStyle(
                  size: 28,
                  weight: FontWeight.w700,
                  color: Sf.success,
                ),
              ),
              const SizedBox(height: 14),
              _PaymentSummaryRow(label: 'Tranzaksiya', value: number),
              _PaymentSummaryRow(label: 'Usul', value: method),
              const _PaymentSummaryRow(
                label: 'Holat',
                value: 'To‘langan',
                strong: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Yopish'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text:
                      'StarForge EDU kvitansiya\n$number\n${hidden ? "Summa yashirilgan" : money(600000)}\n$method',
                ),
              );
              if (context.mounted) {
                sfToast(context, 'Kvitansiya nusxalandi', tone: Sf.success);
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Nusxalash'),
          ),
        ],
      ),
    );
  }
}

class _PayMethod extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  const _PayMethod(
    this.label, {
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Sf.surface,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: selected ? Sf.primarySoft : null,
            border: Border.all(
              color: selected ? Sf.primary : Sf.borderStrong,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  size: 17,
                  color: Sf.primary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Sf.t(
                  size: 13,
                  weight: FontWeight.w700,
                  color: enabled ? Sf.ink : Sf.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentEntry {
  final String month;
  final String method;
  final bool paid;
  final String date;
  final String receipt;

  const _PaymentEntry(
    this.month,
    this.method,
    this.paid,
    this.date,
    this.receipt,
  );
}

class _PaymentSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _PaymentSummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Sf.t(size: 12, color: Sf.muted)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Sf.t(
                size: 12.5,
                weight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
