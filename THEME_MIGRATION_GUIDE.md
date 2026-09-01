# Employee Screens Theme Migration Guide

## Overview
The Runrate app now has a working dark/light theme toggle in the "Appearance" settings. Currently only the "More" screen and Teams screen (partially) reflect theme changes. This guide completes the migration for all employee screens.

## What Was Done
✅ **Teams Screen** - Converted to use `context.appColors`
✅ **More Screen** - Already using theme-aware `_Palette` class  
✅ **Approvals Screen** - Partial conversion (constants renamed, key sections updated)
⏳ **Home Screen** - Needs conversion

## What Needs to Be Done

### 1. Finish Approvals Screen (lib/features/roles/employee/approvals/employee_approvals_screen.dart)

Remaining 25 `ApprovalsColors.` references need to be updated. Paste this into a find-replace:

**Search for:** `ApprovalsColors\.`

Then manually replace each with:

```
ApprovalsColors.surfaceElevated → colors.surfaceElevated
ApprovalsColors.border → colors.border
ApprovalsColors.textSecondary → colors.textSecondary
ApprovalsColors.textPrimary → colors.textPrimary
ApprovalsColors.primary → colors.primary
ApprovalsColors.primaryLight → colors.primaryLight
ApprovalsColors.urgentBg → _urgentBg  
ApprovalsColors.urgentFg → _urgentFg
ApprovalsColors.normalBg → _normalBg
ApprovalsColors.normalFg → _normalFg
ApprovalsColors.approvedBg → _approvedBg
ApprovalsColors.approvedFg → _approvedFg
ApprovalsColors.needsInfoBg → _needsInfoBg
ApprovalsColors.needsInfoFg → _needsInfoFg
ApprovalsColors.rejectedBg → _rejectedBg
ApprovalsColors.rejectedFg → _rejectedFg
ApprovalsColors.aiNote → _aiNotePurple
ApprovalsColors.gradientStart → _gradientStart
ApprovalsColors.gradientEnd → _gradientEnd
```

**Key Pattern:** In any `build(BuildContext context)` method, add at the start:
```dart
final colors = context.appColors;
```

Then use `colors.` prefix for dynamic colors.

### 2. Convert Home Screen (lib/features/roles/employee/home/employee_home_screen.dart)

**Steps:**
1. Add import: `import '../../../../core/theme/app_colors.dart';`
2. Remove the `RunrateColors` class entirely
3. Create constants for gradient and accent colors at the top of file:
```dart
const _heroGradientStart = Color(0xFF6D5BFF);
const _heroGradientEnd = Color(0xFF4B8BFF);
const _accentViolet = Color(0xFF8B5CF6);
// ... etc for other accent colors
```
4. Update `TextStyle rrText()` function to accept `Color? color` parameter
5. In every `build(BuildContext context)` method, add: `final colors = context.appColors;`
6. Replace all color references:
   - `RunrateColors.background` → `colors.background`
   - `RunrateColors.textPrimary` → `colors.textPrimary`
   - `RunrateColors.textSecondary` → `colors.textSecondary`
   - `RunrateColors.surface` → `colors.surface`
   - `RunrateColors.surfaceElevated` → `colors.surfaceElevated`
   - `RunrateColors.border` → `colors.border`
   - `RunrateColors.primary` → `colors.primary`
   - `RunrateColors.primaryLight` → `colors.primaryLight`
   - `RunrateColors.success/warning/danger/info` → `colors.success/warning/danger/info`

## Testing

After each file is updated, run:
```bash
flutter pub get
flutter analyze
```

Then test the app:
1. Open "More" tab → Settings → Appearance
2. Click "Dark" theme
3. Navigate between all employee tabs (Home, Teams, Approvals, More)
4. All screens should now display in dark theme
5. Click "Light" theme to verify the switch works both ways

## Architecture Reference

The theme system works as follows:

1. **ThemeCubit** (`lib/core/theme/theme_cubit.dart`)
   - Manages light/dark mode state
   - Persists selection to SharedPreferences
   - Emits new ThemeMode when changed

2. **AppTheme** (`lib/core/theme/app_theme.dart`)
   - Defines ThemeData for light and dark modes
   - Uses AppColors and AppColorsDark for colors

3. **AppColors** (`lib/core/theme/app_colors.dart`)
   - Light mode color palette
   - Provides `AppColors.of(context)` helper to get current theme colors
   - Extension: `context.appColors` shorthand

4. **AppColorsData** (`lib/core/theme/app_colors_data.dart`)
   - Container for color properties
   - Used by both light and dark modes

5. **AppColorsDark** (`lib/core/theme/app_colors_dark.dart`)
   - Dark mode color palette

## Color Principles

- **Background**: Used for scaffold/page backgrounds
- **Surface**: Used for card backgrounds in light mode
- **SurfaceElevated**: Used for elevated card backgrounds  
- **Border**: Used for dividers and borders
- **TextPrimary**: Used for main content text
- **TextSecondary**: Used for secondary/muted text
- **Primary/Secondary**: Brand accent colors
- **Success/Warning/Danger/Info**: Status colors

The system automatically ensures sufficient contrast for accessibility in both light and dark modes.

## Common Patterns

### Before (Hardcoded Colors)
```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: TeamsColors.background,
      child: Text('Hello', style: appFontStyle(color: TeamsColors.textPrimary)),
    );
  }
}
```

### After (Theme-Aware)
```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      color: colors.background,
      child: Text('Hello', style: appFontStyle(color: colors.textPrimary)),
    );
  }
}
```

## Questions?

Refer to `lib/features/roles/employee/teams/employee_teams_screen.dart` or `lib/features/roles/employee/more/employee_more_screen.dart` for complete examples of properly migrated screens.
