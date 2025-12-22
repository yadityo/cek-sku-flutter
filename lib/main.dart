import 'package:crypto/crypto.dart' show md5;
import 'dart:convert' as convert;
import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const SkuCheckerApp());
}

// --- Theme Constants ---
class AppColors {
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate400 = Color(0xFF94A3B8);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);

  static const blue50 = Color(0xFFEFF6FF);
  static const blue200 = Color(0xFFBFDBFE);
  static const blue700 = Color(0xFF1D4ED8);

  static const elzattaPurple = Color(0xFF6C3756);
  static const elzattaDarkPurple = Color(0xFF3C1053);
  static const green500 = Color(0xFF22C55E);
}

class SkuCheckerApp extends StatelessWidget {
  const SkuCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SKU Checker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.slate50,
        primaryColor: AppColors.elzattaPurple,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.elzattaPurple),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: const MainScreen(),
    );
  }
}

// --- Main Responsive Layout ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    SearchScreen(),
    ScanScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 768) {
          return _buildTabletLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: SafeArea(child: _screens[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.slate200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.elzattaPurple,
          unselectedItemColor: AppColors.slate400,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Cari'),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.blue50,
            selectedIconTheme: const IconThemeData(
              color: AppColors.elzattaPurple,
            ),
            unselectedIconTheme: const IconThemeData(color: AppColors.slate600),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.elzattaPurple,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: AppColors.slate600,
            ),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 24.0),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.elzattaPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    "SK",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.search),
                label: Text('Cari'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Scan'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Pengaturan'),
              ),
            ],
          ),
          const VerticalDivider(
            thickness: 1,
            width: 1,
            color: AppColors.slate200,
          ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}

// --- Screens ---

