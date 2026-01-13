import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'search_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens =  [
    SearchScreen(),
    ScanScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
          backgroundColor: AppColors.biruMudaAbu,
          selectedItemColor: AppColors.biru,
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
            backgroundColor: AppColors.biruMudaAbu,
            indicatorColor: AppColors.blue50,
            selectedIconTheme: const IconThemeData(
              color: AppColors.biru,
            ),
            unselectedIconTheme: const IconThemeData(color: AppColors.slate600),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.biru,
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
                  color: AppColors.biru,
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