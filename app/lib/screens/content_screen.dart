import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _storageKey = 'starforge.content_workspace.v1';

  final _searchController = TextEditingController();
  final _downloadedIds = <String>{};
  late final List<_LibraryFile> _files = [..._seedFiles];
  _ContentType _type = _ContentType.all;
  String? _folder;
  bool _showSearch = false;
  bool _sortByTitle = false;
  String? _storageError;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreLibrary());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _restoreLibrary() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final map = Map<String, dynamic>.from(decoded);
      final restoredFiles = (map['localResources'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (value) => _LibraryFile.fromJson(Map<String, dynamic>.from(value)),
          )
          .whereType<_LibraryFile>()
          .toList();
      final restoredIds = (map['offlineBookmarks'] as List? ?? const [])
          .whereType<String>()
          .toSet();
      if (!mounted) return;
      setState(() {
        _files
          ..removeWhere((file) => file.isLocal)
          ..addAll(restoredFiles);
        _downloadedIds
          ..clear()
          ..addAll(
            restoredIds.where((id) => _files.any((file) => file.id == id)),
          );
        _storageError = null;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _storageError = _contentText(
          context,
          uz: 'Mahalliy kutubxona o‘qilmadi. Asosiy materiallar xavfsiz qoldi.',
          en: 'The local library could not be read. Seed materials remain safe.',
        );
      });
    }
  }

  Future<bool> _persistLibrary() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _storageKey,
        jsonEncode({
          'version': 1,
          'localResources': _files
              .where((file) => file.isLocal)
              .map((file) => file.toJson())
              .toList(),
          'offlineBookmarks': _downloadedIds.toList(),
        }),
      );
      if (!saved) throw StateError('SharedPreferences write returned false.');
      if (mounted && _storageError != null) {
        setState(() => _storageError = null);
      }
      return true;
    } on Object {
      if (mounted) {
        setState(() {
          _storageError = _contentText(
            context,
            uz: 'O‘zgarish qurilmaga saqlanmadi. Qayta urinib ko‘ring.',
            en: 'The change was not saved on this device. Please retry.',
          );
        });
      }
      return false;
    }
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
            title: _contentText(context, uz: 'Materiallar', en: 'Materials'),
            subtitle: _contentText(
              context,
              uz: 'Xodimlar kutubxonasi · ${_files.length} fayl',
              en: 'Staff library · ${_files.length} items',
            ),
            leading: _BackButton(
              label: _contentText(context, uz: 'Ortga', en: 'Back'),
              onPressed: () => _goBack(context),
            ),
            actions: [
              _HeaderAction(
                icon: _showSearch ? Icons.close_rounded : SfIcons.search,
                label: _showSearch
                    ? _contentText(
                        context,
                        uz: 'Izlashni yopish',
                        en: 'Close search',
                      )
                    : _contentText(
                        context,
                        uz: 'Material izlash',
                        en: 'Search materials',
                      ),
                onPressed: () => setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) _searchController.clear();
                }),
              ),
              _HeaderAction(
                icon: SfIcons.upload,
                label: _contentText(
                  context,
                  uz: 'Material kartasi qo‘shish',
                  en: 'Add material card',
                ),
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
                hint: _contentText(
                  context,
                  uz: 'Fayl yoki papka nomi',
                  en: 'Material or folder name',
                ),
                prefixIcon: SfIcons.search,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                suffix: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: _contentText(
                          context,
                          uz: 'Tozalash',
                          en: 'Clear',
                        ),
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
            title: _contentText(
              context,
              uz: '${session.role.uzLabel} kutubxonasi',
              en: '${session.role.label} library',
            ),
            message: _contentText(
              context,
              uz: 'Material kartalarini ko‘ring, oflayn ro‘yxatga belgilang yoki chop navbatiga yuboring. Demo rejimida haqiqiy fayl uzatish ulanmagan.',
              en: 'Review material cards, bookmark them for offline planning, or send them to the print queue. Binary file transfer is not connected in demo mode.',
            ),
            actionLabel: session.can(StaffCapability.submitPrintJobs)
                ? _contentText(context, uz: 'Chop navbati', en: 'Print queue')
                : null,
            onAction: session.can(StaffCapability.submitPrintJobs)
                ? () => context.push('/print')
                : null,
          ),
          if (_storageError != null) ...[
            const SizedBox(height: 10),
            SfHintCard(
              compact: true,
              tone: SfHintTone.danger,
              title: _contentText(
                context,
                uz: 'Saqlash muammosi',
                en: 'Storage problem',
              ),
              message: _storageError!,
              actionLabel: _contentText(
                context,
                uz: 'Qayta urinish',
                en: 'Retry',
              ),
              onAction: () => unawaited(_persistLibrary()),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                _contentText(context, uz: 'PAPKALAR', en: 'FOLDERS'),
                style: SfType.eyebrow(color: c.muted),
              ),
              const Spacer(),
              if (_folder != null)
                TextButton(
                  onPressed: () => setState(() => _folder = null),
                  child: Text(_contentText(context, uz: 'Hammasi', en: 'All')),
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
                _folder == null
                    ? _contentText(
                        context,
                        uz: 'SO‘NGGI FAYLLAR',
                        en: 'RECENT MATERIALS',
                      )
                    : _folder!.toUpperCase(),
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
                label: Text(
                  _sortByTitle
                      ? _contentText(context, uz: 'Nom bo‘yicha', en: 'By name')
                      : _contentText(
                          context,
                          uz: 'Yangi avval',
                          en: 'Newest first',
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (visibleFiles.isEmpty)
            SfSurfaceCard(
              child: SfEmptyState(
                compact: true,
                icon: SfIcons.folder,
                title: _contentText(
                  context,
                  uz: 'Material topilmadi',
                  en: 'No materials found',
                ),
                message: _contentText(
                  context,
                  uz: 'Izlash yoki tur filtrini tozalab ko‘ring.',
                  en: 'Clear the search or type filter and try again.',
                ),
                actionLabel: _contentText(
                  context,
                  uz: 'Filtrlarni tozalash',
                  en: 'Clear filters',
                ),
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
          meta: 'Mahalliy material kartasi · fayl biriktirilmagan',
          folder: draft.folder,
          order: DateTime.now().millisecondsSinceEpoch,
          aiSummary: false,
          description: draft.description,
          isLocal: true,
        ),
      );
      _type = _ContentType.all;
      _folder = null;
    });
    final persisted = await _persistLibrary();
    if (!mounted) return;
    SfToast.show(
      context,
      title: persisted
          ? _contentText(
              context,
              uz: 'Material kartasi saqlandi',
              en: 'Material card saved',
            )
          : _contentText(context, uz: 'Saqlab bo‘lmadi', en: 'Could not save'),
      message: persisted
          ? _contentText(
              context,
              uz: '${draft.name} ushbu qurilmadagi kutubxonaga qo‘shildi.',
              en: '${draft.name} was added to this device library.',
            )
          : _contentText(
              context,
              uz: 'Kartani ko‘rishingiz mumkin, ammo u qayta ochilganda yo‘qolishi mumkin.',
              en: 'The card remains visible now but may be lost after reopening.',
            ),
      tone: persisted ? SfToastTone.success : SfToastTone.error,
    );
  }

  Future<void> _download(_LibraryFile file) async {
    final added = !_downloadedIds.contains(file.id);
    setState(() {
      if (added) {
        _downloadedIds.add(file.id);
      } else {
        _downloadedIds.remove(file.id);
      }
    });
    final persisted = await _persistLibrary();
    if (!mounted) return;
    SfToast.show(
      context,
      title: persisted
          ? added
                ? _contentText(
                    context,
                    uz: 'Oflayn ro‘yxatga belgilandi',
                    en: 'Added to offline planning',
                  )
                : _contentText(
                    context,
                    uz: 'Oflayn ro‘yxatdan olindi',
                    en: 'Removed from offline planning',
                  )
          : _contentText(
              context,
              uz: 'Belgini saqlab bo‘lmadi',
              en: 'Could not save bookmark',
            ),
      message: persisted
          ? _contentText(
              context,
              uz: 'Bu belgi qurilmada saqlanadi; demo rejimi faylning o‘zini yuklab olmaydi.',
              en: 'The bookmark is saved on this device; demo mode does not download the binary file.',
            )
          : _contentText(
              context,
              uz: 'Qurilma xotirasiga yozishda muammo yuz berdi.',
              en: 'The device could not store this change.',
            ),
      tone: persisted ? SfToastTone.success : SfToastTone.error,
    );
  }

  Future<void> _showPreview(_LibraryFile file) async {
    final app = AppScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final c = SfTheme.colorsOf(sheetContext);
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .88,
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
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
                  '${file.folder} · ${_fileMeta(sheetContext, file)}',
                  textAlign: TextAlign.center,
                  style: SfType.ui(size: 12, color: c.muted),
                ),
                if (file.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    file.description,
                    textAlign: TextAlign.center,
                    style: SfType.ui(size: 12, color: c.ink2, height: 1.45),
                  ),
                ],
                if (file.isLocal) ...[
                  const SizedBox(height: 12),
                  SfHintCard(
                    compact: true,
                    tone: SfHintTone.warning,
                    title: _contentText(
                      sheetContext,
                      uz: 'Mahalliy karta',
                      en: 'Local card',
                    ),
                    message: _contentText(
                      sheetContext,
                      uz: 'Nomi va izohi qurilmada saqlangan. Fayl uzatish ishlab chiqarish serveri ulangach mavjud bo‘ladi.',
                      en: 'Its title and notes are stored on this device. File transfer becomes available when the production server is connected.',
                    ),
                  ),
                ],
                if (file.aiSummary) ...[
                  const SizedBox(height: 14),
                  SfHintCard(
                    compact: true,
                    tone: SfHintTone.ai,
                    title: _contentText(
                      sheetContext,
                      uz: 'AI xulosa tayyor',
                      en: 'AI summary ready',
                    ),
                    message: _contentText(
                      sheetContext,
                      uz: 'Asosiy mavzular va dars uchun tavsiya etilgan savollar ajratilgan.',
                      en: 'Key topics and suggested lesson questions are highlighted.',
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SfButton(
                        kind: SfButtonKind.ghost,
                        label: _downloadedIds.contains(file.id)
                            ? _contentText(
                                sheetContext,
                                uz: 'Oflayn belgisi bor',
                                en: 'Offline bookmark',
                              )
                            : _contentText(
                                sheetContext,
                                uz: 'Oflayn belgilash',
                                en: 'Bookmark offline',
                              ),
                        leading: _downloadedIds.contains(file.id)
                            ? SfIcons.check
                            : SfIcons.download,
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          unawaited(_download(file));
                        },
                      ),
                    ),
                    if (app.can(StaffCapability.submitPrintJobs)) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: SfButton(
                          label: _contentText(
                            sheetContext,
                            uz: 'Chop etish',
                            en: 'Print',
                          ),
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
            semanticLabel: _contentText(
              context,
              uz: '${_typeLabel(context, type)} filtri',
              en: '${_typeLabel(context, type)} filter',
            ),
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
                _typeLabel(context, type),
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
        semanticLabel: _contentText(
          context,
          uz: '$name papkasi, $count fayl',
          en: '$name folder, $count items',
        ),
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
              Text(
                _contentText(context, uz: '$count fayl', en: '$count items'),
                style: SfType.ui(size: 10, color: c.muted),
              ),
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
      semanticLabel: '${file.name}. ${_fileMeta(context, file)}',
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
                          _fileMeta(context, file),
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
                    ? _contentText(
                        context,
                        uz: 'Oflayn ro‘yxatdan olish',
                        en: 'Remove offline bookmark',
                      )
                    : _contentText(
                        context,
                        uz: 'Oflayn ro‘yxatga belgilash',
                        en: 'Add offline bookmark',
                      ),
                tooltip: downloaded
                    ? _contentText(
                        context,
                        uz: 'Oflayn belgi',
                        en: 'Offline bookmark',
                      )
                    : _contentText(
                        context,
                        uz: 'Oflayn belgilash',
                        en: 'Bookmark offline',
                      ),
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
      semanticLabel: _contentText(
        context,
        uz: 'Yangi material kartasi qo‘shish',
        en: 'Add a new material card',
      ),
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
              _contentText(
                context,
                uz: 'Material kartasi qo‘shish',
                en: 'Add material card',
              ),
              style: SfType.ui(size: 14, weight: FontWeight.w700, color: c.ink),
            ),
            const SizedBox(height: 2),
            Text(
              _contentText(
                context,
                uz: 'Nomi, izohi, turi va papkasini kiriting',
                en: 'Enter a title, notes, type, and folder',
              ),
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
  final _descriptionController = TextEditingController();
  _ContentType _type = _ContentType.pdf;
  String _folder = _folders.first;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
                _contentText(
                  context,
                  uz: 'Yangi material kartasi',
                  en: 'New material card',
                ),
                style: SfType.ui(
                  size: 20,
                  weight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _contentText(
                  context,
                  uz: 'Demo rejimida metadata qurilmada saqlanadi; haqiqiy fayl yuborilmaydi.',
                  en: 'Demo mode stores metadata on this device; it does not upload a binary file.',
                ),
                style: SfType.ui(size: 12, color: c.muted),
              ),
              const SizedBox(height: 18),
              SfTextField(
                controller: _nameController,
                label: _contentText(
                  context,
                  uz: 'Material nomi',
                  en: 'Material title',
                ),
                hint: _contentText(
                  context,
                  uz: 'Masalan, Kvadrat tenglamalar',
                  en: 'For example, Quadratic equations',
                ),
                prefixIcon: SfIcons.doc,
                autofocus: true,
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().length < 3
                    ? _contentText(
                        context,
                        uz: 'Kamida 3 ta belgi kiriting',
                        en: 'Enter at least 3 characters',
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              SfTextField(
                controller: _descriptionController,
                label: _contentText(
                  context,
                  uz: 'Qisqa izoh',
                  en: 'Short note',
                ),
                hint: _contentText(
                  context,
                  uz: 'Darsda qanday ishlatiladi?',
                  en: 'How will this be used in class?',
                ),
                prefixIcon: Icons.notes_rounded,
                minLines: 2,
                maxLines: 4,
                maxLength: 240,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<_ContentType>(
                initialValue: _type,
                decoration: InputDecoration(
                  labelText: _contentText(
                    context,
                    uz: 'Fayl turi',
                    en: 'Material type',
                  ),
                ),
                items: _ContentType.values
                    .where((type) => type != _ContentType.all)
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_typeLabel(context, type)),
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
                decoration: InputDecoration(
                  labelText: _contentText(context, uz: 'Papka', en: 'Folder'),
                ),
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
                label: _contentText(
                  context,
                  uz: 'Kartani saqlash',
                  en: 'Save card',
                ),
                leading: SfIcons.upload,
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.pop(
                    context,
                    _NewResourceDraft(
                      name: _nameController.text.trim(),
                      type: _type,
                      folder: _folder,
                      description: _descriptionController.text.trim(),
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
  const _BackButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      onPressed: onPressed,
      semanticLabel: label,
      tooltip: label,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(SfIcons.arrowL, size: 18, color: c.primary),
            const SizedBox(width: 3),
            Text(label, style: SfType.ui(size: 13, color: c.primary)),
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
    this.description = '',
    this.isLocal = false,
  });

  final String id;
  final String name;
  final _ContentType type;
  final String meta;
  final String folder;
  final int order;
  final bool aiSummary;
  final String description;
  final bool isLocal;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'meta': meta,
    'folder': folder,
    'order': order,
    'description': description,
  };

  static _LibraryFile? fromJson(Map<String, dynamic> json) {
    try {
      final type = _ContentType.values.byName(json['type'] as String);
      if (type == _ContentType.all) return null;
      return _LibraryFile(
        id: json['id'] as String,
        name: json['name'] as String,
        type: type,
        meta:
            json['meta'] as String? ??
            'Mahalliy material kartasi · fayl biriktirilmagan',
        folder: json['folder'] as String,
        order: json['order'] as int,
        aiSummary: false,
        description: json['description'] as String? ?? '',
        isLocal: true,
      );
    } on Object {
      return null;
    }
  }
}

class _NewResourceDraft {
  const _NewResourceDraft({
    required this.name,
    required this.type,
    required this.folder,
    required this.description,
  });

  final String name;
  final _ContentType type;
  final String folder;
  final String description;
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

String _typeLabel(BuildContext context, _ContentType type) => switch (type) {
  _ContentType.all => _contentText(context, uz: 'Hammasi', en: 'All'),
  _ContentType.pdf => 'PDF',
  _ContentType.video => 'Video',
  _ContentType.slide => _contentText(context, uz: 'Slayd', en: 'Slides'),
  _ContentType.document => _contentText(context, uz: 'Hujjat', en: 'Document'),
};

String _contentText(
  BuildContext context, {
  required String uz,
  required String en,
}) => Localizations.localeOf(context).languageCode == 'uz' ? uz : en;

String _fileMeta(BuildContext context, _LibraryFile file) => file.isLocal
    ? _contentText(
        context,
        uz: 'Mahalliy material kartasi · fayl biriktirilmagan',
        en: 'Local material card · no file attached',
      )
    : file.meta;

void _goBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/more');
  }
}
