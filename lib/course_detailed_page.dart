import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'colors.dart';
import 'custom_image.dart';
import 'payment_service.dart';
import 'enrollment_service.dart';
import 'ide_screen.dart';
import 'coding_question.dart' show CodingQuestion, TestCase;
import 'lecture_practice_page.dart';

class CourseDetailedPage extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseDetailedPage({Key? key, required this.course}) : super(key: key);

  @override
  _CourseDetailedPageState createState() => _CourseDetailedPageState();
}

class _CourseDetailedPageState extends State<CourseDetailedPage> {
  bool _isEnrolled = false;
  final EnrollmentService _enrollmentService = EnrollmentService();

  @override
  void initState() {
    super.initState();
    _checkEnrollmentStatus();
  }

  Future<void> _checkEnrollmentStatus() async {
    final courseId =
        (widget.course["id"] ?? widget.course["name"] ?? "unknown_course")
            .toString();
    final isEnrolled = await _enrollmentService.isEnrolled(courseId);
    if (mounted) {
      setState(() {
        _isEnrolled = isEnrolled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.appBgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.textColor),
        centerTitle: true,
        title: Text(
          widget.course["name"]?.toString() ?? "Course Details",
          style: const TextStyle(
            color: AppColor.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image - Made clickable to navigate to Vimeo
            GestureDetector(
              onTap: () => _openCourseVideo(context),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.shadowColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CustomImage(
                        widget.course["image"],
                        width: double.infinity,
                        height: 200,
                        radius: 20,
                      ),
                    ),
                  ),
                  // Play button overlay on image
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withOpacity(0.4),
                      ),
                      child: const Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Course Title and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.course["name"]?.toString() ?? "No Title",
                    style: const TextStyle(
                      color: AppColor.textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5BC0EB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.course["price"]?.toString() ?? "Free",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Course Category
            Text(
              widget.course["category"] ?? "General",
              style: const TextStyle(
                color: AppColor.labelColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Stats Row: Session, Duration, Review, Difficulty
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat(Icons.play_circle_outline,
                    widget.course["session"]?.toString() ?? "N/A", "Sessions"),
                _buildStat(Icons.schedule,
                    widget.course["duration"]?.toString() ?? "N/A", "Duration"),
                _buildStat(Icons.star,
                    widget.course["review"]?.toString() ?? "N/A", "Rating"),
                _buildStat(
                    Icons.trending_up,
                    widget.course["difficulty"]?.toString() ?? "Intermediate",
                    "Level"),
              ],
            ),
            const SizedBox(height: 20),

            // Instructor
            if (widget.course.containsKey("instructor"))
              Text(
                "Instructor: ${widget.course["instructor"]}",
                style: const TextStyle(
                  color: AppColor.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 12),

            // Prerequisites
            if (widget.course.containsKey("prerequisites") &&
                widget.course["prerequisites"].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Prerequisites",
                    style: TextStyle(
                      color: AppColor.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...widget.course["prerequisites"]
                      .map<Widget>((prereq) => Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "• $prereq",
                              style: const TextStyle(
                                color: AppColor.labelColor,
                                fontSize: 14,
                              ),
                            ),
                          )),
                ],
              ),
            const SizedBox(height: 16),

            // Description
            const Text(
              "Description",
              style: TextStyle(
                color: AppColor.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.course["description"],
              style: const TextStyle(
                color: AppColor.labelColor,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Lectures
            if (widget.course.containsKey("lectures") &&
                widget.course["lectures"].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Course Lectures",
                    style: TextStyle(
                      color: AppColor.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.course["lectures"]
                      .asMap()
                      .entries
                      .map<Widget>((entry) => GestureDetector(
                            onTap: _isEnrolled
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LectureDetailPage(
                                          course: widget.course,
                                          lectureIndex: entry.key,
                                          lectureTitle: entry.value,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: _isEnrolled
                                    ? AppColor.cardColor
                                    : AppColor.cardColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color:
                                        AppColor.shadowColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColor.primary,
                                    radius: 15,
                                    child: Text(
                                      "${entry.key + 1}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        color: _isEnrolled
                                            ? AppColor.textColor
                                            : AppColor.textColor
                                                .withOpacity(0.5),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _isEnrolled ? Icons.play_arrow : Icons.lock,
                                    color: _isEnrolled
                                        ? AppColor.primary
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          )),
                ],
              ),
            const SizedBox(height: 30),

            // Enroll Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isEnrolled
                    ? null
                    : () {
                        _enrollInCourse(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isEnrolled ? Colors.grey : const Color(0xFF5BC0EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  shadowColor: AppColor.shadowColor.withOpacity(0.3),
                  elevation: 5,
                ),
                child: Text(
                  _isEnrolled ? "Enrolled" : "Enroll Now",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColor.labelColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColor.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColor.labelColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _openCourseVideo(BuildContext context) async {
    // Use the specific Vimeo URL for all courses
    final String vimeoUrl = "https://vimeo.com/1070736587/c5fa59aa6e";

    if (await canLaunchUrl(Uri.parse(vimeoUrl))) {
      await launchUrl(Uri.parse(vimeoUrl),
          mode: LaunchMode.externalApplication);
    } else {
      // Show error message if URL cannot be launched
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to open video"),
          backgroundColor: Color(0xFFf77080),
        ),
      );
    }
  }

  void _enrollInCourse(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => PaymentDialog(
        course: widget.course,
        parentContext: context,
        onPaymentSuccess: () {
          _checkEnrollmentStatus();
        },
      ),
    );
  }
}

class PaymentDialog extends StatefulWidget {
  final Map<String, dynamic> course;
  final BuildContext parentContext;
  final Function? onCoinsUpdated;
  final Function? onPaymentSuccess;

  const PaymentDialog({
    Key? key,
    required this.course,
    required this.parentContext,
    this.onCoinsUpdated,
    this.onPaymentSuccess,
  }) : super(key: key);

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final PaymentService _paymentService = PaymentService();
  final EnrollmentService _enrollmentService = EnrollmentService();

  int _userCoins = 0;
  bool _isLoadingCoins = true;
  bool _isLoadingPayment = false;
  int _selectedPaymentOption = 0; // 0 = full payment, 1 = partial payment
  TextEditingController _coinsController = TextEditingController();
  int _coursePriceRupees = 0;
  int _coursePricePaisa = 0;
  int _remainingAmountPaisa = 0;

  @override
  void initState() {
    super.initState();
    _initializeDialog();
    _coinsController.addListener(_updateRemainingAmount);
  }

  @override
  void dispose() {
    _coinsController.removeListener(_updateRemainingAmount);
    _coinsController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  void _updateRemainingAmount() {
    final coinsToUse = int.tryParse(_coinsController.text) ?? 0;
    final paiseEquivalent = coinsToUse * 100; // 1 coin = 1 rupee = 100 paise
    setState(() {
      _remainingAmountPaisa = _coursePricePaisa - paiseEquivalent;
      if (_remainingAmountPaisa < 0) _remainingAmountPaisa = 0;
    });
  }

  Future<void> _initializeDialog() async {
    try {
      // Parse course price synchronously
      final priceString = widget.course["price"] ?? "0";
      final rupees =
          int.tryParse(priceString.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

      // Start async coin fetch
      setState(() {
        _coursePriceRupees = rupees;
        _coursePricePaisa = rupees;
        _remainingAmountPaisa = rupees;
      });

      final coins = await _enrollmentService.getUserCoins();

      // Update state with fetched coins
      setState(() {
        _userCoins = coins;
        _isLoadingCoins = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCoins = false;
      });
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text('Failed to load payment information: $e'),
          backgroundColor: Color(0xFFf77080),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCoins) {
      return const Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BC0EB)),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enroll in ${widget.course["name"]}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Course Price & Coin Balance
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Course Price',
                        style: TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '₹${(_coursePriceRupees / 100).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Coins',
                        style: TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$_userCoins',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Options
            _buildPaymentOption(
              title: 'Pay Full Amount',
              subtitle:
                  '₹${(_coursePriceRupees / 100).toStringAsFixed(2)} via Razorpay',
              value: 0,
            ),
            if (_userCoins > 0)
              _buildPaymentOption(
                title: 'Pay with Coins + Money',
                subtitle: 'Use your available coins',
                value: 1,
              ),

            // Coin Input Field
            if (_selectedPaymentOption == 1) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _coinsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter coins to use (max: $_userCoins)',
                  hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Remaining Amount',
                    style: TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '₹${(_remainingAmountPaisa / 100).toStringAsFixed(3)}',
                    style: const TextStyle(
                      color: Color(0xFF5BC0EB),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFF5BC0EB)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF5BC0EB),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isLoadingPayment ? null : () => _processPayment(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF5BC0EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoadingPayment
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Pay Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required int value,
  }) {
    final isSelected = _selectedPaymentOption == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentOption = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5BC0EB).withOpacity(0.1)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF5BC0EB) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color(0xFF5BC0EB)
                  : const Color(0xFFB0B0B0),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment() async {
    final courseId =
        (widget.course["id"] ?? widget.course["name"] ?? "unknown_course")
            .toString();

    if (_selectedPaymentOption == 0) {
      // Full payment with Razorpay
      setState(() {
        _isLoadingPayment = true;
      });

      try {
        await _paymentService.initiatePayment(
          context: widget.parentContext,
          amount: _coursePricePaisa,
          courseId: courseId,
          courseName: widget.course["name"] ?? "",
          courseData: widget.course,
          onPaymentSuccess: _handlePaymentSuccess,
          onPaymentError: _handlePaymentError,
        );

        // Don't pop here, wait for payment result
      } catch (e) {
        setState(() {
          _isLoadingPayment = false;
        });
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text('Pay Now Exception: $e'),
            backgroundColor: const Color(0xFFf77080),
          ),
        );
      }
    } else {
      // Partial payment with coins + Razorpay
      int coinsToUse = int.tryParse(_coinsController.text) ?? 0;
      final inputCoins = coinsToUse; // Store original input to handle capping

      if (coinsToUse > _userCoins) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          const SnackBar(
            content: Text('You don\'t have enough coins'),
            backgroundColor: Color(0xFFf77080),
          ),
        );
        return;
      }

      if (coinsToUse <= 0) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid number of coins'),
            backgroundColor: Color(0xFFf77080),
          ),
        );
        return;
      }

      // Handle case where entered coins > course price in rupees
      final coursePriceInRupees = _coursePriceRupees ~/ 100;
      if (inputCoins > coursePriceInRupees) {
        final excessCoins = inputCoins - coursePriceInRupees;
        // Refund excess coins back to user
        await _enrollmentService.addCoins(excessCoins);
        // Cap coins to use at course price in rupees
        coinsToUse = coursePriceInRupees;
        // Update remaining amount to 0
        _remainingAmountPaisa = 0;
        // Update the controller to show capped value
        setState(() {
          _coinsController.text = coinsToUse.toString();
        });
      }

      try {
        // Deduct coins
        final success = await _enrollmentService.deductCoins(coinsToUse);
        if (!success) {
          ScaffoldMessenger.of(widget.parentContext).showSnackBar(
            const SnackBar(
              content: Text('Failed to deduct coins'),
              backgroundColor: Color(0xFFf77080),
            ),
          );
          return;
        }

        // If there are remaining amounts, charge via Razorpay
        if (_remainingAmountPaisa > 0) {
          await _paymentService.initiatePayment(
            context: widget.parentContext,
            amount: _remainingAmountPaisa,
            courseId: courseId,
            courseName: widget.course["name"] ?? "",
            courseData: widget.course,
            onPaymentSuccess: (paymentId, courseData) =>
                _handlePartialPaymentSuccess(paymentId, courseData, coinsToUse),
            onPaymentError: (error) =>
                _handlePartialPaymentError(error, coinsToUse),
          );
        } else {
          // All payment covered by coins
          await _handleCoinsOnlyPayment(coinsToUse);
        }
      } catch (e) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text('Partial Payment Exception: $e'),
            backgroundColor: const Color(0xFFf77080),
          ),
        );
      }
    }
  }

  void _handlePaymentSuccess(
      String paymentId, Map<String, dynamic> courseData) async {
    // UI update will be handled by the parent context callback
    // Enrollment is now handled by PaymentService
    setState(() {
      _isLoadingPayment = false;
    });
    if (widget.onPaymentSuccess != null) {
      widget.onPaymentSuccess!();
    }
    Navigator.of(context).pop(); // Close the dialog
  }

  void _handlePartialPaymentSuccess(
      String paymentId, Map<String, dynamic> courseData, int coinsUsed) async {
    // Enrollment already handled by PaymentService
    // Coin transaction was handled before Razorpay
    if (widget.onPaymentSuccess != null) {
      widget.onPaymentSuccess!();
    }
    Navigator.of(context).pop(); // Close the dialog
  }

  Future<void> _handleCoinsOnlyPayment(int coinsUsed) async {
    try {
      await _enrollmentService.storeCoinTransaction(
        courseId:
            (widget.course["id"] ?? widget.course["name"] ?? "unknown_course")
                .toString(),
        courseName: widget.course["name"] ?? "",
        courseData: widget.course,
        coinsUsed: coinsUsed,
        amount: _coursePriceRupees,
      );

      await _enrollmentService.storeEnrollment(
        courseId:
            (widget.course["id"] ?? widget.course["name"] ?? "unknown_course")
                .toString(),
        courseName: widget.course["name"] ?? "",
        courseData: widget.course,
        paymentId: 'coins_only',
        coinsUsed: coinsUsed,
      );

      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully enrolled in ${widget.course["name"]} using $coinsUsed coins!'),
          backgroundColor: const Color(0xFF5BC0EB),
        ),
      );
      if (widget.onPaymentSuccess != null) {
        widget.onPaymentSuccess!();
      }
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text('Enrollment with coins failed: $e'),
          backgroundColor: const Color(0xFFf77080),
        ),
      );
    }
  }

  void _handlePaymentError(String error) {
    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
      SnackBar(
        content: Text('Payment failed: $error'),
        backgroundColor: const Color(0xFFf77080),
      ),
    );
  }

  void _handlePartialPaymentError(String error, int coinsToRefund) {
    // Refund coins since Razorpay payment failed
    _enrollmentService.addCoins(coinsToRefund);

    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
      SnackBar(
        content: Text('Payment failed, coins refunded: $error'),
        backgroundColor: const Color(0xFFf77080),
      ),
    );
  }
}

