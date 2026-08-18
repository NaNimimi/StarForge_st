part of 'portal_app.dart';

String _identityText(BuildContext context, String uz, String ru, String en) =>
    switch (PortalScope.of(context).preferences.language) {
      PortalLanguage.uz => uz,
      PortalLanguage.ru => ru,
      PortalLanguage.en => en,
    };

class _IdentityPortalPage extends StatelessWidget {
  const _IdentityPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    return portal.isStudent
        ? _ModernStudentProfilePage(portal: portal)
        : _ModernParentProfilePage(portal: portal);
  }
}

class _ModernStudentProfilePage extends StatelessWidget {
  const _ModernStudentProfilePage({required this.portal});

  final PortalController portal;

  @override
  Widget build(BuildContext context) {
    String t(String uz, String ru, String en) =>
        _identityText(context, uz, ru, en);
    final profile = portal.studentProfile;
    if (profile.isEmpty) {
      return _PortalPage(
        title: t('Mening profilim', 'Мой профиль', 'My profile'),
        subtitle: t(
          'Shaxsiy va o‘quv ma’lumotlaringiz.',
          'Ваши личные и учебные данные.',
          'Your personal and learning information.',
        ),
        section: PortalSection.identity,
        children: [
          _EmptyState(
            icon: Icons.person_search_outlined,
            title: t(
              'Profil ma’lumotlari topilmadi',
              'Данные профиля не найдены',
              'Profile information is unavailable',
            ),
            message: t(
              'Ma’lumotlar markaz tomonidan qo‘shilgach, ular shu yerda ko‘rinadi.',
              'Информация появится здесь после добавления учебным центром.',
              'Your information will appear here after the learning center adds it.',
            ),
          ),
        ],
      );
    }
    return _PortalPage(
      title: t('Mening profilim', 'Мой профиль', 'My profile'),
      subtitle: t(
        'Kerakli shaxsiy va o‘quv ma’lumotlari — ortiqcha bloklarsiz.',
        'Нужные личные и учебные данные — без лишних блоков.',
        'The personal and learning details you need, without clutter.',
      ),
      section: PortalSection.identity,
      children: [
        _ModernProfileHeader(
          name: valueText(profile, const [
            'full_name',
          ], fallback: portal.displayName),
          role: t('O‘quvchi', 'Ученик', 'Student'),
          detail: valueText(
            profile,
            const ['current_cohort_name', 'academic_level'],
            fallback: t(
              'Guruh hali biriktirilmagan',
              'Группа ещё не назначена',
              'No group assigned yet',
            ),
          ),
          status: _identityStatusLabel(context, '${profile['status'] ?? ''}'),
          blocked: profile['is_blocked'] == true,
        ),
        const SizedBox(height: 16),
        _ModernProfileSectionHeader(
          title: t(
            'Shaxsiy ma’lumotlar',
            'Личные данные',
            'Personal information',
          ),
          onEdit: () => _openProfileEditor(context, portal),
        ),
        const SizedBox(height: 9),
        _ModernProfileDetails(
          fields: [
            _IdentityField(
              Icons.phone_iphone_rounded,
              t('Telefon', 'Телефон', 'Phone'),
              valueText(profile, const ['phone'], fallback: ''),
            ),
            _IdentityField(
              Icons.alternate_email_rounded,
              t('Email', 'Email', 'Email'),
              valueText(profile, const ['email'], fallback: ''),
            ),
            _IdentityField(
              Icons.cake_outlined,
              t('Tug‘ilgan sana', 'Дата рождения', 'Date of birth'),
              _dateLabel(profile['birthdate']),
            ),
            _IdentityField(
              Icons.location_on_outlined,
              t('Hudud', 'Регион', 'Region'),
              valueText(profile, const ['location'], fallback: ''),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ModernProfileSectionHeader(title: t('Ta’lim', 'Обучение', 'Learning')),
        const SizedBox(height: 9),
        _ModernProfileDetails(
          fields: [
            _IdentityField(
              Icons.tag_rounded,
              t('O‘quvchi ID', 'ID ученика', 'Student ID'),
              valueText(profile, const ['student_id'], fallback: ''),
            ),
            _IdentityField(
              Icons.groups_2_outlined,
              t('Guruh', 'Группа', 'Group'),
              valueText(
                profile,
                const ['current_cohort_name'],
                fallback: _referenceLabel(context, profile['current_cohort']),
              ),
            ),
            _IdentityField(
              Icons.auto_graph_rounded,
              t('Daraja', 'Уровень', 'Level'),
              valueText(profile, const ['academic_level'], fallback: ''),
            ),
            _IdentityField(
              Icons.event_available_outlined,
              t('Qabul sanasi', 'Дата зачисления', 'Enrollment date'),
              _dateLabel(profile['enrollment_date']),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ModernProfileNavigation(
          icon: Icons.history_rounded,
          title: t('O‘qish tarixi', 'История обучения', 'Learning history'),
          subtitle: t(
            'Status o‘zgarishlari va markaz izohlari',
            'Изменения статуса и комментарии центра',
            'Status changes and center notes',
          ),
          onTap: () => _openProfileHistory(context, portal),
        ),
        const SizedBox(height: 9),
        _ModernProfileNavigation(
          icon: Icons.tune_rounded,
          title: t(
            'Sozlamalar va maxfiylik',
            'Настройки и конфиденциальность',
            'Settings and privacy',
          ),
          subtitle: t(
            'Til, xavfsizlik, qurilmalar va akkaunt',
            'Язык, безопасность, устройства и аккаунт',
            'Language, security, devices, and account',
          ),
          onTap: () =>
              _PortalNavigationScope.go(context, PortalSection.account),
        ),
      ],
    );
  }
}

class _ModernParentProfilePage extends StatelessWidget {
  const _ModernParentProfilePage({required this.portal});

  final PortalController portal;

  @override
  Widget build(BuildContext context) {
    String t(String uz, String ru, String en) =>
        _identityText(context, uz, ru, en);
    final parent = portal.parentProfile;
    final child = portal.studentProfile;
    final selectedId = portal.selectedStudentId;
    final guardians = _forSelectedChild(portal.guardians, selectedId);
    final pickups = _forSelectedChild(
      portal.pickups,
      selectedId,
    ).where((row) => row['is_active'] != false).toList();
    return _PortalPage(
      title: t('Oila profili', 'Профиль семьи', 'Family profile'),
      subtitle: t(
        'Siz va tanlangan farzand uchun kerakli ma’lumotlar.',
        'Нужная информация о вас и выбранном ребёнке.',
        'Essential information for you and your selected child.',
      ),
      section: PortalSection.identity,
      children: [
        if (parent.isEmpty)
          _EmptyState(
            icon: Icons.family_restroom_outlined,
            title: t(
              'Ota-ona profili topilmadi',
              'Профиль родителя не найден',
              'Parent profile is unavailable',
            ),
            message: t(
              'Markaz ma’lumotlarni tasdiqlagach oila profili shu yerda ko‘rinadi.',
              'Семейный профиль появится после подтверждения данных центром.',
              'The family profile will appear after the center verifies the data.',
            ),
          )
        else
          _ModernProfileHeader(
            name: valueText(parent, const [
              'full_name',
            ], fallback: portal.displayName),
            role: t('Ota-ona', 'Родитель', 'Parent'),
            detail: valueText(
              parent,
              const ['phone', 'email'],
              fallback: t(
                'Aloqa kiritilmagan',
                'Контакт не указан',
                'No contact provided',
              ),
            ),
            status: t('Oila akkaunti', 'Семейный аккаунт', 'Family account'),
          ),
        if (portal.children.length > 1) ...[
          const SizedBox(height: 14),
          _ChildSwitcher(
            children: portal.children,
            selectedId: selectedId,
            onSelected: portal.selectChild,
          ),
        ],
        const SizedBox(height: 18),
        _ModernProfileSectionHeader(
          title: t('Tanlangan farzand', 'Выбранный ребёнок', 'Selected child'),
        ),
        const SizedBox(height: 9),
        if (child.isEmpty)
          _EmptyState(
            icon: Icons.person_search_outlined,
            title: t(
              'Farzand profili topilmadi',
              'Профиль ребёнка не найден',
              'Child profile is unavailable',
            ),
            message: t(
              'Markaz bog‘lanishni tasdiqlagach, farzand ma’lumotlari shu yerda ko‘rinadi.',
              'Данные появятся после подтверждения связи учебным центром.',
              'Information will appear after the learning center confirms the link.',
            ),
          )
        else
          _ModernProfileDetails(
            fields: [
              _IdentityField(
                Icons.person_outline_rounded,
                t('Ism', 'Имя', 'Name'),
                valueText(
                  child,
                  const ['full_name'],
                  fallback:
                      '${valueText(child, const ['first_name'], fallback: '')} ${valueText(child, const ['last_name'], fallback: '')}'
                          .trim(),
                ),
              ),
              _IdentityField(
                Icons.tag_rounded,
                t('O‘quvchi ID', 'ID ученика', 'Student ID'),
                valueText(child, const ['student_id'], fallback: ''),
              ),
              _IdentityField(
                Icons.groups_2_outlined,
                t('Guruh', 'Группа', 'Group'),
                valueText(child, const [
                  'current_cohort_name',
                ], fallback: _referenceLabel(context, child['current_cohort'])),
              ),
              _IdentityField(
                Icons.auto_graph_rounded,
                t('Daraja', 'Уровень', 'Level'),
                valueText(child, const ['academic_level'], fallback: ''),
              ),
            ],
          ),
        const SizedBox(height: 18),
        _ModernProfileSectionHeader(
          title: t('Mening ma’lumotlarim', 'Мои данные', 'My information'),
          onEdit: parent.isEmpty
              ? null
              : () => _openProfileEditor(context, portal),
        ),
        const SizedBox(height: 9),
        _ModernProfileDetails(
          fields: [
            _IdentityField(
              Icons.phone_iphone_rounded,
              t('Telefon', 'Телефон', 'Phone'),
              valueText(parent, const ['phone'], fallback: ''),
            ),
            _IdentityField(
              Icons.alternate_email_rounded,
              t('Email', 'Email', 'Email'),
              valueText(parent, const ['email'], fallback: ''),
            ),
            _IdentityField(
              Icons.work_outline_rounded,
              t('Ish joyi', 'Место работы', 'Workplace'),
              valueText(parent, const ['workplace'], fallback: ''),
            ),
            _IdentityField(
              Icons.badge_outlined,
              t('Hujjat', 'Документ', 'Document'),
              valueText(parent, const [
                'document_number',
                'passport_number',
              ], fallback: ''),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ModernProfileSectionHeader(
          title: t(
            'Vakillar va olib ketish',
            'Представители и получение',
            'Guardians and pickup',
          ),
        ),
        const SizedBox(height: 9),
        if (guardians.isEmpty && pickups.isEmpty)
          _EmptyState(
            icon: Icons.verified_user_outlined,
            title: t(
              'Vakillar kiritilmagan',
              'Представители не указаны',
              'No guardians added',
            ),
            message: t(
              'Rasmiy vakil yoki olib ketish ruxsati markaz tomonidan qo‘shilganda shu yerda ko‘rinadi.',
              'Официальные представители и разрешения появятся здесь после добавления центром.',
              'Official guardians and pickup permissions will appear here after the center adds them.',
            ),
          )
        else
          _SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final guardian in guardians)
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: Text(
                      valueText(
                        guardian,
                        const ['parent_name', 'full_name'],
                        fallback: t(
                          'Rasmiy vakil',
                          'Официальный представитель',
                          'Official guardian',
                        ),
                      ),
                    ),
                    subtitle: Text(
                      valueText(
                        guardian,
                        const ['relationship', 'relation'],
                        fallback: t(
                          'Qarindoshlik ko‘rsatilmagan',
                          'Родство не указано',
                          'Relationship not provided',
                        ),
                      ),
                    ),
                  ),
                for (final pickup in pickups)
                  ListTile(
                    leading: const Icon(Icons.directions_walk_rounded),
                    title: Text(
                      valueText(
                        pickup,
                        const ['full_name', 'name'],
                        fallback: t(
                          'Olib ketish ruxsati',
                          'Разрешение на получение',
                          'Pickup permission',
                        ),
                      ),
                    ),
                    subtitle: Text(
                      valueText(
                        pickup,
                        const ['phone', 'relationship'],
                        fallback: t(
                          'Faol ruxsat',
                          'Активное разрешение',
                          'Active permission',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 18),
        _ModernProfileNavigation(
          icon: Icons.history_rounded,
          title: t('Farzand tarixi', 'История ребёнка', 'Child history'),
          subtitle: t(
            'Status va o‘quv yo‘li',
            'Статус и учебный путь',
            'Status and learning journey',
          ),
          onTap: () => _openProfileHistory(context, portal),
        ),
        const SizedBox(height: 9),
        _ModernProfileNavigation(
          icon: Icons.tune_rounded,
          title: t(
            'Sozlamalar va maxfiylik',
            'Настройки и конфиденциальность',
            'Settings and privacy',
          ),
          subtitle: t(
            'Til, xavfsizlik, qurilmalar va akkaunt',
            'Язык, безопасность, устройства и аккаунт',
            'Language, security, devices, and account',
          ),
          onTap: () =>
              _PortalNavigationScope.go(context, PortalSection.account),
        ),
      ],
    );
  }
}

class _ModernProfileHeader extends StatelessWidget {
  const _ModernProfileHeader({
    required this.name,
    required this.role,
    required this.detail,
    required this.status,
    this.blocked = false,
  });

  final String name;
  final String role;
  final String detail;
  final String status;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            blocked ? Icons.lock_outline_rounded : Icons.verified_rounded,
            color: blocked ? colors.errorContainer : Colors.white,
          ),
        ],
      ),
    );
  }
}

class _ModernProfileSectionHeader extends StatelessWidget {
  const _ModernProfileSectionHeader({required this.title, this.onEdit});

  final String title;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      if (onEdit != null)
        TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 17),
          label: Text(_identityText(context, 'Tahrirlash', 'Изменить', 'Edit')),
        ),
    ],
  );
}

class _ModernProfileDetails extends StatelessWidget {
  const _ModernProfileDetails({required this.fields});

