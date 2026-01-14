import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// Pastikan path import ini sesuai dengan struktur project Anda
import '../constants/app_colors.dart';
import '../services/postgres_service.dart';

// Enum untuk mengelola status scan dengan lebih rapi
enum ScanStatus { scanning, processing, found, notFound, error }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  // Optimasi: detectionSpeed.noDuplicates mencegah scan berulang super cepat
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  ScanStatus _scanStatus = ScanStatus.scanning;
  bool _torchOn = false;
  String? _barcode;
  Map<String, dynamic>? _foundProduct;
  String? _errorMessage;
  
  // Cache service database
  PostgresService? _dbService;

  @override
  void initState() {
    super.initState();
    _initDbService();
  }

  @override
  void dispose() {
    // OPTIMASI KRUSIAL: Dispose controller saat keluar halaman
    _scannerController.dispose();
    super.dispose();
  }

  // Inisialisasi DB sekali di awal
  Future<void> _initDbService() async {
    try {
      _dbService = await PostgresService.createFromPrefs();
    } catch (e) {
      // Jangan set error state UI dulu, biarkan user mencoba scan
      debugPrint("Info: DB belum siap di init awal, akan dicoba saat scan. Error: $e");
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    // Jika sedang loading atau sudah ada hasil, abaikan input kamera
    if (_scanStatus != ScanStatus.scanning) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;

    setState(() {
      _scanStatus = ScanStatus.processing;
      _barcode = barcode;
    });

    try {
      // Pastikan service ready, jika null coba buat lagi
      _dbService ??= await PostgresService.createFromPrefs();

      final result = await _dbService!.searchProduct(barcode);

      // OPTIMASI: Cek mounted untuk mencegah error "setState called after dispose"
      if (!mounted) return;

      if (result.isNotEmpty) {
        setState(() {
          _foundProduct = result.first;
          _scanStatus = ScanStatus.found;
        });
      } else {
        setState(() {
          _foundProduct = null;
          _scanStatus = ScanStatus.notFound;
        });
      }
      
      // OPTIMASI: Stop kamera saat menampilkan hasil untuk hemat baterai & CPU
      await _scannerController.stop();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanStatus = ScanStatus.error;
        _errorMessage = 'Gagal memproses: ${e.toString().split('\n').first}';
      });
      // Stop kamera juga jika error agar user bisa baca errornya
      await _scannerController.stop();
    }
  }

  // Fungsi untuk me-reset kondisi agar bisa scan lagi
  void _resetScan() {
    setState(() {
      _scanStatus = ScanStatus.scanning;
      _foundProduct = null;
      _barcode = null;
      _errorMessage = null;
    });
    // Nyalakan kamera lagi
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isTablet = constraints.maxWidth > 768;
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: isTablet ? _buildTabletView() : _buildMobileView(),
        );
      },
    );
  }

  // --- TAMPILAN MOBILE ---
  Widget _buildMobileView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
          fit: BoxFit.cover,
        ),
        _buildScannerOverlay(label: "Posisikan barcode di dalam frame"),
        
        // Tombol Flashlight
        Positioned(
          bottom: 70,
          right: 0,
          left: 0,
          child: Center(child: _buildTorchButton(isTablet: false)),
        ),

        // Tampilkan Bottom Sheet jika status BUKAN scanning (artinya ada hasil/error)
        if (_scanStatus != ScanStatus.scanning && _scanStatus != ScanStatus.processing)
          _buildBottomSheetMobile(),
          
        // Loading Indicator Overlay jika sedang processing
        if (_scanStatus == ScanStatus.processing)
          Container(
            color: Colors.black45,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }

  // --- TAMPILAN TABLET ---
  Widget _buildTabletView() {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
                fit: BoxFit.cover,
              ),
              _buildScannerOverlay(label: "Posisikan barcode di dalam frame"),
              
              // Controls (Exit & Flash)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 32),
                          onPressed: _resetScan, // Reset saat exit full screen scan
                          tooltip: 'Reset / Exit',
                        ),
                      ),
                      const SizedBox(width: 190),
                      _buildTorchButton(isTablet: true),
                    ],
                  ),
                ),
              ),
              
              if (_scanStatus == ScanStatus.processing)
                Container(
                  color: Colors.black45,
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(32),
            child: _decidePanelContent(),
          ),
        ),
      ],
    );
  }

  // --- KOMPONEN UI ---

  Widget _buildTorchButton({required bool isTablet}) {
    return Container(
      width: isTablet ? null : 72,
      height: isTablet ? null : 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isTablet ? Colors.white.withOpacity(0.2) : AppColors.biru,
      ),
      child: IconButton(
        icon: Icon(
          _torchOn ? Icons.flash_on : Icons.flash_off,
          color: Colors.white,
          size: 32,
        ),
        tooltip: 'Flashlight',
        onPressed: () async {
          await _scannerController.toggleTorch();
          setState(() {
            _torchOn = !_torchOn;
          });
        },
      ),
    );
  }

  Widget _buildBottomSheetMobile() {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
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
          child: _decidePanelContent(),
        ),
      ),
    );
  }

  // Logika Pemilihan Konten Panel
  Widget _decidePanelContent() {
    switch (_scanStatus) {
      case ScanStatus.processing:
        return const Center(child: Text("Sedang memproses..."));
      case ScanStatus.found:
        return _buildProductDetailPanel();
      case ScanStatus.notFound:
        return _buildNotFoundPanel();
      case ScanStatus.error:
        return _buildErrorPanel();
      case ScanStatus.scanning:
      default:
        return const Center(child: Text("Menunggu pemindaian..."));
    }
  }

  // --- PANEL: BARANG DITEMUKAN (BLUE) ---
  Widget _buildProductDetailPanel() {
    return Stack(
      children: [
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
                      color: AppColors.biru,
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
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "SKU: ${_foundProduct?['sku']?.toString() ?? '-'}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.biru,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Stock Saat Ini",
                          style: TextStyle(
                            color: Color.fromARGB(179, 255, 255, 255),
                          ),
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
            const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _resetScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.biru,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text("Scan Ulang"),
                    ),
                  ),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.close, color: AppColors.slate400),
            onPressed: _resetScan,
            tooltip: 'Tutup',
          ),
        ),
      ],
    );
  }

  // --- PANEL: TIDAK DITEMUKAN (RED) ---
  Widget _buildNotFoundPanel() {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Hasil Scan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Data tidak ditemukan di database",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
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
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      color: Colors.red.shade400,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Produk Tidak Terdaftar",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "SKU: ${_barcode ?? '-'}",
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _resetScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text("Scan Ulang"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: _resetScan,
            tooltip: 'Tutup',
          ),
        ),
      ],
    );
  }

  // --- PANEL: ERROR ---
  Widget _buildErrorPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.orange),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? "Terjadi kesalahan",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _resetScan,
          child: const Text("Coba Lagi"),
        )
      ],
    );
  }

  // --- OVERLAY & DEKORASI ---

  Widget _buildScannerOverlay({required String label}) {
    return Stack(
      children: [
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
}