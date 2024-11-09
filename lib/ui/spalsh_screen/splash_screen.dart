import 'package:flutter/material.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(
      Duration(seconds: 3), // Adjust the duration as needed
      () {},
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DashBoardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Ensure the image covers the entire screen
          Image.asset(
            'images/splashscreen.jpg',
            fit: BoxFit.cover, // Use BoxFit.cover to fill the screen
            width: double.infinity,
            height: double.infinity,
          ),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }
}
