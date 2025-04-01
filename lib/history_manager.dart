import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryManager {
  static final HistoryManager _instance = HistoryManager._internal();

  factory HistoryManager() {
    return _instance;
  }

  HistoryManager._internal();

  final String _storageKey = 'history';
  List<Map<String, dynamic>> _history = [];

  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contents = prefs.getString(_storageKey);
      if (contents != null) {
        _history = List<Map<String, dynamic>>.from(json.decode(contents));
      }
    } catch (e) {
      debugPrint('Failed to load history: $e');
    }
  }

  Future<void> saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(_history));
    } catch (e) {
      debugPrint('Failed to save history: $e');
    }
  }

  void addConversation(Map<String, dynamic> conversation) {
    _history.add(conversation);
  }

  List<Map<String, dynamic>> getHistory() {
    return List<Map<String, dynamic>>.from(_history);
  }
}
