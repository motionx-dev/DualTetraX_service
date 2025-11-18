import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.usageGuide),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _GuideSection(
            title: l10n.guideStep1Title,
            steps: [
              l10n.guideStep1Item1,
              l10n.guideStep1Item2,
              l10n.guideStep1Item3,
            ],
          ),
          const SizedBox(height: 24),
          _GuideSection(
            title: l10n.guideStep2Title,
            steps: [
              l10n.guideStep2Item1,
              l10n.guideStep2Item2,
            ],
          ),
          const SizedBox(height: 24),
          _GuideSection(
            title: l10n.guideStep3Title,
            steps: [
              l10n.guideStep3Item1,
              l10n.guideStep3Item2,
            ],
          ),
          const SizedBox(height: 24),
          _GuideSection(
            title: l10n.guideStep4Title,
            steps: [
              l10n.guideStep4Item1,
              l10n.guideStep4Item2,
              l10n.guideStep4Item3,
            ],
          ),
          const SizedBox(height: 24),
          _GuideSection(
            title: l10n.guideStep5Title,
            steps: [
              l10n.guideStep5Item1,
              l10n.guideStep5Item2,
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final String title;
  final List<String> steps;

  const _GuideSection({
    required this.title,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...steps.map((step) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
