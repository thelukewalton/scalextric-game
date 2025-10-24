class RFIDResponse {
  final String idHex;
  final DateTime timestamp;

  RFIDResponse({required this.idHex, required this.timestamp});

  factory RFIDResponse.fromJson(Map<String, dynamic> json) {
    return RFIDResponse(idHex: json['data']['idHex'], timestamp: DateTime.parse(json['timestamp']));
  }

  Map<String, dynamic> toJson() => {
    'data': {'idHex': idHex},
    'timestamp': timestamp.toIso8601String(),
  };
}
