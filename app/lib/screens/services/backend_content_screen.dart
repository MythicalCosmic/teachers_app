import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/backend_core.dart';
import '../../data/api/backend_models.dart';
import '../../data/api/backend_services_api.dart';
import '../../features/services/backend_services_controllers.dart';
import '../../features/services/content_binary_uploader.dart';
import '../../theme/sf_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/formatters.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_media_player.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_pressable.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_search_field.dart';
import '../../widgets/sf_service_unavailable.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_toast.dart';

enum _ContentBackendTab { hierarchy, files, materials }

enum _BackendFileFilter { all, video, audio, documents, images }

class BackendContentScreen extends StatefulWidget {
  const BackendContentScreen({
    super.key,
    required this.api,
    this.canManageContent = false,
    this.canApproveContent = false,
    this.canPublishContent = false,
    this.canGenerateContent = false,
  });

  final BackendServicesApi api;
  final bool canManageContent;
  final bool canApproveContent;
  final bool canPublishContent;
  final bool canGenerateContent;

  @override
  State<BackendContentScreen> createState() => _BackendContentScreenState();
}

class _BackendContentScreenState extends State<BackendContentScreen> {
  late final BackendContentController _controller;
  _ContentBackendTab _tab = _ContentBackendTab.hierarchy;

  @override
  void initState() {
    super.initState();
    _controller = BackendContentController(widget.api)..refresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final library = _controller.selectedLibrary;
      return SfScaffold(
        safeBottom: true,
        top: Column(
          children: [
            SfLargeAppBar(
              title: _copy(context, uz: 'Kontent markazi', en: 'Content hub'),
              subtitle: _copy(
                context,
                uz: switch (_tab) {
                  _ContentBackendTab.hierarchy =>
                    library == null
                        ? 'Prod serverdagi kutubxonalar'
                        : library.name,
                  _ContentBackendTab.files =>
                    'Xodim ruxsati · ${_controller.files.length} server fayli',
                  _ContentBackendTab.materials =>
                    library == null
                        ? 'Prod server materiallari'
                        : '${library.name} · ${_controller.materials.length} material',
                },
                en: switch (_tab) {
                  _ContentBackendTab.hierarchy =>
                    library == null
                        ? 'Libraries from the production server'
                        : library.name,
                  _ContentBackendTab.files =>
                    'Staff scope · ${_controller.files.length} server files',
                  _ContentBackendTab.materials =>
                    library == null
                        ? 'Production server materials'
                        : '${library.name} · ${_controller.materials.length} materials',
                },
              ),
              leading: IconButton(
                tooltip: _copy(context, uz: 'Ortga', en: 'Back'),
                onPressed: () => _goBack(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              actions: [
                IconButton(
                  key: const Key('backend-content-refresh'),
                  tooltip: _copy(context, uz: 'Yangilash', en: 'Refresh'),
                  onPressed: _controller.refreshing
                      ? null
                      : () => _controller.refresh(),
                  icon: _controller.refreshing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
                if (_tab == _ContentBackendTab.files && widget.canManageContent)
                  IconButton(
                    key: const Key('backend-content-request-upload'),
                    tooltip: _copy(
                      context,
                      uz: 'Upload havolasi',
                      en: 'Upload link',
                    ),
                    onPressed: () => _openUploadSheet(context),
                    icon: const Icon(Icons.upload_file_rounded),
                  ),
                if (_tab == _ContentBackendTab.materials &&
                    library != null &&
                    widget.canManageContent)
                  IconButton(
                    key: const Key('backend-content-create-material'),
                    tooltip: _copy(
                      context,
                      uz: 'Material yaratish',
                      en: 'Create material',
                    ),
                    onPressed: () => _openCreateMaterial(context, library.id),
                    icon: const Icon(Icons.add_rounded),
                  ),
              ],
            ),
            Container(
              color: SfTheme.colorsOf(context).surface,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: SfSegmentedControl<_ContentBackendTab>(
                expanded: true,
                value: _tab,
                onChanged: (value) => setState(() => _tab = value),
                segments: [
                  SfSegment(
                    value: _ContentBackendTab.hierarchy,
                    label: _copy(context, uz: 'Tuzilma', en: 'Structure'),
                    icon: Icons.account_tree_outlined,
                  ),
                  SfSegment(
                    value: _ContentBackendTab.files,
                    label: _copy(context, uz: 'Fayllar', en: 'Files'),
                    icon: Icons.folder_copy_outlined,
                  ),
                  SfSegment(
                    value: _ContentBackendTab.materials,
                    label: _copy(context, uz: 'Material', en: 'Materials'),
                    icon: Icons.auto_stories_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _buildBody(context),
      );
    },
  );

  Widget _buildBody(BuildContext context) {
    if (_controller.isInitialLoading) {
      return SfLoadingState(
        label: _copy(
          context,
          uz: 'Kontent yuklanmoqda…',
          en: 'Loading content…',
        ),
        message: _copy(
          context,
          uz: 'Kutubxonalar va ruxsatlar tekshirilmoqda',
          en: 'Checking libraries and permissions',
        ),
      );
    }
    if (_controller.isUnavailable) {
      return SfServiceUnavailable(
        title: _copy(
          context,
          uz: 'Kontentga ruxsat yo‘q',
          en: 'Content unavailable',
        ),
        message: _copy(
          context,
          uz: 'Bu xodim hisobiga kontent moduli biriktirilmagan.',
          en: 'This staff account does not have access to the content module.',
        ),
        statusLabel: 'CONTENT · RESTRICTED',
        retryLabel: _copy(context, uz: 'Qayta tekshirish', en: 'Check again'),
        onRetry: () => _controller.refresh(showSpinner: true),
      );
    }
    if (_controller.hasError && !_controller.hasRenderableData) {
      return SfServiceUnavailable(
        title: _copy(
          context,
          uz: 'Kontent xizmati vaqtincha ishlamayapti',
          en: 'Content service is temporarily unavailable',
        ),
        message:
            _controller.errorMessage ??
            _copy(
              context,
              uz: 'Server bilan xavfsiz aloqa o‘rnatilmadi.',
              en: 'A secure connection to the server could not be established.',
            ),
        statusLabel: 'CONTENT · OFFLINE',
        retryLabel: _copy(context, uz: 'Qayta urinish', en: 'Try again'),
        onRetry: () => _controller.refresh(showSpinner: true),
      );
    }
    if (_controller.phase == BackendLoadPhase.empty) {
      return SfEmptyState(
        title: _copy(
          context,
          uz: 'Kutubxona topilmadi',
          en: 'No libraries yet',
        ),
        message: _copy(
          context,
          uz: 'Server bu xodim uchun faol kutubxona qaytarmadi.',
          en: 'The server returned no active library for this staff account.',
        ),
        actionLabel: _copy(context, uz: 'Yangilash', en: 'Refresh'),
        onAction: _controller.refresh,
      );
    }

    final child = switch (_tab) {
      _ContentBackendTab.hierarchy => _HierarchyView(controller: _controller),
      _ContentBackendTab.files => _FilesView(
        controller: _controller,
        onOpen: (file) => _openContentFile(context, file),
        onApproveTeacher: widget.canApproveContent
            ? (file) => _approveTeacher(context, file)
            : null,
        onApproveManager: widget.canApproveContent
            ? (file) => _approveManager(context, file)
            : null,
        onGetLink: (file) => _showDownloadLink(context, file),
        onNewVersion: widget.canManageContent
            ? (file) => _openUploadSheet(context, previous: file)
            : null,
      ),
      _ContentBackendTab.materials => _MaterialsView(
        controller: _controller,
        onGenerate: widget.canGenerateContent
            ? (material) => _generateMaterial(context, material)
            : null,
        onPublish: widget.canPublishContent
            ? (material) => _publishMaterial(context, material)
            : null,
      ),
    };
    return AnimatedSwitcher(
      duration: SfMotion.resolve(context, SfMotion.standard),
      switchInCurve: SfMotion.enter,
      switchOutCurve: SfMotion.exit,
      child: KeyedSubtree(key: ValueKey(_tab), child: child),
    );
  }

  Future<void> _approveTeacher(BuildContext context, BackendContentFile file) =>
      _runAction(
        context,
        action: () => _controller.approveTeacher(file.id),
        success: _copy(
          context,
          uz: 'O‘qituvchi tasdig‘i saqlandi',
          en: 'Teacher approval saved',
        ),
      );

  Future<void> _approveManager(
    BuildContext context,
    BackendContentFile file,
  ) async {
    final downloadable = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _copy(
                sheetContext,
                uz: 'Manager tasdig‘i',
                en: 'Manager approval',
              ),
              style: SfType.ui(size: 20, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              file.title,
              style: SfType.ui(
                size: 13,
                color: SfTheme.colorsOf(sheetContext).muted,
              ),
            ),
            const SizedBox(height: 16),
            SfButton(
              block: true,
              leading: Icons.download_done_rounded,
              label: _copy(
                sheetContext,
                uz: 'Tasdiqlash va yuklashga ruxsat',
                en: 'Approve and allow download',
              ),
              onPressed: () => Navigator.pop(sheetContext, true),
            ),
            const SizedBox(height: 10),
            SfButton(
              block: true,
              kind: SfButtonKind.ghost,
              leading: Icons.visibility_outlined,
              label: _copy(
                sheetContext,
                uz: 'Tasdiqlash, faqat ko‘rish',
                en: 'Approve as view only',
              ),
              onPressed: () => Navigator.pop(sheetContext, false),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || downloadable == null) return;
    await _runAction(
      context,
      action: () =>
          _controller.approveManager(file.id, downloadable: downloadable),
      success: _copy(
        context,
        uz: 'Menejer tasdig‘i saqlandi',
        en: 'Manager approval saved',
      ),
    );
  }

  Future<void> _generateMaterial(
    BuildContext context,
    BackendMaterial material,
  ) async {
    try {
      final request = await _controller.generateMaterial(material.id);
      if (!context.mounted) return;
      SfToast.show(
        context,
        title: _copy(
          context,
          uz: 'AI navbatga qo‘shildi',
          en: 'AI request queued',
        ),
        message: _copy(
          context,
          uz: 'So‘rov #${request.requestId} · ${request.status}',
          en: 'Request #${request.requestId} · ${request.status}',
        ),
        tone: SfToastTone.success,
      );
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _publishMaterial(
    BuildContext context,
    BackendMaterial material,
  ) => _runAction(
    context,
    action: () => _controller.publishMaterial(material.id),
    success: _copy(
      context,
      uz: 'Material e’lon qilindi',
      en: 'Material published',
    ),
  );

  Future<void> _showDownloadLink(
    BuildContext context,
    BackendContentFile file,
  ) async {
    try {
      final url = await _controller.requestDownloadUrl(file.id);
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.title,
                  style: SfType.ui(size: 20, weight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const SfHintCard(
                  compact: true,
                  title: 'Temporary server link',
                  message:
                      'This is a signed download URL. Treat it as private and share only with an authorized colleague.',
                ),
                const SizedBox(height: 14),
                SelectableText(url, style: SfType.mono(size: 11, height: 1.4)),
                const SizedBox(height: 16),
                SfButton(
                  block: true,
                  leading: Icons.copy_rounded,
                  label: _copy(
                    sheetContext,
                    uz: 'Havolani nusxalash',
                    en: 'Copy link',
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _openContentFile(
    BuildContext context,
    BackendContentFile file,
  ) async {
    final kind = sfMediaKindForContentType(file.contentType);
    if (kind == null) {
      await _showDownloadLink(context, file);
      return;
    }

    try {
      final url = await _controller.requestPlaybackUrl(file.id);
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final c = SfTheme.colorsOf(sheetContext);
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.92,
            ),
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.borderStrong,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kind == SfMediaKind.video
                                  ? _copy(
                                      sheetContext,
                                      uz: 'Video dars',
                                      en: 'Video lesson',
                                    )
                                  : _copy(
                                      sheetContext,
                                      uz: 'Audio material',
                                      en: 'Audio material',
                                    ),
                              style: SfType.eyebrow(color: c.primary),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              file.title.isEmpty
                                  ? 'File #${file.id}'
                                  : file.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: SfType.ui(
                                size: 18,
                                weight: FontWeight.w800,
                                color: c.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: _copy(sheetContext, uz: 'Yopish', en: 'Close'),
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SfNetworkMediaPlayer(
                    key: ValueKey('backend-media-player-${file.id}'),
                    url: url,
                    title: file.title.isEmpty ? 'File #${file.id}' : file.title,
                    subtitle: [
                      if (file.lessonTitle.isNotEmpty) file.lessonTitle,
                      if (file.folderName.isNotEmpty) file.folderName,
                    ].join(' · '),
                    kind: kind,
                    refreshUrl: () => _controller.requestPlaybackUrl(file.id),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _copy(
                      sheetContext,
                      uz: 'Media vaqtinchalik xavfsiz server havolasidan uzatilmoqda.',
                      en: 'Media is streaming from a short-lived secure server link.',
                    ),
                    textAlign: TextAlign.center,
                    style: SfType.ui(size: 10.5, color: c.muted),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _openUploadSheet(
    BuildContext context, {
    BackendContentFile? previous,
  }) async {
    final grant = await showModalBottomSheet<BackendUploadGrant>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _UploadGrantSheet(
        controller: _controller,
        lessons: _controller.lessons,
        folders: _controller.folders,
        previous: previous,
      ),
    );
    if (!context.mounted || grant == null) return;
    SfToast.show(
      context,
      title: _copy(
        context,
        uz: 'Fayl xavfsiz yuklandi',
        en: 'File uploaded securely',
      ),
      message: _copy(
        context,
        uz: 'Server faylni qabul qildi va tekshiruvga yubordi.',
        en: 'The server received the file and queued its validation.',
      ),
      tone: SfToastTone.success,
    );
  }

  Future<void> _openCreateMaterial(BuildContext context, int libraryId) async {
    final created = await showModalBottomSheet<BackendMaterial>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) =>
          _CreateMaterialSheet(controller: _controller, libraryId: libraryId),
    );
    if (!context.mounted || created == null) return;
    SfToast.show(
      context,
      message: _copy(context, uz: 'Material yaratildi', en: 'Material created'),
      tone: SfToastTone.success,
    );
  }

  Future<void> _runAction<T>(
    BuildContext context, {
    required Future<T> Function() action,
    required String success,
  }) async {
    try {
      await action();
      if (!context.mounted) return;
      SfToast.show(context, message: success, tone: SfToastTone.success);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }
}

class _HierarchyView extends StatelessWidget {
  const _HierarchyView({required this.controller});

  final BackendContentController controller;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return RefreshIndicator.adaptive(
      onRefresh: controller.refresh,
      child: ListView(
        key: const PageStorageKey('backend-content-hierarchy'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          if (controller.hasError && controller.hasRenderableData) ...[
            SfHintCard(
              tone: SfHintTone.danger,
              title: _copy(
                context,
                uz: 'Yangilash tugamadi',
                en: 'Refresh incomplete',
              ),
              message: controller.errorMessage ?? 'Unknown error',
              actionLabel: _copy(context, uz: 'Qayta urinish', en: 'Retry'),
              onAction: controller.refresh,
            ),
            const SizedBox(height: 14),
          ],
          _SectionHeading(
            title: _copy(context, uz: 'Kutubxonalar', en: 'Libraries'),
            trailing: '${controller.libraries.length}',
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.libraries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final library = controller.libraries[index];
                final selected = library.id == controller.selectedLibraryId;
                return _LibraryChoice(
                  library: library,
                  selected: selected,
                  onPressed: () => controller.selectLibrary(library.id),
                );
              },
            ),
          ),
          if (controller.hasMoreLibraries) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: SfButton(
                kind: SfButtonKind.ghost,
                label: _copy(
                  context,
                  uz: 'Ko‘proq kutubxona',
                  en: 'More libraries',
                ),
                onPressed: controller.loadingMore
                    ? null
                    : controller.loadMoreLibraries,
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (controller.hierarchyUnavailable)
            SfHintCard(
              tone: SfHintTone.warning,
              title: _copy(
                context,
                uz: 'Tuzilma cheklangan',
                en: 'Structure restricted',
              ),
              message: _copy(
                context,
                uz: 'Kurs yoki papka ma’lumotlari bu rolda ochilmadi.',
                en: 'Course or folder data is not available for this role.',
              ),
            )
          else ...[
            _SectionHeading(
              title: _copy(context, uz: 'Kurslar', en: 'Courses'),
              trailing: '${controller.courses.length}',
            ),
            const SizedBox(height: 9),
            _ChoiceWrap(
              items: controller.courses,
              selectedId: controller.selectedCourseId,
              onSelected: controller.selectCourse,
            ),
            const SizedBox(height: 18),
            _SectionHeading(
              title: _copy(context, uz: 'Modullar', en: 'Modules'),
              trailing: '${controller.modules.length}',
            ),
            const SizedBox(height: 9),
            _ChoiceWrap(
              items: controller.modules,
              selectedId: controller.selectedModuleId,
              onSelected: controller.selectModule,
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 620;
                final folders = _NodePanel(
                  icon: Icons.folder_open_rounded,
                  title: _copy(context, uz: 'Papkalar', en: 'Folders'),
                  empty: _copy(context, uz: 'Papka yo‘q', en: 'No folders'),
                  items: controller.folders,
                );
                final lessons = _NodePanel(
                  icon: Icons.menu_book_rounded,
                  title: _copy(
                    context,
                    uz: 'Dars kontenti',
                    en: 'Content lessons',
                  ),
                  empty: _copy(
                    context,
                    uz: 'Dars kontenti yo‘q',
                    en: 'No content lessons',
                  ),
                  items: controller.lessons,
                );
                if (!wide) {
                  return Column(
                    children: [folders, const SizedBox(height: 14), lessons],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: folders),
                    const SizedBox(width: 14),
                    Expanded(child: lessons),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 18),
          SfHintCard(
            compact: true,
            icon: Icons.verified_user_outlined,
            title: _copy(context, uz: 'Server manbasi', en: 'Server source'),
            message: _copy(
              context,
              uz: 'Bu ro‘yxat qurilma demo ma’lumotlari emas. Tortib yangilash prod serverdan qayta o‘qiydi.',
              en: 'This is not device demo data. Pull to refresh reads the production server again.',
            ),
          ),
          if (controller.phase == BackendLoadPhase.loading) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(color: c.primary),
          ],
        ],
      ),
    );
  }
}

class _FilesView extends StatefulWidget {
  const _FilesView({
    required this.controller,
    required this.onOpen,
    required this.onApproveTeacher,
    required this.onApproveManager,
    required this.onGetLink,
    required this.onNewVersion,
  });

  final BackendContentController controller;
  final ValueChanged<BackendContentFile> onOpen;
  final ValueChanged<BackendContentFile>? onApproveTeacher;
  final ValueChanged<BackendContentFile>? onApproveManager;
  final ValueChanged<BackendContentFile> onGetLink;
  final ValueChanged<BackendContentFile>? onNewVersion;

  @override
  State<_FilesView> createState() => _FilesViewState();
}

class _FilesViewState extends State<_FilesView> {
  final _search = TextEditingController();
  _BackendFileFilter _filter = _BackendFileFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final query = _search.text.trim().toLowerCase();
    final visible = controller.files
        .where((file) {
          final type = file.contentType.toLowerCase();
          final matchesType = switch (_filter) {
            _BackendFileFilter.all => true,
            _BackendFileFilter.video => type.startsWith('video/'),
            _BackendFileFilter.audio => type.startsWith('audio/'),
            _BackendFileFilter.images => type.startsWith('image/'),
            _BackendFileFilter.documents =>
              !type.startsWith('video/') &&
                  !type.startsWith('audio/') &&
                  !type.startsWith('image/'),
          };
          final haystack =
              '${file.title} ${file.lessonTitle} ${file.folderName} ${file.contentType}'
                  .toLowerCase();
          return matchesType && (query.isEmpty || haystack.contains(query));
        })
        .toList(growable: false);
    final videoCount = controller.files
        .where((file) => file.contentType.startsWith('video/'))
        .length;
    final audioCount = controller.files
        .where((file) => file.contentType.startsWith('audio/'))
        .length;

    return RefreshIndicator.adaptive(
      onRefresh: controller.refresh,
      child: ListView(
        key: const PageStorageKey('backend-content-files'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          _MediaLibrarySummary(
            total: controller.files.length,
            videos: videoCount,
            audio: audioCount,
          ),
          const SizedBox(height: 14),
          SfSearchField(
            key: const Key('backend-content-file-search'),
            controller: _search,
            hintText: _copy(
              context,
              uz: 'Material, dars yoki papkani izlash',
              en: 'Search material, lesson, or folder',
            ),
            onChanged: (_) => setState(() {}),
            clearTooltip: _copy(context, uz: 'Tozalash', en: 'Clear'),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SfSegmentedControl<_BackendFileFilter>(
              value: _filter,
              onChanged: (value) => setState(() => _filter = value),
              segments: [
                SfSegment(
                  value: _BackendFileFilter.all,
                  label: _copy(context, uz: 'Hammasi', en: 'All'),
                ),
                SfSegment(
                  value: _BackendFileFilter.video,
                  label: _copy(context, uz: 'Video', en: 'Video'),
                  icon: Icons.play_circle_outline_rounded,
                ),
                SfSegment(
                  value: _BackendFileFilter.audio,
                  label: _copy(context, uz: 'Audio', en: 'Audio'),
                  icon: Icons.headphones_rounded,
                ),
                SfSegment(
                  value: _BackendFileFilter.documents,
                  label: _copy(context, uz: 'Hujjat', en: 'Documents'),
                  icon: Icons.description_outlined,
                ),
                SfSegment(
                  value: _BackendFileFilter.images,
                  label: _copy(context, uz: 'Rasm', en: 'Images'),
                  icon: Icons.image_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SfSegmentedControl<String?>(
              value: controller.fileStatus,
              onChanged: controller.setFileStatus,
              segments: [
                SfSegment(
                  value: null,
                  label: _copy(context, uz: 'Barcha holat', en: 'All status'),
                ),
                const SfSegment(value: 'pending', label: 'Pending'),
                const SfSegment(value: 'clean', label: 'Ready'),
                const SfSegment(value: 'rejected', label: 'Rejected'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (controller.hasError && controller.hasRenderableData) ...[
            SfHintCard(
              compact: true,
              tone: SfHintTone.danger,
              message: controller.errorMessage ?? 'Unknown error',
              actionLabel: _copy(context, uz: 'Qayta urinish', en: 'Retry'),
              onAction: controller.refresh,
            ),
            const SizedBox(height: 12),
          ],
          const SfHintCard(
            compact: true,
            icon: Icons.shield_outlined,
            title: 'Presigned upload workflow',
            message:
                'Video and audio stream in the app from short-lived signed links. An upload link creates a server grant; it does not mean the file was uploaded.',
          ),
          const SizedBox(height: 14),
          if (controller.filesUnavailable)
            SfErrorState(
              compact: true,
              title: _copy(
                context,
                uz: 'Fayllarga ruxsat yo‘q',
                en: 'Files restricted',
              ),
            )
          else if (visible.isEmpty)
            SfEmptyState(
              compact: true,
              icon: Icons.folder_off_outlined,
              title: _copy(
                context,
                uz: 'Material topilmadi',
                en: 'No matching material',
              ),
              message: _copy(
                context,
                uz: 'Izlash, tur yoki server holati filtrini o‘zgartiring.',
                en: 'Change the search, media type, or server status filter.',
              ),
              actionLabel: query.isNotEmpty || _filter != _BackendFileFilter.all
                  ? _copy(context, uz: 'Filtrni tozalash', en: 'Clear filters')
                  : null,
              onAction: query.isNotEmpty || _filter != _BackendFileFilter.all
                  ? () {
                      _search.clear();
                      setState(() => _filter = _BackendFileFilter.all);
                    }
                  : null,
            )
          else
            AnimatedSwitcher(
              duration: SfMotion.resolve(context, SfMotion.standard),
              child: Column(
                key: ValueKey('${_filter.name}-$query-${visible.length}'),
                children: [
                  for (final file in visible) ...[
                    _FileCard(
                      file: file,
                      onOpen: () => widget.onOpen(file),
                      onApproveTeacher: widget.onApproveTeacher == null
                          ? null
                          : () => widget.onApproveTeacher!(file),
                      onApproveManager: widget.onApproveManager == null
                          ? null
                          : () => widget.onApproveManager!(file),
                      onGetLink: () => widget.onGetLink(file),
                      onNewVersion: widget.onNewVersion == null
                          ? null
                          : () => widget.onNewVersion!(file),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          if (controller.hasMoreFiles)
            SfButton(
              kind: SfButtonKind.ghost,
              block: true,
              label: _copy(context, uz: 'Ko‘proq fayl', en: 'Load more files'),
              onPressed: controller.loadingMore
                  ? null
                  : controller.loadMoreFiles,
            ),
        ],
      ),
    );
  }
}

class _MediaLibrarySummary extends StatelessWidget {
  const _MediaLibrarySummary({
    required this.total,
    required this.videos,
    required this.audio,
  });

  final int total;
  final int videos;
  final int audio;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary, c.primaryHover, c.accent],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.video_library_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _copy(context, uz: 'Media kutubxonasi', en: 'Media library'),
                  style: SfType.ui(
                    size: 17,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _copy(
                    context,
                    uz: '$total material · $videos video · $audio audio',
                    en: '$total materials · $videos video · $audio audio',
                  ),
                  style: SfType.ui(
                    size: 11,
                    color: Colors.white.withValues(alpha: 0.80),
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

class _MaterialsView extends StatelessWidget {
  const _MaterialsView({
    required this.controller,
    required this.onGenerate,
    required this.onPublish,
  });

  final BackendContentController controller;
  final ValueChanged<BackendMaterial>? onGenerate;
  final ValueChanged<BackendMaterial>? onPublish;

  @override
  Widget build(BuildContext context) => RefreshIndicator.adaptive(
    onRefresh: controller.refresh,
    child: ListView(
      key: const PageStorageKey('backend-content-materials'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        if (controller.hasError && controller.hasRenderableData) ...[
          SfHintCard(
            compact: true,
            tone: SfHintTone.danger,
            message: controller.errorMessage ?? 'Unknown error',
            actionLabel: _copy(context, uz: 'Qayta urinish', en: 'Retry'),
            onAction: controller.refresh,
          ),
          const SizedBox(height: 12),
        ],
        if (controller.materialsUnavailable)
          SfErrorState(
            compact: true,
            title: _copy(
              context,
              uz: 'Materiallarga ruxsat yo‘q',
              en: 'Materials restricted',
            ),
          )
        else if (controller.materials.isEmpty)
          SfEmptyState(
            compact: true,
            icon: Icons.auto_stories_outlined,
            title: _copy(context, uz: 'Material yo‘q', en: 'No materials yet'),
            message: _copy(
              context,
              uz: 'Tanlangan kutubxonada material yaratilmagan.',
              en: 'The selected library has no generated material yet.',
            ),
          )
        else
          for (final material in controller.materials) ...[
            _MaterialCard(
              material: material,
              onGenerate: onGenerate == null
                  ? null
                  : () => onGenerate!(material),
              onPublish: material.status == 'published' || onPublish == null
                  ? null
                  : () => onPublish!(material),
            ),
            const SizedBox(height: 12),
          ],
        if (controller.hasMoreMaterials)
          SfButton(
            block: true,
            kind: SfButtonKind.ghost,
            label: _copy(
              context,
              uz: 'Ko‘proq material',
              en: 'Load more materials',
            ),
            onPressed: controller.loadingMore
                ? null
                : controller.loadMoreMaterials,
          ),
      ],
    ),
  );
}

class _LibraryChoice extends StatelessWidget {
  const _LibraryChoice({
    required this.library,
    required this.selected,
    required this.onPressed,
  });

  final BackendContentLibrary library;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SizedBox(
      width: 210,
      child: SfPressable(
        onPressed: onPressed,
        selected: selected,
        haptic: true,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: SfMotion.resolve(context, SfMotion.quick),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected ? c.primarySoft : c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? c.primary : c.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected ? c.primary : c.surface2,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.local_library_outlined,
                  color: selected ? c.bg : c.ink2,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      library.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SfType.ui(
                        size: 13,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      library.visibility,
                      style: SfType.ui(size: 11, color: c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  final List<BackendContentNode> items;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        '—',
        style: SfType.ui(size: 14, color: SfTheme.colorsOf(context).muted),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          ChoiceChip(
            label: Text(item.title.isEmpty ? '#${item.id}' : item.title),
            selected: item.id == selectedId,
            onSelected: (_) => onSelected(item.id),
          ),
      ],
    );
  }
}

class _NodePanel extends StatelessWidget {
  const _NodePanel({
    required this.icon,
    required this.title,
    required this.empty,
    required this.items,
  });

  final IconData icon;
  final String title;
  final String empty;
  final List<BackendContentNode> items;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: c.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: SfType.ui(
                    size: 14,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
              ),
              SfPill(label: '${items.length}'),
            ],
          ),
          const SizedBox(height: 11),
          if (items.isEmpty)
            Text(empty, style: SfType.ui(size: 12, color: c.muted))
          else
            for (var index = 0; index < items.length; index++) ...[
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: SfType.mono(size: 10, color: c.muted),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      items[index].title.isEmpty
                          ? '#${items[index].id}'
                          : items[index].title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SfType.ui(size: 12.5, color: c.ink2),
                    ),
                  ),
                ],
              ),
              if (index != items.length - 1) const SizedBox(height: 9),
            ],
        ],
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.file,
    required this.onOpen,
    required this.onApproveTeacher,
    required this.onApproveManager,
    required this.onGetLink,
    required this.onNewVersion,
  });

  final BackendContentFile file;
  final VoidCallback onOpen;
  final VoidCallback? onApproveTeacher;
  final VoidCallback? onApproveManager;
  final VoidCallback onGetLink;
  final VoidCallback? onNewVersion;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final mediaKind = sfMediaKindForContentType(file.contentType);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _statusTone(file.status, c).$2,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _fileIcon(file.contentType),
                  color: _statusTone(file.status, c).$1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.title.isEmpty ? 'File #${file.id}' : file.title,
                      style: SfType.ui(
                        size: 15,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (file.lessonTitle.isNotEmpty) file.lessonTitle,
                        if (file.folderName.isNotEmpty) file.folderName,
                        _bytes(file.sizeBytes),
                        'v${file.version}',
                      ].join(' · '),
                      style: SfType.ui(size: 11.5, color: c.muted),
                    ),
                  ],
                ),
              ),
              SfPill(
                label: file.status,
                tone: switch (file.status) {
                  'clean' => SfPillTone.success,
                  'rejected' => SfPillTone.danger,
                  _ => SfPillTone.warn,
                },
              ),
            ],
          ),
          if (file.rejectReason.isNotEmpty) ...[
            const SizedBox(height: 12),
            SfHintCard(
              compact: true,
              tone: SfHintTone.danger,
              title: _copy(
                context,
                uz: 'Rad etish sababi',
                en: 'Rejection reason',
              ),
              message: file.rejectReason,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              SfPill(
                label: file.approvedByTeacher
                    ? _copy(context, uz: 'Teacher ✓', en: 'Teacher ✓')
                    : _copy(
                        context,
                        uz: 'Teacher kutilmoqda',
                        en: 'Teacher pending',
                      ),
                tone: file.approvedByTeacher
                    ? SfPillTone.success
                    : SfPillTone.neutral,
              ),
              SfPill(
                label: file.approvedByManager
                    ? _copy(context, uz: 'Manager ✓', en: 'Manager ✓')
                    : _copy(
                        context,
                        uz: 'Manager kutilmoqda',
                        en: 'Manager pending',
                      ),
                tone: file.approvedByManager
                    ? SfPillTone.success
                    : SfPillTone.neutral,
              ),
              SfPill(
                label: file.isDownloadable
                    ? _copy(context, uz: 'Yuklanadi', en: 'Downloadable')
                    : _copy(context, uz: 'Faqat ko‘rish', en: 'View only'),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (mediaKind != null)
                SfButton(
                  label: mediaKind == SfMediaKind.video
                      ? _copy(context, uz: 'Videoni ko‘rish', en: 'Watch video')
                      : _copy(context, uz: 'Audio tinglash', en: 'Play audio'),
                  leading: mediaKind == SfMediaKind.video
                      ? Icons.play_circle_fill_rounded
                      : Icons.headphones_rounded,
                  onPressed: onOpen,
                )
              else
                SfButton(
                  kind: SfButtonKind.soft,
                  label: _copy(context, uz: 'Ochish', en: 'Open'),
                  leading: Icons.open_in_new_rounded,
                  onPressed: onOpen,
                ),
              SfButton(
                kind: SfButtonKind.ghost,
                label: _copy(context, uz: 'Havola', en: 'Get link'),
                leading: Icons.link_rounded,
                onPressed: onGetLink,
              ),
              if (onNewVersion != null)
                SfButton(
                  kind: SfButtonKind.ghost,
                  label: _copy(context, uz: 'Yangi versiya', en: 'New version'),
                  leading: Icons.upload_file_outlined,
                  onPressed: onNewVersion,
                ),
              if (!file.approvedByTeacher && onApproveTeacher != null)
                SfButton(
                  kind: SfButtonKind.soft,
                  label: _copy(
                    context,
                    uz: 'Teacher tasdiq',
                    en: 'Teacher approve',
                  ),
                  leading: Icons.school_outlined,
                  onPressed: onApproveTeacher,
                ),
              if (file.approvedByTeacher &&
                  !file.approvedByManager &&
                  onApproveManager != null)
                SfButton(
                  label: _copy(
                    context,
                    uz: 'Manager tasdiq',
                    en: 'Manager approve',
                  ),
                  leading: Icons.verified_outlined,
                  onPressed: onApproveManager,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    required this.material,
    required this.onGenerate,
    required this.onPublish,
  });

  final BackendMaterial material;
  final VoidCallback? onGenerate;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  material.title,
                  style: SfType.ui(
                    size: 16,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
              ),
              SfPill(
                label: material.status,
                tone: material.status == 'published'
                    ? SfPillTone.success
                    : SfPillTone.warn,
              ),
            ],
          ),
          if (material.topic.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(material.topic, style: SfType.ui(size: 12, color: c.primary)),
          ],
          const SizedBox(height: 10),
          Text(
            material.body.isEmpty
                ? _copy(
                    context,
                    uz: 'Tana hali yaratilmagan. AI generatsiyasini navbatga qo‘yish mumkin.',
                    en: 'No body yet. You can queue server-side AI generation.',
                  )
                : material.body,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: SfType.ui(size: 12.5, color: c.ink2, height: 1.45),
          ),
          const SizedBox(height: 12),
          Text(
            '${material.libraryName} · ${material.createdByName.isEmpty ? '—' : material.createdByName}'
            '${material.updatedAt == null ? '' : ' · ${SfFormatters.compactDateUz(material.updatedAt!)}'}',
            style: SfType.ui(size: 11, color: c.muted),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onGenerate != null)
                SfButton(
                  kind: SfButtonKind.soft,
                  leading: Icons.auto_awesome_rounded,
                  label: _copy(
                    context,
                    uz: 'AI yaratish',
                    en: 'Generate with AI',
                  ),
                  onPressed: onGenerate,
                ),
              if (onPublish != null)
                SfButton(
                  leading: Icons.publish_rounded,
                  label: _copy(context, uz: 'E’lon qilish', en: 'Publish'),
                  onPressed: onPublish,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadGrantSheet extends StatefulWidget {
  const _UploadGrantSheet({
    required this.controller,
    required this.lessons,
    required this.folders,
    this.previous,
  });

  final BackendContentController controller;
  final List<BackendContentNode> lessons;
  final List<BackendContentNode> folders;
  final BackendContentFile? previous;

  @override
  State<_UploadGrantSheet> createState() => _UploadGrantSheetState();
}

class _UploadGrantSheetState extends State<_UploadGrantSheet> {
  final _formKey = GlobalKey<FormState>();
  final _filename = TextEditingController();
  final _title = TextEditingController();
  final _contentType = TextEditingController(text: 'application/pdf');
  final _size = TextEditingController();
  final _uploader = ContentBinaryUploader();
  PlatformFile? _pickedFile;
  int? _lessonId;
  int? _folderId;
  bool _loading = false;
  bool _destinationMissing = false;
  double _progress = 0;
  BackendUploadGrant? _grant;

  @override
  void dispose() {
    _filename.dispose();
    _title.dispose();
    _contentType.dispose();
    _size.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (_loading) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'ppt',
        'pptx',
        'xls',
        'xlsx',
        'txt',
        'csv',
        'png',
        'jpg',
        'jpeg',
        'webp',
        'mp3',
        'm4a',
        'wav',
        'mp4',
        'mov',
      ],
      allowMultiple: false,
      withData: false,
    );
    final file = result?.files.singleOrNull;
    if (!mounted || file == null) return;
    if (file.size <= 0) {
      _showError(
        context,
        _copy(
          context,
          uz: 'Bo\'sh faylni yuklab bo\'lmaydi.',
          en: 'An empty file cannot be uploaded.',
        ),
      );
      return;
    }
    setState(() {
      _pickedFile = file;
      _grant = null;
      _progress = 0;
      _filename.text = file.name;
      _contentType.text = _contentTypeFor(file);
      _size.text = '${file.size}';
      if (_title.text.trim().isEmpty) {
        _title.text = _displayNameWithoutExtension(file.name);
      }
    });
  }

  Future<void> _request() async {
    if (_loading) return;
    if (_pickedFile == null) {
      await _pickFile();
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.previous == null && _lessonId == null && _folderId == null) {
      setState(() => _destinationMissing = true);
      return;
    }
    setState(() {
      _loading = true;
      _destinationMissing = false;
      _progress = .02;
    });
    try {
      final file = _pickedFile!;
      final previous = widget.previous;
      final grant =
          _grant ??
          (previous == null
              ? await widget.controller.requestUpload(
                  filename: _filename.text.trim(),
                  contentType: _contentType.text.trim(),
                  sizeBytes: int.parse(_size.text.trim()),
                  title: _title.text.trim(),
                  lessonId: _lessonId,
                  folderId: _folderId,
                )
              : await widget.controller.requestNewVersion(
                  fileId: previous.id,
                  filename: _filename.text.trim(),
                  contentType: _contentType.text.trim(),
                  sizeBytes: int.parse(_size.text.trim()),
                ));
      if (grant.method.toUpperCase() != 'PUT' || grant.fileId == null) {
        throw const ContentUploadException(
          'The server returned an incomplete upload grant.',
        );
      }
      if (mounted) setState(() => _grant = grant);
      await _uploader.put(
        url: grant.url,
        contentType: _contentType.text.trim(),
        expectedBytes: file.size,
        openRead: file.xFile.openRead,
        onProgress: (value) {
          final next = .05 + (value * .85);
          // Native file streams can emit hundreds of chunks per second. A
          // one-percent visual cadence stays fluid without rebuilding the
          // entire sheet for every storage packet.
          if (mounted && (next - _progress >= .01 || value >= 1)) {
            setState(() => _progress = next);
          }
        },
      );
      if (mounted) setState(() => _progress = .94);
      await widget.controller.confirmUpload(grant.fileId!);
      if (!mounted) return;
      setState(() => _progress = 1);
      Navigator.pop(context, grant);
    } catch (error) {
      if (mounted) {
        // Presigned upload links are deliberately short-lived and a failed
        // transfer may have partially consumed one. Always request a fresh
        // grant on retry instead of looping on an expired or dirty URL.
        setState(() => _grant = null);
        _showError(context, error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(child: _form(context)),
    );
  }

  Widget _form(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _copy(
            context,
            uz: widget.previous == null
                ? 'Fayl yuklash'
                : 'Yangi versiya yuklash',
            en: widget.previous == null
                ? 'Upload a file'
                : 'Upload a new version',
          ),
          style: SfType.ui(size: 20, weight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SfHintCard(
          compact: true,
          tone: SfHintTone.info,
          title: _copy(
            context,
            uz: 'Xavfsiz to\'g\'ridan-to\'g\'ri yuklash',
            en: 'Secure direct upload',
          ),
          message: _copy(
            context,
            uz: 'Fayl qurilmadan himoyalangan vaqtinchalik havola orqali yuboriladi va serverda avtomatik tasdiqlanadi.',
            en: 'The file is sent from this device through a protected temporary link, then confirmed automatically.',
          ),
        ),
        const SizedBox(height: 16),
        _PickedFileCard(
          file: _pickedFile,
          loading: _loading,
          onPick: _pickFile,
        ),
        const SizedBox(height: 12),
        Offstage(
          offstage: true,
          child: SfTextField(controller: _filename, validator: _requiredText),
        ),
        if (widget.previous == null && _pickedFile != null) ...[
          SfTextField(
            controller: _title,
            label: _copy(context, uz: 'Ko‘rinadigan nom', en: 'Display title'),
          ),
          const SizedBox(height: 12),
        ],
        Offstage(
          offstage: true,
          child: SfTextField(
            controller: _contentType,
            validator: _requiredText,
          ),
        ),
        Offstage(
          offstage: true,
          child: SfTextField(
            controller: _size,
            keyboardType: TextInputType.number,
          ),
        ),
        if (_pickedFile != null &&
            widget.previous == null &&
            widget.lessons.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            key: ValueKey(
              'upload-lesson-${_lessonId ?? 'none'}-${_folderId ?? 'none'}',
            ),
            initialValue: _lessonId,
            decoration: InputDecoration(
              labelText: _copy(
                context,
                uz: 'Dars (ixtiyoriy)',
                en: 'Lesson (optional)',
              ),
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(
                  _copy(context, uz: 'Tanlanmagan', en: 'Not selected'),
                ),
              ),
              for (final lesson in widget.lessons)
                DropdownMenuItem(value: lesson.id, child: Text(lesson.title)),
            ],
            onChanged: _loading
                ? null
                : (value) => setState(() {
                    _lessonId = value;
                    if (value != null) _folderId = null;
                    _grant = null;
                    _destinationMissing = false;
                  }),
          ),
        ],
        if (_pickedFile != null &&
            widget.previous == null &&
            widget.folders.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            key: ValueKey(
              'upload-folder-${_folderId ?? 'none'}-${_lessonId ?? 'none'}',
            ),
            initialValue: _folderId,
            decoration: InputDecoration(
              labelText: _copy(
                context,
                uz: 'Papka (ixtiyoriy)',
                en: 'Folder (optional)',
              ),
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(
                  _copy(context, uz: 'Tanlanmagan', en: 'Not selected'),
                ),
              ),
              for (final folder in widget.folders)
                DropdownMenuItem(value: folder.id, child: Text(folder.title)),
            ],
            onChanged: _loading
                ? null
                : (value) => setState(() {
                    _folderId = value;
                    if (value != null) _lessonId = null;
                    _grant = null;
                    _destinationMissing = false;
                  }),
          ),
        ],
        if (_pickedFile != null &&
            widget.previous == null &&
            widget.lessons.isEmpty &&
            widget.folders.isEmpty) ...[
          const SizedBox(height: 12),
          SfHintCard(
            compact: true,
            tone: SfHintTone.warning,
            title: _copy(
              context,
              uz: 'Yuklash joyi mavjud emas',
              en: 'No upload destination',
            ),
            message: _copy(
              context,
              uz: 'Avval sizga ochilgan dars yoki papka bo\'lishi kerak.',
              en: 'An available lesson or folder is required first.',
            ),
          ),
        ],
        if (_destinationMissing &&
            (widget.lessons.isNotEmpty || widget.folders.isNotEmpty)) ...[
          const SizedBox(height: 12),
          SfHintCard(
            compact: true,
            tone: SfHintTone.warning,
            title: _copy(
              context,
              uz: 'Joyni tanlang',
              en: 'Choose a destination',
            ),
            message: _copy(
              context,
              uz: 'Fayl dars yoki papkaga biriktirilishi kerak.',
              en: 'The file must be attached to a lesson or folder.',
            ),
          ),
        ],
        if (_loading) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              key: const Key('backend-content-upload-progress'),
              value: _progress.clamp(0, 1),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _progress >= .93
                ? _copy(
                    context,
                    uz: 'Serverda tasdiqlanmoqda…',
                    en: 'Confirming securely…',
                  )
                : _copy(
                    context,
                    uz: 'Yuklanmoqda · ${(_progress * 100).round()}%',
                    en: 'Uploading · ${(_progress * 100).round()}%',
                  ),
            style: SfType.ui(size: 11, color: SfTheme.colorsOf(context).muted),
          ),
        ],
        const SizedBox(height: 18),
        SfButton(
          key: const Key('backend-content-generate-upload-link'),
          block: true,
          leading: _pickedFile == null
              ? Icons.attach_file_rounded
              : Icons.cloud_upload_outlined,
          label: _loading
              ? _copy(context, uz: 'Yuklanmoqda…', en: 'Uploading…')
              : _pickedFile == null
              ? _copy(context, uz: 'Fayl tanlash', en: 'Choose file')
              : _copy(context, uz: 'Xavfsiz yuklash', en: 'Upload securely'),
          onPressed: _loading ? null : _request,
        ),
      ],
    ),
  );
}

class _PickedFileCard extends StatelessWidget {
  const _PickedFileCard({
    required this.file,
    required this.loading,
    required this.onPick,
  });

  final PlatformFile? file;
  final bool loading;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final selected = file;
    return SfSurfaceCard(
      padding: const EdgeInsets.all(14),
      color: selected == null ? c.surface2 : c.primarySoft,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected == null
                  ? c.surface3
                  : c.primary.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Icon(
              selected == null
                  ? Icons.note_add_outlined
                  : _pickedFileIcon(selected),
              color: c.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected?.name ??
                      _copy(
                        context,
                        uz: 'Fayl tanlanmagan',
                        en: 'No file selected',
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SfType.ui(
                    size: 13,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  selected == null
                      ? _copy(
                          context,
                          uz: 'Hujjat, rasm, audio yoki video',
                          en: 'Document, image, audio, or video',
                        )
                      : '${_bytes(selected.size)} · ${_contentTypeFor(selected)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SfType.ui(size: 10.5, color: c.muted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: loading ? null : onPick,
            child: Text(
              selected == null
                  ? _copy(context, uz: 'Tanlash', en: 'Choose')
                  : _copy(context, uz: 'Almashtirish', en: 'Replace'),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _pickedFileIcon(PlatformFile file) {
  final type = _contentTypeFor(file);
  if (type.startsWith('image/')) return Icons.image_outlined;
  if (type.startsWith('video/')) return Icons.movie_outlined;
  if (type.startsWith('audio/')) return Icons.audio_file_outlined;
  if (type == 'application/pdf') return Icons.picture_as_pdf_outlined;
  return Icons.description_outlined;
}

String _displayNameWithoutExtension(String filename) {
  final dot = filename.lastIndexOf('.');
  return dot > 0 ? filename.substring(0, dot) : filename;
}

String _contentTypeFor(PlatformFile file) => switch (file.extension
    ?.toLowerCase()) {
  'pdf' => 'application/pdf',
  'doc' => 'application/msword',
  'docx' =>
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'ppt' => 'application/vnd.ms-powerpoint',
  'pptx' =>
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'xls' => 'application/vnd.ms-excel',
  'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'txt' => 'text/plain',
  'csv' => 'text/csv',
  'png' => 'image/png',
  'jpg' || 'jpeg' => 'image/jpeg',
  'webp' => 'image/webp',
  'mp3' => 'audio/mpeg',
  'm4a' => 'audio/mp4',
  'wav' => 'audio/wav',
  'mp4' => 'video/mp4',
  'mov' => 'video/quicktime',
  _ => 'application/octet-stream',
};

class _CreateMaterialSheet extends StatefulWidget {
  const _CreateMaterialSheet({
    required this.controller,
    required this.libraryId,
  });

  final BackendContentController controller;
  final int libraryId;

  @override
  State<_CreateMaterialSheet> createState() => _CreateMaterialSheetState();
}

class _CreateMaterialSheetState extends State<_CreateMaterialSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _topic = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _topic.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final value = await widget.controller.createMaterial(
        libraryId: widget.libraryId,
        title: _title.text.trim(),
        topic: _topic.text.trim(),
      );
      if (mounted) Navigator.pop(context, value);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _copy(context, uz: 'Yangi material', en: 'New material'),
            style: SfType.ui(size: 20, weight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SfTextField(
            controller: _title,
            label: _copy(context, uz: 'Sarlavha', en: 'Title'),
            validator: _requiredText,
          ),
          const SizedBox(height: 12),
          SfTextField(
            controller: _topic,
            label: _copy(context, uz: 'Mavzu', en: 'Topic'),
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: 18),
          SfButton(
            block: true,
            label: _loading
                ? _copy(context, uz: 'Yaratilmoqda…', en: 'Creating…')
                : _copy(context, uz: 'Draft yaratish', en: 'Create draft'),
            onPressed: _loading ? null : _submit,
          ),
        ],
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: SfType.ui(size: 15, weight: FontWeight.w800, color: c.ink),
          ),
        ),
        Text(trailing, style: SfType.mono(size: 11, color: c.muted)),
      ],
    );
  }
}

(Color, Color) _statusTone(String status, SfColors c) => switch (status) {
  'clean' => (c.success, c.successSoft),
  'rejected' => (c.danger, c.dangerSoft),
  _ => (c.warn, c.warnSoft),
};

IconData _fileIcon(String contentType) {
  if (contentType.startsWith('video/')) {
    return Icons.play_circle_outline_rounded;
  }
  if (contentType.startsWith('audio/')) return Icons.headphones_rounded;
  if (contentType.startsWith('image/')) return Icons.image_outlined;
  if (contentType.contains('pdf')) return Icons.picture_as_pdf_outlined;
  return Icons.description_outlined;
}

String _bytes(int value) {
  if (value >= 1024 * 1024) {
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (value >= 1024) return '${(value / 1024).toStringAsFixed(0)} KB';
  return '$value B';
}

String? _requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;

void _showError(BuildContext context, Object error) => SfToast.show(
  context,
  title: _copy(
    context,
    uz: 'Server amali bajarilmadi',
    en: 'Server action failed',
  ),
  message: error.toString(),
  tone: SfToastTone.error,
);

String _copy(BuildContext context, {required String uz, required String en}) =>
    Localizations.maybeLocaleOf(context)?.languageCode == 'uz' ? uz : en;

void _goBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/more');
  }
}
