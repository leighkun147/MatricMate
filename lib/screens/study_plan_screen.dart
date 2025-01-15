import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/study_plan.dart';

class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  final List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  // Default time slots
  final List<String> defaultTimeSlots = [
    '6:00 AM - 8:00 AM',
    '8:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM',
    '2:00 PM - 4:00 PM',
    '4:00 PM - 6:00 PM',
    '7:00 PM - 9:00 PM',
  ];

  // List to store all time slots (default + custom)
  List<String> timeSlots = [];

  // Initialize studyPlan with an empty schedule
  WeeklyStudyPlan studyPlan = WeeklyStudyPlan(
    schedule: {
      'Monday': DaySchedule(timeSlots: []),
      'Tuesday': DaySchedule(timeSlots: []),
      'Wednesday': DaySchedule(timeSlots: []),
      'Thursday': DaySchedule(timeSlots: []),
      'Friday': DaySchedule(timeSlots: []),
      'Saturday': DaySchedule(timeSlots: []),
      'Sunday': DaySchedule(timeSlots: []),
    },
  );

  String selectedSubject = '';
  String selectedDay = '';
  String selectedTimeSlot = '';
  String selectedActivity = '';
  bool isNaturalScience = true;
  int selectedDayIndex = 0;
  TimeOfDay? customStartTime;
  TimeOfDay? customEndTime;

  @override
  void initState() {
    super.initState();
    _loadTimeSlots();
    _loadStudyPlan();
  }

  Future<void> _loadTimeSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final String? customSlotsJson = prefs.getString('custom_time_slots');
    
    setState(() {
      timeSlots = List<String>.from(defaultTimeSlots);
      if (customSlotsJson != null) {
        final List<dynamic> customSlots = json.decode(customSlotsJson);
        timeSlots.addAll(List<String>.from(customSlots));
      }
      timeSlots.sort(); // Sort time slots chronologically
    });
  }

  Future<void> _saveTimeSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final customSlots = timeSlots
        .where((slot) => !defaultTimeSlots.contains(slot))
        .toList();
    await prefs.setString('custom_time_slots', json.encode(customSlots));
  }

  void _showAddCustomTimeSlotDialog() {
    customStartTime = null;
    customEndTime = null;
    
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
                      ? () {
                          final startTimeStr = _formatTimeOfDay(customStartTime!);
                          final endTimeStr = _formatTimeOfDay(customEndTime!);
                          final newTimeSlot = '$startTimeStr - $endTimeStr';
                          
                          if (!timeSlots.contains(newTimeSlot)) {
                            setState(() {
                              timeSlots.add(newTimeSlot);
                              timeSlots.sort();
                            });
                            _saveTimeSlots();
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

  void _showManageTimeSlotsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Manage Time Slots'),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
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
                  itemCount: timeSlots.length,
                  itemBuilder: (context, index) {
                    final timeSlot = timeSlots[index];
                    final isDefault = defaultTimeSlots.contains(timeSlot);
                    
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
                              // Callback to update both dialogs
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
                  timeSlots.remove(timeSlot);
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
                          timeSlots.add(timeSlot);
                          timeSlots.sort();
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

  Future<void> _loadStudyPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final String? planJson = prefs.getString('study_plan');
    
    if (planJson != null) {
      setState(() {
        studyPlan = WeeklyStudyPlan.fromJson(json.decode(planJson));
      });
    } 
  }

  Future<void> _saveStudyPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studyPlanJson = json.encode(studyPlan.toJson());
      await prefs.setString('study_plan', studyPlanJson);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes saved successfully'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save changes'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddActivityDialog() {
    String startTime = '';
    String endTime = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final subjects = isNaturalScience 
                ? naturalScienceSubjects 
                : socialScienceSubjects;
            
            return AlertDialog(
              title: const Text('Add Study Activity'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stream selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Stream: '),
                        ToggleButtons(
                          isSelected: [isNaturalScience, !isNaturalScience],
                          onPressed: (index) {
                            setState(() {
                              isNaturalScience = index == 0;
                              selectedSubject = '';
                            });
                          },
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Natural'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Social'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Time slot selection
                    DropdownButtonFormField<String>(
                      value: selectedTimeSlot.isEmpty ? null : selectedTimeSlot,
                      hint: const Text('Select Time Slot'),
                      items: timeSlots.map((slot) {
                        return DropdownMenuItem(
                          value: slot,
                          child: Text(slot),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTimeSlot = value!;
                          final times = value.split(' - ');
                          startTime = times[0];
                          endTime = times[1];
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Subject selection
                    DropdownButtonFormField<String>(
                      value: selectedSubject.isEmpty ? null : selectedSubject,
                      hint: const Text('Select Subject'),
                      items: subjects.map((subject) {
                        return DropdownMenuItem(
                          value: subject.name,
                          child: Text(subject.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSubject = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Activity input
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Activity (e.g., Solve problems, Read chapter)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        selectedActivity = value;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: selectedSubject.isNotEmpty && 
                           selectedTimeSlot.isNotEmpty && 
                           selectedActivity.isNotEmpty
                      ? () {
                          final daySchedule = studyPlan.schedule[weekDays[selectedDayIndex]]!;
                          final updatedSlots = List<TimeSlot>.from(daySchedule.timeSlots);
                          
                          updatedSlots.add(TimeSlot(
                            startTime: startTime,
                            endTime: endTime,
                            subjectName: selectedSubject,
                            activity: selectedActivity,
                          ));
                          
                          setState(() {
                            studyPlan = WeeklyStudyPlan(
                              schedule: {
                                ...studyPlan.schedule,
                                weekDays[selectedDayIndex]: DaySchedule(timeSlots: updatedSlots),
                              },
                            );
                          });
                          
                          Navigator.of(context).pop();
                          _saveStudyPlan();
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

  Widget _buildDaySchedule(String day, List<TimeSlot> slots) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).primaryColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.access_time, color: Colors.white),
                      onPressed: _showManageTimeSlotsDialog,
                      tooltip: 'Manage Time Slots',
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        selectedDayIndex = weekDays.indexOf(day);
                        _showAddActivityDialog();
                      },
                      tooltip: 'Add Activity',
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: timeSlots.length,
            itemBuilder: (context, index) {
              final timeSlot = timeSlots[index];
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

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: ListTile(
                  leading: Text(
                    timeSlot,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  title: activity.subjectName.isEmpty
                      ? const Text('Free Time',
                          style: TextStyle(color: Colors.grey))
                      : Text(activity.subjectName),
                  subtitle: activity.activity.isEmpty
                      ? null
                      : Text(activity.activity),
                  trailing: activity.subjectName.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteActivity(day, activity),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _deleteActivity(String day, TimeSlot activityToDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Activity'),
          content: Text('Remove ${activityToDelete.subjectName} activity?'),
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
                          slot.startTime != activityToDelete.startTime ||
                          slot.endTime != activityToDelete.endTime)
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
                                ..add(activityToDelete);
                              
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: weekDays.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Study Plan'),
          bottom: TabBar(
            isScrollable: true,
            tabs: weekDays.map((day) => Tab(text: day)).toList(),
          ),
        ),
        body: TabBarView(
          children: weekDays.map((day) {
            final daySchedule = studyPlan.schedule[day];
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildDaySchedule(day, daySchedule?.timeSlots ?? []),
            );
          }).toList(),
        ),
      ),
    );
  }
}
