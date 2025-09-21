// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late SharedPreferences _prefs;
  final NotificationService _notificationService = NotificationService();

  // Notification preferences
  bool _communityNotifications = true;
  bool _feedNotifications = true;
  bool _likeNotifications = true;
  bool _commentNotifications = true;
  bool _newPostNotifications = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = _prefs.getString('name') ?? '';
      _emailController.text = _prefs.getString('email') ?? '';
      _communityNotifications =
          _prefs.getBool('community_notifications') ?? true;
      _feedNotifications = _prefs.getBool('feed_notifications') ?? true;
      _likeNotifications = _prefs.getBool('like_notifications') ?? true;
      _commentNotifications = _prefs.getBool('comment_notifications') ?? true;
      _newPostNotifications = _prefs.getBool('new_post_notifications') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setString('name', _nameController.text);
    await _prefs.setString('email', _emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('Common'),
            tiles: [
              SettingsTile.navigation(
                leading: Icon(Icons.language),
                title: Text('Language'),
                value: Text('English'),
              ),
              SettingsTile.switchTile(
                onToggle: (value) {},
                initialValue: true,
                leading: Icon(Icons.format_paint),
                title: Text('Enable custom theme'),
              ),
            ],
          ),
          SettingsSection(
            title: Text('Personal Information'),
            tiles: [
              SettingsTile(
                title: Text('Name'),
                value: Text(_nameController.text),
                onPressed: (BuildContext context) {
                  _showTextFieldDialog('Name', _nameController);
                },
              ),
              SettingsTile(
                title: Text('Email'),
                value: Text(_emailController.text),
                onPressed: (BuildContext context) {
                  _showTextFieldDialog('Email', _emailController);
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text('Notifications'),
            tiles: [
              SettingsTile.switchTile(
                onToggle: (value) async {
                  setState(() => _communityNotifications = value);
                  await _notificationService.updateNotificationPreference(
                      'community_notifications', value);
                },
                initialValue: _communityNotifications,
                leading: Icon(Icons.group),
                title: Text('Community Notifications'),
                description:
                    Text('Get notified about new communities and messages'),
              ),
              SettingsTile.switchTile(
                onToggle: (value) async {
                  setState(() => _feedNotifications = value);
                  await _notificationService.updateNotificationPreference(
                      'feed_notifications', value);
                },
                initialValue: _feedNotifications,
                leading: Icon(Icons.feed),
                title: Text('Feed Notifications'),
                description: Text('Get notified about new posts in the feed'),
              ),
              SettingsTile.switchTile(
                onToggle: (value) async {
                  setState(() => _likeNotifications = value);
                  await _notificationService.updateNotificationPreference(
                      'like_notifications', value);
                },
                initialValue: _likeNotifications,
                leading: Icon(Icons.thumb_up),
                title: Text('Like Notifications'),
                description: Text('Get notified when someone likes your posts'),
              ),
              SettingsTile.switchTile(
                onToggle: (value) async {
                  setState(() => _commentNotifications = value);
                  await _notificationService.updateNotificationPreference(
                      'comment_notifications', value);
                },
                initialValue: _commentNotifications,
                leading: Icon(Icons.comment),
                title: Text('Comment Notifications'),
                description:
                    Text('Get notified when someone comments on your posts'),
              ),
              SettingsTile.switchTile(
                onToggle: (value) async {
                  setState(() => _newPostNotifications = value);
                  await _notificationService.updateNotificationPreference(
                      'new_post_notifications', value);
                },
                initialValue: _newPostNotifications,
                leading: Icon(Icons.post_add),
                title: Text('New Post Notifications'),
                description:
                    Text('Get notified about new posts from other users'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _saveSettings();
          // Restart the app to apply the new settings
          // You can use packages like `flutter_restart` for this purpose
        },
        child: const Icon(Icons.save),
      ),
    );
  }

  Future<void> _showTextFieldDialog(
      String title, TextEditingController controller) async {
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter $title',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newValue != null) {
      setState(() {
        controller.text = newValue;
      });
    }
  }
}
