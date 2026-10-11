import 'package:flutter/material.dart';

import '../format.dart';

class StationPanel extends StatelessWidget {
  const StationPanel({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class TemperatureStepper extends StatelessWidget {
  const TemperatureStepper({
    super.key,
    required this.temperature,
    required this.onChanged,
  });

  final double temperature;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filled(
          tooltip: 'Decrease temperature',
          onPressed: () => onChanged(_step(temperature, -0.5)),
          icon: const Icon(Icons.remove),
          iconSize: 32,
          style: IconButton.styleFrom(minimumSize: const Size(64, 64)),
        ),
        Expanded(
          child: Text(
            formatCelsius(temperature),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        IconButton.filled(
          tooltip: 'Increase temperature',
          onPressed: () => onChanged(_step(temperature, 0.5)),
          icon: const Icon(Icons.add),
          iconSize: 32,
          style: IconButton.styleFrom(minimumSize: const Size(64, 64)),
        ),
      ],
    );
  }

  double _step(double current, double delta) {
    final next = (current + delta).clamp(-40.0, 30.0).toDouble();
    return (next * 2).round() / 2;
  }
}
