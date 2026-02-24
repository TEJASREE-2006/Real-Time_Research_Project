// profile_page.dart
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String userName;
  final String email;

  const ProfilePage({super.key, required this.userName, required this.email});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // You can add bio or profile picture URL here as well if needed
  String bio = "Welcome to VidGenie! Create AI-powered videos effortlessly.";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings if any
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=150&q=80', // beautiful flower image
              ),
            ),

            const SizedBox(height: 20),

            // User Name (dynamic)
            Text(
              widget.userName,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            // Email (dynamic)
            Text(
              widget.email,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 20),

            // Bio
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                bio,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.left,
              ),
            ),

            const SizedBox(height: 40),

            // Edit Profile Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // TODO: Navigate to Edit Profile page
                },
              ),
            ),

            const SizedBox(height: 15),

            // Log Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.indigo),
                label: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.indigo),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.indigo),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // TODO: Implement log out logic
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
