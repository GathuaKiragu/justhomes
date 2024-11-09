import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_apartment_live/models/configuration.dart';
import 'package:just_apartment_live/ui/reelsplayer/reels_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:path/path.dart';
import 'package:flutter/rendering.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class TrimmerView extends StatefulWidget {
  final File file;

  const TrimmerView(this.file, {Key? key}) : super(key: key);

  @override
  State<TrimmerView> createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  final _trimmer = Trimmer();
  final TextEditingController _descriptionController = TextEditingController();

  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;
  bool _progressVisibility = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  void _loadVideo() {
    _trimmer.loadVideo(videoFile: widget.file);
  }

  Future<File?> _captureScreenshot() async {
    final uint8List = await VideoThumbnail.thumbnailData(
      video: widget.file.path,
      imageFormat: ImageFormat.PNG,
      maxWidth: 1280, 
      quality: 75,
    );

    if (uint8List != null) {
      final filePath = '${widget.file.path}_thumbnail.png';
      final file = File(filePath);
      await file.writeAsBytes(uint8List);
      return file;
    }
    return null;
  }

  Future<void> _saveVideo(BuildContext context) async {
    setState(() {
      _progressVisibility = true;
    });

    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      // ffmpegCommand:
      //     '-vf "fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0',
      // customVideoFormat: '.gif',
      onSave: (String? outputPath) async {
        if (outputPath != null) {
          final directory = dirname(outputPath);
          final fileName = 'trimmed_video.mp4';
          final newFilePath = join(directory, fileName);

          final trimmedFile = File(newFilePath);
          await File(outputPath).copy(trimmedFile.path);
          await File(outputPath).delete();

          // Call upload video function
          await _uploadVideo(trimmedFile, _descriptionController.text, context);

          setState(() {
            _progressVisibility = false;
          });

          // Show success message (optional)
          final snackBar = SnackBar(
            content: Text('Video Saved successfully\n${trimmedFile.path}'),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          setState(() {
            _progressVisibility = false;
          });

          // Show error message
          _showErrorDialog('Failed to save video', context);
        }
      },
    );
  }

  Future<void> _uploadVideo(
      File videoFile, String description, BuildContext context) async {
    // Show loading dialog
    final loadingDialog = AlertDialog(
      content: Row(
        children: const [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Text('Uploading video...'),
        ],
      ),
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => loadingDialog,
    );

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    final uri = Uri.parse(Configuration.API_URL + 'reels/upload-video');

    final request = http.MultipartRequest('POST', uri)
      ..fields['user_id'] = user['id'].toString()
      ..fields['description'] = description
      ..files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
          filename: basename(videoFile.path),
        ),
      );

    // Capture the screenshot
    final screenshotFile = await _captureScreenshot();
    if (screenshotFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'screenshot', // Change the field name as required by your server
          screenshotFile.path,
          filename: basename(screenshotFile.path),
        ),
      );
    }

    try {
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        // Redirect to ReelsPage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) =>
                ReelsPage(), // Your ReelsPage widget
          ),
        );
      } else {
        _showErrorDialog('Failed to upload video: $responseData', context);
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog('Error uploading video: $e', context);
    }
  }

  void _showErrorDialog(String message, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Upload Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          if (Navigator.of(context).userGestureInProgress) {
            return false;
          } else {
            return true;
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Upload Reel'),
            backgroundColor: Colors.black,
          ),
          body: Center(
            child: Container(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Visibility(
                    visible: _progressVisibility,
                    child: const LinearProgressIndicator(
                      backgroundColor: Colors.red,
                    ),
                  ),
                  Expanded(child: VideoViewer(trimmer: _trimmer)),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TrimViewer(
                        trimmer: _trimmer,
                        viewerHeight: 50.0,
                        viewerWidth: MediaQuery.of(context).size.width,
                        durationStyle: DurationStyle.FORMAT_MM_SS,
                        maxVideoLength: const Duration(seconds: 140),
                        editorProperties: TrimEditorProperties(
                          borderPaintColor: Colors.yellow,
                          borderWidth: 4,
                          borderRadius: 5,
                          circlePaintColor: Colors.yellow.shade800,
                        ),
                        areaProperties:
                            TrimAreaProperties.edgeBlur(thumbnailQuality: 10),
                        onChangeStart: (value) => _startValue = value,
                        onChangeEnd: (value) => _endValue = value,
                        onChangePlaybackState: (value) => setState(
                          () => _isPlaying = value,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    child: _isPlaying
                        ? const Icon(
                            Icons.pause,
                            size: 50.0,
                            color: Colors.white,
                          )
                        : const Icon(
                            Icons.play_arrow,
                            size: 50.0,
                            color: Colors.white,
                          ),
                    onPressed: () async {
                      final playbackState = await _trimmer.videoPlaybackControl(
                        startValue: _startValue,
                        endValue: _endValue,
                      );
                      setState(() => _isPlaying = playbackState);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              hintText: 'Add a description...',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 20.0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _progressVisibility
                                ? null
                                : () => _saveVideo(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
