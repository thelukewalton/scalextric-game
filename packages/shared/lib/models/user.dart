class User {
  User({
    required this.name,
    required this.id,
    this.attempts,
    this.overallTime,
    this.fastestLap,
    this.change,
    this.diff,
    this.newRecord,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is User && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;

  factory User.fromSQL(Map<String, dynamic> sql) {
    return User(
      id: sql['id'].toString(),
      name: sql['name'],
      attempts: sql['attempts'] as int,
      overallTime: sql['overall_time'] as int?,
      fastestLap: sql['lap_time'] as int?,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final int? overallTime;
    final int attempts;
    final int? fastestLap;

    if (json.containsKey('fastestLap') && json['fastestLap'] != null) {
      fastestLap = json['fastestLap'];
    } else {
      fastestLap = null;
    }
    if (json.containsKey('attempts') && json['attempts'] != null) {
      attempts = (json['attempts']);
    } else {
      attempts = 0;
    }
    if (json.containsKey('overallTime') && json['overallTime'] != null) {
      overallTime = json['overallTime'];
    } else {
      overallTime = null;
    }

    return User(
      id: json['id'].toString(),
      name: json['name'] as String,
      attempts: attempts,
      overallTime: overallTime,
      fastestLap: fastestLap,
    );
  }

  final String name;
  int? fastestLap;
  int? overallTime;
  final String id;
  int? attempts;
  final PlaceChange? change;
  final bool? newRecord;
  final int? diff;

  User copyWith({
    String? name,
    String? employeeId,
    int? overallTime,
    int? fastestLap,
    String? id,
    int? attempts,
    PlaceChange? change,
    bool? newRecord,
    int? diff,
  }) {
    return User(
      name: name ?? this.name,
      overallTime: overallTime ?? this.overallTime,
      fastestLap: fastestLap ?? this.fastestLap,
      id: id ?? this.id,
      attempts: attempts ?? this.attempts,
      change: change ?? this.change,
      newRecord: newRecord ?? this.newRecord,
      diff: diff ?? this.diff,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'name': name, 'id': id};

    if (overallTime != null) data['overallTime'] = overallTime;
    if (fastestLap != null) data['fastestLap'] = fastestLap;
    if (attempts != null) data['attempts'] = attempts;
    if (change != null) data['change'] = change.toString();
    if (newRecord != null) data['newRecord'] = newRecord;
    if (diff != null) data['diff'] = diff;

    return data;
  }
}

enum PlaceChange { up, down, none }
