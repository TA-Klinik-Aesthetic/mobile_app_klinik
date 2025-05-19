import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

<<<<<<< Updated upstream:lib/presentation/treatment_screen/treatment_screen.dart
import '../../api/api_constant.dart';

class TreatmentScreen extends StatefulWidget {
  const TreatmentScreen({super.key});
=======
class ScheduleDoctorScreen extends StatelessWidget {
  const ScheduleDoctorScreen({super.key});
>>>>>>> Stashed changes:lib/presentation/schedule_doctor_screen/schedule_doctor_screen.dart

  @override
  State<TreatmentScreen> createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen> {
  DateTime? _selectedDateTime;
  List<Map<String, dynamic>> treatmentDetails = [];
  List<Map<String, dynamic>> doctors = [];
  List<Map<String, dynamic>> beauticians = [];
  List<Map<String, dynamic>> treatments = [];
  List<Map<String, dynamic>> bookingHistory = [];
  int? idUser;

  @override
  void initState() {
    super.initState();
    debugPrint("Inisialisasi TreatmentScreen");
    fetchDoctors();
    fetchBeauticians();
    fetchTreatments();
    _loadUserId();
    fetchBookingHistory();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getInt('id_user');
    });
    print('ID User dari SharedPreferences: $idUser');

    if (idUser != null) {
      fetchBookingHistory();
  }
  }

Future<void> fetchBookingHistory() async {
  debugPrint("Memulai fetchBookingHistory...");
  try {
    final response = await http.get(Uri.parse(ApiConstants.booking));
    debugPrint("Response statusCode fetchBookingHistory: ${response.statusCode}");
    debugPrint("Response body fetchBookingHistory: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<Map<String, dynamic>> rawData = List<Map<String, dynamic>>.from(jsonDecode(response.body));

      setState(() {
        bookingHistory = rawData
            .where((item) {
              final bookingUserId = item['id_user'];
              debugPrint("bookingUserId: $bookingUserId (type: ${bookingUserId.runtimeType})");
              if (bookingUserId is int) {
                return bookingUserId == idUser;
              } else if (bookingUserId is String) {
                return int.tryParse(bookingUserId) == idUser;
              }
              return false;
            })
            .toList();
      });

      debugPrint("Filtered booking history: $bookingHistory");
    } else {
      throw Exception('Gagal memuat data riwayat booking');
    }
  } catch (e) {
    debugPrint("Error fetchBookingHistory: $e");
    showErrorDialog('Gagal mengambil data riwayat booking: $e');
  }
}




