import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PDFGenerator {
  static Future<Uint8List> generateReceiptPDF(
    Map<String, dynamic> purchaseData,
    Map<int, Map<String, dynamic>> productsData,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Container(
                      width: 80,
                      height: 80,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange200,
                        borderRadius: pw.BorderRadius.circular(40),
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'NAVYA HUB',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Jl. WR Supratman No.248, Kesiman Kertalangu,\nKec. Denpasar Tim., Kota Denpasar, Bali 80237',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 32),
              pw.Divider(),
              pw.SizedBox(height: 16),
              
              // Transaction Details
              pw.Text(
                'TRANSAKSI',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              
              _buildPDFRow('ID Transaksi', '#PURC${purchaseData['id_penjualan_produk']}'),
              _buildPDFRow('Tanggal', _formatDate(purchaseData['tanggal_pembelian'])),
              
              pw.SizedBox(height: 16),
              
              // Products
              if (purchaseData['detail_pembelian'] != null) ...[
                pw.Text(
                  'Produk yang Dibeli:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                ...purchaseData['detail_pembelian'].map<pw.Widget>((item) {
                  final int? productId = int.tryParse(item['id_produk'].toString());
                  final productData = productId != null ? productsData[productId] : null;
                  final productName = productData?['nama_produk'] ?? 'Produk #${item['id_produk']}';
                  final quantity = item['jumlah_produk'];
                  final price = _formatPrice(item['harga_penjualan_produk']);
                  
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('$productName (${quantity}x)'),
                      pw.Text('Rp $price'),
                    ],
                  );
                }).toList(),
              ],
              
              pw.SizedBox(height: 24),
              
              // Payment Details
              pw.Text(
                'DETAIL PEMBAYARAN',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              
              if (purchaseData['pembayaran_produk']?['waktu_pembayaran'] != null)
                _buildPDFRow('Waktu Pembayaran', _formatDate(purchaseData['pembayaran_produk']['waktu_pembayaran'])),
              
              _buildPDFRow('Subtotal', 'Rp ${_formatPrice(purchaseData['harga_total'])}'),
              
              if (purchaseData['potongan_harga'] != null && purchaseData['potongan_harga'] != '0.00')
                _buildPDFRow('Potongan', '- Rp ${_formatPrice(purchaseData['potongan_harga'])}'),
              
              if (purchaseData['besaran_pajak'] != null)
                _buildPDFRow('Pajak (10%)', 'Rp ${_formatPrice(purchaseData['besaran_pajak'])}'),
              
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Pembayaran',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Rp ${_formatPrice(purchaseData['harga_akhir'])}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.orange),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 16),
              
              if (purchaseData['pembayaran_produk'] != null) ...[
                _buildPDFRow('Metode Pembayaran', purchaseData['pembayaran_produk']['metode_pembayaran'] ?? '-'),
                if (purchaseData['pembayaran_produk']['transaction_status'] != null)
                  _buildPDFRow('Status Transaksi', purchaseData['pembayaran_produk']['transaction_status']),
                if (purchaseData['pembayaran_produk']['payment_type'] != null)
                  _buildPDFRow('Tipe Pembayaran', purchaseData['pembayaran_produk']['payment_type']),
                if (purchaseData['pembayaran_produk']['bank'] != null)
                  _buildPDFRow('Bank', purchaseData['pembayaran_produk']['bank']),
                if (purchaseData['pembayaran_produk']['va_number'] != null)
                  _buildPDFRow('VA Number', purchaseData['pembayaran_produk']['va_number']),
              ],
              
              pw.Spacer(),
              
              // Thank you
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Divider(),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      'TERIMA KASIH',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Atas kepercayaan Anda berbelanja di Navya Hub',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateTreatmentReceiptPDF(Map<String, dynamic> booking) async {
    final pdf = pw.Document();
    final List details = (booking['detail_booking'] as List?) ?? [];
    String fmtMoney(dynamic n) {
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

    String fmtDateTime(String? iso) {
      if (iso == null || iso.isEmpty) return '-';
      final dt = DateTime.parse(iso);
      const months = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
      final m = months[dt.month - 1];
      return '${dt.day} $m ${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }

    final pay = booking['pembayaran_treatment'] as Map<String, dynamic>?;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Center(child: pw.Text('NAVYA HUB', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 12),

          pw.Text('E-Receipt Treatment', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('ID Booking: #BOOK${booking['id_booking_treatment']}'),
              pw.Text('Tanggal: ${fmtDateTime(booking['created_at'])}'),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text('Jadwal Treatment: ${fmtDateTime(booking['waktu_treatment'])}'),

          if (pay != null) ...[
            pw.SizedBox(height: 8),
            pw.Text('Metode Pembayaran: ${pay['metode_pembayaran'] ?? '-'}'),
            if (pay['waktu_pembayaran'] != null) pw.Text('Waktu Pembayaran: ${fmtDateTime(pay['waktu_pembayaran'])}'),
          ],

          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text('Rincian Treatment', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          ...details.map<pw.Widget>((it) {
            final tr = it['treatment'] ?? {};
            final name = (tr['nama_treatment'] ?? '-').toString();
            final price = it['biaya_treatment'];
            return pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: pw.Text(name)),
                pw.Text('Rp ${fmtMoney(price)}'),
              ],
            );
          }).toList(),

          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Subtotal'),
              pw.Text('Rp ${fmtMoney(booking['harga_total'])}'),
            ],
          ),
          if (booking['id_promo'] != null) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Potongan'),
                pw.Text('- Rp ${fmtMoney(booking['potongan_harga'])}'),
              ],
            ),
          ],
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Pajak (10%)'),
              pw.Text('Rp ${fmtMoney(booking['besaran_pajak'])}'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Pembayaran', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Rp ${fmtMoney(booking['harga_akhir_treatment'])}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),

          pw.SizedBox(height: 24),
          pw.Center(child: pw.Text('Terima kasih atas kepercayaan Anda!')),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPDFRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value),
        ],
      ),
    );
  }

  static String _formatPrice(dynamic price) {
    if (price == null) return '0';
    double priceDouble;
    if (price is int) {
      priceDouble = price.toDouble();
    } else if (price is String) {
      priceDouble = double.tryParse(price) ?? 0.0;
    } else if (price is double) {
      priceDouble = price;
    } else {
      return '0';
    }

    final String priceString = priceDouble.toStringAsFixed(0);
    final StringBuffer formattedPrice = StringBuffer();
    int count = 0;
    for (int i = priceString.length - 1; i >= 0; i--) {
      formattedPrice.write(priceString[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        formattedPrice.write('.');
      }
    }
    return formattedPrice.toString().split('').reversed.join('');
  }

  static String _formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    const List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final monthName = months[dateTime.month - 1];
    return '${dateTime.day} $monthName ${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}