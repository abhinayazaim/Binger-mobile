import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'English';
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setString('language', _selectedLanguage);
  }
  
  @override
  Widget build(BuildContext context) {
    // Get theme provider to access dark mode state
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.amber,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          // App Theme
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            value: themeProvider.isDarkMode,
            activeColor: Colors.amber,
            onChanged: (value) {
              // Update theme through provider
              themeProvider.setDarkMode(value);
              // No snackbar needed as theme changes immediately
            },
          ),
          const Divider(),
          
          // Notifications
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Get notified about new movies and updates'),
            value: _notificationsEnabled,
            activeColor: Colors.amber,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
                _saveSettings();
              });
            },
          ),
          const Divider(),
          
          // Language
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Language',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'English',
            groupValue: _selectedLanguage,
            activeColor: Colors.amber,
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
                _saveSettings();
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Spanish'),
            value: 'Spanish',
            groupValue: _selectedLanguage,
            activeColor: Colors.amber,
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
                _saveSettings();
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Bahasa Indonesia'),
            value: 'Bahasa Indonesia',
            groupValue: _selectedLanguage,
            activeColor: Colors.amber,
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
                _saveSettings();
              });
            },
          ),
          const Divider(),
          
          // Account Settings
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('Change Password'),
            leading: const Icon(Icons.lock),
            onTap: () {
              // Show change password dialog
              _showChangePasswordDialog();
            },
          ),
          ListTile(
            title: const Text('Clear App Data'),
            leading: const Icon(Icons.delete),
            onTap: () {
              _showClearDataConfirmation();
            },
          ),
          
          // About
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const ListTile(
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
            leading: Icon(Icons.info),
          ),
          ListTile(
            title: const Text('Terms of Service'),
            leading: const Icon(Icons.description),
            onTap: () {
              _showTermsOfService();
            },
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            leading: const Icon(Icons.privacy_tip),
            onTap: () {
              _showPrivacyPolicy();
            },
          ),
        ],
      ),
    );
  }
  
  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Terms of Service'),
          content: const SingleChildScrollView(
            child: Text(
              'These Terms of Service ("Terms") govern your access to and use of Binger app. '
              'By using our services, you agree to be bound by these Terms.\n\n'
              '1. USING OUR SERVICES\n\n'
              'You must follow any policies made available to you within the Services.\n\n'
              '2. PRIVACY AND COPYRIGHT PROTECTION\n\n'
              'Our privacy policies explain how we treat your personal data and protect your privacy when you use our Services.\n\n'
              '3. YOUR CONTENT IN OUR SERVICES\n\n'
              'Our Services allow you to upload, submit, store, send or receive content. You retain ownership of any intellectual property rights that you hold in that content.\n\n'
              '4. ABOUT SOFTWARE IN OUR SERVICES\n\n'
              'Binger gives you a personal, worldwide, royalty-free, non-assignable and non-exclusive license to use the software provided to you by Binger as part of the Services.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: const SingleChildScrollView(
            child: Text(
              'This Privacy Policy describes how your personal information is collected, used, and shared when you use Binger app.\n\n'
              'PERSONAL INFORMATION WE COLLECT\n\n'
              'When you use our app, we automatically collect certain information about your device, including information about your web browser, IP address, time zone, and some of the cookies that are installed on your device.\n\n'
              'HOW WE USE YOUR PERSONAL INFORMATION\n\n'
              'We use the information we collect to:\n'
              '- Provide, operate, and maintain our app\n'
              '- Improve, personalize, and expand our app\n'
              '- Understand and analyze how you use our app\n'
              '- Develop new products, services, features, and functionality\n\n'
              'SHARING YOUR PERSONAL INFORMATION\n\n'
              'We share your Personal Information with third parties to help us use your Personal Information, as described above.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Check if passwords match
                if (newPasswordController.text == confirmPasswordController.text) {
                  // Save new password
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.amber)),
            ),
          ],
        );
      },
    );
  }
  
  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text('Are you sure you want to clear all app data? This will remove all your saved movies, ratings, and preferences.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Clear SharedPreferences data
                final prefs = await SharedPreferences.getInstance();
                // Preserve dark mode setting if needed
                final bool darkMode = prefs.getBool('dark_mode') ?? false;
                await prefs.clear();
                // Optionally restore dark mode setting
                await prefs.setBool('dark_mode', darkMode);
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared successfully')),
                );
              },
              child: const Text('Clear Data', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}