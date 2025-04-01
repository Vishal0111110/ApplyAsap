// ignore_for_file: prefer_const_constructors, prefer_final_fields, deprecated_member_use

import 'dart:convert';

// Define a class to hold question data
class QuestionData {
  // Define class properties
  final List<String> titles;
  final List<List<String>> options;

  // Define a constructor for the class
  QuestionData({required this.titles, required this.options});

  // Factory constructor to create an instance of the class from JSON
  factory QuestionData.fromJson(Map<String, dynamic> jsonData) {
    // Extract options from JSON data
    var optionsFromJson = jsonData['options'];
    // Convert options to a list of lists
    List<List<String>> optionsList = List<List<String>>.from(
        optionsFromJson.map((i) => List<String>.from(i)));

    // Return an instance of the class
    return QuestionData(
      titles: List<String>.from(jsonData['titles']),
      options: optionsList,
    );
  }

  // Method to convert an instance of the class to JSON
  String toJson() {
    Map<String, dynamic> json = {};
    // Iterate over the titles and options
    for (int i = 0; i < titles.length; i++) {
      // Add each title and its corresponding options to the map
      json[titles[i]] =
          options[i].where((option) => option.isNotEmpty).toList();
    }
    // Convert the map to a JSON string
    return jsonEncode(json);
  }
}
