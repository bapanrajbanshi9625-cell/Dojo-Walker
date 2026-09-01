import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';

enum DetailsFilterType {
  date,
  week,
}

class DetailsDateFilter extends StatelessWidget {
  const DetailsDateFilter({
    super.key,
    required this.selectedType,
    required this.selectedDate,
    required this.onTypeChanged,
    required this.onDateChanged,
  });

  final DetailsFilterType selectedType;
  final DateTime selectedDate;
  final ValueChanged<DetailsFilterType> onTypeChanged;
  final ValueChanged<DateTime> onDateChanged;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _monthName(int month) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  DateTime _startOfWeek(DateTime date) {
    final DateTime day = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return day.subtract(
      Duration(days: day.weekday - 1),
    );
  }

  String _formatWeek(DateTime date) {
    final DateTime start = _startOfWeek(date);
    final DateTime end = start.add(
      const Duration(days: 6),
    );

    if (start.year == end.year) {
      return '${start.day} ${_monthName(start.month)}'
          ' - '
          '${end.day} ${_monthName(end.month)}';
    }

    return '${start.day} ${_monthName(start.month)} ${start.year}'
        ' - '
        '${end.day} ${_monthName(end.month)} ${end.year}';
  }

  String get _displayValue {
    if (selectedType == DetailsFilterType.date) {
      return _formatDate(selectedDate);
    }

    return _formatWeek(selectedDate);
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime today = DateTime.now();

    final DateTime initialDate = selectedDate.isAfter(today)
        ? today
        : selectedDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: today,
      builder: (
        BuildContext context,
        Widget? child,
      ) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: DojoColors.primary,
              surface: DojoColors.surface,
              onSurface: DojoColors.textPrimary,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) {
      return;
    }

    onDateChanged(picked);
    onTypeChanged(DetailsFilterType.date);
  }

  Future<void> _showFilterMenu(
    BuildContext context,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: DojoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (
        BuildContext sheetContext,
      ) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DojoColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Select Period',
                  style: TextStyle(
                    color: DojoColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _FilterTile(
                  icon: Icons.calendar_today_rounded,
                  title: 'Date',
                  subtitle: _formatDate(selectedDate),
                  selected:
                      selectedType == DetailsFilterType.date,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickDate(context);
                  },
                ),
                const SizedBox(height: 8),
                _FilterTile(
                  icon: Icons.date_range_rounded,
                  title: 'Week',
                  subtitle: _formatWeek(selectedDate),
                  selected:
                      selectedType == DetailsFilterType.week,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onTypeChanged(DetailsFilterType.week);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DojoColors.surface,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: DojoColors.divider,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selectedType == DetailsFilterType.date
                  ? Icons.calendar_today_rounded
                  : Icons.date_range_rounded,
              size: 18,
              color: DojoColors.iconPrimary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _displayValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DojoColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            InkWell(
              onTap: () => _pickDate(context),
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 20,
                  color: DojoColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _showFilterMenu(context),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Text(
                      selectedType == DetailsFilterType.date
                          ? 'Date'
                          : 'Week',
                      style: const TextStyle(
                        color: DojoColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 19,
                      color: DojoColors.iconSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: selected ? 1.0 : 0.85,
      child: Material(
        color: DojoColors.background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: DojoColors.orangeSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: DojoColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: DojoColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: DojoColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: DojoColors.primary,
                    size: 21,
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: DojoColors.iconSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
