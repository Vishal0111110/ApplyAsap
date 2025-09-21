import 'package:flutter/material.dart';
import 'interview.dart';
import 'question_data.dart';

class InterviewTypeSelection extends StatefulWidget {
  final QuestionData ans;
  final int language;
  final String? selectedJobTitle;
  final List<String>? selectedJobData;

  const InterviewTypeSelection({
    Key? key,
    required this.ans,
    required this.language,
    this.selectedJobTitle,
    this.selectedJobData,
  }) : super(key: key);

  @override
  _InterviewTypeSelectionState createState() => _InterviewTypeSelectionState();
}

class _InterviewTypeSelectionState extends State<InterviewTypeSelection> {
  String? _selectedInterviewType;

  final Map<String, List<String>> _localizedStrings = {
    'selectInterviewType': [
      "इंटरव्यू प्रकार चुनें", // Kashmiri (Devanagari)
      "ਇੰਟਰਵਿਊ ਕਿਸਮ ਚੁਣੋ", // Punjabi (Gurmukhi)
      "इंटरव्यू प्रकार चुनें", // Haryanvi
      "साक्षात्कार प्रकार चुनें", // Hindi
      "इंटरव्यू प्रकार चुनें", // Rajasthani
      "इंटरव्यू प्रकार चुनें", // Bhojpuri
      "সাক্ষাৎকারের ধরন নির্বাচন করুন", // Bengali
      "ઇન્ટરવ્યૂ પ્રકાર પસંદ કરો", // Gujarati
      "সাক্ষাৎকাৰ প্ৰকাৰ বাছনি কৰক", // Assamese
      "ସାକ୍ଷାତକାର ପ୍ରକାର ବାଛନ୍ତୁ", // Odia
      "मुलाखत प्रकार निवडा", // Marathi
      "நேர்காணல் வகையைத் தேர்ந்தெடுக்கவும்", // Tamil
      "ఇంటర్వ్యూ రకాన్ని ఎంచుకోండి", // Telugu
      "ಸಂದರ್ಶನದ ಪ್ರಕಾರವನ್ನು ಆಯ್ಕೆ ಮಾಡಿ", // Kannada
      "അഭിമുഖം തരം തിരഞ്ഞെടുക്കുക", // Malayalam
      "Select Interview Type", // English
    ],
    'technicalInterview': [
      "तकनीकी साक्षात्कार",
      "ਤਕਨੀਕੀ ਇੰਟਰਵਿਊ",
      "तकनीकी साक्षात्कार",
      "तकनीकी साक्षात्कार",
      "तकनीकी साक्षात्कार",
      "तकनीकी साक्षात्कार",
      "প্রযুক্তিগত সাক্ষাৎকার",
      "તકનીકી ઇન્ટરવ્યૂ",
      "প্ৰযুক্তিগত সাক্ষাৎকাৰ",
      "ପ୍ରଯୁକ୍ତିକ ସାକ୍ଷାତକାର",
      "तांत्रिक मुलाखत",
      "தொழில்நுட்ப நேர்காணல்",
      "సాంకేతిక ఇంటర్వ్యూ",
      "ತಾಂತ್ರಿಕ ಸಂದರ್ಶನ",
      "സാങ്കേതിക അഭിമുഖം",
      "Technical Interview",
    ],
    'hrInterview': [
      "मानव संसाधन साक्षात्कार",
      "ਮਾਨਵ ਸੰਸਾਧਨ ਇੰਟਰਵਿਊ",
      "मानव संसाधन साक्षात्कार",
      "मानव संसाधन साक्षात्कार",
      "मानव संसाधन साक्षात्कार",
      "मानव संसाधन साक्षात्कार",
      "মানব সম্পদ সাক্ষাৎকার",
      "માનવ સંસાધન ઇન્ટરવ્યૂ",
      "মানৱ সম্পদ সাক্ষাৎকাৰ",
      "ମାନବ ସମ୍ପଦ ସାକ୍ଷାତକାର",
      "मानव संसाधन मुलाखत",
      "மனித வள நேர்காணல்",
      "మానవ వనరుల ఇంటర్వ్యూ",
      "ಮಾನವ ಸಂಪನ್ಮೂಲ ಸಂದರ್ಶನ",
      "മാനുഷിക വിഭവ അഭിമുഖം",
      "HR Interview",
    ],
    'hiringManagerInterview': [
      "नियुक्ति प्रबंधक साक्षात्कार",
      "ਨਿਯੁਕਤੀ ਮੈਨੇਜਰ ਇੰਟਰਵਿਊ",
      "नियुक्ति प्रबंधक साक्षात्कार",
      "नियुक्ति प्रबंधक साक्षात्कार",
      "नियुक्ति प्रबंधक साक्षात्कार",
      "नियुक्ति प्रबंधक साक्षात्कार",
      "নিয়োগ ব্যবস্থাপক সাক্ষাৎকার",
      "નિયુક્તિ મેનેજર ઇન્ટરવ્યૂ",
      "নিযুক্তি ব্যৱস্থাপক সাক্ষাৎকাৰ",
      "ନିଯୁକ୍ତି ପ୍ରବନ୍ଧକ ସାକ୍ଷାତକାର",
      "नियुक्ती व्यवस्थापक मुलाखत",
      "வேலைவாய்ப்பு மேலாளர் நேர்காணல்",
      "నియామక నిర్వాహకుడు ఇంటర్వ్యూ",
      "ನೇಮಕಾತಿ ನಿರ್ವಾಹಕ ಸಂದರ್ಶನ",
      "നിയമന മാനേജർ അഭിമുഖം",
      "Hiring Manager Interview",
    ],
    'technicalDescription': [
      "यह साक्षात्कार आपके इस नौकरी के लिए तकनीकी ज्ञान का परीक्षण करता है",
      "ਇਹ ਇੰਟਰਵਿਊ ਤੁਹਾਡੇ ਇਸ ਨੌਕਰੀ ਲਈ ਤਕਨੀਕੀ ਗਿਆਨ ਦੀ ਜਾਂਚ ਕਰਦਾ ਹੈ",
      "यह साक्षात्कार आपके इस नौकरी के लिए तकनीकी ज्ञान का परीक्षण करता है",
      "यह साक्षात्कार आपके इस नौकरी के लिए तकनीकी ज्ञान का परीक्षण करता है",
      "यह साक्षात्कार आपके इस नौकरी के लिए तकनीकी ज्ञान का परीक्षण करता है",
      "यह साक्षात्कार आपके इस नौकरी के लिए तकनीकी ज्ञान का परीक्षण करता है",
      "এই সাক্ষাৎকারটি এই চাকরির জন্য আপনার প্রযুক্তিগত জ্ঞান পরীক্ষা করে",
      "આ ઇન્ટરવ્યૂ આ નોકરી માટે તમારા તકનીકી જ્ઞાનની તપાસ કરે છે",
      "এই সাক্ষাৎকাৰে এই চাকৰিৰ বাবে আপোনাৰ প্ৰযুক্তিগত জ্ঞান পৰীক্ষা কৰে",
      "ଏହି ସାକ୍ଷାତକାର ଏହି ନୌକରି ପାଇଁ ଆପଣଙ୍କର ପ୍ରଯୁକ୍ତିକ ଜ୍ଞାନ ପରୀକ୍ଷା କରେ",
      "हा मुलाखत तुमच्या या नोकरीसाठी तांत्रिक ज्ञानाची चाचणी घेतो",
      "இந்த நேர்காணல் இந்த வேலைக்கு உங்கள் தொழில்நுட்ப அறிவை சோதிக்கிறது",
      "ఈ ఇంటర్వ్యూ ఈ ఉద్యోగానికి మీ సాంకేతిక జ్ఞానాన్ని పరీక్షిస్తుంది",
      "ಈ ಸಂದರ್ಶನವು ಈ ಕೆಲಸಕ್ಕೆ ನಿಮ್ಮ ತಾಂತ್ರಿಕ ಜ್ಞಾನವನ್ನು ಪರೀಕ್ಷಿಸುತ್ತದೆ",
      "ഈ അഭിമുഖം ഈ ജോലിക്ക് നിങ്ങളുടെ സാങ്കേതിക അറിവ് പരിശോധിക്കുന്നു",
      "This interview tests your technical knowledge for this job",
    ],
    'hrDescription': [
      "व्यक्तिगत, व्यवहारिक और सामान्य प्रश्न",
      "ਵਿਅਕਤੀਗਤ, ਵਿਵਹਾਰਕ ਅਤੇ ਆਮ ਸਵਾਲ",
      "व्यक्तिगत, व्यवहारिक और सामान्य सवाल",
      "व्यक्तिगत, व्यवहारिक और सामान्य प्रश्न",
      "व्यक्तिगत, व्यवहारिक और सामान्य प्रश्न",
      "व्यक्तिगत, व्यवहारिक और सामान्य सवाल",
      "ব্যক্তিগত, আচরণগত এবং সাধারণ প্রশ্ন",
      "વ્યક્તિગત, વર્તણૂકીય અને સામાન્ય પ્રશ્નો",
      "ব্যক্তিগত, আচৰণগত আৰু সাধাৰণ প্ৰশ্ন",
      "ବ୍ୟକ୍ତିଗତ, ଆଚରଣଗତ ଏବଂ ସାଧାରଣ ପ୍ରଶ୍ନ",
      "वैयक्तिक, वर्तनपरक आणि सामान्य प्रश्न",
      "தனிப்பட்ட, நடத்தை மற்றும் பொதுவான கேள்விகள்",
      "వ్యక్తిగత, ప్రవర్తనా మరియు సాధారణ ప్రశ్నలు",
      "ವೈಯಕ್ತಿಕ, ನಡವಳಿಕ ಮತ್ತು ಸಾಮಾನ್ಯ ಪ್ರಶ್ನೆಗಳು",
      "വ്യക്തിഗത, പെരുമാറ്റപരമായ, സാധാരണ ചോദ്യങ്ങൾ",
      "Personal, behavioral, and general questions",
    ],
    'hiringManagerDescription': [
      "भूमिका विशिष्ट, नेतृत्व और कंपनी फिट प्रश्न",
      "ਭੂਮਿਕਾ ਵਿਸ਼ੇਸ਼, ਨੇਤ੍ਰਿਤਵ ਅਤੇ ਕੰਪਨੀ ਫਿਟ ਸਵਾਲ",
      "भूमिका विशिष्ट, नेतृत्व और कंपनी फिट सवाल",
      "भूमिका विशिष्ट, नेतृत्व और कंपनी फिट प्रश्न",
      "भूमिका विशिष्ट, नेतृत्व और कंपनी फिट प्रश्न",
      "भूमिका विशिष्ट, नेतृत्व और कंपनी फिट सवाल",
      "ভূমিকা নির্দিষ্ট, নেতৃত্ব এবং কোম্পানি ফিট প্রশ্ন",
      "ભૂમિકા વિશિષ્ટ, નેતૃત્વ અને કંપની ફિટ પ્રશ્નો",
      "ভূমিকা নিৰ্দিষ্ট, নেতৃত্ব আৰু কোম্পানি ফিট প্ৰশ্ন",
      "ଭୂମିକା ନିର୍ଦ୍ଧିଷ୍ଟ, ନେତୃତ୍ଵ ଏବଂ କମ୍ପାନୀ ଫିଟ୍ ପ୍ରଶ୍ନ",
      "भूमिका विशिष्ट, नेतृत्व आणि कंपनी फिट प्रश्न",
      "பங்கு குறிப்பிட்ட, தலைமை மற்றும் நிறுவனம் பொருத்தம் கேள்விகள்",
      "పాత్ర నిర్దిష్ట, నాయకత్వం మరియు కంపెనీ ఫిట్ ప్రశ్నలు",
      "ಪಾತ್ರ ನಿರ್ದಿಷ್ಟ, ನಾಯಕತ್ವ ಮತ್ತು ಕಂಪನಿ ಫಿಟ್ ಪ್ರಶ್ನೆಗಳು",
      "ഭൂമികാ നിർദ്ദിഷ്ട, നേതൃത്വം, കമ്പനി ഫിറ്റ് ചോദ്യങ്ങൾ",
      "Role-specific, leadership, and company fit questions",
    ],
    'startInterview': [
      "साक्षात्कार शुरू करें",
      "ਇੰਟਰਵਿਊ ਸ਼ੁਰੂ ਕਰੋ",
      "साक्षात्कार शुरू करें",
      "साक्षात्कार शुरू करें",
      "साक्षात्कार शुरू करें",
      "साक्षात्कार शुरू करें",
      "সাক্ষাৎকার শুরু করুন",
      "ઇન્ટરવ્યૂ શરૂ કરો",
      "সাক্ষাৎকাৰ আৰম্ভ কৰক",
      "ସାକ୍ଷାତକାର ଆରମ୍ଭ କରନ୍ତୁ",
      "मुलाखत सुरू करा",
      "நேர்காணலைத் தொடங்கவும்",
      "ఇంటర్వ్యూ ప్రారంభించండి",
      "ಸಂದರ್ಶನವನ್ನು ಪ್ರಾರಂಭಿಸಿ",
      "അഭിമുഖം ആരംഭിക്കുക",
      "Start Interview",
    ],
  };

