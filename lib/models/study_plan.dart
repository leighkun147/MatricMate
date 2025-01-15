class TimeSlot {
  final String startTime;
  final String endTime;
  final String subjectName;
  final String activity;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.subjectName,
    required this.activity,
  });

  Map<String, dynamic> toJson() => {
        'startTime': startTime,
        'endTime': endTime,
        'subjectName': subjectName,
        'activity': activity,
      };

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        startTime: json['startTime'],
        endTime: json['endTime'],
        subjectName: json['subjectName'],
        activity: json['activity'],
      );
}

class DaySchedule {
  final List<TimeSlot> timeSlots;

  DaySchedule({required this.timeSlots});

  Map<String, dynamic> toJson() => {
        'timeSlots': timeSlots.map((slot) => slot.toJson()).toList(),
      };

  factory DaySchedule.fromJson(Map<String, dynamic> json) => DaySchedule(
        timeSlots: (json['timeSlots'] as List)
            .map((slot) => TimeSlot.fromJson(slot))
            .toList(),
      );
}

class WeeklyStudyPlan {
  final Map<String, DaySchedule> schedule;

  WeeklyStudyPlan({required this.schedule});

  Map<String, dynamic> toJson() {
    Map<String, dynamic> scheduleJson = {};
    schedule.forEach((key, value) {
      scheduleJson[key] = value.toJson();
    });
    return scheduleJson;
  }

  factory WeeklyStudyPlan.fromJson(Map<String, dynamic> json) {
    Map<String, DaySchedule> schedule = {};
    json.forEach((key, value) {
      schedule[key] = DaySchedule.fromJson(value);
    });
    return WeeklyStudyPlan(schedule: schedule);
  }
}
