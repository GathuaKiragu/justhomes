import 'package:flutter/material.dart';
import 'package:just_apartment_live/ui/reelsplayer/reel_player.dart';

import '../ui/dashboard/dashboard_page.dart';
import '../ui/favorites/favorites_page.dart';
import '../ui/property/property_by_type_page.dart';
import '../ui/reelsplayer/reels_page.dart';

class CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const CustomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashBoardPage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const PropertyByTypePage(
                    leaseType: '1',
                    selectedIndex: 1,
                  )),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const PropertyByTypePage(
                    leaseType: '2',
                    selectedIndex: 2,
                  )),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Reels()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FavoritesPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType
          .fixed, // Ensure labels are shown for all items
      currentIndex: selectedIndex,
      selectedItemColor: Colors.purple, // Set the selected item color to purple
      unselectedItemColor: Colors.grey, // Set the unselected item color
      onTap: (index) {
        onItemSelected(index);
        _navigate(context, index);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home_work_outlined),
          label: 'Rent',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.house),
          label: 'Sale',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.video_collection_outlined),
          label: 'Reels',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Favorites',
        ),
      ],
    );
  }
}
