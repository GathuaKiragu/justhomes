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
import 'package:just_apartment_live/ui/reels/trimmer_view.dart';
import 'package:just_apartment_live/ui/reelsplayer/video.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

import '../login/login.dart';
import '../reels/comment.dart';


final logger = Logger();


// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_vlc_player/flutter_vlc_player.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:just_apartment_live/models/configuration.dart';
// import 'package:just_apartment_live/ui/dashboard/dashboard_page.dart';
// import 'package:just_apartment_live/ui/reels/trimmer_view.dart';
// import 'package:just_apartment_live/ui/reelsplayer/video.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:logger/logger.dart';
// import '../login/login.dart';

// final logger = Logger();

class ReelsPage extends StatefulWidget {
  @override
  _ReelsPageState createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();
  int _currentPageIndex = 0;
  List<Video> videos = [];
  bool _hasLoggedIn = false;
  int _userID = 0;
  String username = '';

  @override
  void initState() {
    super.initState();
    _checkCachedVideos(); 
    _fetchVideos();
    _loadUser();
  }

  Future<void> _loadUser() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    if (user.isNotEmpty) {
      setState(() {
        _hasLoggedIn = true;
        _userID = user['id'];
        username = user['name'];
      });
    }
  }

  Future<void> _checkCachedVideos() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    bool isConnected = connectivityResult != ConnectivityResult.none;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedVideos = prefs.getString('cachedVideos');
    
    if (cachedVideos != null) {
      setState(() {
        videos = (json.decode(cachedVideos) as List)
            .map((videoData) => Video.fromJson(videoData))
            .toList();
      });
      logger.i("Loaded cached videos, count: ${videos.length}");
    }

    if (isConnected) {
      await _fetchVideos();
    } else if (cachedVideos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No internet connection")),
      );
    }
  }

  Future<void> _fetchVideos() async {
    try {
      final postData = {'key': 'value'};
      final response = await http.post(
        Uri.parse('${Configuration.API_URL}reels/get-videos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<Video> newVideos = (data['data'] as List).map((video) {
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

          setState(() {
            videos = newVideos;
          });

          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('cachedVideos', json.encode(newVideos.map((video) => video.toJson()).toList()));
          logger.i("Caching videos, count: ${newVideos.length}");
        }
      } else {
        logger.e("Failed to fetch videos, status code: ${response.statusCode}");
      }
    } catch (e) {
      logger.e("Error fetching videos: $e");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final video = videos[index];
              return CachedVlcPlayerWidget(
                videoID: video.id,
                 username: username,
                videoUrl: video.url,
                user: video.user,
                caption: video.caption,
                likes: video.likes.toString(),
                shares: video.shares.toString(),
                comments: video.comments,
              );
            },
          ),
        ],
      ),
    );
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
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ListTile(
                  leading: Icon(Icons.fiber_manual_record, color: Colors.red),
                  title: Text('Live'),
                  onTap: () {
                    // Navigator.of(context).pop();
                    // 
                      _hasLoggedIn?
                  {
            
                     Navigator.of(context).pop(),
                    _recordVideo()
                  }:
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Please log in or create an account first', style: TextStyle(
                                                    fontSize: 15
            
                          ),),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginPage(),
                                  ),
                                );
                              },
                              child: Text('Log in'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.video_library),
                  title: Text('Add Video'),
                  onTap: () {
                  _hasLoggedIn?
                  {
            
                     Navigator.of(context).pop(),
                    _pickVideoFromGallery()
                  }:
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Please log in or create an account first',  style: TextStyle(
                            fontSize: 15
                          ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginPage(),
                                  ),
                                );
                              },
                              child: Text('Log in'),
                            ),
                          ],
                        );
                      },
                    );
              
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
  Future<void> _recordVideo() async {
    final XFile? videoFile = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: Duration(minutes: 5),
    );

    if (videoFile != null) {
      final file = File(videoFile.path);
      logger.i("videoFile.path: ${videoFile.path}");
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TrimmerView(file, isLiveVideo: true,),
        ),
      );
    }
  }

  Future<void> _showLoginPrompt() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Please log in or create an account first', style: TextStyle(fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
              },
              child: Text('Log in'),
            ),
          ],
        );
      },
    );
  }
}
 
 

