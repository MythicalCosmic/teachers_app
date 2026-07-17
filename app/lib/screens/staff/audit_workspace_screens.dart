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

SfPillTone _severityTone(AuditSeverity severity) => switch (severity) {
  AuditSeverity.low => SfPillTone.neutral,
  AuditSeverity.medium => SfPillTone.warn,
  AuditSeverity.high || AuditSeverity.critical => SfPillTone.danger,
};

StaffMetricTone _severityMetricTone(AuditSeverity severity) =>
    switch (severity) {
      AuditSeverity.low => StaffMetricTone.neutral,
      AuditSeverity.medium => StaffMetricTone.warning,
      AuditSeverity.high || AuditSeverity.critical => StaffMetricTone.danger,
    };

String _severityLabel(AuditSeverity severity) => switch (severity) {
  AuditSeverity.low => 'Past',
  AuditSeverity.medium => 'O\u2018rta',
  AuditSeverity.high => 'Yuqori',
  AuditSeverity.critical => 'Jiddiy',
};

String _caseStatusLabel(AuditCaseStatus status) => switch (status) {
  AuditCaseStatus.open => 'Ochiq',
  AuditCaseStatus.investigating => 'Tekshiruvda',
  AuditCaseStatus.resolved => 'Hal qilindi',
  AuditCaseStatus.dismissed => 'Yopildi',
};

class AuditorDashboardScreen extends StatelessWidget {
  const AuditorDashboardScreen({
    super.key,
    this.role = StaffRole.auditor,
    this.anomalies = const [],
    this.cases = const [],
    this.onOpenSignals,
    this.onOpenCases,
    this.onOpenAuditLog,
    this.onOpenSignal,
    this.onRefresh,
  });

