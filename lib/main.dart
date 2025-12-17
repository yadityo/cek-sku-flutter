import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SkuCheckerApp());
}

// --- Theme Constants (Mirip dengan Tailwind Config) ---
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
  // static const elzattaPurple = Color(0xFF3B82F6);
  // static const elzattaPurple = Color(0xFF2563EB);
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
        fontFamily: 'Roboto', // Default flutter font, similar to sans
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
    // Menggunakan LayoutBuilder untuk menentukan Tablet vs Mobile
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

  // Layout Mobile (Bottom Navigation Bar)
  Widget _buildMobileLayout() {
    return Scaffold(
      body: SafeArea(child: _screens[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.slate200)),
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
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  // Layout Tablet (Navigation Rail di sebelah kiri)
  Widget _buildTabletLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.blue50,
            selectedIconTheme: const IconThemeData(color: AppColors.elzattaPurple),
            unselectedIconTheme: const IconThemeData(color: AppColors.slate600),
            selectedLabelTextStyle: const TextStyle(color: AppColors.elzattaPurple),
            unselectedLabelTextStyle: const TextStyle(color: AppColors.slate600),
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
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.search),
                label: Text('Search'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Scan'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1, color: AppColors.slate200),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}

// --- Screens ---

// 1. Search Screen
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 768;

    if (isTablet) {
      return _buildTabletView(context);
    }
    return _buildMobileView(context);
  }

  Widget _buildMobileView(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                Image.asset(
                'images/elzatta-logo.png',
                alignment: Alignment.center,
                height: 36,
                fit: BoxFit.contain,
                ),
              const SizedBox(height: 16),
              _buildSearchBar(),
            ],
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildProductCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletView(BuildContext context) {
    return Row(
      children: [
        // Left Panel (List/Search)
        Container(
          width: 320,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: AppColors.slate200),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "SKU Search",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.slate900),
                    ),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.slate100),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.access_time, size: 16, color: AppColors.slate50),
                        SizedBox(width: 8),
                        Text("Recent Searches", style: TextStyle(color: AppColors.slate700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRecentSearchItem("Premium Widget Pro", "WIDGET-2024", "2 min ago", true),
                    _buildRecentSearchItem("Smart Gadget Plus", "GADGET-5500", "15 min ago", false),
                    _buildRecentSearchItem("Professional Tool Set", "TOOL-8800", "1 hour ago", false),
                  ],
                ),
              )
            ],
          ),
        ),
        // Right Panel (Detail)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _buildProductCard(isTablet: true),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: "Cari Barang/SKU...",
        prefixIcon: const Icon(Icons.search, color: AppColors.slate400),
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
          borderSide: const BorderSide(color: AppColors.elzattaPurple, width: 2),
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(String name, String sku, String time, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.blue50 : AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.blue200 : Colors.transparent, 
          width: isActive ? 1 : 0
        ),
      ),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.slate900)),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(sku, style: const TextStyle(fontSize: 12, color: AppColors.slate600)),
            Text(time, style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
          ],
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildProductCard({bool isTablet = false}) {
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
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Icon
          Container(
            width: isTablet ? 128 : 96,
            height: isTablet ? 128 : 96,
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: isTablet ? 64 : 48,
              color: AppColors.elzattaPurple,
            ),
          ),
          const SizedBox(height: 24),
          // Title
          const Text(
            "Premium Widget Pro",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.slate900),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "SKU: WIDGET-2024",
              style: TextStyle(color: AppColors.slate600, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 24),
          // Stock Gradient Card
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
                )
              ],
            ),
            child: Column(
              children: [
                Text("Stock Saat Ini", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: const [
                    Text("342", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Text("unit", style: TextStyle(color: Colors.white, fontSize: 18)),
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

// 2. Scan Screen
class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera Viewfinder Background
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.slate800, AppColors.slate900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.qr_code_scanner, size: 64, color: Colors.white24),
              SizedBox(height: 16),
              Text("Camera Feed", style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
        
        // Scan Frame
        Center(
          child: Container(
            width: 300,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.elzattaPurple.withOpacity(0.8), width: 4),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                // Corner accents could be drawn with CustomPainter, keeping it simple here
                Center(
                  child: Container(
                    height: 2,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.elzattaPurple,
                      boxShadow: [
                        BoxShadow(color: AppColors.elzattaPurple, blurRadius: 10, spreadRadius: 1)
                      ]
                    ),
                  ),
                )
              ],
            ),
          ),
        ),

        // Instructions
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.slate800.withOpacity(0.9),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Text(
                "Posisikan kode QR di dalam bingkai untuk memindai",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),

        // Bottom Controls
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 3. Settings Screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For Tablet, create a centered modal-like look, for mobile full width
    final isTablet = MediaQuery.of(context).size.width > 768;

    Widget content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isTablet) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text("Pengaturan", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.slate900)),
            ),
          ],
          if (isTablet) ...[
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text("Pengaturan", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.slate900)),
                 IconButton(icon: const Icon(Icons.close, color: AppColors.slate50), onPressed: (){},)
               ],
             ),
             const SizedBox(height: 24),
          ],

          _buildSettingField("Server IP Address", Icons.dns, "192.168.1.100"),
          const SizedBox(height: 16),
          _buildSettingField("Nama Database", Icons.storage, "inventory_db"),
          const SizedBox(height: 16),
          _buildSettingField("Store Code", Icons.store, "STORE-001"),
          
          const SizedBox(height: 32),
          
            Row(
            children: [
              Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.network_check),
                label: const Text("Test Koneksi"),
                style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 158, 78, 125),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                ),
              ),
              ),
              const SizedBox(width: 16),

              Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.save),
                label: const Text("Simpan Konfigurasi"),
                style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.elzattaPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                ),
              ),
              ),
              
            ],
            ),
          
          const SizedBox(height: 16),
          const Center(
            child: Text(
              "Settings will be applied immediately after saving",
              style: TextStyle(color: AppColors.slate50, fontSize: 12),
            ),
          ),
        ],
      ),
    );

    if (isTablet) {
      return Center(
        child: Container(
          width: 600,
          height: 600,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.1 * 255).round()),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: content,
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: content,
      ),
    );
  }

  Widget _buildSettingField(String label, IconData icon, String initialValue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.elzattaPurple),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.slate700)),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: initialValue,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: AppColors.slate50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.slate200),
              ),
              enabledBorder: OutlineInputBorder(
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