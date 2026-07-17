import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import 'staff_surface_widgets.dart';
import 'staff_workspace_models.dart';

class MethodistQualityScreen extends StatefulWidget {
  const MethodistQualityScreen({
    super.key,
    this.role = StaffRole.methodist,
    this.attendanceSheets = const [],
    this.cards = const [],
    this.tasks = const [],
    this.signals = _fallbackSignals,
    this.onCreateFollowUp,
    this.onOpenTeacher,
  });

  final StaffRole role;
  final List<AttendanceSheet> attendanceSheets;
  final List<RecognitionCard> cards;
  final List<StaffTask> tasks;
  final List<QualitySignalView> signals;
  final ValueChanged<QualitySignalView>? onCreateFollowUp;
  final ValueChanged<String>? onOpenTeacher;

  static const _fallbackSignals = [
    QualitySignalView(
      id: 'quality-01',
      title: 'Karta muvozanatini ko\u2018rib chiqing',
      subtitle: 'Bir guruhda ogohlantirishlar odatiy darajadan yuqori.',
      metric: '8 Down',
      tone: QualitySignalTone.urgent,
      teacherName: 'Jasur Rahimov',
    ),
    QualitySignalView(
      id: 'quality-02',
      title: 'Davomat qaydi kech topshirildi',
      subtitle: 'Oxirgi yetti kunda ikki dars 30 daqiqadan keyin yopilgan.',
      metric: '2 dars',
      tone: QualitySignalTone.attention,
      teacherName: 'Malika Yusupova',
    ),
    QualitySignalView(
      id: 'quality-03',
      title: 'Barqaror o\u2018sish',
      subtitle: 'Guruh davomati uch hafta ketma-ket yaxshilandi.',
      metric: '+6%',
      tone: QualitySignalTone.positive,
      teacherName: 'Nigora Karimova',
    ),
  ];

  @override
  State<MethodistQualityScreen> createState() => _MethodistQualityScreenState();
}

class _MethodistQualityScreenState extends State<MethodistQualityScreen> {
  QualityPeriod _period = QualityPeriod.week;

