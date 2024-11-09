import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/reels/trimmer_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UserReels extends StatefulWidget {
  const UserReels({Key? key}) : super(key: key);

  @override
  State<UserReels> createState() => _UserReelsState();
}

class _UserReelsState extends State<UserReels> {
  List<File> _uploadedVideos = []; // List to store uploaded videos
  List _userReels = []; // List to hold user reels

  @override
  void initState() {
    super.initState();
    _getUserReels(); // Fetch user reels on initialization
  }

  Future<bool> _getUserReels() async {
    try {
      // Retrieve user details from SharedPreferences
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = json.decode(localStorage.getString('user') ?? '{}');

      final uri =
          '${Configuration.API_URL}reels/get-user-reels'; // Ensure this URL is correct

      // Make the API call
      final response = await http.post(
        Uri.parse(uri),
        headers: {
          'Content-Type': 'application/json', // Set content type to JSON
        },
        body: json.encode({
          'user_id': user['id'], // Ensure user['id'] is valid
        }),
      );

      print("Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        // Handle success and parse the response body
        var data = json.decode(response.body);

        // Check if the data contains reels
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _userReels = List.from(
                data['data']); // Assign the retrieved reels to _userReels
          });
          return true;
        } else {
          print("Failed to fetch user reels: ${data['message']}");
          return false;
        }
      } else {
        // Handle failure
        print("Failed to fetch user reels: ${response.body}");
        return false;
      }
    } catch (e) {
      // Handle exceptions (e.g., network errors)
      print("Error fetching user reels: $e");
      return false;
    }
  }

  void _deleteReel(String reelId) {
    // Show confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Reel'),
          content: const Text('Are you sure you want to delete this reel?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the confirmation dialog

                // Show a loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const AlertDialog(
                      content: Text('Deleting... Please wait...'),
                    );
                  },
                );

                // Implement the logic to delete the reel using its ID
                print("Delete reel with ID: $reelId");

                // Call the method to perform the delete API request
                _performDeleteReel(reelId);

                // Close the loading dialog
                Navigator.of(context).pop();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  _performDeleteReel(String reelId) async {
    try {
      // Retrieve user details from SharedPreferences

      final uri =
          '${Configuration.API_URL}reels/delete-reel'; // Ensure this URL is correct

      // Make the API call
      final response = await http.post(
        Uri.parse(uri),
        headers: {
          'Content-Type': 'application/json', // Set content type to JSON
        },
        body: json.encode({
          'reelId': reelId, // Ensure user['id'] is valid
        }),
      );

      print("Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return UserReels();
          }),
        );
        // Handle success and parse the response body
        var data = json.decode(response.body);

        // Check if the data contains reels
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _userReels = List.from(
                data['data']); // Assign the retrieved reels to _userReels
          });
        } else {
          print("Failed to delete ${data['message']}");
        }
      } else {
        // Handle failure
        print("Failed to delete ${response.body}");
      }
    } catch (e) {
      // Handle exceptions (e.g., network errors)
      print("Error deleting reels: $e");
    }

    // Implement the actual delete logic here
    // Add API call to delete the reel and update state
    print("Reel deleted with ID: $reelId");
    // Refresh the list after deletion
    // setState(() {
    //   _userReels.removeWhere((reel) => reel['id'] == reelId);
    // });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Reels',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF252742),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Card for uploading video
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                color: Colors.grey[200],
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double
                              .infinity, // Ensure the button takes the full width
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.video_file),
                            label: const Text('UPLOAD VIDEO'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.purple,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                            onPressed: () async {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.video,
                                allowCompression: false,
                              );
                              if (result != null) {
                                final file = File(result.files.single.path!);
                                setState(() {
                                  _uploadedVideos
                                      .add(file); // Add video to the list
                                });
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => TrimmerView(file),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Click on Upload video to get started',
                          style: TextStyle(fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              // Card for displaying user reels
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: Colors.grey[200],
                  margin: EdgeInsets.zero, // Set margin to zero
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox.expand(
                      // Ensure full width is used
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          if (_userReels.isEmpty)
                            const Text(
                              "No reels yet.",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            )
                          else
                            // ListView to show user reels
                            Expanded(
                              child: ListView.builder(
                                itemCount: _userReels.length,
                                itemBuilder: (context, index) {
                                  final reel = _userReels[index];
                                  return Card(
                                    margin: const EdgeInsets.only(
                                        bottom:
                                            10), // Margin for individual reels
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(
                                              Configuration.WEB_URL +
                                                  reel['screenshot'],
                                              width: 90, // Thumbnail width
                                              height: 90, // Thumbnail height
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      _formatDate(
                                                          reel['created_at']),
                                                      style: const TextStyle(
                                                          fontSize: 14),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.grey),
                                                      onPressed: () {
                                                        _deleteReel(reel['id']
                                                            .toString());
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const FaIcon(
                                                            FontAwesomeIcons
                                                                .heart,
                                                            size: 16),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                            '${reel['likes']}'),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Row(
                                                      children: [
                                                        const FaIcon(
                                                            FontAwesomeIcons
                                                                .share,
                                                            size: 16),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                            '${reel['shares']}'),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                            Icons.comment,
                                                            size: 16),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                            '${reel['comments']?.length ?? 0}'),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
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
      );

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final formatter =
          DateFormat('MMMM d, yyyy HH:mm'); // Use 'HH' for 24-hour format
      return formatter.format(date);
    } catch (e) {
      print("Error formatting date: $e");
      return dateStr;
    }
  }
}
