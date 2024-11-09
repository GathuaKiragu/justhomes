import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
import 'package:just_apartment_live/ui/login/login.dart';
import 'package:just_apartment_live/ui/reels/trimmer_view.dart';
import 'package:just_apartment_live/ui/reelsplayer/comment_popup.dart';
import 'package:just_apartment_live/ui/reelsplayer/video.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReelsPage extends StatefulWidget {
  @override
  _ReelsPageState createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  List<Video> videos = [];

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    // Define the data you want to send in the POST request
    final postData = {
      'key': 'value', // replace 'key' and 'value' with actual parameters
    };

    final response = await http.post(
      Uri.parse('https://justhomes.co.ke/api/reels/get-videos'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(postData),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          videos = (data['data'] as List).map((video) {
            return Video(
                id: video['id'],
                url: 'https://justhomes.co.ke/${video['video_path']}',
                user: video['user']['name'],
                caption: video['description'] ?? '',
                likes: video['likes'],
                shares: video['shares'],
                comments: video['comments']);
          }).toList();
        });
      }
    } else {
      // Handle the error, show a snackbar or something similar
    }
  }

  Future<void> _fetchDetailsForCurrentVideo(String videoId) async {}

  void _onVideoEnd() {
    if (_currentPageIndex < videos.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _pageController.animateToPage(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  Future<void> _pickVideo() async {
    // Request permission to access storage
    var status = await Permission.storage.request();
    if (status.isGranted) {
      // If permission is granted, pick the video file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowCompression: false,
      );
      if (result != null) {
        final file = File(result.files.single.path!);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TrimmerView(file),
          ),
        );
      }
    } else {
      // Handle the case when permission is denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission to access storage denied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding:
            const EdgeInsets.only(bottom: 35.0), // Adjust this value as needed
        child: FloatingActionButton(
          onPressed: _pickVideo,
          backgroundColor: Colors.purple, // Set the background color to purple
          child: FaIcon(
            FontAwesomeIcons.plus, // Use the Font Awesome video icon
            color: Colors.white, // Set the icon color to white
          ),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Optional: Center the FAB

      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            onPageChanged: (index) async {
              setState(() {
                _currentPageIndex = index;
              });

              await _fetchDetailsForCurrentVideo(videos[index].id.toString());
            },
            itemBuilder: (context, index) {
              final video = videos[index];
              return Stack(
                children: [
                  VlcPlayerWidget(
                    videoUrl: video.url,
                    user: video.user,
                    caption: video.caption,
                    likes: video.likes.toString(),
                    shares: video.shares.toString(),
                    onVideoEnd: _onVideoEnd,
                    comments: video.comments,
                    videoID: video.id,
                    // aspectRatio: 16/9, // You can adjust this to maintain the aspect ratio
                  ),
                  Positioned(
                    bottom: 55,
                    left: 20,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '@${video.user}\n',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: '${video.caption}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class VlcPlayerWidget extends StatefulWidget {
  final int videoID;
  final String videoUrl;
  final String user;
  final String caption;
  final String likes;
  final String shares;
  final List comments;
  final VoidCallback onVideoEnd;

  VlcPlayerWidget({
    required this.videoID,
    required this.videoUrl,
    required this.user,
    required this.caption,
    required this.likes,
    required this.shares,
    required this.comments,
    required this.onVideoEnd,
  });

  @override
  _VlcPlayerWidgetState createState() => _VlcPlayerWidgetState();
}

class _VlcPlayerWidgetState extends State<VlcPlayerWidget> {
  late VlcPlayerController _vlcPlayerController;
  bool _isMuted = false;
  bool _isPlaying = true;
  Duration _videoDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  late Timer _positionTimer;

  late int _likesCount;
  late int _shareCount;

  ///NEW
  bool _isLiked = false;

  void _loadLikeStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isLiked = prefs.getBool('isLiked_${widget.videoID}') ?? false;
    _likesCount = _isLiked ? (_likesCount + 1) : _likesCount;
    setState(() {});
  }

  // void _toggleLike() async {
  //   setState(() {
  //     if (_isLiked) {
  //       _likesCount--; // Decrease like count
  //     } else {
  //       _likesCount++; // Increase like count
  //     }
  //     _isLiked = !_isLiked;
  //   });
  //
  //   // Send updated likes status to server
  //   await _sendLikesToServer(_likesCount);
  // }


  void _toggleLike() async {
    setState(() {
      if (_isLiked) {
        _likesCount--; // Decrease like count
      } else {
        _likesCount++; // Increase like count
      }
      _isLiked = !_isLiked;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLiked_${widget.videoID}', _isLiked);

    // Send updated likes status to server
    await _sendLikesToServer(_likesCount);
  }
  void _incrementLikes() async {
    setState(() {
      _likesCount++; // Increment likes locally
    });
    // Send the updated likes count to the server
    await _sendLikesToServer(_likesCount);
  }

  // Simulated method to send likes to server
  Future<bool> _sendLikesToServer(int likesCount) async {
    try {
      // Retrieve user details from SharedPreferences
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = json.decode(localStorage.getString('user') ?? '{}');

      final uri =
          '${Configuration.API_URL}reels/update-likes'; // Ensure this URL is correct

      // Make the API call
      final response = await http.post(
        Uri.parse(uri),
        headers: {
          'Content-Type': 'application/json', // Set content type to JSON
        },
        body: json.encode({
          'likes': likesCount,
          'videoId': widget.videoID, // Ensure this is defined in your widget
          'user_id': user['id'], // Ensure user['id'] is valid
        }),
      );

      print("Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        // Handle success
        return true;
      } else {
        // Handle failure (you can print or log the error response)
        print("Failed to update likes: ${response.body}");
        return false;
      }
    } catch (e) {
      // Handle exceptions (e.g., network errors)
      print("Error sending likes: $e");
      return false;
    }
  }

  Future<bool> _sendShareToServer(int _shareCount) async {
    try {
      // Retrieve user details from SharedPreferences
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = json.decode(localStorage.getString('user') ?? '{}');

      final uri =
          '${Configuration.API_URL}reels/update-shares'; // Ensure this URL is correct

      // Make the API call
      final response = await http.post(
        Uri.parse(uri),
        headers: {
          'Content-Type': 'application/json', // Set content type to JSON
        },
        body: json.encode({
          'shares': _shareCount,
          'videoId': widget.videoID, // Ensure this is defined in your widget
          'user_id': user['id'], // Ensure user['id'] is valid
        }),
      );

      print("Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        // Handle success
        return true;
      } else {
        // Handle failure (you can print or log the error response)
        print("Failed to update likes: ${response.body}");
        return false;
      }
    } catch (e) {
      // Handle exceptions (e.g., network errors)
      print("Error sending likes: $e");
      return false;
    }
  }

  Future<bool> _getLikesStatus(String videoId) async {
    try {
      final uri =
          '${Configuration.API_URL}reels/get-likes-status'; // Ensure this URL is correct

      // Make the API call
      final response = await http.post(
        Uri.parse(uri),
        headers: {
          'Content-Type': 'application/json', // Set content type to JSON
        },
        body: json.encode({
          'videoId': videoId, // Ensure this is defined in your widget
        }),
      );

      print("Response init: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        // Parse the response body
        final data = json.decode(response.body);

        // Assign the values to the variables
        _likesCount = data['likes'] ??
            0; // Use null-aware operator to provide a default value
        _shareCount = data['shares'] ??
            0; // Use null-aware operator to provide a default value

        return true;
      } else {
        // Handle failure (you can print or log the error response)
        print("Failed to get likes status: ${response.body}");
        return false;
      }
    } catch (e) {
      // Handle exceptions (e.g., network errors)
      print("Error getting likes status: $e");
      return false;
    }
  }

  @override
  void initState() {
    _likesCount = int.parse(widget.likes);
    _shareCount = int.parse(widget.shares);

    _getLikesStatus(widget.videoID.toString());
    _loadLikeStatus();

    super.initState();
    _vlcPlayerController = VlcPlayerController.network(
      widget.videoUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );

    _vlcPlayerController.addListener(_onPlayerStateChange);

    // Periodically update video position
    _positionTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (_vlcPlayerController.value.isInitialized) {
        _updateVideoPosition();
      }
    });
  }

  void _onPlayerStateChange() {
    if (_vlcPlayerController.value.isEnded) {
      widget.onVideoEnd();
    }
  }

  void _updateVideoPosition() {
    setState(() {
      _currentPosition = _vlcPlayerController.value.position;
      _videoDuration = _vlcPlayerController.value.duration;
    });
  }

  @override
  void dispose() {
    _vlcPlayerController.removeListener(_onPlayerStateChange);
    _positionTimer.cancel();
    _vlcPlayerController.dispose();
    super.dispose();
  }

  void _seek(double value) {
    final positionInMillis =
        value.toInt() * 1000; // Convert seconds to milliseconds
    _vlcPlayerController.setTime(positionInMillis);
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _vlcPlayerController.setVolume(_isMuted ? 0 : 100);
    });
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _vlcPlayerController.pause();
      } else {
        _vlcPlayerController.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  ///NEW FUNCTION GATHUA
  ///
  ///
  Future<void> _shareVideo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasShared = prefs.getBool('hasShared_${widget.videoID}') ?? false;

    if (!hasShared) {
      prefs.setBool('hasShared_${widget.videoID}', true);
      // Increment share count on the server
      _sendShareToServer(_shareCount + 1);
    }

    Share.share(widget.videoUrl);
  }

  // void _shareVideo() {
  //   final String shareContent = '${widget.videoUrl}\n\n'
  //       'Check this out by @${widget.user}\n'
  //       'Description: ${widget.caption}';
  //   setState(() {
  //     _shareCount++; // Increment likes locally
  //   });
  //
  //   Share.share(shareContent);
  //   _sendShareToServer(_shareCount);
  // }

  void _checkLoginAndPerformAction(Function action) async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    if (user.isEmpty) {
      // Show login dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Login Required'),
          content: Text('Please log in to like or share the video.'),
          actions: [
            TextButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text('Login'),
            ),
          ],
        ),
      );
    } else {
      action(); // Proceed with the like/share action
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Toggle play/pause on tap
        _togglePlayPause();
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: VlcPlayer(
                controller: _vlcPlayerController,
                aspectRatio: 9 / 16,
                placeholder: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
          Stack(
            children: [
              // Your video player widget here
              Stack(
                children: [
                  // Your video player widget here
                  Positioned(
                    top: 60,
                    left: 15,
                    right: 15,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DashBoardPage(),
                              ),
                            );
                          },
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black54,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isMuted ? Icons.volume_off : Icons.volume_up,
                                  color: Colors.grey,
                                ),
                                onPressed: _toggleMute,
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 1.0,
                                    thumbShape: RoundSliderThumbShape(
                                      enabledThumbRadius: 1.0,
                                    ),
                                    overlayShape: RoundSliderOverlayShape(
                                      overlayRadius: 2.0,
                                    ),
                                  ),
                                  child: Slider(
                                    value:
                                        _currentPosition.inSeconds.toDouble(),
                                    max: _videoDuration.inSeconds.toDouble(),
                                    onChanged: (value) {
                                      _seek(value);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 260,
                    right: 20,
                    child: Column(
                      children: [
                        // Like Icon
                        IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons
                                .solidHeart, // Use solid heart for filled effect
                            color: _isLiked ? Colors.red : Colors.white, // Filled icon color
                            size: 24.0, // Adjusted size to be visible
                          ),

                          onPressed: () =>
                              _checkLoginAndPerformAction(_toggleLike),
                          // onPressed:
                          // _incrementLikes, // Function for liking video
                        ),
                        // Reduced spacing between icon and count
                        Text(
                          _likesCount
                              .toString(), // Replace with actual likes count
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold, // Bold text
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: 190,
                    right: 20,
                    child: Column(
                      children: [
                        // Comment Icon
                        IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons
                                .solidComment, // Use solid comment for filled effect
                            color: Colors.white, // Filled icon color
                            size: 24.0, // Adjusted size
                          ),
                          onPressed: () async {
                            SharedPreferences localStorage =
                                await SharedPreferences.getInstance();
                            var user = json
                                .decode(localStorage.getString('user') ?? '{}');

                            if (user.isEmpty) {
                              // Show login dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Login Required'),
                                  content: Text(
                                      'Please log in to like or share the video.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => LoginPage()),
                                        );
                                      },
                                      child: Text('Login'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return CommentPopup(
                                      comments: widget.comments,
                                      onCommentAdded: (String comment) {
                                        // Handle adding the comment logic here
                                        print("New Comment: $comment");
                                        // Optionally, update comments state or make an API call
                                      },
                                      videoID: widget.videoID.toString());
                                },
                              );
                            }
                          },
                        ),
                        SizedBox(
                            height:
                                2), // Reduced spacing between icon and count
                        Text(
                          widget.comments.length
                              .toString(), // Replace with actual comments count
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold, // Bold text
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: 120,
                    right: 20,
                    child: Column(
                      children: [
                        // Share Icon
                        IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons
                                .share, // Use solid share for filled effect
                            color: Colors.white, // Filled icon color
                            size: 24.0, // Adjusted size
                          ),
                          onPressed: () =>
                              _checkLoginAndPerformAction(_shareVideo),
                        ),
                        SizedBox(
                            height:
                                2), // Reduced spacing between icon and count
                        Text(
                          _shareCount.toString(), // Increment likes locally

                          // Replace with actual shares count
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold, // Bold text
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