  Future<void> fetchDoctors() async {
    debugPrint("Memulai fetchDoctors...");
    try {
      final response = await http.get(Uri.parse(ApiConstants.dokter));
      debugPrint("Response statusCode fetchDoctors: ${response.statusCode}");
      debugPrint("Response body fetchDoctors: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          doctors = List<Map<String, dynamic>>.from(data['data']);
        });
        debugPrint("Data doctors berhasil diambil: $doctors");
      } else {
        throw Exception('Failed to load doctors');
      }
    } catch (e) {
      debugPrint("Error fetchDoctors: $e");
      showErrorDialog('Gagal mengambil data dokter: $e');
    }
  }

  Future<void> fetchBeauticians() async {
    debugPrint("Memulai fetchBeauticians...");
    try {
      final response = await http.get(Uri.parse(ApiConstants.beautician));
      debugPrint("Response statusCode fetchBeauticians: ${response.statusCode}");
      debugPrint("Response body fetchBeauticians: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          beauticians = List<Map<String, dynamic>>.from(data['data']);
        });
        debugPrint("Data beauticians berhasil diambil: $beauticians");
      } else {
        throw Exception('Failed to load beauticians');
      }
    } catch (e) {
      debugPrint("Error fetchBeauticians: $e");
      showErrorDialog('Gagal mengambil data beautician: $e');
    }
  }

  Future<void> fetchTreatments() async {
    debugPrint("Memulai fetchTreatments...");
    try {
      final response = await http.get(Uri.parse(ApiConstants.treatment));
      debugPrint("Response statusCode fetchTreatments: ${response.statusCode}");
      debugPrint("Response body fetchTreatments: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          treatments = List<Map<String, dynamic>>.from(data['data']);
        });
        debugPrint("Data treatments berhasil diambil: $treatments");
      } else {
        throw Exception('Failed to load treatments');
      }
    } catch (e) {
      debugPrint("Error fetchTreatments: $e");
      showErrorDialog('Gagal mengambil data treatment: $e');
    }
  }

  void showErrorDialog(String message) {
    debugPrint("Menampilkan ErrorDialog: $message");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

<<<<<<< Updated upstream:lib/presentation/treatment_screen/treatment_screen.dart
  void _addTreatmentDetail() {
    setState(() {
      treatmentDetails.add({
        'id_treatment': null,
        'id_dokter': null,
        'id_beautician': null,
      });
    });
    debugPrint("Tambah treatmentDetail: $treatmentDetails");
  }

  void _removeTreatmentDetail(int index) {
    setState(() {
      treatmentDetails.removeAt(index);
    });
    debugPrint("Hapus treatmentDetail index $index: $treatmentDetails");
  }

  Future<void> _pickDateTime() async {
    debugPrint("Memulai pemilihan tanggal dan waktu...");
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });

    debugPrint("Waktu terpilih: $_selectedDateTime");
  }

  Future<void> _submitBooking() async {
    debugPrint("Memulai _submitBooking...");
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih waktu treatment')),
      );
      debugPrint("Gagal submit: Waktu treatment belum dipilih");
      return;
    }

    const String url = ApiConstants.bookingTreatment;
    final body = {
      "id_user": idUser,
      "waktu_treatment": _selectedDateTime!
          .toIso8601String()
          .replaceFirst('T', ' ')
          .split('.')
          .first,
      "status_booking_treatment": "Verifikasi",
      "potongan_harga": null,
      "details": treatmentDetails,
    };

    debugPrint("Request body: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint("Response statusCode: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil: ${data['message']}')),
        );
        debugPrint("Submit booking berhasil: ${data['message']}");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
        debugPrint("Submit booking gagal: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error _submitBooking: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

Widget _buildHistoryTab() {
  return ListView.builder(
    itemCount: bookingHistory.length,
    itemBuilder: (context, index) {
      final booking = bookingHistory[index];

      Color cardColor;
      switch (booking['status_booking_treatment']) {
        case 'Verifikasi':
          cardColor = Colors.yellow.shade100;
          break;
        case 'Berhasil dibooking':
          cardColor = Colors.green.shade100;
          break;
        default:
          cardColor = Colors.grey.shade100;
      }

      return Card(
        margin: const EdgeInsets.all(8.0),
        elevation: 4,
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Treatment ID: ${booking['id_booking_treatment']}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text('Tanggal Treatment: ${booking['waktu_treatment']}'),
              Text('Status: ${booking['status_booking_treatment']}'),
              if (booking['harga_total'] != null)
                Text('Harga Total: Rp ${booking['harga_total']}'),
              if (booking['potongan_harga'] != null)
                Text('Potongan Harga: Rp ${booking['potongan_harga']}'),
              if (booking['harga_akhir_treatment'] != null)
                Text('Harga Akhir: Rp ${booking['harga_akhir_treatment']}'),
            ],
          ),
        ),
      );
    },
  );
}


  Widget _buildBookingTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickDateTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _selectedDateTime == null
                    ? 'Pilih Waktu Treatment'
                    : _selectedDateTime.toString().split(' ').first,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: treatmentDetails.length,
              itemBuilder: (context, index) {
                final detail = treatmentDetails[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        DropdownButtonFormField<int>(
                          value: detail['id_treatment'],
                          onChanged: (value) {
                            setState(() {
                              detail['id_treatment'] = value;
                            });
                          },
                          items: treatments.map((treatment) {
                            return DropdownMenuItem<int>(
                              value: treatment['id_treatment'],
                              child: Text(treatment['nama_treatment']),
                            );
                          }).toList(),
                          decoration: const InputDecoration(labelText: 'Pilih Treatment'),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: detail['id_dokter'],
                          onChanged: (value) {
                            setState(() {
                              detail['id_dokter'] = value;
                            });
                          },
                          items: doctors.map((doctor) {
                            return DropdownMenuItem<int>(
                              value: doctor['id_dokter'],
                              child: Text(doctor['nama_dokter']),
                            );
                          }).toList(),
                          decoration: const InputDecoration(labelText: 'Pilih Dokter'),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: detail['id_beautician'],
                          onChanged: (value) {
                            setState(() {
                              detail['id_beautician'] = value;
                            });
                          },
                          items: beauticians.map((beautician) {
                            return DropdownMenuItem<int>(
                              value: beautician['id_beautician'],
                              child: Text(beautician['nama_beautician']),
                            );
                          }).toList(),
                          decoration: const InputDecoration(labelText: 'Pilih Beautician'),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: () => _removeTreatmentDetail(index),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton.icon(
            onPressed: _addTreatmentDetail,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Treatment'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _submitBooking,
            child: const Text('Kirim Booking Treatment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Treatment'),
          backgroundColor: Colors.green,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.history), text: 'History'),
              Tab(icon: Icon(Icons.book_online), text: 'Booking'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHistoryTab(),
            _buildBookingTab(),
          ],
        ),
      ),
=======
  AppBar appBar() {
    return AppBar(
      title: Text(
        'Schedule Doctor',
        style: TextStyle(
          color: appTheme.black900,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: appTheme.whiteA700,
      elevation: 0.0,
      centerTitle: true,
>>>>>>> Stashed changes:lib/presentation/schedule_doctor_screen/schedule_doctor_screen.dart
    );
  }
}