  final List<_IdentityField> fields;

  @override
  Widget build(BuildContext context) => _SectionCard(
    padding: EdgeInsets.zero,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 2 : 1;
        return Wrap(
          children: [
            for (final field in fields)
              SizedBox(
                width: constraints.maxWidth / columns,
                child: ListTile(
                  leading: Icon(
                    field.icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    field.label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  subtitle: Text(
                    _filled(field.value)
                        ? field.value
                        : _identityText(
                            context,
                            'Kiritilmagan',
                            'Не указано',
                            'Not provided',
                          ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _ModernProfileNavigation extends StatelessWidget {
  const _ModernProfileNavigation({
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
  Widget build(BuildContext context) => _SectionCard(
    padding: EdgeInsets.zero,
    child: ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

void _openProfileEditor(BuildContext context, PortalController portal) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          PortalScope(controller: portal, child: const _ProfileEditScreen()),
    ),
  );
}

void _openProfileHistory(BuildContext context, PortalController portal) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          PortalScope(controller: portal, child: const _ProfileHistoryScreen()),
    ),
  );
}

class _ProfileHistoryScreen extends StatelessWidget {
  const _ProfileHistoryScreen();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    final events = portal.studentEvents;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _identityText(
            context,
            'O‘qish tarixi',
            'История обучения',
            'Learning history',
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: events.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: _EmptyState(
                      icon: Icons.history_toggle_off_rounded,
                      title: _identityText(
                        context,
                        'Tarix hali bo‘sh',
                        'История пока пуста',
                        'History is empty',
                      ),
                      message: _identityText(
                        context,
                        'Status o‘zgarganda sana va markaz izohi shu sahifada ko‘rinadi.',
                        'После изменения статуса здесь появятся дата и комментарий центра.',
                        'Status changes, dates, and center notes will appear on this page.',
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _SectionCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.route_rounded),
                          title: Text(
                            valueText(
                              event,
                              const ['title', 'status', 'event_type'],
                              fallback: _identityText(
                                context,
                                'Status yangilandi',
                                'Статус обновлён',
                                'Status updated',
                              ),
                            ),
                          ),
                          subtitle: Text(
                            '${_dateLabel(event['created_at'] ?? event['occurred_at'], time: true)}\n${valueText(event, const ['note', 'comment', 'reason'], fallback: _identityText(context, 'Markaz izohi kiritilmagan.', 'Комментарий центра не указан.', 'No center note was provided.'))}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

// Retained for legacy visual fixtures while the connected portal uses the
// streamlined profile above.
// ignore: unused_element
class _StudentIdentityPage extends StatelessWidget {
  const _StudentIdentityPage({required this.portal});

  final PortalController portal;

  @override
  Widget build(BuildContext context) {
    String t(String uz, String ru, String en) =>
        _identityText(context, uz, ru, en);
    final profile = portal.studentProfile;
    final stats = portal.studentStats;
    final profileProgress = _studentProfileCompleteness(profile);
    final total = valueInt(stats['total']) ?? 0;
    final statusStats = _mapEntries(context, stats['by_status']);
    final branchStats = _mapEntries(context, stats['by_branch']);
    final activeReasons = portal.enrollmentReasons
        .where((item) => item['is_active'] != false)
        .toList();
    final birthdays = portal.birthdays;
    final studentBlue = Theme.of(context).colorScheme.primary;
    final studentCyan = Theme.of(context).colorScheme.secondary;

    if (profile.isEmpty) {
      return _PortalPage(
        title: t('Mening profilim', 'Мой профиль', 'My profile'),
        subtitle: t(
          'Shaxsiy o‘quv pasportingiz va markazdagi yo‘lingiz.',
          'Ваш личный учебный паспорт и путь в центре.',
          'Your personal learning passport and journey at the center.',
        ),
        section: PortalSection.identity,
        children: [
          _IdentityEmptyPanel(
            icon: Icons.badge_outlined,
            title: t(
              'Profil ma’lumotlari yuklanmadi',
              'Данные профиля не загружены',
              'Profile data was not loaded',
            ),
            message: t(
              'O‘quvchi profili serverda mavjud bo‘lgach, shaxsiy va akademik ma’lumotlar shu yerda ko‘rinadi.',
              'Личные и учебные данные появятся здесь, когда профиль ученика будет доступен на сервере.',
              'Personal and academic information will appear here when the student profile is available on the server.',
            ),
            accent: studentBlue,
          ),
        ],
      );
    }

    return _PortalPage(
      title: t('Mening profilim', 'Мой профиль', 'My profile'),
      subtitle: t(
        'Shaxsiy o‘quv pasportingiz, guruh holati va markazdagi yo‘lingiz.',
        'Ваш учебный паспорт, статус группы и путь в центре.',
        'Your learning passport, group status, and journey at the center.',
      ),
      section: PortalSection.identity,
      trailing: _ProfileEditAction(portal: portal),
      children: [
        _StudentPassportHero(
          profile: profile,
          fallbackName: portal.displayName,
          completeness: profileProgress,
        ),
        const SizedBox(height: 18),
        _IdentityMetricGrid(
          items: [
            _IdentityMetric(
              icon: Icons.data_usage_rounded,
              label: t(
                'Profil tayyorligi',
                'Готовность профиля',
                'Profile readiness',
              ),
              value: '${(profileProgress * 100).round()}%',
              detail: t(
                'Asosiy ma’lumotlar to‘liqligi',
                'Заполненность основных данных',
                'Core information completeness',
              ),
              accent: studentBlue,
              progress: profileProgress,
              onTap: () => _showJsonDetail(
                context,
                title: t(
                  'Profil to‘liqligi',
                  'Заполненность профиля',
                  'Profile completeness',
                ),
                fields: {
                  t('To‘ldirilgan', 'Заполнено', 'Completed'):
                      '${(profileProgress * 100).round()}%',
                  t('Telefon', 'Телефон', 'Phone'): _availability(
                    context,
                    profile['phone'],
                  ),
                  t('Email', 'Email', 'Email'): _availability(
                    context,
                    profile['email'],
                  ),
                  t('Manzil', 'Адрес', 'Address'): _availability(
                    context,
                    profile['location'],
                  ),
                  t('Guruh', 'Группа', 'Group'): _availability(
                    context,
                    profile['current_cohort'],
                  ),
                },
              ),
            ),
            _IdentityMetric(
              icon: Icons.hub_outlined,
              label: t('Guruh holati', 'Статус группы', 'Group status'),
              value: profile['current_cohort'] == null
                  ? t('Kutilmoqda', 'Ожидается', 'Pending')
                  : t('Ulangan', 'Подключена', 'Connected'),
              detail: profile['current_cohort'] == null
                  ? t(
                      'Joriy guruh biriktirilmagan',
                      'Текущая группа не назначена',
                      'No current group assigned',
                    )
                  : t(
                      'Markaz tizimida guruh biriktirilgan',
                      'Группа назначена в системе центра',
                      'A group is assigned in the center system',
                    ),
              accent: studentCyan,
              progress: profile['current_cohort'] == null ? 0 : 1,
            ),
            _IdentityMetric(
              icon: Icons.school_outlined,
              label: t('O‘qish statusi', 'Статус обучения', 'Learning status'),
              value: _identityStatusLabel(
                context,
                '${profile['status'] ?? ''}',
              ),
              detail: _filled(profile['enrollment_date'])
                  ? t(
                      '${_dateLabel(profile['enrollment_date'])} dan boshlab',
                      'С ${_dateLabel(profile['enrollment_date'])}',
                      'Since ${_dateLabel(profile['enrollment_date'])}',
                    )
                  : t(
                      'Qabul sanasi hali ko‘rsatilmagan',
                      'Дата зачисления ещё не указана',
                      'Enrollment date is not specified yet',
                    ),
              accent: studentCyan,
            ),
            _IdentityMetric(
              icon: profile['is_blocked'] == true
                  ? Icons.lock_rounded
                  : Icons.verified_user_rounded,
              label: t(
                'Akkaunt xavfsizligi',
                'Безопасность аккаунта',
                'Account security',
              ),
              value: profile['is_blocked'] == true
                  ? t('Cheklangan', 'Ограничен', 'Restricted')
                  : t('Himoyalangan', 'Защищён', 'Protected'),
              detail: profile['is_blocked'] == true
                  ? valueText(profile, const ['block_reason'])
                  : t(
                      'Kirish va o‘qish xizmatlari faol',
                      'Доступ и учебные сервисы активны',
                      'Access and learning services are active',
                    ),
              accent: profile['is_blocked'] == true
                  ? Theme.of(context).colorScheme.error
                  : Sf.success,
              progress: profile['is_blocked'] == true ? 0 : 1,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _IdentitySectionHeading(
          icon: Icons.badge_outlined,
          overline: t('O‘QUVCHI DOSYESI', 'ДОСЬЕ УЧЕНИКА', 'STUDENT FILE'),
          title: t(
            'Shaxsiy va akademik ma’lumotlar',
            'Личные и учебные данные',
            'Personal and academic information',
          ),
          description: t(
            'Markaz tizimida tasdiqlangan identifikatsiya va ta’lim maydonlari.',
            'Подтверждённые поля личных и учебных данных в системе центра.',
            'Verified identity and education fields in the center system.',
          ),
        ),
        const SizedBox(height: 12),
        _IdentityInformationPanel(
          accent: studentBlue,
          groups: [
            _IdentityInfoGroup(
              title: t(
                'Aloqa va shaxsiy ma’lumotlar',
                'Контакты и личные данные',
                'Contact and personal information',
              ),
              icon: Icons.person_outline_rounded,
              fields: [
                _IdentityField(
                  Icons.person_outline_rounded,
                  t('Ism', 'Имя', 'First name'),
                  valueText(profile, const ['first_name']),
                ),
                _IdentityField(
                  Icons.person_outline_rounded,
                  t('Familiya', 'Фамилия', 'Last name'),
                  valueText(profile, const ['last_name']),
                ),
                _IdentityField(
                  Icons.person_outline_rounded,
                  t('Otasining ismi', 'Отчество', 'Middle name'),
                  valueText(profile, const ['middle_name']),
                ),
                _IdentityField(
                  Icons.phone_iphone_rounded,
                  t('Telefon', 'Телефон', 'Phone'),
                  valueText(profile, const ['phone']),
                ),
                _IdentityField(
                  Icons.alternate_email_rounded,
                  t('Email', 'Email', 'Email'),
                  valueText(profile, const ['email']),
                ),
                _IdentityField(
                  Icons.cake_outlined,
                  t('Tug‘ilgan sana', 'Дата рождения', 'Date of birth'),
                  _dateLabel(profile['birthdate']),
                ),
                _IdentityField(
                  Icons.wc_outlined,
                  t('Jins', 'Пол', 'Gender'),
                  _genderLabel(context, '${profile['gender'] ?? ''}'),
                ),
                _IdentityField(
                  Icons.location_on_outlined,
                  t('Hudud', 'Регион', 'Region'),
                  valueText(profile, const ['location']),
                ),
                _IdentityField(
                  Icons.login_rounded,
                  t('Oxirgi kirish', 'Последний вход', 'Last sign-in'),
                  _dateLabel(profile['last_login_at'], time: true),
                ),
              ],
            ),
            _IdentityInfoGroup(
              title: t(
                'Ta’lim profili',
                'Учебный профиль',
                'Education profile',
              ),
              icon: Icons.school_outlined,
              fields: [
                _IdentityField(
                  Icons.tag_rounded,
                  t('O‘quvchi ID', 'ID ученика', 'Student ID'),
                  valueText(profile, const ['student_id']),
                ),
                _IdentityField(
                  Icons.auto_graph_rounded,
                  t(
                    'Akademik daraja',
                    'Академический уровень',
                    'Academic level',
                  ),
                  valueText(profile, const ['academic_level']),
                ),
                _IdentityField(
                  Icons.groups_2_outlined,
                  t('Guruh holati', 'Статус группы', 'Group status'),
                  valueText(
                    profile,
                    const ['current_cohort_name'],
                    fallback: _referenceLabel(
                      context,
                      profile['current_cohort'],
                    ),
                  ),
                ),
                _IdentityField(
                  Icons.apartment_rounded,
                  t('Filial holati', 'Статус филиала', 'Branch status'),
                  valueText(profile, const [
                    'branch_name',
                  ], fallback: _referenceLabel(context, profile['branch'])),
                ),
                _IdentityField(
                  Icons.co_present_outlined,
                  t(
                    'Asosiy ustoz',
                    'Основной преподаватель',
                    'Primary teacher',
                  ),
                  valueText(profile, const [
                    'primary_teacher_name',
                    'teacher_name',
                  ]),
                ),
                _IdentityField(
                  Icons.event_available_outlined,
                  t('Qabul sanasi', 'Дата зачисления', 'Enrollment date'),
                  _dateLabel(profile['enrollment_date']),
                ),
                _IdentityField(
                  Icons.account_balance_outlined,
                  t('Oldingi maktab', 'Предыдущая школа', 'Previous school'),
                  valueText(profile, const ['previous_school']),
                ),
              ],
            ),
            _IdentityInfoGroup(
              title: t(
                'Akkaunt va tizim holati',
                'Аккаунт и статус системы',
                'Account and system status',
              ),
              icon: Icons.admin_panel_settings_outlined,
              fields: [
                _IdentityField(
                  Icons.alternate_email_rounded,
                  t('Login', 'Логин', 'Username'),
                  valueText(profile, const ['username']),
                ),
                _IdentityField(
                  Icons.power_settings_new_rounded,
                  t('Akkaunt holati', 'Статус аккаунта', 'Account status'),
                  _activeAccountLabel(context, profile['is_active']),
                ),
                _IdentityField(
                  Icons.password_rounded,
                  t('Parol holati', 'Статус пароля', 'Password status'),
                  _passwordStateLabel(context, profile['must_change_password']),
                ),
                _IdentityField(
                  Icons.lock_clock_outlined,
                  t('Bloklangan sana', 'Дата блокировки', 'Blocked at'),
                  _dateLabel(profile['blocked_at'], time: true),
                ),
                _IdentityField(
                  Icons.event_outlined,
                  t('Profil yaratilgan', 'Профиль создан', 'Profile created'),
                  _dateLabel(profile['created_at'], time: true),
                ),
                _IdentityField(
                  Icons.update_rounded,
                  t(
                    'So‘nggi yangilanish',
                    'Последнее обновление',
                    'Last updated',
                  ),
                  _dateLabel(profile['updated_at'], time: true),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        _IdentityDisclosureCard(
          key: const ValueKey('student-profile-insights'),
          icon: Icons.insights_outlined,
          title: t(
            'Profil tayyorligi va markaz ma’lumotlari',
            'Готовность профиля и данные центра',
            'Profile readiness and center data',
          ),
          description: t(
            'To‘liqlik tekshiruvi, guruh kesimi va sizga ochiq markaz ma’lumotlari.',
            'Проверка заполненности, срез по группам и доступные вам данные центра.',
            'Completeness checks, group breakdown, and center data available to you.',
          ),
          accent: studentBlue,
          count:
              1 +
              (statusStats.isNotEmpty || branchStats.isNotEmpty ? 1 : 0) +
              (activeReasons.isNotEmpty ? 1 : 0) +
              (birthdays.isNotEmpty ? 1 : 0),
          initiallyExpanded: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StudentReadinessPanel(
                profile: profile,
                completeness: profileProgress,
                accent: studentBlue,
              ),
              if (statusStats.isNotEmpty || branchStats.isNotEmpty) ...[
                const SizedBox(height: 14),
                _StudentScopeBreakdown(
                  statusEntries: statusStats,
                  branchEntries: branchStats,
                  total: total,
                ),
              ],
              if (activeReasons.isNotEmpty) ...[
                const SizedBox(height: 14),
                _EnrollmentReasonCloud(reasons: activeReasons),
              ],
              if (birthdays.isNotEmpty) ...[
                const SizedBox(height: 14),
                _BirthdayStrip(rows: birthdays),
              ],
            ],
          ),
        ),
        if (_hasEmergencyContacts(profile)) ...[
          const SizedBox(height: 20),
          _IdentitySectionHeading(
            icon: Icons.emergency_outlined,
            overline: t('MUHIM ALOQA', 'ВАЖНЫЙ КОНТАКТ', 'IMPORTANT CONTACT'),
            title: t(
              'Favqulodda bog‘lanish',
              'Экстренная связь',
              'Emergency contact',
            ),
            description: t(
              'Markazga taqdim etilgan tezkor aloqa ma’lumotlari.',
              'Данные для экстренной связи, переданные центру.',
              'Emergency contact information provided to the center.',
            ),
          ),
          const SizedBox(height: 12),
          _EmergencyContactPanel(
            rawContacts: profile['emergency_contacts'],
            accent: Theme.of(context).colorScheme.error,
          ),
        ],
        const SizedBox(height: 20),
        _IdentitySectionHeading(
          icon: Icons.route_rounded,
          overline: t('TARIX', 'ИСТОРИЯ', 'HISTORY'),
          title: t('O‘qish yo‘li', 'Учебный путь', 'Learning journey'),
          description: t(
            'Profil statusidagi rasmiy o‘zgarishlar xronologiyasi.',
            'Хронология официальных изменений статуса профиля.',
            'Timeline of official profile status changes.',
          ),
          count: portal.studentEvents.length,
        ),
        const SizedBox(height: 12),
        if (portal.studentEvents.isEmpty)
          _IdentityEmptyPanel(
            icon: Icons.route_outlined,
            title: t(
              'Yo‘l endi boshlanmoqda',
              'Путь только начинается',
              'The journey is just beginning',
            ),
            message: t(
              'Status o‘zgarganda tarix, sana va markaz izohi shu yerda paydo bo‘ladi.',
              'При изменении статуса здесь появятся дата, история и комментарий центра.',
              'When the status changes, its date, history, and center note will appear here.',
            ),
            accent: studentBlue,
          )
        else
          _PremiumTimeline(events: portal.studentEvents, accent: studentBlue),
      ],
    );
  }
}

class _ProfileEditAction extends StatelessWidget {
  const _ProfileEditAction({required this.portal});

  final PortalController portal;

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PortalScope(controller: portal, child: const _ProfileEditScreen()),
      ),
    ),
    icon: const Icon(Icons.edit_outlined, size: 18),
    label: Text(_identityText(context, 'Tahrirlash', 'Редактировать', 'Edit')),
  );
}

// Retained for legacy visual fixtures.
// ignore: unused_element
class _ParentFamilyPage extends StatelessWidget {
  const _ParentFamilyPage({required this.portal});

  final PortalController portal;

  @override
  Widget build(BuildContext context) {
    String t(String uz, String ru, String en) =>
        _identityText(context, uz, ru, en);
    final parent = portal.parentProfile;
    final child = portal.studentProfile;
    final selectedId = portal.selectedStudentId;
    final childProgress = _studentProfileCompleteness(child);
    final parentProgress = _parentProfileCompleteness(parent);
    final visibleGuardians = _forSelectedChild(portal.guardians, selectedId);
    final visiblePickups = _forSelectedChild(portal.pickups, selectedId);
    final activePickups = visiblePickups
        .where((item) => item['is_active'] == true)
        .length;
    final familyTeal = Theme.of(context).colorScheme.primary;
    final familyWarm = Theme.of(context).colorScheme.secondary;

    return _PortalPage(
      title: t('Farzandlarim', 'Мои дети', 'My children'),
      subtitle: t(
        'Oilaviy nazorat markazi: farzand profili, rasmiy vakillar va xavfsiz olib ketish.',
        'Центр семейного контроля: профиль ребёнка, официальные представители и безопасное получение.',
        'Family control center: child profile, official guardians, and safe pickup.',
      ),
      section: PortalSection.identity,
      trailing: _HeaderCountBadge(
        icon: Icons.family_restroom_rounded,
        label: t(
          '${portal.children.length} farzand',
          '${portal.children.length} ${_russianChildrenWord(portal.children.length)}',
          '${portal.children.length} ${portal.children.length == 1 ? 'child' : 'children'}',
        ),
        accent: familyTeal,
      ),
      children: [
        if (parent.isEmpty)
          _IdentityEmptyPanel(
            icon: Icons.family_restroom_outlined,
            title: t(
              'Ota-ona profili topilmadi',
              'Профиль родителя не найден',
              'Parent profile not found',
            ),
            message: t(
              'Kabinetning shaxsiy ma’lumotlari serverdan qaytgach oila profili shu yerda ko‘rinadi.',
              'Семейный профиль появится здесь, когда сервер вернёт личные данные кабинета.',
              'The family profile will appear here when the server returns the account information.',
            ),
            accent: familyTeal,
          )
        else
          _ParentFamilyHero(
            parent: parent,
            fallbackName: portal.displayName,
            children: portal.children,
            profileCompleteness: parentProgress,
          ),
        if (portal.children.length > 1) ...[
          const SizedBox(height: 18),
          _ChildSwitcher(
            children: portal.children,
            selectedId: selectedId,
            onSelected: portal.selectChild,
          ),
        ],
        const SizedBox(height: 18),
        _IdentityMetricGrid(
          items: [
            _IdentityMetric(
              icon: Icons.child_care_rounded,
              label: t(
                'Oiladagi o‘quvchilar',
                'Ученики в семье',
                'Students in family',
              ),
              value: '${portal.children.length}',
              detail: portal.children.length == 1
                  ? t(
                      'Bitta faol o‘quvchi profili',
                      'Один активный профиль ученика',
                      'One active student profile',
                    )
                  : t(
                      'Kabinetga ulangan profillar',
                      'Профили, привязанные к кабинету',
                      'Profiles linked to this account',
                    ),
              accent: familyTeal,
            ),
            _IdentityMetric(
              icon: Icons.verified_user_outlined,
              label: t(
                'Rasmiy vakillar',
                'Официальные представители',
                'Official guardians',
              ),
              value: '${visibleGuardians.length}',
              detail: t(
                'Tanlangan farzandga bog‘langan',
                'Привязаны к выбранному ребёнку',
                'Linked to the selected child',
              ),
              accent: familyWarm,
            ),
            _IdentityMetric(
              icon: Icons.directions_walk_rounded,
              label: t(
                'Faol ruxsatnomalar',
                'Активные разрешения',
                'Active permits',
              ),
              value: '$activePickups',
              detail: visiblePickups.isEmpty
                  ? t(
                      'Ruxsatnoma hali kiritilmagan',
                      'Разрешения ещё не добавлены',
                      'No permits have been added yet',
                    )
                  : t(
                      '${visiblePickups.length} ta yozuvdan faol',
                      'Активных из ${visiblePickups.length}',
                      'Active out of ${visiblePickups.length} records',
                    ),
              accent: Sf.success,
              progress: visiblePickups.isEmpty
                  ? 0
                  : activePickups / visiblePickups.length,
            ),
            _IdentityMetric(
              icon: Icons.fact_check_outlined,
              label: t('Farzand profili', 'Профиль ребёнка', 'Child profile'),
              value: '${(childProgress * 100).round()}%',
              detail: t(
                'Ma’lumotlarning to‘liqligi',
                'Заполненность данных',
                'Information completeness',
              ),
              accent: familyWarm,
              progress: childProgress,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _IdentitySectionHeading(
          icon: Icons.face_retouching_natural_rounded,
          overline: t(
            'TANLANGAN FARZAND',
            'ВЫБРАННЫЙ РЕБЁНОК',
            'SELECTED CHILD',
          ),
          title: t(
            'O‘quvchi profili va holati',
            'Профиль и статус ученика',
            'Student profile and status',
          ),
          description: t(
            'Markaz bazasidagi joriy akademik va shaxsiy ma’lumotlar.',
            'Текущие учебные и личные данные из базы центра.',
            'Current academic and personal information in the center database.',
          ),
        ),
        const SizedBox(height: 12),
        if (child.isEmpty)
          _IdentityEmptyPanel(
            icon: Icons.person_search_outlined,
            title: t(
              'Farzand profili topilmadi',
              'Профиль ребёнка не найден',
              'Child profile not found',
            ),
            message: t(
              'Markaz rasmiy bog‘lanishni tasdiqlagach profil shu yerda ko‘rinadi.',
              'Профиль появится здесь после подтверждения официальной связи центром.',
              'The profile will appear here after the center confirms the official link.',
            ),
            accent: familyTeal,
          )
        else ...[
          _ChildSpotlightCard(child: child, completeness: childProgress),
          const SizedBox(height: 14),
          _IdentityInformationPanel(
            accent: familyWarm,
            groups: [
              _IdentityInfoGroup(
                title: t(
                  'Shaxsiy ma’lumotlar',
                  'Личные данные',
                  'Personal information',
                ),
                icon: Icons.contact_page_outlined,
                fields: [
                  _IdentityField(
                    Icons.person_outline_rounded,
                    t('Ism', 'Имя', 'First name'),
                    valueText(child, const ['first_name']),
                  ),
                  _IdentityField(
                    Icons.person_outline_rounded,
                    t('Familiya', 'Фамилия', 'Last name'),
                    valueText(child, const ['last_name']),
                  ),
                  _IdentityField(
                    Icons.person_outline_rounded,
                    t('Otasining ismi', 'Отчество', 'Middle name'),
                    valueText(child, const ['middle_name']),
                  ),
                  _IdentityField(
                    Icons.tag_rounded,
                    t('O‘quvchi ID', 'ID ученика', 'Student ID'),
                    valueText(child, const ['student_id']),
                  ),
                  _IdentityField(
                    Icons.cake_outlined,
                    t('Tug‘ilgan sana', 'Дата рождения', 'Date of birth'),
                    _dateLabel(child['birthdate']),
                  ),
                  _IdentityField(
                    Icons.phone_iphone_rounded,
                    t('Telefon', 'Телефон', 'Phone'),
                    valueText(child, const ['phone']),
                  ),
                  _IdentityField(
                    Icons.alternate_email_rounded,
                    t('Email', 'Email', 'Email'),
                    valueText(child, const ['email']),
                  ),
                  _IdentityField(
                    Icons.wc_outlined,
                    t('Jins', 'Пол', 'Gender'),
                    _genderLabel(context, '${child['gender'] ?? ''}'),
                  ),
                  _IdentityField(
                    Icons.location_on_outlined,
                    t('Hudud', 'Регион', 'Region'),
                    valueText(child, const ['location']),
                  ),
                ],
              ),
              _IdentityInfoGroup(
                title: t(
                  'Ta’lim holati',
                  'Статус обучения',
                  'Education status',
                ),
                icon: Icons.menu_book_outlined,
                fields: [
                  _IdentityField(
                    Icons.auto_graph_rounded,
                    t(
                      'Akademik daraja',
                      'Академический уровень',
                      'Academic level',
                    ),
                    valueText(child, const ['academic_level']),
                  ),
                  _IdentityField(
                    Icons.groups_2_outlined,
                    t('Guruh holati', 'Статус группы', 'Group status'),
                    valueText(
                      child,
                      const ['current_cohort_name'],
                      fallback: _referenceLabel(
                        context,
                        child['current_cohort'],
                      ),
                    ),
                  ),
                  _IdentityField(
                    Icons.apartment_rounded,
                    t('Filial holati', 'Статус филиала', 'Branch status'),
                    valueText(child, const [
                      'branch_name',
                    ], fallback: _referenceLabel(context, child['branch'])),
                  ),
                  _IdentityField(
                    Icons.co_present_outlined,
                    t(
                      'Asosiy ustoz',
                      'Основной преподаватель',
                      'Primary teacher',
                    ),
                    valueText(child, const [
                      'primary_teacher_name',
                      'teacher_name',
                    ]),
                  ),
                  _IdentityField(
                    Icons.event_available_outlined,
                    t('Qabul sanasi', 'Дата зачисления', 'Enrollment date'),
                    _dateLabel(child['enrollment_date']),
                  ),
                  _IdentityField(
                    Icons.account_balance_outlined,
                    t('Oldingi maktab', 'Предыдущая школа', 'Previous school'),
                    valueText(child, const ['previous_school']),
                  ),
                  _IdentityField(
                    Icons.shield_outlined,
                    t('Akkaunt', 'Аккаунт', 'Account'),
                    child['is_blocked'] == true
                        ? t('Cheklangan', 'Ограничен', 'Restricted')
                        : _activeAccountLabel(context, child['is_active']),
                  ),
                ],
              ),
              _IdentityInfoGroup(
                title: t(
                  'Akkaunt va xizmatlar',
                  'Аккаунт и сервисы',
                  'Account and services',
                ),
                icon: Icons.security_outlined,
                fields: [
                  _IdentityField(
                    Icons.alternate_email_rounded,
                    t('Login', 'Логин', 'Username'),
                    valueText(child, const ['username']),
                  ),
                  _IdentityField(
                    Icons.power_settings_new_rounded,
                    t('Tizim holati', 'Статус системы', 'System status'),
                    _activeAccountLabel(context, child['is_active']),
                  ),
                  _IdentityField(
                    Icons.password_rounded,
                    t('Parol holati', 'Статус пароля', 'Password status'),
                    _passwordStateLabel(context, child['must_change_password']),
                  ),
                  _IdentityField(
                    Icons.login_rounded,
                    t('Oxirgi kirish', 'Последний вход', 'Last sign-in'),
                    _dateLabel(child['last_login_at'], time: true),
                  ),
                  _IdentityField(
                    Icons.lock_clock_outlined,
                    t('Bloklangan sana', 'Дата блокировки', 'Blocked at'),
                    _dateLabel(child['blocked_at'], time: true),
                  ),
                  _IdentityField(
                    Icons.update_rounded,
                    t(
                      'So‘nggi yangilanish',
                      'Последнее обновление',
                      'Last updated',
                    ),
                    _dateLabel(child['updated_at'], time: true),
                  ),
                ],
              ),
            ],
          ),
          if (_hasEmergencyContacts(child)) ...[
            const SizedBox(height: 14),
            _EmergencyContactPanel(
              rawContacts: child['emergency_contacts'],
              accent: Theme.of(context).colorScheme.error,
            ),
          ],
        ],
        const SizedBox(height: 14),
        _IdentityDisclosureCard(
          key: const ValueKey('parent-own-profile-section'),
          icon: Icons.person_pin_outlined,
          title: t(
            'Ota-ona ma’lumotlari',
            'Данные родителя',
            'Parent information',
          ),
          description: t(
            'Markaz bilan aloqa qiluvchi tasdiqlangan kabinet egasi.',
            'Подтверждённый владелец кабинета для связи с центром.',
            'Verified account owner who communicates with the center.',
          ),
          accent: familyTeal,
          initiallyExpanded: false,
          child: parent.isEmpty
              ? _IdentityEmptyPanel(
                  icon: Icons.person_search_outlined,
                  title: t(
                    'Shaxsiy ma’lumotlar mavjud emas',
                    'Личные данные отсутствуют',
                    'Personal information is unavailable',
                  ),
                  message: t(
                    'Ota-ona kartasi ma’lumotlar tasdiqlangach avtomatik to‘ldiriladi.',
                    'Карта родителя заполнится автоматически после подтверждения данных.',
                    'The parent card will be filled automatically after the information is verified.',
                  ),
                  accent: familyTeal,
                )
              : _ParentIdentityCard(
                  parent: parent,
                  fallbackName: portal.displayName,
                  completeness: parentProgress,
                ),
        ),
        if (child.isNotEmpty) ...[
          const SizedBox(height: 14),
          _IdentityDisclosureCard(
            key: const ValueKey('parent-family-safety-section'),
            icon: Icons.health_and_safety_outlined,
            title: t(
              'Farzand bo‘yicha tezkor holat',
              'Краткий статус ребёнка',
              'Child status overview',
            ),
            description: t(
              'Akkaunt, vakillik va olib ketish ruxsatlari bitta ko‘rinishda.',
              'Аккаунт, представители и разрешения на получение в одном месте.',
              'Account, guardianship, and pickup permits in one view.',
            ),
            accent: Sf.success,
            initiallyExpanded: false,
            child: _FamilySafetyOverview(
              child: child,
              guardians: visibleGuardians,
              pickups: visiblePickups,
            ),
          ),
        ],
        const SizedBox(height: 14),
        _IdentityDisclosureCard(
          key: const ValueKey('parent-guardians-section'),
          icon: Icons.account_tree_outlined,
          title: t(
            'Vakillik va qarindoshlik',
            'Представители и родство',
            'Guardianship and relationships',
          ),
          description: t(
            'Farzand nomidan markaz bilan bog‘lanishga ruxsat berilgan shaxslar.',
            'Лица, которым разрешено связываться с центром от имени ребёнка.',
            'People authorized to contact the center on behalf of the child.',
          ),
          count: visibleGuardians.length,
          accent: familyTeal,
          initiallyExpanded: false,
          child: visibleGuardians.isEmpty
              ? _IdentityEmptyPanel(
                  icon: Icons.link_off_rounded,
                  title: t(
                    'Rasmiy bog‘lanish topilmadi',
                    'Официальная связь не найдена',
                    'No official link found',
                  ),
                  message: t(
                    'Guardian yozuvi markaz tomonidan tasdiqlangach shu bo‘limda ko‘rinadi.',
                    'Запись о представителе появится здесь после подтверждения центром.',
                    'The guardian record will appear here after center approval.',
                  ),
                  accent: familyTeal,
                )
              : _GuardianGrid(rows: visibleGuardians),
        ),
        const SizedBox(height: 14),
        _IdentityDisclosureCard(
          key: const ValueKey('parent-pickups-section'),
          icon: Icons.directions_walk_rounded,
          title: t(
            'Tasdiqlangan ruxsatnomalar',
            'Подтверждённые разрешения',
            'Approved permits',
          ),
          description: t(
            'Farzandingizni markazdan olib ketishi mumkin bo‘lgan shaxslar.',
            'Лица, которые могут забрать вашего ребёнка из центра.',
            'People authorized to pick up your child from the center.',
          ),
          count: visiblePickups.length,
          accent: familyWarm,
          initiallyExpanded: false,
          child: visiblePickups.isEmpty
              ? _IdentityEmptyPanel(
                  icon: Icons.person_pin_circle_outlined,
                  title: t(
                    'Ruxsatnomalar mavjud emas',
                    'Разрешения отсутствуют',
                    'No permits available',
                  ),
                  message: t(
                    'Ruxsat berilgan shaxslar markaz tasdig‘idan so‘ng shu yerda chiqadi.',
                    'Разрешённые лица появятся здесь после подтверждения центром.',
                    'Authorized people will appear here after center approval.',
                  ),
                  accent: familyWarm,
                )
              : _PickupPermitGrid(rows: visiblePickups),
        ),
        if (portal.studentEvents.isNotEmpty) ...[
          const SizedBox(height: 14),
          _IdentityDisclosureCard(
            key: const ValueKey('parent-student-history-section'),
            icon: Icons.history_edu_rounded,
            title: t('O‘qish yo‘li', 'Учебный путь', 'Learning journey'),
            description: t(
              'Tanlangan farzand statusining rasmiy xronologiyasi.',
              'Официальная хронология статуса выбранного ребёнка.',
              'Official status timeline for the selected child.',
            ),
            count: portal.studentEvents.length,
            accent: familyTeal,
            initiallyExpanded: false,
            child: _PremiumTimeline(
              events: portal.studentEvents,
              accent: familyTeal,
            ),
          ),
        ],
      ],
    );
  }
}

class _StudentPassportHero extends StatelessWidget {
  const _StudentPassportHero({
    required this.profile,
    required this.fallbackName,
    required this.completeness,
  });

  final Map<String, Object?> profile;
  final String fallbackName;
  final double completeness;

  @override
  Widget build(BuildContext context) {
    String t(String uz, String ru, String en) =>
        _identityText(context, uz, ru, en);
    final scheme = Theme.of(context).colorScheme;
    final name = valueText(profile, const [
      'full_name',
    ], fallback: fallbackName);
    final active =
        profile['is_active'] == true && profile['is_blocked'] == false;
    final accessLabel = profile['is_blocked'] == true
        ? t('Kirish cheklangan', 'Доступ ограничен', 'Access restricted')
        : profile['is_active'] == true
        ? t('Faol o‘quvchi', 'Активный ученик', 'Active student')
        : profile['is_active'] == false
        ? t('Akkaunt nofaol', 'Аккаунт неактивен', 'Account inactive')
        : t(
            'Akkaunt holati noma’lum',
            'Статус аккаунта неизвестен',
            'Account status unknown',
          );
    return _IdentityHeroShell(
      colors: [
        Sf.ink,
        Color.alphaBlend(scheme.primary.withValues(alpha: 0.5), Sf.ink),
        Color.alphaBlend(scheme.secondary.withValues(alpha: 0.2), Sf.ink),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _HeroAvatar(
                label: _initials(name),
                icon: Icons.school_rounded,
                accent: Colors.white,
                compact: compact,
              ),
              SizedBox(width: compact ? 12 : 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroEyebrow(
                      icon: Icons.auto_awesome_rounded,
                      text: t(
                        'STARFORGE O‘QUVCHI PASPORTI',
                        'ПАСПОРТ УЧЕНИКА STARFORGE',
                        'STARFORGE STUDENT PASS',
                      ),
                    ),
                    SizedBox(height: compact ? 5 : 9),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            height: 1.05,
                            fontSize: compact ? 21 : null,
                          ),
                    ),
                    SizedBox(height: compact ? 5 : 8),
                    Text(
                      'ID ${valueText(profile, const ['student_id'])}  •  ${valueText(profile, const ['academic_level'], fallback: t('Daraja belgilanmagan', 'Уровень не указан', 'Level not specified'))}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: compact ? 9 : 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroChip(
                          icon: active
                              ? Icons.bolt_rounded
                              : Icons.lock_rounded,
                          text: accessLabel,
                        ),
                        _HeroChip(
                          icon: Icons.groups_2_outlined,
                          text: profile['current_cohort'] == null
                              ? t(
                                  'Guruh kutilmoqda',
                                  'Ожидается группа',
                                  'Waiting for group',
                                )
                              : t(
                                  'Guruh biriktirilgan',
                                  'Группа назначена',
                                  'Group assigned',
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
          final score = _HeroScore(
            value: '${(completeness * 100).round()}%',
            label: t('profil tayyor', 'профиль готов', 'profile ready'),
            icon: Icons.verified_rounded,
            compact: compact,
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [identity, const SizedBox(height: 12), score],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 28),
              SizedBox(width: 184, child: score),
            ],
          );
        },
      ),
    );
  }
}

class _ParentFamilyHero extends StatelessWidget {
  const _ParentFamilyHero({
    required this.parent,
    required this.fallbackName,
    required this.children,
    required this.profileCompleteness,
  });

  final Map<String, Object?> parent;
  final String fallbackName;
  final List<Map<String, Object?>> children;
  final double profileCompleteness;

  @override
  Widget build(BuildContext context) {
    String t(String uz, String ru, String en) =>
        _identityText(context, uz, ru, en);
    final name = valueText(parent, const ['full_name'], fallback: fallbackName);
    final active = parent['is_active'] == true;
    final accountLabel = parent['is_active'] == true
        ? t(
            'Faol ota-ona kabineti',
            'Активный кабинет родителя',
            'Active parent account',
          )
        : parent['is_active'] == false
        ? t('Kabinet nofaol', 'Кабинет неактивен', 'Account inactive')
        : t(
            'Kabinet holati noma’lum',
            'Статус кабинета неизвестен',
            'Account status unknown',
          );
    final scheme = Theme.of(context).colorScheme;
    return _IdentityHeroShell(
      colors: [
        Sf.ink,
        Color.alphaBlend(scheme.primary.withValues(alpha: 0.48), Sf.ink),
        Color.alphaBlend(scheme.secondary.withValues(alpha: 0.16), Sf.ink),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final identity = Row(
            children: [
              _HeroAvatar(
                label: _initials(name),
                icon: Icons.family_restroom_rounded,
                accent: Sf.accentSoft,
                compact: compact,
              ),
              SizedBox(width: compact ? 12 : 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroEyebrow(
                      icon: Icons.home_rounded,
                      text: t(
                        'STARFORGE OILA MAKONI',
                        'СЕМЕЙНОЕ ПРОСТРАНСТВО STARFORGE',
                        'STARFORGE FAMILY SPACE',
                      ),
                    ),
                    SizedBox(height: compact ? 5 : 9),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            height: 1.05,
                            fontSize: compact ? 21 : null,
                          ),
                    ),
                    SizedBox(height: compact ? 5 : 8),
                    Text(
                      valueText(
                        parent,
                        const ['workplace'],
                        fallback: t(
                          'Ish joyi ko‘rsatilmagan',
                          'Место работы не указано',
                          'Workplace not specified',
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: compact ? 9 : 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroChip(
                          icon: active
                              ? Icons.verified_user_rounded
                              : Icons.person_off_outlined,
                          text: accountLabel,
                        ),
                        _HeroChip(
                          icon: Icons.child_care_rounded,
                          text: t(
                            '${children.length} farzand ulangan',
                            'Подключено: ${children.length} ${_russianChildrenWord(children.length)}',
                            '${children.length} ${children.length == 1 ? 'child' : 'children'} linked',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
          final score = _HeroScore(
            value: '${(profileCompleteness * 100).round()}%',
            label: t('oila profili', 'семейный профиль', 'family profile'),
            icon: Icons.shield_outlined,
            subtitle: valueText(parent, const ['phone']),
            compact: compact,
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [identity, const SizedBox(height: 12), score],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 28),
              SizedBox(width: 200, child: score),
            ],
          );
        },
      ),
    );
  }
}

class _IdentityHeroShell extends StatelessWidget {
  const _IdentityHeroShell({required this.colors, required this.child});

  final List<Color> colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return ClipRRect(
      borderRadius: BorderRadius.circular(mobile ? 18 : 22),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
            ),
          ),
          Positioned(
            right: -74,
            top: -96,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 34,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
          ),
          Positioned(
            left: -34,
            bottom: -64,
            child: Container(
              width: 146,
              height: 146,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.045),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.all(mobile ? 14 : 20), child: child),
        ],
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({
    required this.label,
    required this.icon,
    required this.accent,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: compact ? 52 : 68,
          height: compact ? 52 : 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.38),
              width: 2,
            ),
          ),
          child: Text(
            label.isEmpty ? 'SF' : label,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 18 : null,
            ),
          ),
        ),
        Positioned(
          right: -3,
          bottom: -3,
          child: Container(
            width: compact ? 24 : 30,
            height: compact ? 24 : 30,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, color: Sf.accentInk, size: compact ? 14 : 17),
          ),
        ),
      ],
    );
  }
}

class _HeroEyebrow extends StatelessWidget {
  const _HeroEyebrow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.86)),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              letterSpacing: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroScore extends StatelessWidget {
  const _HeroScore({
    required this.value,
    required this.label,
    required this.icon,
    this.subtitle,
    this.compact = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final String? subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 13 : 16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: compact
          ? Row(
              children: [
                Icon(icon, color: Colors.white, size: 19),
                const SizedBox(width: 10),
                Text(
                  value,
                  style: Sf.monoStyle(
                    size: 17,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.74),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 23),
                const SizedBox(height: 14),
                Text(
                  value,
                  style: Sf.monoStyle(
                    size: 21,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _IdentityMetric {
  const _IdentityMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.accent,
    this.progress,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color accent;
  final double? progress;
  final VoidCallback? onTap;
}

class _IdentityMetricGrid extends StatelessWidget {
  const _IdentityMetricGrid({required this.items});

  final List<_IdentityMetric> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          final textScale = MediaQuery.textScalerOf(
            context,
          ).scale(1).clamp(1.0, 2.0);
          return SizedBox(
            height: 128 + (textScale - 1) * 115,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => SizedBox(
                width: 148 + (textScale - 1) * 22,
                child: _IdentityMetricCard(item: items[index], dense: true),
              ),
            ),
          );
        }
        final columns = constraints.maxWidth >= 1060 ? 4 : 2;
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _IdentityMetricCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _IdentityMetricCard extends StatelessWidget {
  const _IdentityMetricCard({required this.item, this.dense = false});

  final _IdentityMetric item;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = item.progress?.clamp(0.0, 1.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: EdgeInsets.all(dense ? 10 : 13),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: dense ? 28 : 32,
                    height: dense ? 28 : 32,
                    decoration: BoxDecoration(
                      color: item.accent.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.accent,
                      size: dense ? 15 : 17,
                    ),
                  ),
                  const Spacer(),
                  if (item.onTap != null)
                    Icon(
                      Icons.arrow_outward_rounded,
                      color: colors.onSurfaceVariant,
                      size: 18,
                    ),
                ],
              ),
              SizedBox(height: dense ? 6 : 11),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Sf.monoStyle(
                  size: dense ? 17 : 19,
                  weight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              SizedBox(height: dense ? 3 : 5),
              Text(
                item.label.toUpperCase(),
                maxLines: dense ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: Sf.eyebrow(
                  color: colors.onSurfaceVariant,
                ).copyWith(fontSize: dense ? 9.5 : null),
              ),
              SizedBox(height: dense ? 2 : 4),
              Text(
                item.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              if (progress != null && !dense) ...[
                const SizedBox(height: 13),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: item.accent,
                    backgroundColor: item.accent.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentitySectionHeading extends StatelessWidget {
  const _IdentitySectionHeading({
    required this.icon,
    required this.overline,
    required this.title,
    required this.description,
    this.count,
  });

  final IconData icon;
  final String overline;
  final String title;
  final String description;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: mobile ? 36 : 46,
          height: mobile ? 36 : 46,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(mobile ? 11 : 15),
          ),
          child: Icon(
            icon,
            color: colors.onPrimaryContainer,
            size: mobile ? 19 : 24,
          ),
        ),
        SizedBox(width: mobile ? 10 : 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overline,
                maxLines: mobile ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.15,
                ),
              ),
              SizedBox(height: mobile ? 1 : 3),
              Text(
                title,
                style:
                    (mobile
                            ? Theme.of(context).textTheme.titleMedium
                            : Theme.of(context).textTheme.titleLarge)
                        ?.copyWith(fontWeight: FontWeight.w900),
              ),
              SizedBox(height: mobile ? 2 : 4),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (count != null && !mobile) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              _identityCount(context, count!),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ],
    );
  }
}

class _IdentityDisclosureCard extends StatelessWidget {
  const _IdentityDisclosureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.child,
    this.count,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final Widget child;
  final int? count;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: EdgeInsets.symmetric(
            horizontal: mobile ? 11 : 14,
            vertical: mobile ? 3 : 5,
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            mobile ? 11 : 14,
            0,
            mobile ? 11 : 14,
            mobile ? 12 : 15,
          ),
          leading: Container(
            width: mobile ? 36 : 42,
            height: mobile ? 36 : 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(mobile ? 11 : 14),
            ),
            child: Icon(icon, color: accent, size: mobile ? 19 : 22),
          ),
          title: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              count == null
                  ? description
                  : '$description · ${_identityCount(context, count!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
          children: [child],
        ),
      ),
    );
  }
}

class _IdentityField {
  const _IdentityField(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class _IdentityInfoGroup {
  const _IdentityInfoGroup({
    required this.title,
    required this.icon,
    required this.fields,
  });

  final String title;
  final IconData icon;
  final List<_IdentityField> fields;
}

class _IdentityInformationPanel extends StatelessWidget {
  const _IdentityInformationPanel({required this.accent, required this.groups});

  final Color accent;
  final List<_IdentityInfoGroup> groups;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120 && groups.length >= 3
            ? 3
            : constraints.maxWidth >= 760
            ? 2
            : 1;
        const gap = 14.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var index = 0; index < groups.length; index++)
              SizedBox(
                width: width,
                child: _IdentityInfoGroupCard(
                  key: ValueKey('identity-info-group-${groups[index].title}'),
                  group: groups[index],
                  accent: accent,
                  initiallyExpanded: columns > 1 || index == 0,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _IdentityInfoGroupCard extends StatelessWidget {
  const _IdentityInfoGroupCard({
    super.key,
    required this.group,
    required this.accent,
    required this.initiallyExpanded,
  });

  final _IdentityInfoGroup group;
  final Color accent;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>('identity-group-${group.title}'),
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          tilePadding: EdgeInsets.symmetric(
            horizontal: mobile ? 11 : 14,
            vertical: mobile ? 2 : 4,
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            mobile ? 11 : 14,
            0,
            mobile ? 11 : 14,
            mobile ? 11 : 14,
          ),
          leading: Container(
            width: mobile ? 30 : 36,
            height: mobile ? 30 : 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(group.icon, color: accent, size: mobile ? 17 : 20),
          ),
          title: Text(
            group.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            _identityText(
              context,
              '${group.fields.length} ta maydon',
              '${group.fields.length} ${_russianFieldWord(group.fields.length)}',
              '${group.fields.length} ${group.fields.length == 1 ? 'field' : 'fields'}',
            ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          children: [
            for (var index = 0; index < group.fields.length; index++) ...[
              _IdentityDataRow(field: group.fields[index], accent: accent),
              if (index != group.fields.length - 1)
                Divider(height: mobile ? 13 : 19, indent: mobile ? 27 : 35),
            ],
          ],
        ),
      ),
    );
  }
}

class _IdentityDataRow extends StatelessWidget {
  const _IdentityDataRow({required this.field, required this.accent});

  final _IdentityField field;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(field.icon, size: mobile ? 16 : 19, color: accent),
        ),
        SizedBox(width: mobile ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                field.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                field.value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudentReadinessPanel extends StatelessWidget {
  const _StudentReadinessPanel({
    required this.profile,
    required this.completeness,
    required this.accent,
  });

  final Map<String, Object?> profile;
  final double completeness;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    String t(String uz, String ru, String en) =>
        _identityText(context, uz, ru, en);
    final checks = [
      (
        t('Shaxsiy aloqa', 'Личные контакты', 'Personal contact'),
        _filled(profile['phone']) && _filled(profile['email']),
        Icons.contact_phone_outlined,
      ),
      (
        t('Guruh biriktiruvi', 'Назначение группы', 'Group assignment'),
        _filled(profile['current_cohort']),
        Icons.groups_2_outlined,
      ),
      (
        t('Ta’lim tarixi', 'История обучения', 'Education history'),
        _filled(profile['previous_school']),
        Icons.history_edu_outlined,
      ),
      (
        t('Hudud ma’lumoti', 'Данные о регионе', 'Region information'),
        _filled(profile['location']),
        Icons.location_on_outlined,
      ),
    ];
    final bars = [
      _PortalBarDatum(
        label: t(
          'Shaxsiy ma’lumotlar',
          'Личные данные',
          'Personal information',
        ),
        value: completeness * 100,
        detail: t(
          'Telefon, email, tug‘ilgan sana va hudud asosida.',
          'На основе телефона, email, даты рождения и региона.',
          'Based on phone, email, date of birth, and region.',
        ),
        color: accent,
        icon: Icons.person_outline_rounded,
      ),
      _PortalBarDatum(
        label: t('O‘quv holati', 'Статус обучения', 'Learning status'),
        value: profile['current_cohort'] == null ? 35 : 100,
        detail: profile['current_cohort'] == null
            ? t(
                'Joriy guruh hali biriktirilmagan.',
                'Текущая группа ещё не назначена.',
                'No current group has been assigned yet.',
              )
            : t(
                'O‘quvchi guruhga to‘liq biriktirilgan.',
                'Ученик полностью привязан к группе.',
                'The student is fully assigned to a group.',
              ),
        color: Theme.of(context).colorScheme.secondary,
        icon: Icons.school_outlined,
      ),
      _PortalBarDatum(
        label: t('Akkaunt faolligi', 'Активность аккаунта', 'Account activity'),
        value: profile['is_blocked'] == true ? 0 : 100,
        detail: profile['is_blocked'] == true
            ? t(
                'Markaz akkauntga cheklov qo‘ygan.',
                'Центр ограничил аккаунт.',
                'The center has restricted the account.',
              )
            : t(
                'Akkaunt faol va ruxsatli xizmatlar ochiq.',
                'Аккаунт активен, а разрешённые сервисы доступны.',
                'The account is active and permitted services are available.',
              ),
        color: Sf.success,
        icon: Icons.shield_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final ring = _InteractiveRingChart(
          value: completeness,
          label: t('Tayyorlik', 'Готовность', 'Readiness'),
          detail: t(
            'Asosiy profil maydonlarining ${(completeness * 100).round()}% qismi serverda to‘ldirilgan.',
            'На сервере заполнено ${(completeness * 100).round()}% основных полей профиля.',
            '${(completeness * 100).round()}% of the core profile fields are completed on the server.',
          ),
          color: accent,
          centerIcon: Icons.badge_outlined,
          size: compact ? 106 : 120,
        );
        final checklist = _ProfileChecklist(checks: checks, accent: accent);
        final chart = _CompactBarChart(
          title: t(
            'Profil va o‘qishga tayyorlik',
            'Готовность профиля и к обучению',
            'Profile and learning readiness',
          ),
          items: bars,
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ring,
              const SizedBox(height: 12),
              checklist,
              const SizedBox(height: 12),
              chart,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 198, child: ring),
            const SizedBox(width: 12),
            Expanded(child: checklist),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: chart),
          ],
        );
      },
    );
  }
}

class _StudentScopeBreakdown extends StatelessWidget {
  const _StudentScopeBreakdown({
    required this.statusEntries,
    required this.branchEntries,
    required this.total,
  });

  final List<MapEntry<String, double>> statusEntries;
  final List<MapEntry<String, double>> branchEntries;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final status = _IdentityDistributionCard(
          title: _identityText(context, 'Statuslar', 'Статусы', 'Statuses'),
          subtitle: _identityText(
            context,
            'O‘quvchi holati bo‘yicha',
            'По статусу ученика',
            'By student status',
          ),
          icon: Icons.donut_large_outlined,
          accent: colors.primary,
          entries: statusEntries,
          total: total,
          transformLabel: (value) => _identityStatusLabel(context, value),
        );
        final branches = _IdentityDistributionCard(
          title: _identityText(context, 'Filiallar', 'Филиалы', 'Branches'),
          subtitle: _identityText(
            context,
            'Ko‘rinadigan profillar kesimi',
            'Срез доступных профилей',
            'Visible profile breakdown',
          ),
          icon: Icons.apartment_rounded,
          accent: colors.secondary,
          entries: branchEntries,
          total: total,
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [status, const SizedBox(height: 12), branches],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: status),
            const SizedBox(width: 12),
            Expanded(child: branches),
          ],
        );
      },
    );
  }
}

