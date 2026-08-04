import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppFilterChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const AppFilterChips(
      {super.key,
      required this.options,
      required this.selected,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final option = options[i];
          final isSelected = option == selected;
          return ChoiceChip(
            label: Text(option),
            selected: isSelected,
            selectedColor: context.appColors.primaryLight,
            labelStyle: TextStyle(
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null),
            onSelected: (_) => onSelected(option),
          );
        },
      ),
    );
  }
}
