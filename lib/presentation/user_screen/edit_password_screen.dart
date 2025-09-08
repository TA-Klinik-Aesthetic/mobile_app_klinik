import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_constant.dart';
import '../../theme/theme_helper.dart';
import 'package:http/http.dart' as http;

class EditPasswordScreen extends StatefulWidget {
  const EditPasswordScreen({super.key});

  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<int?> _resolveUserId(SharedPreferences prefs) async {
    // Coba beberapa key umum
    final int? byInt = prefs.getInt('id_user') ?? prefs.getInt('user_id') ?? prefs.getInt('id');
    if (byInt != null) return byInt;

    final String? byStr = prefs.getString('id_user') ?? prefs.getString('user_id') ?? prefs.getString('id');
    if (byStr != null) {
      final parsed = int.tryParse(byStr);
      if (parsed != null) return parsed;
    }

    // Coba JSON 'user'
    final String? userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        final m = jsonDecode(userJson);
        final raw = m['id_user'] ?? m['user_id'] ?? m['id'];
        if (raw is int) return raw;
        return int.tryParse(raw?.toString() ?? '');
      } catch (_) {}
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        _showError('Sesi berakhir. Silakan login kembali.');
        if (mounted) Navigator.pop(context, false);
        return;
      }

      final userId = await _resolveUserId(prefs);
      if (userId == null) {
        _showError('ID pengguna tidak ditemukan.');
        return;
      }

      final url = ApiConstants.updateUserPassword.replaceAll('{id_user}', userId.toString());
      if (kDebugMode) {
        print('PUT $url');
        print('Body: ${_passwordController.text.replaceAll(RegExp("."), "*")} / ${_confirmController.text.replaceAll(RegExp("."), "*")}');
      }

      final resp = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'password': _passwordController.text.trim(),
          'password_confirmation': _confirmController.text.trim(),
        }),
      );

      if (kDebugMode) {
        print('Status: ${resp.statusCode}');
        print('Body: ${resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body}');
      }

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final success = data['success'] == true;
        final message = data['message']?.toString() ?? 'Password berhasil diubah';
        _showSuccess(message);
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) Navigator.pop(context, success);
      } else {
        try {
          final err = jsonDecode(resp.body);
          _showError(err['message']?.toString() ?? 'Gagal mengubah password');
        } catch (_) {
          _showError('Gagal mengubah password (${resp.statusCode})');
        }
      }
    } catch (e) {
      _showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: appTheme.darkCherry,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: appTheme.lightGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  InputDecoration _decoration(String hint, {required bool obscure, required VoidCallback onToggle}) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: appTheme.orange200, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade500),
        onPressed: onToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ubah Kata Sandi',
          style: TextStyle(
            color: appTheme.black900,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Password Baru', style: TextStyle(fontWeight: FontWeight.w600, color: appTheme.black900)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure1,
                decoration: _decoration('Masukkan password baru', obscure: _obscure1, onToggle: () {
                  setState(() => _obscure1 = !_obscure1);
                }),
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Password tidak boleh kosong';
                  if (val.length < 8) return 'Minimal 8 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('Konfirmasi Password Baru', style: TextStyle(fontWeight: FontWeight.w600, color: appTheme.black900)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscure2,
                decoration: _decoration('Ulangi password baru', obscure: _obscure2, onToggle: () {
                  setState(() => _obscure2 = !_obscure2);
                }),
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                  if (val != _passwordController.text.trim()) return 'Password tidak sama';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.orange200,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Memproses...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        )
                      : const Text(
                          'UBAH KATA SANDI',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}