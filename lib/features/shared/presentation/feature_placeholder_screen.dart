import 'package:flutter/material.dart';

class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    required this.title,
    required this.description,
    required this.primaryActionLabel,
    required this.primaryActionRoute,
    super.key,
  });

  final String title;
  final String description;
  final String primaryActionLabel;
  final String primaryActionRoute;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Foundation status',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This screen is wired into app routing and is ready for feature-specific state, domain logic, and integrations.',
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                    primaryActionRoute,
                  ),
                  child: Text(primaryActionLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
