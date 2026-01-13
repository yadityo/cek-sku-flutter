import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/postgres_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Cache service agar tidak connect ulang terus menerus
  PostgresService? _dbService;
  
  Map<String, dynamic>? _foundProduct;
  bool _isLoading = false;
  bool _hasSearched = false; // Untuk membedakan belum cari vs tidak ketemu
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  @override
  void dispose() {
    // 1. OPTIMASI: Wajib dispose controller untuk cegah memory leak
    _searchController.dispose();
    super.dispose();
  }

  // 2. OPTIMASI: Init DB di awal
  Future<void> _initDb() async {
    try {
      _dbService = await PostgresService.createFromPrefs();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal inisialisasi Database. Cek koneksi.";
        });
      }
    }
  }

  Future<void> _performSearch() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    // 3. OPTIMASI: Tutup keyboard saat mulai mencari
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _foundProduct = null;
      _hasSearched = true; 
    });

    try {
      // Pastikan service ada, jika null coba init lagi
      _dbService ??= await PostgresService.createFromPrefs();

      final result = await _dbService!.searchProduct(keyword);

      // 4. OPTIMASI: Cek mounted sebelum update UI setelah proses async
      if (!mounted) return;

      if (result != null) {
        setState(() {
          _foundProduct = result;
        });
      } else {
        // Kita tidak pakai dialog lagi agar UX lebih smooth,
        // status not found ditangani di _buildContent
        setState(() {
          _foundProduct = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal koneksi ke Database.\nError: ${e.toString().split('\n').first}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan LayoutBuilder lebih aman untuk responsivitas
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 768;
        return Scaffold(
           // Tambahkan background color agar konsisten
           backgroundColor: Colors.white,
           body: isTablet ? _buildTabletView(context) : _buildMobileView(context),
        );
      },
    );
  }

  Widget _buildMobileView(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16), // Top padding disesuaikan safe area
          color: AppColors.biruMudaAbu,
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    'images/bestock-logo.png',
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => const Icon(Icons.inventory, color: AppColors.biru),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'beStock',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.biru,
                    ),
                  ),
                ],
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
            border: Border(right: BorderSide(color: AppColors.biruMudaAbu)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'images/bestock-logo.png',
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.inventory, color: AppColors.biru),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'beStock',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.biru,
                          ),
                        ),
                      ],
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
          child: Container(
            color: Colors.grey.shade50, // Background sedikit abu untuk tablet content area
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
            textInputAction: TextInputAction.search, // Keyboard enter icon jadi search
            onSubmitted: (_) => _performSearch(),
            onChanged: (value) {
               // Optional: Rebuild UI untuk show/hide clear button
               setState(() {}); 
            },
            decoration: InputDecoration(
              hintText: "Cari Barang/SKU...",
              prefixIcon: const Icon(Icons.search, color: AppColors.slate400),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel, color: AppColors.slate400),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _hasSearched = false;
                          _foundProduct = null;
                          _errorMessage = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
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
                borderSide: const BorderSide(color: AppColors.biru, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isLoading ? null : _performSearch,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.biru,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            elevation: 0,
          ),
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("Cari", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildContent({bool isTablet = false}) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage, 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
             const SizedBox(height: 16),
             ElevatedButton(
               onPressed: _initDb, // Coba connect ulang
               child: const Text("Coba Koneksi Ulang"),
             )
          ],
        ),
      );
    }

    // Kondisi 1: Belum pernah mencari
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 80, color: AppColors.slate200),
            const SizedBox(height: 16),
            const Text(
              "Silakan masukkan SKU atau Nama Barang\nuntuk memulai pencarian.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate400),
            ),
          ],
        ),
      );
    }

    // Kondisi 2: Sudah cari, tapi hasil null (Tidak Ditemukan)
    // 5. OPTIMASI UX: Ganti Dialog dengan tampilan in-body
    if (_foundProduct == null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 60, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                "Data Tidak Ditemukan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade800),
              ),
              const SizedBox(height: 8),
              Text(
                "Barang '${_searchController.text}' tidak ada di database.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Kondisi 3: Barang Ditemukan
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
              color: AppColors.biru,
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
              color: AppColors.biru,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.biru.withOpacity(0.3),
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