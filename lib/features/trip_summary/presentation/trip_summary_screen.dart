import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../application/trip_summary_controller.dart';

class TripSummaryScreen extends StatefulWidget {
  const TripSummaryScreen({
    super.key,
    this.controller,
  });

  final TripSummaryController? controller;

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen> {
  late final TripSummaryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TripSummaryController();
    _controller.addListener(_handleControllerUpdate);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Trip Summary'),
            actions: <Widget>[
              IconButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.settings),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_controller.hasData
                    ? _EmptyTripSummary(
                        onGoToDriverMode: () => Navigator.of(context)
                            .pushNamed(AppRoutes.driver),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: <Widget>[
                          _SummaryHeroCard(summary: _controller.summary),
                          const SizedBox(height: 16),
                          _MetricGrid(summary: _controller.summary),
                          const SizedBox(height: 16),
                          const _PlaceholderChartCard(),
                          const SizedBox(height: 16),
                          _TimelineCard(summary: _controller.summary),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _confirmClearCurrentTrip,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Clear Current Trip'),
                            ),
                          ),
                        ],
                      ),
          ),
        );
      },
    );
  }

  Future<void> _confirmClearCurrentTrip() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear current trip?'),
          content: const Text(
            'This removes the latest trip summary, related trip events, and hazards captured in that trip window from local storage.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _controller.clearCurrentTrip();
    }
  }

  void _handleControllerUpdate() {
    final String? message = _controller.statusMessage;
    if (!mounted || message == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    _controller.clearStatusMessage();
  }
}

class _EmptyTripSummary extends StatelessWidget {
  const _EmptyTripSummary({
    required this.onGoToDriverMode,
  });

  final VoidCallback onGoToDriverMode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'No trip summary available yet.',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start driver mode and capture trip events to populate this summary.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onGoToDriverMode,
              child: const Text('Open Driver Mode'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeroCard extends StatelessWidget {
  const _SummaryHeroCard({
    required this.summary,
  });

  final TripSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final Duration duration = summary.tripDuration;
    final String durationLabel =
        '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Latest Trip',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Trip ID: ${summary.tripId}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Text(
              durationLabel,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Trip duration',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.summary,
  });

  final TripSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final List<_MetricItem> items = <_MetricItem>[
      _MetricItem('Total Hazards', '${summary.totalHazardsDetected}'),
      _MetricItem('Potholes', '${summary.potholes}'),
      _MetricItem('Road Humps', '${summary.roadHumps}'),
      _MetricItem('Pedestrians', '${summary.pedestrianAlerts}'),
      _MetricItem('Vehicles', '${summary.vehicleAlerts}'),
      _MetricItem('Critical Alerts', '${summary.criticalAlerts}'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _MetricItem item = items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  item.value,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricItem {
  const _MetricItem(this.label, this.value);

  final String label;
  final String value;
}

class _PlaceholderChartCard extends StatelessWidget {
  const _PlaceholderChartCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Trip Trend Chart',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: <Color>[
                    Color(0xFFDBF4FF),
                    Color(0xFFF2F7EA),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Chart placeholder for hazard trend and risk intensity',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.summary,
  });

  final TripSummaryData summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Recent Alert Timeline',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...summary.timeline.take(8).map(
              (TripTimelineItem item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                trailing: Text(item.severityLabel.toUpperCase()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
