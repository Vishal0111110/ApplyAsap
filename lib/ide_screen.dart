import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'coding_question.dart';
import 'jdoodle_service.dart';
import 'coding_chatbot.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/javascript.dart' as js_lang;
import 'package:highlight/languages/python.dart' as py_lang;
import 'package:highlight/languages/java.dart' as java_lang;
import 'package:highlight/languages/cpp.dart' as cpp_lang;
import 'package:highlight/languages/php.dart' as php_lang;
import 'package:highlight/languages/ruby.dart' as ruby_lang;
import 'package:highlight/languages/go.dart' as go_lang;
import 'package:highlight/languages/swift.dart' as swift_lang;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'gamification_service.dart';

class IDEScreen extends StatefulWidget {
  final CodingQuestion question;

  const IDEScreen({Key? key, required this.question}) : super(key: key);

  @override
  _IDEScreenState createState() => _IDEScreenState();
}

class LanguageOption {
  final String name;
  final String code;
  final String extension;

  const LanguageOption(this.name, this.code, this.extension);
}

class _IDEScreenState extends State<IDEScreen> {
  late CodeController _codeController;
  List<Map<String, dynamic>> _testResults = [];
  bool _isRunning = false;
  String _currentStatus =
      'Ready'; // Status: Ready, Running, Accepted, CE, RE, TLE
  late LanguageOption _selectedLanguage;

  final List<LanguageOption> _allLanguages = [
    const LanguageOption('JavaScript', 'JAVASCRIPT', 'js'),
    const LanguageOption('Python', 'PYTHON', 'py'),
    const LanguageOption('Java', 'JAVA', 'java'),
    const LanguageOption('C++', 'CPP', 'cpp'),
    const LanguageOption('C', 'C', 'c'),
    const LanguageOption('C#', 'CSHARP', 'cs'),
    const LanguageOption('PHP', 'PHP', 'php'),
    const LanguageOption('Ruby', 'RUBY', 'rb'),
    const LanguageOption('Go', 'GO', 'go'),
    const LanguageOption('Swift', 'SWIFT', 'swift'),
  ];

  late List<LanguageOption> _languages;

