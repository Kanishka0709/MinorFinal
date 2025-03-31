import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/ngo_search_page.dart';
import 'pages/profile_page.dart';
import 'pages/login_page.dart';
import 'pages/volunteer_home_page.dart';
import 'pages/user_login_page.dart';
import 'pages/volunteer_login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const PashuRakshakApp());
}

class PashuRakshakApp extends StatelessWidget {
  const PashuRakshakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pashu Rakshak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Earthy color scheme
        primaryColor: const Color(0xFF8B7355), // Brown
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B7355),
          secondary: const Color(0xFF9B8B7A), // Light brown
          tertiary: const Color(0xFF6B8E23), // Olive green
          background: const Color(0xFFF5F5DC), // Beige
        ),
        useMaterial3: true,
      ),
      home: const RoleSelectionDialog(),
      routes: {
        '/user-login': (context) => const UserLoginPage(),
        '/volunteer-login': (context) => const VolunteerLoginPage(),
        '/user': (context) => const MainScreen(),
        '/volunteer': (context) => const VolunteerHomePage(),
      },
    );
  }
}

class RoleSelectionDialog extends StatelessWidget {
  const RoleSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Welcome to Pashu Rakshak',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Are you a User or a Volunteer?',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/user-login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text('User'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/volunteer-login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text('Volunteer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  UserData? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      if (userDataString != null) {
        setState(() {
          _userData = UserData.fromJson(jsonDecode(userDataString));
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(username: _userData?.name ?? 'User'),
      const NGOSearchPage(),
      ProfilePage(userData: _userData),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Find NGOs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}

// NGO Search Page
class NGOSearchPage extends StatelessWidget {
  const NGOSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find NGOs'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text('NGO Search Content'),
      ),
    );
  }
}
