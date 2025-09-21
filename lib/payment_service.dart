import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService {
  Razorpay? _razorpay;
  bool _isInitialized = false;

  PaymentService() {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    if (_isInitialized) return;

    try {
      _razorpay = Razorpay();
      _setupEventHandlers();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize Razorpay: $e');
    }
  }

  void _setupEventHandlers() {
    if (_razorpay == null) return;

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    if (_razorpay != null) {
      _razorpay!.clear();
    }
  }

  Future<void> initiatePayment({
    required BuildContext context,
    required int amount,
    required String courseId,
    required String courseName,
    required Map<String, dynamic> courseData,
    required Function(String, Map<String, dynamic>) onPaymentSuccess,
    required Function(String) onPaymentError,
  }) async {
    if (_razorpay == null || !_isInitialized) {
      _initializeRazorpay();
      if (_razorpay == null) {
        onPaymentError('Failed to initialize payment gateway');
        return;
      }
    }

    // Clear any previous payment context
    _currentPaymentContext = null;

    try {
      var options = {
        'key': dotenv.env['RAZORPAY_KEY'] ?? '',
        'amount': amount, // Keep as int in rupees (not paisa)
        'name': 'Career Recommendation App',
        'description': 'Course Enrollment - $courseName',
        'currency': 'INR',
        'prefill': {
          'contact': '',
          'email': FirebaseAuth.instance.currentUser?.email ?? '',
        },
        'theme': {
          'color': '#5BC0EB',
        },
      };

      // Store payment context before opening payment gateway
      _currentPaymentContext = {
        'courseId': courseId,
        'courseName': courseName,
        'courseData': courseData,
        'amount': amount,
        'onPaymentSuccess': onPaymentSuccess,
        'onPaymentError': onPaymentError,
        'context': context,
      };

      _razorpay!.open(options);
    } catch (e, stackTrace) {
      debugPrint('Payment initiation error: $e');
      debugPrint('Stack trace: $stackTrace');
      onPaymentError('Payment initialization failed: $e');
    }
  }

  Map<String, dynamic>? _currentPaymentContext;

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_currentPaymentContext == null) return;

    final context = _currentPaymentContext!;
    final BuildContext buildContext = context['context'];
    final courseId = context['courseId'];
    final courseName = context['courseName'];
    final courseData = context['courseData'];
    final amount = context['amount'];
    final onPaymentSuccess = context['onPaymentSuccess'];

    try {
      // Store transaction in database
      await _storePaymentRecord(
        paymentId: response.paymentId ?? '',
        courseId: courseId,
        courseName: courseName,
        courseData: courseData,
        amount: amount,
        status: 'success',
      );

      // Update enrollment
      await _storeEnrollment(
        courseId: courseId,
        courseName: courseName,
        courseData: courseData,
        paymentId: response.paymentId ?? '',
      );

      _showSnackBar(buildContext, 'Payment successful!');

      // Call success callback on next tick to ensure UI updates properly
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPaymentSuccess(response.paymentId ?? '', courseData);
      });
    } catch (e) {
      _showSnackBar(
          buildContext, 'Payment successful but failed to store enrollment');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_currentPaymentContext == null) return;

    final context = _currentPaymentContext!;
    final BuildContext buildContext = context['context'];
    final onPaymentError = context['onPaymentError'];

    _showSnackBar(buildContext, 'Payment failed: ${response.message}');
    onPaymentError('Payment failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet selection
  }

  Future<void> _storePaymentRecord({
    required String paymentId,
    required String courseId,
    required String courseName,
    required Map<String, dynamic> courseData,
    required int amount,
    required String status,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final transactionId = _generateTransactionId();

    final paymentData = {
      'transactionId': transactionId,
      'paymentId': paymentId,
      'courseId': courseId,
      'courseName': courseName,
      'courseData': courseData,
      'amount': amount,
      'currency': 'INR',
      'status': status,
      'paymentMethod': 'razorpay',
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'transactionType': 'course_enrollment',
    };

    // Store in transactions node
    await FirebaseDatabase.instance
        .ref()
        .child('transactions')
        .child(transactionId)
        .set(paymentData);

    // Store in user-specific transactions
    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId)
        .child('transactions')
        .child(transactionId)
        .set(paymentData);
  }

  Future<void> _storeEnrollment({
    required String courseId,
    required String courseName,
    required Map<String, dynamic> courseData,
    required String paymentId,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final enrollmentData = {
      'courseId': courseId,
      'courseName': courseName,
      'courseData': courseData,
      'paymentId': paymentId,
      'enrollmentDate': DateTime.now().toIso8601String(),
      'status': 'active',
      'progress': 0,
      'completedLectures': [],
    };

    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId)
        .child('enrollments')
        .child(courseId)
        .set(enrollmentData);
  }

  String _generateTransactionId() {
    final now = DateTime.now();
    return 'TXN${now.millisecondsSinceEpoch}';
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('failed')
            ? const Color(0xFFf77080)
            : const Color(0xFF5BC0EB),
      ),
    );
  }
}
