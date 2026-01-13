import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../services/postgres_service.dart';

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
      _serverIpController.text = prefs.getString('server_ip') ?? '';
      _dbNameController.text = prefs.getString('db_name') ?? '';
      _storeCodeController.text = prefs.getString('store_code') ?? '';
    });
  }

  
  bool _validateForm() {
    if (_serverIpController.text.trim().isEmpty ||
        _dbNameController.text.trim().isEmpty ||
        _storeCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Semua kolom harus diisi!'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _saveSettings() async {
    if (!_validateForm()) return; 

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', _serverIpController.text.trim());
    await prefs.setString('db_name', _dbNameController.text.trim());
    await prefs.setString('store_code', _storeCodeController.text.trim());

    await PostgresService.resetPool();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pengaturan tersimpan!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    
    final serverIp = _serverIpController.text.trim();
    final dbName = _dbNameController.text.trim();
    final storeCode = _storeCodeController.text.trim();

    
    String dbConnectionPassword = PostgresService.determinePassword(storeCode);

    debugPrint("--- DEBUG KONEKSI ---");
    debugPrint("IP: $serverIp");
    debugPrint(
      "Store Code Input: '$storeCode'",
    );
    debugPrint("Password yang dikirim: '$dbConnectionPassword'");
    
    try {
      final dbService = PostgresService(
        host: serverIp,
        databaseName: dbName,
        username: 'postgres', 
        password:
            dbConnectionPassword, 
      );

      await dbService.testConnection();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Koneksi Database Berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal: $e'), backgroundColor: Colors.red),
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
              color: AppColors.biru,
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
                    backgroundColor: AppColors.orange,
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
                    backgroundColor: AppColors.hijau,
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
    
    if (label.toLowerCase().contains('password')) {
      return const SizedBox.shrink();
    }
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
              Icon(icon, size: 20, color: AppColors.biru),
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
                borderSide: const BorderSide(color: AppColors.biru),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
