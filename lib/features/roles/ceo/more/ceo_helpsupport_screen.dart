import 'package:flutter/material.dart';
import 'package:runrate/core/theme/app_colors_data.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/toast.dart';

class _FaqEntry {
  const _FaqEntry({
    required this.category,
    required this.question,
    required this.answer,
  });
  final String category;
  final String question;
  final String answer;
}

const _faqEntries = <_FaqEntry>[
  _FaqEntry(
    category: 'Approvals',
    question: 'How do I approve or reject a pending request?',
    answer:
        'Open the Approvals tab, tap a request to review its details, then '
        'use Approve or Reject. Every decision is logged with a timestamp '
        'and can include an optional note for the requester.',
  ),
  _FaqEntry(
    category: 'Approvals',
    question: 'Can I delegate approvals while I\'m away?',
    answer:
        'Yes. Go to Security Settings > Delegation and choose a teammate to '
        'act on your behalf for a set date range. You\'ll still see every '
        'decision they make in your activity log.',
  ),
  _FaqEntry(
    category: 'Budgets',
    question: 'How often are department budgets refreshed?',
    answer:
        'Budget figures sync nightly from your finance system. You can '
        'force an immediate refresh from the Budgets screen using the '
        'pull-to-refresh gesture.',
  ),
  _FaqEntry(
    category: 'Budgets',
    question: 'Why does a department show as over budget?',
    answer:
        'A department is flagged red once committed spend plus pending '
        'approvals exceeds its allocated budget for the period. Tap the '
        'department for a full breakdown.',
  ),
  _FaqEntry(
    category: 'AI Copilot',
    question: 'What can the AI Copilot actually do?',
    answer:
        'The Copilot surfaces spend anomalies, drafts approval summaries, '
        'and answers questions about your dashboards in plain language. It '
        'never approves anything on its own — every suggestion needs your '
        'sign-off.',
  ),
  _FaqEntry(
    category: 'AI Copilot',
    question: 'Is my data used to train the AI model?',
    answer:
        'No. Copilot responses are generated per-request from your live '
        'data and are not used for model training. See the AI Policy tile '
        'in More for full details.',
  ),
  _FaqEntry(
    category: 'Account',
    question: 'How do I change my password?',
    answer:
        'Go to More > Account & Security > Change Password. You\'ll need '
        'your current password to set a new one.',
  ),
  _FaqEntry(
    category: 'Account',
    question: 'Can I update my organization name?',
    answer:
        'Yes — open More > your profile card > Edit, then update the '
        'Organization field and save. The change reflects across the app '
        'immediately.',
  ),
];

/// Real Help & Support screen: searchable FAQ accordion plus contact
/// options, replacing the previous AlertDialog placeholders.
class CeoHelpSupportScreen extends StatefulWidget {
  const CeoHelpSupportScreen({super.key});

  @override
  State<CeoHelpSupportScreen> createState() => _CeoHelpSupportScreenState();
}

