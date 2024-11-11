import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

import 'package:http/http.dart' as http;
import 'package:just_apartment_live/models/configuration.dart';

import '../reelsplayer/video.dart';
 

 

class ReelDetailPage extends StatefulWidget {
  final int videoID;
  final String videoUrl;
  final String user;
  final String caption;
  final int likes;
  final int shares;
  final List comments;

  ReelDetailPage({
    required this.videoID,
    required this.videoUrl,
    required this.user,
    required this.caption,
    required this.likes,
    required this.shares,
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
              child: Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: VlcPlayer(
                    controller: _vlcPlayerController,
                    aspectRatio: MediaQuery.of(context).size.aspectRatio,
                    placeholder: Center(child: CircularProgressIndicator()),
                  ),
                ),
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
          ],
        ),
      ),
    );
  }
}
