import 'package:flutter/material.dart';
import 'package:mobile_app_klinik/core/app_export.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: appTheme.whiteA700, // pastikan sama dengan AppBar
        appBar: AppBar(
          title: Text(
            'Booking',
            style: TextStyle(
              color: appTheme.black900,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: appTheme.whiteA700,
          elevation: 0, // Hilangkan shadow AppBar
          shadowColor: Colors.transparent, // Pastikan tidak ada garis halus
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  color: appTheme.whiteA700, // samakan warna latar belakang
                  child: TabBar(
                    indicatorColor: Colors.transparent, // Hilangkan garis indikator bawah tab
                    labelColor: appTheme.orange200,
                    unselectedLabelColor: appTheme.black900,
                    labelStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                    tabs: const [
                      Tab(text: "Consultation"),
                      Tab(text: "Treatment"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text("Consultation Content")),
            Center(child: Text("Treatment Content")),
          ],
        ),
      ),
    );
  }
}
