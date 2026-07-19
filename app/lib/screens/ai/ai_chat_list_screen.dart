import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/api/backend_services_api.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_ai_badge.dart';
import '../../widgets/sf_ai_surface.dart';
import '../../widgets/sf_bottom_navigation.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pressable.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_shell_scope.dart';
import '../../widgets/sf_star.dart';
import '../../widgets/sf_tab_bar.dart';
import '../services/backend_ai_screens.dart';
import 'ai_workspace_data.dart';

class AiChatListScreen extends StatefulWidget {
  const AiChatListScreen({super.key});

  @override
  State<AiChatListScreen> createState() => _AiChatListScreenState();
}

class _AiChatListScreenState extends State<AiChatListScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  bool _showSearch = false;

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) _search.clear();
    });
    if (_showSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    } else {
      _searchFocus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = AppScope.maybeOf(context)?.backendApi;
    if (backend != null) {
      return BackendAiWorkspaceScreen(api: BackendServicesApi.fromApi(backend));
    }
    final c = SfTheme.colorsOf(context);
    final copy = AiWorkspaceCopy.of(context);
    final usesShellNavigation =
        SfShellScope.maybeOf(context)?.suppressEmbeddedNavigation ?? false;
    final query = _search.text.trim().toLowerCase();
    final groups = copy.staffGroups
        .where((group) => query.isEmpty || group.searchableText.contains(query))
        .toList(growable: false);
    final suggestions = copy.generalPrompts
        .where(
          (prompt) => query.isEmpty || prompt.toLowerCase().contains(query),
        )
        .toList(growable: false);

    return SfScaffold(
      tab: usesShellNavigation ? SfTab.ai : null,
      bottom: usesShellNavigation
          ? null
          : _AiWorkspaceNavigation(
              copy: copy,
              onChanged: (index) => _openTab(context, index),
            ),
      safeBottom: usesShellNavigation,
      top: _AiListHeader(
        copy: copy,
        searching: _showSearch,
        onSearch: _toggleSearch,
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          AnimatedSwitcher(
            duration: SfMotion.resolve(context, SfMotion.standard),
            switchInCurve: SfMotion.enter,
            switchOutCurve: SfMotion.exit,
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              alignment: Alignment.topLeft,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: !_showSearch
                ? const SizedBox.shrink(key: ValueKey('ai-search-hidden'))
                : Padding(
                    key: const ValueKey('ai-search-visible'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      key: const Key('ai-workspace-search-field'),
                      controller: _search,
                      focusNode: _searchFocus,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: copy.searchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                key: const Key('ai-search-clear'),
                                tooltip: copy.clearSearch,
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),
          ),
          SfAiSurface(
            borderRadius: BorderRadius.circular(18),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.ai.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.phone_iphone_rounded,
                    color: c.ai,
                    size: 20,
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
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: SfAiBadge(
                                  label: copy.deviceDemo,
                                  compact: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            copy.noServer,
                            style: SfType.mono(size: 8.5, color: c.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        copy.privacyDescription,
                        style: SfType.ui(
                          size: 11.5,
                          color: c.ink2,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          _SectionTitle(title: copy.myGroups, count: groups.length),
          const SizedBox(height: 8),
          if (groups.isEmpty && suggestions.isEmpty)
            _EmptySearch(
              copy: copy,
              onClear: () {
                _search.clear();
                setState(() {});
              },
            )
          else ...[
            for (final group in groups) ...[
              _GroupCard(
                key: Key('ai-group-${group.id}'),
                copy: copy,
                group: group,
                onPressed: () => context.push(aiChatLocation(group)),
              ),
              const SizedBox(height: 10),
            ],
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              _SectionTitle(
                title: copy.generalQuestions,
                count: suggestions.length,
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < suggestions.length; index++) ...[
                _SuggestionTile(
                  key: Key('ai-suggestion-$index'),
                  copy: copy,
                  prompt: suggestions[index],
                  onPressed: () => context.push(
                    aiChatLocation(copy.allGroups, prompt: suggestions[index]),
                  ),
                ),
                const SizedBox(height: 7),
              ],
            ],
          ],
        ],
      ),
    );
  }

  void _openTab(BuildContext context, int index) {
    const routes = ['/home', '/workspace', '/work', '/more', '/more'];
    context.go(routes[index.clamp(0, routes.length - 1)]);
  }
}

class _AiWorkspaceNavigation extends StatelessWidget {
  const _AiWorkspaceNavigation({required this.copy, required this.onChanged});

  final AiWorkspaceCopy copy;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const icons = [
      SfIcons.home,
      SfIcons.cohort,
      SfIcons.check,
      SfIcons.ai,
      SfIcons.printer,
    ];
    final labels = copy.navigationLabels;
    return SfAdaptiveBottomNavigation(
      activeIndex: 3,
      onDestinationSelected: onChanged,
      destinations: [
        for (var index = 0; index < labels.length; index++)
          SfBottomDestination(icon: Icon(icons[index]), label: labels[index]),
      ],
    );
  }
}

class _AiListHeader extends StatelessWidget {
  const _AiListHeader({
    required this.copy,
    required this.searching,
    required this.onSearch,
  });

  final AiWorkspaceCopy copy;
  final bool searching;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: IgnorePointer(
              child: Opacity(
                opacity: .08,
                child: SfStar(size: 140, color: c.primary),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SfAiBadge(label: copy.assistant),
                    const SizedBox(height: 8),
                    Text(
                      copy.workspaceTitle,
                      style: SfType.ui(
                        size: 28,
                        weight: FontWeight.w800,
                        color: c.ink,
                        letterSpacing: -.7,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      copy.workspaceSubtitle,
                      style: SfType.display(size: 15, color: c.muted),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                key: const Key('ai-search-toggle'),
                tooltip: searching ? copy.closeSearch : copy.searchWorkspace,
                onPressed: onSearch,
                icon: AnimatedSwitcher(
                  duration: SfMotion.resolve(context, SfMotion.quick),
                  child: Icon(
                    searching ? Icons.close_rounded : SfIcons.search,
                    key: ValueKey(searching),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      children: [
        Text(title, style: SfType.eyebrow(color: c.muted)),
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text('$count', style: SfType.mono(size: 9, color: c.muted)),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    super.key,
    required this.copy,
    required this.group,
    required this.onPressed,
  });

  final AiWorkspaceCopy copy;
  final AiStaffGroup group;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final accent = group.usesAccent ? c.accent : c.primary;
    return SfPressable(
      onPressed: onPressed,
      haptic: true,
      semanticLabel: copy.openGroup(group.name),
      borderRadius: BorderRadius.circular(20),
      child: SfSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -18,
              child: IgnorePointer(
                child: Opacity(
                  opacity: .055,
                  child: SfStar(size: 92, color: accent),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .18),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const SfStar(size: 22, color: Color(0xFFFFFCF5)),
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
                              group.name,
                              style: SfType.ui(
                                size: 14.5,
                                weight: FontWeight.w800,
                                color: c.ink,
                              ),
                            ),
                          ),
                          Icon(SfIcons.arrowR, size: 15, color: c.muted),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        copy.studentsAndSchedule(group),
                        style: SfType.ui(size: 10.5, color: c.muted),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: c.aiGradient,
                          border: Border.all(color: c.aiBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              copy.latestSummary,
                              style: SfType.eyebrow(color: c.ai, size: 8.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              group.preview,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: SfType.display(
                                size: 12.5,
                                color: c.ink2,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 10,
                        runSpacing: 5,
                        children: [
                          _Metric(
                            label: '↑ ${group.upCards} Up',
                            color: c.success,
                          ),
                          _Metric(
                            label: '↓ ${group.downCards} Down',
                            color: c.danger,
                          ),
                          _Metric(
                            label: copy.attendance(group.attendance),
                            color: group.attendance >= 92 ? c.success : c.warn,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: SfType.mono(size: 9.5, weight: FontWeight.w700, color: color),
  );
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    super.key,
    required this.copy,
    required this.prompt,
    required this.onPressed,
  });

  final AiWorkspaceCopy copy;
  final String prompt;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      onPressed: onPressed,
      haptic: true,
      semanticLabel: copy.openQuestion(prompt),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                gradient: c.aiGradient,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.aiBorder),
              ),
              alignment: Alignment.center,
              child: Text('Ai', style: SfType.display(size: 13, color: c.ai)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(prompt, style: SfType.ui(size: 12.5, color: c.ink2)),
            ),
            Icon(SfIcons.arrowR, size: 14, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.copy, required this.onClear});

  final AiWorkspaceCopy copy;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 34, color: c.muted),
          const SizedBox(height: 10),
          Text(
            copy.noMatches,
            textAlign: TextAlign.center,
            style: SfType.ui(size: 14, weight: FontWeight.w700, color: c.ink),
          ),
          const SizedBox(height: 7),
          TextButton(onPressed: onClear, child: Text(copy.clearSearch)),
        ],
      ),
    );
  }
}
