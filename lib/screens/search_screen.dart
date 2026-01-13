import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../services/postgres_service.dart'; 

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

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 768;
    return isTablet ? _buildTabletView(context) : _buildMobileView(context);
  }

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
    
    
    
    final dbPassword = 'password'; 

    try {
      
      final dbService = PostgresService(
        host: serverIp,
        databaseName: dbName,
        username: 'postgres', 
        password: dbPassword,
      );

      
      final result = await dbService.searchProduct(keyword);

      if (result != null) {
        setState(() {
          _foundProduct = result;
        });
      } else {
        _showNotFoundDialog();
      }
    } catch (e) {
      
      _showErrorDialog('Gagal koneksi ke Database.\nError: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showNotFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Tidak Ditemukan'),
        content: const Text('Barang tidak ditemukan di database.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    setState(() {
      _errorMessage = '';
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terjadi Kesalahan'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    setState(() {
      _errorMessage = '';
    });
  }

  
  
  Widget _buildMobileView(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          color: AppColors.biruMudaAbu,
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    'images/bestock-logo.png',
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'images/bestock-logo.png',
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(),
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
            onChanged: (value) {
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
                        setState(() {});
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
                borderSide: const BorderSide(
                  color: AppColors.biru,
                  width: 2,
                ),
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0,
          ),
          child: const Text(
            "Cari",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildContent({bool isTablet = false}) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          height: 500,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_foundProduct == null) {
      return const Center(
        child: Text(
          "Silakan cari barang.",
          style: TextStyle(color: AppColors.slate400),
        ),
      );
    }

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