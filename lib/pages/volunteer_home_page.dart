import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'volunteer_profile_page.dart';
import 'volunteer_rescues_page.dart';

class VolunteerHomePage extends StatefulWidget {
  const VolunteerHomePage({super.key});

  @override
  State<VolunteerHomePage> createState() => _VolunteerHomePageState();
}

class _VolunteerHomePageState extends State<VolunteerHomePage> {
  String _username = '';
  int _livesSaved = 0;
  String _currentAddress = '';
  bool _requestAccepted = false;
  bool _arrivedAtLocation = false;
  bool _rescuedCured = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('userName') ?? '';
      _livesSaved = prefs.getInt('livesSaved') ?? 0;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _updateRescueStatus(String status) {
    setState(() {
      switch (status) {
        case 'request':
          _requestAccepted = !_requestAccepted;
          if (!_requestAccepted) {
            _arrivedAtLocation = false;
            _rescuedCured = false;
          }
          break;
        case 'arrived':
          if (_requestAccepted) {
            _arrivedAtLocation = !_arrivedAtLocation;
            if (!_arrivedAtLocation) {
              _rescuedCured = false;
            }
          }
          break;
        case 'rescued':
          if (_arrivedAtLocation) {
            _rescuedCured = !_rescuedCured;
            if (_rescuedCured) {
              _incrementLivesSaved();
            }
          }
          break;
      }
    });
  }

  Future<void> _incrementLivesSaved() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _livesSaved++;
      prefs.setInt('livesSaved', _livesSaved);
    });
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Text(
            'PASHU RAKSHAK!!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B7355),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'HELP . HEAL . HOPE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rescue Tracking',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _requestAccepted,
                    onChanged: (_) => _updateRescueStatus('request'),
                    title: const Text(
                      'Request Accepted',
                      style: TextStyle(fontSize: 16),
                    ),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  CheckboxListTile(
                    value: _arrivedAtLocation,
                    onChanged: _requestAccepted ? (_) => _updateRescueStatus('arrived') : null,
                    title: const Text(
                      'Arrived at the location',
                      style: TextStyle(fontSize: 16),
                    ),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  CheckboxListTile(
                    value: _rescuedCured,
                    onChanged: _arrivedAtLocation ? (_) => _updateRescueStatus('rescued') : null,
                    title: const Text(
                      'Rescued / Cured',
                      style: TextStyle(fontSize: 16),
                    ),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'ADDRESS',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      setState(() {
                        _currentAddress = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Impact',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'NO. OF LIVES SAVED BY YOU: $_livesSaved',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildMainContent(),
      const VolunteerRescuesPage(),
      const VolunteerProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pashu Rakshak'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              // TODO: Implement language selection
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Rescues',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
} 