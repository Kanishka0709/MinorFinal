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

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _reporterNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _landmarkController = TextEditingController();
  String _selectedAnimalType = 'Dog'; // Default value
  
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

  // Initialize Cloudinary
  final cloudinary = Cloudinary.signedConfig(
    apiKey: '563881842238764',
    apiSecret: 'EKBvQcavtdBakegu0LMVgI42FQQ',
    cloudName: 'dlwtrimk6',
  );

  Future<String?> _uploadToCloudinary(XFile photo) async {
    try {
      final response = await cloudinary.upload(
        file: photo.path,
        fileBytes: await photo.readAsBytes(),
        resourceType: CloudinaryResourceType.image,
        folder: 'animal_reports', // Optional: organize images in a folder
        fileName: 'report_${DateTime.now().millisecondsSinceEpoch}', // Unique filename
      );

      if (response.isSuccessful) {
        return response.secureUrl;  // Returns the HTTPS URL of the uploaded image
      }
      return null;
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    
    if (photo != null && mounted) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Image.file(File(photo.path)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Upload to Cloudinary before showing the form
                  final String? imageUrl = await _uploadToCloudinary(photo);
                  if (imageUrl != null) {
                    _showReportForm(photo, imageUrl);
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
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _showReportForm(XFile photo, String imageUrl) async {
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
                  // Display uploaded image
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
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
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // TODO: Save the report with the imageUrl
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  String _selectedLanguage = 'en-US';
  
  final List<String> languages = [
    'English',
    'हिंदी (Hindi)',
    'मराठी (Marathi)',
    'தமிழ் (Tamil)',
    'తెలుగు (Telugu)',
    'বাংলা (Bengali)',
    'ગુજરાતી (Gujarati)',
    'ਪੰਜਾਬੀ (Punjabi)',
    'ಕನ್ನಡ (Kannada)',
    'മലയാളം (Malayalam)',
    'ଓଡ଼ିଆ (Odia)',
  ];

  String _getLanguageCode(String language) {
    switch (language) {
      case 'हिंदी (Hindi)':
        return 'hi-IN';
      case 'मराठी (Marathi)':
        return 'mr-IN';
      case 'தமிழ் (Tamil)':
        return 'ta-IN';
      case 'తెలుగు (Telugu)':
        return 'te-IN';
      case 'বাংলা (Bengali)':
        return 'bn-IN';
      case 'ગુજરાતી (Gujarati)':
        return 'gu-IN';
      case 'ਪੰਜਾਬੀ (Punjabi)':
        return 'pa-IN';
      case 'ಕನ್ನಡ (Kannada)':
        return 'kn-IN';
      case 'മലയാളം (Malayalam)':
        return 'ml-IN';
      case 'ଓଡ଼ିଆ (Odia)':
        return 'or-IN';
      default:
        return 'en-US';
    }
  }

  Future<void> _updateLanguage(String language) async {
    final String langCode = _getLanguageCode(language);
    setState(() {
      _selectedLanguage = langCode;
    });
    // Optionally save selected language to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', langCode);
  }

  Future<void> _speak(String text) async {
    final FlutterTts flutterTts = FlutterTts();
    await flutterTts.setLanguage(_selectedLanguage);
    await flutterTts.speak(text);
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: languages.map((String language) {
                return ListTile(
                  title: Text(language),
                  onTap: () {
                    _updateLanguage(language);
                    Navigator.pop(context);
                  },
                  trailing: _getLanguageCode(language) == _selectedLanguage
                      ? const Icon(Icons.check, color: Color(0xFF4B5EFC))
                      : null,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Upper Half with Background Image
            Container(
              height: MediaQuery.of(context).size.height * 0.35,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background.jpg'), // This should match your pubspec.yaml declaration
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black26,
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  // Carousel with updated styling
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: CarouselSlider(
                      options: CarouselOptions(
                        height: MediaQuery.of(context).size.height * 0.22,
                        autoPlay: true,
                        enlargeCenterPage: true,
                        viewportFraction: 0.85,
                        autoPlayAnimationDuration: const Duration(seconds: 1),
                      ),
                      items: heroes.map((hero) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Card(
                              elevation: 8,
                              shadowColor: Colors.black38,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Colors.grey.shade50,
                                    ],
                                  ),
                                ),
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
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            hero.description,
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                  color: Colors.grey[600],
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            hero.achievement,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // Top Actions with updated styling
                  Positioned(
                    top: 40,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.volume_up,
                              color: Color(0xFF4B5EFC),
                              size: 24,
                            ),
                            onPressed: () => _speak('Pashu Rakshak'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.language,
                              color: Color(0xFF4B5EFC),
                              size: 24,
                            ),
                            onPressed: () => _showLanguageDialog(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lower Half with updated styling
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.pets,
                        color: Color(0xFF4B5EFC),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Report Animal',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _takePicture,
                      icon: const Icon(Icons.camera_alt, size: 28),
                      label: const Text(
                        'Report Animal in Need',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Take a photo to report',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Emergency Call Button
      floatingActionButton: Container(
        margin: const EdgeInsets.only(left: 32),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () async {
                final Uri phoneUri = Uri.parse('tel:139');
                try {
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                  }
                } catch (e) {
                  // Handle error
                }
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.phone,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reporterNameController.dispose();
    _contactNumberController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }
} 