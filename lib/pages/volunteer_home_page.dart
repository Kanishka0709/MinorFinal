import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:ui';  // Add this import for ImageFilter
import 'volunteer_profile_page.dart';
import 'volunteer_rescues_page.dart';

class VolunteerHomePage extends StatefulWidget {
  const VolunteerHomePage({super.key});

  @override
  State<VolunteerHomePage> createState() => _VolunteerHomePageState();
}

class _VolunteerHomePageState extends State<VolunteerHomePage> with SingleTickerProviderStateMixin {
  String _username = '';
  int _livesSaved = 0;
  String _currentAddress = '';
  bool _requestAccepted = false;
  bool _arrivedAtLocation = false;
  bool _rescuedCured = false;
  int _selectedIndex = 0;
  final FlutterTts flutterTts = FlutterTts();
  String _selectedLanguage = 'en-US';
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late PageController _pageController;
  int _currentPage = 0;

  final List<String> backgroundImages = [
    'assets/volunteer2.jpg',
    'assets/volunteer3.jpg',
    'assets/volunteer4.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _initializeTts();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    _pageController = PageController();
    // Auto-scroll background images
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _autoScrollBackground();
      }
    });
  }

  void _autoScrollBackground() {
    if (!mounted) return;
    
    Future.delayed(const Duration(seconds: 5), () {
      if (_currentPage < backgroundImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
        );
      }
      
      _autoScrollBackground();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeTts() async {
    await flutterTts.setLanguage(_selectedLanguage);
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage(_selectedLanguage);
    await flutterTts.speak(text);
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageOption('English', 'en-US'),
                _buildLanguageOption('हिंदी (Hindi)', 'hi-IN'),
                _buildLanguageOption('मराठी (Marathi)', 'mr-IN'),
                _buildLanguageOption('ગુજરાતી (Gujarati)', 'gu-IN'),
                _buildLanguageOption('বাংলা (Bengali)', 'bn-IN'),
                _buildLanguageOption('தமிழ் (Tamil)', 'ta-IN'),
                _buildLanguageOption('తెలుగు (Telugu)', 'te-IN'),
                _buildLanguageOption('ಕನ್ನಡ (Kannada)', 'kn-IN'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String label, String code) {
    return ListTile(
      title: Text(label),
      onTap: () {
        setState(() {
          _selectedLanguage = code;
        });
        _initializeTts();
        Navigator.pop(context);
      },
      trailing: _selectedLanguage == code
          ? const Icon(Icons.check, color: Color(0xFF8B7355))
          : null,
    );
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
    return Stack(
      children: [
        // Beautiful gradient background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.9),
                  Theme.of(context).primaryColor.withOpacity(0.7),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                ],
              ),
            ),
            child: CustomPaint(
              painter: BackgroundPatternPainter(),
            ),
          ),
        ),
        // Content
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: -50, end: 0),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(value, 0),
                      child: child,
                    );
                  },
                  child: const Text(
                    'Welcome to',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 50, end: 0),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(value, 0),
                      child: child,
                    );
                  },
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFE0C9A6)],
                    ).createShader(bounds),
                    child: const Text(
                      'PASHU RAKSHAK!!',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(3, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1500),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: const Text(
                      'HELP . HEAL . HOPE',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Rescue Tracking Card with Glass Effect
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rescue Tracking',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B7355),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildAnimatedCheckbox(
                              'Request Accepted',
                              _requestAccepted,
                              (value) => _updateRescueStatus('request'),
                              0,
                            ),
                            _buildAnimatedCheckbox(
                              'Arrived at the location',
                              _arrivedAtLocation,
                              _requestAccepted ? (value) => _updateRescueStatus('arrived') : null,
                              1,
                            ),
                            _buildAnimatedCheckbox(
                              'Rescued / Cured',
                              _rescuedCured,
                              _arrivedAtLocation ? (value) => _updateRescueStatus('rescued') : null,
                              2,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              decoration: const InputDecoration(
                                labelText: 'ADDRESS',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor: Colors.white70,
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
                  ),
                ),
                const SizedBox(height: 24),
                // Impact Card with Glass Effect
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Impact',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B7355),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TweenAnimationBuilder(
                              tween: Tween<int>(begin: 0, end: _livesSaved),
                              duration: const Duration(seconds: 2),
                              builder: (context, int value, child) {
                                return Text(
                                  'NO. OF LIVES SAVED BY YOU: $value',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF8B7355),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedCheckbox(String title, bool value, Function(bool?)? onChanged, int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 50, end: 0),
      duration: Duration(milliseconds: 800 + (index * 200)),
      builder: (context, double offset, child) {
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF8B7355),
          ),
        ),
        activeColor: Theme.of(context).primaryColor,
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
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () => _speak('Welcome to Pashu Rakshak'),
            tooltip: 'Read Aloud',
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguageDialog,
            tooltip: 'Change Language',
          ),
          const SizedBox(width: 8),
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

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 0; i < size.width; i += 30) {
      for (var j = 0; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 