class _IdentityDistributionCard extends StatelessWidget {
  const _IdentityDistributionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.entries,
    required this.total,
    this.transformLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<MapEntry<String, double>> entries;
  final int total;
  final String Function(String)? transformLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final computedTotal = total > 0
        ? total.toDouble()
        : entries.fold<double>(0, (sum, item) => sum + item.value);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            Text(
              _identityText(
                context,
                'Taqsimot ma’lumoti mavjud emas',
                'Данные распределения отсутствуют',
                'Distribution data is unavailable',
              ),
              style: TextStyle(color: colors.onSurfaceVariant),
            )
          else
            for (var index = 0; index < entries.length; index++) ...[
              _DistributionRow(
                label:
                    transformLabel?.call(entries[index].key) ??
                    entries[index].key,
                value: entries[index].value,
                total: computedTotal,
                color:
                    Color.lerp(
                      accent,
                      colors.secondary,
                      entries.length <= 1 ? 0 : index / (entries.length - 1),
                    ) ??
                    accent,
              ),
              if (index != entries.length - 1) const SizedBox(height: 13),
            ],
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final double value;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: _identityText(
        context,
        '$label: ${value.round()}, ${(ratio * 100).round()} foiz',
        '$label: ${value.round()}, ${(ratio * 100).round()} процентов',
        '$label: ${value.round()}, ${(ratio * 100).round()} percent',
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${value.round()} · ${(ratio * 100).round()}%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              color: color,
              backgroundColor: color.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactPanel extends StatelessWidget {
  const _EmergencyContactPanel({
    required this.rawContacts,
    required this.accent,
  });

  final Object? rawContacts;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final contacts = _contactRows(rawContacts);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.12),
                foregroundColor: accent,
                child: const Icon(Icons.health_and_safety_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _identityText(
                        context,
                        'Favqulodda kontaktlar',
                        'Экстренные контакты',
                        'Emergency contacts',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _identityText(
                        context,
                        '${contacts.length} ta server yozuvi',
                        '${contacts.length} ${_russianRecordWord(contacts.length)} сервера',
                        '${contacts.length} server ${contacts.length == 1 ? 'record' : 'records'}',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 700 ? 2 : 1;
              const gap = 10.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var index = 0; index < contacts.length; index++)
                    SizedBox(
                      width: width,
                      child: _EmergencyContactCard(
                        contact: contacts[index],
                        index: index,
                        accent: accent,
                      ),
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

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({
    required this.contact,
    required this.index,
    required this.accent,
  });

  final Map<String, Object?> contact;
  final int index;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = valueText(
      contact,
      const ['full_name', 'name', 'contact_name'],
      fallback: _identityText(
        context,
        'Kontakt ${index + 1}',
        'Контакт ${index + 1}',
        'Contact ${index + 1}',
      ),
    );
    final phone = valueText(contact, const ['phone', 'phone_number', 'mobile']);
    final relation = valueText(contact, const [
      'relationship',
      'relation',
      'type',
    ]);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: accent.withValues(alpha: 0.1),
            foregroundColor: accent,
            child: Text(
              _initials(name),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (relation != '—')
                  Text(
                    _relationshipLabel(context, relation),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 6),
                SelectableText(
                  phone,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
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

class _BirthdayStrip extends StatelessWidget {
  const _BirthdayStrip({required this.rows});

  final List<Map<String, Object?>> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              _BirthdayCard(row: rows[index]),
              if (index != rows.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _BirthdayCard extends StatelessWidget {
  const _BirthdayCard({required this.row});

  final Map<String, Object?> row;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = colors.secondary;
    final name = valueText(row, const ['full_name']);
    return Container(
      width: 230,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            child: const Icon(Icons.cake_rounded, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  _dateLabel(row['birthdate']),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
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

class _ProfileChecklist extends StatelessWidget {
  const _ProfileChecklist({required this.checks, required this.accent});

  final List<(String, bool, IconData)> checks;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _identityText(
              context,
              'Tezkor tekshiruv',
              'Быстрая проверка',
              'Quick check',
            ),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 13),
          for (final check in checks) ...[
            Row(
              children: [
                Icon(
                  check.$3,
                  size: 18,
                  color: check.$2 ? accent : colors.outline,
                ),
                const SizedBox(width: 9),
                Expanded(child: Text(check.$1)),
                Icon(
                  check.$2 ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 20,
                  color: check.$2 ? Sf.success : colors.outline,
                ),
              ],
            ),
            if (check != checks.last) const SizedBox(height: 11),
          ],
        ],
      ),
    );
  }
}

class _EnrollmentReasonCloud extends StatelessWidget {
  const _EnrollmentReasonCloud({required this.reasons});

  final List<Map<String, Object?>> reasons;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 940
              ? 3
              : constraints.maxWidth >= 560
              ? 2
              : 1;
          const gap = 10.0;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final reason in reasons)
                SizedBox(
                  width: width,
                  child: _EnrollmentReasonCard(reason: reason),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EnrollmentReasonCard extends StatelessWidget {
  const _EnrollmentReasonCard({required this.reason});

  final Map<String, Object?> reason;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = _apiColor(reason['color'], colors.primary);
    final name = valueText(reason, const ['name']);
    final slug = valueText(reason, const ['slug']);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.11), colors.surface],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.explore_outlined, color: accent, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (slug != '—')
                  Text(
                    slug,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (reason['is_active'] == true)
            Icon(Icons.check_circle_rounded, color: accent, size: 18),
        ],
      ),
    );
  }
}

class _HeaderCountBadge extends StatelessWidget {
  const _HeaderCountBadge({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildSwitcher extends StatelessWidget {
  const _ChildSwitcher({
    required this.children,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Map<String, Object?>> children;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
            child: Row(
              children: [
                Icon(Icons.swap_horiz_rounded, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  _identityText(
                    context,
                    'Farzand profilini almashtirish',
                    'Сменить профиль ребёнка',
                    'Switch child profile',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  _ChildSwitchCard(
                    child: children[index],
                    selected: valueInt(children[index]['id']) == selectedId,
                    onTap: () {
                      final id = valueInt(children[index]['id']);
                      if (id != null) onSelected(id);
                    },
                  ),
                  if (index != children.length - 1) const SizedBox(width: 9),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildSwitchCard extends StatelessWidget {
  const _ChildSwitchCard({
    required this.child,
    required this.selected,
    required this.onTap,
  });

  final Map<String, Object?> child;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = colors.primary;
    final name = valueText(child, const ['full_name']);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 232,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.1)
                : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.55)
                  : colors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: selected
                    ? accent
                    : colors.surfaceContainerHighest,
                foregroundColor: selected
                    ? Colors.white
                    : colors.onSurfaceVariant,
                child: Text(_initials(name)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valueText(child, const ['student_id', 'academic_level']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildSpotlightCard extends StatelessWidget {
  const _ChildSpotlightCard({required this.child, required this.completeness});

  final Map<String, Object?> child;
  final double completeness;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = colors.primary;
    final name = valueText(child, const ['full_name']);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 590;
          final summary = Row(
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: accent,
                foregroundColor: Colors.white,
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${valueText(child, const ['student_id'])} · ${_ageLabel(context, child['birthdate'])}',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _SoftStatusBadge(
                          text: valueText(child, const ['status']),
                          icon: Icons.bolt_rounded,
                          positive: child['is_blocked'] != true,
                        ),
                        _SoftStatusBadge(
                          text: child['current_cohort'] == null
                              ? _identityText(
                                  context,
                                  'Guruhsiz',
                                  'Без группы',
                                  'No group',
                                )
                              : _identityText(
                                  context,
                                  'Guruh biriktirilgan',
                                  'Группа назначена',
                                  'Group assigned',
                                ),
                          icon: Icons.groups_2_outlined,
                          positive: child['current_cohort'] != null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
          final readiness = Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    value: completeness,
                    strokeWidth: 5,
                    color: accent,
                    backgroundColor: accent.withValues(alpha: 0.13),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(completeness * 100).round()}%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: accent,
                            ),
                      ),
                      Text(
                        _identityText(
                          context,
                          'profil to‘liq',
                          'профиль заполнен',
                          'profile complete',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [summary, const SizedBox(height: 16), readiness],
            );
          }
          return Row(
            children: [
              Expanded(child: summary),
              const SizedBox(width: 18),
              readiness,
            ],
          );
        },
      ),
    );
  }
}

class _SoftStatusBadge extends StatelessWidget {
  const _SoftStatusBadge({
    required this.text,
    required this.icon,
    required this.positive,
  });

  final String text;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = positive ? Sf.success : colors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              _identityStatusLabel(context, text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentIdentityCard extends StatelessWidget {
  const _ParentIdentityCard({
    required this.parent,
    required this.fallbackName,
    required this.completeness,
  });

  final Map<String, Object?> parent;
  final String fallbackName;
  final double completeness;

  @override
  Widget build(BuildContext context) {
    String t(String uz, String ru, String en) =>
        _identityText(context, uz, ru, en);
    final accent = Theme.of(context).colorScheme.primary;
    final name = valueText(parent, const ['full_name'], fallback: fallbackName);
    final fields = [
      _IdentityField(
        Icons.phone_iphone_rounded,
        t('Telefon', 'Телефон', 'Phone'),
        valueText(parent, const ['phone']),
      ),
      _IdentityField(
        Icons.alternate_email_rounded,
        t('Email', 'Email', 'Email'),
        valueText(parent, const ['email']),
      ),
      _IdentityField(
        Icons.work_outline_rounded,
        t('Ish joyi', 'Место работы', 'Workplace'),
        valueText(parent, const ['workplace']),
      ),
      _IdentityField(
        Icons.cake_outlined,
        t('Tug‘ilgan sana', 'Дата рождения', 'Date of birth'),
        _dateLabel(parent['birthdate']),
      ),
      _IdentityField(
        Icons.wc_outlined,
        t('Jins', 'Пол', 'Gender'),
        _genderLabel(context, '${parent['gender'] ?? ''}'),
      ),
      _IdentityField(
        Icons.login_rounded,
        t('Oxirgi kirish', 'Последний вход', 'Last sign-in'),
        _dateLabel(parent['last_login_at'], time: true),
      ),
      _IdentityField(
        Icons.alternate_email_rounded,
        t('Login', 'Логин', 'Username'),
        valueText(parent, const ['username']),
      ),
      _IdentityField(
        Icons.power_settings_new_rounded,
        t('Akkaunt holati', 'Статус аккаунта', 'Account status'),
        _activeAccountLabel(context, parent['is_active']),
      ),
      _IdentityField(
        Icons.password_rounded,
        t('Parol holati', 'Статус пароля', 'Password status'),
        _passwordStateLabel(context, parent['must_change_password']),
      ),
      _IdentityField(
        Icons.event_outlined,
        t('Profil yaratilgan', 'Профиль создан', 'Profile created'),
        _dateLabel(parent['created_at'], time: true),
      ),
    ];
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 29,
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    child: Text(
                      _initials(name),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          t(
                            'Tasdiqlangan kabinet egasi',
                            'Подтверждённый владелец кабинета',
                            'Verified account owner',
                          ),
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  _MiniCompletion(value: completeness, accent: accent),
                ],
              ),
              if (_filled(parent['notes'])) ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes_rounded, color: accent, size: 19),
                      const SizedBox(width: 9),
                      Expanded(child: Text('${parent['notes']}')),
                    ],
                  ),
                ),
              ],
            ],
          );
          final details = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final field in fields)
                SizedBox(
                  width: compact
                      ? constraints.maxWidth
                      : (constraints.maxWidth * 0.58 - 12) / 2,
                  child: _CompactIdentityFact(field: field, accent: accent),
                ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [identity, const SizedBox(height: 20), details],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: identity),
              const SizedBox(width: 26),
              Expanded(flex: 5, child: details),
            ],
          );
        },
      ),
    );
  }
}

