import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();
  int _currentPageIndex = 0;
  List<Video> videos = [];

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    final postData = {'key': 'value'};
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
              comments: video['comments'],
            );
          }).toList();
        });
      }
    }
  }

  void _showVideoOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ListTile(
                leading: Icon(Icons.fiber_manual_record, color: Colors.red),
                title: Text('Live'),
                onTap: () {
                  Navigator.of(context).pop();
                  _recordVideo();
                },
              ),
              ListTile(
                leading: Icon(Icons.video_library),
                title: Text('Add Video'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickVideoFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _recordVideo() async {
    final XFile? videoFile = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: Duration(minutes: 5),
    );

    if (videoFile != null) {
      final file = File(videoFile.path);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TrimmerView(file),
        ),
      );
    }
  }

  Future<void> _pickVideoFromGallery() async {
    final XFile? videoFile = await _picker.pickVideo(source: ImageSource.gallery);

    if (videoFile != null) {
      final file = File(videoFile.path);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TrimmerView(file),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 35.0),
        child: FloatingActionButton(
          onPressed: _showVideoOptions,
          backgroundColor: Colors.purple,
          child: FaIcon(
            FontAwesomeIcons.plus,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
            },
            itemBuilder: (context, index) {
              final video = videos[index];
              return VlcPlayerWidget(
                videoUrl: video.url,
                user: video.user,
                caption: video.caption,
                likes: video.likes.toString(),
                shares: video.shares.toString(),
                comments: video.comments,
                videoID: video.id,
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

  VlcPlayerWidget({
    required this.videoID,
    required this.videoUrl,
    required this.user,
    required this.caption,
    required this.likes,
    required this.shares,
    required this.comments,
  });

  @override
  _VlcPlayerWidgetState createState() => _VlcPlayerWidgetState();
}

class _VlcPlayerWidgetState extends State<VlcPlayerWidget> {
  late VlcPlayerController _vlcPlayerController;
  bool _isMuted = false;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
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
      // Handle video end
    }
  }

  @override
  void dispose() {
    _vlcPlayerController.removeListener(_onPlayerStateChange);
    _vlcPlayerController.dispose();
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
    return Stack(
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
                    MaterialPageRoute(builder: (context) => DashBoardPage()),
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
      ],
    );
  }
}
