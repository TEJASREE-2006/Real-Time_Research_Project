// video_setup_page.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile_page.dart';

class VideoSetupPage extends StatefulWidget {
  const VideoSetupPage({super.key});

  @override
  State<VideoSetupPage> createState() => _VideoSetupPageState();
}

class _VideoSetupPageState extends State<VideoSetupPage> {
  String? selectedVoice;
  String? selectedStyle;
  final TextEditingController topicController = TextEditingController();

  final List<String> voiceOptions = ['Male', 'Female'];
  final List<String> styleOptions = [
    'Whiteboard Animation',
    'Infographic',
    'Storytelling',
  ];

  List<String> history = [];
  bool isLoading = false;
  String? videoUrl;
  VideoPlayerController? _videoPlayerController;
  bool isVideoPlaying = false;

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    topicController.dispose();
    super.dispose();
  }

  Future<void> _generateVideo() async {
    String voice = selectedVoice ?? '';
    String style = selectedStyle ?? '';
    String topic = topicController.text.trim();

    if (voice.isEmpty || style.isEmpty || topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      videoUrl = null;
    });

    try {
      String scriptText = '''
Plants are living organisms that belong to the Plantae kingdom. The evolution of plants has been a crucial part of environmental development. Planting more trees helps in maintaining the ecosystem and saves the environment from the harmful effects of global warming.

Plants also include various other types called bushes, green algae, mosses, vines, trees, herbs, etc. Botany is the study of plants and their features and characteristics.
''';

      // Step 2: Generate TTS audio
      final ttsRes = await http.post(
        Uri.parse("http://10.190.55.12:8000/api/text_to_speech_view/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"script": scriptText, "voice": voice}),
      );

      if (ttsRes.statusCode != 200) {
        throw Exception('TTS generation failed: ${ttsRes.body}');
      }

      final ttsData = jsonDecode(ttsRes.body);
      String audioUrl = ttsData["audio_file"];
      if (audioUrl.isEmpty) throw Exception('Audio URL is empty');

      // Step 3: Fetch images
      final imageRes = await http.post(
        Uri.parse("http://10.190.55.12:8000/api/fetch_unsplash_images/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"topic": topic}),
      );

      if (imageRes.statusCode != 200) {
        throw Exception('Image fetch failed: ${imageRes.body}');
      }

      final imageData = jsonDecode(imageRes.body);
      List<dynamic> imageUrls = imageData["image_urls"];
      if (imageUrls.isEmpty) throw Exception('No images found');

      // Step 4: Generate final video
      final videoRes = await http.post(
        Uri.parse("http://10.190.55.12:8000/api/generate_video/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "script": scriptText,
          "audio_url": audioUrl,
          "image_urls": imageUrls,
          "video_style": style,
        }),
      );

      if (videoRes.statusCode != 200) {
        throw Exception('Video generation failed: ${videoRes.body}');
      }

      final finalVideoData = jsonDecode(videoRes.body);
      videoUrl = finalVideoData["video_url"];

      if (_videoPlayerController != null) {
        await _videoPlayerController!.dispose();
      }

      _videoPlayerController = VideoPlayerController.network(videoUrl!)
        ..initialize().then((_) {
          setState(() {
            _videoPlayerController!.play();
            isVideoPlaying = true;
          });
        });

      if (!history.contains(topic)) {
        history.insert(0, topic);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _togglePlayPause() {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized)
      return;

    setState(() {
      if (isVideoPlaying) {
        _videoPlayerController!.pause();
      } else {
        _videoPlayerController!.play();
      }
      isVideoPlaying = !isVideoPlaying;
    });
  }

  void _showHistory() {
    if (history.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No history available')));
      return;
    }

    showModalBottomSheet(
      context: context,
      builder:
          (_) => ListView(
            padding: const EdgeInsets.all(16),
            children:
                history.map((topic) {
                  return ListTile(
                    title: Text(topic),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        topicController.text = topic;
                      });
                    },
                  );
                }).toList(),
          ),
    );
  }

  void _showProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ProfilePage(
              userName: "Teja Sree", // Replace with actual user name
              email: "teja@example.com", // Replace with actual email
            ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0FE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: _showHistory,
                      tooltip: 'View history',
                    ),
                    const Text(
                      'Create Your Video',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person),
                      onPressed: _showProfile,
                      tooltip: 'Profile',
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                DropdownButtonFormField<String>(
                  value: selectedVoice,
                  decoration: _dropdownDecoration('Select Voice'),
                  items:
                      voiceOptions.map((voice) {
                        return DropdownMenuItem(
                          value: voice,
                          child: Text(voice),
                        );
                      }).toList(),
                  onChanged: (value) => setState(() => selectedVoice = value),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: selectedStyle,
                  decoration: _dropdownDecoration('Select Video Style'),
                  items:
                      styleOptions.map((style) {
                        return DropdownMenuItem(
                          value: style,
                          child: Text(style),
                        );
                      }).toList(),
                  onChanged: (value) => setState(() => selectedStyle = value),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: topicController,
                        decoration: InputDecoration(
                          labelText: 'Enter Topic',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.mic),
                      tooltip: 'Use voice input',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Voice input not yet implemented'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: isLoading ? null : _generateVideo,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Generate Video',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                ),
                const SizedBox(height: 30),

                if (videoUrl != null &&
                    _videoPlayerController != null &&
                    _videoPlayerController!.value.isInitialized)
                  Column(
                    children: [
                      AspectRatio(
                        aspectRatio: _videoPlayerController!.value.aspectRatio,
                        child: VideoPlayer(_videoPlayerController!),
                      ),
                      IconButton(
                        icon: Icon(
                          isVideoPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.indigo,
                          size: 40,
                        ),
                        onPressed: _togglePlayPause,
                        tooltip: isVideoPlaying ? 'Pause' : 'Play',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