class LectureDetailPage extends StatefulWidget {
  final Map<String, dynamic> course;
  final int lectureIndex;
  final String lectureTitle;

  const LectureDetailPage({
    Key? key,
    required this.course,
    required this.lectureIndex,
    required this.lectureTitle,
  }) : super(key: key);

  @override
  _LectureDetailPageState createState() => _LectureDetailPageState();
}

class _LectureDetailPageState extends State<LectureDetailPage> {
  late String _lectureLink;

  @override
  void initState() {
    super.initState();
    // Generate or fetch lecture link - in a real app, this could come from course data
    _lectureLink = _generateLectureLink(widget.lectureIndex);
  }

  String _generateLectureLink(int index) {
    // Use the specific Vimeo URL for all lectures as requested
    return "https://vimeo.com/1070736587/c5fa59aa6e";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.appBgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.textColor),
        centerTitle: true,
        title: Text(
          "Lecture ${widget.lectureIndex + 1}",
          style: const TextStyle(
            color: AppColor.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lecture Title
            Text(
              widget.lectureTitle,
              style: const TextStyle(
                color: AppColor.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "From ${widget.course["name"]}",
              style: const TextStyle(
                color: AppColor.labelColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Lecture Link Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.cardColor,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColor.shadowColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Lecture Link",
                    style: TextStyle(
                      color: AppColor.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lectureLink,
                    style: const TextStyle(
                      color: Color(0xFF5BC0EB),
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (await canLaunchUrl(Uri.parse(_lectureLink))) {
                          await launchUrl(Uri.parse(_lectureLink),
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Watch Lecture'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BC0EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Download Content Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.cardColor,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColor.shadowColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Resources & Downloads",
                    style: TextStyle(
                      color: AppColor.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDownloadItem(
                      "Lecture Notes", "PDF", Icons.picture_as_pdf),
                  const SizedBox(height: 8),
                  _buildDownloadItem("Source Code", "ZIP", Icons.code),
                  const SizedBox(height: 8),
                  _buildDownloadItem("Exercises", "PDF", Icons.assignment),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Practice Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.cardColor,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColor.shadowColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Practice Quiz",
                    style: TextStyle(
                      color: AppColor.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Test your understanding of this lecture with targeted questions.",
                    style: TextStyle(
                      color: AppColor.labelColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LecturePracticePage(
                              lectureTitle: widget.lectureTitle,
                              courseName: widget.course["name"],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.quiz),
                      label: const Text('Start Quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BC0EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Additional Features Section (placeholder)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.cardColor,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColor.shadowColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Additional Features",
                    style: TextStyle(
                      color: AppColor.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                      "Progress Tracking", "Mark this lecture as completed",
                      onTap: () => _showProgressDialog(
                          context, widget.lectureIndex, widget.lectureTitle)),
                  const SizedBox(height: 8),
                  _buildFeatureItem(
                      "Discussion Forum", "Ask questions to instructors",
                      onTap: () => _showDiscussionForum(
                          context, widget.lectureIndex, widget.lectureTitle)),
                  const SizedBox(height: 8),
                  _buildFeatureItem(
                      "Certificate Status", "Track your learning progress",
                      onTap: () => _showCertificateStatus(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadItem(String title, String type, IconData icon) {
    return InkWell(
      onTap: () {
        // Handle download logic here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title download started'),
            backgroundColor: const Color(0xFF5BC0EB),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5BC0EB), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                type,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.download,
              color: Color(0xFF5BC0EB),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.star_outline,
              color: Color(0xFF5BC0EB),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFB0B0B0),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  bool _isSoftwareRelatedForCourse() {
    final courseName = widget.course["name"]?.toString().toLowerCase() ?? "";
    final courseCategory =
        widget.course["category"]?.toString().toLowerCase() ?? "";

    // Check if course name matches software-related courses
    final softwareCourses = [
      'programming',
      'python programming',
      'javascript basics',
      'mobile app development',
      'data structures',
      'web design',
      'video editing',
      'advanced photoshoop',
      'ui/ux design',
      'mathematics',
      'physics fundamentals',
      'mobile graphic design',
    ];

    // Check if course name contains software-related keywords
    bool containsSoftwareKeyword = softwareCourses
        .any((keyword) => courseName.contains(keyword.toLowerCase()));

    // Check if course category is coding/design-technology related
    bool isTechCategory =
        courseCategory == "coding" || courseCategory == "design";

    return containsSoftwareKeyword || isTechCategory;
  }

  void _showProgressDialog(
      BuildContext context, int lectureIndex, String lectureTitle) async {
    final EnrollmentService enrollmentService = EnrollmentService();
    final courseId =
        (widget.course["id"] ?? widget.course["name"] ?? "unknown_course")
            .toString();

    // Check if lecture is already completed
    final lectureProgress =
        await enrollmentService.getLectureProgress(courseId, lectureIndex);
    final isCompleted = lectureProgress['completed'] ?? false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCompleted ? "Lecture Completed!" : "Mark as Completed",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.play_circle_outline,
                            color: isCompleted
                                ? Colors.green
                                : const Color(0xFF5BC0EB),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Lecture ${widget.lectureIndex + 1}: $lectureTitle",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      "Completed",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_isSoftwareRelatedForCourse())
                                const SizedBox(height: 8),
                              if (_isSoftwareRelatedForCourse())
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5BC0EB)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF5BC0EB)
                                              .withOpacity(0.4),
                                        ),
                                      ),
                                      child: const Text(
                                        "DSA",
                                        style: TextStyle(
                                          color: Color(0xFF5BC0EB),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6B35)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFFF6B35)
                                              .withOpacity(0.4),
                                        ),
                                      ),
                                      child: const Text(
                                        "Dev",
                                        style: TextStyle(
                                          color: Color(0xFFFF6B35),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (!isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await enrollmentService.markLectureCompleted(
                            courseId, lectureIndex);
                        setState(() {
                          // Trigger UI update after marking complete
                        });
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lecture marked as completed!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Refresh parent state if needed
                        if (mounted) {
                          this.setState(() {});
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Mark as Completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BC0EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Color(0xFF5BC0EB)),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Color(0xFF5BC0EB),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDiscussionForum(
      BuildContext context, int lectureIndex, String lectureTitle) async {
    final EnrollmentService enrollmentService = EnrollmentService();
    final courseId =
        (widget.course["id"] ?? widget.course["name"] ?? "unknown_course")
            .toString();

    // Get instructor name from course data
    final instructorName = widget.course["instructor"] ?? "Instructor";

    // Mock questions data with realistic instructor responses
    List<Map<String, dynamic>> questions = [
      {
        'question': 'Can you explain the concept of data flow in this topic?',
        'askedBy': 'Student A',
        'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
        'answers': [
          {
            'answer':
                'Great question! Data flow refers to how information moves through different components of your application. The key is understanding the input → process → output cycle and how data transformations occur at each step.',
            'answeredBy': instructorName,
            'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          }
        ],
      },
      {
        'question': 'I\'m having trouble understanding the core concepts here.',
        'askedBy': 'Student B',
        'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
        'answers': [
          {
            'answer':
                'Let\'s break this down step by step. First, focus on the fundamental principles and then build upon them. Would you like me to create some practice examples to help clarify these concepts?',
            'answeredBy': instructorName,
            'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
          }
        ],
      },
      {
        'question': 'Are there any real-world applications for this technique?',
        'askedBy': 'Student C',
        'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
        'answers': [],
      },
    ];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 600,
              maxWidth: 500,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF323232),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.forum,
                        color: Color(0xFF5BC0EB),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Discussion Forum',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Lecture ${widget.lectureIndex + 1}: $lectureTitle',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Questions List
                        Expanded(
                          child: ListView.builder(
                            itemCount: questions.length,
                            itemBuilder: (context, index) {
                              final question = questions[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.question_answer,
                                          color: Color(0xFF5BC0EB),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            question['question'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Asked by ${question['askedBy']}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),

                                    // Answers
                                    if (question['answers'].isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      const Divider(color: Colors.white24),
                                      ...question['answers']
                                          .map<Widget>((answer) {
                                        return Container(
                                          margin: const EdgeInsets.only(top: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.green.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.school,
                                                    color: Colors.green,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Answered by ${answer['answeredBy']}',
                                                    style: const TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                answer['answer'],
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // Ask Question Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showAskQuestionDialog(
                                context, questions, instructorName, setState),
                            icon: const Icon(Icons.add),
                            label: const Text('Ask Question'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5BC0EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFF5BC0EB)),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: Color(0xFF5BC0EB),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAskQuestionDialog(
      BuildContext context,
      List<Map<String, dynamic>> questions,
      String instructorName,
      void Function(void Function()) setState) {
    final TextEditingController _questionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ask a Question',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _questionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your question here...',
                  hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF5BC0EB)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF5BC0EB), width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFF5BC0EB)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF5BC0EB),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final questionText = _questionController.text.trim();
                        if (questionText.isNotEmpty) {
                          // Add new question to the list
                          setState(() {
                            questions.add({
                              'question': questionText,
                              'askedBy':
                                  'You', // In real app, would get from user profile
                              'timestamp': DateTime.now(),
                              'answers': [], // No answers initially
                            });
                          });

                          Navigator.of(dialogContext).pop();
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Question posted! $instructorName will respond soon.',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF5BC0EB),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF5BC0EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit Question',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // Dispose controller after dialog closes
      _questionController.dispose();
    });
  }

  void _showCertificateStatus(BuildContext context) async {
    final EnrollmentService enrollmentService = EnrollmentService();
    final courseId =
        (widget.course["id"] ?? widget.course["name"] ?? "unknown_course")
            .toString();

    // Get course progress
    final progress = await enrollmentService.getCourseProgress(courseId);
    final totalLectures = widget.course['lectures']?.length ?? 1;
    final completedLectures = progress['completedLectures'] ?? 0;
    final progressPercentage = (completedLectures / totalLectures) * 100;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Certificate Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.course["name"]}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),

              // Progress Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress Circle
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: progressPercentage / 100,
                            strokeWidth: 8,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progressPercentage >= 100
                                  ? Colors.green
                                  : const Color(0xFF5BC0EB),
                            ),
                          ),
                        ),
                        Text(
                          '${progressPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              '$completedLectures',
                              style: const TextStyle(
                                color: Color(0xFF5BC0EB),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Completed',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '$totalLectures',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Total',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${totalLectures - completedLectures}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Remaining',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Certificate Status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: progressPercentage >= 100
                            ? Colors.green.withOpacity(0.1)
                            : const Color(0xFF323232),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: progressPercentage >= 100
                              ? Colors.green
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            progressPercentage >= 100
                                ? Icons.workspace_premium
                                : Icons.schedule,
                            color: progressPercentage >= 100
                                ? Colors.green
                                : Colors.white70,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  progressPercentage >= 100
                                      ? 'Certificate Eligible!'
                                      : 'Certificate Progress',
                                  style: TextStyle(
                                    color: progressPercentage >= 100
                                        ? Colors.green
                                        : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  progressPercentage >= 100
                                      ? 'You can now claim your certificate'
                                      : 'Complete ${totalLectures - completedLectures} more lectures',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Button
              if (progressPercentage >= 100)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Certificate download feature coming soon!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download Certificate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFF5BC0EB)),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Color(0xFF5BC0EB),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
