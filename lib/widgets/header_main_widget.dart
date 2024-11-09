import 'dart:convert';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:just_apartment_live/ui/agents/agents_page.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
import 'package:just_apartment_live/ui/government_housing/government_housing.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/ui/profile/profile_page.dart';
import 'package:just_apartment_live/ui/property/auctioned_properties_page.dart';
import 'package:just_apartment_live/ui/property/offplan_properties_page.dart';
import 'package:just_apartment_live/ui/property/post_page.dart';
import 'package:just_apartment_live/ui/property/search_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color appBarColor = Color(0xFF252742); // Purple background color
const String userKey = 'user';
const String tokenKey = 'token';

Future<int> checkIfUserIsLoggedIn() async {
  SharedPreferences localStorage = await SharedPreferences.getInstance();
  var user = json.decode(localStorage.getString(userKey) ?? '{}');
  return user['id'] != null ? 1 : 0;
}

void navigateToPage(BuildContext context, Widget page) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
}

AppBar buildHeader(BuildContext context) {
  return AppBar(
    backgroundColor: appBarColor,
    iconTheme: IconThemeData(color: Colors.white),
    centerTitle: false,
    elevation: 0.0,
    actions: <Widget>[
      IconButton(
        icon: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          checkIfUserIsLoggedIn().then((result) {
            navigateToPage(context, result == 1 ? PostPage() : LoginPage());
          });
        },
      ),
      IconButton(
        icon: Icon(Icons.person_pin, color: Colors.white),
        onPressed: () {
          checkIfUserIsLoggedIn().then((result) {
            navigateToPage(context, result == 1 ? ProfilePage() : LoginPage());
          });
        },
      ),
    ],
  );
}

Drawer buildDrawer(BuildContext context, {bool isPublic = false}) {
  return Drawer(
    child: Column(
      children: <Widget>[
        Divider(height: 30.0),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              buildDrawerItem(context, Icons.home, 'Home', DashBoardPage()),
              buildDrawerItem(
                  context, Icons.settings, 'Dashboard', ProfilePage()),
              buildDrawerItem(
                  context, Icons.people, 'Just Homes Agents', AgentsPage()),
              buildDrawerItem(
                  context, Icons.search, 'Search Property', SearchPage()),
              buildDrawerItem(
                  context,
                  Icons.house_outlined,
                  'OffPlan Properties',
                  OffPlanPropertiesPage(selectedIndex: 2)),
              buildDrawerItem(
                  context,
                  Icons.house_siding_rounded,
                  'On Auction Properties',
                  AuctionedPropertiesPage(selectedIndex: 2)),
              buildDrawerItem(context, Icons.house_siding_rounded,
                  'Government Housing', GovernmentHousing(selectedIndex: 2)),
              buildDrawerItem(
                  context, Icons.house, 'Post New Property', PostPage()),
              buildLogoutItem(context),
              buildThemeToggle(context),
              if (isPublic) buildLoginItem(context),
            ],
          ),
        ),
      ],
    ),
  );
}

ListTile buildDrawerItem(
    BuildContext context, IconData icon, String title, Widget page) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    onTap: () => navigateToPage(context, page),
  );
}

ListTile buildLogoutItem(BuildContext context) {
  return ListTile(
    leading: Icon(Icons.logout),
    title: Text('Logout'),
    onTap: () async {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      await localStorage.remove(userKey);
      await localStorage.remove(tokenKey);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    },
  );
}

ListTile buildThemeToggle(BuildContext context) {
  return ListTile(
    title: Text('Light/Dark Mode'),
    trailing: Switch(
      value: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light,
      onChanged: (value) {
        AdaptiveTheme.of(context).setThemeMode(
          value ? AdaptiveThemeMode.light : AdaptiveThemeMode.dark,
        );
      },
    ),
  );
}

ListTile buildLoginItem(BuildContext context) {
  return ListTile(
    leading: Icon(Icons.login),
    title: Text('Login'),
    onTap: () {
      navigateToPage(context, LoginPage());
    },
  );
}
