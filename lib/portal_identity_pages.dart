part of 'portal_app.dart';

class _IdentityPortalPage extends StatelessWidget {
  const _IdentityPortalPage();

  @override
  Widget build(BuildContext context) {
    final portal = PortalScope.of(context);
    return portal.isStudent
        ? _StudentIdentityPage(portal: portal)
        : _ParentFamilyPage(portal: portal);
  }
}

class _StudentIdentityPage extends StatelessWidget {
  const _StudentIdentityPage({required this.portal});

  final PortalController portal;

  @override
  Widget build(BuildContext context) {
    final profile = portal.studentProfile;
    final stats = portal.studentStats;
    final profileProgress = _studentProfileCompleteness(profile);
    final withCohort = valueInt(stats['with_cohort']) ?? 0;
    final total = valueInt(stats['total']) ?? 0;
    final activeReasons = portal.enrollmentReasons
        .where((item) => item['is_active'] != false)
        .toList();
    final birthdays = portal.birthdays;
    final statusStats = _mapEntries(stats['by_status']);
    final branchStats = _mapEntries(stats['by_branch']);
    final studentBlue = Theme.of(context).colorScheme.primary;
    final studentCyan = Theme.of(context).colorScheme.secondary;

    if (profile.isEmpty) {
      return _PortalPage(
        title: 'Mening profilim',
        subtitle: 'Shaxsiy o‘quv pasportingiz va markazdagi yo‘lingiz.',
        section: PortalSection.identity,
        children: [
          _IdentityEmptyPanel(
            icon: Icons.badge_outlined,
            title: 'Profil ma’lumotlari yuklanmadi',
            message:
                'O‘quvchi profili serverda mavjud bo‘lgach, shaxsiy va akademik ma’lumotlar shu yerda ko‘rinadi.',
            accent: studentBlue,
          ),
        ],
      );
    }

    return _PortalPage(
      title: 'Mening profilim',
      subtitle:
          'Shaxsiy o‘quv pasportingiz, guruh holati va markazdagi yo‘lingiz.',
      section: PortalSection.identity,
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
              label: 'Profil tayyorligi',
              value: '${(profileProgress * 100).round()}%',
              detail: 'Asosiy ma’lumotlar to‘liqligi',
              accent: studentBlue,
              progress: profileProgress,
              onTap: () => _showJsonDetail(
                context,
                title: 'Profil to‘liqligi',
                fields: {
                  'To‘ldirilgan': '${(profileProgress * 100).round()}%',
                  'Telefon': _availability(profile['phone']),
                  'Email': _availability(profile['email']),
                  'Manzil': _availability(profile['location']),
                  'Guruh': _availability(profile['current_cohort']),
                },
              ),
            ),
            _IdentityMetric(
              icon: Icons.hub_outlined,
              label: 'Guruh holati',
              value: profile['current_cohort'] == null
                  ? 'Kutilmoqda'
                  : 'Ulangan',
              detail: profile['current_cohort'] == null
                  ? 'Joriy guruh biriktirilmagan'
                  : 'Markaz tizimida guruh biriktirilgan',
              accent: studentCyan,
              progress: total <= 0 ? null : withCohort / total,
            ),
            _IdentityMetric(
              icon: Icons.school_outlined,
              label: 'O‘qish statusi',
              value: _statusLabel('${profile['status'] ?? ''}'),
              detail: _filled(profile['enrollment_date'])
                  ? '${_dateLabel(profile['enrollment_date'])} dan boshlab'
                  : 'Qabul sanasi hali ko‘rsatilmagan',
              accent: studentCyan,
            ),
            _IdentityMetric(
              icon: profile['is_blocked'] == true
                  ? Icons.lock_rounded
                  : Icons.verified_user_rounded,
              label: 'Akkaunt xavfsizligi',
              value: profile['is_blocked'] == true
                  ? 'Cheklangan'
                  : 'Himoyalangan',
              detail: profile['is_blocked'] == true
                  ? valueText(profile, const ['block_reason'])
                  : 'Kirish va o‘qish xizmatlari faol',
              accent: profile['is_blocked'] == true
                  ? Theme.of(context).colorScheme.error
                  : Sf.success,
              progress: profile['is_blocked'] == true ? 0 : 1,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _IdentitySectionHeading(
          icon: Icons.badge_outlined,
          overline: 'O‘QUVCHI DOSYESI',
          title: 'Shaxsiy va akademik ma’lumotlar',
          description:
              'Markaz tizimida tasdiqlangan identifikatsiya va ta’lim maydonlari.',
        ),
        const SizedBox(height: 12),
        _IdentityInformationPanel(
          accent: studentBlue,
          groups: [
            _IdentityInfoGroup(
              title: 'Aloqa va shaxsiy ma’lumotlar',
              icon: Icons.person_outline_rounded,
              fields: [
                _IdentityField(
                  Icons.person_outline_rounded,
                  'Ism',
                  valueText(profile, const ['first_name']),
                ),
                _IdentityField(
                  Icons.person_outline_rounded,
                  'Familiya',
                  valueText(profile, const ['last_name']),
                ),
                _IdentityField(
                  Icons.person_outline_rounded,
                  'Otasining ismi',
                  valueText(profile, const ['middle_name']),
                ),
                _IdentityField(
                  Icons.phone_iphone_rounded,
                  'Telefon',
                  valueText(profile, const ['phone']),
                ),
                _IdentityField(
                  Icons.alternate_email_rounded,
                  'Email',
                  valueText(profile, const ['email']),
                ),
                _IdentityField(
                  Icons.cake_outlined,
                  'Tug‘ilgan sana',
                  _dateLabel(profile['birthdate']),
                ),
                _IdentityField(
                  Icons.wc_outlined,
                  'Jins',
                  _genderLabel('${profile['gender'] ?? ''}'),
                ),
                _IdentityField(
                  Icons.location_on_outlined,
                  'Hudud',
                  valueText(profile, const ['location']),
                ),
                _IdentityField(
                  Icons.login_rounded,
                  'Oxirgi kirish',
                  _dateLabel(profile['last_login_at'], time: true),
                ),
              ],
            ),
            _IdentityInfoGroup(
              title: 'Ta’lim profili',
              icon: Icons.school_outlined,
              fields: [
                _IdentityField(
                  Icons.tag_rounded,
                  'O‘quvchi ID',
                  valueText(profile, const ['student_id']),
                ),
                _IdentityField(
                  Icons.auto_graph_rounded,
                  'Akademik daraja',
                  valueText(profile, const ['academic_level']),
                ),
                _IdentityField(
                  Icons.groups_2_outlined,
                  'Guruh holati',
                  _referenceLabel(profile['current_cohort']),
                ),
                _IdentityField(
                  Icons.apartment_rounded,
                  'Filial holati',
                  _referenceLabel(profile['branch']),
                ),
                _IdentityField(
                  Icons.event_available_outlined,
                  'Qabul sanasi',
                  _dateLabel(profile['enrollment_date']),
                ),
                _IdentityField(
                  Icons.account_balance_outlined,
                  'Oldingi maktab',
                  valueText(profile, const ['previous_school']),
                ),
              ],
            ),
            _IdentityInfoGroup(
              title: 'Akkaunt va tizim holati',
              icon: Icons.admin_panel_settings_outlined,
              fields: [
                _IdentityField(
                  Icons.alternate_email_rounded,
                  'Login',
                  valueText(profile, const ['username']),
                ),
                _IdentityField(
                  Icons.power_settings_new_rounded,
                  'Akkaunt holati',
                  _activeAccountLabel(profile['is_active']),
                ),
                _IdentityField(
                  Icons.password_rounded,
                  'Parol holati',
                  _passwordStateLabel(profile['must_change_password']),
                ),
                _IdentityField(
                  Icons.lock_clock_outlined,
                  'Bloklangan sana',
                  _dateLabel(profile['blocked_at'], time: true),
                ),
                _IdentityField(
                  Icons.event_outlined,
                  'Profil yaratilgan',
                  _dateLabel(profile['created_at'], time: true),
                ),
                _IdentityField(
                  Icons.update_rounded,
                  'So‘nggi yangilanish',
                  _dateLabel(profile['updated_at'], time: true),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        _StudentReadinessPanel(
          profile: profile,
          completeness: profileProgress,
          accent: studentBlue,
        ),
        if (statusStats.isNotEmpty || branchStats.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _IdentitySectionHeading(
            icon: Icons.analytics_outlined,
            overline: 'JONLI KO‘RSATKICHLAR',
            title: 'Guruh va markaz kesimi',
            description:
                'O‘quv markazidagi faol holatlar va filiallar taqsimoti.',
          ),
          const SizedBox(height: 12),
          _StudentScopeBreakdown(
            statusEntries: statusStats,
            branchEntries: branchStats,
            total: total,
          ),
        ],
        if (_hasEmergencyContacts(profile)) ...[
          const SizedBox(height: 20),
          const _IdentitySectionHeading(
            icon: Icons.emergency_outlined,
            overline: 'MUHIM ALOQA',
            title: 'Favqulodda bog‘lanish',
            description: 'Markazga taqdim etilgan tezkor aloqa ma’lumotlari.',
          ),
          const SizedBox(height: 12),
          _EmergencyContactPanel(
            rawContacts: profile['emergency_contacts'],
            accent: Theme.of(context).colorScheme.error,
          ),
        ],
        if (activeReasons.isNotEmpty) ...[
          const SizedBox(height: 20),
          _IdentitySectionHeading(
            icon: Icons.explore_outlined,
            overline: 'MARKAZ KATALOGI',
            title: 'Qabul yo‘nalishlari',
            description:
                'Markazda hozir faol bo‘lgan qabul sabab va yo‘nalishlari.',
            count: activeReasons.length,
          ),
          const SizedBox(height: 12),
          _EnrollmentReasonCloud(reasons: activeReasons),
        ],
        if (birthdays.isNotEmpty) ...[
          const SizedBox(height: 20),
          _IdentitySectionHeading(
            icon: Icons.cake_outlined,
            overline: 'HAMJAMIYAT',
            title: 'Yaqin tug‘ilgan kunlar',
            description:
                'Sizga ko‘rishga ruxsat berilgan o‘quvchilar orasidagi yaqin sanalar.',
            count: birthdays.length,
          ),
          const SizedBox(height: 12),
          _BirthdayStrip(rows: birthdays),
        ],
        const SizedBox(height: 20),
        _IdentitySectionHeading(
          icon: Icons.route_rounded,
          overline: 'TARIX',
          title: 'O‘qish yo‘li',
          description: 'Profil statusidagi rasmiy o‘zgarishlar xronologiyasi.',
          count: portal.studentEvents.length,
        ),
        const SizedBox(height: 12),
        if (portal.studentEvents.isEmpty)
          _IdentityEmptyPanel(
            icon: Icons.route_outlined,
            title: 'Yo‘l endi boshlanmoqda',
            message:
                'Status o‘zgarganda tarix, sana va markaz izohi shu yerda paydo bo‘ladi.',
            accent: studentBlue,
          )
        else
          _PremiumTimeline(events: portal.studentEvents, accent: studentBlue),
      ],
    );
  }
}

class _ParentFamilyPage extends StatelessWidget {
  const _ParentFamilyPage({required this.portal});

  final PortalController portal;

  @override
  Widget build(BuildContext context) {
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
      title: 'Farzandlarim',
      subtitle:
          'Oilaviy nazorat markazi: farzand profili, rasmiy vakillar va xavfsiz olib ketish.',
      section: PortalSection.identity,
      trailing: _HeaderCountBadge(
        icon: Icons.family_restroom_rounded,
        label: '${portal.children.length} farzand',
        accent: familyTeal,
      ),
      children: [
        if (parent.isEmpty)
          _IdentityEmptyPanel(
            icon: Icons.family_restroom_outlined,
            title: 'Ota-ona profili topilmadi',
            message:
                'Kabinetning shaxsiy ma’lumotlari serverdan qaytgach oila profili shu yerda ko‘rinadi.',
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
              label: 'Oiladagi o‘quvchilar',
              value: '${portal.children.length}',
              detail: portal.children.length == 1
                  ? 'Bitta faol o‘quvchi profili'
                  : 'Kabinetga ulangan profillar',
              accent: familyTeal,
            ),
            _IdentityMetric(
              icon: Icons.verified_user_outlined,
              label: 'Rasmiy vakillar',
              value: '${visibleGuardians.length}',
              detail: 'Tanlangan farzandga bog‘langan',
              accent: familyWarm,
            ),
            _IdentityMetric(
              icon: Icons.directions_walk_rounded,
              label: 'Faol ruxsatnomalar',
              value: '$activePickups',
              detail: visiblePickups.isEmpty
                  ? 'Ruxsatnoma hali kiritilmagan'
                  : '${visiblePickups.length} ta yozuvdan faol',
              accent: Sf.success,
              progress: visiblePickups.isEmpty
                  ? 0
                  : activePickups / visiblePickups.length,
            ),
            _IdentityMetric(
              icon: Icons.fact_check_outlined,
              label: 'Farzand profili',
              value: '${(childProgress * 100).round()}%',
              detail: 'Ma’lumotlarning to‘liqligi',
              accent: familyWarm,
              progress: childProgress,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _IdentitySectionHeading(
          icon: Icons.face_retouching_natural_rounded,
          overline: 'TANLANGAN FARZAND',
          title: 'O‘quvchi profili va holati',
          description:
              'Markaz bazasidagi joriy akademik va shaxsiy ma’lumotlar.',
        ),
        const SizedBox(height: 12),
        if (child.isEmpty)
          _IdentityEmptyPanel(
            icon: Icons.person_search_outlined,
            title: 'Farzand profili topilmadi',
            message:
                'Markaz rasmiy bog‘lanishni tasdiqlagach profil shu yerda ko‘rinadi.',
            accent: familyTeal,
          )
        else ...[
          _ChildSpotlightCard(child: child, completeness: childProgress),
          const SizedBox(height: 14),
          _IdentityInformationPanel(
            accent: familyWarm,
            groups: [
              _IdentityInfoGroup(
                title: 'Shaxsiy ma’lumotlar',
                icon: Icons.contact_page_outlined,
                fields: [
                  _IdentityField(
                    Icons.person_outline_rounded,
                    'Ism',
                    valueText(child, const ['first_name']),
                  ),
                  _IdentityField(
                    Icons.person_outline_rounded,
                    'Familiya',
                    valueText(child, const ['last_name']),
                  ),
                  _IdentityField(
                    Icons.person_outline_rounded,
                    'Otasining ismi',
                    valueText(child, const ['middle_name']),
                  ),
                  _IdentityField(
                    Icons.tag_rounded,
                    'O‘quvchi ID',
                    valueText(child, const ['student_id']),
                  ),
                  _IdentityField(
                    Icons.cake_outlined,
                    'Tug‘ilgan sana',
                    _dateLabel(child['birthdate']),
                  ),
                  _IdentityField(
                    Icons.phone_iphone_rounded,
                    'Telefon',
                    valueText(child, const ['phone']),
                  ),
                  _IdentityField(
                    Icons.alternate_email_rounded,
                    'Email',
                    valueText(child, const ['email']),
                  ),
                  _IdentityField(
                    Icons.wc_outlined,
                    'Jins',
                    _genderLabel('${child['gender'] ?? ''}'),
                  ),
                  _IdentityField(
                    Icons.location_on_outlined,
                    'Hudud',
                    valueText(child, const ['location']),
                  ),
                ],
              ),
              _IdentityInfoGroup(
                title: 'Ta’lim holati',
                icon: Icons.menu_book_outlined,
                fields: [
                  _IdentityField(
                    Icons.auto_graph_rounded,
                    'Akademik daraja',
                    valueText(child, const ['academic_level']),
                  ),
                  _IdentityField(
                    Icons.groups_2_outlined,
                    'Guruh holati',
                    _referenceLabel(child['current_cohort']),
                  ),
                  _IdentityField(
                    Icons.apartment_rounded,
                    'Filial holati',
                    _referenceLabel(child['branch']),
                  ),
                  _IdentityField(
                    Icons.event_available_outlined,
                    'Qabul sanasi',
                    _dateLabel(child['enrollment_date']),
                  ),
                  _IdentityField(
                    Icons.account_balance_outlined,
                    'Oldingi maktab',
                    valueText(child, const ['previous_school']),
                  ),
                  _IdentityField(
                    Icons.shield_outlined,
                    'Akkaunt',
                    child['is_blocked'] == true
                        ? 'Cheklangan'
                        : _activeAccountLabel(child['is_active']),
                  ),
                ],
              ),
              _IdentityInfoGroup(
                title: 'Akkaunt va xizmatlar',
                icon: Icons.security_outlined,
                fields: [
                  _IdentityField(
                    Icons.alternate_email_rounded,
                    'Login',
                    valueText(child, const ['username']),
                  ),
                  _IdentityField(
                    Icons.power_settings_new_rounded,
                    'Tizim holati',
                    _activeAccountLabel(child['is_active']),
                  ),
                  _IdentityField(
                    Icons.password_rounded,
                    'Parol holati',
                    _passwordStateLabel(child['must_change_password']),
                  ),
                  _IdentityField(
                    Icons.login_rounded,
                    'Oxirgi kirish',
                    _dateLabel(child['last_login_at'], time: true),
                  ),
                  _IdentityField(
                    Icons.lock_clock_outlined,
                    'Bloklangan sana',
                    _dateLabel(child['blocked_at'], time: true),
                  ),
                  _IdentityField(
                    Icons.update_rounded,
                    'So‘nggi yangilanish',
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
        const SizedBox(height: 20),
        const _IdentitySectionHeading(
          icon: Icons.person_pin_outlined,
          overline: 'OILA PROFILI',
          title: 'Ota-ona ma’lumotlari',
          description:
              'Markaz bilan aloqa qiluvchi tasdiqlangan kabinet egasi.',
        ),
        const SizedBox(height: 12),
        if (parent.isEmpty)
          _IdentityEmptyPanel(
            icon: Icons.person_search_outlined,
            title: 'Shaxsiy ma’lumotlar mavjud emas',
            message:
                'Ota-ona kartasi ma’lumotlar tasdiqlangach avtomatik to‘ldiriladi.',
            accent: familyTeal,
          )
        else
          _ParentIdentityCard(
            parent: parent,
            fallbackName: portal.displayName,
            completeness: parentProgress,
          ),
        if (child.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _IdentitySectionHeading(
            icon: Icons.health_and_safety_outlined,
            overline: 'XAVFSIZLIK MARKAZI',
            title: 'Farzand bo‘yicha tezkor holat',
            description:
                'Akkaunt, vakillik va olib ketish ruxsatlari bitta ko‘rinishda.',
          ),
          const SizedBox(height: 12),
          _FamilySafetyOverview(
            child: child,
            guardians: visibleGuardians,
            pickups: visiblePickups,
          ),
        ],
        const SizedBox(height: 20),
        _IdentitySectionHeading(
          icon: Icons.account_tree_outlined,
          overline: 'RASMİY BOG‘LANISHLAR',
          title: 'Vakillik va qarindoshlik',
          description:
              'Farzand nomidan markaz bilan bog‘lanishga ruxsat berilgan shaxslar.',
          count: visibleGuardians.length,
        ),
        const SizedBox(height: 12),
        if (visibleGuardians.isEmpty)
          _IdentityEmptyPanel(
            icon: Icons.link_off_rounded,
            title: 'Rasmiy bog‘lanish topilmadi',
            message:
                'Guardian yozuvi markaz tomonidan tasdiqlangach shu bo‘limda ko‘rinadi.',
            accent: familyTeal,
          )
        else
          _GuardianGrid(rows: visibleGuardians),
        const SizedBox(height: 20),
        _IdentitySectionHeading(
          icon: Icons.directions_walk_rounded,
          overline: 'XAVFSIZ OLIB KETISH',
          title: 'Tasdiqlangan ruxsatnomalar',
          description:
              'Farzandingizni markazdan olib ketishi mumkin bo‘lgan shaxslar.',
          count: visiblePickups.length,
        ),
        const SizedBox(height: 12),
        if (visiblePickups.isEmpty)
          _IdentityEmptyPanel(
            icon: Icons.person_pin_circle_outlined,
            title: 'Ruxsatnomalar mavjud emas',
            message:
                'Ruxsat berilgan shaxslar markaz tasdig‘idan so‘ng shu yerda chiqadi.',
            accent: familyWarm,
          )
        else
          _PickupPermitGrid(rows: visiblePickups),
        if (portal.studentEvents.isNotEmpty) ...[
          const SizedBox(height: 20),
          _IdentitySectionHeading(
            icon: Icons.history_edu_rounded,
            overline: 'FARZAND TARIXI',
            title: 'O‘qish yo‘li',
            description: 'Tanlangan farzand statusining rasmiy xronologiyasi.',
            count: portal.studentEvents.length,
          ),
          const SizedBox(height: 12),
          _PremiumTimeline(events: portal.studentEvents, accent: familyTeal),
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
    final scheme = Theme.of(context).colorScheme;
    final name = valueText(profile, const [
      'full_name',
    ], fallback: fallbackName);
    final active =
        profile['is_active'] == true && profile['is_blocked'] == false;
    final accessLabel = profile['is_blocked'] == true
        ? 'Kirish cheklangan'
        : profile['is_active'] == true
        ? 'Faol o‘quvchi'
        : profile['is_active'] == false
        ? 'Akkaunt nofaol'
        : 'Akkaunt holati noma’lum';
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
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HeroEyebrow(
                      icon: Icons.auto_awesome_rounded,
                      text: 'STARFORGE STUDENT PASS',
                    ),
                    const SizedBox(height: 9),
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
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID ${valueText(profile, const ['student_id'])}  •  ${valueText(profile, const ['academic_level'], fallback: 'Daraja belgilanmagan')}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
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
                              ? 'Guruh kutilmoqda'
                              : 'Guruh biriktirilgan',
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
            label: 'profil tayyor',
            icon: Icons.verified_rounded,
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [identity, const SizedBox(height: 20), score],
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
    final name = valueText(parent, const ['full_name'], fallback: fallbackName);
    final active = parent['is_active'] == true;
    final accountLabel = parent['is_active'] == true
        ? 'Faol ota-ona kabineti'
        : parent['is_active'] == false
        ? 'Kabinet nofaol'
        : 'Kabinet holati noma’lum';
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
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HeroEyebrow(
                      icon: Icons.home_rounded,
                      text: 'STARFORGE FAMILY SPACE',
                    ),
                    const SizedBox(height: 9),
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
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      valueText(parent, const [
                        'workplace',
                      ], fallback: 'Ish joyi ko‘rsatilmagan'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
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
                          text: '${children.length} farzand ulangan',
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
            label: 'oila profili',
            icon: Icons.shield_outlined,
            subtitle: valueText(parent, const ['phone']),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [identity, const SizedBox(height: 20), score],
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
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
          Padding(padding: const EdgeInsets.all(20), child: child),
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
  });

  final String label;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 68,
          height: 68,
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
            ),
          ),
        ),
        Positioned(
          right: -3,
          bottom: -3,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, color: Sf.accentInk, size: 17),
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
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
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
  });

  final String value;
  final String label;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
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
  const _IdentityMetricCard({required this.item});

  final _IdentityMetric item;

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
          padding: const EdgeInsets.all(13),
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: item.accent.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: item.accent, size: 17),
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
              const SizedBox(height: 11),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Sf.monoStyle(
                  size: 19,
                  weight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Sf.eyebrow(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                item.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              if (progress != null) ...[
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: colors.onPrimaryContainer),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overline,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$count ta',
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
            for (final group in groups)
              SizedBox(
                width: width,
                child: _IdentityInfoGroupCard(group: group, accent: accent),
              ),
          ],
        );
      },
    );
  }
}

class _IdentityInfoGroupCard extends StatelessWidget {
  const _IdentityInfoGroupCard({required this.group, required this.accent});

  final _IdentityInfoGroup group;
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(group.icon, color: accent, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  group.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < group.fields.length; index++) ...[
            _IdentityDataRow(field: group.fields[index], accent: accent),
            if (index != group.fields.length - 1)
              const Divider(height: 19, indent: 35),
          ],
        ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(field.icon, size: 19, color: accent),
        ),
        const SizedBox(width: 14),
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
    final checks = [
      (
        'Shaxsiy aloqa',
        _filled(profile['phone']) && _filled(profile['email']),
        Icons.contact_phone_outlined,
      ),
      (
        'Guruh biriktiruvi',
        _filled(profile['current_cohort']),
        Icons.groups_2_outlined,
      ),
      (
        'Ta’lim tarixi',
        _filled(profile['previous_school']),
        Icons.history_edu_outlined,
      ),
      (
        'Hudud ma’lumoti',
        _filled(profile['location']),
        Icons.location_on_outlined,
      ),
    ];
    final bars = [
      _PortalBarDatum(
        label: 'Shaxsiy ma’lumotlar',
        value: completeness * 100,
        detail: 'Telefon, email, tug‘ilgan sana va hudud asosida.',
        color: accent,
        icon: Icons.person_outline_rounded,
      ),
      _PortalBarDatum(
        label: 'O‘quv holati',
        value: profile['current_cohort'] == null ? 35 : 100,
        detail: profile['current_cohort'] == null
            ? 'Joriy guruh hali biriktirilmagan.'
            : 'O‘quvchi guruhga to‘liq biriktirilgan.',
        color: Theme.of(context).colorScheme.secondary,
        icon: Icons.school_outlined,
      ),
      _PortalBarDatum(
        label: 'Akkaunt faolligi',
        value: profile['is_blocked'] == true ? 0 : 100,
        detail: profile['is_blocked'] == true
            ? 'Markaz akkauntga cheklov qo‘ygan.'
            : 'Akkaunt faol va ruxsatli xizmatlar ochiq.',
        color: Sf.success,
        icon: Icons.shield_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final ring = _InteractiveRingChart(
          value: completeness,
          label: 'Tayyorlik',
          detail:
              'Asosiy profil maydonlarining ${(completeness * 100).round()}% qismi serverda to‘ldirilgan.',
          color: accent,
          centerIcon: Icons.badge_outlined,
          size: compact ? 106 : 120,
        );
        final checklist = _ProfileChecklist(checks: checks, accent: accent);
        final chart = _CompactBarChart(
          title: 'Profil va o‘qishga tayyorlik',
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
          title: 'Statuslar',
          subtitle: 'O‘quvchi holati bo‘yicha',
          icon: Icons.donut_large_outlined,
          accent: colors.primary,
          entries: statusEntries,
          total: total,
          transformLabel: _statusLabel,
        );
        final branches = _IdentityDistributionCard(
          title: 'Filiallar',
          subtitle: 'Ko‘rinadigan profillar kesimi',
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
              'Taqsimot ma’lumoti mavjud emas',
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
      label: '$label: ${value.round()}, ${(ratio * 100).round()} foiz',
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
                      'Favqulodda kontaktlar',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${contacts.length} ta server yozuvi',
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
    final name = valueText(contact, const [
      'full_name',
      'name',
      'contact_name',
    ], fallback: 'Kontakt ${index + 1}');
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
                    _relationshipLabel(relation),
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
            'Tezkor tekshiruv',
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
                  'Farzand profilini almashtirish',
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
                      '${valueText(child, const ['student_id'])} · ${_ageLabel(child['birthdate'])}',
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
                              ? 'Guruhsiz'
                              : 'Guruh biriktirilgan',
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
              mainAxisSize: MainAxisSize.min,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(completeness * 100).round()}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                    Text(
                      'profil to‘liq',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
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
          Text(
            _statusLabel(text),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
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
    final accent = Theme.of(context).colorScheme.primary;
    final name = valueText(parent, const ['full_name'], fallback: fallbackName);
    final fields = [
      _IdentityField(
        Icons.phone_iphone_rounded,
        'Telefon',
        valueText(parent, const ['phone']),
      ),
      _IdentityField(
        Icons.alternate_email_rounded,
        'Email',
        valueText(parent, const ['email']),
      ),
      _IdentityField(
        Icons.work_outline_rounded,
        'Ish joyi',
        valueText(parent, const ['workplace']),
      ),
      _IdentityField(
        Icons.cake_outlined,
        'Tug‘ilgan sana',
        _dateLabel(parent['birthdate']),
      ),
      _IdentityField(
        Icons.wc_outlined,
        'Jins',
        _genderLabel('${parent['gender'] ?? ''}'),
      ),
      _IdentityField(
        Icons.login_rounded,
        'Oxirgi kirish',
        _dateLabel(parent['last_login_at'], time: true),
      ),
      _IdentityField(
        Icons.alternate_email_rounded,
        'Login',
        valueText(parent, const ['username']),
      ),
      _IdentityField(
        Icons.power_settings_new_rounded,
        'Akkaunt holati',
        _activeAccountLabel(parent['is_active']),
      ),
      _IdentityField(
        Icons.password_rounded,
        'Parol holati',
        _passwordStateLabel(parent['must_change_password']),
      ),
      _IdentityField(
        Icons.event_outlined,
        'Profil yaratilgan',
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
                          'Tasdiqlangan kabinet egasi',
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
        title: 'O‘quvchi akkaunti',
        value: accountReady ? 'Himoyalangan' : 'E’tibor talab qiladi',
        description: child['is_blocked'] == true
            ? valueText(child, const [
                'block_reason',
              ], fallback: 'Akkaunt markaz tomonidan cheklangan.')
            : child['is_active'] == false
            ? 'O‘quvchi akkaunti hozir nofaol.'
            : child['must_change_password'] == true
            ? 'Birinchi kirishda parolni almashtirish kerak.'
            : accountReady
            ? 'Kirish holati va parol talablari joyida.'
            : 'Akkaunt holati bo‘yicha to‘liq ma’lumot mavjud emas.',
        ok: accountReady,
      ),
      (
        icon: hasPrimary
            ? Icons.family_restroom_rounded
            : Icons.person_search_outlined,
        title: 'Asosiy vakil',
        value: hasPrimary ? 'Tasdiqlangan' : 'Belgilanmagan',
        description: guardians.isEmpty
            ? 'Farzandga rasmiy vakil yozuvi bog‘lanmagan.'
            : '${guardians.length} ta vakillik yozuvi mavjud.',
        ok: hasPrimary,
      ),
      (
        icon: activePickups.isNotEmpty
            ? Icons.how_to_reg_rounded
            : Icons.person_off_outlined,
        title: 'Olib ketish',
        value: '${activePickups.length} ta faol',
        description: pickups.isEmpty
            ? 'Olib ketish uchun ruxsatnoma kiritilmagan.'
            : '${pickups.length} ta ruxsat yozuvi tekshirildi.',
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
                      _relationshipLabel('${row['relationship'] ?? ''}'),
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              _SoftStatusBadge(
                text: primary ? 'Asosiy' : 'Qo‘shimcha',
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
            label: 'Farzand',
            value: valueText(row, const ['student_name']),
          ),
          if (_filled(row['custody_notes'])) ...[
            const SizedBox(height: 9),
            _LabeledLine(
              icon: Icons.gavel_outlined,
              label: 'Rasmiy izoh',
              value: '${row['custody_notes']}',
            ),
          ],
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
                text: active ? 'Ruxsat bor' : 'Bekor qilingan',
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
            _relationshipLabel('${row['relationship'] ?? ''}'),
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          if (_filled(row['student_name'])) ...[
            const SizedBox(height: 11),
            _LabeledLine(
              icon: Icons.child_care_outlined,
              label: 'Farzand',
              value: '${row['student_name']}',
            ),
          ],
          const SizedBox(height: 14),
          _LabeledLine(
            icon: Icons.phone_outlined,
            label: 'Telefon',
            value: valueText(row, const ['phone']),
          ),
          const SizedBox(height: 8),
          _LabeledLine(
            icon: Icons.event_outlined,
            label: 'Ruxsat yaratilgan',
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
    final from = _statusLabel('${event['from_status'] ?? ''}');
    final to = _statusLabel('${event['to_status'] ?? ''}');
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
                            from.isEmpty || from == 'Noma’lum'
                                ? to
                                : '$from  →  $to',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (latest)
                          Text(
                            'SO‘NGGI',
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
                        fallback: 'Profil holati markaz tomonidan yangilandi.',
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
        Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: accent, size: 27),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                Text(message, style: TextStyle(color: colors.onSurfaceVariant)),
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

String _availability(Object? value) =>
    _filled(value) ? 'Kiritilgan' : 'Kutilmoqda';

String _activeAccountLabel(Object? raw) => switch (raw) {
  true => 'Faol',
  false => 'Nofaol',
  _ => 'Ma’lumot mavjud emas',
};

String _passwordStateLabel(Object? raw) => switch (raw) {
  true => 'Almashtirish talab qilinadi',
  false => 'Almashtirish talab qilinmaydi',
  _ => 'Ma’lumot mavjud emas',
};

String _genderLabel(String value) => switch (value.toLowerCase()) {
  'male' || 'm' => 'Erkak',
  'female' || 'f' => 'Ayol',
  _ => value.trim().isEmpty ? '—' : value,
};

String _ageLabel(Object? raw) {
  final birthdate = DateTime.tryParse('${raw ?? ''}');
  if (birthdate == null) return 'Yosh ko‘rsatilmagan';
  final now = DateTime.now();
  var age = now.year - birthdate.year;
  if (now.month < birthdate.month ||
      (now.month == birthdate.month && now.day < birthdate.day)) {
    age--;
  }
  return age < 0 ? 'Yosh ko‘rsatilmagan' : '$age yosh';
}

Color _apiColor(Object? raw, Color fallback) {
  final value = '${raw ?? ''}'.trim().replaceFirst('#', '');
  if (value.length != 6) return fallback;
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? fallback : Color(0xFF000000 | parsed);
}

String _relationshipLabel(String value) => switch (value.toLowerCase()) {
  'mother' => 'Ona',
  'father' => 'Ota',
  'grandparent' => 'Buvi yoki buva',
  'legal_guardian' => 'Qonuniy vakil',
  'sibling' => 'Aka, uka, opa yoki singil',
  'aunt' => 'Amma, xola',
  'uncle' => 'Amaki, tog‘a',
  'relative' => 'Qarindosh',
  'family_friend' => 'Oila tanishi',
  _ => value.trim().isEmpty ? 'Vakil' : value,
};

double? _identityDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}');
}

List<MapEntry<String, double>> _mapEntries(Object? raw) {
  if (raw is! Map) return const [];
  final entries = <MapEntry<String, double>>[];
  for (final entry in raw.entries) {
    final value = _identityDouble(entry.value);
    if (value == null || value < 0) continue;
    final key = '${entry.key ?? ''}'.trim();
    entries.add(
      MapEntry(key.isEmpty || key == 'null' ? 'Noma’lum' : key, value),
    );
  }
  entries.sort((a, b) => b.value.compareTo(a.value));
  return entries;
}

String _referenceLabel(Object? raw) {
  if (!_filled(raw)) return 'Biriktirilmagan';
  if (raw is Map) {
    final normalized = raw.map((key, value) => MapEntry('$key', value));
    return valueText(normalized, const [
      'name',
      'title',
      'label',
    ], fallback: 'Biriktirilgan');
  }
  if (raw is num || int.tryParse('$raw'.trim()) != null) {
    return 'Biriktirilgan';
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
