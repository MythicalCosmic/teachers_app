import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_toast.dart';

enum _PrinterChoice { library, staffRoom }

extension on _PrinterChoice {
  String get id => switch (this) {
    _PrinterChoice.library => 'printer-library',
    _PrinterChoice.staffRoom => 'printer-staff',
  };

  String get label => switch (this) {
    _PrinterChoice.library => 'Kutubxona',
    _PrinterChoice.staffRoom => 'Xodimlar xonasi',
  };

  String get fullName => switch (this) {
    _PrinterChoice.library => 'Kutubxona printeri',
    _PrinterChoice.staffRoom => 'O‘qituvchilar xonasi',
  };
}

class NewPrintJobScreen extends StatefulWidget {
  const NewPrintJobScreen({super.key});

  @override
  State<NewPrintJobScreen> createState() => _NewPrintJobScreenState();
}

class _NewPrintJobScreenState extends State<NewPrintJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _document = TextEditingController(text: 'Algebra ish varaqalari.pdf');
  final _pages = TextEditingController(text: '2');
  _PrinterChoice _printer = _PrinterChoice.library;
  int _copies = 1;
  bool _submitting = false;
  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    _prefilled = true;
    final requested = GoRouterState.of(
      context,
    ).uri.queryParameters['document']?.trim();
    if (requested != null && requested.isNotEmpty) {
      _document.text = requested;
    }
  }

  @override
  void dispose() {
    _document.dispose();
    _pages.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    final app = AppScope.of(context);
    setState(() => _submitting = true);
    try {
      await app.submitPrintJob(
        documentName: _document.text,
        printerId: _printer.id,
        printerName: _printer.fullName,
        copies: _copies,
        pageCount: int.parse(_pages.text),
      );
      if (!mounted) return;
      SfToast.show(
        context,
        message: 'Print ishi navbatga qo‘shildi',
        tone: SfToastTone.success,
        glassEnabled: app.settings.liquidGlass,
        motionEnabled: !app.settings.reducedMotion,
      );
      context.pop();
    } on Object catch (error) {
      if (!mounted) return;
      SfToast.show(
        context,
        message: error.toString(),
        tone: SfToastTone.error,
        glassEnabled: app.settings.liquidGlass,
        motionEnabled: !app.settings.reducedMotion,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final session = app.session;
    final c = SfTheme.colorsOf(context);
    if (session == null || !session.can(StaffCapability.submitPrintJobs)) {
      return const SfScaffold(
        body: SfErrorState(title: 'Print yuborishga ruxsat yo‘q'),
      );
    }
    final pages = int.tryParse(_pages.text) ?? 0;
    final totalPages = pages * _copies;

    return SfScaffold(
      dismissKeyboardOnTap: true,
      top: SfNavBar(
        title: 'Yangi chop etish',
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text('Bekor'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            const SfHintCard(
              compact: true,
              title: 'Material nomi',
              message:
                  'Fayl tanlash ulanmaguncha qurilmadagi hujjat nomini aniq kiriting.',
            ),
            const SizedBox(height: 18),
            SfTextField(
              controller: _document,
              label: 'Hujjat',
              hint: 'Masalan: 9-B algebra.pdf',
              prefixIcon: SfIcons.doc,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Hujjat nomini kiriting';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text('PRINTER', style: SfType.eyebrow(color: c.muted)),
            const SizedBox(height: 8),
            SfSegmentedControl<_PrinterChoice>(
              expanded: true,
              value: _printer,
              onChanged: (value) => setState(() => _printer = value),
              segments: [
                for (final printer in _PrinterChoice.values)
                  SfSegment(
                    value: printer,
                    label: printer.label,
                    icon: SfIcons.printer,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SfTextField(
                    controller: _pages,
                    label: 'Bet soni',
                    hint: '1',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed < 1 || parsed > 500) {
                        return '1–500 oralig‘i';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NUSXA', style: SfType.eyebrow(color: c.muted)),
                      const SizedBox(height: 6),
                      SfSurfaceCard(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Kamaytirish',
                              onPressed: _copies <= 1
                                  ? null
                                  : () => setState(() => _copies--),
                              icon: const Icon(Icons.remove_rounded),
                            ),
                            Expanded(
                              child: Text(
                                '$_copies',
                                textAlign: TextAlign.center,
                                style: SfType.mono(
                                  size: 18,
                                  weight: FontWeight.w800,
                                  color: c.ink,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Ko‘paytirish',
                              onPressed: _copies >= 99
                                  ? null
                                  : () => setState(() => _copies++),
                              icon: const Icon(Icons.add_rounded),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.ink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(SfIcons.printer, color: c.accent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalPages sahifa',
                          style: SfType.ui(
                            size: 16,
                            weight: FontWeight.w800,
                            color: c.bg,
                          ),
                        ),
                        Text(
                          '${_printer.fullName} · $_copies nusxa',
                          style: SfType.ui(
                            size: 11.5,
                            color: c.bg.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SfButton(
              block: true,
              height: 50,
              label: _submitting
                  ? 'Navbatga qo‘shilmoqda…'
                  : 'Navbatga qo‘shish',
              trailing: SfIcons.arrowR,
              haptic: app.settings.haptics,
              motionEnabled: !app.settings.reducedMotion,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
