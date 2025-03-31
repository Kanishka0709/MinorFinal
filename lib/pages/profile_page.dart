import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:minor/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:minor/pages/home_page.dart';
import 'welcome_page.dart';
import 'user_login_page.dart';

// Primary color (Sage Green)
const Color primaryColor = Color(0xFF7C8F6E);

// Secondary colors
const Color accentColor = Color(0xFFA67B5B);    // Warm Terra Cotta
const Color highlightColor = Color(0xFF8B7355);  // Your existing brown
const Color errorColor = Color(0xFFC35B4E);      // Earthy Red for errors/logout

const translations = {
  'en-US': {
    'profileTitle': 'Profile',
    'signIn': 'Sign In',
    'signUp': 'Sign Up',
    'loginTitle': 'Login',
    'signInToYourAccount': 'Sign in to your account',
    'emailAddress': 'Email Address',
    'password': 'Password',
    'forgotPassword': 'Forgot Password?',
    'confirm': 'Confirm',
    'signUpTitle': 'Sign Up',
    'name': 'Name',
    'mobileNumber': 'Mobile Number',
    'confirmPassword': 'Confirm Password',
    'logout': 'Logout',
    'newUserSignUp': 'New User? Sign Up to continue',
  },
  'hi-IN': {
    'profileTitle': 'प्रोफ़ाइल',
    'signIn': 'साइन इन करें',
    'signUp': 'साइन अप करें',
    'loginTitle': 'लॉगिन',
    'signInToYourAccount': 'अपने खाते में सइन इन करें',
    'emailAddress': 'ेल पता',
    'password': 'पासवर्ड',
    'forgotPassword': 'पासवर्ड भूल गए?',
    'confirm': 'पुष्टि करें',
    'signUpTitle': 'साइन अप',
    'name': 'नाम',
    'mobileNumber': 'मोबाइल नंबर',
    'confirmPassword': 'पासवर्ड की पुष्टि करें',
    'logout': 'लॉग आउट',
    'newUserSignUp': 'नए उपयोगकर्ता? जारी रखने के लिए साइन अप करें',
  },
  'mr-IN': {
    'profileTitle': 'प्रोफाइल',
    'signIn': 'साइन इन',
    'signUp': 'साइन अप',
    'loginTitle': 'लॉगिन',
    'signInToYourAccount': 'तुमच्या खात्यात साइन इन करा',
    'emailAddress': 'ईमेल पत्ता',
    'password': 'पासवर्ड',
    'forgotPassword': 'पासवर्ड विसरलात?',
    'confirm': 'पुष्टी करा',
    'signUpTitle': 'साइन अप',
    'name': 'नाव',
    'mobileNumber': 'मोबाइल नंबर',
    'confirmPassword': 'पासवर्डची पुष्टी करा',
    'logout': 'लॉगआउट',
    'newUserSignUp': 'नवीन वापरकर्ता? सुरू ठेवण्यासाठी साइन अप करा',
  },
  'ta-IN': {
    'profileTitle': 'சுயவிவரம்',
    'signIn': 'உள்நுழைவு',
    'signUp': 'பதிவு செய்யவும்',
    'loginTitle': 'உள்நுழையவும்',
    'signInToYourAccount': 'உங்கள் கணக்கில் உள்நுழைக',
    'emailAddress': 'மின்னஞ்சல் முகவரி',
    'password': 'கடவுச்சொல்',
    'forgotPassword': 'கடவுச்சொல் மறந்துவிட்டதா?',
    'confirm': 'உறுதிப்படுத்தவும்',
    'signUpTitle': 'பதிவு செய்யவும்',
    'name': 'பெயர்',
    'mobileNumber': 'மொபைல் எண்',
    'confirmPassword': 'கடவுச்சொல்லை உறுதிப்படுத்தவும்',
    'logout': 'லோகெட்',
    'newUserSignUp': 'புதிய பயனரா? தொடர பதிவு செய்யவும்',
  },
  'te-IN': {
    'profileTitle': 'ప్రొఫైల్',
    'signIn': 'సైన్ ఇన్ చేయండి',
    'signUp': 'చేరండి',
    'loginTitle': 'లాగిన్',
    'signInToYourAccount': 'మీ ఖాతాలో సైన్ ఇన్ చేయండి',
    'emailAddress': 'ఇమెయిల్ చిరునామా',
    'password': 'పాస్వర్డ్',
    'forgotPassword': 'పాస్వర్డ్ మర్చిపోయారా?',
    'confirm': 'నిర్ధారించండి',
    'signUpTitle': 'చేరండి',
    'name': 'పేరు',
    'mobileNumber': 'మొబైల్ నంబర్',
    'confirmPassword': 'పాస్వర్డ్ నిర్ధారించండి',
    'logout': 'లోగెట్',
    'newUserSignUp': 'కొత్త వినియోగదారుడా? కొనసాగించడానికి సైన్ అప్ చేయండి',
  },
  'bn-IN': {
    'profileTitle': 'প্রোফাইল',
    'signIn': 'সাইন ইন করুন',
    'signUp': 'সাইন আপ করুন',
    'loginTitle': 'লগইন',
    'signInToYourAccount': 'আপনার অ্যাকাউন্টে সাইন ইন করুন',
    'emailAddress': 'ইমেল ঠিকানা',
    'password': 'পাসওয়ার্ড',
    'forgotPassword': 'পাসওয়ার্ড ভুলে গেছেন?',
    'confirm': 'নশ্চিত করুন',
    'signUpTitle': 'সাইন আপ করুন',
    'name': 'নাম',
    'mobileNumber': 'মোবাইল নম্বর',
    'confirmPassword': 'পাসওয়ার্ড নিশ্চিত করুন',
    'logout': 'লগ আউট',
    'newUserSignUp': 'নতুন ব্যবহারকারী? চালিয়ে যেতে সাইন আপ করুন',
  },
  'gu-IN': {
    'profileTitle': 'પ્રોફાઇલ',
    'signIn': 'સાઇન ઇન કરો',
    'signUp': 'સાઇન અપ કરો',
    'loginTitle': 'લૉગિન',
    'signInToYourAccount': 'તમારા ખાતામાં સાઇન ઇન કરો',
    'emailAddress': 'ઇમેઇલ સરનામું',
    'password': 'પાસવર્ડ',
    'forgotPassword': 'પાસર્ડ ભૂલી ગયા છો?',
    'confirm': 'પુષ્ટિ કરો',
    'signUpTitle': 'સાઇન અપ',
    'name': 'નામ',
    'mobileNumber': 'મોબાઇલ નંબર',
    'confirmPassword': 'પાસવર્ડની પુષ્ટિ કરો',
    'logout': 'લોગ આઉટ',
    'newUserSignUp': 'નવા વપરાશકર્તા? ચાલુ રાખવા માટે સાઇન અપ કરો',
  },
  'pa-IN': {
    'profileTitle': 'ਪ੍ਰੋਫਾਈਲ',
    'signIn': 'ਸਾਈਨ ਇਨ ਕਰੋ',
    'signUp': 'ਸਾਈਨ ਅਪ ਕਰੋ',
    'loginTitle': 'ਲਾਗਿਨ',
    'signInToYourAccount': 'ਆਪਣੇ ਖਾਤੇੇ ਵਿੱਚ ਸਾਈਨ ਇਨ ਕਰੋ',
    'emailAddress': 'ਈਮੇਲ ਪਤਾ',
    'password': 'ਪਾਸਵਰਡ',
    'forgotPassword': 'ਪਾਸਵਰਡ ਭੁੱਲ ਗਏ?',
    'confirm': 'ਪੁਸ਼ਟੀ ਕਰੋ',
    'signUpTitle': 'ਸਾਈਨ ਅਪ ਕਰੋ',
    'name': 'ਨਾਮ',
    'mobileNumber': 'ਮੋਬਾਈਈਈਲ ਨੰਬਰ',
    'confirmPassword': 'ਪਾਸਵਰਡ ਦੀ ਪੁਸ਼ਟੀ ਕਰੋ',
    'logout': 'ਲੋਗ ਆਉਟ',
    'newUserSignUp': 'ਨਵਾਂ ਯੂਜ਼ਰ? ਜਾਰੀ ਰੱਖਣ ਲਈ ਸਾਈਨ ਅੱਪ ਕਰੋ',
  },
  'kn-IN': {
    'profileTitle': 'ಪ್ರೊಫೈಲ್',
    'signIn': 'ಸೈನ್ ಇನ್ ಮಾಡಿ',
    'signUp': 'ಸೈನ್ ಅಪ್ ಮಾಡಿ',
    'loginTitle': 'ಲಾಗಿನ್',
    'signInToYourAccount': 'ನಿಮ್ಮ ಖಾತೆಗೆ ಸೈನ್ ಇನ್ ಮಾಡಿ',
    'emailAddress': 'ಇಮೇಲ್ ವಿಳಾಸ',
    'password': 'ಪಾಸ್‌ವರ್ಡ್',
    'forgotPassword': 'ಪಾಸ್‌ವರ್ಡ್ ಮರೆತಿದ್ದೀರಾ?',
    'confirm': 'ದೃಢೀಕರಿಸಿ',
    'signUpTitle': 'ಸೈನ್ ಅಪ್',
    'name': 'ಹೆಸರು',
    'mobileNumber': 'ಮೊಬೈಲ್ ನಂಬರ್',
    'confirmPassword': 'ಪಾಸ್‌ವರ್ಡ್ ದೃಢೀಕರಿಸಿ',
    'logout': 'ಲೋಗೆಟ್',
    'newUserSignUp': 'ಹೊಸ ಬಳಕೆದಾರ? ಮುಂದುವರಿಯಲು ಸೈನ್ ಅಪ್ ಮಾಡಿ',
  },
  'ml-IN': {
    'profileTitle': 'പ്രൊഫൈൽ',
    'signIn': 'സൈൻ ഇൻ ചെയ്യുക',
    'signUp': 'സൈൻ അപ്പ് ചെയ്യുക',
    'loginTitle': 'ലോഗിൻ',
    'signInToYourAccount': 'നിങ്ങളുടെ അക്കൗണ്ടിൽ സൈൻ ഇൻ ചെയ്യുക',
    'emailAddress': 'ഇമെയിൽ വിലാസം',
    'password': 'പാസ്വേഡ്',
    'forgotPassword': 'പാസ്വേഡ് മറന്നോ?',
    'confirm': 'സ്ഥിരീകരിക്കുക',
    'signUpTitle': 'സൈൻ അപ്പ് ചെയ്യുക',
    'name': 'പേര്',
    'mobileNumber': 'മൊബൈൽ നമ്പർ',
    'confirmPassword': 'പാസ്വേഡ് സ്ഥിരീകരിക്കുക',
    'logout': 'ലോഗെട്',
    'newUserSignUp': 'പുതിയ ഉപയോക്താവ്? തുടരാൻ സൈൻ അപ്പ് ചെയ്യുക',
  },
  'or-IN': {
    'profileTitle': 'ପ୍ରୋଫାଇଲ୍',
    'signIn': 'ସାଇନ୍ ଇନ୍ କରନ୍ତୁ',
    'signUp': 'ସାଇନ୍ ଅପ୍ କରନ୍ତୁ',
    'loginTitle': 'ଲଗଇନ୍',
    'signInToYourAccount': 'ଆପଣଙ୍କର ଖାତାରେ ସାଇନ୍ ଇନ୍ କରନ୍ତୁ',
    'emailAddress': 'ଇମେଲ୍ ଠିକଣା',
    'password': 'ପାସୱାର୍ଡ',
    'forgotPassword': 'ପାସୱାର୍ଡ ଭୁଲିଗଲାନି?',
    'confirm': 'ନିଶ୍ଚିତ କରନ୍ତୁ',
    'signUpTitle': 'ସାଇନ୍ ଅପ୍ କରନ୍ତୁ',
    'name': 'ନାମ',
    'mobileNumber': 'ମୋବାଇଲ୍ ନମ୍ବର',
    'confirmPassword': 'ପାସୱାର୍ଡ ନିଶ୍ଚିତ କରନ୍ତୁ',
    'logout': 'ଲୋଗ୆ଟ୍',
    'newUserSignUp': 'ନୂଆ ୟୁଜର୍? ଜାରି ରଖିବାକୁ ସାଇନ୍ ଅପ୍ କରନ୍ତୁ',
  },
};

class ProfilePage extends StatelessWidget {
  final UserData? userData;

  const ProfilePage({
    super.key,
    required this.userData,
  });

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored data
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/user-login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  userData?.name.isNotEmpty == true
                      ? userData!.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileItem(
                      icon: Icons.person,
                      title: 'Name',
                      value: userData?.name ?? 'Not set',
                    ),
                    const Divider(),
                    _buildProfileItem(
                      icon: Icons.email,
                      title: 'Email',
                      value: userData?.email ?? 'Not set',
                    ),
                    const Divider(),
                    _buildProfileItem(
                      icon: Icons.phone,
                      title: 'Phone',
                      value: userData?.phone ?? 'Not set',
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () => _handleLogout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}