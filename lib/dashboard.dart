import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutterapplicationwithnodejs/FloatingActionBar.dart';
import 'package:flutterapplicationwithnodejs/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // This is the same backend base URL used by the login page.
  // 10.0.2.2 is used because the Android emulator needs this special address
  // to reach localhost on your computer.
  final String baseUrl = 'http://10.0.2.2:5000/api/auth';

  // Stores the logged-in user's details returned by GET /api/auth/me.
  // The backend returns keys like name, email, and phonenumber.
  Map<String, dynamic>? _user;

  // Stores an error message if loading the profile fails.
  String? _error;

  // Controls whether the loading spinner or the profile details are shown.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Load the current user's profile as soon as the dashboard opens.
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      // The token was saved in SharedPreferences after login/register.
      // It is needed so the backend knows which user is requesting /me.
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No saved login token');
      }

      // Ask the backend for the current user's details.
      // Authorization: Bearer <token> sends the JWT to the protected route.
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // The backend sends JSON, so decode it into a Dart map.
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save the user details in state so the UI rebuilds and displays them.
        setState(() {
          _user = data;
          _isLoading = false;
        });
      } else {
        // If the server returns an error, show its message if available.
        throw Exception(data['message'] ?? 'Failed to load user');
      }
    } catch (e) {
      // Any network, JSON, or auth error ends up here and is shown on screen.
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> logout(BuildContext context) async {
    // Remove the saved JWT so the app no longer treats the user as logged in.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    // Send the user back to the login page and remove dashboard from history.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      //app bar
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      
      //floating action button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your action here
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.black, // Set the background color of the FAB
        foregroundColor: Colors.white, // Set the icon color of the FAB
        // elevation: 6.0, // Set the elevation of the FAB
        shape: const CircleBorder(), // Set the shape of the FAB
     ),


      //bottom navigation bar
      bottomNavigationBar: BottomAppBar(
        notchMargin: 6.0,
        shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            Expanded(
              child: IconButton(
                iconSize: 32,
                icon: const Icon(Icons.restaurant_menu),
                onPressed: () {Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Floatingactionbar(),
                    ),
                  );
                },
              ),
            ),

            const VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 10,
              endIndent: 10,
            ),

            Expanded(
              child: IconButton(
                iconSize: 32,
                icon: const Icon(Icons.home),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Dashboard(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
      
      body: Center(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    // While /me is loading, show a spinner instead of empty content.
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    // If loading failed, show the error message in the dashboard body.
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_error!, textAlign: TextAlign.center),
      );
    }

    // Use fallback text so the UI does not crash if a field is missing.
    final name = _user?['name'] ?? 'Unknown';
    final email = _user?['email'] ?? 'Unknown';
    final phone = _user?['phonenumber'] ?? 'Unknown';

    // Display the profile values loaded from the backend.
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text('Name: $name', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          Text('Phone: $phone', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          Text('Email: $email', style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
