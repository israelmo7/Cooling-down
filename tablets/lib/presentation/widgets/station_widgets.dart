import 'package:flutter/material.dart';

import '../format.dart';

const stationLine = Color(0xFFD7E0E4);

class ScreenBody extends StatelessWidget {
  const ScreenBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF122428),
      ),
    );
  }
}

class StationPanel extends StatelessWidget {
  const StationPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: stationLine),
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.selected,
    required this.onPressed,
    required this.child,
  });

  final bool selected;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? scheme.primary : stationLine,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: child,
          ),
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
    final buttonStyle = IconButton.styleFrom(
      minimumSize: const Size(64, 64),
      iconSize: 28,
      foregroundColor: const Color(0xFF122428),
      backgroundColor: const Color(0xFFF4F7F8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    return Row(
      children: [
        IconButton.filled(
          tooltip: 'הורדת טמפרטורה',
          onPressed: () => onChanged(_step(temperature, -0.5)),
          icon: const Icon(Icons.remove),
          style: buttonStyle,
        ),
        Expanded(
          child: Text(
            formatCelsius(temperature),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Color(0xFF122428),
            ),
          ),
        ),
        IconButton.filled(
          tooltip: 'העלאת טמפרטורה',
          onPressed: () => onChanged(_step(temperature, 0.5)),
          icon: const Icon(Icons.add),
          style: buttonStyle,
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
        minimumSize: const Size.fromHeight(64),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}