class _CeoHelpSupportScreenState extends State<CeoHelpSupportScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  String? _expandedQuestion;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<_FaqEntry> get _filtered {
    if (_query.isEmpty) return _faqEntries;
    return _faqEntries
        .where((f) =>
            f.question.toLowerCase().contains(_query) ||
            f.answer.toLowerCase().contains(_query) ||
            f.category.toLowerCase().contains(_query))
        .toList();
  }

  Map<String, List<_FaqEntry>> get _grouped {
    final map = <String, List<_FaqEntry>>{};
    for (final entry in _filtered) {
      map.putIfAbsent(entry.category, () => []).add(entry);
    }
    return map;
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@acmecorp.com',
      query: 'subject=CEO Dashboard Support Request',
    );
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      showAppToast(context, 'Could not open your mail app');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 100),
          children: [
            Row(
              children: [
                _ScaleOnTap(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(Icons.arrow_back_rounded,
                        color: colors.textPrimary, size: 20),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Help & Support',
                          style: AppTypography.h2(colors.textPrimary)),
                      Text('Answers, guides, and ways to reach us',
                          style: AppTypography.caption(colors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _Staggered(index: 0, child: _buildHeroSearch(colors)),
            const SizedBox(height: AppSpacing.xxl),
            if (grouped.isEmpty)
              _Staggered(index: 1, child: _buildEmptyState(colors))
            else
              for (var i = 0; i < grouped.keys.length; i++) ...[
                _Staggered(
                  index: i + 1,
                  child: _CategorySection(
                    category: grouped.keys.elementAt(i),
                    entries: grouped.values.elementAt(i),
                    expandedQuestion: _expandedQuestion,
                    onToggle: (q) => setState(() =>
                        _expandedQuestion = _expandedQuestion == q ? null : q),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            _Staggered(index: grouped.keys.length + 1, child: _buildContact(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSearch(AppColorsData colors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary,
              colors.secondary,
              colors.primary.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How can we help?',
                style: AppTypography.h2(Colors.white)),
            const SizedBox(height: 4),
            Text('Search FAQs or browse by category below',
                style:
                    AppTypography.caption(Colors.white.withValues(alpha: 0.85))),
            const SizedBox(height: AppSpacing.lg),
            _AnimatedSearchField(
              controller: _searchController,
              focusNode: _searchFocus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColorsData colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, color: colors.textSecondary, size: 32),
          const SizedBox(height: AppSpacing.md),
          Text('No results for "${_searchController.text}"',
              style: AppTypography.body(colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildContact(AppColorsData colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Still need help?', style: AppTypography.h3(colors.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        _ContactCard(
          icon: Icons.mail_outline_rounded,
          accent: colors.primary,
          title: 'Email Support',
          subtitle: 'support@acmecorp.com · replies within 1 business day',
          onTap: _emailSupport,
        ),
        const SizedBox(height: AppSpacing.md),
        _ContactCard(
          icon: Icons.chat_bubble_outline_rounded,
          accent: colors.info,
          title: 'Live Chat',
          subtitle: 'Chat with our team in real time',
          onTap: () => showAppToast(context, 'Live chat is coming soon'),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.entries,
    required this.expandedQuestion,
    required this.onToggle,
  });

  final String category;
  final List<_FaqEntry> entries;
  final String? expandedQuestion;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Text(category,
                style: AppTypography.caption(colors.primary)
                    .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          ),
          for (var i = 0; i < entries.length; i++) ...[
            _FaqTile(
              entry: entries[i],
              expanded: expandedQuestion == entries[i].question,
              onTap: () => onToggle(entries[i].question),
            ),
            if (i != entries.length - 1)
              Divider(height: 1, color: colors.border),
          ],
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.entry,
    required this.expanded,
    required this.onTap,
  });

  final _FaqEntry entry;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(entry.question,
                      style: AppTypography.body(colors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: colors.textSecondary),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(entry.answer,
                          style: AppTypography.caption(colors.textSecondary)
                              .copyWith(height: 1.5)),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.body(colors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.caption(colors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AnimatedSearchField extends StatefulWidget {
  const _AnimatedSearchField(
      {required this.controller, required this.focusNode});
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  State<_AnimatedSearchField> createState() => _AnimatedSearchFieldState();
}

class _AnimatedSearchFieldState extends State<_AnimatedSearchField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused
              ? Colors.white
              : Colors.white.withValues(alpha: 0.35),
          width: _focused ? 1.6 : 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        style: AppTypography.body(Colors.white),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          hintText: 'Search help articles...',
          hintStyle:
              AppTypography.body(Colors.white.withValues(alpha: 0.7)),
          prefixIcon: Icon(Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.85)),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.85), size: 18),
                  onPressed: () => widget.controller.clear(),
                )
              : null,
        ),
      ),
    );
  }
}

class _Staggered extends StatelessWidget {
  const _Staggered({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (index * 60).clamp(0, 480)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _ScaleOnTap extends StatefulWidget {
  const _ScaleOnTap({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        child: widget.child,
      ),
    );
  }
}