  @override
  void initState() {
    super.initState();

    // Filter languages based on question category
    if (widget.question.category == 'Dev') {
      _languages =
          _allLanguages.where((lang) => lang.name == 'JavaScript').toList();
    } else {
      _languages = _allLanguages;
    }

    _selectedLanguage = _languages[0]; // Default to first available language

    // Initialize CodeController with proper language and initial code
    _codeController = CodeController(
      text: _getInitialCodeForLanguage(_selectedLanguage.name),
      language: _getLanguage(_selectedLanguage.name),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Get language definition for syntax highlighting
  dynamic _getLanguage(String languageName) {
    switch (languageName) {
      case 'JavaScript':
        return js_lang.javascript;
      case 'Python':
        return py_lang.python;
      case 'Java':
        return java_lang.java;
      case 'C++':
        return cpp_lang.cpp;
      case 'C':
        return cpp_lang.cpp; // Use C++ syntax for C as fallback
      case 'C#':
        return js_lang.javascript; // Use JavaScript syntax for C# as fallback
      case 'PHP':
        return php_lang.php;
      case 'Ruby':
        return ruby_lang.ruby;
      case 'Go':
        return go_lang.go;
      case 'Swift':
        return swift_lang.swift;
      default:
        return js_lang.javascript; // Default to JavaScript
    }
  }

  // Get initial code for the selected language
  String _getInitialCodeForLanguage(String languageName) {
    // Handle different formats of initialCode
    if (widget.question.initialCode is String) {
      // Dev questions: initialCode is a string
      return widget.question.initialCode;
    } else if (widget.question.initialCode is Map) {
      // DSA questions: initialCode is an object with language keys
      final Map<String, dynamic> codeMap =
          widget.question.initialCode as Map<String, dynamic>;

      // Map language names to the keys used in JSON
      String languageKey;
      switch (languageName) {
        case 'JavaScript':
          languageKey = 'javascript';
          break;
        case 'Python':
          languageKey = 'python';
          break;
        case 'Java':
          languageKey = 'java';
          break;
        case 'C++':
          languageKey = 'cpp';
          break;
        case 'C#':
          languageKey = 'csharp';
          break;
        default:
          languageKey = 'javascript'; // Default fallback
      }

      // Return the language-specific code or fallback to JavaScript
      return codeMap[languageKey] ??
          codeMap['javascript'] ??
          '// No code template available';
    }

    // Fallback for unexpected formats
    return '// No code template available';
  }

  // Check if the current code is still the initial template
  bool _isInitialTemplate(String currentText, String? category) {
    if (category == 'Dev') {
      // For dev questions, check if it matches the JavaScript template
      return currentText.trim() ==
          widget.question.initialCode.toString().trim();
    } else {
      // For DSA questions, check if it matches any of the language templates
      if (widget.question.initialCode is Map) {
        final Map<String, dynamic> codeMap =
            widget.question.initialCode as Map<String, dynamic>;
        return codeMap.values.any(
            (template) => currentText.trim() == template.toString().trim());
      }
    }
    return false;
  }

  String _wrapDSACodeWithBoilerplate(String userCode, String inputData) {
    switch (_selectedLanguage.name) {
      case 'JavaScript':
        return _wrapJavaScriptDSA(userCode, inputData);
      case 'Python':
        return _wrapPythonDSA(userCode, inputData);
      case 'Java':
        return _wrapJavaDSA(userCode, inputData);
      case 'C++':
        return _wrapCppDSA(userCode, inputData);
      case 'C':
        return _wrapCDSA(userCode, inputData);
      case 'C#':
        return _wrapCSharpDSA(userCode, inputData);
      case 'PHP':
        return _wrapPhpDSA(userCode, inputData);
      case 'Ruby':
        return _wrapRubyDSA(userCode, inputData);
      case 'Go':
        return _wrapGoDSA(userCode, inputData);
      case 'Swift':
        return _wrapSwiftDSA(userCode, inputData);
      default:
        return userCode; // Fallback
    }
  }

  String _wrapJavaScriptDSA(String userCode, String inputData) {
    final functionMatch = RegExp(r'function\s+(\w+)\s*\(').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      String processedInput = inputData.replaceAll('\n', ',');
      return '$userCode\n\nconsole.log(JSON.stringify($functionName($processedInput)));';
    }
    return userCode;
  }

  String _wrapPythonDSA(String userCode, String inputData) {
    final functionMatch = RegExp(r'def\s+(\w+)\s*\(').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      String processedInput = inputData.replaceAll('\n', ',');
      return '$userCode\n\nprint($functionName($processedInput))';
    }
    return userCode;
  }

