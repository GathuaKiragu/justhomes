// import 'dart:convert';
// import 'dart:io';
//
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:just_apartment_live/api/api.dart';
// import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
// import 'package:just_apartment_live/ui/forgot_password/forgot_password.dart';
// import 'package:just_apartment_live/ui/loading.dart';
// import 'package:just_apartment_live/ui/profile/profile_page.dart';
// import 'package:just_apartment_live/ui/register/activation_page.dart';
// import 'package:just_apartment_live/ui/register/register.dart';
// import 'package:just_apartment_live/widgets/header_main_widget.dart';
// import 'package:just_apartment_live/widgets/theme_helper.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
// import 'package:http/http.dart' as http;
// import 'package:device_info_plus/device_info_plus.dart'; // Add this import to use device info
//
// class LoginPage extends StatefulWidget {
//   @override
//   _LoginPageState createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   final _scaffoldKey = GlobalKey<ScaffoldState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _obscureText = true;
//
//   final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
//
//   Future _handleGoogleSignIn() async {
//     try {
//       print("START");
//       final GoogleSignInAccount? googleSignInAccount =
//           await googleSignIn.signIn();
//       if (googleSignInAccount != null) {
//         print("success");
//         //print(error);
//
//         Loading().loader(context, "Logging in...Please wait");
//
//         var data = {
//           'name': googleSignIn.currentUser?.displayName,
//           'email': googleSignIn.currentUser?.email,
//           'user_id': googleSignIn.currentUser?.id,
//           'profile_photo': googleSignIn.currentUser?.photoUrl,
//         };
//
//         var res = await CallApi().postData(data, 'user/social-media-login');
//         var body = json.decode(res.body);
//
//         if (body['success']) {
//           SharedPreferences localStorage =
//               await SharedPreferences.getInstance();
//           localStorage.setString('user', json.encode(body['data']));
//           Navigator.pop(context);
//           return Navigator.push(context,
//               MaterialPageRoute(builder: (context) => DashBoardPage()));
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               backgroundColor: Colors.red,
//               duration: Duration(milliseconds: 8000),
//               content: Text(body['message'].toString()),
//               action: SnackBarAction(
//                 label: 'X',
//                 textColor: Colors.orange,
//                 onPressed: () {},
//               ),
//             ),
//           );
//         }
//         Navigator.pop(context);
//       }
//     } catch (error) {
//       print("ERROR");
//       print(error);
//
//       showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: Text('Sign-In Error'),
//             content: Text(
//               'An error occurred during Google Sign-In:\n\n$error',
//               style: TextStyle(color: Colors.red),
//             ),
//             actions: <Widget>[
//               TextButton(
//                 child: Text('OK'),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//               ),
//             ],
//           );
//         },
//       );
//     }
//   }
//
//   Widget _loginWithGoogle(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: _handleGoogleSignIn,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Theme.of(context).brightness == Brightness.dark
//               ? Colors.blueGrey
//               : Colors.red, // Background color depending on dark mode
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10.0),
//           ),
//           padding: EdgeInsets.symmetric(
//               vertical: 15), // Increased padding for better height
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(right: 8.0),
//               child: Icon(
//                 FontAwesomeIcons.google,
//                 color: Colors.white,
//                 size: 20,
//               ),
//             ),
//             Text(
//               'Login with Google',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   _buildEmail(context) {
//     return Container(
//       child: TextFormField(
//         controller: _emailController,
//         style: TextStyle(
//             color: Theme.of(context)
//                 .colorScheme
//                 .onBackground), // Dynamic text color
//         decoration: InputDecoration(
//           filled: true,
//           fillColor: Theme.of(context)
//               .scaffoldBackgroundColor, // Background color of the input
//           labelText: 'Email',
//           labelStyle: TextStyle(
//               color: Theme.of(context)
//                   .colorScheme
//                   .onBackground
//                   .withOpacity(0.7)), // Dynamic label color
//           hintText: 'Enter your Email Address.',
//           hintStyle: TextStyle(
//               color: Theme.of(context)
//                   .colorScheme
//                   .onBackground
//                   .withOpacity(0.5)), // Dynamic hint color
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(10.0),
//             borderSide: BorderSide(
//               color: Theme.of(context)
//                   .colorScheme
//                   .onBackground
//                   .withOpacity(0.5), // Border color
//             ),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(10.0),
//             borderSide: BorderSide(
//               color: Theme.of(context)
//                   .colorScheme
//                   .onBackground
//                   .withOpacity(0.5), // Enabled border color
//             ),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(10.0),
//             borderSide: BorderSide(
//               color:
//                   Theme.of(context).colorScheme.primary, // Focused border color
//             ),
//           ),
//         ),
//         validator: (value) {
//           if (value!.isEmpty) {
//             return 'Please Enter Email to continue';
//           }
//           return null;
//         },
//         onSaved: (value) {
//           _emailController.text = value!;
//         },
//       ),
//       decoration: ThemeHelper().inputBoxDecorationShaddow(),
//     );
//   }
//
//   _buildPassword(context) {
//     return Container(
//       child: TextFormField(
//         controller: _passwordController,
//         style: TextStyle(
//             color: Theme.of(context)
//                 .colorScheme
//                 .onBackground), // Dynamic text color
//         obscureText: _obscureText,
//         decoration: InputDecoration(
//           filled: true,
//           fillColor: Theme.of(context)
//               .scaffoldBackgroundColor, // Background color of the input
//           labelText: 'Password',
//           labelStyle: TextStyle(
//               color: Theme.of(context)
//                   .colorScheme
//                   .onBackground
//                   .withOpacity(0.7)), // Dynamic label color
//           hintText: 'Enter your password',
//           hintStyle: TextStyle(
//               color: Theme.of(context)
//                   .colorScheme
//                   .onBackground
//                   .withOpacity(0.5)), // Dynamic hint color
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(10.0),
//             borderSide: BorderSide(
//               color: Theme.of(context)
//                   .colorScheme
//                   .onBackground
//                   .withOpacity(0.5), // Border color
//             ),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(10.0),
//             borderSide: BorderSide(
//               color: Theme.of(context)
//                   .colorScheme
//                   .onBackground
//                   .withOpacity(0.5), // Enabled border color
//             ),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(10.0),
//             borderSide: BorderSide(
//               color:
//                   Theme.of(context).colorScheme.primary, // Focused border color
//             ),
//           ),
//           suffixIcon: IconButton(
//             icon: Icon(
//               _obscureText ? Icons.visibility : Icons.visibility_off,
//               color: Colors.grey,
//             ),
//             onPressed: () {
//               setState(() {
//                 _obscureText = !_obscureText;
//               });
//             },
//           ),
//         ),
//         validator: (value) {
//           if (value!.isEmpty) {
//             return 'Please Enter Password to continue';
//           }
//           return null;
//         },
//         onSaved: (value) {
//           _passwordController.text = value!;
//         },
//       ),
//       decoration: ThemeHelper().inputBoxDecorationShaddow(),
//     );
//   }
//
//   _buildForgetPassword(context) {
//     return Container(
//       margin: EdgeInsets.fromLTRB(10, 0, 10, 20),
//       alignment: Alignment.topRight,
//       child: GestureDetector(
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
//           );
//         },
//         child: Text(
//           "Forgot your password?",
//           style: TextStyle(
//             color: Theme.of(context).colorScheme.primary, // Dynamic text color
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
//
//   _buildLoginButton(context) {
//     return Container(
//       width: double.infinity, // Makes the button full width
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.purple, // Set the background color to purple
//           foregroundColor: Colors.white, // Set the text color to white
//           shape: RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(10.0), // Adjusts the button's shape
//           ),
//           padding: EdgeInsets.fromLTRB(40, 10, 40, 10), // Button padding
//         ),
//         child: Text(
//           'Login'.toUpperCase(),
//           style: TextStyle(
//             fontSize: 15,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         onPressed: () => _handleLogin(context),
//       ),
//     );
//   }
//
//   _buildRegisterButton(context) {
//     return Container(
//       margin: EdgeInsets.fromLTRB(10, 20, 10, 20),
//       alignment: Alignment.center,
//       child: RichText(
//         text: TextSpan(
//           children: [
//             TextSpan(
//               text: "Don't have an account? ",
//               style: TextStyle(
//                 color: Theme.of(context)
//                     .colorScheme
//                     .onBackground
//                     .withOpacity(0.7), // Dynamic text color
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             TextSpan(
//               text: "Register",
//               style: TextStyle(
//                 color:
//                     Theme.of(context).colorScheme.primary, // Dynamic link color
//                 fontWeight: FontWeight.bold,
//               ),
//               recognizer: TapGestureRecognizer()
//                 ..onTap = () {
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (context) => RegisterPage()));
//                 },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   _handleLogin(BuildContext context) async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//     _formKey.currentState!.save();
//
//     Loading().loader(context, "Logging in...Please wait");
//
//     var data = {
//       'email': _emailController.text,
//       'password': _passwordController.text
//     };
//     var res = await CallApi().postData(data, 'user/login');
//     var body = json.decode(res.body);
//
//     if (body['success']) {
//       SharedPreferences localStorage = await SharedPreferences.getInstance();
//       localStorage.setString('user', json.encode(body['data']));
//       Navigator.pop(context);
//       return Navigator.push(
//           context, MaterialPageRoute(builder: (context) => DashBoardPage()));
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.red,
//           duration: Duration(milliseconds: 8000),
//           content: Text(body['message'].toString()),
//           action: SnackBarAction(
//             label: 'X',
//             textColor: Colors.orange,
//             onPressed: () {},
//           ),
//         ),
//       );
//     }
//     Navigator.pop(context);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor:
//           Theme.of(context).scaffoldBackgroundColor, // Dynamic background color
//       appBar: buildHeader(context),
//       drawer: buildDrawer(context),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             SafeArea(
//               child: Container(
//                   padding: EdgeInsets.fromLTRB(10, 60, 20, 10),
//                   margin: EdgeInsets.fromLTRB(20, 10, 20, 10),
//                   child: Column(
//                     children: [
//                       Text(
//                         'LOGIN',
//                         style: TextStyle(
//                             color: Theme.of(context).colorScheme.onBackground,
//                             fontSize: 25), // Dynamic text color
//                       ),
//                       Text(
//                         'Login into your account',
//                         style: TextStyle(
//                             color: Theme.of(context)
//                                 .colorScheme
//                                 .onBackground), // Dynamic text color
//                       ),
//                       SizedBox(height: 20.0),
//                       Form(
//                         key: _formKey,
//                         child: Column(
//                           children: [
//                             _loginWithGoogle(context),
//                             // SizedBox(height: 15.0),
//                             // _loginWithApple(context),
//                             Padding(
//                               padding: EdgeInsets.only(top: 10, bottom: 10),
//                               child: Text("Login wiith Email & Passwords"),
//                             ),
//                             _buildEmail(context),
//                             SizedBox(height: 30.0),
//                             _buildPassword(context),
//                             SizedBox(height: 15.0),
//                             _buildForgetPassword(context),
//                             _buildLoginButton(context),
//                             SizedBox(height: 15.0),
//                             _buildRegisterButton(context),
//                           ],
//                         ),
//                       ),
//                     ],
//                   )),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _loginWithApple(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: () => signInWithApple(context),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.black, // Apple button color
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10.0),
//           ),
//           padding: EdgeInsets.symmetric(
//               vertical: 15), // Increased padding for better height
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(right: 8.0),
//               child: Icon(
//                 FontAwesomeIcons.apple,
//                 color: Colors.white,
//                 size: 26,
//               ),
//             ),
//             Text(
//               'Login with Apple',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   signInWithApple(BuildContext context) async {
//     try {
//       final result = await SignInWithApple.getAppleIDCredential(
//         scopes: [
//           AppleIDAuthorizationScopes.email,
//           AppleIDAuthorizationScopes.fullName,
//         ],
//       );
//
//       // Check if identityToken is retrieved
//       final appleToken = result.identityToken;
//       if (appleToken == null) {
//         throw Exception("Failed to retrieve Apple identity token");
//       } else {
//         String userName = "Unknown User"; // Default if name is not available
//
//         // Check if the full name is provided by Apple
//         if (result.givenName != null || result.familyName != null) {
//           userName =
//               "${result.givenName ?? ''} ${result.familyName ?? ''}".trim();
//         }
//
//         // If no name is provided, fetch the device name (fallback)
//         if (userName.isEmpty || userName == "Unknown User") {
//           DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//           if (Platform.isAndroid) {
//             AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//             userName = androidInfo.model; // Device model name for Android
//           } else if (Platform.isIOS) {
//             IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
//             userName = iosInfo.name; // Device name for iOS
//           }
//         }
//
//         Loading().loader(context, "Logging in...Please wait");
//
//         // Send the token and username to your backend
//         final response = await http.post(
//           Uri.parse('https://justhomes.co.ke/auth/apple'),
//           headers: {'Content-Type': 'application/json'},
//           body: jsonEncode({
//             'token': appleToken,
//             'name': userName, // Send the username
//           }),
//         );
//
//         if (response.statusCode == 200) {
//           final body = jsonDecode(response.body);
//
//           if (body['success']) {
//             SharedPreferences localStorage =
//                 await SharedPreferences.getInstance();
//             localStorage.setString('user', json.encode(body['data']));
//             Navigator.pop(context);
//             return Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => DashBoardPage()),
//             );
//           } else {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 backgroundColor: Colors.red,
//                 duration: Duration(milliseconds: 8000),
//                 content: Text(body['message'].toString()),
//                 action: SnackBarAction(
//                   label: 'X',
//                   textColor: Colors.orange,
//                   onPressed: () {},
//                 ),
//               ),
//             );
//           }
//         }
//
//         Navigator.pop(context);
//       }
//     } catch (error) {
//       // Handle error here, for example showing an error message
//     }
//   }
// }
import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
import 'package:just_apartment_live/ui/forgot_password/forgot_password.dart';
import 'package:just_apartment_live/ui/loading.dart';
import 'package:just_apartment_live/ui/profile/profile_page.dart';
import 'package:just_apartment_live/ui/register/activation_page.dart';
import 'package:just_apartment_live/ui/register/register.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:just_apartment_live/widgets/theme_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  int selectedOption = 1;

  bool _obscureText = true;

  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);

  Future _handleAppleSignIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      Loading().loader(context, "Logging in...Please wait");

      var data = {
        'name': credential.givenName ?? 'User',
        'email': credential.email ?? '',
        'user_id': credential.userIdentifier,
        'profile_photo': '', // Apple doesn't provide a profile photo
      };

      var res = await CallApi().postData(data, 'user/social-media-login');
      var body = json.decode(res.body);

      if (body['success']) {
        SharedPreferences localStorage = await SharedPreferences.getInstance();
        localStorage.setString('user', json.encode(body['data']));
        Navigator.pop(context);
        return Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DashBoardPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 8000),
            content: Text(body['message'].toString()),
            action: SnackBarAction(
              label: 'X',
              textColor: Colors.orange,
              onPressed: () {},
            ),
          ),
        );
      }
      Navigator.pop(context);
    } catch (error) {
      print("Apple Sign-In Error: $error");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Sign-In Error'),
            content: Text(
              'An error occurred during Apple Sign-In:\n\n$error',
              style: TextStyle(color: Colors.red),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Widget _loginWithApple(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleAppleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black, // Apple's recommended button color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: EdgeInsets.symmetric(vertical: 15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(
                FontAwesomeIcons.apple,
                color: Colors.white,
                size: 20,
              ),
            ),
            Text(
              'Login with Apple',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _handleLogin(BuildContext context) async {
    // if (!_formKey.currentState!.validate()) {
    //   return;
    // }
    // _formKey.currentState!.save();

    var data = {};
    if (selectedOption == 1) {
      if (_emailController.text == "" || _emailController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 8000),
            content: Text("Email address cannot be empty"),
            action: SnackBarAction(
              label: 'X',
              textColor: Colors.orange,
              onPressed: () {},
            ),
          ),
        );
        return;
      } else {
        data = {
          'email': _emailController.text,
          'password': _passwordController.text
        };
      }
    } else {
      if (_phoneNumberController.text == "" ||
          _phoneNumberController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 8000),
            content: Text("Phone Number cannot be empty"),
            action: SnackBarAction(
              label: 'X',
              textColor: Colors.orange,
              onPressed: () {},
            ),
          ),
        );
        return;
      } else {
        data = {
          'telephone': _phoneNumberController.text,
          'password': _passwordController.text
        };
      }
    }


    print("BODY LOGIN -----> $data");
    var res = await CallApi().postData(data, 'user/login');
    Loading().loader(context, "Logging in...Please wait");


    var body = json.decode(res.body);
    print("BODY REEEES -----> ${res.statusCode.runtimeType}}");

    if(res.statusCode == 200) {
      if (body['success']) {
        SharedPreferences localStorage = await SharedPreferences.getInstance();
        localStorage.setString('user', json.encode(body['data']));
        Navigator.pop(context);
        return Navigator.push(
            context, MaterialPageRoute(builder: (context) => DashBoardPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 8000),
            content: Text(body['message'].toString()),
            action: SnackBarAction(
              label: 'X',
              textColor: Colors.orange,
              onPressed: () {},
            ),
          ),
        );
      }
      Navigator.pop(context);
    }else{
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 8000),
          content: Text("Server Error! ${res.statusCode}"),
          action: SnackBarAction(
            label: 'X',
            textColor: Colors.orange,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future _handleGoogleSignIn() async {
    try {
      print("START");
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      print('\n\n\n\n\n\n\n?????????START');
      if (googleSignInAccount != null) {
        print("success");
        //print(error);

        // print('\n\n\n\n\n\n\n?????????SUCCESSS');

        Loading().loader(context, "Logging in...Please wait");

        var data = {
          'name': googleSignIn.currentUser?.displayName,
          'email': googleSignIn.currentUser?.email,
          'user_id': googleSignIn.currentUser?.id,
          'profile_photo': googleSignIn.currentUser?.photoUrl,
        };

        print(
            "DATA LOGIN ------<<<<<<>>>>>>>>>>>>>>\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
        print(data);
        print(
            "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n <<<<<<<<<<<<<END>>>>>>>>>>>>>>>>");

        var res = await CallApi().postData(data, 'user/social-media-login');
        var body = json.decode(res.body);

        if (body['success']) {
          SharedPreferences localStorage =
              await SharedPreferences.getInstance();
          localStorage.setString('user', json.encode(body['data']));
          Navigator.pop(context);
          return Navigator.push(context,
              MaterialPageRoute(builder: (context) => DashBoardPage()));
        } else {
          print("\n\n\n\nERROR ---LOGIN-->>>>>" + res + "\n\n\n\n\n");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              duration: Duration(milliseconds: 8000),
              content: Text(body['message'].toString()),
              action: SnackBarAction(
                label: 'X',
                textColor: Colors.orange,
                onPressed: () {},
              ),
            ),
          );
        }
        Navigator.pop(context);
      }
    } catch (error) {
      print(
          "ERROR ------<<<<<<>>>>>>>>>>>>>>\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
      print(error);
      print(
          "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n <<<<<<<<<<<<<END>>>>>>>>>>>>>>>>");

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Sign-In Error'),
            content: Text(
              'An error occurred during Google Sign-In:\n\n$error',
              style: TextStyle(color: Colors.red),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Widget _loginWithGoogle(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red, // Apple's recommended button color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: EdgeInsets.symmetric(vertical: 15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(
                FontAwesomeIcons.google,
                color: Colors.white,
                size: 20,
              ),
            ),
            Text(
              'Login with Google',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginButton(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleLogin(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple, // Apple's recommended button color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: EdgeInsets.symmetric(vertical: 15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Padding(
            //   padding: const EdgeInsets.only(right: 8.0),
            //   child: Icon(
            //     FontAwesomeIcons.accessibleIcon,
            //     color: Colors.white,
            //     size: 20,
            //   ),
            // ),
            Text(
              'Login',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildEmail(context) {
    return Container(
      child: TextFormField(
        controller: _emailController,
        style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onBackground), // Dynamic text color
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context)
              .scaffoldBackgroundColor, // Background color of the input
          labelText: 'Email',
          labelStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onBackground
                  .withOpacity(0.7)), // Dynamic label color
          hintText: 'Enter your Email Address.',
          hintStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onBackground
                  .withOpacity(0.5)), // Dynamic hint color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .onBackground
                  .withOpacity(0.5), // Border color
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .onBackground
                  .withOpacity(0.5), // Enabled border color
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color:
                  Theme.of(context).colorScheme.primary, // Focused border color
            ),
          ),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please Enter Email to continue';
          }
          return null;
        },
        onSaved: (value) {
          _emailController.text = value!;
        },
      ),
      decoration: ThemeHelper().inputBoxDecorationShaddow(),
    );
  }

  _buildPhone(context) {
    return Container(
      child: TextFormField(
        controller: _phoneNumberController,
        style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onBackground), // Dynamic text color
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context)
              .scaffoldBackgroundColor, // Background color of the input
          labelText: 'Phone',
          labelStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onBackground
                  .withOpacity(0.7)), // Dynamic label color
          hintText: 'Enter your Phone Number.',
          hintStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onBackground
                  .withOpacity(0.5)), // Dynamic hint color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .onBackground
                  .withOpacity(0.5), // Border color
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .onBackground
                  .withOpacity(0.5), // Enabled border color
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color:
                  Theme.of(context).colorScheme.primary, // Focused border color
            ),
          ),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please enter phone number to continue';
          }
          return null;
        },
        onSaved: (value) {
          _emailController.text = value!;
        },
      ),
      decoration: ThemeHelper().inputBoxDecorationShaddow(),
    );
  }

  _buildPassword(context) {
    return Container(
      child: TextFormField(
        controller: _passwordController,
        style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onBackground), // Dynamic text color
        obscureText: _obscureText,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context)
              .scaffoldBackgroundColor, // Background color of the input
          labelText: 'Password',
          labelStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onBackground
                  .withOpacity(0.7)), // Dynamic label color
          hintText: 'Enter your password',
          hintStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onBackground
                  .withOpacity(0.5)), // Dynamic hint color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .onBackground
                  .withOpacity(0.5), // Border color
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .onBackground
                  .withOpacity(0.5), // Enabled border color
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color:
                  Theme.of(context).colorScheme.primary, // Focused border color
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please Enter Password to continue';
          }
          return null;
        },
        onSaved: (value) {
          _passwordController.text = value!;
        },
      ),
      decoration: ThemeHelper().inputBoxDecorationShaddow(),
    );
  }

  _buildForgetPassword(context) {
    return Container(
      margin: EdgeInsets.fromLTRB(10, 0, 10, 20),
      alignment: Alignment.topRight,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
          );
        },
        child: Text(
          "Forgot your password?",
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary, // Dynamic text color
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildHeader(context),
      drawer: buildDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SafeArea(
              child: Container(
                padding: EdgeInsets.fromLTRB(10, 60, 20, 10),
                child: Column(
                  children: [
                    Text(
                      'LOGIN',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontSize: 25), // Dynamic text color
                    ),
                    Text(
                      'Login into your account',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground), // Dynamic text color
                    ),
                    Container(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: ListTile(
                              title: const Text('Email'),
                              leading: Radio<int>(
                                value: 1,
                                groupValue: selectedOption,
                                onChanged: (value) {
                                  setState(() {
                                    selectedOption = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: const Text('Phone'),
                              leading: Radio<int>(
                                value: 2,
                                groupValue: selectedOption,
                                onChanged: (value) {
                                  setState(() {
                                    selectedOption = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          selectedOption == 1
                              ? _buildEmail(context)
                              : _buildPhone(context),
                          SizedBox(height: 30.0),
                          _buildPassword(context),
                          SizedBox(height: 15.0),
                          _buildForgetPassword(context),
                          _loginButton(context),
                          SizedBox(height: 15.0),
                          _buildRegisterButton(context),
                          SizedBox(height: 30.0),
                          _loginWithGoogle(context),
                          SizedBox(height: 15.0),
                          _loginWithApple(context)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildForgetPassword(BuildContext context) {
  return Container(
    margin: EdgeInsets.fromLTRB(10, 0, 10, 20),
    alignment: Alignment.topRight,
    child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
        );
      },
      child: Text(
        "Forgot your password?",
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary, // Dynamic text color
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

Widget _buildRegisterButton(BuildContext context) {
  return TextButton(
    onPressed: () {
      // Navigate to registration page
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                RegisterPage()), // Replace with your RegisterPage widget
      );
    },
    child: Text(
      'Don’t have an account? Register',
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget _buildPassword(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: TextField(
      decoration: InputDecoration(
        labelText: 'Password',
        border: OutlineInputBorder(),
      ),
      obscureText: true,
      onChanged: (value) {
        // Handle password input logic if needed
      },
    ),
  );
}

//   Future _handleGoogleSignIn() async {
//     try {
//       print("START");
//       final GoogleSignInAccount? googleSignInAccount =
//           await googleSignIn.signIn();
//       if (googleSignInAccount != null) {
//         print("success");
//         //print(error);
//
//         Loading().loader(context, "Logging in...Please wait");
//
//         var data = {
//           'name': googleSignIn.currentUser?.displayName,
//           'email': googleSignIn.currentUser?.email,
//           'user_id': googleSignIn.currentUser?.id,
//           'profile_photo': googleSignIn.currentUser?.photoUrl,
//         };
//
//         var res = await CallApi().postData(data, 'user/social-media-login');
//         var body = json.decode(res.body);
//
//         if (body['success']) {
//           SharedPreferences localStorage =
//               await SharedPreferences.getInstance();
//           localStorage.setString('user', json.encode(body['data']));
//           Navigator.pop(context);
//           return Navigator.push(context,
//               MaterialPageRoute(builder: (context) => DashBoardPage()));
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               backgroundColor: Colors.red,
//               duration: Duration(milliseconds: 8000),
//               content: Text(body['message'].toString()),
//               action: SnackBarAction(
//                 label: 'X',
//                 textColor: Colors.orange,
//                 onPressed: () {},
//               ),
//             ),
//           );
