import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:just_apartment_live/firebase_options.dart';
import 'package:just_apartment_live/ui/reelsplayer/reel_player.dart';
import 'package:just_apartment_live/ui/reelsplayer/widgets/pusherclient.dart';

import 'ui/spalsh_screen/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: HexColor('#252742'), // Set the color of the status bar
    statusBarIconBrightness:
        Brightness.light, // Set icons color to light for dark background
  ));
  runApp(const MyApp());
}





class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Poppins', // Set Poppins as the default font
      ),
      dark: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Poppins', // Set Poppins as the default font
      ),
      initial: AdaptiveThemeMode.system,
      builder: (theme, darkTheme) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: HexColor('#252742'),
          statusBarIconBrightness: Brightness.light,
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter App',
          theme: theme,
          darkTheme: darkTheme,
          home: SplashScreen(),
          // home: const SplashScreen()),
          // home:  RealTimeUpdatePage()),
          // RealTimeUpdatePage
        ),
      ),
    );
  }
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}
