import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/constants/app_spacing.dart';

import 'employee_home_cubit.dart';

TextStyle appFontStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
  double? height,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

extension _EmployeeHomeThemeExtensions on BuildContext {
  Color get scaffoldColor => Theme.of(this).scaffoldBackgroundColor;
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get mutedTextColor =>
      Theme.of(this).textTheme.bodyMedium?.color ?? Colors.grey;
  Color get cardColor => Theme.of(this).cardColor;
  Color get onSurfaceColor => Theme.of(this).colorScheme.onSurface;
  Color get borderColor => Theme.of(this).dividerColor;
}

/// Employee · Home
/// Dashboard: header (avatar + notifications), attendance check-in,
/// my tasks, leave balance, announcements.
class EmployeeHomeScreen extends StatelessWidget {
  const EmployeeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmployeeHomeCubit(),
      child: const _EmployeeHomeView(),
    );
  }
}

class _EmployeeHomeView extends StatelessWidget {
  const _EmployeeHomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldColor,
      body: SafeArea(
        child: BlocBuilder<EmployeeHomeCubit, EmployeeHomeState>(
          builder: (context, state) {
            if (state.status == EmployeeHomeStatus.loading &&
                state.employeeName.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.hasError && state.employeeName.isEmpty) {
              return EmptyState(
                title: 'Something went wrong',
                message: state.errorMessage ?? 'Please try again.',
                icon: Icons.error_outline,
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<EmployeeHomeCubit>().loadDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HomeHeader(state: state),
                    const SizedBox(height: AppSpacing.xl),
                    _AttendanceCard(state: state),
                    const SizedBox(height: AppSpacing.lg),
                    _TasksCard(tasks: state.tasks),
                    const SizedBox(height: AppSpacing.lg),
                    _LeaveBalanceCard(days: state.leaveBalanceDays),
                    const SizedBox(height: AppSpacing.lg),
                    _AnnouncementsCard(announcements: state.announcements),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.state});

  final EmployeeHomeState state;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: context.primaryColor.withOpacity(0.12),
          child: Text(
            state.employeeInitials,
            style: appFontStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.primaryColor,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style:
                    appFontStyle(fontSize: 13, color: context.mutedTextColor),
              ),
              Text(
                state.employeeName,
                style: appFontStyle(fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _NotificationBell(count: state.unreadNotifications),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.cardColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_outlined,
            size: 20,
            color: context.onSurfaceColor,
          ),
        ),
        if (count > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: appFontStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.state});

  final EmployeeHomeState state;

  @override
  Widget build(BuildContext context) {
    final checkedIn = state.isCheckedIn;
    final todayLabel = DateFormat('EEEE, d MMM').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance',
                  style:
                      appFontStyle(fontSize: 12, color: context.primaryColor),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  checkedIn ? 'Checked in' : 'Not checked in',
                  style:
                      appFontStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  checkedIn && state.checkInTime != null
                      ? '$todayLabel · ${DateFormat('h:mm a').format(state.checkInTime!)}'
                      : todayLabel,
                  style:
                      appFontStyle(fontSize: 12, color: context.mutedTextColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          ElevatedButton(
            onPressed: checkedIn || state.isCheckingIn
                ? null
                : () => context.read<EmployeeHomeCubit>().checkIn(),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: context.primaryColor.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: state.isCheckingIn
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    checkedIn ? 'Checked in' : 'Check in',
                    style: appFontStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TasksCard extends StatelessWidget {
  const _TasksCard({required this.tasks});

  final List<EmployeeTaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My tasks',
            style: appFontStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          if (tasks.isEmpty)
            Text(
              'No tasks assigned right now.',
              style: appFontStyle(fontSize: 13, color: context.mutedTextColor),
            )
          else
            for (var i = 0; i < tasks.length; i++) ...[
              _TaskRow(task: tasks[i]),
              if (i != tasks.length - 1) const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final EmployeeTaskItem task;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            task.title,
            style: appFontStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: task.status.background(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            task.status.label,
            style: appFontStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: task.status.foreground(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaveBalanceCard extends StatelessWidget {
  const _LeaveBalanceCard({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leave balance',
                  style:
                      appFontStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '$days days available',
                  style:
                      appFontStyle(fontSize: 12, color: context.mutedTextColor),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              // TODO: navigate to Apply Leave flow.
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              'Apply leave',
              style: appFontStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementsCard extends StatelessWidget {
  const _AnnouncementsCard({required this.announcements});

  final List<EmployeeAnnouncement> announcements;

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) return const SizedBox.shrink();
    final latest = announcements.first;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Announcements',
            style: appFontStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            latest.body,
            style: appFontStyle(
              fontSize: 12,
              color: context.mutedTextColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