  String _wrapJavaDSA(String userCode, String inputData) {
    final functionMatch =
        RegExp(r'public\s+.*\s+(\w+)\s*\(').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      final classMatch = RegExp(r'public\s+class\s+(\w+)').firstMatch(userCode);
      final className = classMatch?.group(1) ?? 'Solution';

      String processedInput = inputData.replaceAll('\n', ',');

      return '''
$userCode

public class Main {
    public static void main(String[] args) {
        $className solution = new $className();
        System.out.println(solution.$functionName($processedInput));
    }
}
''';
    }
    return userCode;
  }

  String _wrapCppDSA(String userCode, String inputData) {
    final functionMatch = RegExp(r'\w+\s+(\w+)\s*\(').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      String processedInput = inputData.replaceAll('\n', ',');
      return '''
#include <iostream>
using namespace std;

$userCode

int main() {
    cout << $functionName($processedInput) << endl;
    return 0;
}
''';
    }
    return userCode;
  }

  String _wrapCDSA(String userCode, String inputData) {
    final functionMatch = RegExp(r'\w+\s+(\w+)\s*\(').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      String processedInput = inputData.replaceAll('\n', ',');
      return '''
#include <stdio.h>

$userCode

int main() {
    printf("%d\\n", $functionName($processedInput));
    return 0;
}
''';
    }
    return userCode;
  }

  String _wrapCSharpDSA(String userCode, String inputData) {
    final functionMatch =
        RegExp(r'(?:public\s+)?(?:static\s+)?\w+\s+(\w+)\s*\(')
            .firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      final classMatch =
          RegExp(r'(?:public\s+)?class\s+(\w+)').firstMatch(userCode);
      final className = classMatch?.group(1) ?? 'Solution';

      String processedInput = inputData.replaceAll('\n', ',');

      return '''
using System;

$userCode

public class Program {
    public static void Main(string[] args) {
        $className solution = new $className();
        Console.WriteLine(solution.$functionName($processedInput));
    }
}
''';
    }
    return userCode;
  }

  String _wrapPhpDSA(String userCode, String inputData) {
    final functionMatch = RegExp(r'function\s+(\w+)\s*\(').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      String processedInput = inputData.replaceAll('\n', ',');
      return '''
$userCode

echo $functionName($processedInput);
''';
    }
    return userCode;
  }

  String _wrapRubyDSA(String userCode, String inputData) {
    final functionMatch = RegExp(r'def\s+(\w+)').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      String processedInput = inputData.replaceAll('\n', ',');
      return '$userCode\n\nputs $functionName($processedInput)';
    }
    return userCode;
  }

  String _wrapGoDSA(String userCode, String inputData) {
    final functionMatch = RegExp(r'func\s+(\w+)\s*\(').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      String processedInput = inputData.replaceAll('\n', ',');
      return '''
package main

import "fmt"

$userCode

func main() {
    fmt.Println($functionName($processedInput))
}
''';
    }
    return userCode;
  }

  String _wrapSwiftDSA(String userCode, String inputData) {
    final functionMatch = RegExp(r'func\s+(\w+)\s*\(').firstMatch(userCode);
    if (functionMatch != null) {
      final functionName = functionMatch.group(1);
      String processedInput = inputData.replaceAll('\n', ',');
      return '$userCode\n\nprint($functionName($processedInput))';
    }
    return userCode;
  }

  Future<Map<String, dynamic>> _runTestCase(TestCase testCase) async {
    try {
      // Prepare source code based on question type and language
      String sourceCode = _codeController.text;
      String inputData = testCase.input;

      // Wrap the code with proper boilerplate
      sourceCode = _wrapDSACodeWithBoilerplate(sourceCode, inputData);
      inputData = ''; // Input is now embedded in the code

      // Execute code using JDoodle service
      final jdoodleResult = await JDoodleService.executeCode(
        language: _selectedLanguage.code,
        script: sourceCode,
        stdin: inputData,
        timeout: const Duration(seconds: 30),
      );

      print('JDoodle Result: $jdoodleResult');

      if (jdoodleResult['status'] == 'success') {
        final output = jdoodleResult['output'] ?? '';
        final executionStatus = jdoodleResult['executionStatus'] ?? 'Accepted';
        final passed = output.trim() == testCase.output.trim();

        // Provide detailed error information based on execution status
        String actualOutput = output.trim();
        if (executionStatus != 'Accepted') {
          actualOutput =
              '${JDoodleService.mapStatusToDisplay(executionStatus)}: $actualOutput';
        } else if (actualOutput.isEmpty && !passed) {
          actualOutput = 'No output produced';
        }

        return {
          'input': testCase.input,
          'expected': testCase.output,
          'actual': actualOutput,
          'passed': passed,
          'hidden': testCase.hidden,
          'executionStatus': executionStatus,
          'memory': jdoodleResult['memory'],
          'cpuTime': jdoodleResult['cpuTime'],
        };
      } else {
        // Handle error cases
        final errorMessage = jdoodleResult['message'] ?? 'Unknown error';
        final executionStatus = jdoodleResult['executionStatus'] ?? 'RE';

        return {
          'input': testCase.input,
          'expected': testCase.output,
          'actual':
              '${JDoodleService.mapStatusToDisplay(executionStatus)}: $errorMessage',
          'passed': false,
          'hidden': testCase.hidden,
          'executionStatus': executionStatus,
          'error': errorMessage,
        };
      }
    } catch (e) {
      print('Error in _runTestCase: $e');
      return {
        'input': testCase.input,
        'expected': testCase.output,
        'actual': 'Execution failed: $e',
        'passed': false,
        'hidden': testCase.hidden,
        'executionStatus': 'RE',
        'error': e.toString(),
      };
    }
  }

  void _submitCode() async {
    setState(() {
      _isRunning = true;
      _currentStatus = 'Running';
      _testResults = [];
    });

    try {
      for (var testCase in widget.question.testCases) {
        setState(() {
          _currentStatus =
              'Running Test ${widget.question.testCases.indexOf(testCase) + 1}';
        });

        final result = await _runTestCase(testCase);
        setState(() {
          _testResults.add(result);
        });
      }

      // Determine final status based on results
      if (_testResults.isNotEmpty) {
        final allPassed =
            _testResults.every((result) => result['passed'] == true);
        final hasCompilationError =
            _testResults.any((result) => result['executionStatus'] == 'CE');
        final hasRuntimeError =
            _testResults.any((result) => result['executionStatus'] == 'RE');
        final hasTimeout =
            _testResults.any((result) => result['executionStatus'] == 'TLE');

        if (allPassed) {
          _currentStatus = 'Accepted';
          // Award points and mark question as complete
          await _awardQuestionCompletion();
        } else if (hasCompilationError) {
          _currentStatus = 'Compilation Error';
        } else if (hasRuntimeError) {
          _currentStatus = 'Runtime Error';
        } else if (hasTimeout) {
          _currentStatus = 'Time Limit Exceeded';
        } else {
          _currentStatus = 'Wrong Answer';
        }
      }
    } catch (e) {
      setState(() {
        _currentStatus = 'Execution Failed';
      });
      print('Error in _submitCode: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _awardQuestionCompletion() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final questionId = widget.question.questionText.hashCode.toString();

    try {
      // Check if already completed
      final completedRef = FirebaseDatabase.instance
          .ref()
          .child('completed_questions')
          .child(currentUser.uid)
          .child(questionId);

      if ((await completedRef.get()).exists) return;

      // Mark as completed
      await completedRef.set({
        'questionText': widget.question.questionText,
        'category': widget.question.category,
        'completedAt': DateTime.now().toIso8601String(),
        'language': _selectedLanguage.name,
      });

      // Award points using the gamification service
      const int QUESTION_COMPLETION_POINTS = 20;
      await GamificationService().awardPoints(
        currentUser.uid,
        QUESTION_COMPLETION_POINTS,
        'Completed ${widget.question.category} question',
        context: context,
        showPopup: true,
      );

      // Update activity stats for achievements
      await GamificationService().updateActivityStats(
        currentUser.uid,
        'question_completed',
      );

      // Update challenge progress for coding questions
      if (widget.question.category == 'DSA' ||
          widget.question.category == 'Dev') {
        await GamificationService().updateChallengeProgress(
          currentUser.uid,
          'questions_completed',
          'weekly',
        );
        await GamificationService().updateChallengeProgress(
          currentUser.uid,
          'questions_completed',
          'monthly',
        );
      }
    } catch (e) {
      print('Error awarding completion: $e');
    }
  }

  Color _getSummaryColor() {
    if (_testResults.isEmpty) return Colors.grey;

    int passedCount =
        _testResults.where((result) => result['passed'] == true).length;
    double percentage = passedCount / _testResults.length;

    if (percentage == 1.0) return const Color(0xFF4CAF50); // Professional green
    if (percentage >= 0.5)
      return const Color(0xFFFF9800); // Professional orange
    return const Color(0xFFF44336); // Professional red
  }

  String _getSummaryText() {
    if (_testResults.isEmpty) return 'Ready to Test';

    int passedCount =
        _testResults.where((result) => result['passed'] == true).length;
    int totalCount = _testResults.length;

    if (passedCount == totalCount) {
      return 'All Tests Passed';
    } else if (passedCount > 0) {
      return 'Partial Success';
    } else {
      return 'Tests Failed';
    }
  }

  String _getSummaryDetails() {
    if (_testResults.isEmpty) return 'Run your code to see test results';

    int passedCount =
        _testResults.where((result) => result['passed'] == true).length;
    int totalCount = _testResults.length;
    double percentage = (passedCount / totalCount * 100);

    String details =
        '$passedCount of $totalCount tests passed (${percentage.toStringAsFixed(0)}%)';

    if (passedCount == totalCount) {
      details += '\n\nExcellent! Your solution is correct.';
    } else if (passedCount > 0) {
      details += '\n\nGood progress. Review the failed test cases.';
    } else {
      details += '\n\nCheck your code logic and try again.';
    }

    return details;
  }

  IconData _getSummaryIcon() {
    if (_testResults.isEmpty) return Icons.play_circle_outline;

    int passedCount =
        _testResults.where((result) => result['passed'] == true).length;
    int totalCount = _testResults.length;

    if (passedCount == totalCount) return Icons.check_circle;
    if (passedCount > 0) return Icons.warning;
    return Icons.error;
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case 'Ready':
        return Colors.grey;
      case 'Running':
      case 'Running Test 1':
      case 'Running Test 2':
      case 'Running Test 3':
        return Colors.blue;
      case 'Accepted':
        return const Color(0xFF4CAF50); // Green
      case 'Compilation Error':
        return const Color(0xFFFF9800); // Orange
      case 'Runtime Error':
      case 'Time Limit Exceeded':
      case 'Wrong Answer':
      case 'Execution Failed':
        return const Color(0xFFF44336); // Red
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'Code Playground',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _currentStatus,
              style: TextStyle(
                color: _getStatusColor(),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5BC0EB)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Question Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1F1F1F),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Problem Statement',
                    style: TextStyle(
                      color: Color(0xFF5BC0EB),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.question.questionText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language Selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Language',
                          style: TextStyle(
                            color: Color(0xFF5BC0EB),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF323232),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<LanguageOption>(
                              value: _selectedLanguage,
                              dropdownColor: const Color(0xFF323232),
                              style: const TextStyle(color: Colors.white),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Color(0xFF5BC0EB),
                              ),
                              items: _languages.map((LanguageOption language) {
                                return DropdownMenuItem<LanguageOption>(
                                  value: language,
                                  child: Text(language.name),
                                );
                              }).toList(),
                              onChanged: (LanguageOption? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedLanguage = newValue;
                                    // Check if the current code is still the initial template
                                    String currentText = _codeController.text;
                                    String initialCode =
                                        _getInitialCodeForLanguage(
                                            _selectedLanguage.name);

                                    // If the current code is still the initial template or empty, update it
                                    // Otherwise, keep the user's code but change the language
                                    String newText = currentText;
                                    if (currentText.trim().isEmpty ||
                                        _isInitialTemplate(currentText,
                                            widget.question.category)) {
                                      newText = initialCode;
                                    }

                                    // Create new controller with updated language and text
                                    _codeController = CodeController(
                                      text: newText,
                                      language:
                                          _getLanguage(_selectedLanguage.name),
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Code Editor
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 200,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF323232),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedLanguage.name == 'JavaScript'
                                    ? Icons.javascript
                                    : Icons.code,
                                color: const Color(0xFF5BC0EB),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Code Editor',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5BC0EB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _selectedLanguage.extension.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          constraints: BoxConstraints(
                            minHeight: 200,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: CodeTheme(
                            data: CodeThemeData(styles: monokaiSublimeTheme),
                            child: CodeField(
                              controller: _codeController,
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                              minLines: 10,
                              maxLines: null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Test Cases Section
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF323232),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.science,
                                color: Color(0xFF5BC0EB),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Test Cases',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade700,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${widget.question.testCases.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.question.testCases.length,
                          itemBuilder: (context, index) {
                            final testCase = widget.question.testCases[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: index <
                                            widget.question.testCases.length - 1
                                        ? Colors.grey.shade800
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                              child: testCase.hidden
                                  ? Row(
                                      children: [
                                        Icon(
                                          Icons.visibility_off,
                                          color: Colors.grey.shade600,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Hidden Test Case ${index + 1}',
                                          style: const TextStyle(
                                            color: Color(0xFFB0B0B0),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.input,
                                              color: Color(0xFF5BC0EB),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Input:',
                                              style: TextStyle(
                                                color: Color(0xFF5BC0EB),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF323232),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            testCase.input,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.output,
                                              color: Colors.green,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Expected Output:',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF323232),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            testCase.output,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Results Section
                  if (_testResults.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFF323232),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.assessment,
                                  color: Color(0xFF5BC0EB),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Test Results',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getSummaryColor(),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_testResults.where((r) => r['passed']).length}/${_testResults.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _testResults.length,
                            itemBuilder: (context, index) {
                              final result = _testResults[index];
                              final isPassed = result['passed'] as bool;
                              final isHidden = result['hidden'] as bool;

                              return Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF323232),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isPassed
                                        ? Colors.green.withOpacity(0.3)
                                        : Colors.red.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isPassed
                                              ? Icons.check_circle
                                              : Icons.error,
                                          color: isPassed
                                              ? const Color(0xFF4CAF50)
                                              : const Color(0xFFF44336),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isHidden
                                              ? 'Hidden Test Case ${index + 1}'
                                              : 'Test Case ${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isPassed
                                                ? const Color(0xFF4CAF50)
                                                : const Color(0xFFF44336),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            isPassed ? 'PASS' : 'FAIL',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!isHidden) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Input',
                                                  style: TextStyle(
                                                    color: Color(0xFF5BC0EB),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF1F1F1F),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    result['input'] as String,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'monospace',
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Expected',
                                                  style: TextStyle(
                                                    color: Color(0xFF4CAF50),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF1F1F1F),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    result['expected']
                                                        as String,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'monospace',
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!isPassed) ...[
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Your Output',
                                          style: TextStyle(
                                            color: Color(0xFFF44336),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1F1F1F),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFFF44336)
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            result['actual'] as String,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Summary Card
                  if (_testResults.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getSummaryColor().withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getSummaryColor().withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getSummaryIcon(),
                                color: _getSummaryColor(),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _getSummaryText(),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: _getSummaryColor(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF323232),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getSummaryDetails(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isRunning ? null : _submitCode,
                          icon: _isRunning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(_isRunning ? 'Running...' : 'Run Tests'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5BC0EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  backgroundColor: const Color(0xFF1F1F1F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.lightbulb,
                                              color: Color(0xFF5BC0EB),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Solution Approach',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          constraints: BoxConstraints(
                                            maxHeight: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.6,
                                          ),
                                          child: SingleChildScrollView(
                                            child: Text(
                                              widget.question.solution != null
                                                  ? widget.question.solution!
                                                  : 'Solution approach will be provided here with step-by-step pseudo code logic.',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                height: 1.6,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text(
                                              'Got it!',
                                              style: TextStyle(
                                                color: Color(0xFF5BC0EB),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.lightbulb_outline),
                          label: const Text('Show Solution'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5BC0EB),
                            side: const BorderSide(color: Color(0xFF5BC0EB)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CodingChatbot(
                question: widget.question,
                userCode: _codeController.text,
                selectedLanguage: _selectedLanguage.name,
                testResults: _testResults,
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF5BC0EB),
        child: const Icon(
          Icons.chat,
          color: Colors.white,
        ),
        tooltip: 'Ask AI Assistant',
      ),
    );
  }
}
