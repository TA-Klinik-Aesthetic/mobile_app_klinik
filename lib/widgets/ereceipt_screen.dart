import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';

import '../core/app_export.dart';
import '../core/services/pdf_generator.dart';

enum ReceiptType { product, treatment }

class EReceiptScreen extends StatelessWidget {
  final ReceiptType type;

  // Produk
  final Map<String, dynamic>? purchaseData;
  final Map<int, Map<String, dynamic>>? productsData;

  // Treatment
  final Map<String, dynamic>? bookingData;

  const EReceiptScreen.product({
    super.key,
    required Map<String, dynamic> purchaseData,
    required Map<int, Map<String, dynamic>> productsData,
  })  : type = ReceiptType.product,
        purchaseData = purchaseData,
        productsData = productsData,
        bookingData = null;

  const EReceiptScreen.treatment({
    super.key,
    required Map<String, dynamic> bookingData,
  })  : type = ReceiptType.treatment,
        purchaseData = null,
        productsData = null,
        bookingData = bookingData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          'E-Receipt',
          style: TextStyle(
            color: appTheme.orange200,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appTheme.whiteA700,
        elevation: 0.0,
        centerTitle: true,
        iconTheme: IconThemeData(color: appTheme.black900),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: type == ReceiptType.product
              ? _buildProductReceipt()
              : _buildTreatmentReceipt(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: appTheme.orange200, width: 2),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () => _downloadPDF(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download, color: appTheme.orange200, size: 20),
                            const SizedBox(width: 8),
                            Text('Download PDF',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: appTheme.orange200)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: appTheme.orange200, width: 2),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () => _sharePDF(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share, color: appTheme.orange200, size: 20),
                            const SizedBox(width: 8),
                            Text('Bagikan',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: appTheme.orange200)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ======================== PRODUCT RECEIPT ========================
  Widget _buildProductReceipt() {
    final purchase = purchaseData!;
    final products = productsData!;
    return Column(
      children: [
        _buildReceiptHeader(),
        const SizedBox(height: 24),
        _buildTransactionSectionProduct(purchase, products),
        const SizedBox(height: 24),
        _buildPaymentSectionProduct(purchase),
        const SizedBox(height: 24),
        _buildThankYouSection(),
      ],
    );
  }

