class LapResponse {
  final int fastestLap;
  final int overallTime;
  final int attempts;
  final String carId;

  LapResponse({required this.fastestLap, required this.overallTime, required this.attempts, required this.carId});

  factory LapResponse.fromJson(Map<String, dynamic> json) {
    return LapResponse(
      fastestLap: json['fastestLap'] as int,
      overallTime: json['overallTime'] as int,
      attempts: json['attempts'] as int,
      carId: json['carId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'fastestLap': fastestLap,
    'overallTime': overallTime,
    'attempts': attempts,
    'carId': carId,
  };
}
