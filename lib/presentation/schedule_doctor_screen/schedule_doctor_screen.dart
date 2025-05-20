import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../api/api_constant.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  _DoctorScheduleScreenState createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  Map<DateTime, List<Map<String, String>>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctorSchedule();
  }

  Future<void> _fetchDoctorSchedule() async {
    final response = await http.get(Uri.parse(ApiConstants.jadwalDokter));

    try {
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final Map<DateTime, List<Map<String, String>>> events = {};
        for (var item in data) {
          final DateTime date = DateTime.parse(item['tgl_kerja']);
          final DateTime onlyDate = DateTime(date.year, date.month, date.day);

          final String doctorName = item['dokter']['nama_dokter'];
          final String timeSlot = '${item['jam_mulai']} - ${item['jam_selesai']}';

          if (events[onlyDate] == null) {
            events[onlyDate] = [];
          }
          events[onlyDate]?.add({
            'doctorName': doctorName,
            'timeSlot': timeSlot,
          });
        }

        setState(() {
          _events = events;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load schedule');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching doctor schedule: $e');
    }
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
                  firstDay: DateTime(2025),
                  lastDay: DateTime(2030),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarFormat: CalendarFormat.month,
                  eventLoader: (day) {
                    final DateTime onlyDate = DateTime(day.year, day.month, day.day);
                    return _events[onlyDate] ?? [];
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _selectedDay == null
                      ? const Center(
                          child: Text(
                            'Pilih tanggal untuk melihat jadwal dokter.',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : _isWeekend(_selectedDay!)
                          ? const Center(
                              child: Text(
                                'Klinik tidak beroperasi pada waktu tersebut.',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : _events[_selectedDay!] == null || _events[_selectedDay!]!.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Tidak ada dokter pada waktu tersebut.',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _events[_selectedDay!]!.length,
                                  itemBuilder: (context, index) {
                                    final Map<String, String> event =
                                        _events[_selectedDay!]![index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 10),
                                      child: ListTile(
                                        leading: const Icon(Icons.person),
                                        title: Text(event['doctorName']!),
                                        subtitle: Text('Jam: ${event['timeSlot']}'),
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
    );
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }
}