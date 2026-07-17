import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../theme/sf_theme.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_form_controls.dart';
import '../widgets/sf_hint_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pill.dart';
import '../widgets/sf_pressable.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_state_view.dart';
import '../widgets/sf_toast.dart';

enum _ContentType { all, pdf, video, slide, document }

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final _searchController = TextEditingController();
  final _downloadedIds = <String>{};
  late final List<_LibraryFile> _files = [..._seedFiles];
  _ContentType _type = _ContentType.all;
  String? _folder;
  bool _showSearch = false;
  bool _sortByTitle = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    final session = app.session;
    if (session == null) return const SizedBox.shrink();

    final query = _searchController.text.trim().toLowerCase();
    final visibleFiles =
        _files.where((file) {
          final matchesType = _type == _ContentType.all || file.type == _type;
          final matchesFolder = _folder == null || file.folder == _folder;
          final matchesQuery =
              query.isEmpty ||
              '${file.name} ${file.folder} ${file.meta}'.toLowerCase().contains(
                query,
              );
          return matchesType && matchesFolder && matchesQuery;
        }).toList()..sort(
          (a, b) => _sortByTitle
              ? a.name.compareTo(b.name)
              : b.order.compareTo(a.order),
        );

    return SfScaffold(
      top: Column(
        children: [
          SfLargeAppBar(
            title: 'Materiallar',
            subtitle: 'Xodimlar kutubxonasi · ${_files.length} fayl',
            leading: _BackButton(onPressed: () => _goBack(context)),
            actions: [
              _HeaderAction(
                icon: _showSearch ? Icons.close_rounded : SfIcons.search,
                label: _showSearch ? 'Izlashni yopish' : 'Material izlash',
                onPressed: () => setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) _searchController.clear();
                }),
              ),
              _HeaderAction(
                icon: SfIcons.upload,
                label: 'Material qo‘shish',
                onPressed: _addResource,
              ),
            ],
          ),
          if (_showSearch)
            Container(
              color: c.surface,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: SfTextField(
                controller: _searchController,
                autofocus: true,
                hint: 'Fayl yoki papka nomi',
                prefixIcon: SfIcons.search,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                suffix: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Tozalash',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
              ),
            ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: _TypeFilters(
              value: _type,
              onChanged: (value) => setState(() => _type = value),
            ),
          ),
        ],
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
        children: [
          SfHintCard(
            compact: true,
            title: '${session.role.uzLabel} kutubxonasi',
            message:
                'Materialni ko‘rib chiqing, qurilmaga saqlang yoki to‘g‘ridan-to‘g‘ri chopga yuboring.',
            actionLabel: session.can(StaffCapability.submitPrintJobs)
                ? 'Chop navbati'
                : null,
            onAction: session.can(StaffCapability.submitPrintJobs)
                ? () => context.push('/print')
                : null,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('PAPKALAR', style: SfType.eyebrow(color: c.muted)),
              const Spacer(),
              if (_folder != null)
                TextButton(
                  onPressed: () => setState(() => _folder = null),
                  child: const Text('Hammasi'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _folders.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final folder = _folders[index];
                return _FolderCard(
                  name: folder,
                  count: _files.where((file) => file.folder == folder).length,
                  active: _folder == folder,
                  onPressed: () => setState(() {
                    _folder = _folder == folder ? null : folder;
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                _folder == null ? 'SO‘NGGI FAYLLAR' : _folder!.toUpperCase(),
                style: SfType.eyebrow(color: c.muted),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _sortByTitle = !_sortByTitle),
                icon: Icon(
                  _sortByTitle
                      ? Icons.sort_by_alpha_rounded
                      : Icons.schedule_rounded,
                  size: 16,
                ),
                label: Text(_sortByTitle ? 'Nom bo‘yicha' : 'Yangi avval'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (visibleFiles.isEmpty)
            SfSurfaceCard(
              child: SfEmptyState(
                compact: true,
                icon: SfIcons.folder,
                title: 'Material topilmadi',
                message: 'Izlash yoki tur filtrini tozalab ko‘ring.',
                actionLabel: 'Filtrlarni tozalash',
                onAction: () {
                  _searchController.clear();
                  setState(() {
                    _type = _ContentType.all;
                    _folder = null;
                  });
                },
              ),
            )
          else
            SfSurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0; index < visibleFiles.length; index++)
                    _FileTile(
                      file: visibleFiles[index],
                      downloaded: _downloadedIds.contains(
                        visibleFiles[index].id,
                      ),
                      showDivider: index != visibleFiles.length - 1,
                      onOpen: () => _showPreview(visibleFiles[index]),
                      onDownload: () => _download(visibleFiles[index]),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          _UploadCard(onPressed: _addResource),
        ],
      ),
    );
  }

  Future<void> _addResource() async {
    final draft = await showModalBottomSheet<_NewResourceDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddResourceSheet(),
    );
    if (draft == null || !mounted) return;
    setState(() {
      _files.add(
        _LibraryFile(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          name: draft.name,
          type: draft.type,
          meta: 'Mahalliy material · yangi',
          folder: draft.folder,
          order: DateTime.now().millisecondsSinceEpoch,
          aiSummary: false,
        ),
      );
      _type = _ContentType.all;
      _folder = null;
    });
    SfToast.show(
      context,
      title: 'Material qo‘shildi',
      message: '${draft.name} xodimlar kutubxonasiga joylandi.',
      tone: SfToastTone.success,
    );
  }

  void _download(_LibraryFile file) {
    setState(() => _downloadedIds.add(file.id));
    SfToast.show(
      context,
      title: 'Qurilmaga saqlandi',
      message: '${file.name} oflayn foydalanish uchun tayyor.',
      tone: SfToastTone.success,
    );
  }

  Future<void> _showPreview(_LibraryFile file) async {
    final app = AppScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final c = SfTheme.colorsOf(sheetContext);
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: c.borderStrong,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 20),
              _FileIcon(type: file.type, size: 64),
              const SizedBox(height: 14),
              Text(
                file.name,
                textAlign: TextAlign.center,
                style: SfType.ui(
                  size: 19,
                  weight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${file.folder} · ${file.meta}',
                textAlign: TextAlign.center,
                style: SfType.ui(size: 12, color: c.muted),
              ),
              if (file.aiSummary) ...[
                const SizedBox(height: 14),
                const SfHintCard(
                  compact: true,
                  tone: SfHintTone.ai,
                  title: 'AI xulosa tayyor',
                  message:
                      'Asosiy mavzular va dars uchun tavsiya etilgan savollar ajratilgan.',
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SfButton(
                      kind: SfButtonKind.ghost,
                      label: _downloadedIds.contains(file.id)
                          ? 'Saqlandi'
                          : 'Saqlash',
                      leading: _downloadedIds.contains(file.id)
                          ? SfIcons.check
                          : SfIcons.download,
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _download(file);
                      },
                    ),
                  ),
                  if (app.can(StaffCapability.submitPrintJobs)) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: SfButton(
                        label: 'Chop etish',
                        leading: SfIcons.printer,
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          context.push(
                            '/print/new?document=${Uri.encodeQueryComponent(file.name)}',
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TypeFilters extends StatelessWidget {
  const _TypeFilters({required this.value, required this.onChanged});

  final _ContentType value;
  final ValueChanged<_ContentType> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _ContentType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final type = _ContentType.values[index];
          final active = type == value;
          return SfPressable(
            onPressed: () => onChanged(type),
            semanticLabel: '${_typeLabel(type)} filtri',
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: active ? c.ink : Colors.transparent,
                border: Border.all(color: active ? c.ink : c.border),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _typeLabel(type),
                style: SfType.ui(
                  size: 12,
                  weight: FontWeight.w700,
                  color: active ? c.bg : c.muted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.name,
    required this.count,
    required this.active,
    required this.onPressed,
  });

  final String name;
  final int count;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SizedBox(
      width: 164,
      child: SfPressable(
        onPressed: onPressed,
        semanticLabel: '$name papkasi, $count fayl',
        borderRadius: BorderRadius.circular(16),
        child: SfSurfaceCard(
          padding: const EdgeInsets.all(13),
          color: active ? c.primarySoft : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: active ? c.primary : c.ink2,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  SfIcons.folder,
                  size: 20,
                  color: Color(0xFFFFFCF5),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SfType.ui(
                  size: 13,
                  weight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text('$count fayl', style: SfType.ui(size: 10, color: c.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.file,
    required this.downloaded,
    required this.showDivider,
    required this.onOpen,
    required this.onDownload,
  });

  final _LibraryFile file;
  final bool downloaded;
  final bool showDivider;
  final VoidCallback onOpen;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      onPressed: onOpen,
      semanticLabel: '${file.name}. ${file.meta}',
      borderRadius: BorderRadius.zero,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: c.border))
              : null,
        ),
        child: Row(
          children: [
            _FileIcon(type: file.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SfType.ui(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          file.meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SfType.ui(size: 10.5, color: c.muted),
                        ),
                      ),
                      if (file.aiSummary) ...[
                        const SizedBox(width: 6),
                        const SfPill(tone: SfPillTone.ai, label: 'AI'),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox.square(
              dimension: 44,
              child: SfPressable(
                onPressed: onDownload,
                semanticLabel: downloaded
                    ? 'Qurilmaga saqlangan'
                    : 'Qurilmaga saqlash',
                tooltip: downloaded ? 'Saqlandi' : 'Saqlash',
                borderRadius: BorderRadius.circular(12),
                child: Icon(
                  downloaded ? SfIcons.check : SfIcons.download,
                  size: 18,
                  color: downloaded ? c.success : c.ink2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon({required this.type, this.size = 44});

  final _ContentType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final (icon, color) = switch (type) {
      _ContentType.pdf => (SfIcons.pdf, c.danger),
      _ContentType.video => (SfIcons.video, c.accent),
      _ContentType.slide => (Icons.slideshow_outlined, c.warn),
      _ContentType.document => (SfIcons.doc, c.primary),
      _ContentType.all => (SfIcons.doc, c.ink2),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.46, color: const Color(0xFFFFFCF5)),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      onPressed: onPressed,
      semanticLabel: 'Yangi material qo‘shish',
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.borderStrong, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(SfIcons.upload, size: 22, color: c.primary),
            ),
            const SizedBox(height: 10),
            Text(
              'Material qo‘shish',
              style: SfType.ui(size: 14, weight: FontWeight.w700, color: c.ink),
            ),
            const SizedBox(height: 2),
            Text(
              'Nomi, turi va papkasini kiriting',
              style: SfType.ui(size: 11, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddResourceSheet extends StatefulWidget {
  const _AddResourceSheet();

  @override
  State<_AddResourceSheet> createState() => _AddResourceSheetState();
}

class _AddResourceSheetState extends State<_AddResourceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  _ContentType _type = _ContentType.pdf;
  String _folder = _folders.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        22 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.borderStrong,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Yangi material',
                style: SfType.ui(
                  size: 20,
                  weight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Kutubxonada xodimlar uchun tushunarli nomdan foydalaning.',
                style: SfType.ui(size: 12, color: c.muted),
              ),
              const SizedBox(height: 18),
              SfTextField(
                controller: _nameController,
                label: 'Material nomi',
                hint: 'Masalan, Kvadrat tenglamalar',
                prefixIcon: SfIcons.doc,
                autofocus: true,
                textInputAction: TextInputAction.done,
                validator: (value) => value == null || value.trim().length < 3
                    ? 'Kamida 3 ta belgi kiriting'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<_ContentType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Fayl turi'),
                items: _ContentType.values
                    .where((type) => type != _ContentType.all)
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_typeLabel(type)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _folder,
                decoration: const InputDecoration(labelText: 'Papka'),
                items: _folders
                    .map(
                      (folder) =>
                          DropdownMenuItem(value: folder, child: Text(folder)),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _folder = value);
                },
              ),
              const SizedBox(height: 20),
              SfButton(
                block: true,
                label: 'Kutubxonaga qo‘shish',
                leading: SfIcons.upload,
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.pop(
                    context,
                    _NewResourceDraft(
                      name: _nameController.text.trim(),
                      type: _type,
                      folder: _folder,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SizedBox.square(
      dimension: 44,
      child: SfPressable(
        onPressed: onPressed,
        semanticLabel: label,
        tooltip: label,
        borderRadius: BorderRadius.circular(12),
        child: Icon(icon, size: 20, color: c.ink2),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      onPressed: onPressed,
      semanticLabel: 'Ortga',
      tooltip: 'Ortga',
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(SfIcons.arrowL, size: 18, color: c.primary),
            const SizedBox(width: 3),
            Text('Ortga', style: SfType.ui(size: 13, color: c.primary)),
          ],
        ),
      ),
    );
  }
}

class _LibraryFile {
  const _LibraryFile({
    required this.id,
    required this.name,
    required this.type,
    required this.meta,
    required this.folder,
    required this.order,
    required this.aiSummary,
  });

  final String id;
  final String name;
  final _ContentType type;
  final String meta;
  final String folder;
  final int order;
  final bool aiSummary;
}

class _NewResourceDraft {
  const _NewResourceDraft({
    required this.name,
    required this.type,
    required this.folder,
  });

  final String name;
  final _ContentType type;
  final String folder;
}

const _folders = <String>[
  'Algebra · Daraja II',
  'Geometriya',
  'Olimpiada to‘plami',
];

const _seedFiles = <_LibraryFile>[
  _LibraryFile(
    id: 'content-1',
    name: 'Kvadrat tenglama · 03',
    type: _ContentType.pdf,
    meta: '2.1 MB · 8 bet',
    folder: 'Algebra · Daraja II',
    order: 6,
    aiSummary: true,
  ),
  _LibraryFile(
    id: 'content-2',
    name: 'Funksiyalar grafigi',
    type: _ContentType.video,
    meta: '6:42 · MP4',
    folder: 'Algebra · Daraja II',
    order: 5,
    aiSummary: false,
  ),
  _LibraryFile(
    id: 'content-3',
    name: 'Diskriminant · slayd',
    type: _ContentType.slide,
    meta: 'PPTX · 16 slayd',
    folder: 'Algebra · Daraja II',
    order: 4,
    aiSummary: false,
  ),
  _LibraryFile(
    id: 'content-4',
    name: 'Uchburchaklar to‘plami',
    type: _ContentType.pdf,
    meta: '880 KB · 12 bet',
    folder: 'Geometriya',
    order: 3,
    aiSummary: false,
  ),
  _LibraryFile(
    id: 'content-5',
    name: 'Matematik induksiya',
    type: _ContentType.document,
    meta: 'DOCX · 4 bet',
    folder: 'Olimpiada to‘plami',
    order: 2,
    aiSummary: true,
  ),
  _LibraryFile(
    id: 'content-6',
    name: 'Geometriya amaliyoti',
    type: _ContentType.video,
    meta: '8:10 · MP4',
    folder: 'Geometriya',
    order: 1,
    aiSummary: false,
  ),
];

String _typeLabel(_ContentType type) => switch (type) {
  _ContentType.all => 'Hammasi',
  _ContentType.pdf => 'PDF',
  _ContentType.video => 'Video',
  _ContentType.slide => 'Slayd',
  _ContentType.document => 'Hujjat',
};

void _goBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/more');
  }
}
