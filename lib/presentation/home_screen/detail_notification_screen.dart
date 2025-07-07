// file: lib/models/notifikasi_model.dart

class NotifikasiModel {
  final int idNotifikasi;
  final int idUser;
  final String judul;
  final String pesan;
  final String jenis;
  final int? idReferensi;
  final String status;
  final String? gambar;
  final DateTime tanggalNotifikasi;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotifikasiModel({
    required this.idNotifikasi,
    required this.idUser,
    required this.judul,
    required this.pesan,
    required this.jenis,
    this.idReferensi,
    required this.status,
    this.gambar,
    required this.tanggalNotifikasi,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      idNotifikasi: json['id_notifikasi'],
      idUser: json['id_user'],
      judul: json['judul'],
      pesan: json['pesan'],
      jenis: json['jenis'],
      idReferensi: json['id_referensi'],
      status: json['status'],
      gambar: json['gambar'],
      tanggalNotifikasi: DateTime.parse(json['tanggal_notifikasi']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_notifikasi': idNotifikasi,
      'id_user': idUser,
      'judul': judul,
      'pesan': pesan,
      'jenis': jenis,
      'id_referensi': idReferensi,
      'status': status,
      'gambar': gambar,
      'tanggal_notifikasi': tanggalNotifikasi.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}