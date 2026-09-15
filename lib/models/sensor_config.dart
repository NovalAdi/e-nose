class SensorConfig {
  final String pin;
  bool enabled;
  String name;
  String type; // 'OFF', 'Default', 'Custom'

  SensorConfig({
    required this.pin,
    required this.enabled,
    required this.name,
    required this.type,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
        'pin': pin,
        'enabled': enabled,
        'name': name,
        'type': type,
      };

  // Create from JSON
  factory SensorConfig.fromJson(Map<String, dynamic> json) => SensorConfig(
        pin: json['pin'] as String,
        enabled: json['enabled'] as bool,
        name: json['name'] as String,
        type: json['type'] as String,
      );

  // Deep copy
  SensorConfig clone() {
    return SensorConfig(
      pin: pin,
      enabled: enabled,
      name: name,
      type: type,
    );
  }
}
