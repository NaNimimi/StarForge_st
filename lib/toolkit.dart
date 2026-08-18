import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'theme.dart';

enum ToolkitActionKind { toggle, input, picker, counter, action }

enum ToolkitAudience { all, student, parent }

class ToolkitFeature {
  final String id;
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final ToolkitActionKind kind;
  final ToolkitAudience audience;
  final List<String> options;
  final String inputLabel;

  const ToolkitFeature({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.kind,
    this.audience = ToolkitAudience.all,
    this.options = const [],
    this.inputLabel = 'Qiymat',
  });
}

abstract final class ToolkitFeatureCatalog {
  static const categories = [
    'Barchasi',
    'Rejalash',
    'O‘rganish',
    'Tartib',
    'Salomatlik',
    'Oila',
  ];

  static const features = <ToolkitFeature>[
    ToolkitFeature(
      id: 'quick_note',
      title: 'Tezkor qayd',
      description: 'Muhim fikrni bir zumda saqlash',
      category: 'Rejalash',
      icon: Icons.note_add_outlined,
      kind: ToolkitActionKind.input,
      inputLabel: 'Qayd matni',
    ),
    ToolkitFeature(
      id: 'daily_priority',
      title: 'Kun ustuvorligi',
      description: 'Bugungi eng muhim ishni belgilash',
      category: 'Rejalash',
      icon: Icons.flag_outlined,
      kind: ToolkitActionKind.input,
      inputLabel: 'Eng muhim ish',
    ),
    ToolkitFeature(
      id: 'weekly_plan',
      title: 'Haftalik reja uslubi',
      description: 'Hafta yuklamasini moslashtirish',
      category: 'Rejalash',
      icon: Icons.view_week_outlined,
      kind: ToolkitActionKind.picker,
      options: ['Yengil', 'Muvozanatli', 'Faol'],
    ),
    ToolkitFeature(
      id: 'focus_length',
      title: 'Fokus davomiyligi',
      description: 'Bir o‘qish blokining vaqtini tanlash',
      category: 'Rejalash',
      icon: Icons.timer_outlined,
      kind: ToolkitActionKind.picker,
      options: ['15 daqiqa', '25 daqiqa', '40 daqiqa', '60 daqiqa'],
    ),
    ToolkitFeature(
      id: 'exam_countdown',
      title: 'Imtihon sanog‘i',
      description: 'Yaqin imtihon nomi va sanasini yozish',
      category: 'Rejalash',
      icon: Icons.event_busy_outlined,
      kind: ToolkitActionKind.input,
      inputLabel: 'Masalan: Algebra · 12 Avgust',
    ),
    ToolkitFeature(
      id: 'homework_estimate',
      title: 'Vazifa vaqt bahosi',
      description: 'Kunlik vazifalar uchun vaqt zaxirasi',
      category: 'Rejalash',
      icon: Icons.hourglass_bottom_rounded,
      kind: ToolkitActionKind.picker,
      options: ['30 daqiqa', '60 daqiqa', '90 daqiqa', '120 daqiqa'],
    ),
    ToolkitFeature(
      id: 'break_schedule',
      title: 'Tanaffus eslatmalari',
      description: 'Fokus bloklari orasida dam olish',
      category: 'Rejalash',
      icon: Icons.free_breakfast_outlined,
      kind: ToolkitActionKind.toggle,
    ),
    ToolkitFeature(
      id: 'auto_sort',
      title: 'Vazifalarni avtomatik saralash',
      description: 'Eng yaqin muddatni tepaga chiqarish',
      category: 'Rejalash',
      icon: Icons.sort_rounded,
      kind: ToolkitActionKind.toggle,
    ),
    ToolkitFeature(
      id: 'deadline_alerts',
      title: 'Muddat ogohlantirishlari',
      description: 'Muhim vazifa muddati yaqinlashganda ko‘rsatish',
      category: 'Rejalash',
      icon: Icons.notification_important_outlined,
      kind: ToolkitActionKind.toggle,
    ),
    ToolkitFeature(
      id: 'flashcard',
      title: 'Yangi kartochka',
      description: 'Savol va javobni tezkor kartaga saqlash',
      category: 'O‘rganish',
      icon: Icons.style_outlined,
      kind: ToolkitActionKind.input,
      inputLabel: 'Savol — javob',
    ),
    ToolkitFeature(
      id: 'reading_log',
      title: 'O‘qish jurnali',
      description: 'Kitob va o‘qilgan sahifalarni yozish',
      category: 'O‘rganish',
      icon: Icons.auto_stories_outlined,
      kind: ToolkitActionKind.input,
      inputLabel: 'Kitob · sahifalar',
    ),
    ToolkitFeature(
      id: 'formula_note',
      title: 'Formula daftari',
      description: 'Muhim formulani alohida saqlash',
      category: 'O‘rganish',
      icon: Icons.functions_rounded,
      kind: ToolkitActionKind.input,
      inputLabel: 'Formula va izoh',
    ),
    ToolkitFeature(
      id: 'mistake_note',
      title: 'Xatolar jurnali',
      description: 'Qayta takrorlamaslik uchun xatoni yozish',
      category: 'O‘rganish',
      icon: Icons.rule_folder_outlined,
      kind: ToolkitActionKind.input,
      inputLabel: 'Xato va to‘g‘ri yechim',
    ),
    ToolkitFeature(
      id: 'vocabulary',
      title: 'Lug‘atga so‘z qo‘shish',
      description: 'Yangi so‘z va tarjimasini saqlash',
      category: 'O‘rganish',
      icon: Icons.translate_rounded,
      kind: ToolkitActionKind.input,
      inputLabel: 'So‘z — tarjima',
    ),
    ToolkitFeature(
      id: 'quiz_mode',
      title: 'Mini-test rejimi',
      description: 'Materiallardan qisqa savollar tayyorlash',
      category: 'O‘rganish',
      icon: Icons.quiz_outlined,
      kind: ToolkitActionKind.toggle,
    ),
    ToolkitFeature(
      id: 'practice_streak',
      title: 'Mashq seriyasi',
      description: 'Har tugallangan mashqni hisoblash',
      category: 'O‘rganish',
      icon: Icons.local_fire_department_outlined,
      kind: ToolkitActionKind.counter,
    ),
    ToolkitFeature(
      id: 'focus_score',
      title: 'Fokus bahosi',
      description: 'Bugungi diqqat sifatini qayd etish',
      category: 'O‘rganish',
      icon: Icons.center_focus_strong_outlined,
      kind: ToolkitActionKind.picker,
      options: ['1/5', '2/5', '3/5', '4/5', '5/5'],
    ),
    ToolkitFeature(
      id: 'favorite_subject',
      title: 'Asosiy fan',
      description: 'Hozirgi rivojlanish yo‘nalishini tanlash',
      category: 'O‘rganish',
      icon: Icons.school_outlined,
      kind: ToolkitActionKind.picker,
      options: ['Algebra', 'Geometriya', 'Ingliz tili', 'Biologiya'],
    ),
    ToolkitFeature(
      id: 'quiet_hours',
      title: 'Tinch vaqt',
      description: 'Chalg‘ituvchi bildirishnomalar oralig‘i',
      category: 'Tartib',
      icon: Icons.do_not_disturb_on_outlined,
      kind: ToolkitActionKind.picker,
      options: ['20:00–07:00', '21:00–07:00', '22:00–08:00'],
    ),
    ToolkitFeature(
      id: 'calendar_color',
      title: 'Taqvim rangi',
      description: 'Shaxsiy voqealarni ajratib ko‘rsatish',
      category: 'Tartib',
      icon: Icons.palette_outlined,
      kind: ToolkitActionKind.picker,
      options: ['Yashil', 'Ko‘k', 'Binafsha', 'To‘q sariq'],
    ),
    ToolkitFeature(
      id: 'grade_alerts',
      title: 'Yangi baho signali',
      description: 'Yangi natijani bosh sahifada ko‘rsatish',
      category: 'Tartib',
      icon: Icons.grade_outlined,
      kind: ToolkitActionKind.toggle,
    ),
    ToolkitFeature(
      id: 'attendance_alerts',
      title: 'Davomat signali',
      description: 'Kechikish yoki yo‘qlikni ajratish',
      category: 'Tartib',
      icon: Icons.fact_check_outlined,
      kind: ToolkitActionKind.toggle,
    ),
    ToolkitFeature(
      id: 'wifi_download',
      title: 'Faqat Wi-Fi orqali yuklash',
      description: 'Mobil internet sarfini cheklash',
      category: 'Tartib',
      icon: Icons.wifi_rounded,
      kind: ToolkitActionKind.toggle,
    ),
    ToolkitFeature(
      id: 'offline_mode',
      title: 'Offline materiallar',
      description: 'Saqlangan materiallarni tez ko‘rsatish',
      category: 'Tartib',
      icon: Icons.offline_pin_outlined,
      kind: ToolkitActionKind.toggle,
    ),
    ToolkitFeature(
      id: 'compact_agenda',
      title: 'Ixcham kun rejasi',
      description: 'Bosh sahifada ko‘proq band ko‘rsatish',
      category: 'Tartib',
      icon: Icons.view_agenda_outlined,
      kind: ToolkitActionKind.toggle,
    ),
    ToolkitFeature(
      id: 'backup_snapshot',
      title: 'Lokal zaxira nusxa',
      description: 'Joriy asboblar holatidan snapshot yaratish',
      category: 'Tartib',
      icon: Icons.backup_outlined,
      kind: ToolkitActionKind.action,
    ),
    ToolkitFeature(
      id: 'export_summary',
      title: 'Svodkani nusxalash',
      description: 'Sozlangan asboblar ro‘yxatini clipboardga olish',
      category: 'Tartib',
      icon: Icons.copy_all_outlined,
      kind: ToolkitActionKind.action,
    ),
    ToolkitFeature(
      id: 'mood',
      title: 'Kayfiyat qaydi',
      description: 'Bugungi holatni bir so‘z bilan belgilash',
      category: 'Salomatlik',
      icon: Icons.mood_outlined,
      kind: ToolkitActionKind.picker,
      options: ['A’lo', 'Yaxshi', 'Tinch', 'Charchagan', 'Qiyin'],
    ),
    ToolkitFeature(
      id: 'water',
      title: 'Suv hisoblagichi',
      description: 'Ichilgan har bir stakanni qo‘shish',
      category: 'Salomatlik',
      icon: Icons.water_drop_outlined,
      kind: ToolkitActionKind.counter,
    ),
    ToolkitFeature(
      id: 'stretch',
      title: 'Cho‘zilish eslatmasi',
      description: 'Uzoq o‘qishdan keyin yengil harakat',
      category: 'Salomatlik',
      icon: Icons.accessibility_new_rounded,
      kind: ToolkitActionKind.toggle,
    ),
    ToolkitFeature(
      id: 'screen_break',
      title: 'Ekrandan tanaffus',
      description: 'Ko‘zlarni dam oldirish eslatmasi',
      category: 'Salomatlik',
      icon: Icons.remove_red_eye_outlined,
      kind: ToolkitActionKind.toggle,
    ),
    ToolkitFeature(
      id: 'sleep_goal',
      title: 'Uyqu maqsadi',
      description: 'Tungi dam olish davomiyligini tanlash',
      category: 'Salomatlik',
      icon: Icons.bedtime_outlined,
      kind: ToolkitActionKind.picker,
      options: ['7 soat', '8 soat', '9 soat', '10 soat'],
    ),
    ToolkitFeature(
      id: 'breathing',
      title: 'Nafas mashqi',
      description: 'Bajarilgan bir daqiqalik mashqlar soni',
      category: 'Salomatlik',
      icon: Icons.air_rounded,
      kind: ToolkitActionKind.counter,
    ),
    ToolkitFeature(
      id: 'walk',
      title: 'Faol tanaffus',
      description: 'Bajarilgan qisqa yurishlarni hisoblash',
      category: 'Salomatlik',
      icon: Icons.directions_walk_rounded,
      kind: ToolkitActionKind.counter,
    ),
    ToolkitFeature(
      id: 'gratitude',
      title: 'Minnatdorlik qaydi',
      description: 'Bugungi yaxshi voqeani saqlash',
      category: 'Salomatlik',
      icon: Icons.favorite_border_rounded,
      kind: ToolkitActionKind.input,
      inputLabel: 'Bugungi yaxshi voqea',
    ),
    ToolkitFeature(
      id: 'daily_energy',
      title: 'Energiya darajasi',
      description: 'Kunlik quvvatni kuzatib borish',
      category: 'Salomatlik',
      icon: Icons.battery_charging_full_rounded,
      kind: ToolkitActionKind.picker,
      options: ['Past', 'O‘rtacha', 'Yaxshi', 'Juda yaxshi'],
    ),
    ToolkitFeature(
      id: 'parent_digest',
      title: 'Ota-ona haftalik svodkasi',
      description: 'Asosiy o‘zgarishlarni bitta blokda jamlash',
      category: 'Oila',
      icon: Icons.summarize_outlined,
      kind: ToolkitActionKind.toggle,
      audience: ToolkitAudience.parent,
    ),
    ToolkitFeature(
      id: 'praise_note',
      title: 'Maqtov qaydi',
      description: 'Farzandga aytiladigan ijobiy fikrni saqlash',
      category: 'Oila',
      icon: Icons.volunteer_activism_outlined,
      kind: ToolkitActionKind.input,
      audience: ToolkitAudience.parent,
      inputLabel: 'Maqtov matni',
    ),
    ToolkitFeature(
      id: 'home_agreement',
      title: 'Uy o‘qish kelishuvi',
      description: 'Oilaviy o‘qish qoidasini belgilash',
      category: 'Oila',
      icon: Icons.handshake_outlined,
      kind: ToolkitActionKind.input,
      audience: ToolkitAudience.parent,
      inputLabel: 'Kelishuv',
    ),
    ToolkitFeature(
      id: 'pocket_budget',
      title: 'Haftalik o‘quv budjeti',
      description: 'Kitob va materiallar limitini yozish',
      category: 'Oila',
      icon: Icons.savings_outlined,
      kind: ToolkitActionKind.input,
      audience: ToolkitAudience.parent,
      inputLabel: 'Masalan: 80 000 so‘m',
    ),
    ToolkitFeature(
      id: 'self_reward',
      title: 'Shaxsiy mukofot',
      description: 'Maqsad bajarilganda kichik mukofot belgilash',
      category: 'Oila',
      icon: Icons.redeem_outlined,
      kind: ToolkitActionKind.input,
      audience: ToolkitAudience.student,
      inputLabel: 'Mukofot',
    ),
    ToolkitFeature(
      id: 'study_buddy',
      title: 'O‘qish hamkori',
      description: 'Birga tayyorlanadigan sinfdoshni belgilash',
      category: 'Oila',
      icon: Icons.group_outlined,
      kind: ToolkitActionKind.input,
      audience: ToolkitAudience.student,
      inputLabel: 'Ism',
    ),
    ToolkitFeature(
      id: 'confidence',
      title: 'Darsga ishonch',
      description: 'Bugungi tayyorgarlik holatini baholash',
      category: 'Oila',
      icon: Icons.psychology_alt_outlined,
      kind: ToolkitActionKind.picker,
      audience: ToolkitAudience.student,
      options: ['Yordam kerak', 'Tayyorlanyapman', 'Tayyorman'],
    ),
    ToolkitFeature(
      id: 'question_parking',
      title: 'Keyingi savolim',
      description: 'Ustozga beriladigan savolni unutmaslik',
      category: 'Oila',
      icon: Icons.contact_support_outlined,
      kind: ToolkitActionKind.input,
      audience: ToolkitAudience.student,
      inputLabel: 'Savol',
    ),
  ];

