import 'package:flutter/material.dart';

class ReadingHeatmap extends StatelessWidget {
  final Map<String, int> stats;
  final int totalDays;

  const ReadingHeatmap({
    super.key,
    required this.stats,
    required this.totalDays
  });

  Color getColorForPages(int pages, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (pages == 0) return colorScheme.primary.withAlpha(50);
    if (pages < 5) return colorScheme.primary.withAlpha(100);
    if (pages < 10) return colorScheme.primary.withAlpha(300);
    if (pages < 20) return colorScheme.primary.withAlpha(500);
    return colorScheme.primary;
  }

  List<DateTime> generateLastNDays(int days) {
    final now = DateTime.now();
    return List.generate(
      days,
          (index) => DateTime(now.year, now.month, now.day - (days - index - 1)),
    );
  }

  String formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final days = generateLastNDays(totalDays);

    final weeks = <List<DateTime>>[];
    for (int i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, (i + 7) > days.length ? days.length : i + 7));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: weeks.map((week) {
          return Column(
            children: week.map((day) {
              final key = formatDate(day);
              final pagesRead = stats[key] ?? 0;

              return Tooltip(
                message: "$key\nPages read: $pagesRead",
                child: Container(
                  margin: const EdgeInsets.all(2),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: getColorForPages(pagesRead, context),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
