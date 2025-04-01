// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late SharedPreferences _prefs;

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

  Future<void> _showTextFieldDialog(String title, TextEditingController controller) async {
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
