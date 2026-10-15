/// Wraps [value] so a Hebrew line does not reorder it.
String ltrIsolate(String value) => '\u2066$value\u2069';

/// `4.0°C`, kept left to right.
String ltrCelsius(double temperature) =>
    ltrIsolate('${temperature.toStringAsFixed(1)}°C');

/// `4.0 °C`, kept left to right. This is the temperature shown on the tablet.
String ltrCelsiusSpaced(double temperature) =>
    ltrIsolate('${temperature.toStringAsFixed(1)} °C');

/// `0.0–5.0°C`, kept left to right.
String ltrCelsiusRange(double min, double max) =>
    ltrIsolate('${min.toStringAsFixed(1)}–${max.toStringAsFixed(1)}°C');
