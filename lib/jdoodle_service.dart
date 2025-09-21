import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class JDoodleService {
  static const String _baseUrl = 'PUT_YOUR_PROXY_URL';

  // Language mappings for JDoodle
  static const Map<String, String> _languageMap = {
    'JAVASCRIPT': 'nodejs',
    'PYTHON': 'python3',
    'JAVA': 'java',
    'CPP': 'cpp',
    'C': 'c',
    'CSHARP': 'csharp',
    'PHP': 'php',
    'RUBY': 'ruby',
    'GO': 'go',
    'SWIFT': 'swift',
  };

  // Version indices for JDoodle
  static const Map<String, int> _versionIndexMap = {
    'nodejs': 4,
    'python3': 4,
    'java': 4,
    'cpp': 5,
    'c': 5,
    'csharp': 4,
    'php': 4,
    'ruby': 3,
    'go': 3,
    'swift': 4,
  };

  static Future<Map<String, dynamic>> executeCode({
    required String language,
    required String script,
    String stdin = '',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final jdoodleLanguage = _languageMap[language];
      final versionIndex = _versionIndexMap[jdoodleLanguage];

      if (jdoodleLanguage == null || versionIndex == null) {
        return {
          'status': 'error',
          'message': 'Unsupported language: $language',
          'executionStatus': 'CE',
        };
      }

      final requestBody = {
        'language': jdoodleLanguage,
        'versionIndex': versionIndex.toString(),
        'script': script,
        'stdin': stdin,
      };

      print('JDoodle Request: $requestBody');

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);

      print('JDoodle Response Status: ${response.statusCode}');
      print('JDoodle Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Handle JDoodle response format
        if (result.containsKey('output')) {
          final output = result['output'] ?? '';
          final statusCode = result['statusCode'];
          final memory = result['memory'];
          final cpuTime = result['cpuTime'];

          // Determine execution status based on JDoodle response
          String executionStatus = 'Accepted';
          if (statusCode != null && statusCode != 200) {
            executionStatus = 'RE'; // Runtime Error
          }

          return {
            'status': 'success',
            'output': output,
            'executionStatus': executionStatus,
            'memory': memory,
            'cpuTime': cpuTime,
            'statusCode': statusCode,
          };
        } else if (result.containsKey('error')) {
          return {
            'status': 'error',
            'message': result['error'],
            'executionStatus': 'CE', // Compilation Error
          };
        } else {
          return {
            'status': 'error',
            'message': 'Unexpected response format',
            'executionStatus': 'RE',
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'HTTP ${response.statusCode}: ${response.body}',
          'executionStatus': 'RE',
        };
      }
    } on TimeoutException {
      return {
        'status': 'error',
        'message': 'Execution timeout',
        'executionStatus': 'TLE',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'executionStatus': 'RE',
      };
    }
  }

  static String mapStatusToDisplay(String executionStatus) {
    switch (executionStatus) {
      case 'Accepted':
        return 'Accepted';
      case 'CE':
        return 'Compilation Error';
      case 'RE':
        return 'Runtime Error';
      case 'TLE':
        return 'Time Limit Exceeded';
      default:
        return executionStatus;
    }
  }
}