  String _t(String key) {
    return _localizedStrings[key]?[widget.language] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        centerTitle: true,
        title: Text(
          _t('selectInterviewType'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              _t('selectInterviewType'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Choose the type of interview you want to practice:",
              style: TextStyle(
                color: Color(0xFFD1D1D1),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),

            // Technical Interview Option
            _buildInterviewTypeCard(
              type: 'technical',
              title: _t('technicalInterview'),
              description: _t('technicalDescription'),
              icon: Icons.code,
              color: const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 20),

            // HR Interview Option
            _buildInterviewTypeCard(
              type: 'hr',
              title: _t('hrInterview'),
              description: _t('hrDescription'),
              icon: Icons.people,
              color: const Color(0xFF2196F3),
            ),
            const SizedBox(height: 20),

            // Hiring Manager Interview Option
            _buildInterviewTypeCard(
              type: 'hiring_manager',
              title: _t('hiringManagerInterview'),
              description: _t('hiringManagerDescription'),
              icon: Icons.business,
              color: const Color(0xFFFF9800),
            ),

            const Spacer(),

            // Start Interview Button
            if (_selectedInterviewType != null)
              Center(
                child: ElevatedButton(
                  onPressed: _startInterview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BC0EB),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _t('startInterview'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewTypeCard({
    required String type,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedInterviewType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedInterviewType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : const Color(0xFF1F1F1F),
          border: Border.all(
            color: isSelected ? color : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Color(0xFFD1D1D1),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _startInterview() {
    if (_selectedInterviewType == null) return;

    // Use selected job data if available, otherwise fall back to questionnaire answers
    String careerData;
    String? jobTitle;
    if (widget.selectedJobTitle != null && widget.selectedJobData != null) {
      // Create a formatted string with job title and data for better IDE detection
      careerData =
          "${widget.selectedJobTitle}: ${widget.selectedJobData!.join(', ')}";
      jobTitle = widget.selectedJobTitle;
    } else {
      careerData = widget.ans.toJson();
      jobTitle = null;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InterviewPage(
          career: careerData,
          ans: widget.ans,
          language: widget.language,
          interviewType: _selectedInterviewType!,
          jobTitle: jobTitle,
        ),
      ),
    );
  }
}
