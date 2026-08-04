# Runrate — AI Spend Copilot (scaffold + CEO role complete)

Build status: **core/ + shared/ + authentication + CEO role are fully implemented with real
mock data and real interactions (no TODOs, no placeholders). CFO, Engineering Manager,
Employee, and Org Admin are still breadth-first stubs**, ready for the same treatment.

## CEO role — complete
Every CEO tab is fully built against `CeoMockRepository` (in `features/roles/ceo/data/`),
with its own Cubit + Equatable state class per spec section 12:
- **Home** — KPI grid (count-up animated), department SimpleBarChart, AI insight cards,
  pull-to-refresh, skeleton loading state, error/retry state.
- **AI** — Chat Assistant (typing indicator, quick-reply chips, canned contextual replies)
  and an Insights view, switched via a segmented toggle.
- **Teams** — department list (Engineering, Sales, Marketing, Support, HR, Operations) with
  spend + trend arrows, search, tap-to-expand detail sheet.
- **Approvals** — pending requests; Approve completes instantly with a toast; Reject opens
  the shared `RejectRequestSheet` (preset reason chips + custom message), which declines the
  request **and** pushes the message into the requester's Notification Center via
  `NotificationsCubit.push`.
- **More** — Report Center + Report Detail (chart + mock "Preparing PDF..." export), Board
  Reports, AI Policy, Blog & Insights, Profile/Preferences/Security shortcuts, Log Out.

New shared components built to support this (reusable by every other role):
`RejectRequestSheet`, `TypingIndicator`, `ChatBubble`, `SegmentedToggle`, `InsightCard`,
`GlowBackground` (ambient orbs for Home/AI), plus `ChatMessageModel`, `InsightModel`,
`ReportModel`.

## What's fully functional right now
- Design system: `core/theme` (AppColors / AppColorsDark / AppTypography / AppTheme / ThemeCubit)
  with a working light/dark toggle wired through `main.dart` (AnimatedTheme crossfade).
- Mock auth: 5 hardcoded accounts in `MockAuthRepository`, `AuthCubit`, Login → Org Selection →
  role-based `RoleHomeShell` flow.
- Shared bottom-nav shell (`features/roles/role_home_shell.dart`) — Home · AI · Teams ·
  Approvals · More — using `IndexedStack` + `BottomNavCubit` so tab state persists.
- Shared widget library in `shared/widgets/` (buttons, cards, KpiCard, ProgressRing,
  SimpleBarChart, ApprovalCard, TeamCard, EmptyState, SkeletonLoader, AnimatedCounter, etc.)
  — all theme-aware, no hardcoded colors.
- Shared models in `shared/models/`.
- Notifications / Profile / Preferences (dark mode toggle works) / Security shells.

## What's stubbed (breadth over depth)
Every one of the 25 role-tab combinations (5 roles × Home/AI/Teams/Approvals/More) has:
- `features/roles/<role>/<tab>/<role>_<tab>_screen.dart` — a real, compiling screen that
  renders using the shared widgets, with a clear "TODO: build out this screen" marker.
- `features/roles/<role>/<tab>/<role>_<tab>_cubit.dart` — a placeholder Cubit ready to be
  replaced with real state classes + mock repository calls.

None of these stub screens implement the actual dashboards, chat UI, approval reject-flow,
department comparisons, etc. described in the original spec — they only prove the navigation
and folder structure wire together end-to-end.

## Suggested next steps (best done in Claude Code)
1. `flutter pub get`, then `flutter run` to confirm the scaffold boots (splash → login →
   org selection → role shell with 5 tabs).
2. Pick one role folder per person/branch (`feature/ceo-role`, `feature/cfo-role`, ...).
3. Flesh out `home` first for each role (KPI cards, SimpleBarChart, quick actions), since it's
   what testers see first.
4. Implement the Approvals reject-with-message bottom sheet (section 8 of the spec) — the
   `ApprovalCard` widget and `showAppBottomSheet` helper are already in place to build it on.
5. Build out the AI tab's chat UI (typing indicator, streaming reveal, suggested chips) as a
   shared component in `shared/widgets/` since the interaction pattern is identical per role,
   only the seeded conversation content differs.
6. Add the Reports module (`features/roles/<role>/more/`) with mock PDF-export animation.

## Folder map
```
lib/
  core/       theme, constants, utils, routes, di
  shared/     widgets, models, bloc
  features/
    authentication/
    notifications/
    profile/
    settings/
    roles/
      role_home_shell.dart      <- shared bottom-nav shell
      ceo/ cfo/ engineering_manager/ employee/ org_admin/
        home/ ai/ teams/ approvals/ more/
  main.dart
```