class _FamilySafetyOverview extends StatelessWidget {
  const _FamilySafetyOverview({
    required this.child,
    required this.guardians,
    required this.pickups,
  });

  final Map<String, Object?> child;
  final List<Map<String, Object?>> guardians;
  final List<Map<String, Object?>> pickups;

  @override
  Widget build(BuildContext context) {
    String t(String uz, String ru, String en) =>
        _identityText(context, uz, ru, en);
    final activePickups = pickups.where((item) => item['is_active'] == true);
    final hasPrimary = guardians.any((item) => item['is_primary'] == true);
    final accountReady =
        child['is_active'] == true &&
        child['is_blocked'] == false &&
        child['must_change_password'] == false;
    final items = [
      (
        icon: accountReady
            ? Icons.verified_user_rounded
            : Icons.gpp_maybe_outlined,
        title: t('O‘quvchi akkaunti', 'Аккаунт ученика', 'Student account'),
        value: accountReady
            ? t('Himoyalangan', 'Защищён', 'Protected')
            : t('E’tibor talab qiladi', 'Требует внимания', 'Needs attention'),
        description: child['is_blocked'] == true
            ? valueText(
                child,
                const ['block_reason'],
                fallback: t(
                  'Akkaunt markaz tomonidan cheklangan.',
                  'Аккаунт ограничен центром.',
                  'The account was restricted by the center.',
                ),
              )
            : child['is_active'] == false
            ? t(
                'O‘quvchi akkaunti hozir nofaol.',
                'Аккаунт ученика сейчас неактивен.',
                'The student account is currently inactive.',
              )
            : child['must_change_password'] == true
            ? t(
                'Birinchi kirishda parolni almashtirish kerak.',
                'При первом входе нужно сменить пароль.',
                'The password must be changed on first sign-in.',
              )
            : accountReady
            ? t(
                'Kirish holati va parol talablari joyida.',
                'Статус доступа и требования к паролю в порядке.',
                'Access status and password requirements are in order.',
              )
            : t(
                'Akkaunt holati bo‘yicha to‘liq ma’lumot mavjud emas.',
                'Полные данные о статусе аккаунта отсутствуют.',
                'Complete account status information is unavailable.',
              ),
        ok: accountReady,
      ),
      (
        icon: hasPrimary
            ? Icons.family_restroom_rounded
            : Icons.person_search_outlined,
        title: t('Asosiy vakil', 'Основной представитель', 'Primary guardian'),
        value: hasPrimary
            ? t('Tasdiqlangan', 'Подтверждён', 'Verified')
            : t('Belgilanmagan', 'Не назначен', 'Not assigned'),
        description: guardians.isEmpty
            ? t(
                'Farzandga rasmiy vakil yozuvi bog‘lanmagan.',
                'К ребёнку не привязана запись об официальном представителе.',
                'No official guardian record is linked to the child.',
              )
            : t(
                '${guardians.length} ta vakillik yozuvi mavjud.',
                'Доступно ${guardians.length} ${_russianRecordWord(guardians.length)} о представителях.',
                '${guardians.length} guardian ${guardians.length == 1 ? 'record is' : 'records are'} available.',
              ),
        ok: hasPrimary,
      ),
      (
        icon: activePickups.isNotEmpty
            ? Icons.how_to_reg_rounded
            : Icons.person_off_outlined,
        title: t('Olib ketish', 'Получение ребёнка', 'Pickup'),
        value: t(
          '${activePickups.length} ta faol',
          'Активных: ${activePickups.length}',
          '${activePickups.length} active',
        ),
        description: pickups.isEmpty
            ? t(
                'Olib ketish uchun ruxsatnoma kiritilmagan.',
                'Разрешения на получение ребёнка не добавлены.',
                'No pickup permits have been added.',
              )
            : t(
                '${pickups.length} ta ruxsat yozuvi tekshirildi.',
                'Проверено ${pickups.length} ${_russianRecordWord(pickups.length)} о разрешениях.',
                '${pickups.length} permit ${pickups.length == 1 ? 'record was' : 'records were'} checked.',
              ),
        ok: activePickups.isNotEmpty,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 860
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _SafetyStatusCard(
                  icon: item.icon,
                  title: item.title,
                  value: item.value,
                  description: item.description,
                  ok: item.ok,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SafetyStatusCard extends StatelessWidget {
  const _SafetyStatusCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
    required this.ok,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = ok ? Sf.success : Sf.warn;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 21),
              ),
              const Spacer(),
              Icon(
                ok ? Icons.check_circle_rounded : Icons.info_rounded,
                color: accent,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCompletion extends StatelessWidget {
  const _MiniCompletion({required this.value, required this.accent});

  final double value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        '${(value * 100).round()}%',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: accent,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CompactIdentityFact extends StatelessWidget {
  const _CompactIdentityFact({required this.field, required this.accent});

  final _IdentityField field;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(field.icon, size: 18, color: accent),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  field.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuardianGrid extends StatelessWidget {
  const _GuardianGrid({required this.rows});

  final List<Map<String, Object?>> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 2 : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final row in rows)
              SizedBox(
                width: width,
                child: _GuardianCard(row: row),
              ),
          ],
        );
      },
    );
  }
}

class _GuardianCard extends StatelessWidget {
  const _GuardianCard({required this.row});