  @override
  Widget build(BuildContext context) {
    if (!widget.role.can(StaffCapability.viewQualityWorkspace)) {
      return const StaffPageScaffold(
        eyebrow: 'Ruxsatlar',
        title: 'Sifat maydoni',
        subtitle: 'Metodistlar uchun pedagogik sifat ko\u2018rinishi',
        body: StaffEmptyState(
          title: 'Kirish cheklangan',
          message:
              'Bu ekranda moliya yo\u2018q va sifat ko\u2018rsatkichlari faqat metodistga ochiladi.',
          icon: SfIcons.shield,
        ),
      );
    }

    return StaffPageScaffold(
      eyebrow: 'Metodist · sifat nazorati',
      title: 'Ta\u2018lim sifati',
      subtitle:
          'Signalni tushuning, ustozga yordam bering, keyingi qadamni vazifaga aylantiring',
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final allEntries = widget.attendanceSheets
        .expand((sheet) => sheet.entries)
        .toList();
    final marked = allEntries.where((entry) => entry.status != null).toList();
    final attended = marked
        .where(
          (entry) =>
              entry.status == AttendanceStatus.present ||
              entry.status == AttendanceStatus.late,
        )
        .length;
    final attendance = marked.isEmpty
        ? 92
        : ((attended / marked.length) * 100).round();
    final warnings = widget.cards
        .where((card) => card.kind == CardKind.warning)
        .length;
    final openTasks = widget.tasks
        .where((task) => task.status != TaskStatus.done)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        StaffSegment<QualityPeriod>(
          values: QualityPeriod.values,
          selected: _period,
          labelOf: (value) => value.label,
          onChanged: (value) => setState(() => _period = value),
        ),
        const SizedBox(height: 14),
        StaffAdaptiveGrid(
          children: [
            StaffMetricCard(
              label: 'O\u2018rtacha davomat',
              value: '$attendance%',
              detail: 'O\u2018quv sifati signali',
              icon: SfIcons.check,
              tone: attendance >= 90
                  ? StaffMetricTone.success
                  : StaffMetricTone.warning,
            ),
            StaffMetricCard(
              label: 'Ko\u2018rib chiqish kerak',
              value:
                  '${widget.signals.where((s) => s.tone != QualitySignalTone.positive).length}',
              detail: 'Ustozga yordam nuqtalari',
              icon: SfIcons.flag,
              tone: StaffMetricTone.warning,
            ),
            StaffMetricCard(
              label: 'Ochiq vazifa',
              value: '$openTasks',
              detail: 'Sifat bo\u2018yicha kuzatuv',
              icon: SfIcons.doc,
              tone: StaffMetricTone.primary,
            ),
            StaffMetricCard(
              label: 'Down kartalar',
              value: '$warnings',
              detail: 'Adolat kontekstida',
              icon: SfIcons.brand,
              tone: warnings > 6
                  ? StaffMetricTone.danger
                  : StaffMetricTone.accent,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const StaffHintCard(
          title: 'Raqam hukm emas',
          message:
              'Signalni dars konteksti bilan tekshiring. Bu sahifa oylik, to\u2018lov yoki boshqa moliyaviy ma\u2018lumotni ko\u2018rsatmaydi.',
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: 20),
        StaffSectionHeader(
          title: 'Ustozga yordam signallari',
          subtitle: '${_period.label} · eng muhimlari yuqorida',
        ),
        const SizedBox(height: 10),
        if (widget.signals.isEmpty)
          const StaffEmptyState(
            title: 'Signal yo\u2018q',
            message:
                'Tanlangan davrda metodist e\u2018tiborini talab qiladigan o\u2018zgarish topilmadi.',
            icon: SfIcons.check,
          )
        else
          SfSurfaceCard(
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < widget.signals.length;
                    index++
                  ) ...[
                    _QualitySignalTile(
                      signal: widget.signals[index],
                      onOpenTeacher: widget.onOpenTeacher,
                      onCreateFollowUp: widget.onCreateFollowUp,
                    ),
                    if (index < widget.signals.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _QualitySignalTile extends StatelessWidget {
  const _QualitySignalTile({
    required this.signal,
    this.onOpenTeacher,
    this.onCreateFollowUp,
  });

  final QualitySignalView signal;
  final ValueChanged<String>? onOpenTeacher;
  final ValueChanged<QualitySignalView>? onCreateFollowUp;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final (tone, icon, color) = switch (signal.tone) {
      QualitySignalTone.positive => (
        SfPillTone.success,
        Icons.trending_up,
        c.success,
      ),
      QualitySignalTone.attention => (
        SfPillTone.warn,
        Icons.visibility_outlined,
        c.warn,
      ),
      QualitySignalTone.urgent => (SfPillTone.danger, SfIcons.flag, c.danger),
    };
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      leading: Icon(icon, size: 21, color: color),
      title: Text(
        signal.title,
        style: SfType.ui(size: 13.5, weight: FontWeight.w700, color: c.ink),
      ),
      subtitle: Text(
        signal.teacherName,
        style: SfType.ui(size: 11, color: c.muted),
      ),
      trailing: SfPill(tone: tone, label: signal.metric),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            signal.subtitle,
            style: SfType.ui(size: 12, color: c.ink2, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SfButton(
                kind: SfButtonKind.ghost,
                label: 'Ustoz profili',
                fontSize: 12,
                onPressed: onOpenTeacher == null
                    ? null
                    : () => onOpenTeacher!(signal.teacherName),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SfButton(
                label: 'Vazifa yaratish',
                leading: SfIcons.plus,
                fontSize: 12,
                onPressed: onCreateFollowUp == null
                    ? null
                    : () => onCreateFollowUp!(signal),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