  Widget _buildTransactionSectionProduct(
      Map<String, dynamic> purchase, Map<int, Map<String, dynamic>> products) {
    final List items = (purchase['detail_pembelian'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TRANSAKSI',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appTheme.black900)),
        const SizedBox(height: 12),
        _buildRow('ID Transaksi', '#PURC${purchase['id_penjualan_produk']}'),
        const SizedBox(height: 8),
        if (purchase['pembayaran_produk'] != null) ...[
          _buildRow('ID Pembayaran', '#PAYM${purchase['pembayaran_produk']['id_pembayaran']}'),
          const SizedBox(height: 8),
          if (purchase['pembayaran_produk']['order_id'] != null) ...[
            _buildRow('Order ID', purchase['pembayaran_produk']['order_id']),
            const SizedBox(height: 8),
          ],
        ],
        _buildRow('Tanggal', _formatDateTime(purchase['tanggal_pembelian'].toString())),
        const SizedBox(height: 12),
        Container(width: double.infinity, height: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(vertical: 8)),
        Text('PRODUK', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: appTheme.black900)),
        const SizedBox(height: 8),
        ...items.map<Widget>((item) {
          final int? productId = int.tryParse(item['id_produk'].toString());
          final productData = productId != null ? products[productId] : null;
          final productName = productData?['nama_produk'] ?? 'Produk #${item['id_produk']}';
          final quantity = int.tryParse(item['jumlah_produk'].toString()) ?? 0;
          final unitPrice = double.tryParse(item['harga_penjualan_produk'].toString()) ?? 0.0;
          final totalAmount = unitPrice * quantity;

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: Text(productName, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${quantity}x @ Rp ${_formatMoney(unitPrice)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(),
                    Text('Rp ${_formatMoney(totalAmount)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: appTheme.orange200)),
                  ],
                ),
                if (item != items.last)
                  Container(height: 0.5, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(vertical: 4)),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPaymentSectionProduct(Map<String, dynamic> purchase) {
    final payment = purchase['pembayaran_produk'];
    if (payment == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DETAIL PEMBAYARAN',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appTheme.black900)),
        const SizedBox(height: 12),
        _buildRow('Metode Pembayaran', payment['metode_pembayaran'] ?? '-'),
        const SizedBox(height: 8),
        if (payment['waktu_pembayaran'] != null) ...[
          _buildRow('Waktu Pembayaran', _formatDateTime(payment['waktu_pembayaran'].toString())),
          const SizedBox(height: 8),
        ],
        _buildRow('Subtotal', 'Rp ${_formatMoney(purchase['harga_total'])}'),
        const SizedBox(height: 4),
        if (purchase['potongan_harga'] != null &&
            double.tryParse(purchase['potongan_harga'].toString()) != 0) ...[
          _buildRow('Potongan', '- Rp ${_formatMoney(purchase['potongan_harga'])}'),
          const SizedBox(height: 4),
        ],
        if (purchase['besaran_pajak'] != null &&
            double.tryParse(purchase['besaran_pajak'].toString()) != 0) ...[
          _buildRow('Pajak (10%)', 'Rp ${_formatMoney(purchase['besaran_pajak'])}'),
          const SizedBox(height: 8),
        ],
        Container(height: 1, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        _buildRow('Total Pembayaran', 'Rp ${_formatMoney(purchase['harga_akhir'])}', isTotal: true),
        const SizedBox(height: 16),
        if (payment['transaction_status'] != null ||
            payment['payment_type'] != null ||
            payment['bank'] != null ||
            payment['va_number'] != null) ...[
          Text('DETAIL TEKNIS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: appTheme.black900)),
          const SizedBox(height: 8),
          if (payment['transaction_status'] != null) ...[
            _buildRow('Status Transaksi', payment['transaction_status'].toString()),
            const SizedBox(height: 4),
          ],
          if (payment['payment_type'] != null) ...[
            _buildRow('Tipe Pembayaran', payment['payment_type'].toString()),
            const SizedBox(height: 4),
          ],
          if (payment['bank'] != null) ...[
            _buildRow('Bank', payment['bank'].toString().toUpperCase()),
            const SizedBox(height: 4),
          ],
          if (payment['va_number'] != null) ...[
            _buildRow('VA Number', payment['va_number'].toString()),
          ],
        ],
      ],
    );
  }

  // ======================== TREATMENT RECEIPT ========================
  Widget _buildTreatmentReceipt() {
    final booking = bookingData!;
    final payment = booking['pembayaran_treatment'];
    final List details = (booking['detail_booking'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header lengkap (logo + alamat)
        _buildReceiptHeader(),
        const SizedBox(height: 24),

        // TRANSAKSI
        Text(
          'TRANSAKSI',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appTheme.black900),
        ),
        const SizedBox(height: 12),
        _buildRow('ID Booking', '#BOOK${booking['id_booking_treatment']}'),
        const SizedBox(height: 8),
        if (payment != null && payment['id_pembayaran'] != null) ...[
          _buildRow('ID Pembayaran', '#PAYM${payment['id_pembayaran']}'),
          const SizedBox(height: 8),
        ],
        if (payment != null && payment['order_id'] != null) ...[
          _buildRow('Order ID', payment['order_id'].toString()),
          const SizedBox(height: 8),
        ],
        _buildRow('Tanggal Booking', _formatDateTime(booking['created_at']?.toString())),
        const SizedBox(height: 8),
        _buildRow('Jadwal Treatment', _formatDateTime(booking['waktu_treatment']?.toString())),

        const SizedBox(height: 12),
        Container(width: double.infinity, height: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(vertical: 8)),

        // RINCIAN TREATMENT
        const Text('RINCIAN TREATMENT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...details.map<Widget>((it) {
          final tr = it['treatment'] ?? {};
          final name = (tr['nama_treatment'] ?? '-').toString();
          final price = it['biaya_treatment'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontSize: 12))),
                Text('Rp ${_formatMoney(price)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: appTheme.orange200)),
              ],
            ),
          );
        }).toList(),

        const SizedBox(height: 12),
        Container(width: double.infinity, height: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(vertical: 8)),

        // DETAIL PEMBAYARAN
        Text('DETAIL PEMBAYARAN',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appTheme.black900)),
        const SizedBox(height: 12),
        if (payment != null) ...[
          _buildRow('Metode Pembayaran', payment['metode_pembayaran']?.toString() ?? '-'),
          if (payment['waktu_pembayaran'] != null) ...[
            const SizedBox(height: 8),
            _buildRow('Waktu Pembayaran', _formatDateTime(payment['waktu_pembayaran'].toString())),
          ],
          const SizedBox(height: 8),
        ],
        _buildRow('Subtotal', 'Rp ${_formatMoney(booking['harga_total'])}'),
        if (booking['id_promo'] != null) ...[
          const SizedBox(height: 4),
          _buildRow('Potongan', '- Rp ${_formatMoney(booking['potongan_harga'])}'),
        ],
        const SizedBox(height: 4),
        _buildRow('Pajak (10%)', 'Rp ${_formatMoney(booking['besaran_pajak'])}'),
        const SizedBox(height: 8),
        Container(height: 1, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        _buildRow('Total Pembayaran', 'Rp ${_formatMoney(booking['harga_akhir_treatment'])}', isTotal: true),

        // DETAIL TEKNIS (opsional, jika ada)
        if (payment != null &&
            (payment['transaction_status'] != null ||
             payment['payment_type'] != null ||
             payment['bank'] != null ||
             payment['va_number'] != null)) ...[
          const SizedBox(height: 16),
          Text('DETAIL TEKNIS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: appTheme.black900)),
          const SizedBox(height: 8),
          if (payment['transaction_status'] != null) ...[
            _buildRow('Status Transaksi', payment['transaction_status'].toString()),
            const SizedBox(height: 4),
          ],
          if (payment['payment_type'] != null) ...[
            _buildRow('Tipe Pembayaran', payment['payment_type'].toString()),
            const SizedBox(height: 4),
          ],
          if (payment['bank'] != null) ...[
            _buildRow('Bank', payment['bank'].toString().toUpperCase()),
            const SizedBox(height: 4),
          ],
          if (payment['va_number'] != null) ...[
            _buildRow('VA Number', payment['va_number'].toString()),
          ],
        ],

        const SizedBox(height: 24),
        _buildThankYouSection(),
      ],
    );
  }

  // ======================== SHARED UI ========================
  Widget _buildReceiptHeader() {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(40)),
          child: ClipOval(
            child: SvgPicture.asset('assets/images/logo_navya_hub.svg', width: 60, height: 60, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 12),
        Text('NAVYA HUB', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: appTheme.orange200)),
        const SizedBox(height: 8),
        Text(
          'Jl. WR Supratman No.248, Kesiman Kertalangu,\nKec. Denpasar Tim., Kota Denpasar, Bali 80237',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
        ),
        const SizedBox(height: 16),
        Container(height: 1, width: double.infinity, color: Colors.grey.shade300),
      ],
    );
  }

  Widget _headerSimple() {
    return Column(
      children: [
        Text('NAVYA HUB', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: appTheme.orange200)),
        const SizedBox(height: 6),
        Container(height: 1, color: Colors.grey.shade300),
      ],
    );
  }

  Widget _buildThankYouSection() {
    return Column(
      children: [
        Container(height: 1, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('TERIMA KASIH',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: appTheme.orange200)),
        const SizedBox(height: 8),
        Text('Atas kepercayaan Anda di Klinik Nesh Navya!',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: isTotal ? 14 : 12,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? appTheme.black900 : Colors.grey.shade700,
              )),
          Text(value,
              style: TextStyle(
                fontSize: isTotal ? 14 : 12,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? appTheme.orange200 : appTheme.black900,
              )),
        ],
      ),
    );
  }

  // ======================== ACTIONS ========================
  Future<void> _downloadPDF(BuildContext context) async {
    // Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(appTheme.orange200)),
              const SizedBox(height: 16),
              Text('Membuat PDF...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );

    try {
      final Uint8List bytes = await _withTimeout(
        type == ReceiptType.product
            ? PDFGenerator.generateReceiptPDF(purchaseData!, productsData!)
            : PDFGenerator.generateTreatmentReceiptPDF(bookingData!),
        const Duration(seconds: 30),
        onTimeoutMessage: 'PDF generation timeout',
      );

      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      if (dir == null) {
        throw Exception('Tidak dapat mengakses direktori penyimpanan');
      }

      final fileName = type == ReceiptType.product
          ? 'E-Receipt_PURC${purchaseData!['id_penjualan_produk']}.pdf'
          : 'E-Receipt_BOOK${bookingData!['id_booking_treatment']}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      if (Navigator.canPop(context)) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text('PDF tersimpan: ${file.path}')),
          ]),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Buka',
            textColor: Colors.white,
            onPressed: () async {
              try {
                await Printing.sharePdf(bytes: bytes, filename: fileName);
              } catch (_) {}
            },
          ),
        ),
      );
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text('Gagal mengunduh PDF: $e')),
          ]),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _sharePDF(BuildContext context) async {
    // Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(appTheme.orange200)),
              const SizedBox(height: 16),
              Text('Menyiapkan file...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );

    try {
      final Uint8List bytes = await _withTimeout(
        type == ReceiptType.product
            ? PDFGenerator.generateReceiptPDF(purchaseData!, productsData!)
            : PDFGenerator.generateTreatmentReceiptPDF(bookingData!),
        const Duration(seconds: 30),
        onTimeoutMessage: 'PDF generation timeout',
      );

      final temp = await getTemporaryDirectory();
      final fileName = type == ReceiptType.product
          ? 'E-Receipt_PURC${purchaseData!['id_penjualan_produk']}.pdf'
          : 'E-Receipt_BOOK${bookingData!['id_booking_treatment']}.pdf';
      final file = File('${temp.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      if (Navigator.canPop(context)) Navigator.pop(context);

      await Share.shareXFiles([XFile(file.path)],
          text: type == ReceiptType.product
              ? '📄 E-Receipt Klinik Nesh Navya\n'
                  '🏷️ Transaksi: #PURC${purchaseData!['id_penjualan_produk']}\n'
                  '💰 Total: Rp ${_formatMoney(purchaseData!['harga_akhir'])}\n'
                  '📅 ${_formatDateTime(purchaseData!['tanggal_pembelian'].toString())}'
              : '📄 E-Receipt Treatment\n'
                  '🏷️ Booking: #BOOK${bookingData!['id_booking_treatment']}\n'
                  '💰 Total: Rp ${_formatMoney(bookingData!['harga_akhir_treatment'])}\n'
                  '📅 ${_formatDateTime(bookingData!['created_at'].toString())}',
          subject: type == ReceiptType.product
              ? 'E-Receipt Klinik Nesh Navya - #PURC${purchaseData!['id_penjualan_produk']}'
              : 'E-Receipt Treatment - #BOOK${bookingData!['id_booking_treatment']}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.share, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text('E-Receipt siap dibagikan!', style: TextStyle(fontWeight: FontWeight.w500)),
          ]),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text('Gagal membagikan PDF: $e')),
          ]),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ======================== HELPERS ========================
  String _formatMoney(dynamic n) {
    final d = double.tryParse((n ?? '0').toString()) ?? 0;
    final s = d.toStringAsFixed(0);
    final buf = StringBuffer();
    int c = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      c++;
      if (c % 3 == 0 && i != 0) buf.write('.');
    }
    return buf.toString().split('').reversed.join();
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    const months = [
      'Januari','Februari','Maret','April','Mei','Juni',
      'Juli','Agustus','September','Oktober','November','Desember'
    ];
    final m = months[dt.month - 1];
    return '${dt.day} $m ${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// Helper timeout wrapper via PDFGenerator (agar tak bentrok import dart:async TimeoutException)
// TAMBAHKAN fungsi helper top-level di akhir file:
Future<Uint8List> _withTimeout(
  Future<Uint8List> future,
  Duration duration, {
  String onTimeoutMessage = 'Timeout',
}) async {
  bool completed = false;
  late Uint8List result;
  await Future.any([
    future.then((value) {
      completed = true;
      result = value;
    }),
    Future<void>.delayed(duration),
  ]);
  if (!completed) {
    throw Exception(onTimeoutMessage);
  }
  return result;
}