  final Map<String, Object?> row;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = colors.primary;
    final primary = row['is_primary'] == true;
    final name = valueText(row, const ['parent_name']);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary
              ? accent.withValues(alpha: 0.34)
              : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.12),
                foregroundColor: accent,
                child: Text(_initials(name)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _relationshipLabel(
                        context,
                        '${row['relationship'] ?? ''}',
                      ),
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              _SoftStatusBadge(
                text: primary
                    ? _identityText(context, 'Asosiy', 'Основной', 'Primary')
                    : _identityText(
                        context,
                        'Qo‘shimcha',
                        'Дополнительный',
                        'Additional',
                      ),
                icon: primary
                    ? Icons.star_rounded
                    : Icons.person_outline_rounded,
                positive: primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LabeledLine(
            icon: Icons.child_care_outlined,
            label: _identityText(context, 'Farzand', 'Ребёнок', 'Child'),
            value: valueText(row, const ['student_name']),
          ),
          const SizedBox(height: 9),
          _LabeledLine(
            icon: Icons.gavel_outlined,
            label: _identityText(
              context,
              'Rasmiy izoh',
              'Официальное примечание',
              'Official note',
            ),
            value: valueText(
              row,
              const ['custody_notes'],
              fallback: _identityText(
                context,
                'Izoh kiritilmagan',
                'Примечание не добавлено',
                'No note provided',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupPermitGrid extends StatelessWidget {
  const _PickupPermitGrid({required this.rows});

  final List<Map<String, Object?>> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 970
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final row in rows)
              SizedBox(
                width: width,
                child: _PickupPermitCard(row: row),
              ),
          ],
        );
      },
    );
  }
}

