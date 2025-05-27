import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

import '../../api/api_constant.dart';
import '../../core/app_export.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  _DoctorScheduleScreenState createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  Map<String, List<Map<String, dynamic>>> _events = {};
  DateTime _focusedDay = DateTime(2025, 5, 1); // Start with May 2025
  DateTime _selectedDay = DateTime(2025, 5, 1); // Pre-select first day
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctorSchedule();
  }

  Future<void> _fetchDoctorSchedule() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.get(Uri.parse(ApiConstants.jadwalDokter));
      developer.log('API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        developer.log('Received ${data.length} schedule items');

        // Clear any existing events
        Map<String, List<Map<String, dynamic>>> events = {};

        for (var item in data) {
          final String dateStr = item['tgl_kerja']; // Format: "2025-05-01"
          developer.log('Processing date: $dateStr');

          if (events[dateStr] == null) {
            events[dateStr] = [];
          }

          events[dateStr]!.add({
            'doctorName': item['dokter']['nama_dokter'],
            'doctorPhoto': item['dokter']['foto_dokter'],
            'timeSlot': '${item['jam_mulai']} - ${item['jam_selesai']}',
            'id_dokter': item['dokter']['id_dokter'],
          });

          developer.log('Added doctor ${item['dokter']['nama_dokter']} to $dateStr');
        }

        developer.log('Events created for dates: ${events.keys.join(", ")}');

        setState(() {
          _events = events;
          _isLoading = false;
        });
      } else {
        developer.log('Failed to load doctor schedule: ${response.statusCode}');
        throw Exception('Failed to load doctor schedule');
      }
    } catch (e) {
      developer.log('Error fetching schedule: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading schedule: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final dateStr = _formatDate(day);
    developer.log('Looking for events on $dateStr: ${_events.containsKey(dateStr) ? "Found" : "Not found"}');
    return _events[dateStr] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Dokter'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2024),
            lastDay: DateTime(2026),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              developer.log('Day selected: ${_formatDate(selectedDay)}');
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: CalendarFormat.month,
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: appTheme.orange200,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: appTheme.lightGreen.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              markerSize: 8.0,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appTheme.black900,
              ),
            ),
          ),

          // Debug info
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Selected: ${_formatDate(_selectedDay)} | Available dates: ${_events.keys.join(", ")}',
              style: const TextStyle(fontSize: 12),
            ),
          ),

          Expanded(
            child: _buildScheduleContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleContent() {
    final String dateStr = _formatDate(_selectedDay);

    // Check for weekend first
    if (_selectedDay.weekday == DateTime.saturday || _selectedDay.weekday == DateTime.sunday) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: appTheme.lightBadge100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: appTheme.orange200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 48, color: appTheme.orange200),
              const SizedBox(height: 16),
              const Text(
                'Klinik tidak beroperasi pada akhir pekan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Check if there are events
    if (!_events.containsKey(dateStr) || _events[dateStr]!.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: appTheme.lightBadge100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: appTheme.lightGrey),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy, size: 48, color: appTheme.lightGrey),
              const SizedBox(height: 16),
              const Text(
                'Tidak ada jadwal dokter pada tanggal ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Display events
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _events[dateStr]!.length,
      itemBuilder: (context, index) {
        final event = _events[dateStr]![index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: appTheme.black900, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Doctor image
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: appTheme.black900, width: 1),
                    image: DecorationImage(
                      image: NetworkImage(event['doctorPhoto']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Doctor info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['doctorName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: appTheme.lightBadge100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 16, color: appTheme.orange200),
                            const SizedBox(width: 4),
                            Text(
                              event['timeSlot'],
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: appTheme.orange200,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}