import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import 'staff_surface_widgets.dart';
import 'staff_workspace_models.dart';

enum ReceptionLeadFilter { all, needsAction, trial, admission }

class ReceptionWorkspaceScreen extends StatefulWidget {
  const ReceptionWorkspaceScreen({
    super.key,
    this.role = StaffRole.reception,
    this.canViewLeads,
    this.canManageAdmissions,
    this.store,
    this.onCall,
    this.onOpenLead,
    this.onCreateLead,
  });

  final StaffRole role;
  final bool? canViewLeads;
  final bool? canManageAdmissions;
  final ReceptionWorkspaceStore? store;
  final ValueChanged<String>? onCall;
  final ValueChanged<String>? onOpenLead;
  final VoidCallback? onCreateLead;

  @override
  State<ReceptionWorkspaceScreen> createState() =>
      _ReceptionWorkspaceScreenState();
}

class _ReceptionWorkspaceScreenState extends State<ReceptionWorkspaceScreen> {
  late ReceptionWorkspaceStore _store;
  late bool _ownsStore;
  ReceptionLeadFilter _filter = ReceptionLeadFilter.all;

  @override
  void initState() {
    super.initState();
    _ownsStore = widget.store == null;
    _store = widget.store ?? DemoReceptionWorkspaceStore();
  }

  @override
  void didUpdateWidget(covariant ReceptionWorkspaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store == widget.store) return;
    if (_ownsStore) _store.dispose();
    _ownsStore = widget.store == null;
    _store = widget.store ?? DemoReceptionWorkspaceStore();
  }

  @override
  void dispose() {
    if (_ownsStore) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!(widget.canViewLeads ?? widget.role.can(StaffCapability.viewLeads)) ||
        !(widget.canManageAdmissions ??
            widget.role.can(StaffCapability.manageAdmissions))) {
      return const _ReceptionAccessDenied();
    }

    return StaffPageScaffold(
      eyebrow: 'Qabulxona · Yunusobod',
      title: 'Lidlar va qabul',
      subtitle:
          'Birinchi murojaatdan guruhga joylashgunga qadar bitta sokin oqim',
      actions: [
        StaffIconButton(
          key: const ValueKey('reception-add-lead'),
          icon: SfIcons.plus,
          tooltip: 'Yangi lid qo\u2018shish',
          onPressed: widget.onCreateLead,
        ),
      ],
      body: AnimatedBuilder(
        animation: _store,
        builder: (context, _) => _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return switch (_store.loadState) {
      StaffWorkspaceLoad.loading => const StaffLoadingView(
        label: 'Lidlar yangilanmoqda',
      ),
      StaffWorkspaceLoad.failure => StaffErrorView(
        message:
            _store.errorMessage ??
            'Qabul ma\u2018lumotlarini olib bo\u2018lmadi.',
        onRetry: _store.refresh,
      ),
      StaffWorkspaceLoad.empty => StaffEmptyState(
        title: 'Hozircha lid yo\u2018q',
        message:
            'Yangi murojaat kelganda u shu yerda keyingi aniq qadam bilan ko\u2018rinadi.',
        icon: SfIcons.cohort,
        actionLabel: widget.onCreateLead == null
            ? null
            : 'Birinchi lidni qo\u2018shish',
        onAction: widget.onCreateLead,
      ),
      StaffWorkspaceLoad.ready => _ReceptionReadyBody(
        store: _store,
        filter: _filter,
        onFilterChanged: (value) => setState(() => _filter = value),
        onCall: widget.onCall,
        onOpenLead: widget.onOpenLead,
      ),
    };
  }
}

class _ReceptionReadyBody extends StatelessWidget {
  const _ReceptionReadyBody({
    required this.store,
    required this.filter,
    required this.onFilterChanged,
    this.onCall,
    this.onOpenLead,
  });

  final ReceptionWorkspaceStore store;
  final ReceptionLeadFilter filter;
  final ValueChanged<ReceptionLeadFilter> onFilterChanged;
  final ValueChanged<String>? onCall;
  final ValueChanged<String>? onOpenLead;

