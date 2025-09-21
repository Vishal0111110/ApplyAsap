class CodingQuestion {
  final String questionText;
  final dynamic initialCode; // Can be String (dev) or Map (DSA)
  final List<TestCase> testCases;
  final String? solution;
  final String? category;

  CodingQuestion({
    required this.questionText,
    required this.initialCode,
    required this.testCases,
    this.solution,
    this.category,
  });
}

class TestCase {
  final String input;
  final String output;
  final bool hidden;

  TestCase({
    required this.input,
    required this.output,
    this.hidden = false,
  });
}
