import 'package:flutter/material.dart';
import 'package:minor/main.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HeroInfo {
  final String name;
  final String description;
  final String achievement;
  final IconData icon;

  const HeroInfo({
    required this.name,
    required this.description,
    required this.achievement,
    required this.icon,
  });
}

class HomePage extends StatefulWidget {
  final String username;
  
  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  
  // Form controllers
  final _reporterNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedAnimalType = 'Dog';
  String _selectedLanguage = 'en-US';
  final FlutterTts flutterTts = FlutterTts();
  bool _isTrafficAccident = false;
  bool _isAnimalAggressive = false;
  String? _currentPhotoUrl;
  bool _isLoading = false;

  // Initialize Cloudinary
  final cloudinary = Cloudinary.signedConfig(
    apiKey: '563881842238764',
    apiSecret: 'EKBvQcavtdBakegu0LMVgI42FQQ',
    cloudName: 'dlwtrimk6',
  );

  static const List<HeroInfo> heroes = [
    HeroInfo(
      name: 'Dr. Rajesh Kumar',
      description: 'Veterinarian',
      achievement: 'Saved 200+ street animals in last year',
      icon: Icons.medical_services,
    ),
    HeroInfo(
      name: 'Priya Singh',
      description: 'Animal Welfare Activist',
      achievement: 'Runs shelter home for 100+ animals',
      icon: Icons.home,
    ),
    HeroInfo(
      name: 'NGO Paws & Care',
      description: 'Animal Welfare Organization',
      achievement: 'Conducted 50+ rescue operations this month',
      icon: Icons.pets,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage(_selectedLanguage);
    await flutterTts.speak(text);
  }

  Future<String?> _uploadToCloudinary(XFile photo) async {
    try {
      final response = await cloudinary.upload(
        file: photo.path,
        fileBytes: await photo.readAsBytes(),
        resourceType: CloudinaryResourceType.image,
        folder: 'animal_reports',
        fileName: 'report_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (response.isSuccessful) {
        return response.secureUrl;
      }
      return null;
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  Future<void> _takePicture() async {
    setState(() => _isLoading = true);
    
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1920,
      );
      
      if (photo != null && mounted) {
        final String? imageUrl = await _uploadToCloudinary(photo);
        if (imageUrl != null) {
          setState(() => _currentPhotoUrl = imageUrl);
          _showReportForm();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload image'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error taking picture'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showReportForm() async {
    // Get current location
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
    } catch (e) {
      position = Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Report Details'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentPhotoUrl != null)
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(_currentPhotoUrl!),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reporterNameController,
                    decoration: const InputDecoration(labelText: 'Your Name *'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _contactNumberController,
                    decoration: const InputDecoration(labelText: 'Contact Number *'),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter contact number';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedAnimalType,
                    decoration: const InputDecoration(labelText: 'Animal Type *'),
                    items: ['Dog', 'Cat', 'Cow', 'Bird', 'Other']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAnimalType = value!;
                      });
                    },
                  ),
                  TextFormField(
                    controller: _landmarkController,
                    decoration: const InputDecoration(labelText: 'Landmark *'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a landmark';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description *'),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Traffic Accident'),
                    value: _isTrafficAccident,
                    onChanged: (value) {
                      setState(() {
                        _isTrafficAccident = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Animal is Aggressive'),
                    value: _isAnimalAggressive,
                    onChanged: (value) {
                      setState(() {
                        _isAnimalAggressive = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Location: ${position.latitude}, ${position.longitude}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    'Report Time: ${DateTime.now().toString()}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final report = AnimalReport(
                    reporterName: _reporterNameController.text,
                    contactNumber: _contactNumberController.text,
                    latitude: position.latitude,
                    longitude: position.longitude,
                    reportTime: DateTime.now(),
                    address: '${position.latitude}, ${position.longitude}',
                    landmark: _landmarkController.text,
                    animalType: _selectedAnimalType,
                    description: _descriptionController.text,
                    photoUrls: _currentPhotoUrl != null ? [_currentPhotoUrl!] : [],
                    isTrafficAccident: _isTrafficAccident,
                    isAnimalAggressive: _isAnimalAggressive,
                  );

                  // TODO: Send report to your backend
                  print('Report data: ${jsonEncode(report.toJson())}');

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Clear form
                  _reporterNameController.clear();
                  _contactNumberController.clear();
                  _landmarkController.clear();
                  _descriptionController.clear();
                  setState(() {
                    _currentPhotoUrl = null;
                    _isTrafficAccident = false;
                    _isAnimalAggressive = false;
                  });
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Beautiful gradient background with pattern
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  // Welcome Text with Animations
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: -50, end: 0),
                          duration: const Duration(milliseconds: 1000),
                          builder: (context, double value, child) {
                            return Transform.translate(
                              offset: Offset(value, 0),
                              child: child,
                            );
                          },
                          child: Text(
                            'Welcome, ${widget.username}!',
                            style: const TextStyle(
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
                              'PASHU RAKSHAK',
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Heroes Carousel with Glass Effect
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 200,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      viewportFraction: 0.85,
                      autoPlayAnimationDuration: const Duration(seconds: 1),
                    ),
                    items: heroes.map((hero) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
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
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 35,
                                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                        child: Icon(
                                          hero.icon,
                                          size: 35,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              hero.name,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              hero.description,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              hero.achievement,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Theme.of(context).primaryColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  // Report Animal Section with Glass Effect
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
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
                                Row(
                                  children: [
                                    Icon(
                                      Icons.pets,
                                      color: Theme.of(context).primaryColor,
                                      size: 30,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Report Animal',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _takePicture,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.camera_alt),
                                            SizedBox(width: 10),
                                            Text(
                                              'Take a Photo to Report',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
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

// Report Model
class AnimalReport {
  final String reporterName;
  final String contactNumber;
  final double? latitude;
  final double? longitude;
  final DateTime reportTime;
  final String address;
  final String landmark;
  final String animalType;
  final String description;
  final List<String> photoUrls;
  final bool isTrafficAccident;
  final bool isAnimalAggressive;

  AnimalReport({
    required this.reporterName,
    required this.contactNumber,
    this.latitude,
    this.longitude,
    required this.reportTime,
    required this.address,
    required this.landmark,
    required this.animalType,
    required this.description,
    required this.photoUrls,
    required this.isTrafficAccident,
    required this.isAnimalAggressive,
  });

  Map<String, dynamic> toJson() {
    return {
      'reporterName': reporterName,
      'contactNumber': contactNumber,
      'latitude': latitude,
      'longitude': longitude,
      'reportTime': reportTime.toIso8601String(),
      'address': address,
      'landmark': landmark,
      'animalType': animalType,
      'description': description,
      'photoUrls': photoUrls,
      'isTrafficAccident': isTrafficAccident,
      'isAnimalAggressive': isAnimalAggressive,
    };
  }
} 