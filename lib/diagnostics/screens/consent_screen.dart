import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/diagnostics_service.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _privacyConsent = false;
  bool _dataSharingConsent = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Privacy & Consent',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5BC0EB),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1F1F1F), Color(0xFF252525)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF5BC0EB).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.security,
                            color: Color(0xFF5BC0EB),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Data Collection & Privacy',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'To provide personalized career insights, our assessments collect and analyze various data points.',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Section 1: Privacy Consent
                    _buildConsentSection(
                      icon: Icons.lock,
                      title: 'Privacy Notice',
                      content: [
                        'Our assessments use scientifically validated psychological testing methods',
                        'Data is encrypted and stored securely in compliance with data protection laws',
                        'Responses are analyzed to provide personalized career recommendations',
                        'Results are stored for your future reference and progress tracking',
                      ],
                      value: _privacyConsent,
                      onChanged: (value) {
                        setState(() {
                          _privacyConsent = value ?? false;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Section 2: Data Sharing Consent
                    _buildConsentSection(
                      icon: Icons.share,
                      title: 'Data Research & Improvement',
                      content: [
                        'Anonymous, aggregated data may be used for research purposes',
                        'This helps improve our assessment tools and career recommendations',
                        'No personally identifiable information is shared without explicit permission',
                        'You can withdraw this consent at any time',
                      ],
                      value: _dataSharingConsent,
                      onChanged: (value) {
                        setState(() {
                          _dataSharingConsent = value ?? false;
                        });
                      },
                    ),

                    const SizedBox(height: 32),

                    // Important Notes
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can update your consent preferences at any time from your profile settings.',
                              style: TextStyle(
                                color: Colors.orange.shade200,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Decline',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _privacyConsent
                                ? () async => await _acceptConsent()
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _privacyConsent
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Accept & Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildConsentSection({
    required IconData icon,
    required String title,
    required List<String> content,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? const Color(0xFF5BC0EB).withOpacity(0.5)
              : Colors.grey.shade700,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: value
                      ? const Color(0xFF5BC0EB).withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: value ? const Color(0xFF5BC0EB) : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...content.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: value,
            onChanged: onChanged,
            title: Text(
              'I understand and agree to the above terms',
              style: TextStyle(
                color: value ? Colors.white : Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFF5BC0EB),
            checkColor: Colors.black,
          ),
        ],
      ),
    );
  }

  Future<void> _acceptConsent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = DiagnosticsService();
      await service.updateUserConsent(
        privacyConsent: _privacyConsent,
        dataSharingConsent: _dataSharingConsent,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save consent: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