class _PickupPermitCard extends StatelessWidget {
  const _PickupPermitCard({required this.row});

  final Map<String, Object?> row;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active = row['is_active'] == true;
    final accent = active ? Sf.success : colors.error;
    final name = valueText(row, const ['full_name']);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _initials(name),
                  style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                ),
              ),
              const Spacer(),
              _SoftStatusBadge(
                text: active
                    ? _identityText(
                        context,
                        'Ruxsat bor',
                        'Разрешено',
                        'Permitted',
                      )
                    : _identityText(
                        context,
                        'Bekor qilingan',
                        'Отменено',
                        'Cancelled',
                      ),
                icon: active ? Icons.check_circle_rounded : Icons.block_rounded,
                positive: active,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            _relationshipLabel(context, '${row['relationship'] ?? ''}'),
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          if (_filled(row['student_name'])) ...[
            const SizedBox(height: 11),
            _LabeledLine(
              icon: Icons.child_care_outlined,
              label: _identityText(context, 'Farzand', 'Ребёнок', 'Child'),
              value: '${row['student_name']}',
            ),
          ],
          const SizedBox(height: 14),
          _LabeledLine(
            icon: Icons.phone_outlined,
            label: _identityText(context, 'Telefon', 'Телефон', 'Phone'),
            value: valueText(row, const ['phone']),
          ),
          const SizedBox(height: 8),
          _LabeledLine(
            icon: Icons.event_outlined,
            label: _identityText(
              context,
              'Ruxsat yaratilgan',
              'Разрешение создано',
              'Permit created',
            ),
            value: _dateLabel(row['created_at']),
          ),
        ],
      ),
    );
  }
}

