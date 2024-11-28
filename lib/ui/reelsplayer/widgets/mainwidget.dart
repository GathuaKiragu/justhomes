import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:full_picker/full_picker.dart';
import 'package:just_apartment_live/ui/reelsplayer/widgets/image.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

final logger = Logger();

Column likeShareCommentSave(var likes, var comments, var shares,
    BuildContext ctx, var commentList, String filepath) {
  return Column(
    children: [
      iconDetail(CupertinoIcons.heart, likes.toString(), () {
        print("I was liked");
      }),
      const SizedBox(height: 25),
      iconDetail(CupertinoIcons.chat_bubble, comments.toString(), () {
        print("I was commented");
        showCommentsDialog(ctx, commentList);
      }),
      const SizedBox(height: 25),
      iconDetail(CupertinoIcons.arrow_turn_up_right, shares.toString(),
          () async {
        print("I was shared");
        if (await File(filepath).exists()) {
          // Share the video file
          logger.i("ERROR ! ------>  $filepath");
          XFile videoFile = XFile(filepath);

          await Share.shareXFiles([videoFile],
              text: 'Check out this cool just homes video!');
        } else {
          // Show an error message if file doesn't exist
          logger.e("ERROR ! ------>  $filepath");
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('Video file not found!')),
          );
        }
      }),
      const SizedBox(height: 25),
      const Icon(CupertinoIcons.ellipsis_vertical,
          size: 22, color: Colors.white),
    ],
  );
}

Widget postComment(String time, String postComment, String profileName,
    String profileImage, int likeCount) {
  return Padding(
    padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CircleAvatar(
          maxRadius: 16,
          backgroundImage:
              NetworkImage(profileImage), // Recommended for circular images
          child: profileImage == null
              ? Icon(Icons.person) // Fallback if no image is available
              : null,
        ),
        SizedBox(width: 16.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profileName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      postComment,
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.0),
            Row(
              children: [
                Text(time, style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(width: 1),
                InkWell(
                  onTap: () {},
                  child: Text('$likeCount'),
                ),
                SizedBox(width: 1),
              ],
            ),
          ],
        )
      ],
    ),
  );
}

void showCommentsDialog(BuildContext context, var comments) {
  TextEditingController _controller = TextEditingController();

  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display existing comments
            Center(child: Text("Comments")),
            Expanded(
              child: comments.isEmpty
                  ? Center(child: Text("No comments"))
                  : ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (BuildContext context, int index) {
                        final comment = comments[index];
                        return postComment(
                          timeago.format(DateTime.parse(comment['created_at'])),
                          comment['comment'],
                          comment['user'] ?? 'User1',
                          'https://xsgames.co/randomusers/assets/avatars/male/51.jpg',
                          comments.length,
                        );
                      },
                    ),
            ),
            // Input field to add new comment
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 16.0),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        // Handle comment submission (you might want to add the comment to your database here)
                        comments.add({
                          'comment': _controller.text,
                          'user':
                              'Current User', // Replace with actual user info
                          'created_at': DateTime.now().toIso8601String(),
                        });
                        _controller.clear(); // Clear input field
                        Navigator.pop(
                            context); // Close the dialog after submitting
                        showCommentsDialog(
                            context, comments); // Refresh the comment list
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> updateLikes(int like, int videoId, int user_id) async {
  var url =
      "https://justhomes.co.ke/api/reels/update-likes?likes=$like&videoId=$videoId&user_id=$user_id";
  try {
    final response = await http.post(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        // likes = int.parse(data['likes']);
        // shares = data['shares'];
        print("Likes updated successfully!");
      }
    } else {
      print("Failed to update likes: ${response.body}");
    }
  } catch (e) {
    print("Error: $e");
  }
}

Widget iconDetail(IconData icon, String number, VoidCallback onPressed) {
  return GestureDetector(
    onTap: onPressed, // Trigger onPressed callback when tapped
    child: Column(
      children: [
        Icon(icon, size: 33, color: Colors.white),
        Text(
          number,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

class CommentWithPublisher extends StatefulWidget {
  final String userName;
  final String imageProfile;
  final String description;

  const CommentWithPublisher(
      {super.key,
      required this.userName,
      required this.imageProfile,
      required this.description});

  @override
  _CommentWithPublisherState createState() => _CommentWithPublisherState();
}

class _CommentWithPublisherState extends State<CommentWithPublisher> {
  @override
  Widget build(BuildContext context) => Column(children: [
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            children: [
              const Icon(CupertinoIcons.arrow_left, color: Colors.white),
              const Text(
                'Just Homes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(CupertinoIcons.camera, color: Colors.white),
                onPressed: () {
                  FullPicker(
                    context: context,
                    prefixName: 'just hones',
                    file: false,
                    voiceRecorder: false,
                    video: true,
                    videoCamera: true,
                    imageCamera: true,
                    imageCropper: true,
                    multiFile: false,
                    url: false,
                    onError: (final int value) {
                      if (kDebugMode) {
                        print(' ----  onError ----=$value');
                      }
                    },
                    onSelected: (final FullPickerOutput value) async {
                      if (kDebugMode) {
                        print(' ----  onSelected ----');
                      }
                      setState(() {});
                    },
                  );
                },
              )
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 40.0,
          ),
        ),
      ]);
}
