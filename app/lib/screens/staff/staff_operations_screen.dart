import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/api/backend_core.dart';
import '../../data/models.dart';
import '../../features/operations/staff_operations_controller.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_adaptive_dialog.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_pressable.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_toast.dart';

class StaffOperationsHubScreen extends StatefulWidget {
  const StaffOperationsHubScreen({
    super.key,
    this.role,
    this.canAccess,
    this.showBack = true,
  });

  final StaffRole? role;
  final bool Function(StaffCapability capability)? canAccess;
  final bool showBack;

  @override
  State<StaffOperationsHubScreen> createState() =>
      _StaffOperationsHubScreenState();
}

class _StaffOperationsHubScreenState extends State<StaffOperationsHubScreen> {
  final _search = TextEditingController();
  _StaffServiceCategory? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.maybeOf(context);
    final role = widget.role ?? app?.session?.role;
    bool can(StaffCapability capability) =>
        widget.canAccess?.call(capability) ??
        app?.can(capability) ??
        role?.can(capability) ??
        false;
    final permitted = staffOperationModules
        .where((module) => can(module.requiredCapability))
        .toList(growable: false);
    final query = _search.text.trim().toLowerCase();
    final visible = permitted
        .where((module) {
          final categoryMatches =
              _category == null || _serviceCategory(module.id) == _category;
          final searchMatches =
              query.isEmpty ||
              '${module.title} ${module.description} ${_moduleTitle(context, module)} ${_moduleDescription(context, module)}'
                  .toLowerCase()
                  .contains(query);
          return categoryMatches && searchMatches;
        })
        .toList(growable: false);

    return SfScaffold(
      top: SfNavBar(
        title: _copy(context, 'Xodimlar xizmatlari', 'Staff services'),
        subtitle: _copy(
          context,
          '${permitted.length} ta ruxsat etilgan vosita',
          '${permitted.length} permitted tools',
        ),
        leading: widget.showBack ? const BackButton() : null,
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: app == null
            ? () async => setState(() {})
            : app.retryConnection,
        child: ListView(
          key: const PageStorageKey('staff-services-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _StaffServicesOverview(serviceCount: permitted.length),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('staff-services-search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: _copy(
                  context,
                  'Xizmat yoki vazifani qidiring',
                  'Search a service or task',
                ),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: _copy(context, 'Tozalash', 'Clear search'),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 11),
            _ServiceCategorySelector(
              selected: _category,
              counts: {
                for (final category in _StaffServiceCategory.values)
                  category: permitted
                      .where(
                        (module) => _serviceCategory(module.id) == category,
                      )
                      .length,
              },
              onSelected: (category) => setState(() => _category = category),
            ),
            const SizedBox(height: 18),
            if (visible.isEmpty)
              SfSurfaceCard(
                child: SfEmptyState(
                  compact: true,
                  icon: Icons.search_off_rounded,
                  title: _copy(
                    context,
                    'Mos xizmat topilmadi',
                    'No matching service',
                  ),
                  message: query.isEmpty
                      ? _copy(
                          context,
                          'Bu toifada hisobingizga ochiq xizmat yo‘q.',
                          'No service in this category is open to your account.',
                        )
                      : _copy(
                          context,
                          'Boshqa so‘z bilan qidiring yoki filtrni tozalang.',
                          'Try another phrase or clear the filter.',
                        ),
                  actionLabel: _copy(
                    context,
                    'Filtrni tozalash',
                    'Clear filter',
                  ),
                  onAction: () {
                    _search.clear();
                    setState(() => _category = null);
                  },
                ),
              )
            else
              for (final category in _StaffServiceCategory.values)
                if (visible.any(
                  (module) => _serviceCategory(module.id) == category,
                )) ...[
                  _ServiceCategoryHeader(
                    category: category,
                    count: visible
                        .where(
                          (module) => _serviceCategory(module.id) == category,
                        )
                        .length,
                  ),
                  const SizedBox(height: 9),
                  for (final module in visible.where(
                    (module) => _serviceCategory(module.id) == category,
                  )) ...[
                    _StaffServiceModuleCard(
                      module: module,
                      onPressed: () =>
                          context.push('/staff/operations/${module.id}'),
                    ),
                    const SizedBox(height: 9),
                  ],
                  const SizedBox(height: 8),
                ],
          ],
        ),
      ),
    );
  }
}

enum _StaffServiceCategory { today, learning, people, support }

_StaffServiceCategory _serviceCategory(String id) => switch (id) {
  'rules' ||
  'cover' ||
  'meetings' ||
  'approvals' => _StaffServiceCategory.today,
  'exams' ||
  'grades' ||
  'warnings' ||
  'honor-roll' ||
  'reports' ||
  'risk' ||
  'placement' ||
  'achievements' => _StaffServiceCategory.learning,
  'students' ||
  'teachers' ||
  'campaigns' ||
  'card-scans' => _StaffServiceCategory.people,
  _ => _StaffServiceCategory.support,
};

