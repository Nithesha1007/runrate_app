import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/features/roles/cfo/approvals/cfo_approval_state.dart';
import 'package:runrate/features/roles/cfo/approvals/cfo_approvals_cubit.dart';

// ---------------------------------------------------------------------------
// Palette — matches the Approvals list screen (gradient hero, pill badges,
// outlined chips, stadium-shaped action buttons).
// ---------------------------------------------------------------------------
const _kGradientStart = Color(0xFF6C5CE7);
const _kGradientEnd = Color(0xFF4C6FEF);
const _kPrimary = Color(0xFF6C5CE7);
const _kBackground = Color(0xFFF7F6FB);
const _kCardRadius = 20.0;

const _kUrgent = Color(0xFFE5484D);
const _kUrgentBg = Color(0xFFFBE3E4);

class CfoApprovalDetailScreen extends StatelessWidget {
  const CfoApprovalDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Request Details',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<CfoApprovalsCubit, CfoApprovalsState>(
        builder: (context, state) {
          if (state is! CfoApprovalsLoaded) {
            return const SizedBox.shrink();
          }
          final request = state.requestById(requestId);
          if (request == null) {
            return const Center(child: Text('This request is no longer available.'));
          }
          final isBusy = state.actionInFlightId == request.id;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    children: [
                      _HeroCard(request: request),
                      const SizedBox(height: 14),
                      _RequesterCard(request: request),
                      const SizedBox(height: 14),
                      _JustificationCard(request: request),
                      const SizedBox(height: 14),
                      _BudgetImpactCard(request: request),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                if (request.status == ApprovalStatus.pending)
                  _ActionBar(
                    isBusy: isBusy,
                    onApprove: () async {
                      await context.read<CfoApprovalsCubit>().approve(request.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    onReject: () => _confirmReject(context, request),
                    onRequestInfo: () => _requestInfo(context, request),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmReject(BuildContext context, ApprovalRequest request) async {
    final cubit = context.read<CfoApprovalsCubit>();

    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _RejectReasonSheet(requesterName: request.requesterName),
    );

    if (message != null && message.isNotEmpty) {
      await cubit.reject(request.id, message);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _requestInfo(BuildContext context, ApprovalRequest request) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Request more info'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'What do you need from ${request.requesterName}?',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _kPrimary, shape: const StadiumBorder()),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }
}

/// Category no longer carries an explicit icon/color from the request model,
/// so the detail screen derives a look from the category label.
IconData _iconForCategory(String category) {
  final c = category.toLowerCase();
  if (c.contains('infra')) return Icons.dns_outlined;
  if (c.contains('design')) return Icons.brush_outlined;
  if (c.contains('dev')) return Icons.code;
  if (c.contains('ai') || c.contains('assistant')) return Icons.smart_toy_outlined;
  return Icons.apps_outlined;
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child}) : padding = null;

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

/// Small rounded pill with a leading dot — used for priority throughout
/// the Approvals flow ("URGENT" / "NORMAL").
class _DotPill extends StatelessWidget {
  const _DotPill({required this.label, required this.color, required this.background});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}

/// Outlined chip — used for the category label ("Software", "Infrastructure").
class _OutlinedChip extends StatelessWidget {
  const _OutlinedChip({required this.label, this.light = false});

  final String label;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: light ? Colors.white.withOpacity(0.16) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: light ? Colors.white.withOpacity(0.4) : Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: light ? Colors.white : Colors.grey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Gradient hero card — mirrors the "Awaiting your sign-off" banner on the
/// Approvals list, scoped down to this single request.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.request});

  final ApprovalRequest request;

  @override
  Widget build(BuildContext context) {
    final isUrgent = request.priority == ApprovalPriority.urgent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGradientStart, _kGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: _kGradientEnd.withOpacity(0.28), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DotPill(
                label: request.priority.label.toUpperCase(),
                color: Colors.white,
                background: Colors.white.withOpacity(isUrgent ? 0.22 : 0.16),
              ),
              const SizedBox(width: 8),
              _OutlinedChip(label: request.categoryLabel, light: true),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconForCategory(request.categoryLabel), color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  request.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatInr(request.amount),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32, height: 1),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'requested amount',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequesterCard extends StatelessWidget {
  const _RequesterCard({required this.request});

  final ApprovalRequest request;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _kPrimary.withOpacity(0.12),
                child: Text(
                  _initialsOf(request.requesterName),
                  style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.requesterName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(request.requesterRole, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('Requested', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(formatShortDate(request.requestedDate), style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  static String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class _JustificationCard extends StatelessWidget {
  const _JustificationCard({required this.request});

  final ApprovalRequest request;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.description_outlined, color: _kPrimary, size: 15),
              ),
              const SizedBox(width: 10),
              const Text('Business Justification', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF6F5FB), borderRadius: BorderRadius.circular(14)),
            child: Text(
              request.businessJustification,
              style: TextStyle(color: Colors.grey.shade800, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetImpactCard extends StatelessWidget {
  const _BudgetImpactCard({required this.request});

  final ApprovalRequest request;

  @override
  Widget build(BuildContext context) {
    final ratio = request.budgetImpactRatio;
    final usagePercent = (request.budgetLimit <= 0 ? 0 : (request.currentUsage / request.budgetLimit * 100)).round();

    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.donut_large, color: _kPrimary, size: 18),
              const SizedBox(width: 8),
              const Text('Budget Impact', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              _OutlinedChip(label: request.department),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Usage', style: TextStyle(color: Colors.grey.shade600)),
              Text(
                '${formatInr(request.currentUsage)} / ${formatInr(request.budgetLimit)} limit',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(_kPrimary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey.shade500, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Used ($usagePercent%)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('+${formatInr(request.amount)} (Impact)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet used to collect a rejection reason. Pops with the trimmed
/// note when confirmed, or `null` when dismissed without one.
class _RejectReasonSheet extends StatefulWidget {
  const _RejectReasonSheet({required this.requesterName});

  final String requesterName;

  @override
  State<_RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<_RejectReasonSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'A reason is required');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Text(
              'Reason for rejection',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 4,
              minLines: 3,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Add a short note...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                filled: true,
                fillColor: const Color(0xFFF6F5FB),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: _kUrgent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Confirm rejection',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
    required this.onRequestInfo,
  });

  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRequestInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onReject,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _kUrgentBg,
                    foregroundColor: _kUrgent,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kGradientStart, _kGradientEnd]),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: FilledButton.icon(
                    onPressed: isBusy ? null : onApprove,
                    icon: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: isBusy ? null : onRequestInfo,
              icon: const Icon(Icons.help_outline, size: 16, color: _kPrimary),
              label: const Text(
                'Request Info',
                style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
            ),
          ),
        ],
      ),
    );
  }
}