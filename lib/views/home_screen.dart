import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../view_models/card_scanner_viewmodel.dart';
import '../view_models/passbook_scanner_viewmodel.dart';
import 'card_scanner_screen.dart';
import 'passbook_scanner_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;

  final List<Widget> _screens = [
    const CardScannerScreen(),
    const PassbookScannerScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadTabState();
  }

  Future<void> _loadTabState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedIndex = prefs.getInt('last_tab') ?? 0;
        _isInitialized = true;
      });
    }
  }

  Future<void> _saveTabState(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_tab', index);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _saveTabState(index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Card Scanner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Passbook Scanner',
          ),
        ],
      ),
    );
  }
}
