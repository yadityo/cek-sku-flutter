import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/app_colors.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String? _barcode;
  bool _isProcessing = false;
  Map<String, dynamic>? _foundProduct; // Menyimpan data produk hasil scan

  DateTime? _lastScanTime;
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    final now = DateTime.now();
    if (barcode != null && barcode != _barcode) {
      // Debounce: minimal 1.5 detik antar scan
      if (_lastScanTime != null && now.difference(_lastScanTime!) < const Duration(milliseconds: 1500)) return;
      _lastScanTime = now;
      setState(() {
        _isProcessing = true;
        _barcode = barcode;
        _foundProduct = null;
      });
      final prefs = await SharedPreferences.getInstance();
      final serverIp = prefs.getString('server_ip') ?? '192.168.1.100';
      final storeCode = prefs.getString('store_code') ?? 'STORE-001';
      String baseUrl = serverIp;
      if (!baseUrl.startsWith('http')) {
        baseUrl = 'http://$baseUrl:3000';
      }
      try {
        final response = await ApiService.postRequest(
          baseUrl: baseUrl,
          endpoint: '/api/search',
          body: {
            'keyword': barcode,
            'user': storeCode,
          },
        );
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['status'] == 'success' && (result['data'] as List).isNotEmpty) {
            setState(() {
              _foundProduct = result['data'][0];
            });
          } else {
            setState(() {
              _foundProduct = {
                'name': 'Barang tidak ditemukan',
                'sku': barcode,
                'quantity': 0,
              };
            });
          }
        } else {
          setState(() {
            _foundProduct = {
              'name': 'Error Server: ${response.statusCode}',
              'sku': barcode,
              'quantity': 0,
            };
          });
        }
      } catch (e) {
        setState(() {
          _foundProduct = {
            'name': 'Gagal koneksi ke server',
            'sku': barcode,
            'quantity': 0,
          };
        });
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isTablet = constraints.maxWidth > 768;
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A), // Dark Background
          body: isTablet ? _buildTabletView() : _buildMobileView(),
        );
      },
    );
  }

  // --- VIEW MOBILE ---
  Widget _buildMobileView() {
    return Stack(
      children: [
        MobileScanner(onDetect: _onDetect, fit: BoxFit.cover),
        _buildScannerOverlay(label: "Posisikan barcode didalam frame"),
        if (_foundProduct != null) _buildBottomSheetMobile(),
      ],
    );
  }

  // --- VIEW TABLET (LANDSCAPE) ---
  Widget _buildTabletView() {
    return Row(
      children: [
        // Sisi Kiri: Scanner
        Expanded(
          flex: 6,
          child: Stack(
            children: [
              MobileScanner(onDetect: _onDetect, fit: BoxFit.cover),
              _buildScannerOverlay(label: "Posisikan barcode di dalam frame"),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.fullscreen_exit,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),
        ),
        // Sisi Kanan: Detail Info
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(32),
            child: _foundProduct == null
                ? const Center(child: Text("Menunggu pemindaian..."))
                : _buildProductDetailPanel(),
          ),
        ),
      ],
    );
  }

  // --- REUSABLE COMPONENTS ---

  Widget _buildScannerOverlay({required String label}) {
    return Stack(
      children: [
        // Dim Background (Lubang di tengah)
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.srcOver,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
        ),
        // Text Hint
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        // Scanner Frame (Blue border corners)
        Center(
          child: Container(
            width: 280,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color.fromARGB(127, 33, 150, 243),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                _buildCorner(0, 0, top: true, left: true),
                _buildCorner(0, 0, top: true, left: false),
                _buildCorner(0, 0, top: false, left: true),
                _buildCorner(0, 0, top: false, left: false),
                // Scanning Line Effect
                const Center(
                  child: Divider(color: Colors.blueAccent, thickness: 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(
    double dist,
    double size, {
    required bool top,
    required bool left,
  }) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? const BorderSide(color: Colors.white, width: 6)
                : BorderSide.none,
            bottom: !top
                ? const BorderSide(color: Colors.white, width: 6)
                : BorderSide.none,
            left: left
                ? const BorderSide(color: Colors.white, width: 6)
                : BorderSide.none,
            right: !left
                ? const BorderSide(color: Colors.white, width: 6)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(15) : Radius.zero,
            topRight: top && !left ? const Radius.circular(15) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(15) : Radius.zero,
            bottomRight: !top && !left
                ? const Radius.circular(15)
                : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildProductDetailPanel() {
    return Stack(
      children: [
        // Main content
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Scan Berhasil",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Item ditemukan di database",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            // Product Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                  ),
                ],
                border: Border.all(color: AppColors.slate100),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.checkroom,
                      color: AppColors.elzattaPurple,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _foundProduct?['name']?.toString() ?? '-',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "SKU: ${_foundProduct?['sku']?.toString() ?? '-'}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  // Stock Badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.elzattaDarkPurple,
                          AppColors.elzattaPurple,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Stock Saat Ini",
                          style: TextStyle(color: Color.fromARGB(179, 255, 255, 255)),
                        ),
                        Text(
                          "${_foundProduct?['quantity']?.toString() ?? '0'} unit",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Close button
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.close, color: AppColors.slate400),
            onPressed: () {
              setState(() {
                _foundProduct = null;
                _barcode =
                    null; // Sembunyikan panel dengan menghapus data produk & barcode
              });
            },
            tooltip: 'Tutup',
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheetMobile() {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: _buildProductDetailPanel(),
        ),
      ),
    );
  }
}