class _StaffServicesOverview extends StatelessWidget {
  const _StaffServicesOverview({required this.serviceCount});

  final int serviceCount;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Container(
      key: const ValueKey('staff-services-overview'),
      padding: const EdgeInsets.fromLTRB(18, 17, 17, 17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary, c.primaryHover],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: .18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: onPrimary.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.dashboard_customize_rounded,
              color: onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _copy(context, 'SIZNING ISH MARKAZINGIZ', 'YOUR WORK CENTER'),
                  style: SfType.eyebrow(
                    size: 8.5,
                    color: onPrimary.withValues(alpha: .74),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _copy(
                    context,
                    '$serviceCount ta xizmat tayyor',
                    '$serviceCount services ready',
                  ),
                  style: SfType.ui(
                    size: 18,
                    weight: FontWeight.w900,
                    color: onPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _copy(
                    context,
                    'Muhim kundalik ishlar yuqorida. Hisobingizga ruxsat berilmagan bo‘limlar bu yerda umuman ko‘rsatilmaydi.',
                    'Important daily work is first. Tools outside your account permissions are not shown at all.',
                  ),
                  style: SfType.ui(
                    size: 10.5,
                    height: 1.4,
                    color: onPrimary.withValues(alpha: .82),
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

class _ServiceCategorySelector extends StatelessWidget {
  const _ServiceCategorySelector({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final _StaffServiceCategory? selected;
  final Map<_StaffServiceCategory, int> counts;
  final ValueChanged<_StaffServiceCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ServiceFilterChip(
            key: const ValueKey('staff-service-filter-all'),
            selected: selected == null,
            label: _copy(context, 'Barchasi', 'All'),
            count: counts.values.fold(0, (sum, count) => sum + count),
            onTap: () => onSelected(null),
          ),
          for (final category in _StaffServiceCategory.values) ...[
            const SizedBox(width: 7),
            _ServiceFilterChip(
              key: ValueKey('staff-service-filter-${category.name}'),
              selected: selected == category,
              label: _categoryLabel(context, category),
              count: counts[category] ?? 0,
              onTap: () => onSelected(category),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceFilterChip extends StatelessWidget {
  const _ServiceFilterChip({
    super.key,
    required this.selected,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      selected: selected,
      onPressed: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        constraints: const BoxConstraints(minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? c.primary : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: SfType.ui(
                size: 10.5,
                weight: FontWeight.w800,
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : c.ink2,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: .16)
                    : c.surface3,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$count',
                style: SfType.mono(
                  size: 9,
                  weight: FontWeight.w800,
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimary
                      : c.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCategoryHeader extends StatelessWidget {
  const _ServiceCategoryHeader({required this.category, required this.count});

  final _StaffServiceCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      children: [
        Icon(_categoryIcon(category), size: 18, color: c.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            _categoryLabel(context, category),
            style: SfType.ui(size: 14, weight: FontWeight.w900, color: c.ink),
          ),
        ),
        Text(
          '$count',
          style: SfType.mono(size: 11, weight: FontWeight.w800, color: c.muted),
        ),
      ],
    );
  }
}

class _StaffServiceModuleCard extends StatelessWidget {
  const _StaffServiceModuleCard({
    required this.module,
    required this.onPressed,
  });

  final StaffOperationModule module;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final category = _serviceCategory(module.id);
    final tone = _categoryColor(context, category);
    return SfPressable(
      key: ValueKey('staff-operation-module-${module.id}'),
      semanticLabel:
          '${_moduleTitle(context, module)}. ${_moduleDescription(context, module)}',
      onPressed: onPressed,
      haptic: true,
      borderRadius: BorderRadius.circular(19),
      builder: (context, state, _) => AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 82),
        padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
        decoration: BoxDecoration(
          color: state.pressed ? c.surface3 : c.surface,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: state.hovered ? tone.withValues(alpha: .45) : c.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.center,
              child: Icon(_operationIcon(module.id), color: tone, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _moduleTitle(context, module),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SfType.ui(
                            size: 13.5,
                            weight: FontWeight.w900,
                            color: c.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: c.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _moduleDescription(context, module),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SfType.ui(size: 10.5, color: c.muted, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Icon(Icons.chevron_right_rounded, color: c.muted, size: 21),
          ],
        ),
      ),
    );
  }
}

String _categoryLabel(BuildContext context, _StaffServiceCategory category) =>
    switch (category) {
      _StaffServiceCategory.today => _copy(context, 'Bugungi ishlar', 'Today'),
      _StaffServiceCategory.learning => _copy(context, 'Ta’lim', 'Learning'),
      _StaffServiceCategory.people => _copy(context, 'Odamlar', 'People'),
      _StaffServiceCategory.support => _copy(
        context,
        'Markaz',
        'Center support',
      ),
    };

IconData _categoryIcon(_StaffServiceCategory category) => switch (category) {
  _StaffServiceCategory.today => Icons.bolt_rounded,
  _StaffServiceCategory.learning => Icons.school_outlined,
  _StaffServiceCategory.people => Icons.groups_2_outlined,
  _StaffServiceCategory.support => Icons.apartment_rounded,
};

Color _categoryColor(BuildContext context, _StaffServiceCategory category) {
  final c = SfTheme.colorsOf(context);
  return switch (category) {
    _StaffServiceCategory.today => c.primary,
    _StaffServiceCategory.learning => c.ai,
    _StaffServiceCategory.people => c.success,
    _StaffServiceCategory.support => c.accent,
  };
}

String _moduleTitle(BuildContext context, StaffOperationModule module) {
  if (Localizations.localeOf(context).languageCode == 'en') return module.title;
  return switch (module.id) {
    'rules' => 'Tasdiqlanadigan qoidalar',
    'cover' => 'Dars o‘rnini bosish',
    'meetings' => 'Uchrashuvlar',
    'approvals' => 'Mening so‘rovlarim',
    'achievements' => 'Yutuqlar',
    'rewards' => 'Mukofotlar',
    'loans' => 'Xodim qarzlari',
    'procurement' => 'Xaridlar',
    'exams' => 'Imtihonlar',
    'grades' => 'Baholar',
    'warnings' => 'O‘quv signallari',
    'honor-roll' => 'Faxriy ro‘yxat',
    'students' => 'O‘quvchilar',
    'teachers' => 'O‘qituvchilar',
    'payments' => 'To‘lov holati',
    'reports' => 'Hisobotlar',
    'risk' => 'Xavf signallari',
    'placement' => 'Daraja takliflari',
    'campaigns' => 'Kampaniyalar',
    'sales' => 'Sotuvlar',
    'card-scans' => 'Karta skanlari',
    _ => module.title,
  };
}

String _moduleDescription(BuildContext context, StaffOperationModule module) {
  if (Localizations.localeOf(context).languageCode == 'en') {
    return module.description;
  }
  return switch (module.id) {
    'rules' => 'Sizga biriktirilgan qoidalarni o‘qing va tasdiqlang.',
    'cover' => 'Ochiq dars so‘rovlarini ko‘ring va qabul qiling.',
    'meetings' => 'Yaqin uchrashuvlar va ishtirok javobingiz.',
    'approvals' => 'So‘rov va qoplama holatini kuzating.',
    'achievements' => 'Tasdiqlangan e’tirof va rivojlanish tarixi.',
    'rewards' => 'Hisobingizga berilgan mukofotlar.',
    'loans' => 'Qarz qoldig‘i, shartlari va to‘lovlari.',
    'procurement' => 'Xarid so‘rovlari va joriy holati.',
    'exams' => 'Sizning o‘quv rolingizga ochiq imtihonlar.',
    'grades' => 'Ruxsat doirasidagi e’lon qilingan va ishchi baholar.',
    'warnings' =>
      'O‘z vaqtida yordam kerak bo‘lishi mumkin bo‘lgan o‘quvchilar.',
    'honor-roll' => 'Ko‘rinadigan doiradagi yuqori natijali o‘quvchilar.',
    'students' => 'Ta’lim va qabul uchun ruxsatli o‘quvchi yozuvlari.',
    'teachers' => 'Ruxsat doirasidagi ustoz kontaktlari va yozuvlari.',
    'payments' => 'Qabul uchun xavfsiz to‘lov holatlari.',
    'reports' => 'Hisobotlar va rejalashtirilgan ishga tushirishlar.',
    'risk' => 'Server hisoblagan aralashuv signallari.',
    'placement' => 'Ko‘rib chiqiladigan daraja tavsiyalari.',
    'campaigns' => 'Qabul va aloqa kampaniyalari.',
    'sales' => 'Ruxsat doirasidagi sotuv yozuvlari.',
    'card-scans' => 'So‘nggi kirish va davomat karta skanlari.',
    _ => module.description,
  };
}

class StaffOperationModuleScreen extends StatefulWidget {
  const StaffOperationModuleScreen({
    super.key,
    required this.moduleId,
    this.controller,
  });

  final String moduleId;
  final StaffOperationsController? controller;

  @override
  State<StaffOperationModuleScreen> createState() =>
      _StaffOperationModuleScreenState();
}

class _StaffOperationModuleScreenState
    extends State<StaffOperationModuleScreen> {
  final _search = TextEditingController();
  StaffOperationsController? _controller;
  bool _ownsController = false;
  bool _leavingAccessDeniedModule = false;

  StaffOperationModule? get _module =>
      staffOperationModuleById(widget.moduleId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    if (widget.controller != null) {
      _controller = widget.controller;
      return;
    }
    final app = AppScope.of(context);
    final api = app.backendApi;
    final module = _module;
    if (api == null || module == null) return;
    _controller = StaffOperationsController(
      api: api,
      module: module,
      accountTypeSlug: app.session?.accountTypeSlug ?? '',
    );
    _ownsController = true;
    unawaited(_controller!.refresh());
  }

  @override
  void dispose() {
    _search.dispose();
    if (_ownsController) _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final module = _module;
    final controller = _controller;
    if (module == null) {
      return const SfScaffold(
        top: SfNavBar(title: 'Staff service', leading: BackButton()),
        body: SfErrorState(title: 'Unknown staff service'),
      );
    }
    if (controller == null) {
      return SfScaffold(
        top: SfNavBar(
          title: _moduleTitle(context, module),
          leading: const BackButton(),
        ),
        body: SfEmptyState(
          title: _copy(
            context,
            'Server seansi kerak',
            'Server session required',
          ),
          icon: Icons.lock_outline_rounded,
        ),
      );
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.accessDenied) {
          _leaveAccessDeniedModule();
          return const SizedBox.shrink();
        }
        final query = _search.text.trim().toLowerCase();
        final records = controller.records
            .where(
              (record) => query.isEmpty || _searchText(record).contains(query),
            )
            .toList(growable: false);
        return SfScaffold(
          top: SfNavBar(
            title: _moduleTitle(context, module),
            subtitle: controller.loading
                ? _copy(context, 'Yangilanmoqda…', 'Refreshing…')
                : _copy(
                    context,
                    '${records.length} ta yozuv',
                    '${records.length} ${records.length == 1 ? 'item' : 'items'}',
                  ),
            leading: const BackButton(),
            actions: [
              IconButton(
                tooltip: _copy(context, 'Yangilash', 'Refresh'),
                onPressed: controller.loading
                    ? null
                    : () => unawaited(controller.refresh()),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: _body(context, controller, records),
        );
      },
    );
  }

  void _leaveAccessDeniedModule() {
    if (_leavingAccessDeniedModule) return;
    _leavingAccessDeniedModule = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.go('/staff/operations');
      } on Object {
        unawaited(Navigator.of(context).maybePop());
      }
    });
  }

  Widget _body(
    BuildContext context,
    StaffOperationsController controller,
    List<BackendJson> records,
  ) {
    final app = AppScope.of(context);
    if (controller.loading && controller.records.isEmpty) {
      return SfLoadingState(
        label: _copy(context, 'Ma’lumot yuklanmoqda…', 'Loading records…'),
        motionEnabled: !app.settings.reducedMotion,
      );
    }
    if (controller.error != null && controller.records.isEmpty) {
      return controller.available
          ? SfErrorState(
              title: _copy(
                context,
                'Xizmatni yuklab bo‘lmadi',
                'The service could not be loaded',
              ),
              message: controller.error,
              onRetry: controller.refresh,
            )
          : SfEmptyState(
              title: _copy(
                context,
                'Xizmat hozircha mavjud emas',
                'Service temporarily unavailable',
              ),
              message: controller.error,
              icon: Icons.cloud_off_outlined,
              actionLabel: _copy(context, 'Qayta tekshirish', 'Check again'),
              onAction: controller.refresh,
            );
    }
    return RefreshIndicator.adaptive(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: _copy(context, 'Yozuvlarni qidiring', 'Search records'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          if (records.isEmpty)
            _ModuleEmptyCard(
              module: controller.module,
              filtering: _search.text.isNotEmpty,
              onRetry: controller.refresh,
            )
          else
            for (final record in records) ...[
              _OperationRecordCard(
                module: controller.module,
                record: record,
                onPressed: () => _showRecord(context, controller, record),
              ),
              const SizedBox(height: 9),
            ],
          if (controller.hasNext)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: controller.loadingMore
                    ? null
                    : () => unawaited(controller.loadMore()),
                icon: controller.loadingMore
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: Text(_copy(context, 'Ko‘proq', 'Load more')),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showRecord(
    BuildContext context,
    StaffOperationsController controller,
    BackendJson record,
  ) async {
    final app = AppScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        minChildSize: .45,
        maxChildSize: .94,
        builder: (context, scroll) {
          final actions = controller.actionsFor(record);
          final module = controller.module;
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            children: [
              _RecordDetailHeader(module: module, record: record),
              const SizedBox(height: 13),
              SfSurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 7,
                ),
                child: Column(
                  children: [
                    for (final entry in _visibleEntries(record))
                      _DetailRow(
                        label: _fieldLabel(context, entry.key),
                        value: entry.value,
                      ),
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  _copy(context, 'Mavjud amallar', 'Available actions'),
                  style: SfType.ui(
                    size: 13,
                    weight: FontWeight.w900,
                    color: SfTheme.colorsOf(context).ink,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final action in actions)
                      action.destructive
                          ? OutlinedButton.icon(
                              onPressed: () => _runAction(
                                sheetContext,
                                controller,
                                record,
                                action,
                              ),
                              icon: const Icon(Icons.close_rounded),
                              label: Text(_actionLabel(context, action)),
                            )
                          : FilledButton.icon(
                              onPressed: () => _runAction(
                                sheetContext,
                                controller,
                                record,
                                action,
                              ),
                              icon: const Icon(Icons.check_rounded),
                              label: Text(_actionLabel(context, action)),
                            ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _copy(
                  context,
                  'Amal bajarilganda server ruxsati va joriy holat qayta tekshiriladi.',
                  'The server re-checks your permission and the current record state for every action.',
                ),
                style: SfType.ui(
                  size: 10.5,
                  color: SfTheme.colorsOf(context).muted,
                ),
              ),
            ],
          );
        },
      ),
    );
    if (!mounted || !app.isInitialized) return;
  }

  Future<void> _runAction(
    BuildContext sheetContext,
    StaffOperationsController controller,
    BackendJson record,
    StaffRecordAction action,
  ) async {
    final approved = await showSfConfirmDialog(
      sheetContext,
      title: _actionLabel(sheetContext, action),
      message: _copy(
        sheetContext,
        'Bu amal serverga yuboriladi va qaytarib bo‘lmasligi mumkin.',
        'This action is sent to the server and may not be reversible.',
      ),
      confirmLabel: _actionLabel(sheetContext, action),
      destructive: action.destructive,
    );
    if (!approved || !mounted) return;
    try {
      await controller.perform(record, action);
      if (!mounted || !sheetContext.mounted) return;
      Navigator.of(sheetContext).pop();
      SfToast.show(
        context,
        message: _copy(context, 'Server yangilandi', 'Server updated'),
        tone: SfToastTone.success,
      );
    } on Object catch (error) {
      if (sheetContext.mounted) {
        SfToast.show(sheetContext, message: '$error', tone: SfToastTone.error);
      }
    }
  }
}

IconData _operationIcon(String moduleId) => switch (moduleId) {
  'rules' => Icons.rule_outlined,
  'cover' => Icons.event_repeat_outlined,
  'meetings' => Icons.groups_outlined,
  'approvals' => Icons.approval_outlined,
  'achievements' => Icons.emoji_events_outlined,
  'rewards' => Icons.redeem_outlined,
  'loans' => Icons.account_balance_wallet_outlined,
  'procurement' => Icons.shopping_bag_outlined,
  'exams' => Icons.quiz_outlined,
  'grades' => Icons.grading_outlined,
  'warnings' => Icons.warning_amber_rounded,
  'honor-roll' => Icons.workspace_premium_outlined,
  'students' => Icons.school_outlined,
  'teachers' => Icons.co_present_outlined,
  'payments' => Icons.payments_outlined,
  'reports' => Icons.analytics_outlined,
  'risk' => Icons.psychology_outlined,
  'placement' => Icons.move_up_outlined,
  'campaigns' => Icons.campaign_outlined,
  'sales' => Icons.point_of_sale_outlined,
  'card-scans' => Icons.nfc_outlined,
  _ => Icons.dashboard_customize_outlined,
};

class _ModuleEmptyCard extends StatelessWidget {
  const _ModuleEmptyCard({
    required this.module,
    required this.filtering,
    required this.onRetry,
  });

  final StaffOperationModule module;
  final bool filtering;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tone = _categoryColor(context, _serviceCategory(module.id));
    return SfSurfaceCard(
      key: const ValueKey('staff-operation-empty'),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(19),
            ),
            alignment: Alignment.center,
            child: Icon(
              filtering ? Icons.search_off_rounded : _operationIcon(module.id),
              color: tone,
              size: 27,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            filtering
                ? _copy(context, 'Mos natija yo‘q', 'No matching result')
                : _emptyModuleTitle(context, module),
            textAlign: TextAlign.center,
            style: SfType.ui(size: 16, weight: FontWeight.w900, color: c.ink),
          ),
          const SizedBox(height: 6),
          Text(
            filtering
                ? _copy(
                    context,
                    'Qidiruv so‘zini o‘zgartiring yoki maydonni tozalang.',
                    'Try another phrase or clear the search field.',
                  )
                : _emptyModuleMessage(context, module),
            textAlign: TextAlign.center,
            style: SfType.ui(size: 11.5, color: c.muted, height: 1.42),
          ),
          if (!filtering) ...[
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: () => unawaited(onRetry()),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_copy(context, 'Yangilash', 'Refresh')),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordDetailHeader extends StatelessWidget {
  const _RecordDetailHeader({required this.module, required this.record});

  final StaffOperationModule module;
  final BackendJson record;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tone = _categoryColor(context, _serviceCategory(module.id));
    final status = _recordStatus(record);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(17),
          ),
          alignment: Alignment.center,
          child: Icon(_operationIcon(module.id), color: tone, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _recordTitle(context, module, record),
                style: SfType.ui(
                  size: 19,
                  weight: FontWeight.w900,
                  color: c.ink,
                  height: 1.16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _moduleTitle(context, module),
                style: SfType.ui(size: 10.5, color: c.muted),
              ),
            ],
          ),
        ),
        if (status != null) ...[
          const SizedBox(width: 8),
          _RecordStatusChip(status: status),
        ],
      ],
    );
  }
}

class _OperationRecordCard extends StatelessWidget {
  const _OperationRecordCard({
    required this.module,
    required this.record,
    required this.onPressed,
  });

  final StaffOperationModule module;
  final BackendJson record;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tone = _categoryColor(context, _serviceCategory(module.id));
    final status = _recordStatus(record);
    final entries = _summaryEntries(record, module).take(2).toList();
    return SfPressable(
      key: ValueKey(
        'staff-operation-record-${backendString(record['id'], fallback: record.hashCode.toString())}',
      ),
      onPressed: onPressed,
      haptic: true,
      borderRadius: BorderRadius.circular(19),
      builder: (context, state, _) => AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
        decoration: BoxDecoration(
          color: state.pressed ? c.surface3 : c.surface,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: state.hovered ? tone : c.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.center,
              child: Icon(_operationIcon(module.id), color: tone, size: 21),
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
                          _recordTitle(context, module, record),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: SfType.ui(
                            size: 13.5,
                            weight: FontWeight.w900,
                            color: c.ink,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (status != null) ...[
                        const SizedBox(width: 6),
                        _RecordStatusChip(status: status),
                      ],
                    ],
                  ),
                  if (entries.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    for (final entry in entries)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${_fieldLabel(context, entry.key)} · ${_localizedDisplayValue(context, entry.value)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SfType.ui(
                            size: 10.5,
                            color: c.muted,
                            height: 1.25,
                          ),
                        ),
                      ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      _copy(
                        context,
                        'Batafsil ko‘rish uchun oching',
                        'Open to view the details',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SfType.ui(size: 10.5, color: c.muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Icon(
                Icons.chevron_right_rounded,
                color: c.muted,
                size: 21,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: SfType.eyebrow(size: 8.5, color: c.muted),
          ),
          const SizedBox(height: 4),
          SelectableText(
            _localizedDisplayValue(context, value),
            style: SfType.ui(size: 12.5, color: c.ink, height: 1.42),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: c.border),
        ],
      ),
    );
  }
}

class _RecordStatusChip extends StatelessWidget {
  const _RecordStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'active' || 'approved' || 'accepted' || 'completed' || 'low' => c.success,
      'pending' || 'scheduled' || 'medium' || 'open' => c.warn,
      'rejected' || 'declined' || 'cancelled' || 'failed' || 'high' => c.danger,
      _ => c.primary,
    };
    return Container(
      constraints: const BoxConstraints(maxWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _statusLabel(context, status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SfType.ui(size: 8.5, weight: FontWeight.w900, color: color),
      ),
    );
  }
}

Iterable<MapEntry<String, Object?>> _visibleEntries(BackendJson record) =>
    record.entries.where(
      (entry) =>
          !_recordMetadataKeys.contains(entry.key) &&
          !_recordTitleKeys.contains(entry.key) &&
          !_secretKey.hasMatch(entry.key) &&
          entry.value != null &&
          _displayValue(entry.value).isNotEmpty,
    );

Iterable<MapEntry<String, Object?>> _summaryEntries(
  BackendJson record,
  StaffOperationModule module,
) sync* {
  final preferred = switch (module.id) {
    'risk' => const ['score', 'flags', 'cohort'],
    'meetings' => const ['starts_at', 'location', 'response'],
    'cover' => const ['starts_at', 'cohort_name', 'room_name'],
    'approvals' => const ['request_type', 'amount', 'created_at'],
    'loans' => const ['balance', 'amount', 'status'],
    'payments' => const ['amount', 'status', 'due_at'],
    _ => const <String>[],
  };
  final visible = _visibleEntries(record)
      .where((entry) => entry.key != 'status' && entry.key != 'level')
      .toList(growable: false);
  final yielded = <String>{};
  for (final key in preferred) {
    final entry = visible.where((item) => item.key == key).firstOrNull;
    if (entry != null && yielded.add(entry.key)) yield entry;
  }
  for (final entry in visible) {
    if (yielded.add(entry.key)) yield entry;
  }
}

const _recordMetadataKeys = {
  'id',
  'count',
  'page',
  'page_size',
  'pages',
  'total_pages',
  'next',
  'previous',
  'has_next',
  'has_previous',
};

const _recordTitleKeys = {
  'title',
  'name',
  'label',
  'student_name',
  'teacher_name',
  'full_name',
  'cohort_name',
  'subject_name',
  'rule_title',
  'request_title',
};

final _secretKey = RegExp(
  r'(password|secret|token|credential|private_key)',
  caseSensitive: false,
);

String _recordTitle(
  BuildContext context,
  StaffOperationModule module,
  BackendJson record,
) {
  for (final key in const [
    'title',
    'name',
    'label',
    'student_name',
    'teacher_name',
    'full_name',
    'cohort_name',
    'subject_name',
    'rule_title',
    'request_title',
    'feature',
    'kind',
  ]) {
    final value = backendString(record[key]);
    if (value.isNotEmpty) return value;
  }
  final student = backendString(record['student']);
  if (student.isNotEmpty) {
    return _copy(context, 'O‘quvchi #$student', 'Student #$student');
  }
  final id = backendString(record['id']);
  if (id.isNotEmpty) {
    return _copy(context, 'Yozuv #$id', 'Item #$id');
  }
  return _copy(
    context,
    '${_moduleTitle(context, module)} tafsiloti',
    '${_moduleTitle(context, module)} detail',
  );
}

String? _recordStatus(BackendJson record) {
  for (final key in const ['status', 'level', 'state']) {
    final value = backendString(record[key]);
    if (value.isNotEmpty) return value;
  }
  return null;
}

String _searchText(BackendJson record) => record.entries
    .where((entry) => !_secretKey.hasMatch(entry.key))
    .map((entry) => _displayValue(entry.value).toLowerCase())
    .join(' ');

String _displayValue(Object? value) {
  if (value == null) return '';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is List) {
    return value.map(_displayValue).where((item) => item.isNotEmpty).join(', ');
  }
  if (value is Map) {
    final map = backendMap(value);
    return map.entries
        .where((entry) => !_secretKey.hasMatch(entry.key))
        .take(6)
        .map(
          (entry) => '${_humanize(entry.key)}: ${_displayValue(entry.value)}',
        )
        .join(' · ');
  }
  final text = value.toString();
  final date = DateTime.tryParse(text);
  if (date != null && text.contains('-')) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
  return text;
}

String _localizedDisplayValue(BuildContext context, Object? value) {
  if (value == null) return '—';
  if (value is bool) {
    return value ? _copy(context, 'Ha', 'Yes') : _copy(context, 'Yo‘q', 'No');
  }
  if (value is List) {
    if (value.isEmpty) return '—';
    final items = value
        .map((item) {
          final map = backendMap(item);
          if (map.isNotEmpty) {
            final reason = backendString(
              map['reason'],
              fallback: backendString(
                map['label'],
                fallback: backendString(map['name']),
              ),
            );
            if (reason.isNotEmpty) return '• $reason';
          }
          return _localizedDisplayValue(context, item);
        })
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return items.isEmpty ? '—' : items.join('\n');
  }
  if (value is Map) {
    final map = backendMap(value);
    if (map.isEmpty) return '—';
    return map.entries
        .where(
          (entry) => !_secretKey.hasMatch(entry.key) && entry.value != null,
        )
        .take(8)
        .map(
          (entry) =>
              '${_fieldLabel(context, entry.key)}: ${_localizedDisplayValue(context, entry.value)}',
        )
        .join('\n');
  }
  final text = value.toString();
  final date = DateTime.tryParse(text);
  if (date != null && text.contains('-')) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month.${local.year} · $hour:$minute';
  }
  return _statusLabel(context, text);
}

String _fieldLabel(BuildContext context, String key) => switch (key) {
  'student' || 'student_id' => _copy(context, 'O‘quvchi', 'Student'),
  'teacher' || 'teacher_id' => _copy(context, 'O‘qituvchi', 'Teacher'),
  'cohort' || 'cohort_id' => _copy(context, 'Guruh', 'Group'),
  'branch' || 'branch_id' => _copy(context, 'Filial', 'Branch'),
  'subject' || 'subject_id' => _copy(context, 'Fan', 'Subject'),
  'score' => _copy(context, 'Xavf bali', 'Risk score'),
  'level' => _copy(context, 'Daraja', 'Level'),
  'flags' => _copy(context, 'Sabablar', 'Reasons'),
  'reason' => _copy(context, 'Sabab', 'Reason'),
  'status' || 'state' => _copy(context, 'Holat', 'Status'),
  'starts_at' || 'start_at' => _copy(context, 'Boshlanishi', 'Starts'),
  'ends_at' || 'end_at' => _copy(context, 'Tugashi', 'Ends'),
  'due_at' || 'due_date' => _copy(context, 'Muddat', 'Due'),
  'created_at' => _copy(context, 'Yaratilgan', 'Created'),
  'updated_at' => _copy(context, 'Yangilangan', 'Updated'),
  'note' || 'notes' => _copy(context, 'Izoh', 'Note'),
  'description' => _copy(context, 'Tavsif', 'Description'),
  'amount' => _copy(context, 'Miqdor', 'Amount'),
  'currency' => _copy(context, 'Valyuta', 'Currency'),
  'phone' => _copy(context, 'Telefon', 'Phone'),
  'email' => 'Email',
  'response' => _copy(context, 'Javob', 'Response'),
  _ => _humanize(key),
};

String _statusLabel(BuildContext context, String status) {
  final normalized = status.trim().toLowerCase();
  return switch (normalized) {
    'active' => _copy(context, 'Faol', 'Active'),
    'approved' => _copy(context, 'Tasdiqlangan', 'Approved'),
    'accepted' => _copy(context, 'Qabul qilingan', 'Accepted'),
    'completed' || 'done' => _copy(context, 'Tugallangan', 'Completed'),
    'pending' => _copy(context, 'Kutilmoqda', 'Pending'),
    'scheduled' => _copy(context, 'Rejalashtirilgan', 'Scheduled'),
    'open' => _copy(context, 'Ochiq', 'Open'),
    'rejected' => _copy(context, 'Rad etilgan', 'Rejected'),
    'declined' => _copy(context, 'Qabul qilinmagan', 'Declined'),
    'cancelled' || 'canceled' => _copy(context, 'Bekor qilingan', 'Cancelled'),
    'failed' => _copy(context, 'Xato', 'Failed'),
    'low' => _copy(context, 'Past', 'Low'),
    'medium' => _copy(context, 'O‘rta', 'Medium'),
    'high' => _copy(context, 'Yuqori', 'High'),
    _ => status,
  };
}

String _actionLabel(BuildContext context, StaffRecordAction action) =>
    switch (action.id) {
      'acknowledge' => _copy(context, 'Tasdiqlash', 'Acknowledge'),
      'claim' => _copy(context, 'Darsni qabul qilish', 'Claim lesson'),
      'cancel' => _copy(context, 'Bekor qilish', 'Cancel'),
      'accept' => _copy(context, 'Qatnashaman', 'Accept'),
      'decline' => _copy(context, 'Qatnashmayman', 'Decline'),
      _ => action.label,
    };

String _emptyModuleTitle(
  BuildContext context,
  StaffOperationModule module,
) => switch (module.id) {
  'rules' => _copy(
    context,
    'Tasdiqlanadigan qoida yo‘q',
    'No rules to acknowledge',
  ),
  'cover' => _copy(context, 'Ochiq dars so‘rovi yo‘q', 'No open lesson cover'),
  'meetings' => _copy(context, 'Yaqin uchrashuv yo‘q', 'No upcoming meetings'),
  'approvals' => _copy(context, 'Faol so‘rov yo‘q', 'No active requests'),
  'risk' => _copy(
    context,
    'Hozircha xavf signali yo‘q',
    'No risk signals right now',
  ),
  'warnings' => _copy(context, 'O‘quv signali yo‘q', 'No academic warnings'),
  _ => _copy(context, 'Hozircha yozuv yo‘q', 'Nothing here yet'),
};

String _emptyModuleMessage(
  BuildContext context,
  StaffOperationModule module,
) => _copy(
  context,
  '${_moduleDescription(context, module)} Yangi ma’lumot kelganda shu yerda ko‘rinadi.',
  '${_moduleDescription(context, module)} New items will appear here automatically.',
);

String _humanize(String key) {
  final words = key.replaceAll('_', ' ').trim();
  if (words.isEmpty) return key;
  return '${words[0].toUpperCase()}${words.substring(1)}';
}

String _copy(BuildContext context, String uz, String en) {
  final code = Localizations.localeOf(context).languageCode;
  return code == 'en' ? en : uz;
}
