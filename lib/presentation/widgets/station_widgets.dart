import 'package:flutter/material.dart';

import '../format.dart';

class ScreenBody extends StatelessWidget {
  const ScreenBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
      child: child,
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
          style: IconButton.styleFrom(
            minimumSize: const Size(88, 88),
            iconSize: 40,
          ),
        ),
        Expanded(
          child: Text(
            formatCelsius(temperature),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton.filled(
          tooltip: 'Increase temperature',
          onPressed: () => onChanged(_step(temperature, 0.5)),
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(
            minimumSize: const Size(88, 88),
            iconSize: 40,
          ),
        ),
      ],
    );
  }

  double _step(double current, double delta) {
    final next = (current + delta).clamp(-40.0, 30.0).toDouble();
    return (next * 2).round() / 2;
  }
}

class ConfirmBar extends StatelessWidget {
  const ConfirmBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.buttonKey,
  });

  final String label;
  final VoidCallback? onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: buttonKey,
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(88),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}