class _LabeledLine extends StatelessWidget {
  const _LabeledLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumTimeline extends StatelessWidget {
  const _PremiumTimeline({required this.events, required this.accent});

  final List<Map<String, Object?>> events;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          for (var index = 0; index < events.length; index++)
            _TimelineEntry(
              event: events[index],
              accent: accent,
              latest: index == 0,
              last: index == events.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.event,
    required this.accent,
    required this.latest,
    required this.last,
  });

  final Map<String, Object?> event;
  final Color accent;
  final bool latest;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final from = _identityStatusLabel(context, '${event['from_status'] ?? ''}');
    final to = _identityStatusLabel(context, '${event['to_status'] ?? ''}');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: latest ? 28 : 22,
                  height: latest ? 28 : 22,
                  decoration: BoxDecoration(
                    color: latest ? accent : accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: 2),
                  ),
                  child: Icon(
                    latest ? Icons.auto_awesome_rounded : Icons.check_rounded,
                    size: latest ? 15 : 12,
                    color: latest ? Colors.white : accent,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: accent.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 10 : 24),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: latest
                      ? accent.withValues(alpha: 0.07)
                      : colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            from.isEmpty ||
                                    from ==
                                        _identityText(
                                          context,
                                          'Noma’lum',
                                          'Неизвестно',
                                          'Unknown',
                                        )
                                ? to
                                : '$from  →  $to',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (latest)
                          Text(
                            _identityText(
                              context,
                              'SO‘NGGI',
                              'ПОСЛЕДНЕЕ',
                              'LATEST',
                            ),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      valueText(
                        event,
                        const ['note'],
                        fallback: _identityText(
                          context,
                          'Profil holati markaz tomonidan yangilandi.',
                          'Статус профиля обновлён центром.',
                          'The profile status was updated by the center.',
                        ),
                      ),
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 5,
                      children: [
                        _TimelineMeta(
                          icon: Icons.schedule_rounded,
                          text: _dateLabel(event['created_at'], time: true),
                        ),
                        if (_filled(event['reason_code']))
                          _TimelineMeta(
                            icon: Icons.sell_outlined,
                            text: '${event['reason_code']}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineMeta extends StatelessWidget {
  const _TimelineMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _IdentityEmptyPanel extends StatelessWidget {
  const _IdentityEmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 12 : 16,
        vertical: mobile ? 12 : 18,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(mobile ? 14 : 16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: mobile ? 38 : 52,
            height: mobile ? 38 : 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(mobile ? 12 : 17),
            ),
            child: Icon(icon, color: accent, size: mobile ? 20 : 27),
          ),
          SizedBox(width: mobile ? 11 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: mobile ? 2 : 4),
                Text(
                  message,
                  maxLines: mobile ? 3 : null,
                  overflow: mobile ? TextOverflow.ellipsis : null,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

double _studentProfileCompleteness(Map<String, Object?> profile) {
  const fields = [
    'full_name',
    'phone',
    'email',
    'birthdate',
    'location',
    'previous_school',
    'enrollment_date',
    'academic_level',
    'branch',
    'current_cohort',
  ];
  if (profile.isEmpty) return 0;
  return fields.where((field) => _filled(profile[field])).length /
      fields.length;
}

double _parentProfileCompleteness(Map<String, Object?> profile) {
  const fields = [
    'full_name',
    'phone',
    'email',
    'birthdate',
    'gender',
    'workplace',
  ];
  if (profile.isEmpty) return 0;
  return fields.where((field) => _filled(profile[field])).length /
      fields.length;
}

List<Map<String, Object?>> _forSelectedChild(
  List<Map<String, Object?>> rows,
  int? selectedId,
) {
  if (selectedId == null) return rows;
  final filtered = rows
      .where((row) => valueInt(row['student']) == selectedId)
      .toList();
  return filtered;
}

bool _filled(Object? value) {
  if (value == null) return false;
  if (value is Iterable) return value.isNotEmpty;
  if (value is Map) return value.isNotEmpty;
  final text = '$value'.trim().toLowerCase();
  return text.isNotEmpty && text != 'null' && text != '—';
}

bool _hasEmergencyContacts(Map<String, Object?> profile) =>
    _filled(profile['emergency_contacts']);

String _availability(BuildContext context, Object? value) => _filled(value)
    ? _identityText(context, 'Kiritilgan', 'Указано', 'Provided')
    : _identityText(context, 'Kutilmoqda', 'Ожидается', 'Pending');

String _activeAccountLabel(BuildContext context, Object? raw) => switch (raw) {
  true => _identityText(context, 'Faol', 'Активен', 'Active'),
  false => _identityText(context, 'Nofaol', 'Неактивен', 'Inactive'),
  _ => _identityText(
    context,
    'Ma’lumot mavjud emas',
    'Данные отсутствуют',
    'Information unavailable',
  ),
};

String _passwordStateLabel(BuildContext context, Object? raw) => switch (raw) {
  true => _identityText(
    context,
    'Almashtirish talab qilinadi',
    'Требуется смена',
    'Change required',
  ),
  false => _identityText(
    context,
    'Almashtirish talab qilinmaydi',
    'Смена не требуется',
    'No change required',
  ),
  _ => _identityText(
    context,
    'Ma’lumot mavjud emas',
    'Данные отсутствуют',
    'Information unavailable',
  ),
};

String _genderLabel(BuildContext context, String value) =>
    switch (value.toLowerCase()) {
      'male' || 'm' => _identityText(context, 'Erkak', 'Мужской', 'Male'),
      'female' || 'f' => _identityText(context, 'Ayol', 'Женский', 'Female'),
      _ => value.trim().isEmpty ? '—' : value,
    };

String _ageLabel(BuildContext context, Object? raw) {
  final birthdate = DateTime.tryParse('${raw ?? ''}');
  if (birthdate == null) {
    return _identityText(
      context,
      'Yosh ko‘rsatilmagan',
      'Возраст не указан',
      'Age not specified',
    );
  }
  final now = DateTime.now();
  var age = now.year - birthdate.year;
  if (now.month < birthdate.month ||
      (now.month == birthdate.month && now.day < birthdate.day)) {
    age--;
  }
  if (age < 0) {
    return _identityText(
      context,
      'Yosh ko‘rsatilmagan',
      'Возраст не указан',
      'Age not specified',
    );
  }
  return _identityText(
    context,
    '$age yosh',
    '$age ${_russianAgeWord(age)}',
    '$age ${age == 1 ? 'year' : 'years'} old',
  );
}

Color _apiColor(Object? raw, Color fallback) {
  final value = '${raw ?? ''}'.trim().replaceFirst('#', '');
  if (value.length != 6) return fallback;
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? fallback : Color(0xFF000000 | parsed);
}

String _relationshipLabel(BuildContext context, String value) => switch (value
    .toLowerCase()) {
  'mother' => _identityText(context, 'Ona', 'Мать', 'Mother'),
  'father' => _identityText(context, 'Ota', 'Отец', 'Father'),
  'grandparent' => _identityText(
    context,
    'Buvi yoki buva',
    'Бабушка или дедушка',
    'Grandparent',
  ),
  'legal_guardian' => _identityText(
    context,
    'Qonuniy vakil',
    'Законный представитель',
    'Legal guardian',
  ),
  'sibling' => _identityText(
    context,
    'Aka, uka, opa yoki singil',
    'Брат или сестра',
    'Sibling',
  ),
  'aunt' => _identityText(context, 'Amma, xola', 'Тётя', 'Aunt'),
  'uncle' => _identityText(context, 'Amaki, tog‘a', 'Дядя', 'Uncle'),
  'relative' => _identityText(context, 'Qarindosh', 'Родственник', 'Relative'),
  'family_friend' => _identityText(
    context,
    'Oila tanishi',
    'Друг семьи',
    'Family friend',
  ),
  _ =>
    value.trim().isEmpty
        ? _identityText(context, 'Vakil', 'Представитель', 'Guardian')
        : value,
};

String _identityStatusLabel(BuildContext context, String raw) => switch (raw
    .trim()
    .toLowerCase()) {
  'active' => _identityText(context, 'Faol', 'Активен', 'Active'),
  'inactive' => _identityText(context, 'Nofaol', 'Неактивен', 'Inactive'),
  'blocked' => _identityText(context, 'Bloklangan', 'Заблокирован', 'Blocked'),
  'pending' => _identityText(context, 'Kutilmoqda', 'Ожидается', 'Pending'),
  'enrolled' => _identityText(
    context,
    'Qabul qilingan',
    'Зачислен',
    'Enrolled',
  ),
  'studying' => _identityText(context, 'O‘qimoqda', 'Обучается', 'Studying'),
  'paused' => _identityText(context, 'To‘xtatilgan', 'Приостановлен', 'Paused'),
  'graduated' => _identityText(context, 'Bitirgan', 'Выпустился', 'Graduated'),
  'withdrawn' || 'dropped' => _identityText(
    context,
    'O‘qishdan chiqarilgan',
    'Отчислен',
    'Withdrawn',
  ),
  'scheduled' => _identityText(context, 'Rejada', 'Запланировано', 'Scheduled'),
  'cancelled' || 'canceled' => _identityText(
    context,
    'Bekor qilingan',
    'Отменено',
    'Cancelled',
  ),
  'approved' => _identityText(
    context,
    'Tasdiqlangan',
    'Подтверждено',
    'Approved',
  ),
  _ =>
    raw.trim().isEmpty
        ? _identityText(context, 'Noma’lum', 'Неизвестно', 'Unknown')
        : raw,
};

String _identityCount(BuildContext context, int count) => _identityText(
  context,
  '$count ta',
  '$count ${_russianRecordWord(count)}',
  '$count ${count == 1 ? 'item' : 'items'}',
);

String _russianChildrenWord(int count) {
  final lastTwo = count % 100;
  if (lastTwo >= 11 && lastTwo <= 14) return 'детей';
  return switch (count % 10) {
    1 => 'ребёнок',
    2 || 3 || 4 => 'ребёнка',
    _ => 'детей',
  };
}

String _russianRecordWord(int count) {
  final lastTwo = count % 100;
  if (lastTwo >= 11 && lastTwo <= 14) return 'записей';
  return switch (count % 10) {
    1 => 'запись',
    2 || 3 || 4 => 'записи',
    _ => 'записей',
  };
}

String _russianFieldWord(int count) {
  final lastTwo = count % 100;
  if (lastTwo >= 11 && lastTwo <= 14) return 'полей';
  return switch (count % 10) {
    1 => 'поле',
    2 || 3 || 4 => 'поля',
    _ => 'полей',
  };
}

String _russianAgeWord(int age) {
  final lastTwo = age % 100;
  if (lastTwo >= 11 && lastTwo <= 14) return 'лет';
  return switch (age % 10) {
    1 => 'год',
    2 || 3 || 4 => 'года',
    _ => 'лет',
  };
}

double? _identityDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}');
}

List<MapEntry<String, double>> _mapEntries(BuildContext context, Object? raw) {
  if (raw is! Map) return const [];
  final entries = <MapEntry<String, double>>[];
  for (final entry in raw.entries) {
    final value = _identityDouble(entry.value);
    if (value == null || value < 0) continue;
    final key = '${entry.key ?? ''}'.trim();
    entries.add(
      MapEntry(
        key.isEmpty || key == 'null'
            ? _identityText(context, 'Noma’lum', 'Неизвестно', 'Unknown')
            : key,
        value,
      ),
    );
  }
  entries.sort((a, b) => b.value.compareTo(a.value));
  return entries;
}

String _referenceLabel(BuildContext context, Object? raw) {
  if (!_filled(raw)) {
    return _identityText(
      context,
      'Biriktirilmagan',
      'Не назначено',
      'Not assigned',
    );
  }
  if (raw is Map) {
    final normalized = raw.map((key, value) => MapEntry('$key', value));
    return valueText(
      normalized,
      const ['name', 'title', 'label'],
      fallback: _identityText(
        context,
        'Biriktirilgan',
        'Назначено',
        'Assigned',
      ),
    );
  }
  if (raw is num || int.tryParse('$raw'.trim()) != null) {
    return _identityText(context, 'Biriktirilgan', 'Назначено', 'Assigned');
  }
  return '$raw'.trim();
}

List<Map<String, Object?>> _contactRows(Object? raw) {
  final source = raw is List ? raw : [raw];
  final result = <Map<String, Object?>>[];
  for (final item in source) {
    if (item == null) continue;
    if (item is Map) {
      result.add(item.map((key, value) => MapEntry('$key', value)));
    } else if ('$item'.trim().isNotEmpty) {
      result.add({'name': '$item'});
    }
  }
  return result;
}
