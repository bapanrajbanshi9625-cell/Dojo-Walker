import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

enum DetailsFilterType {
  date,
  week,
}

class DetailsDateFilter extends StatelessWidget {
  final DetailsFilterType selectedType;
  final DateTime selectedDate;

  final ValueChanged<DetailsFilterType>
      onTypeChanged;

  final ValueChanged<DateTime>
      onDateChanged;

  const DetailsDateFilter({
    super.key,
    required this.selectedType,
    required this.selectedDate,
    required this.onTypeChanged,
    required this.onDateChanged,
  });

  String _dateText() {
    return '${selectedDate.day.toString().padLeft(2, '0')}/'
        '${selectedDate.month.toString().padLeft(2, '0')}/'
        '${selectedDate.year}';
  }

  String _weekText() {
    final DateTime start =
        selectedDate.subtract(
      Duration(
        days: selectedDate.weekday - 1,
      ),
    );

    final DateTime end =
        start.add(
      const Duration(days: 6),
    );

    return '${start.day}/${start.month}'
        ' - '
        '${end.day}/${end.month}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDate =
        selectedType == DetailsFilterType.date;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final RenderBox box =
              context.findRenderObject()
                  as RenderBox;

          final Offset position =
              box.localToGlobal(
            Offset.zero,
          );

          final RelativeRect menuPosition =
              RelativeRect.fromLTRB(
            position.dx,
            position.dy + box.size.height,
            position.dx + box.size.width,
            0,
          );

          final DetailsFilterType? result =
              await showMenu<DetailsFilterType>(
            context: context,
            position: menuPosition,
            color: AppColors.surface,
            items: const [
              PopupMenuItem(
                value: DetailsFilterType.date,
                child: Text('Date'),
              ),
              PopupMenuItem(
                value: DetailsFilterType.week,
                child: Text('Week'),
              ),
            ],
          );

          if (result != null) {
            onTypeChanged(result);
          }
        },
        child: Container(
          height: 44,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.divider,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isDate
                    ? Icons.calendar_today_rounded
                    : Icons.date_range_rounded,
                size: 18,
                color: AppColors.iconPrimary,
              ),

              const SizedBox(width: 9),

              Text(
                isDate
                    ? _dateText()
                    : _weekText(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              Text(
                isDate ? 'Date' : 'Week',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: 5),

              Icon(
                Icons
                    .keyboard_arrow_down_rounded,
                color: AppColors.iconSecondary,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