class CachedVlcPlayerWidget extends StatefulWidget {
  final int videoID;
  final String videoUrl;
  final String user;
  final String caption;
  final String likes;
  final String shares;
  final String  username;
  final List comments;

  CachedVlcPlayerWidget({
    required this.videoID,
    required this.videoUrl,
    required this.user,
    required this.caption,
    required this.likes,
    required this.shares,
    required this.username,
    required this.comments,
  });

  @override
  _CachedVlcPlayerWidgetState createState() => _CachedVlcPlayerWidgetState();
}

class _CachedVlcPlayerWidgetState extends State<CachedVlcPlayerWidget> {
  late VlcPlayerController _vlcPlayerController;
  bool _isMuted = false;
  bool _isPlaying = true;
  File? _cachedFile;
  bool _isLiked = false;
  late int _likesCount;
  late int _shareCount;
    bool _hasLoggedIn = false;
    int?  _userID = 0;
    String userName = ''  ;

  @override
  void initState() {
    super.initState();
    _likesCount = int.parse(widget.likes);
    _shareCount = int.parse(widget.shares);
    _loadUser();
    _loadVideo();
    _loadLikeStatus();
    
  }

  Future<void> _loadVideo() async {
    final cachedFile = await DefaultCacheManager().getSingleFile(widget.videoUrl);
    _cachedFile = cachedFile;
    _vlcPlayerController = VlcPlayerController.file(
      _cachedFile!,
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
    // Add logic here to update the like status on a server or database if required
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

    Future<void> _loadUser() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');
    print('User Details: $user');
    print('User id: ${user['id']}');



    if (user.isEmpty) {
      setState(() {
        _hasLoggedIn = false;
        _userID = user['id'];
        userName = '';
      });

    } else {
      setState(() {
        _hasLoggedIn = true;
        _userID = user['id'];
        userName = user['name'];
      });
    }
   
  }

void _showCommentsBottomSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,  
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.4,  
      maxChildSize: 0.4, 
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,  
          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),  
          boxShadow: [  
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: CommentsWidget(
          username: widget.username,
          videoID: widget.videoID,
          comments: widget.comments,
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _togglePlayPause,
            child: _cachedFile == null
                ? Center(child: CircularProgressIndicator())
                : VlcPlayer(
                    controller: _vlcPlayerController,
                    aspectRatio: MediaQuery.of(context).size.aspectRatio,
                    placeholder: Center(child: CircularProgressIndicator()),
                  ),
          ),
        ),
        if (!_isPlaying)
          Center(
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 80,
            ),
          ),
        _buildInteractiveLayer(),
      ],
    );
  }
  Future<void> _showLoginPrompt() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Please log in or create an account first', style: TextStyle(fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
              },
              child: Text('Log in'),
            ),
          ],
        );
      },
    );
  }
  Widget _buildInteractiveLayer() {
    return Positioned(
      bottom: 55,
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
            'Likes: $_likesCount',
            style: TextStyle(color: Colors.white),
          ),
          IconButton(
            icon: Icon(Icons.comment, color: Colors.white),
            onPressed: () {
              if (widget.username.isEmpty) {
                _showLoginPrompt();
              } else {
                _showCommentsBottomSheet();
              }
            },
          ),
          IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
            ),
            onPressed: _toggleMute,
          ),
          IconButton(
            icon: FaIcon(FontAwesomeIcons.share, color: Colors.white),
            onPressed: _shareVideo,
          ),
          Text(
            'Shares: $_shareCount',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _vlcPlayerController.removeListener(_onPlayerStateChange);
    _vlcPlayerController.dispose();
    super.dispose();
  }
}