  static List<ToolkitFeature> forRole({required bool isParent}) {
    return features
        .where(
          (feature) =>
              feature.audience == ToolkitAudience.all ||
              (isParent && feature.audience == ToolkitAudience.parent) ||
              (!isParent && feature.audience == ToolkitAudience.student),
        )
        .toList(growable: false);
  }
}

class ToolkitPage extends StatefulWidget {
  final bool isParent;
  final void Function(String, {String? detail}) announce;

  const ToolkitPage({
    super.key,
    required this.isParent,
    required this.announce,
  });

  @override
  State<ToolkitPage> createState() => _ToolkitPageState();
}

class _ToolkitPageState extends State<ToolkitPage> {
  final _searchController = TextEditingController();
  String _category = 'Barchasi';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final all = ToolkitFeatureCatalog.forRole(isParent: widget.isParent);
    final query = _searchController.text.trim().toLowerCase();
    final visible = all.where((feature) {
      final categoryMatches =
          _category == 'Barchasi' || feature.category == _category;
      final queryMatches =
          query.isEmpty ||
          '${feature.title} ${feature.description} ${feature.category}'
              .toLowerCase()
              .contains(query);
      return categoryMatches && queryMatches;
    }).toList();
    final configured =
        state.toolkitToggles.values.where((value) => value).length +
        state.toolkitValues.length +
        state.toolkitCounters.values.where((value) => value > 0).length +
        state.toolkitActivity
            .where(
              (activity) =>
                  activity.featureId == 'backup_snapshot' ||
                  activity.featureId == 'export_summary',
            )
            .map((activity) => activity.featureId)
            .toSet()
            .length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Orqaga',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Aqlli asboblar'),
        actions: [
          IconButton(
            key: const ValueKey('toolkit-history'),
            tooltip: 'Faollik tarixi',
            onPressed: () => _showHistory(context, state),
            icon: Badge(
              isLabelVisible: state.toolkitActivity.isNotEmpty,
              label: Text('${state.toolkitActivity.length}'),
              child: const Icon(Icons.history_rounded),
            ),
          ),
          IconButton(
            key: const ValueKey('toolkit-reset'),
            tooltip: 'Asboblarni tozalash',
            onPressed: configured == 0
                ? null
                : () => _confirmReset(context, state),
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ToolkitSummary(
                      total: all.length,
                      configured: configured,
                      actions: state.toolkitActivity.length,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      key: const ValueKey('toolkit-search'),
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Asboblarni izlash',
                        hintText: 'Masalan: fokus, qayd yoki suv',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final category
                              in ToolkitFeatureCatalog.categories) ...[
                            ChoiceChip(
                              label: Text(category),
                              selected: _category == category,
                              onSelected: (_) =>
                                  setState(() => _category = category),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '${visible.length} ta asbob',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (visible.isEmpty)
                      const _ToolkitEmpty()
                    else
                      _ToolkitGroup(
                        children: [
                          for (final feature in visible)
                            _ToolkitRow(
                              feature: feature,
                              state: state,
                              onTap: () =>
                                  _activateFeature(context, state, feature),
                              onToggle: feature.kind == ToolkitActionKind.toggle
                                  ? (value) => _toggle(state, feature, value)
                                  : null,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activateFeature(
    BuildContext context,
    AppState state,
    ToolkitFeature feature,
  ) async {
    switch (feature.kind) {
      case ToolkitActionKind.toggle:
        _toggle(state, feature, !(state.toolkitToggles[feature.id] ?? false));
      case ToolkitActionKind.input:
        final value = await _showInput(context, state, feature);
        if (value == null || !mounted) return;
        state.setToolkitValue(feature.id, feature.title, value);
        widget.announce('${feature.title} saqlandi', detail: value);
      case ToolkitActionKind.picker:
        final value = await _showPicker(context, feature);
        if (value == null || !mounted) return;
        state.setToolkitValue(feature.id, feature.title, value);
        widget.announce('${feature.title}: $value');
      case ToolkitActionKind.counter:
        state.incrementToolkitCounter(feature.id, feature.title);
        widget.announce(
          '${feature.title}: ${state.toolkitCounters[feature.id]}',
        );
      case ToolkitActionKind.action:
        await _performAction(context, state, feature);
    }
  }

  void _toggle(AppState state, ToolkitFeature feature, bool value) {
    state.setToolkitToggle(feature.id, feature.title, value);
    widget.announce('${feature.title} ${value ? 'yoqildi' : 'o‘chirildi'}');
  }

  Future<String?> _showInput(
    BuildContext context,
    AppState state,
    ToolkitFeature feature,
  ) {
    final controller = TextEditingController(
      text: state.toolkitValues[feature.id],
    );
    final formKey = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(feature.title),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: TextFormField(
              key: ValueKey('toolkit-input-${feature.id}'),
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: feature.inputLabel,
                helperText: feature.description,
              ),
              validator: (value) => (value?.trim().length ?? 0) < 2
                  ? 'Kamida 2 ta belgi kiriting'
                  : null,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            key: ValueKey('toolkit-save-${feature.id}'),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, controller.text.trim());
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showPicker(BuildContext context, ToolkitFeature feature) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                feature.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(feature.description),
              const SizedBox(height: 16),
              for (final option in feature.options)
                ListTile(
                  key: ValueKey('toolkit-option-${feature.id}-$option'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const Icon(Icons.radio_button_unchecked_rounded),
                  title: Text(option),
                  onTap: () => Navigator.pop(sheetContext, option),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performAction(
    BuildContext context,
    AppState state,
    ToolkitFeature feature,
  ) async {
    if (feature.id == 'backup_snapshot') {
      final now = TimeOfDay.now();
      final result =
          '${state.toolkitValues.length + state.toolkitToggles.length + state.toolkitCounters.length} sozlama · ${now.format(context)}';
      state.recordToolkitAction(feature.id, feature.title, result);
      if (!mounted) return;
      await _showActionResult(
        state,
        title: 'Lokal snapshot tayyor',
        message:
            '$result\n\nSnapshot joriy seansning asbob holatini qayd etdi. '
            'Natija satrda va faollik tarixida saqlanadi.',
        showHistory: true,
      );
      return;
    }
    if (feature.id == 'export_summary') {
      final lines = <String>[
        'Starforge Family · Aqlli asboblar',
        for (final entry in state.toolkitToggles.entries)
          '${entry.key}: ${entry.value ? 'yoqilgan' : 'o‘chirilgan'}',
        for (final entry in state.toolkitValues.entries)
          '${entry.key}: ${entry.value}',
        for (final entry in state.toolkitCounters.entries)
          '${entry.key}: ${entry.value}',
      ];
      final result = '${lines.length - 1} band nusxalandi';
      state.recordToolkitAction(feature.id, feature.title, result);
      unawaited(
        Clipboard.setData(ClipboardData(text: lines.join('\n'))).catchError((
          Object _,
        ) {
          // The persistent in-app summary remains available when the platform
          // clipboard is temporarily unavailable.
        }),
      );
      await _showActionResult(
        state,
        title: 'Svodka nusxalandi',
        message:
            '${lines.length - 1} ta sozlangan band clipboardga nusxalandi.\n\n'
            'Natija satrda va faollik tarixida saqlanadi.',
        showHistory: true,
      );
    }
  }

  Future<void> _showActionResult(
    AppState state, {
    required String title,
    required String message,
    required bool showHistory,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (showHistory)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                Future<void>.delayed(Duration.zero, () {
                  if (mounted) _showHistory(context, state);
                });
              },
              icon: const Icon(Icons.history_rounded),
              label: const Text('Tarixni ochish'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  Future<void> _showHistory(BuildContext context, AppState state) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => ListenableBuilder(
        listenable: state,
        builder: (context, _) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Text(
                    'Faollik tarixi',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: state.toolkitActivity.isEmpty
                      ? const _ToolkitEmpty(
                          title: 'Tarix hali bo‘sh',
                          message:
                              'Asbobdan foydalanganda natija shu yerda qoladi.',
                        )
                      : ListView.separated(
                          itemCount: state.toolkitActivity.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = state.toolkitActivity[index];
                            return ListTile(
                              leading: const Icon(Icons.check_circle_outline),
                              title: Text(item.title),
                              subtitle: Text(item.value),
                              trailing: Text(
                                '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, AppState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Asboblarni tozalash'),
        content: const Text(
          'Barcha asbob sozlamalari, qiymatlar va faollik tarixi tozalanadi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            key: const ValueKey('toolkit-reset-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Tozalash'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      state.clearToolkitWorkspace();
    }
  }
}

class _ToolkitSummary extends StatelessWidget {
  final int total;
  final int configured;
  final int actions;

  const _ToolkitSummary({
    required this.total,
    required this.configured,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(Sf.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$total ta ishlaydigan imkoniyat',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Har bir amal ko‘rinadigan natija beradi va joriy seansda saqlanadi.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colors.onPrimaryContainer),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill('$configured sozlangan'),
              _SummaryPill('$actions amal'),
              const _SummaryPill('Lokal va xavfsiz'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String text;

  const _SummaryPill(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.onPrimaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ToolkitGroup extends StatelessWidget {
  final List<Widget> children;

  const _ToolkitGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sf.radiusLarge),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Divider(height: 1, indent: 62, color: colors.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _ToolkitRow extends StatelessWidget {
  final ToolkitFeature feature;
  final AppState state;
  final VoidCallback onTap;
  final ValueChanged<bool>? onToggle;

  const _ToolkitRow({
    required this.feature,
    required this.state,
    required this.onTap,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = state.toolkitToggles[feature.id] ?? false;
    final value = state.toolkitValues[feature.id];
    final count = state.toolkitCounters[feature.id] ?? 0;
    ToolkitActivity? latestAction;
    if (feature.kind == ToolkitActionKind.action) {
      for (final activity in state.toolkitActivity) {
        if (activity.featureId == feature.id) {
          latestAction = activity;
          break;
        }
      }
    }
    final configured =
        enabled || value != null || count > 0 || latestAction != null;
    return Semantics(
      button: true,
      label: feature.title,
      child: InkWell(
        key: ValueKey('toolkit-${feature.id}'),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: configured
                        ? colors.primaryContainer
                        : colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    feature.icon,
                    size: 21,
                    color: configured
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        feature.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feature.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (feature.kind == ToolkitActionKind.toggle)
                  Switch(
                    key: ValueKey('toolkit-switch-${feature.id}'),
                    value: enabled,
                    onChanged: onToggle,
                  )
                else if (feature.kind == ToolkitActionKind.counter)
                  _ToolkitStatus(count == 0 ? 'Qo‘shish' : '$count')
                else if (value != null)
                  Flexible(child: _ToolkitStatus(value))
                else if (latestAction != null)
                  Flexible(child: _ToolkitStatus(latestAction.value))
                else
                  const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolkitStatus extends StatelessWidget {
  final String text;

  const _ToolkitStatus(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ToolkitEmpty extends StatelessWidget {
  final String title;
  final String message;

  const _ToolkitEmpty({
    this.title = 'Mos asbob topilmadi',
    this.message = 'Izlash yoki kategoriyani o‘zgartiring.',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
