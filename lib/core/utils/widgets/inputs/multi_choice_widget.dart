import 'package:flutter/material.dart';
import 'package:taqy/core/extensions/txt_theme.dart';
import 'package:taqy/core/theme/colors.dart';

class MultiChoiceWidget<T> extends StatefulWidget {
  final List<T> choices;
  final void Function(T choice, bool selected)? onChanged;
  final String? title;
  final List<T>? value;
  final bool Function(T)? isChoiceSelected;
  final String Function(T choice)? formatOption;

  const MultiChoiceWidget({
    super.key,
    required this.choices,
    this.onChanged,
    this.title,
    this.isChoiceSelected,
    this.value,
    this.formatOption,
  });

  @override
  State<MultiChoiceWidget<T>> createState() => _MultiChoiceWidgetState<T>();
}

class _MultiChoiceWidgetState<T> extends State<MultiChoiceWidget<T>> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Text(widget.title!, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary)),
        ],
        Column(
          children: widget.choices.map((choice) {
            // final isSelected = widget.isChoiceSelected?.call(choice) ?? false;
            final isSelected = widget.value?.contains(choice) ?? false;

            return Theme(
              data: ThemeData(
                unselectedWidgetColor: AppColors.outline,
                splashColor: Colors.transparent,
                hoverColor: Colors.transparent,
                textTheme: context.textTheme,
              ),
              child: CheckboxListTile(
                hoverColor: Colors.transparent,
                tileColor: Colors.transparent,
                selectedTileColor: Colors.transparent,

                contentPadding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                value: isSelected, // Fixed this line to use isSelected
                checkColor: AppColors.background,

                fillColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
                  if (states.contains(WidgetState.disabled)) {
                    // Color when the checkbox is disabled
                    return AppColors.outline;
                  }
                  // Color when the checkbox is enabled
                  return states.contains(WidgetState.selected)
                      ? Theme.of(context).colorScheme.primary
                      : AppColors.background;
                }),

                splashRadius: 0,
                checkboxShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                  side: const BorderSide(color: AppColors.outline),
                ),

                activeColor: Theme.of(context).colorScheme.primary,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(widget.formatOption?.call(choice) ?? "$choice"),
                onChanged: (value) {
                  widget.onChanged?.call(choice, value ?? false);

                  // if (widget.onChanged != null) {
                  //   widget.onChanged!(choice, value ?? false);
                  // }
                  setState(() {});
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
