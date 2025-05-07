import 'package:flutter/material.dart';
import 'package:minor/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
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

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
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
  File? _selectedImage;
  bool _isLoading = false;

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

  Future<String?> _uploadImage(File imageFile) async {
    try {
      print('Starting image upload process...');

      // Create multipart request
      final url =
          Uri.parse('https://pashurakshak-service.vercel.app/api/upload/image');
      final request = http.MultipartRequest('POST', url);

      // Add the image file
      final imageStream = http.ByteStream(imageFile.openRead());
      final imageLength = await imageFile.length();

      final multipartFile = http.MultipartFile(
          'image', // This should match exactly with what API expects
          imageStream,
          imageLength,
          filename: imageFile.path.split('/').last);

      // Add form fields exactly as shown in the screenshot
      request.files.add(multipartFile);
      request.fields['category'] = 'rescue'; // This should be exactly 'rescue'
      request.fields['filename'] = imageFile.path.split('/').last;

      print('Sending request to server...');
      print('Request details:');
      print('URL: ${url.toString()}');
      print('Category: rescue');
      print('Filename: ${imageFile.path.split('/').last}');
      print('File size: ${imageLength} bytes');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          print('Upload successful: ${responseData['message']}');
          // The URL will be in responseData['data']['url'] as shown in the screenshot
          return responseData['data']['url'];
        } else {
          print('Upload failed: ${responseData['message']}');
          return null;
        }
      } else {
        print('Error status code: ${response.statusCode}');
        try {
          final errorData = json.decode(response.body);
          print('Error uploading image: ${errorData['message']}');
          print('Detailed error: ${errorData['error']}');
        } catch (e) {
          print('Raw error response: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      print('Exception during upload: $e');
      return null;
    }
  }

  Future<void> _getImage(ImageSource source) async {
    setState(() => _isLoading = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1920,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        // Upload the image
        final imageUrl = await _uploadImage(_selectedImage!);

        if (imageUrl != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image uploaded successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            _showReportForm();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload image. Please try again.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showReportForm() async {
    // Get current location
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
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
                  if (_selectedImage != null)
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
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
                    decoration:
                        const InputDecoration(labelText: 'Contact Number *'),
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
                    decoration:
                        const InputDecoration(labelText: 'Animal Type *'),
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
                    decoration:
                        const InputDecoration(labelText: 'Description *'),
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
                  // Handle form submission here
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
                    _selectedImage = null;
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
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      itemCount: heroes.length,
                      itemBuilder: (context, index) {
                        final hero = heroes[index];
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
                                      backgroundColor: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1),
                                      child: Icon(
                                        hero.icon,
                                        size: 35,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            hero.name,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .primaryColor,
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
                                              color: Theme.of(context)
                                                  .primaryColor,
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
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Report Animal Section with Glass Effect
                  _buildReportSection(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSection() {
    return Padding(
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
                    onPressed: _isLoading ? null : _showImageSourceDialog,
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
                              Icon(Icons.add_a_photo),
                              SizedBox(width: 10),
                              Text(
                                'Add Photo to Report',
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