// 1. Search Screen
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _foundProduct;
  bool _isLoading = false;
  String _errorMessage = '';

  // String hashMD5(String input) {
  //   return md5.convert(convert.utf8.encode(input)).toString();
  // }

  Future<void> _performSearch() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _foundProduct = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final serverIp = prefs.getString('server_ip') ?? '192.168.1.100';
    final dbName = prefs.getString('db_name') ?? 'inventory_db';
    final storeCode = prefs.getString('store_code') ?? 'STORE-001';

    // PASSWORD LOGIC (hash with MD5)
    final passwordRaw = '$storeCode-password';
    // final password = hashMD5(passwordRaw);
    final password = passwordRaw;

    String baseUrl = serverIp;
    if (!baseUrl.startsWith('http')) {
      baseUrl = 'http://$baseUrl:3000';
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/search'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'keyword': keyword,
              'dbConfig': {
                'host':
                    'localhost', // FIX: Selalu gunakan localhost untuk koneksi DB internal server
                'database': dbName,
                'user': storeCode,
                'password': password,
              },
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' &&
            (result['data'] as List).isNotEmpty) {
          setState(() {
            _foundProduct = result['data'][0];
          });
        } else {
          setState(() {
            _errorMessage = 'Barang tidak ditemukan.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error Server: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Gagal koneksi. Pastikan Server Nyala & Dalam Jaringan Yang Sama.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 768;
    return isTablet ? _buildTabletView(context) : _buildMobileView(context);
  }

  Widget _buildMobileView(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          color: Colors.white,
          child: Column(
            children: [
              Image.asset(
                'images/elzatta-logo.png',
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
              const SizedBox(height: 16),
              _buildSearchBar(),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletView(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 320,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: AppColors.slate200)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset(
                        'images/elzatta-logo.png',
                        height: 36,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _buildContent(isTablet: true),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _performSearch(),
            // Menambahkan listener untuk update icon X secara real-time
            onChanged: (value) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: "Cari Barang/SKU...",
              prefixIcon: const Icon(Icons.search, color: AppColors.slate400),
              // TOMBOL X (Clear) di dalam ujung kanan Search Bar
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel, color: AppColors.slate400),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {}); // Refresh untuk menyembunyikan icon X
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.slate50,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: const BorderSide(color: AppColors.slate200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: const BorderSide(color: AppColors.slate200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: const BorderSide(
                  color: AppColors.elzattaPurple,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // TOMBOL CARI di sebelah kanan Search Bar
        ElevatedButton(
          onPressed: _isLoading ? null : _performSearch,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.elzattaPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Cari",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  Widget _buildContent({bool isTablet = false}) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage.isNotEmpty)
      return Center(
        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
      );
    if (_foundProduct == null)
      return Center(
        child: Text(
          "Silakan cari barang.",
          style: const TextStyle(color: AppColors.slate400),
        ),
      );

    return _buildProductCard(
      name: _foundProduct!['name'] ?? 'Unknown',
      sku: _foundProduct!['sku'] ?? '-',
      qty: _foundProduct!['quantity']?.toString() ?? '0',
      isTablet: isTablet,
    );
  }

  Widget _buildProductCard({
    required String name,
    required String sku,
    required String qty,
    bool isTablet = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: isTablet ? 128 : 96,
            height: isTablet ? 128 : 96,
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.checkroom,
              size: isTablet ? 64 : 48,
              color: AppColors.elzattaPurple,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "SKU: $sku",
              style: const TextStyle(
                color: AppColors.slate600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.elzattaDarkPurple, AppColors.elzattaPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.elzattaPurple.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "Stock Saat Ini",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      qty,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "unit",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 2. Scan Screen (Placeholder)

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String? _barcode;
  bool _isProcessing = false;
  Map<String, dynamic>? _foundProduct; // Menyimpan data produk hasil scan

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode != null && barcode != _barcode) {
      setState(() {
        _isProcessing = true;
        _barcode = barcode;
        _foundProduct = null;
      });

      // Ambil konfigurasi server dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final serverIp = prefs.getString('server_ip') ?? '192.168.1.100';
      final dbName = prefs.getString('db_name') ?? 'inventory_db';
      final storeCode = prefs.getString('store_code') ?? 'STORE-001';
      final passwordRaw = '$storeCode-password'; // Password asli
      final password = passwordRaw; // Tidak di-hash MD5, kirim string asli

      String baseUrl = serverIp;
      if (!baseUrl.startsWith('http')) {
        baseUrl = 'http://$baseUrl:3000';
      }

      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/api/search'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'keyword': barcode,
                'dbConfig': {
                  'host': 'localhost',
                  'database': dbName,
                  'user': storeCode,
                  'password': password,
                },
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['status'] == 'success' &&
              (result['data'] as List).isNotEmpty) {
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
                color: Colors.blueAccent.withOpacity(0.5),
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
                    Center(
                    child: Text(
                      _foundProduct?['name']?.toString() ?? '-',
                      style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
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
                        const Text(
                          "Stock Saat Ini",
                          style: TextStyle(color: Colors.white70),
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

// 3. Settings Screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Fungsi hash MD5
  // String hashMD5(String input) {
  //   return md5.convert(convert.utf8.encode(input)).toString();
  // }

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
          prefs.getString('server_ip') ?? '192.168.1.100';
      _dbNameController.text = prefs.getString('db_name') ?? 'inventory_db';
      _storeCodeController.text = prefs.getString('store_code') ?? 'STORE-001';
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

    // 1. Ambil konfigurasi
    final serverIp = _serverIpController.text.trim();
    final dbName = _dbNameController.text.trim();
    final storeCode = _storeCodeController.text.trim();
    final passwordFinal = 'password'; // FIX: Gunakan password statis

    // 2. Generate password
    final passwordRaw = storeCode + "-" + passwordFinal;
    // final password = hashMD5(passwordRaw);
    final password = passwordRaw;

    // 3. Format URL
    String baseUrl = serverIp;
    if (!baseUrl.startsWith('http')) {
      baseUrl = 'http://$baseUrl:3000';
    }

    try {
      // 4. Kirim request test
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/test-connection'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'host': 'localhost',
              'database': dbName,
              'user': storeCode,
              'password': password,
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
            content: Text('🌐 Koneksi gagal: ${e.toString()}'),
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
