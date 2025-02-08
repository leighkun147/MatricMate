import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/study_plan.dart';
import 'package:lottie/lottie.dart';


class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  bool _isLoading = true;
  String? _error;
  int selectedDayIndex = 0;
  bool isNaturalScience = true;

  // Initialize with empty maps
  Map<String, List<String>> dayTimeSlots = {};
  Map<String, int> subjectHours = {};
  Map<String, double> subjectDistribution = {};

  // Initialize studyPlan with empty schedule
  late WeeklyStudyPlan studyPlan;

  String selectedSubject = '';
  String selectedActivity = '';
  String selectedTimeSlot = '';

  // Undo/Redo stacks
  List<WeeklyStudyPlan> _undoStack = [];
  List<WeeklyStudyPlan> _redoStack = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize empty schedule for all days
    studyPlan = WeeklyStudyPlan(
      schedule: Map.fromEntries(
        weekDays.map((day) => MapEntry(day, DaySchedule(timeSlots: []))),
      ),
    );
    
    // Initialize dayTimeSlots for all days with empty lists
    for (final day in weekDays) {
      dayTimeSlots[day] = [];
    }
    
    // Initialize analytics maps with 0 for all subjects
    subjectHours = {};
    subjectDistribution = {};
    
    // Set initial value of 0 for all subjects
    for (final subject in [...naturalScienceSubjects, ...socialScienceSubjects]) {
      subjectHours[subject.name] = 0;
      subjectDistribution[subject.name] = 0.0;
    }
    
    _initializeStudyPlan();
  }

  void _updateAnalytics() {
    if (!mounted) return;

    final Map<String, int> newSubjectMinutes = {};
    var totalMinutes = 0;

    try {
      // Reset all subject minutes to 0 first
      for (final subject in [...naturalScienceSubjects, ...socialScienceSubjects]) {
        newSubjectMinutes[subject.name] = 0;
      }

      // Calculate total minutes per subject across all days
      for (final day in weekDays) {
        final slots = studyPlan.schedule[day]?.timeSlots ?? [];
        for (final slot in slots) {
          if (slot.subjectName.isNotEmpty) {
            try {
              final start = _parseTimeString(slot.startTime);
              final end = _parseTimeString(slot.endTime);
              final minutes = end.difference(start).inMinutes;
              
              print('Subject: ${slot.subjectName}');
              print('Time slot: ${slot.startTime} - ${slot.endTime}');
              print('Minutes calculated: $minutes');
              
              if (minutes > 0) {  // Only add positive durations
                newSubjectMinutes[slot.subjectName] = 
                    (newSubjectMinutes[slot.subjectName] ?? 0) + minutes;
                totalMinutes += minutes;
              } else {
                print('Warning: Invalid time duration for ${slot.subjectName}: $minutes minutes');
              }
            } catch (e) {
              print('Error calculating time for slot: ${e.toString()}');
            }
          }
        }
      }

      print('Final minutes per subject:');
      newSubjectMinutes.forEach((subject, mins) => print('$subject: $mins minutes'));

      if (mounted) {
        setState(() {
          // Convert total minutes to hours and remaining minutes
          subjectHours = Map<String, int>.from(newSubjectMinutes.map((subject, totalMinutes) {
            final hours = totalMinutes ~/ 60;
            print('Converting $subject: $totalMinutes minutes = $hours hours');
            return MapEntry(subject, hours);
          }));
          
          // Store remaining minutes for display
          subjectDistribution = Map<String, double>.from(newSubjectMinutes.map((subject, totalMinutes) {
            final remainingMinutes = totalMinutes % 60;
            print('Remaining minutes for $subject: $remainingMinutes');
            return MapEntry(subject, remainingMinutes.toDouble());
          }));
        });
      }
    } catch (e) {
      print('Error updating analytics: ${e.toString()}');
      // Set default values to 0 in case of error
      setState(() {
        subjectHours = {};
        subjectDistribution = {};
      });
    }
  }

  Future<void> _initializeStudyPlan() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      
      // Reset analytics maps with 0 for all subjects
      subjectHours = {};
      subjectDistribution = {};
      for (final subject in [...naturalScienceSubjects, ...socialScienceSubjects]) {
        subjectHours[subject.name] = 0;
        subjectDistribution[subject.name] = 0.0;
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load time slots
      for (final day in weekDays) {
        final slots = prefs.getStringList('time_slots_$day');
        if (slots != null) {
          dayTimeSlots[day] = slots;
        } else {
          dayTimeSlots[day] = [];
        }
      }

      // Load study plan
      final studyPlanJson = prefs.getString('study_plan');
      if (studyPlanJson != null) {
        final decodedData = json.decode(studyPlanJson);
        if (mounted) {
          setState(() {
            studyPlan = WeeklyStudyPlan.fromJson(decodedData);
          });
        }
      }

      // Update analytics after loading study plan
      _updateAnalytics();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading study plan: ${e.toString()}';
          // Reset to zero values on error
          for (final subject in [...naturalScienceSubjects, ...socialScienceSubjects]) {
            subjectHours[subject.name] = 0;
            subjectDistribution[subject.name] = 0.0;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveStudyPlan() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save study plan
      final encodedData = json.encode(studyPlan.toJson());
      await prefs.setString('study_plan', encodedData);
      
      // Save time slots
      for (final entry in dayTimeSlots.entries) {
        await prefs.setStringList('time_slots_${entry.key}', entry.value);
      }
      
      _updateAnalytics();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving study plan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadTimeSlots() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      // Initialize with default time slots for each day
      for (var day in weekDays) {
        dayTimeSlots[day] = List<String>.from([]);
      }
      
      // Load custom slots for each day
      for (var day in weekDays) {
        final String? customSlotsJson = prefs.getString('custom_time_slots_$day');
        if (customSlotsJson != null) {
          final List<dynamic> customSlots = json.decode(customSlotsJson);
          dayTimeSlots[day]!.addAll(List<String>.from(customSlots));
          dayTimeSlots[day]!.sort(); // Sort time slots chronologically
        }
      }
    });
  }

  Future<void> _saveTimeSlots() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save custom slots for each day
    for (var day in weekDays) {
      final customSlots = dayTimeSlots[day]!
          .where((slot) => ![].contains(slot))
          .toList();
      await prefs.setString('custom_time_slots_$day', json.encode(customSlots));
    }
  }

  void _showAddCustomTimeSlotDialog() {
    TimeOfDay? customStartTime;
    TimeOfDay? customEndTime;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Custom Time Slot'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Start Time'),
                    trailing: Text(
                      customStartTime?.format(context) ?? 'Select Time',
                    ),
                    onTap: () async {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          customStartTime = time;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('End Time'),
                    trailing: Text(
                      customEndTime?.format(context) ?? 'Select Time',
                    ),
                    onTap: () async {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          customEndTime = time;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: customStartTime != null && customEndTime != null
                      ? () async {
                          try {
                            await _addCustomTimeSlot(
                              weekDays[selectedDayIndex],
                              customStartTime!,
                              customEndTime!,
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error adding time slot: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addCustomTimeSlot(String day, TimeOfDay start, TimeOfDay end) async {
    try {
      // Validate time slot
      if (_isTimeSlotValid(start, end)) {
        final startTimeStr = _formatTimeOfDay(start);
        final endTimeStr = _formatTimeOfDay(end);
        final newTimeSlot = '$startTimeStr - $endTimeStr';

        // Check for overlapping slots
        if (_isTimeSlotOverlapping(day, start, end)) {
          throw Exception('Time slot overlaps with existing slots');
        }

        setState(() {
          dayTimeSlots[day]!.add(newTimeSlot);
          dayTimeSlots[day]!.sort((a, b) {
            final aStart = _parseTimeString(a.split(' - ')[0]);
            final bStart = _parseTimeString(b.split(' - ')[0]);
            return aStart.compareTo(bStart);
          });
        });

        await _saveTimeSlots();
        return;
      }
      throw Exception('Invalid time slot');
    } catch (e) {
      rethrow;
    }
  }

  bool _isTimeSlotValid(TimeOfDay start, TimeOfDay end) {
    final now = DateTime.now();
    final startTime = DateTime(now.year, now.month, now.day, start.hour, start.minute);
    final endTime = DateTime(now.year, now.month, now.day, end.hour, end.minute);
    
    return endTime.isAfter(startTime);
  }

  bool _isTimeSlotOverlapping(String day, TimeOfDay newStart, TimeOfDay newEnd) {
    final existingSlots = dayTimeSlots[day]!;
    
    for (final slot in existingSlots) {
      final times = slot.split(' - ');
      final existingStart = _parseTimeOfDay(times[0]);
      final existingEnd = _parseTimeOfDay(times[1]);
      
      if (_doTimeSlotsOverlap(newStart, newEnd, existingStart, existingEnd)) {
        return true;
      }
    }
    return false;
  }

  bool _doTimeSlotsOverlap(
    TimeOfDay start1, 
    TimeOfDay end1, 
    TimeOfDay start2, 
    TimeOfDay end2
  ) {
    final now = DateTime.now();
    final s1 = DateTime(now.year, now.month, now.day, start1.hour, start1.minute);
    final e1 = DateTime(now.year, now.month, now.day, end1.hour, end1.minute);
    final s2 = DateTime(now.year, now.month, now.day, start2.hour, start2.minute);
    final e2 = DateTime(now.year, now.month, now.day, end2.hour, end2.minute);
    
    return s1.isBefore(e2) && e1.isAfter(s2);
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    final parts = timeStr.split(' ');
    final time = parts[0].split(':');
    final isPM = parts[1] == 'PM';
    
    var hour = int.parse(time[0]);
    final minute = int.parse(time[1]);
    
    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }
    
    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime _parseTimeString(String timeStr) {
    try {
      if (timeStr.isEmpty) {
        throw FormatException('Empty time string');
      }

      final parts = timeStr.split(' ');
      if (parts.length != 2) {
        throw FormatException('Invalid time format');
      }

      final time = parts[0].split(':');
      if (time.length != 2) {
        throw FormatException('Invalid time format');
      }

      final isPM = parts[1].toUpperCase() == 'PM';
      
      var hour = int.tryParse(time[0]);
      final minute = int.tryParse(time[1]);
      
      if (hour == null || minute == null) {
        throw FormatException('Invalid hour or minute');
      }
      
      if (hour < 0 || hour > 12 || minute < 0 || minute > 59) {
        throw FormatException('Hour or minute out of range');
      }
      
      if (isPM && hour != 12) {
        hour += 12;
      } else if (!isPM && hour == 12) {
        hour = 0;
      }
      
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      throw FormatException('Invalid time format: $timeStr');
    }
  }

  void _showManageTimeSlotsDialog() {
    final currentDay = weekDays[selectedDayIndex];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Manage $currentDay Time Slots',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showAddCustomTimeSlotDialog();
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: dayTimeSlots[currentDay]!.length,
                  itemBuilder: (context, index) {
                    final timeSlot = dayTimeSlots[currentDay]![index];
                    final isDefault = [].contains(timeSlot);
                    
                    return ListTile(
                      title: Text(timeSlot),
                      subtitle: Text(isDefault ? 'Default' : 'Custom'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _showDeleteTimeSlotDialog(
                            context, 
                            timeSlot, 
                            isDefault,
                            () {
                              setDialogState(() {});
                              setState(() {});
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteTimeSlotDialog(
    BuildContext context, 
    String timeSlot, 
    bool isDefault,
    VoidCallback onDelete,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Time Slot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this time slot?'),
              const SizedBox(height: 8),
              Text(
                timeSlot,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (isDefault) ...[
                const SizedBox(height: 16),
                const Text(
                  'Note: This is a default time slot. If deleted, it can be restored by clearing app data.',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  dayTimeSlots[weekDays[selectedDayIndex]]!.remove(timeSlot);
                });
                onDelete(); // Call the callback to update the manage dialog
                _saveTimeSlots();
                Navigator.of(context).pop();
                
                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Time slot deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        setState(() {
                          dayTimeSlots[weekDays[selectedDayIndex]]!.add(timeSlot);
                          dayTimeSlots[weekDays[selectedDayIndex]]!.sort();
                        });
                        _saveTimeSlots();
                      },
                    ),
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Widget _buildAnalytics() {
    try {
      // Initialize maps with 0 for all subjects
      final Map<String, int> hours = {};
      final Map<String, double> distribution = {};
      for (final subject in [...naturalScienceSubjects, ...socialScienceSubjects]) {
        hours[subject.name] = 0;
        distribution[subject.name] = 0.0;
      }

      if (subjectHours.isEmpty) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Add some activities to see analytics',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
      }

      return Card(
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weekly Study Distribution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Lottie.asset(
                          'assets/animations/under_construction.json',
                          width: 200,
                          height: 200,
                          repeat: true,
                          animate: true,
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Text(
                              'Under Construction',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Coming Soon',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.black54,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error building analytics: ${e.toString()}');
      return const SizedBox.shrink();
    }
  }

  void _showAddActivityDialog() {
    String startTime = '';
    String endTime = '';
    final formKey = GlobalKey<FormState>();
    final currentDay = weekDays[selectedDayIndex];
    
    // Reset values
    selectedSubject = '';
    selectedActivity = '';
    selectedTimeSlot = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final subjects = isNaturalScience 
                ? naturalScienceSubjects 
                : socialScienceSubjects;
            
            return AlertDialog(
              title: Text('Add Activity for $currentDay'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stream selection with better styling
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Stream: '),
                            const SizedBox(width: 8),
                            ToggleButtons(
                              isSelected: [isNaturalScience, !isNaturalScience],
                              onPressed: (index) {
                                setState(() {
                                  isNaturalScience = index == 0;
                                  selectedSubject = '';
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              selectedColor: Colors.white,
                              fillColor: Theme.of(context).primaryColor,
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('Natural'),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('Social'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Enhanced time slot selection
                      DropdownButtonFormField<String>(
                        value: selectedTimeSlot.isEmpty ? null : selectedTimeSlot,
                        hint: const Text('Select Time Slot'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a time slot';
                          }
                          try {
                            final times = value.split(' - ');
                            if (times.length != 2) {
                              return 'Invalid time slot format';
                            }
                            _parseTimeString(times[0]);
                            _parseTimeString(times[1]);
                          } catch (e) {
                            return 'Invalid time format';
                          }
                          return null;
                        },
                        items: dayTimeSlots[currentDay]?.map((slot) {
                          return DropdownMenuItem(
                            value: slot,
                            child: Text(slot),
                          );
                        }).toList() ?? [],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedTimeSlot = value;
                              final times = value.split(' - ');
                              if (times.length == 2) {
                                startTime = times[0];
                                endTime = times[1];
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Enhanced subject selection
                      DropdownButtonFormField<String>(
                        value: selectedSubject.isEmpty ? null : selectedSubject,
                        hint: const Text('Select Subject'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          prefixIcon: const Icon(Icons.book),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a subject';
                          }
                          return null;
                        },
                        items: subjects.map((subject) {
                          return DropdownMenuItem(
                            value: subject.name,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getSubjectColor(subject.name),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(subject.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSubject = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Enhanced activity input
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Activity',
                          hintText: 'e.g., Solve problems, Read chapter',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          prefixIcon: const Icon(Icons.edit_note),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an activity';
                          }
                          if (value.length < 5) {
                            return 'Activity description too short';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          selectedActivity = value;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        // Validate time slot format
                        if (startTime.isEmpty || endTime.isEmpty) {
                          throw FormatException('Invalid time slot selection');
                        }

                        // Parse times to ensure they're valid
                        final startDateTime = _parseTimeString(startTime);
                        final endDateTime = _parseTimeString(endTime);

                        if (endDateTime.isBefore(startDateTime)) {
                          throw FormatException('End time cannot be before start time');
                        }

                        final currentDay = weekDays[selectedDayIndex];
                        
                        // Initialize day schedule if it doesn't exist
                        if (studyPlan.schedule[currentDay] == null) {
                          studyPlan.schedule[currentDay] = DaySchedule(timeSlots: []);
                        }
                        
                        final daySchedule = studyPlan.schedule[currentDay]!;
                        
                        // Check for time slot conflict
                        final hasConflict = daySchedule.timeSlots.any((slot) => 
                          slot.startTime == startTime && slot.endTime == endTime);
                        
                        if (hasConflict) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('This time slot is already occupied'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        // Save current state for undo
                        _saveState();

                        final updatedSlots = List<TimeSlot>.from(daySchedule.timeSlots);
                        final newTimeSlot = TimeSlot(
                          startTime: startTime,
                          endTime: endTime,
                          subjectName: selectedSubject,
                          activity: selectedActivity,
                        );
                        
                        updatedSlots.add(newTimeSlot);
                        
                        // Sort time slots chronologically
                        updatedSlots.sort((a, b) {
                          final aTime = _parseTimeString(a.startTime);
                          final bTime = _parseTimeString(b.startTime);
                          return aTime.compareTo(bTime);
                        });
                        
                        setState(() {
                          studyPlan = WeeklyStudyPlan(
                            schedule: {
                              ...studyPlan.schedule,
                              currentDay: DaySchedule(timeSlots: updatedSlots),
                            },
                          );
                        });
                        
                        // Save changes immediately
                        await _saveStudyPlan();
                        
                        if (!mounted) return;
                        Navigator.of(context).pop();

                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error adding activity: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDaySchedule(String day, List<TimeSlot> slots) {
    final currentDayTimeSlots = dayTimeSlots[day] ?? [];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Day info - left side
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Icon(
                        _getDayIcon(day),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        day,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions - right side
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.access_time, color: Colors.white),
                        onPressed: _showManageTimeSlotsDialog,
                        tooltip: 'Manage Time Slots',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        onPressed: () {
                          selectedDayIndex = weekDays.indexOf(day);
                          _showAddActivityDialog();
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Activity'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (currentDayTimeSlots.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No time slots available. Add some time slots to get started!',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentDayTimeSlots.length,
              itemBuilder: (context, index) {
                final timeSlot = currentDayTimeSlots[index];
                final times = timeSlot.split(' - ');
                final startTime = times[0];
                final endTime = times[1];
                
                final activity = slots.firstWhere(
                  (slot) => slot.startTime == startTime && slot.endTime == endTime,
                  orElse: () => TimeSlot(
                    startTime: startTime,
                    endTime: endTime,
                    subjectName: '',
                    activity: '',
                  ),
                );

                final bool isOccupied = activity.subjectName.isNotEmpty;
                final Color backgroundColor = isOccupied
                    ? _getSubjectColor(activity.subjectName).withOpacity(0.1)
                    : Colors.transparent;

                return Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          timeSlot,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOccupied
                                ? _getSubjectColor(activity.subjectName)
                                : Colors.grey,
                          ),
                        ),
                        if (isOccupied)
                          Text(
                            'Duration: ${_calculateDuration(startTime, endTime)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    title: isOccupied
                        ? Text(
                            activity.subjectName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : const Text(
                            'Free Time',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                    subtitle: isOccupied
                        ? Text(
                            activity.activity,
                            style: TextStyle(color: Colors.grey[600]),
                          )
                        : null,
                    trailing: isOccupied
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editActivity(day, activity),
                                tooltip: 'Edit Activity',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteActivity(day, activity),
                                tooltip: 'Delete Activity',
                              ),
                            ],
                          )
                        : TextButton.icon(
                            onPressed: () {
                              selectedDayIndex = weekDays.indexOf(day);
                              selectedTimeSlot = timeSlot;
                              _showAddActivityDialog();
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                            ),
                          ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  IconData _getDayIcon(String day) {
    switch (day) {
      case 'Monday':
        return Icons.looks_one;
      case 'Tuesday':
        return Icons.looks_two;
      case 'Wednesday':
        return Icons.looks_3_outlined;
      case 'Thursday':
        return Icons.looks_4;
      case 'Friday':
        return Icons.looks_5;
      case 'Saturday':
        return Icons.looks_6;
      case 'Sunday':
        return Icons.weekend;
      default:
        return Icons.calendar_today;
    }
  }

  Color _getSubjectColor(String subject) {
    // Create a consistent color based on the subject name
    final int hash = subject.hashCode;
    final List<Color> subjectColors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.red,
      Colors.cyan,
      Colors.amber,
    ];
    return subjectColors[hash.abs() % subjectColors.length];
  }

  String _calculateDuration(String startTime, String endTime) {
    final start = _parseTimeString(startTime);
    final end = _parseTimeString(endTime);
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  void _editActivity(String day, TimeSlot activity) {
    selectedDayIndex = weekDays.indexOf(day);
    selectedTimeSlot = '${activity.startTime} - ${activity.endTime}';
    selectedSubject = activity.subjectName;
    selectedActivity = activity.activity;
    
    // First delete the existing activity
    _deleteActivity(day, activity, showSnackBar: false);
    
    // Then show the add dialog with pre-filled values
    _showAddActivityDialog();
  }

  void _deleteActivity(String day, TimeSlot activity, {bool showSnackBar = true}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Activity'),
          content: Text('Remove ${activity.subjectName} activity?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final daySchedule = studyPlan.schedule[day]!;
                  final updatedSlots = daySchedule.timeSlots
                      .where((slot) => 
                          slot.startTime != activity.startTime ||
                          slot.endTime != activity.endTime)
                      .toList();
                  
                  setState(() {
                    studyPlan = WeeklyStudyPlan(
                      schedule: {
                        ...studyPlan.schedule,
                        day: DaySchedule(timeSlots: updatedSlots),
                      },
                    );
                  });
                  
                  // Save changes immediately
                  await _saveStudyPlan();
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    
                    if (showSnackBar) {
                      // Show undo option
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Activity deleted'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () async {
                              setState(() {
                                final currentDaySchedule = studyPlan.schedule[day]!;
                                final restoredSlots = List<TimeSlot>.from(currentDaySchedule.timeSlots)
                                  ..add(activity);
                                
                                studyPlan = WeeklyStudyPlan(
                                  schedule: {
                                    ...studyPlan.schedule,
                                    day: DaySchedule(timeSlots: restoredSlots),
                                  },
                                );
                              });
                              
                              // Save the restored state
                              await _saveStudyPlan();
                            },
                          ),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete activity'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Save current state for undo
  void _saveState() {
    _undoStack.add(studyPlan);
    _redoStack.clear(); // Clear redo stack when new action is performed
    if (_undoStack.length > 10) { // Keep last 10 states
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(studyPlan);
      setState(() {
        studyPlan = _undoStack.removeLast();
      });
      _saveStudyPlan();
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(studyPlan);
      setState(() {
        studyPlan = _redoStack.removeLast();
      });
      _saveStudyPlan();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
              ElevatedButton(
                onPressed: _initializeStudyPlan,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: weekDays.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Study Plan'),
          actions: [
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _undoStack.isEmpty ? null : _undo,
              tooltip: 'Undo',
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: _redoStack.isEmpty ? null : _redo,
              tooltip: 'Redo',
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: weekDays.map((day) => Tab(text: day)).toList(),
            onTap: (index) {
              setState(() {
                selectedDayIndex = index;
              });
            },
          ),
        ),
        body: TabBarView(
          children: weekDays.map((day) {
            final daySchedule = studyPlan.schedule[day];
            return RefreshIndicator(
              onRefresh: _initializeStudyPlan,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDaySchedule(day, daySchedule?.timeSlots ?? []),
                    const SizedBox(height: 16),
                    _buildAnalytics(),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
