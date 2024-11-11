import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_apartment_live/ui/reelsplayer/reels_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class ReelDetailPage extends StatefulWidget {
  final int videoID;
  final String videoUrl;
  final String user;
  final String caption;
  final int likes;
  final int shares;
  final int userID;  
  final List comments;

  ReelDetailPage({
    required this.videoID,
    required this.videoUrl,
    required this.user,
    required this.caption,
    required this.likes,
    required this.shares,
    required this.userID,
    required this.comments,
  });

  @override
  _ReelDetailPageState createState() => _ReelDetailPageState();
}

class _ReelDetailPageState extends State<ReelDetailPage> {
  late VlcPlayerController _vlcPlayerController;
  bool _isMuted = false;
  bool _isPlaying = true;
  bool _isLiked = false;
  late int _likesCount;
  late int _shareCount;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _likesCount = widget.likes;
    _shareCount = widget.shares;
    _loadVideo();
    _loadLikeStatus();
  }

  Future<void> _loadVideo() async {
    _vlcPlayerController = VlcPlayerController.network(
      widget.videoUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );

    _vlcPlayerController.addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (_vlcPlayerController.value.isEnded) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _toggleLike() async {
  setState(() {
    _isLiked = !_isLiked;
    _isLiked ? _likesCount++ : _likesCount--;
  });

  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('isLiked_${widget.videoID}', _isLiked);

  try {
    final userId = prefs.getInt('user_id') ?? 0; // Replace with actual user ID retrieval
    final url = Uri.parse('https://justhomes.co.ke/api/reels/update-likes?likes=$_likesCount&videoId=${widget.videoID}&user_id=${widget.userID}');
    final response = await http.post(url);

    if (response.statusCode == 200) {
      logger.i('Likes updated successfully on server ${response.body}');
    } else {
      print('Failed to update likes on server: ${response.body}');
    }
  } catch (e) {
    print('Error updating likes on server: $e');
  }
}


  Future<void> _postComment(String comment) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var user = json.decode(prefs.getString('user') ?? '{}');

      final url = Uri.parse(
        'https://justhomes.co.ke/api/reels/post-comment?videoID=${widget.videoID}&userID=${widget.userID}&comment=$comment',
      );

      final response = await http.post(url);

      if (response.statusCode == 200) {
        print("Comment posted successfully. Response: ${response.body}");
      } else {
        print("Failed to post comment: ${response.body}");
      }
    } catch (e) {
      print("Error posting comment: $e");
    }
  }

  void _showCommentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Post a Comment"),
        content: TextField(
          controller: _commentController,
          decoration: InputDecoration(hintText: "Enter your comment here"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _postComment(_commentController.text);
              _commentController.clear();
              Navigator.pop(context);
            },
            child: Text("Post"),
          ),
        ],
      ),
    );
  }

  Future<void> _shareVideo() async {
    setState(() {
      _shareCount++;
    });
    Share.share(widget.videoUrl);
  }

  Future<void> _loadLikeStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isLiked = prefs.getBool('isLiked_${widget.videoID}') ?? false;
    setState(() {});
  }

  @override
  void dispose() {
    _vlcPlayerController.removeListener(_onPlayerStateChange);
    _vlcPlayerController.dispose();
    _commentController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                color: Colors.black,
                child: VlcPlayer(
                  controller: _vlcPlayerController,
                  aspectRatio: MediaQuery.of(context).size.aspectRatio,
                  placeholder: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            if (!_isPlaying)
              GestureDetector(
                onTap: _togglePlayPause,
                child: Center(
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 55,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${widget.user}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    widget.caption,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
                  IconButton(
                    icon: FaIcon(
                      FontAwesomeIcons.solidHeart,
                      color: _isLiked ? Colors.red : Colors.white,
                    ),
                    onPressed: _toggleLike,
                  ),
                  Text(
                    _likesCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  IconButton(
                    icon: FaIcon(FontAwesomeIcons.share, color: Colors.white),
                    onPressed: _shareVideo,
                  ),
                  Text(
                    _shareCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 55,
              right: 20,
              child: IconButton(
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                ),
                onPressed: _toggleMute,
              ),
            ),
            Positioned(
              bottom: 160,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.comment, color: Colors.white),
                onPressed: _showCommentDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