  final StaffRole role;
  final List<AuditAnomaly> anomalies;
  final List<AuditCase> cases;
  final VoidCallback? onOpenSignals;
  final VoidCallback? onOpenCases;
  final VoidCallback? onOpenAuditLog;
  final ValueChanged<String>? onOpenSignal;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (!role.can(StaffCapability.viewAuditWorkspace)) {
      return const _AuditAccessDenied();
    }
    final openSignals = anomalies
        .where((item) => item.status == AnomalyStatus.open)
        .length;
    final critical = anomalies
        .where(
          (item) =>
              item.severity == AuditSeverity.critical ||
              item.severity == AuditSeverity.high,
        )
        .length;
    final activeCases = cases
        .where(
          (item) =>
              item.status == AuditCaseStatus.open ||
              item.status == AuditCaseStatus.investigating,
        )
        .length;
    return StaffPageScaffold(
      eyebrow: 'Audit · barcha filiallar',
      title: 'Nazorat markazi',
      subtitle:
          'Manba yozuvlari o\u2018zgarmaydi; tekshiruv ishi holatlar orqali yuritiladi',
      actions: [
        StaffIconButton(
          icon: SfIcons.doc,
          tooltip: 'O\u2018zgarmas jurnal',
          onPressed: onOpenAuditLog,
        ),
      ],
      body: RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const StaffReadOnlyBanner(
              message:
                  'Signal manbalari faqat o\u2018qiladi · holatlar tahrirlanadi',
            ),
            const SizedBox(height: 12),
            StaffAdaptiveGrid(
              children: [
                StaffMetricCard(
                  label: 'Ochiq signal',
                  value: '$openSignals',
                  detail: 'Ko\u2018rib chiqilmagan',
                  icon: SfIcons.flag,
                  tone: openSignals > 0
                      ? StaffMetricTone.danger
                      : StaffMetricTone.success,
                  onTap: onOpenSignals,
                ),
                StaffMetricCard(
                  label: 'Yuqori daraja',
                  value: '$critical',
                  detail: 'Ustuvor tekshiruv',
                  icon: SfIcons.shield,
                  tone: StaffMetricTone.warning,
                  onTap: onOpenSignals,
                ),
                StaffMetricCard(
                  label: 'Faol holat',
                  value: '$activeCases',
                  detail: 'Ish yuritilmoqda',
                  icon: SfIcons.pin,
                  tone: StaffMetricTone.primary,
                  onTap: onOpenCases,
                ),
                const StaffMetricCard(
                  label: 'Yaxlitlik',
                  value: '100%',
                  detail: 'Jurnal zanjiri tasdiqlangan',
                  icon: Icons.verified_user_outlined,
                  tone: StaffMetricTone.success,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const StaffHintCard(
              title: 'Tavsiya etilgan tartib',
              message:
                  'Avval signal dalillarini o\u2018qing, keyin mavjud holatga ulang yoki yangi holat oching. Manba maydonlari hech qachon shu ekrandan o\u2018zgarmaydi.',
              icon: Icons.account_tree_outlined,
            ),
            const SizedBox(height: 20),
            StaffSectionHeader(
              title: 'Ustuvor signallar',
              subtitle: 'Yuqori va jiddiy daraja',
              trailing: TextButton(
                onPressed: onOpenSignals,
                child: const Text('Hammasi'),
              ),
            ),
            const SizedBox(height: 10),
            if (anomalies.isEmpty)
              const StaffEmptyState(
                title: 'Signal yo\u2018q',
                message:
                    'Hozircha tekshiruv talab qiladigan signal aniqlanmadi.',
                icon: SfIcons.check,
              )
            else
              SfSurfaceCard(
                child: Column(
                  children: [
                    for (var i = 0; i < anomalies.take(4).length; i++) ...[
                      _AnomalyRow(
                        anomaly: anomalies[i],
                        onTap: onOpenSignal == null
                            ? null
                            : () => onOpenSignal!(anomalies[i].id),
                      ),
                      if (i < anomalies.take(4).length - 1)
                        const Divider(height: 1),
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

enum AuditSignalFilter { open, highRisk, acknowledged, all }

class AuditSignalsScreen extends StatefulWidget {
  const AuditSignalsScreen({
    super.key,
    this.role = StaffRole.auditor,
    this.anomalies = const [],
    this.onOpenSignal,
    this.onAcknowledge,
    this.onRefresh,
  });

  final StaffRole role;
  final List<AuditAnomaly> anomalies;
  final ValueChanged<String>? onOpenSignal;
  final Future<void> Function(String anomalyId)? onAcknowledge;
  final Future<void> Function()? onRefresh;

  @override
  State<AuditSignalsScreen> createState() => _AuditSignalsScreenState();
}

class _AuditSignalsScreenState extends State<AuditSignalsScreen> {
  AuditSignalFilter _filter = AuditSignalFilter.open;

  @override
  Widget build(BuildContext context) {
    if (!widget.role.can(StaffCapability.reviewAnomalies)) {
      return const _AuditAccessDenied();
    }
    final filtered = widget.anomalies
        .where(
          (item) => switch (_filter) {
            AuditSignalFilter.open => item.status == AnomalyStatus.open,
            AuditSignalFilter.highRisk =>
              item.severity == AuditSeverity.high ||
                  item.severity == AuditSeverity.critical,
            AuditSignalFilter.acknowledged =>
              item.status == AnomalyStatus.acknowledged ||
                  item.status == AnomalyStatus.linked,
            AuditSignalFilter.all => true,
          },
        )
        .toList();
    return StaffPageScaffold(
      eyebrow: 'Audit · signal navbati',
      title: 'Anomaliyalar',
      subtitle:
          'Dalilni ko\u2018ring, qabul qilinganini belgilang yoki holatga ulang',
      body: RefreshIndicator(
        onRefresh: widget.onRefresh ?? () async {},
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const StaffReadOnlyBanner(),
            const SizedBox(height: 12),
            StaffSegment<AuditSignalFilter>(
              values: AuditSignalFilter.values,
              selected: _filter,
              labelOf: (value) => switch (value) {
                AuditSignalFilter.open => 'Ochiq',
                AuditSignalFilter.highRisk => 'Yuqori xavf',
                AuditSignalFilter.acknowledged => 'Ko\u2018rilgan',
                AuditSignalFilter.all => 'Hammasi',
              },
              onChanged: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: staffMotionDuration(context),
              child: filtered.isEmpty
                  ? const StaffEmptyState(
                      key: ValueKey('empty-signals'),
                      title: 'Bu filtrda signal yo\u2018q',
                      message:
                          'Boshqa filtrni tanlang yoki ro\u2018yxatni yangilang.',
                      icon: SfIcons.check,
                    )
                  : Column(
                      key: ValueKey(_filter),
                      children: [
                        for (final anomaly in filtered) ...[
                          SfSurfaceCard(
                            child: Column(
                              children: [
                                _AnomalyRow(
                                  anomaly: anomaly,
                                  onTap: widget.onOpenSignal == null
                                      ? null
                                      : () => widget.onOpenSignal!(anomaly.id),
                                ),
                                if (anomaly.status == AnomalyStatus.open)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      0,
                                      14,
                                      12,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: widget.onAcknowledge == null
                                            ? null
                                            : () => widget.onAcknowledge!(
                                                anomaly.id,
                                              ),
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Ko\u2018rib chiqildi',
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
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

class AuditSignalDetailScreen extends StatelessWidget {
  const AuditSignalDetailScreen({
    super.key,
    this.role = StaffRole.auditor,
    required this.anomaly,
    this.onBack,
    this.onAcknowledge,
    this.onCreateCase,
  });

  final StaffRole role;
  final AuditAnomaly anomaly;
  final VoidCallback? onBack;
  final Future<void> Function(String anomalyId)? onAcknowledge;
  final Future<void> Function(AuditAnomaly anomaly)? onCreateCase;

  @override
  Widget build(BuildContext context) {
    if (!role.can(StaffCapability.reviewAnomalies)) {
      return const _AuditAccessDenied();
    }
    final c = SfTheme.colorsOf(context);
    return StaffPageScaffold(
      eyebrow: 'Signal · ${anomaly.id}',
      title: anomaly.title,
      subtitle:
          '${anomaly.entityLabel} · ${_severityLabel(anomaly.severity)} daraja',
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(SfIcons.arrowL),
        tooltip: 'Orqaga',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const StaffReadOnlyBanner(
            message: 'Aniqlangan manba va dalil maydonlari tahrirlanmaydi',
          ),
          const SizedBox(height: 12),
          SfSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SfPill(
                      tone: _severityTone(anomaly.severity),
                      label: _severityLabel(anomaly.severity),
                    ),
                    const Spacer(),
                    Text(
                      anomaly.status.name,
                      style: SfType.mono(size: 10.5, color: c.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Nima aniqlandi',
                  style: SfType.ui(
                    size: 15,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  anomaly.description,
                  style: SfType.ui(size: 13, color: c.ink2, height: 1.5),
                ),
                const SizedBox(height: 16),
                const Divider(),
                _DetailLine(label: 'Manba obyekti', value: anomaly.entityLabel),
                _DetailLine(
                  label: 'Aniqlangan vaqt',
                  value: _dateTime(anomaly.detectedAt),
                ),
                _DetailLine(label: 'Signal ID', value: anomaly.id, mono: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const StaffHintCard(
            title: 'Keyingi qadam',
            message:
                'Qabul qilish signalni o\u2018zgartirmaydi — faqat auditor ko\u2018rganini qayd etadi. Tekshiruv izohlari holatda saqlanadi.',
            icon: Icons.rule_folder_outlined,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (anomaly.status == AnomalyStatus.open)
                Expanded(
                  child: SfButton(
                    kind: SfButtonKind.ghost,
                    label: 'Ko\u2018rib chiqildi',
                    leading: Icons.visibility_outlined,
                    onPressed: onAcknowledge == null
                        ? null
                        : () => onAcknowledge!(anomaly.id),
                  ),
                ),
              if (anomaly.status == AnomalyStatus.open)
                const SizedBox(width: 8),
              Expanded(
                child: SfButton(
                  label: 'Holat ochish',
                  leading: SfIcons.plus,
                  onPressed: onCreateCase == null
                      ? null
                      : () => onCreateCase!(anomaly),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AuditCasesScreen extends StatefulWidget {
  const AuditCasesScreen({
    super.key,
    this.role = StaffRole.auditor,
    this.cases = const [],
    this.onOpenCase,
    this.onCreateCase,
  });

  final StaffRole role;
  final List<AuditCase> cases;
  final ValueChanged<String>? onOpenCase;
  final VoidCallback? onCreateCase;

  @override
  State<AuditCasesScreen> createState() => _AuditCasesScreenState();
}

class _AuditCasesScreenState extends State<AuditCasesScreen> {
  AuditCaseStatus? _status;

  @override
  Widget build(BuildContext context) {
    if (!widget.role.can(StaffCapability.manageAuditCases)) {
      return const _AuditAccessDenied();
    }
    final filtered = _status == null
        ? widget.cases
        : widget.cases.where((item) => item.status == _status).toList();
    return StaffPageScaffold(
      eyebrow: 'Audit · ish yuritish',
      title: 'Holatlar',
      subtitle:
          'Dalillar, izohlar va qarorlar uchun yoziladigan audit ish maydoni',
      actions: [
        StaffIconButton(
          icon: SfIcons.plus,
          tooltip: 'Yangi holat',
          onPressed: widget.onCreateCase,
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          StaffSegment<AuditCaseStatus?>(
            values: [null, ...AuditCaseStatus.values],
            selected: _status,
            labelOf: (value) =>
                value == null ? 'Hammasi' : _caseStatusLabel(value),
            onChanged: (value) => setState(() => _status = value),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            StaffEmptyState(
              title: 'Holat yo\u2018q',
              message: _status == null
                  ? 'Birinchi holatni signal ichidan yoki + tugmasi orqali oching.'
                  : 'Bu holatda ish yo\u2018q.',
              icon: SfIcons.pin,
              actionLabel: widget.onCreateCase == null ? null : 'Holat ochish',
              onAction: widget.onCreateCase,
            )
          else
            for (final auditCase in filtered) ...[
              _CaseCard(
                auditCase: auditCase,
                onTap: widget.onOpenCase == null
                    ? null
                    : () => widget.onOpenCase!(auditCase.id),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class AuditCaseDetailScreen extends StatefulWidget {
  const AuditCaseDetailScreen({
    super.key,
    this.role = StaffRole.auditor,
    required this.auditCase,
    this.onBack,
    this.onAddNote,
    this.onSetStatus,
  });

  final StaffRole role;
  final AuditCase auditCase;
  final VoidCallback? onBack;
  final Future<void> Function(String caseId, String note)? onAddNote;
  final Future<void> Function(String caseId, AuditCaseStatus status)?
  onSetStatus;

  @override
  State<AuditCaseDetailScreen> createState() => _AuditCaseDetailScreenState();
}

class _AuditCaseDetailScreenState extends State<AuditCaseDetailScreen> {
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.role.can(StaffCapability.manageAuditCases)) {
      return const _AuditAccessDenied();
    }
    final item = widget.auditCase;
    final c = SfTheme.colorsOf(context);
    return StaffPageScaffold(
      eyebrow: 'Holat · ${item.id}',
      title: item.title,
      subtitle:
          '${_caseStatusLabel(item.status)} · ${item.anomalyIds.length} signal bog\u2018langan',
      leading: IconButton(
        onPressed: widget.onBack,
        icon: const Icon(SfIcons.arrowL),
        tooltip: 'Orqaga',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          SfSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SfPill(
                      tone: _severityTone(item.severity),
                      label: _severityLabel(item.severity),
                    ),
                    const Spacer(),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<AuditCaseStatus>(
                        value: item.status,
                        onChanged: widget.onSetStatus == null
                            ? null
                            : (value) {
                                if (value != null) {
                                  widget.onSetStatus!(item.id, value);
                                }
                              },
                        items: [
                          for (final status in AuditCaseStatus.values)
                            DropdownMenuItem(
                              value: status,
                              child: Text(_caseStatusLabel(status)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.description,
                  style: SfType.ui(size: 13, color: c.ink2, height: 1.5),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ochildi · ${_dateTime(item.openedAt)}',
                  style: SfType.ui(size: 11, color: c.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StaffSectionHeader(
            title: 'Tekshiruv qaydlari',
            subtitle: '${item.notes.length} ta qayd',
          ),
          const SizedBox(height: 10),
          if (item.notes.isEmpty)
            const StaffEmptyState(
              title: 'Qayd yo\u2018q',
              message:
                  'Birinchi tekshiruv natijasini pastdagi maydonga yozing.',
              icon: SfIcons.edit,
            )
          else
            SfSurfaceCard(
              child: Column(
                children: [
                  for (var i = 0; i < item.notes.length; i++) ...[
                    StaffStatusRow(
                      icon: SfIcons.doc,
                      title: 'Audit qaydi ${i + 1}',
                      subtitle: item.notes[i],
                      tone: StaffMetricTone.primary,
                    ),
                    if (i < item.notes.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Yangi qayd',
              hintText: 'Dalil, suhbat yoki qarorni aniq yozing',
            ),
          ),
          const SizedBox(height: 10),
          SfButton(
            block: true,
            label: _saving ? 'Saqlanmoqda…' : 'Qaydni saqlash',
            leading: SfIcons.plus,
            onPressed:
                _saving || widget.onAddNote == null || _note.text.trim().isEmpty
                ? null
                : _saveNote,
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote() async {
    setState(() => _saving = true);
    await widget.onAddNote!(widget.auditCase.id, _note.text.trim());
    _note.clear();
    if (mounted) setState(() => _saving = false);
  }
}

class ImmutableAuditLogScreen extends StatefulWidget {
  const ImmutableAuditLogScreen({
    super.key,
    this.role = StaffRole.auditor,
    this.events = const [],
    this.onExport,
  });

  final StaffRole role;
  final List<ImmutableAuditEventView> events;
  final Future<void> Function()? onExport;

  @override
  State<ImmutableAuditLogScreen> createState() =>
      _ImmutableAuditLogScreenState();
}

class _ImmutableAuditLogScreenState extends State<ImmutableAuditLogScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    if (!widget.role.can(StaffCapability.viewImmutableAuditLog)) {
      return const _AuditAccessDenied();
    }
    final matches = widget.events
        .where(
          (event) => '${event.actor} ${event.action} ${event.entity}'
              .toLowerCase()
              .contains(_query.toLowerCase()),
        )
        .toList();
    return StaffPageScaffold(
      eyebrow: 'Audit · yaxlitlik zanjiri',
      title: 'O\u2018zgarmas jurnal',
      subtitle: 'Vaqt, aktyor va amal ketma-ketligi · yozuvlar tahrirlanmaydi',
      actions: [
        StaffIconButton(
          icon: SfIcons.download,
          tooltip: 'Jurnalni eksport qilish',
          onPressed: widget.role.can(StaffCapability.exportAuditData)
              ? widget.onExport
              : null,
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const StaffReadOnlyBanner(
            message:
                'Jurnal append-only · mavjud yozuvni o\u2018zgartirish yoki o\u2018chirish mumkin emas',
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(SfIcons.search),
              labelText: 'Jurnaldan qidirish',
              hintText: 'Aktyor, amal yoki obyekt',
            ),
          ),
          const SizedBox(height: 12),
          if (matches.isEmpty)
            StaffEmptyState(
              title: widget.events.isEmpty
                  ? 'Jurnal hali bo\u2018sh'
                  : 'Mos yozuv topilmadi',
              message: widget.events.isEmpty
                  ? 'Birinchi audit amali bajarilganda kriptografik iz shu yerda paydo bo\u2018ladi.'
                  : 'Qidiruv so\u2018zini qisqartirib ko\u2018ring.',
              icon: SfIcons.doc,
            )
          else
            SfSurfaceCard(
              child: Column(
                children: [
                  for (var i = 0; i < matches.length; i++) ...[
                    _AuditEventRow(event: matches[i]),
                    if (i < matches.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AnomalyRow extends StatelessWidget {
  const _AnomalyRow({required this.anomaly, this.onTap});
  final AuditAnomaly anomaly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => StaffStatusRow(
    icon: SfIcons.flag,
    title: anomaly.title,
    subtitle: '${anomaly.entityLabel} · ${_dateTime(anomaly.detectedAt)}',
    tone: _severityMetricTone(anomaly.severity),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SfPill(
          tone: _severityTone(anomaly.severity),
          label: _severityLabel(anomaly.severity),
        ),
        const SizedBox(width: 4),
        const Icon(SfIcons.chevR, size: 17),
      ],
    ),
    onTap: onTap,
  );
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.auditCase, this.onTap});
  final AuditCase auditCase;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: SfRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SfPill(
                    tone: _severityTone(auditCase.severity),
                    label: _severityLabel(auditCase.severity),
                  ),
                  const Spacer(),
                  SfPill(
                    tone: SfPillTone.primary,
                    label: _caseStatusLabel(auditCase.status),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                auditCase.title,
                style: SfType.ui(
                  size: 15,
                  weight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                auditCase.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SfType.ui(size: 11.5, color: c.muted, height: 1.35),
              ),
              const SizedBox(height: 10),
              Text(
                '${auditCase.anomalyIds.length} signal · ${auditCase.notes.length} qayd',
                style: SfType.mono(size: 10.5, color: c.ink2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditEventRow extends StatelessWidget {
  const _AuditEventRow({required this.event});
  final ImmutableAuditEventView event;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, size: 19, color: c.success),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.action,
                  style: SfType.ui(
                    size: 13,
                    weight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${event.actor} · ${event.entity}',
                  style: SfType.ui(size: 11.5, color: c.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  event.integrityHash,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SfType.mono(size: 9.5, color: c.muted),
                ),
              ],
            ),
          ),
          Text(
            _dateTime(event.occurredAt),
            style: SfType.mono(size: 9.5, color: c.muted),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
    this.mono = false,
  });
  final String label;
  final String value;
  final bool mono;
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: SfType.ui(size: 11, color: c.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: mono
                  ? SfType.mono(size: 11, color: c.ink2)
                  : SfType.ui(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color: c.ink2,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditAccessDenied extends StatelessWidget {
  const _AuditAccessDenied();
  @override
  Widget build(BuildContext context) => const StaffPageScaffold(
    eyebrow: 'Ruxsatlar',
    title: 'Audit',
    subtitle: 'Nazorat ma\u2018lumotlari rol bo\u2018yicha himoyalangan',
    body: StaffEmptyState(
      title: 'Kirish cheklangan',
      message: 'Bu audit ish maydoni faqat auditor roliga ochiladi.',
      icon: SfIcons.shield,
    ),
  );
}

String _dateTime(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)} · ${two(local.hour)}:${two(local.minute)}';
}
