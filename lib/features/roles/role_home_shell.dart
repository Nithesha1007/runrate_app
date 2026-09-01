import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/theme_cubit.dart';
import '../../shared/bloc/bottom_nav_cubit.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/role_enum.dart';
import 'ceo/home/ceo_home_screen.dart';
import 'ceo/ai/ceo_ai_screen.dart';
import 'ceo/teams/ceo_teams_screen.dart';
import 'ceo/approvals/ceo_approvals_screen.dart';
import 'ceo/more/ceo_more_screen.dart';
import 'cfo/home/cfo_home_screen.dart';
import 'cfo/ai/cfo_ai_screen.dart';
import 'cfo/teams/cfo_teams_screen.dart';
import 'cfo/approvals/cfo_approvals_screen.dart';
import 'cfo/more/cfo_more_screen.dart';
import 'engineering_manager/home/engineering_manager_home_screen.dart';
import 'engineering_manager/ai/engineering_manager_ai_screen.dart';
import 'engineering_manager/teams/engineering_manager_teams_screen.dart';
import 'engineering_manager/approvals/engineering_manager_approvals_screen.dart';
import 'engineering_manager/more/engineering_manager_more_screen.dart';
import 'employee/home/employee_home_screen.dart';
import 'employee/ai/employee_ai_screen.dart';
import 'employee/teams/employee_teams_screen.dart';
import 'employee/approvals/employee_approvals_screen.dart';
import 'employee/more/employee_more_screen.dart';
import 'org_admin/home/org_admin_home_screen.dart';
import 'org_admin/ai/org_admin_ai_screen.dart';
import 'org_admin/teams/org_admin_teams_screen.dart';
import 'org_admin/approvals/org_admin_approvals_screen.dart';
import 'org_admin/more/org_admin_more_screen.dart';

/// Shared bottom-nav shell (Home · AI · Teams · Approvals · More) — identical
/// structure for every role. Tab *content* is swapped based on [user.role].
/// IndexedStack + BottomNavCubit keep each tab's state/scroll alive when
/// switching, per spec section 4.
class RoleHomeShell extends StatefulWidget {
  final UserModel user;
  const RoleHomeShell({super.key, required this.user});

  @override
  State<RoleHomeShell> createState() => _RoleHomeShellState();
}

class _RoleHomeShellState extends State<RoleHomeShell> {
  @override
  void initState() {
    super.initState();
    context.read<ThemeCubit>().setRole(widget.user.role);
  }

  List<Widget> _tabsFor(RoleEnum role) {
    switch (role) {
      case RoleEnum.ceo:
        return [
          const CeoHomeScreen(),
          const CeoAiScreen(),
          const CeoTeamsScreen(),
          const CeoApprovalsScreen(),
          const CeoMoreScreen(),
        ];
      case RoleEnum.cfo:
        return const [
          CfoHomeScreen(),
          CfoAiScreen(),
          CfoTeamsScreen(),
          CfoApprovalsScreen(),
          CfoMoreScreen()
        ];
      case RoleEnum.engineeringManager:
        return [
          const EngineeringManagerHomeScreen(),
          const EngineeringManagerAiScreen(),
          const EngineeringManagerTeamsScreen(),
          const EngineeringManagerApprovalsScreen(),
          const EngineeringManagerMoreScreen(),
        ];
      case RoleEnum.employee:
        return [
          const EmployeeHomeScreen(),
          const EmployeeAiScreen(),
          const EmployeeTeamsScreen(),
          const EmployeeApprovalsScreen(),
          const EmployeeMoreScreen(),
        ];
      case RoleEnum.orgAdmin:
        return [
          const OrgAdminHomeScreen(),
          const OrgAdminAiScreen(),
          const OrgAdminTeamsScreen(),
          const OrgAdminApprovalsScreen(),
          const OrgAdminMoreScreen(),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabsFor(widget.user.role);
    return BlocProvider(
      create: (_) => BottomNavCubit(),
      child: Builder(builder: (context) {
        final index = context.watch<BottomNavCubit>().state;
        return Scaffold(
          body: IndexedStack(index: index, children: tabs),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) =>
                context.read<BottomNavCubit>().setIndex(i),
            animationDuration: const Duration(milliseconds: 250),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.auto_awesome), label: 'AI'),
              NavigationDestination(icon: Icon(Icons.group), label: 'Teams'),
              NavigationDestination(
                  icon: Icon(Icons.check_circle), label: 'Approvals'),
              NavigationDestination(
                  icon: Icon(Icons.more_horiz), label: 'More'),
            ],
          ),
        );
      }),
    );
  }
}
