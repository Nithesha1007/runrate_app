import 'package:flutter/material.dart';
import 'app_bottom_sheet.dart';
import 'primary_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_spacing.dart';

const List<String> kRejectPresetReasons = [
  'Budget exceeded',
  'Needs more justification',
  'Not approved this cycle',
  'Duplicate request',
];

/// Opens the animated "Reject Request" bottom sheet described in spec
/// section 8. Returns the final rejection message the caller should:
///   1) attach to the ApprovalModel as its declineReason, and
///   2) push into the requester's Notification Center.
/// Returns null if the approver dismissed the sheet without confirming.
Future<String?> showRejectRequestSheet(BuildContext context,
    {required String requesterName}) {
  return showAppBottomSheet<String>(
    context,
    child: _RejectRequestSheetBody(requesterName: requesterName),
  );
}

class _RejectRequestSheetBody extends StatefulWidget {
  final String requesterName;
  const _RejectRequestSheetBody({required this.requesterName});

  @override
  State<_RejectRequestSheetBody> createState() =>
      _RejectRequestSheetBodyState();
}

class _RejectRequestSheetBodyState extends State<_RejectRequestSheetBody> {
  final _controller = TextEditingController();
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      _controller.text = preset;
      _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                  color: context.appColors.border,
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Text('Reject Request', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Let \${widget.requesterName} know why this was declined.',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kRejectPresetReasons.map((reason) {
              final selected = reason == _selectedPreset;
              return ChoiceChip(
                label: Text(reason),
                selected: selected,
                selectedColor: context.appColors.primaryLight,
                labelStyle: TextStyle(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : null),
                onSelected: (_) => _applyPreset(reason),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Message to requester',
              hintText: 'Write a custom message, or edit the preset above...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Reject & Send Message',
            onPressed: _controller.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(_controller.text.trim()),
          ),
        ],
      ),
    );
  }
}
