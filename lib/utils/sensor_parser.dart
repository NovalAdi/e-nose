class SensorParser {
  /// Parses a serial stream line formatted as "A0:val@A1:val..."
  /// and returns a map of pin to sensor value.
  static Map<String, double> parseLine(String line, List<String> enabledPins) {
    final Map<String, double> data = {
      for (var pin in enabledPins) pin: 0.0
    };

    if (line.isEmpty) return data;

    // Split by '@' to separate sensor readings
    final segments = line.split('@');
    for (final segment in segments) {
      // Split by ':' to get pin and value
      final parts = segment.split(':');
      if (parts.length < 2) continue;

      final key = parts[0].trim();
      final valStr = parts[1].trim();

      // Check if this sensor is enabled and parse the value
      if (enabledPins.contains(key)) {
        final val = double.tryParse(valStr);
        if (val != null) {
          data[key] = val;
        }
      }
    }

    return data;
  }

  /// Calculates average of each sensor column from a collection of row readings
  /// Returns a Map containing pins to their calculated average values.
  static Map<String, double> calculateAverages(
      List<Map<String, double>> rows, List<String> allPins) {
    final Map<String, double> averages = {
      for (var pin in allPins) pin: 0.0
    };

    if (rows.isEmpty) return averages;

    for (final pin in allPins) {
      double sum = 0.0;
      int count = 0;
      for (final row in rows) {
        if (row.containsKey(pin)) {
          sum += row[pin]!;
          count++;
        }
      }
      averages[pin] = count > 0 ? sum / count : 0.0;
    }

    return averages;
  }
  
  /// Formats the raw line into human readable values for logs
  static String formatLineToLog(Map<String, double> data) {
    return data.entries.map((e) => "${e.key}: ${e.value.round()}").join(" | ");
  }
}
