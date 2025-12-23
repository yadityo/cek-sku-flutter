import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final _serverIpController = TextEditingController();
  final _dbNameController = TextEditingController();
  final _storeCodeController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverIpController.text =
          prefs.getString('server_ip') ?? '10.1.10.100';
      _dbNameController.text = prefs.getString('db_name') ?? 'stok_db';
      _storeCodeController.text = prefs.getString('store_code') ?? 'ZJ09';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', _serverIpController.text);
    await prefs.setString('db_name', _dbNameController.text);
    await prefs.setString('store_code', _storeCodeController.text);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pengaturan tersimpan!')));
    }
  }

  // FUNGSI UTAMA KONEKSI KE SERVER
  Future<void> _testConnection() async {
    setState(() => _isLoading = true);

    // 1. Ambil input dari TextField
    final serverIp = _serverIpController.text
        .trim(); // IP Laptop (misal: 192.168.1.10)
    final dbName = _dbNameController.text.trim();
    final storeCode = _storeCodeController.text.trim();

    // 2. Format Password sesuai format 'password@toko'
    // Pastikan ini SAMA PERSIS dengan isi kolom "Password" di tabel msStoreInfo database
    final passwordToSend = '5f4dcc3b5aa765d61d8327deb882cf99@$storeCode';

    // 3. Siapkan Base URL untuk menghubungi Node.js
    String baseUrl = serverIp;
    if (!baseUrl.startsWith('http')) {
      baseUrl = 'http://$baseUrl:3000'; // Port 3000 sesuai index.js
    }

    try {
      // 4. Kirim Request
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/test-connection'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              // PENTING: 'host' di sini adalah host database DARI SUDUT PANDANG SERVER.
              // Karena Node.js dan Postgres ada di komputer yang sama, gunakan 'localhost'
              'host': 'localhost',
              'database': dbName,
              'user': storeCode,
              'password': passwordToSend,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final result = jsonDecode(response.body);

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result['message']}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Menampilkan pesan error dari server (misal: Store Code salah)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🌐 Gagal terhubung ke Server API: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 768;
    Widget content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Pengaturan Server",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 24),

          _buildSettingField(
            "Server IP Address",
            Icons.dns,
            _serverIpController,
          ),
          const SizedBox(height: 16),

          _buildSettingField("Nama Database", Icons.storage, _dbNameController),
          const SizedBox(height: 16),

          _buildSettingField("Store Code", Icons.store, _storeCodeController),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testConnection,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.network_check),
                  label: const Text("Test Koneksi"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 158, 78, 125),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text("Simpan"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.elzattaPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return isTablet
        ? Center(
            child: Container(
              width: 600,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 20),
                ],
              ),
              child: content,
            ),
          )
        : SafeArea(child: SingleChildScrollView(child: content));
  }

  Widget _buildSettingField(
    String label,
    IconData icon,
    TextEditingController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.elzattaPurple),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.slate50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.slate200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.elzattaPurple),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
