import 'package:flutter/material.dart';

class DetailBookingKonsultasi extends StatelessWidget {
  final Map<String, dynamic> dokter;

  const DetailBookingKonsultasi({super.key, required this.dokter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Dokter"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: const CircleAvatar(
                radius: 50,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              dokter['nama'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Spesialis: ${dokter['spesialis']}"),
            const SizedBox(height: 10),
            const Text("Pengalaman: 5 tahun"),
            const SizedBox(height: 10),
            const Text("Rating: ⭐⭐⭐⭐⭐"),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Lanjut ke proses booking di sini
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Booking Sekarang"),
            )
          ],
        ),
      ),
    );
  }
}
