import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../bloc/usage_statistics/usage_statistics_bloc.dart';

class TodayUsageWidget extends StatefulWidget {
  const TodayUsageWidget({super.key});

  @override
  State<TodayUsageWidget> createState() => _TodayUsageWidgetState();
}

class _TodayUsageWidgetState extends State<TodayUsageWidget> {
  @override
  void initState() {
    super.initState();
    // Load today's statistics after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsageStatisticsBloc>()
          .add(LoadDailyStatistics(DateTime.now()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.todayUsage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<UsageStatisticsBloc, UsageStatisticsState>(
              buildWhen: (previous, current) => previous.daily != current.daily,
              builder: (context, state) {
                final data = state.daily;
                if (data.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (data.error != null) {
                  return Text(
                    l10n.cannotLoadData(data.error!),
                    style: const TextStyle(color: Colors.red),
                  );
                } else if (data.statistics != null) {
                  return Column(
                    children: [
                      _buildUsageRow(
                        l10n.totalUsageTime,
                        '${data.statistics!.totalUsageMinutes}${l10n.minutes}',
                      ),
                      const SizedBox(height: 8),
                      if (data.statistics!.usageByShot.isNotEmpty)
                        _buildUsageRow(
                          l10n.mostUsedMode,
                          _getMostUsedShot(data.statistics!.usageByShot),
                        ),
                    ],
                  );
                }
                return Text(l10n.noUsageData);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getMostUsedShot(Map usageByShot) {
    if (usageByShot.isEmpty) return 'N/A';
    var sorted = usageByShot.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key.displayName;
  }
}
