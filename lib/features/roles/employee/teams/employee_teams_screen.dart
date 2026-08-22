import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/constants/app_spacing.dart';

import 'employee_teams_cubit.dart';

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

extension _EmployeeTeamsThemeExtensions on BuildContext {
  Color get scaffoldColor => Theme.of(this).scaffoldBackgroundColor;
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get mutedTextColor =>
      Theme.of(this).textTheme.bodyMedium?.color ?? Colors.grey;
}

/// Employee · Teams
/// Simple scannable list: name + spend + trend.
class EmployeeTeamsScreen extends StatelessWidget {
  const EmployeeTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmployeeTeamsCubit(),
      child: const _EmployeeTeamsView(),
    );
  }
}

class _EmployeeTeamsView extends StatelessWidget {
  const _EmployeeTeamsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldColor,
      appBar: AppBar(title: const Text('Teams')),
      body: SafeArea(
        child: BlocBuilder<EmployeeTeamsCubit, EmployeeTeamsState>(
          builder: (context, state) {
            if (state.isLoading && state.teams.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.hasError && state.teams.isEmpty) {
              return EmptyState(
                title: 'Something went wrong',
                message: state.errorMessage ?? 'Please try again.',
                icon: Icons.error_outline,
              );
            }
            if (state.teams.isEmpty) {
              return const EmptyState(
                title: 'No teams yet',
                message: 'Teams you belong to will show up here.',
                icon: Icons.groups_outlined,
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<EmployeeTeamsCubit>().loadTeams(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                itemCount: state.teams.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) =>
                    _TeamRow(team: state.teams[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({required this.team});

  final TeamSummary team;

  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  Color _trendColor(BuildContext context) {
    switch (team.trend) {
      case SpendTrend.up:
        return const Color(0xFFA32D2D);
      case SpendTrend.down:
        return const Color(0xFF3B6D11);
      case SpendTrend.flat:
        return context.mutedTextColor;
    }
  }

  IconData get _trendIcon {
    switch (team.trend) {
      case SpendTrend.up:
        return Icons.arrow_upward_rounded;
      case SpendTrend.down:
        return Icons.arrow_downward_rounded;
      case SpendTrend.flat:
        return Icons.remove_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: context.primaryColor.withValues(alpha: 0.12),
            child: Text(
              team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
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
                  team.name,
                  style:
                      appFontStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${team.memberCount} members',
                  style:
                      appFontStyle(fontSize: 12, color: context.mutedTextColor),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currency.format(team.spendThisMonth),
                style: appFontStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_trendIcon, size: 13, color: _trendColor(context)),
                  const SizedBox(width: 2),
                  Text(
                    '${team.trendPercent.toStringAsFixed(0)}%',
                    style: appFontStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _trendColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
