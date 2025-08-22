class Hourly {
  int hour;
  int temp;
  String condition;
  Hourly({required this.hour, required this.temp, required this.condition});

  Map<String, dynamic> toJson() => {
    'hour': hour,
    'temp': temp,
    'condition': condition,
  };

  factory Hourly.fromJson(Map<String, dynamic> json) => Hourly(
    hour: (json['hour'] as num).toInt(),
    temp: (json['temp'] as num).toInt(),
    condition: json['condition'] as String,
  );
}