  List<ReceptionLeadView> get filtered => store.leads
      .where((lead) {
        return switch (filter) {
          ReceptionLeadFilter.all => true,
          ReceptionLeadFilter.needsAction =>
            lead.stage == LeadStage.newLead ||
                lead.stage == LeadStage.contacted,
          ReceptionLeadFilter.trial => lead.stage == LeadStage.trialBooked,
          ReceptionLeadFilter.admission => lead.stage == LeadStage.tested,
        };
      })
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final leads = store.leads;
    final newCount = leads
        .where((lead) => lead.stage == LeadStage.newLead)
        .length;
    final trialCount = leads
        .where((lead) => lead.stage == LeadStage.trialBooked)
        .length;
    final readyCount = leads
        .where((lead) => lead.stage == LeadStage.tested)
        .length;
    return RefreshIndicator(
      onRefresh: store.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
            sliver: SliverList.list(
              children: [
                StaffAdaptiveGrid(
                  children: [
                    StaffMetricCard(
                      label: 'Yangi murojaat',
                      value: '$newCount',
                      detail: 'Bugun javob kutmoqda',
                      icon: SfIcons.plus,
                      tone: newCount > 0
                          ? StaffMetricTone.danger
                          : StaffMetricTone.success,
                    ),
                    StaffMetricCard(
                      label: 'Sinov darsi',
                      value: '$trialCount',
                      detail: 'Vaqti belgilangan',
                      icon: SfIcons.cal,
                      tone: StaffMetricTone.primary,
                    ),
                    StaffMetricCard(
                      label: 'Qabulga tayyor',
                      value: '$readyCount',
                      detail: 'Guruh tanlash kerak',
                      icon: SfIcons.check,
                      tone: StaffMetricTone.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const StaffHintCard(
                  title: 'Keyingi eng yaxshi qadam',
                  message:
                      'Yangi murojaatga 15 daqiqa ichida javob bering. Har lid kartasida faqat hozir kerak bo\u2018lgan amal ko\u2018rsatiladi.',
                  icon: Icons.route_outlined,
                ),
                if (store.lastRefreshedAt != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_receptionText(context, uz: 'Yangilandi', en: 'Updated')} · ${_receptionTime(store.lastRefreshedAt!)}',
                      key: const ValueKey('reception-refresh-stamp'),
                      style: SfType.mono(
                        size: 10.5,
                        color: SfTheme.colorsOf(context).muted,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const StaffSectionHeader(
                  title: 'Ish navbati',
                  subtitle: 'Holatni bosqichma-bosqich oldinga suring',
                ),
                const SizedBox(height: 10),
                StaffSegment<ReceptionLeadFilter>(
                  values: ReceptionLeadFilter.values,
                  selected: filter,
                  labelOf: (value) => switch (value) {
                    ReceptionLeadFilter.all => 'Hammasi',
                    ReceptionLeadFilter.needsAction => 'Javob kerak',
                    ReceptionLeadFilter.trial => 'Sinov',
                    ReceptionLeadFilter.admission => 'Qabul',
                  },
                  onChanged: onFilterChanged,
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: staffMotionDuration(context),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: filtered.isEmpty
                      ? const StaffEmptyState(
                          key: ValueKey('empty-filter'),
                          title: 'Bu filtrda lid yo\u2018q',
                          message:
                              'Boshqa bosqichni tanlang yoki ro\u2018yxatni pastga tortib yangilang.',
                          icon: SfIcons.filter,
                        )
                      : Column(
                          key: ValueKey(filter),
                          children: [
                            for (final lead in filtered) ...[
                              _LeadCard(
                                lead: lead,
                                store: store,
                                onCall: onCall,
                                onOpen: onOpenLead,
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
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

class _LeadCard extends StatelessWidget {
  const _LeadCard({
    required this.lead,
    required this.store,
    this.onCall,
    this.onOpen,
  });

  final ReceptionLeadView lead;
  final ReceptionWorkspaceStore store;
  final ValueChanged<String>? onCall;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final urgent = lead.stage == LeadStage.newLead;
    final next = lead.stage.next;
    return Semantics(
      container: true,
      label: '${lead.studentName}, ${lead.stage.label}, ${lead.course}',
      child: SfSurfaceCard(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 54,
                    decoration: BoxDecoration(
                      color: urgent ? c.danger : c.primary,
                      borderRadius: SfRadius.pillAll,
                    ),
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
                                lead.studentName,
                                style: SfType.ui(
                                  size: 15,
                                  weight: FontWeight.w800,
                                  color: c.ink,
                                ),
                              ),
                            ),
                            SfPill(
                              tone: urgent
                                  ? SfPillTone.danger
                                  : SfPillTone.primary,
                              label: lead.stage.label,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lead.course,
                          style: SfType.ui(
                            size: 12,
                            weight: FontWeight.w600,
                            color: c.ink2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${lead.guardianName} · ${lead.source}',
                          style: SfType.ui(size: 11, color: c.muted),
                        ),
                        if (lead.lastContactAt != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            '${_receptionText(context, uz: 'So\u2018nggi aloqa', en: 'Last contact')} · ${_receptionTime(lead.lastContactAt!)}',
                            style: SfType.mono(size: 10, color: c.success),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Lid amallari',
                    color: c.surface,
                    onSelected: (value) {
                      if (value == 'assign') {
                        store.assignLead(lead.id, 'Gulnora');
                      }
                      if (value == 'note') {
                        _showNoteSheet(context);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'assign',
                        child: Text('O\u2018zimga biriktirish'),
                      ),
                      PopupMenuItem(
                        value: 'note',
                        child: Text('Izoh qo\u2018shish'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (lead.note != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: SfRadius.smAll,
                ),
                child: Text(
                  '“${lead.note}”',
                  style: SfType.display(size: 14, color: c.ink2, height: 1.25),
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              decoration: BoxDecoration(
                color: c.surface2.withValues(alpha: 0.62),
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    key: ValueKey('call-lead-${lead.id}'),
                    tooltip: 'Qo\u2018ng\u2018iroq qilish',
                    onPressed: onCall == null ? null : () => onCall!(lead.id),
                    icon: const Icon(Icons.call_outlined, size: 19),
                    color: c.primary,
                  ),
                  Expanded(
                    child: TextButton(
                      key: ValueKey('open-lead-${lead.id}'),
                      onPressed: onOpen == null ? null : () => onOpen!(lead.id),
                      child: const Text('Batafsil'),
                    ),
                  ),
                  if (next != null)
                    Expanded(
                      flex: 2,
                      child: SfButton(
                        key: ValueKey('advance-lead-${lead.id}'),
                        label: next.label,
                        trailing: SfIcons.arrowR,
                        fontSize: 12,
                        height: 40,
                        onPressed: () => store.advanceLead(lead.id),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNoteSheet(BuildContext context) async {
    final controller = TextEditingController(text: lead.note);
    final c = SfTheme.colorsOf(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            18 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lid uchun izoh',
                style: SfType.ui(
                  size: 20,
                  weight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Keyingi suhbatda foydali bo\u2018ladigan qisqa va aniq ma\u2018lumot.',
                style: SfType.ui(size: 12, color: c.muted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Izoh',
                  hintText:
                      'Masalan: shanba kuni qayta qo\u2018ng\u2018iroq qilish',
                ),
              ),
              const SizedBox(height: 14),
              SfButton(
                block: true,
                label: 'Izohni saqlash',
                onPressed: () async {
                  await store.addLeadNote(lead.id, controller.text);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
  }
}

String _receptionTime(DateTime value) {
  final local = value.toLocal();
  String two(int part) => part.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
}

String _receptionText(
  BuildContext context, {
  required String uz,
  required String en,
}) => Localizations.maybeLocaleOf(context)?.languageCode == 'uz' ? uz : en;

class _ReceptionAccessDenied extends StatelessWidget {
  const _ReceptionAccessDenied();

  @override
  Widget build(BuildContext context) {
    return const StaffPageScaffold(
      eyebrow: 'Ruxsatlar',
      title: 'Qabulxona',
      subtitle: 'Bu ish maydoni faqat qabul xodimlari uchun',
      body: StaffEmptyState(
        title: 'Kirish cheklangan',
        message:
            'Lidlar va qabul ma\u2018lumotlari sizning rolingizga ochilmagan.',
        icon: SfIcons.shield,
      ),
    );
  }
}
