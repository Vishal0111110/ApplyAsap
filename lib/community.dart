import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:reward_popup/reward_popup.dart';
import 'commchat.dart';

class Community {
  final String key;
  final String name;
  final String description;
  final String imageUrl; // This will now store a Base64 string
  final bool isPublic;
  final String joinCode;
  final Map<dynamic, dynamic>? members;

  Community({
    required this.key,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isPublic,
    required this.joinCode,
    this.members,
  });

  factory Community.fromData(String key, Map<dynamic, dynamic> data) {
    return Community(
      key: key,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isPublic: data['isPublic'] ?? true,
      joinCode: data['joinCode'] ?? '',
      members: data['members'],
    );
  }
}

const List<String> languageNames = [
  'Kashmiri',
  'Punjabi',
  'Haryanvi',
  'Hindi',
  'Rajasthani',
  'Bhojpuri',
  'Bengali',
  'Gujarati',
  'Assamese',
  'Odia',
  'Marathi',
  'Tamil',
  'Telugu',
  'Kannada',
  'Malayalam',
  'English'
];

const Map<String, Map<String, String>> localizedTexts = {
  "Learn Now": {
    "English": "Learn Now",
    "कश्मीरी": "علم حاصل کرو",
    "ਪੰਜਾਬੀ": "ਸਿੱਖੋ ਹੁਣ",
    "हरियाणवी": "सीख ले",
    "हिन्दी": "अब सीखें",
    "राजस्थानी": "हुण सीखो",
    "भोजपुरी": "अब सीखि",
    "বাংলা": "এখন শেখো",
    "ગુજરાતી": "હવે શીખો",
    "অসমীয়া": "এতিয়া শিকা",
    "ଓଡ଼ିଆ": "ଏବେ ଶିକ୍ଷା",
    "मराठी": "आता शिका",
    "தமிழ்": "இப்போது கற்று கொள்",
    "తెలుగు": "ఇప్పుడు నేర్చుకో",
    "ಕನ್ನಡ": "ಇದೀಗ ಕಲಿಯಿರಿ",
    "മലയാളം": "ഇപ്പോൾ പഠിക്കുക"
  },
  "Free Courses": {
    "English": "Free Courses",
    "कश्मीरी": "مفت کورسز",
    "ਪੰਜਾਬੀ": "ਮੁਫ਼ਤ ਕੋਰਸ",
    "हरियाणवी": "मुफ्त कोर्स",
    "हिन्दी": "नि:शुल्क पाठ्यक्रम",
    "राजस्थानी": "मुफ्त पाठ्यक्रम",
    "भोजपुरी": "फ्री कोर्स",
    "বাংলা": "বিনামূল্যে কোর্স",
    "ગુજરાતી": "મફત કોર્સ",
    "অসমীয়া": "নিশুল্ক পাঠ্যক্রম",
    "ଓଡ଼ିଆ": "ନି:ଶୁଳ୍କ କୋର୍ସ",
    "मराठी": "मोफत कोर्स",
    "தமிழ்": "இலவச பாடங்கள்",
    "తెలుగు": "ఉచిత కోర్సులు",
    "ಕನ್ನಡ": "ಉಚಿತ ಕೋರ್ಸುಗಳು",
    "മലയാളം": "സൗജന്യ കോഴ്‌സുകൾ"
  },
  "Practice Questions": {
    "English": "Practice Questions",
    "कश्मीरी": "प्रैक्टिस सवाल",
    "ਪੰਜਾਬੀ": "ਅਭਿਆਸ ਸਵਾਲ",
    "हरियाणवी": "अभ्यास प्रश्न",
    "हिन्दी": "अभ्यास प्रश्न",
    "राजस्थानी": "अभ्यास प्रश्न",
    "भोजपुरी": "प्रश्न अभ्यास",
    "বাংলা": "অভ্যাস প্রশ্ন",
    "ગુજરાતી": "અભ્યાસ પ્રશ્નો",
    "অসমীয়া": "অভ্যাস প্ৰশ্ন",
    "ଓଡ଼ିଆ": "ଅଭ୍ୟାସ ପ୍ରଶ୍ନ",
    "मराठी": "अभ्यास प्रश्न",
    "தமிழ்": "பயிற்சி கேள்விகள்",
    "తెలుగు": "అభ్యాస ప్రశ్నలు",
    "ಕನ್ನಡ": "ಅಭ್ಯಾಸ ಪ್ರಶ್ನೆಗಳು",
    "മലയാളം": "അഭ്യാസ ചോദ്യങ്ങൾ"
  },
  "No courses found": {
    "English": "No courses found",
    "कश्मीरी": "کوئی کوर्स نہیں ملا",
    "ਪੰਜਾਬੀ": "ਕੋਈ ਕੋਰਸ ਨਹੀਂ ਮਿਲਿਆ",
    "हरियाणवी": "कोई कोर्स ना मिला",
    "हिन्दी": "कोई कोर्स नहीं मिला",
    "राजस्थानी": "कोई पाठ्यक्रम नहीं मिला",
    "भोजपुरी": "कोई कोर्स ना मिलल",
    "বাংলা": "কোন কোর্স পাওয়া যায়নি",
    "ગુજરાતી": "કોઈ કોર્સ મળ્યા નથી",
    "অসমীয়া": "কোনো পাঠ্যক্রম পোৱা নগ'ল",
    "ଓଡ଼ିଆ": "କୌଣସି କୋର୍ସ ମିଳିଲା ନାହିଁ",
    "मराठी": "कोणतेही कोर्स आढळले नाही",
    "தமிழ்": "எந்தவொரு பாடமும் கிடைக்கவில்லை",
    "తెలుగు": "ఏ కోర్సు కూడా కనబడలేదు",
    "ಕನ್ನಡ": "ಯಾವುದೇ ಕೋರ್ಸು ಕಂಡುಬರುವುದಿಲ್ಲ",
    "മലയാളം": "ഏതെങ്കിലും കോഴ്സ് കണ്ടെത്തിയില്ല"
  },
  "Enter a custom course query": {
    "English": "Enter a custom course query",
    "कश्मीरी": "اپنی کسٹم کورس کویری درج کریں",
    "ਪੰਜਾਬੀ": "ਇੱਕ ਕਸਟਮ ਕੋਰਸ ਕਵੇਰੀ ਦਰਜ ਕਰੋ",
    "हरियाणवी": "एक कस्टम कोर्स क्वेरी दर्ज करो",
    "हिन्दी": "एक कस्टम कोर्स क्वेरी दर्ज करें",
    "राजस्थानी": "एक कस्टम पाठ्यक्रम क्वेरी दर्ज करें",
    "भोजपुरी": "एक कस्टम कोर्स क्वेरी दर्ज करीं",
    "বাংলা": "একটি কাস্টম কোর্স অনুসন্ধান লিখুন",
    "ગુજરાતી": "કસ્ટમ કોર્સ ક્વેરી દાખલ કરો",
    "অসমীয়া": "এটা কাষ্টম কোর্স কুৱেৰী প্ৰৱিষ্ট কৰক",
    "ଓଡ଼ିଆ": "ଏକ କଷ୍ଟମ୍ କୋର୍ସ କ୍ୱେରୀ ଦାଖଲ କରନ୍ତୁ",
    "मराठी": "एक कस्टम कोर्स क्वेरी प्रविष्ट करा",
    "தமிழ்": "ஒரு கஸ்டம் பாடம் வினாவை உள்ளிடவும்",
    "తెలుగు": "ఒక కస్టమ్ కోర్సు ప్రశ్నను నమోదు చేయండి",
    "ಕನ್ನಡ": "ಒಂದು ಕಸ್ಟಮ್ ಕೋರ್ಸ್ ಪ್ರಶ್ನೆಯನ್ನು ನಮೂದಿಸಿ",
    "മലയാളം": "ഒരു ഇഷ്ടാനുസൃത കോഴ്സ് ചോദ്യം നൽകുക"
  },
  "Generate": {
    "English": "Generate",
    "कश्मीरी": "جنریٹ کریں",
    "ਪੰਜਾਬੀ": "ਜਨਰੇਟ ਕਰੋ",
    "हरियाणवी": "जेनरेट करो",
    "हिन्दी": "जेनरेट करें",
    "राजस्थानी": "जेनरेट करो",
    "भोजपुरी": "जनरेट करीं",
    "বাংলা": "জেনারেট করুন",
    "ગુજરાતી": "બનાવો",
    "অসমীয়া": "জেনাৰেট কৰক",
    "ଓଡ଼ିଆ": "ଜେନେରେଟ କରନ୍ତୁ",
    "मराठी": "निर्मित करा",
    "தமிழ்": "உருவாக்கு",
    "తెలుగు": "తయారు చేయండి",
    "ಕನ್ನಡ": "ಉತ್ಪಾದನೆ ಮಾಡಿ",
    "മലയാളം": "സൃഷ്ടിക്കുക"
  },
  "Enter a custom question query": {
    "English": "Enter a custom question query",
    "कश्मीरी": "اپنی کسٹم سوال کویری درج کریں",
    "ਪੰਜਾਬੀ": "ਇੱਕ ਕਸਟਮ ਪ੍ਰਸ਼ਨ ਕਵੇਰੀ ਦਰਜ ਕਰੋ",
    "हरियाणवी": "एक कस्टम सवाल क्वेरी दर्ज करो",
    "हिन्दी": "एक कस्टम प्रश्न क्वेरी दर्ज करें",
    "राजस्थानी": "एक कस्टम प्रश्न क्वेरी दर्ज करें",
    "भोजपुरी": "एक कस्टम प्रश्न क्वेरी दर्ज करीं",
    "বাংলা": "একটি কাস্টম প্রশ্ন অনুসন্ধান লিখুন",
    "ગુજરાતી": "કસ્ટમ પ્રશ્ન ક્વેરી દાખલ કરો",
    "অসমীয়া": "এটা কাষ্টম প্ৰশ্ন কুৱেৰী প্ৰৱিষ্ট কৰক",
    "ଓଡ଼ିଆ": "ଏକ କଷ୍ଟମ୍ ପ୍ରଶ୍ନ କ୍ୱେରୀ ଦାଖଲ କରନ୍ତୁ",
    "मराठी": "एक कस्टम प्रश्न क्वेरी प्रविष्ट करा",
    "தமிழ்": "ஒரு கஸ்டம் கேள்வியை உள்ளிடவும்",
    "తెలుగు": "ఒక కస్టమ్ ప్రశ్నను నమోదు చేయండి",
    "ಕನ್ನಡ": "ಒಂದು ಕಸ್ಟಮ್ ಪ್ರಶ್ನೆಯನ್ನು ನಮೂದಿಸಿ",
    "മലയാളം": "ഒരു ഇഷ്ടാനുസൃത ചോദ്യമടങ്ങിക്കുക"
  },
  "Generate More Questions": {
    "English": "Generate More Questions",
    "कश्मीरी": "अजु सवाल जनरेट करें",
    "ਪੰਜਾਬੀ": "ਹੋਰ ਪ੍ਰਸ਼ਨ ਜਨਰੇਟ ਕਰੋ",
    "हरियाणवी": "और सवाल जनरेट करो",
    "हिन्दी": "और प्रश्न जनरेट करें",
    "राजस्थानी": "अधिक प्रश्न जनरेट करें",
    "भोजपुरी": "अउरी प्रश्न जनरेट करीं",
    "বাংলা": "আরও প্রশ্ন তৈরি করুন",
    "ગુજરાતી": "વધુ પ્રશ્નો બનાવો",
    "অসমীয়া": "অধিক প্ৰশ্ন জেনাৰেট কৰক",
    "ଓଡ଼ିଆ": "ଅଧିକ ପ୍ରଶ୍ନ ଜେନେରେଟ କରନ୍ତୁ",
    "मराठी": "अधिक प्रश्न तयार करा",
    "தமிழ்": "மேலும் கேள்விகளை உருவாக்கு",
    "తెలుగు": "ఇంకా ప్రశ్నలను తయారు చేయండి",
    "ಕನ್ನಡ": "ಇನ್ನೂ ಪ್ರಶ್ನೆಗಳನ್ನು ಉತ್ಪಾದಿಸಿ",
    "മലയാളം": "കൂടുതൽ ചോദ്യങ്ങൾ സൃഷ്ടിക്കുക"
  },
  "Your answer is incorrect.": {
    "English": "Your answer is incorrect.",
    "कश्मीरी": "آپ کا جواب غلط ہے۔",
    "ਪੰਜਾਬੀ": "ਤੁਹਾਡਾ ਜਵਾਬ ਗਲਤ ਹੈ।",
    "हरियाणवी": "तेरा उत्तर गलत है।",
    "हिन्दी": "आपका उत्तर गलत है।",
    "राजस्थानी": "आपरो उत्तर गलत है।",
    "भोजपुरी": "रउरा जवाब गलत बा।",
    "বাংলা": "আপনার উত্তর ভুল।",
    "ગુજરાતી": "તમારો જવાબ ખોટો છે.",
    "অসমীয়া": "আপোনাৰ উত্তৰ ভুল হৈছে।",
    "ଓଡ଼ିଆ": "ଆପଣଙ୍କର ଉତ୍ତର ଭୁଲ୍।",
    "मराठी": "तुमचे उत्तर चुकीचे आहे.",
    "தமிழ்": "உங்கள் விடை தவறாக உள்ளது.",
    "తెలుగు": "మీ సమాధానం తప్పు.",
    "ಕನ್ನಡ": "ನಿಮ್ಮ ಉತ್ತರ ತಪ್ಪಾಗಿದೆ.",
    "മലയാളം": "നിങ്ങളുടെ ഉത്തരമതൊൽപ്പത്തി തെറ്റാണ്."
  },
  "Congratulations!": {
    "English": "Congratulations!",
    "कश्मीरी": "مبارک ہو!",
    "ਪੰਜਾਬੀ": "ਵਧਾਈਆਂ!",
    "हरियाणवी": "बधाई हो!",
    "हिन्दी": "बधाई हो!",
    "राजस्थानी": "बधाई हो!",
    "भोजपुरी": "बधाई हो!",
    "বাংলা": "অভিনন্দন!",
    "ગુજરાતી": "અભિનંદન!",
    "অসমীয়া": "অভিনন্দন!",
    "ଓଡ଼ିଆ": "ବାଧାଇ ହୋ!",
    "मराठी": "शुभेच्छा!",
    "தமிழ்": "வாழ்த்துக்கள்!",
    "తెలుగు": "అభినందనలు!",
    "ಕನ್ನಡ": "ಅಭಿನಂದನೆಗಳು!",
    "മലയാളം": "അഭിനന്ദനങ്ങൾ!"
  },
  "You have received {coins} coins!": {
    "English": "You have received {coins} coins!",
    "कश्मीरी": "آپ کو {coins} سکے ملے ہیں!",
    "ਪੰਜਾਬੀ": "ਤੁਹਾਨੂੰ {coins} ਸਿੱਕੇ ਮਿਲੇ ਹਨ!",
    "हरियाणवी": "तेरे को {coins} सिक्के मिले हैं!",
    "हिन्दी": "आपको {coins} सिक्के मिले हैं!",
    "राजस्थानी": "आपको {coins} सिक्के मिले हैं!",
    "भोजपुरी": "तोहरा के {coins} सिक्का मिलल बा!",
    "বাংলা": "আপনি {coins}টি কয়েন পেয়েছেন!",
    "ગુજરાતી": "તમને {coins} સિક્કા મળ્યા છે!",
    "অসমীয়া": "আপুনি {coins} টা কয়েন পালে!",
    "ଓଡ଼ିଆ": "ଆପଣ {coins}ଟି ସିକ୍କା ପାଇଛନ୍ତି!",
    "मराठी": "आपल्याला {coins} नाणे प्राप्त झाले आहेत!",
    "தமிழ்": "உங்களுக்கு {coins} நாணயங்கள் வந்துள்ளன!",
    "తెలుగు": "మీకు {coins} నాణేలు వచ్చాయి!",
    "ಕನ್ನಡ": "ನಿಮಗೆ {coins} ನಾಣ್ಯಗಳು ಸಿಕ್ಕಿವೆ!",
    "മലയാളം": "നിങ്ങള്‍ക്ക് {coins} നാണയങ്ങള്‍ ലഭിച്ചു!"
  },
  "Awesome!": {
    "English": "Awesome!",
    "कश्मीरी": "شानदार!",
    "ਪੰਜਾਬੀ": "ਬਹੁਤ ਵਧੀਆ!",
    "हरियाणवी": "शानदार!",
    "हिन्दी": "शानदार!",
    "राजस्थानी": "शानदार!",
    "भोजपुरी": "शानदार!",
    "বাংলা": "অসাধারণ!",
    "ગુજરાતી": "અદભુત!",
    "অসমীয়া": "অসাধাৰণ!",
    "ଓଡ଼ିଆ": "ଧରଣୀୟ!",
    "मराठी": "शानदार!",
    "தமிழ்": "அற்புதம்!",
    "తెలుగు": "అద్భుతం!",
    "ಕನ್ನಡ": "ಅದ್ಭುತ!",
    "മലയാളം": "അഭിനന്ദനීයമാണ്!"
  },
  "Correct Answer": {
    "English": "Correct Answer",
    "कश्मीरी": "درست جواب",
    "ਪੰਜਾਬੀ": "ਸਹੀ ਜਵਾਬ",
    "हरियाणवी": "सही उत्तर",
    "हिन्दी": "सही उत्तर",
    "राजस्थानी": "सही उत्तर",
    "भोजपुरी": "सही जवाब",
    "বাংলা": "সঠিক উত্তর",
    "ગુજરાતી": "સાચું જવાબ",
    "অসমীয়া": "সঠিক উত্তৰ",
    "ଓଡ଼ିଆ": "ସଠିକ ଉତ୍ତର",
    "मराठी": "बरोबर उत्तर",
    "தமிழ்": "சரியான பதில்",
    "తెలుగు": "సరైన సమాధానం",
    "ಕನ್ನಡ": "ಸರಿ ಉತ್ತರ",
    "മലയാളം": "ശരിയായ ഉത്തരം"
  },
  "Continue": {
    "English": "Continue",
    "कश्मीरी": "جاری رکھیں",
    "ਪੰਜਾਬੀ": "ਜਾਰੀ ਰੱਖੋ",
    "हरियाणवी": "जारी रख",
    "हिन्दी": "जारी रखें",
    "राजस्थानी": "जारी राखो",
    "भोजपुरी": "जारी राखीं",
    "বাংলা": "চালিয়ে যান",
    "ગુજરાતી": "ચાલુ રાખો",
    "অসমীয়া": "চালু ৰাখক",
    "ଓଡ଼ିଆ": "ଚାଲୁ କରନ୍ତୁ",
    "मराठी": "सुरू ठेवा",
    "தமிழ்": "தொடரவும்",
    "తెలుగు": "కొనసాగించండి",
    "ಕನ್ನಡ": "ಮುಂದುವರಿಸಿ",
    "മലയാളം": "തുടരുക"
  },
  "Show Answer": {
    "English": "Show Answer",
    "कश्मीरी": "جواب دیکھائیں",
    "ਪੰਜਾਬੀ": "ਜਵਾਬ ਦਿਖਾਓ",
    "हरियाणवी": "उत्तर दिखा",
    "हिन्दी": "उत्तर दिखाएँ",
    "राजस्थानी": "उत्तर दिखाओ",
    "भोजपुरी": "उत्तर देखाईं",
    "বাংলা": "উত্তর দেখাও",
    "ગુજરાતી": "જવાબ બતાવો",
    "অসমীয়া": "উত্তৰ দেখুৱাওক",
    "ଓଡ଼ିଆ": "ଉତ୍ତର ଦେଖାନ୍ତୁ",
    "मराठी": "उत्तर दाखवा",
    "தமிழ்": "பதில் காட்டவும்",
    "తెలుగు": "సమాధానాన్ని చూపించు",
    "ಕನ್ನಡ": "ಉತ್ತರವನ್ನು ತೋರಿಸಿ",
    "മലയാളം": "ഉത്തരം കാണിക്കുക"
  },
  "Check Answer": {
    "English": "Check Answer",
    "कश्मीरी": "جواب چیک کریں",
    "ਪੰਜਾਬੀ": "ਜਵਾਬ ਚੈੱਕ ਕਰੋ",
    "हरियाणवी": "उत्तर जांच",
    "हिन्दी": "उत्तर जांचें",
    "राजस्थानी": "उत्तर जांचो",
    "भोजपुरी": "उत्तर जांचीं",
    "বাংলা": "উত্তর পরীক্ষা করুন",
    "ગુજરાતી": "જવાબ તપાસો",
    "অসমীয়া": "উত্তৰ পৰীক্ষা কৰক",
    "ଓଡ଼ିଆ": "ଉତ୍ତର ଯାଞ୍ଚ କରନ୍ତୁ",
    "मराठी": "उत्तर तपासा",
    "தமிழ்": "பதில் சரிபார்க்கவும்",
    "తెలుగు": "సమాధానాన్ని తనిఖీ చేయండి",
    "ಕನ್ನಡ": "ಉತ್ತರವನ್ನು ಪರಿಶೀಲಿಸಿ",
    "മലയാളം": "ഉത്തരം പരിശോധിക്കുക"
  },
  "What does Flutter primarily use for building UIs?": {
    "English": "What does Flutter primarily use for building UIs?",
    "कश्मीरी": "فلٹر بنیادی طور پر UI بنانے کے لیے کس چیز کا استعمال کرتا ہے؟",
    "ਪੰਜਾਬੀ": "ਫਲਟਰ ਮੁੱਖ ਤੌਰ 'ਤੇ UI ਬਣਾਉਣ ਲਈ ਕੀ ਵਰਤਦਾ ਹੈ?",
    "हरियाणवी": "Flutter मुख्य रूप से UI बनाने के लिए कै इस्तेमाल करे स?",
    "हिन्दी": "Flutter मुख्य रूप से UI निर्माण के लिए किसका उपयोग करता है?",
    "राजस्थानी": "Flutter मुख्य रूप से UI बनाने के लिए किसका उपयोग करता है?",
    "भोजपुरी": "Flutter मुख्य रूप से UI बनाए खातिर का इस्तेमाल करेला?",
    "বাংলা": "ফ্লাটার মূলত UI তৈরিতে কী ব্যবহার করে?",
    "ગુજરાતી": "Flutter મુખ્યત્વે UI બાંધવામાં શું વાપરે છે?",
    "অসমীয়া": "ফ্লাটাৰ প্ৰধানকৈ UI নিৰ্মাণত কি ব্যৱহাৰ কৰে?",
    "ଓଡ଼ିଆ": "Flutter ପ୍ରଧାନତଃ UI ନirmaଣ ପାଇଁ କ'ଣ ବ୍ୟବହାର କରେ?",
    "मराठी": "Flutter मुख्यत्वे UI तयार करण्यासाठी काय वापरते?",
    "தமிழ்": "Flutter முதன்மையாக UI கட்டுவதற்காக என்ன பயன்படுத்துகிறது?",
    "తెలుగు": "Flutter ప్రధానంగా UI నిర్మాణానికి ఏమి ఉపయోగిస్తుంది?",
    "ಕನ್ನಡ": "Flutter ಮುಖ್ಯವಾಗಿ UI ನಿರ್ಮಾಣಕ್ಕೆ ಏನು ಬಳಸುತ್ತದೆ?",
    "മലയാളം": "Flutter മുഖ്യമായും UI കെട്ടാന് എന്ത് ഉപയോഗിക്കുന്നു?"
  },
  "Dart": {
    "English": "Dart",
    "कश्मीरी": "ڈارٹ",
    "ਪੰਜਾਬੀ": "ਡਾਰਟ",
    "हरियाणवी": "डार्ट",
    "हिन्दी": "Dart",
    "राजस्थानी": "Dart",
    "भोजपुरी": "Dart",
    "বাংলা": "Dart",
    "ગુજરાતી": "Dart",
    "অসমীয়া": "Dart",
    "ଓଡ଼ିଆ": "Dart",
    "मराठी": "Dart",
    "தமிழ்": "Dart",
    "తెలుగు": "Dart",
    "ಕನ್ನಡ": "Dart",
    "മലയാളം": "Dart"
  },
  "JavaScript": {
    "English": "JavaScript",
    "कश्मीरी": "جاوا اسکرپٹ",
    "ਪੰਜਾਬੀ": "ਜਾਵਾਸਕ੍ਰਿਪਟ",
    "हरियाणवी": "जावास्क्रिप्ट",
    "हिन्दी": "JavaScript",
    "राजस्थानी": "JavaScript",
    "भोजपुरी": "JavaScript",
    "বাংলা": "JavaScript",
    "ગુજરાતી": "JavaScript",
    "অসমীয়া": "JavaScript",
    "ଓଡ଼ିଆ": "JavaScript",
    "मराठी": "JavaScript",
    "தமிழ்": "JavaScript",
    "తెలుగు": "JavaScript",
    "ಕನ್ನಡ": "JavaScript",
    "മലയാളം": "JavaScript"
  },
  "Kotlin": {
    "English": "Kotlin",
    "कश्मीरी": "کوٹلن",
    "ਪੰਜਾਬੀ": "ਕਾਟਲਿਨ",
    "हरियाणवी": "कोटलिन",
    "हिन्दी": "Kotlin",
    "राजस्थानी": "Kotlin",
    "भोजपुरी": "Kotlin",
    "বাংলা": "Kotlin",
    "ગુજરાતી": "Kotlin",
    "অসমীয়া": "Kotlin",
    "ଓଡ଼ିଆ": "Kotlin",
    "मराठी": "Kotlin",
    "தமிழ்": "Kotlin",
    "తెలుగు": "Kotlin",
    "ಕನ್ನಡ": "Kotlin",
    "മലയാളം": "Kotlin"
  },
  "Swift": {
    "English": "Swift",
    "कश्मीरी": "سوفٹ",
    "ਪੰਜਾਬੀ": "ਸਵਿਫਟ",
    "हरियाणवी": "स्विफ्ट",
    "हिन्दी": "Swift",
    "राजस्थानी": "Swift",
    "भोजपुरी": "Swift",
    "বাংলা": "Swift",
    "ગુજરાતી": "Swift",
    "অসমীয়া": "Swift",
    "ଓଡ଼ିଆ": "Swift",
    "मराठी": "Swift",
    "தமிழ்": "Swift",
    "తెలుగు": "Swift",
    "ಕನ್ನಡ": "Swift",
    "മലയാളം": "Swift"
  },
  "Which company developed Flutter?": {
    "English": "Which company developed Flutter?",
    "कश्मीरी": "فلٹر کس کمپنی نے تیار کیا؟",
    "ਪੰਜਾਬੀ": "ਫਲਟਰ ਕਿਸ ਕੰਪਨੀ ਨੇ ਵਿਕਸਤ ਕੀਤਾ?",
    "हरियाणवी": "Flutter किस कंपनी ने विकसित की?",
    "हिन्दी": "Flutter किस कंपनी द्वारा विकसित किया गया है?",
    "राजस्थानी": "Flutter किस कंपनी ने विकसित किया?",
    "भोजपुरी": "Flutter के विकसित करे वाला कंपनी कौन बा?",
    "বাংলা": "Flutter কে বিকাশ করেছে?",
    "ગુજરાતી": "Flutter કોના દ્વારા વિકસાવવામાં આવ્યું?",
    "অসমীয়া": "Flutter কোন কোম্পানীৰ দ্বাৰা বিকাশ কৰা হৈছে?",
    "ଓଡ଼ିଆ": "Flutter କେଉଁ କମ୍ପାନୀ ଦ୍ବାରା ବିକାଶ କରାଯାଇଛି?",
    "मराठी": "Flutter कोणत्या कंपनीने विकसित केले?",
    "தமிழ்": "Flutter எந்த நிறுவனத்தால் உருவாக்கப்பட்டது?",
    "తెలుగు": "Flutterని ఏ కంపెనీ అభివృద్ధి చేసింది?",
    "ಕನ್ನಡ": "Flutterಯನ್ನು ಯಾವ ಕಂಪನಿಯವರು ಅಭಿವೃದ್ಧಿಪಡಿಸಿದರು?",
    "മലയാളം": "Flutter ഏത് കമ്പനി വികസിപ്പിച്ചു?"
  },
  "Apple": {
    "English": "Apple",
    "कश्मीरी": "ایپل",
    "ਪੰਜਾਬੀ": "ਐਪਲ",
    "हरियाणवी": "एप्पल",
    "हिन्दी": "Apple",
    "राजस्थानी": "Apple",
    "भोजपुरी": "Apple",
    "বাংলা": "Apple",
    "ગુજરાતી": "Apple",
    "অসমীয়া": "Apple",
    "ଓଡ଼ିଆ": "Apple",
    "मराठी": "Apple",
    "தமிழ்": "Apple",
    "తెలుగు": "Apple",
    "ಕನ್ನಡ": "Apple",
    "മലയാളം": "Apple"
  },
  "Google": {
    "English": "Google",
    "कश्मीरी": "گوگل",
    "ਪੰਜਾਬੀ": "ਗੂਗਲ",
    "हरियाणवी": "गूगल",
    "हिन्दी": "Google",
    "राजस्थानी": "Google",
    "भोजपुरी": "Google",
    "বাংলা": "Google",
    "ગુજરાતી": "Google",
    "অসমীয়া": "Google",
    "ଓଡ଼ିଆ": "Google",
    "मराठी": "Google",
    "தமிழ்": "Google",
    "తెలుగు": "Google",
    "ಕನ್ನಡ": "Google",
    "മലയാളം": "Google"
  },
  "Microsoft": {
    "English": "Microsoft",
    "कश्मीरी": "مائیکروسافٹ",
    "ਪੰਜਾਬੀ": "ਮਾਈਕ੍ਰੋਸਾਫਟ",
    "हरियाणवी": "माइक्रोसॉफ्ट",
    "हिन्दी": "Microsoft",
    "राजस्थानी": "Microsoft",
    "भोजपुरी": "Microsoft",
    "বাংলা": "Microsoft",
    "ગુજરાતી": "Microsoft",
    "অসমীয়া": "Microsoft",
    "ଓଡ଼ିଆ": "Microsoft",
    "मराठी": "Microsoft",
    "தமிழ்": "Microsoft",
    "తెలుగు": "Microsoft",
    "ಕನ್ನಡ": "Microsoft",
    "മലയാളം": "Microsoft"
  },
  "Facebook": {
    "English": "Facebook",
    "कश्मीरी": "فیس بک",
    "ਪੰਜਾਬੀ": "ਫੇਸਬੁੱਕ",
    "हरियाणवी": "फेसबुक",
    "हिन्दी": "Facebook",
    "राजस्थानी": "Facebook",
    "भोजपुरी": "Facebook",
    "বাংলা": "Facebook",
    "ગુજરાતી": "Facebook",
    "অসমীয়া": "Facebook",
    "ଓଡ଼ିଆ": "Facebook",
    "मराठी": "Facebook",
    "தமிழ்": "Facebook",
    "తెలుగు": "Facebook",
    "ಕನ್ನಡ": "Facebook",
    "മലയാളം": "Facebook"
  },
  "What programming language is used with Flutter?": {
    "English": "What programming language is used with Flutter?",
    "कश्मीरी": "فلٹر کے ساتھ کون سی پروگرامنگ زبان استعمال کی جاتی ہے؟",
    "ਪੰਜਾਬੀ": "ਫਲਟਰ ਨਾਲ ਕਿਹੜੀ ਪ੍ਰੋਗ੍ਰਾਮਿੰਗ ਭਾਸ਼ਾ ਵਰਤੀ ਜਾਂਦੀ ਹੈ?",
    "हरियाणवी": "Flutter के साथ किस भाषा का इस्तेमाल करे स?",
    "हिन्दी": "Flutter के साथ किस प्रोग्रामिंग भाषा का उपयोग किया जाता है?",
    "राजस्थानी": "Flutter के साथ कौनसी प्रोग्रामिंग भाषा का उपयोग होता है?",
    "भोजपुरी": "Flutter के साथ कौनो प्रोग्रामिंग भाषा के इस्तेमाल होला?",
    "বাংলা": "Flutter-এর সাথে কোন প্রোগ্রামিং ভাষা ব্যবহার করা হয়?",
    "ગુજરાતી": "Flutter સાથે કઈ પ્રોગ્રામિંગ ભાષાનો ઉપયોગ થાય છે?",
    "অসমীয়া": "Flutter-ৰ সৈতে কোন প্ৰগ্ৰামিং ভাষা ব্যৱহাৰ কৰা হয়?",
    "ଓଡ଼ିଆ": "Flutter ସହିତ କେଉଁ ପ୍ରୋଗ୍ରାମିଂ ଭାଷା ବ୍ୟବହାର କରାଯାଏ?",
    "मराठी": "Flutter सह कोणती प्रोग्रामिंग भाषा वापरली जाते?",
    "தமிழ்": "Flutter உடன் எந்த நிரலாக்க மொழி பயன்படுத்தப்படுகிறது?",
    "తెలుగు": "Flutter తో ఏ ప్రోగ్రామింగ్ భాష ఉపయోగిస్తారు?",
    "ಕನ್ನಡ": "Flutter ಜೊತೆ ಯಾವ programming ಭಾಷೆಯನ್ನು ಬಳಸಲಾಗುತ್ತದೆ?",
    "മലയാളം": "Flutter ഉപയോഗിച്ച് ഏത് പ്രോഗ്രാമിംഗ് ഭാഷ ഉപയോഗിക്കുന്നു?"
  },
  "Python": {
    "English": "Python",
    "कश्मीरी": "پائتھن",
    "ਪੰਜਾਬੀ": "ਪਾਇਥਨ",
    "हरियाणवी": "पायथन",
    "हिन्दी": "Python",
    "राजस्थानी": "Python",
    "भोजपुरी": "Python",
    "বাংলা": "Python",
    "ગુજરાતી": "Python",
    "অসমীয়া": "Python",
    "ଓଡ଼ିଆ": "Python",
    "मराठी": "Python",
    "தமிழ்": "Python",
    "తెలుగు": "Python",
    "ಕನ್ನಡ": "Python",
    "മലയാളം": "Python"
  },
  "Ruby": {
    "English": "Ruby",
    "कश्मीरी": "روبی",
    "ਪੰਜਾਬੀ": "ਰੂਬੀ",
    "हरियाणवी": "रूबी",
    "हिन्दी": "Ruby",
    "राजस्थानी": "Ruby",
    "भोजपुरी": "Ruby",
    "বাংলা": "Ruby",
    "ગુજરાતી": "Ruby",
    "অসমীয়া": "Ruby",
    "ଓଡ଼ିଆ": "Ruby",
    "मराठी": "Ruby",
    "தமிழ்": "Ruby",
    "తెలుగు": "Ruby",
    "ಕನ್ನಡ": "Ruby",
    "മലയാളം": "Ruby"
  },
  "C#": {
    "English": "C#",
    "कश्मीरी": "C#",
    "ਪੰਜਾਬੀ": "C#",
    "हरियाणवी": "C#",
    "हिन्दी": "C#",
    "राजस्थानी": "C#",
    "भोजपुरी": "C#",
    "বাংলা": "C#",
    "ગુજરાતી": "C#",
    "অসমীয়া": "C#",
    "ଓଡ଼ିଆ": "C#",
    "मराठी": "C#",
    "தமிழ்": "C#",
    "తెలుగు": "C#",
    "ಕನ್ನಡ": "C#",
    "മലയാളം": "C#"
  },
  "YouTube: Free {career} Tutorials": {
    "English": "YouTube: Free {career} Tutorials",
    "कश्मीरी": "YouTube: مفت {career} ٹیوٹوریلز",
    "ਪੰਜਾਬੀ": "YouTube: ਮੁਫ਼ਤ {career} ਟਿਊਟੋਰੀਅਲ",
    "हरियाणवी": "YouTube: मुफ्त {career} ट्यूटोरियल",
    "हिन्दी": "YouTube: मुफ्त {career} ट्यूटोरियल",
    "राजस्थानी": "YouTube: मुफ्त {career} ट्यूटोरियल",
    "भोजपुरी": "YouTube: मुफ्त {career} ट्यूटोरियल",
    "বাংলা": "YouTube: ফ্রি {career} টিউটোরিয়াল",
    "ગુજરાતી": "YouTube: મફત {career} ટયુટોરિયલ",
    "অসমীয়া": "YouTube: নিখৰচা {career} টিউটোৰিয়েল",
    "ଓଡ଼ିଆ": "YouTube: ମାଗଣା {career} ଟିଉଟୋରିଅଲ୍",
    "मराठी": "YouTube: मोफत {career} ट्युटोरियल्स",
    "தமிழ்": "YouTube: இலவச {career} டியூட்டோரியல்",
    "తెలుగు": "YouTube: ఉచిత {career} ట్యూటోరియల్స్",
    "ಕನ್ನಡ": "YouTube: ಉಚಿತ {career} ಟ್ಯುಟೋರಿಯಲ್ಸ್",
    "മലയാളം": "YouTube: സൗജന്യ {career} ട്യൂട്ടോറിയലുകൾ"
  },
  "Udemy: Free {career} Courses": {
    "English": "Udemy: Free {career} Courses",
    "कश्मीरी": "Udemy: مفت {career} کورسز",
    "ਪੰਜਾਬੀ": "Udemy: ਮੁਫ਼ਤ {career} ਕੋਰਸ",
    "हरियाणवी": "Udemy: मुफ्त {career} कोर्स",
    "हिन्दी": "Udemy: मुफ्त {career} कोर्स",
    "राजस्थानी": "Udemy: मुफ्त {career} कोर्स",
    "भोजपुरी": "Udemy: मुफ्त {career} कोर्स",
    "বাংলা": "Udemy: ফ্রি {career} কোর্স",
    "ગુજરાતી": "Udemy: મફત {career} કોર્સ",
    "অসমীয়া": "Udemy: নিখৰচা {career} কোৰ্ছ",
    "ଓଡ଼ିଆ": "Udemy: ମାଗଣା {career} କୋର୍ସ",
    "मराठी": "Udemy: मोफत {career} कोर्सेस",
    "தமிழ்": "Udemy: இலவச {career} பாடநெறிகள்",
    "తెలుగు": "Udemy: ఉచిత {career} కోర్సులు",
    "ಕನ್ನಡ": "Udemy: ಉಚಿತ {career} ಕೋರ್ಸ್ಗಳು",
    "മലയാളം": "Udemy: സൗജന്യ {career} കോഴ്സുകൾ"
  },
  "Coursera: Free {career} Courses": {
    "English": "Coursera: Free {career} Courses",
    "कश्मीरी": "Coursera: مفت {career} کورسز",
    "ਪੰਜਾਬੀ": "Coursera: ਮੁਫ਼ਤ {career} ਕੋਰਸ",
    "हरियाणवी": "Coursera: मुफ्त {career} कोर्स",
    "हिन्दी": "Coursera: मुफ्त {career} कोर्स",
    "राजस्थानी": "Coursera: मुफ्त {career} कोर्स",
    "भोजपुरी": "Coursera: मुफ्त {career} कोर्स",
    "বাংলা": "Coursera: ফ্রি {career} কোর্স",
    "ગુજરાતી": "Coursera: મફત {career} કોર્સ",
    "অসমীয়া": "Coursera: নিখৰচা {career} কোৰ্ছ",
    "ଓଡ଼ିଆ": "Coursera: ମାଗଣା {career} କୋର୍ସ",
    "मराठी": "Coursera: मोफत {career} कोर्सेस",
    "தமிழ்": "Coursera: இலவச {career} பாடநெறிகள்",
    "తెలుగు": "Coursera: ఉచిత {career} కోర్సులు",
    "ಕನ್ನಡ": "Coursera: ಉಚಿತ {career} ಕೋರ್ಸ್ಗಳು",
    "മലയാളം": "Coursera: സൗജന്യ {career} കോഴ്സുകൾ"
  },
  "Class Central: {career} Courses": {
    "English": "Class Central: {career} Courses",
    "कश्मीरी": "Class Central: {career} کورسز",
    "ਪੰਜਾਬੀ": "Class Central: {career} ਕੋਰਸ",
    "हरियाणवी": "Class Central: {career} कोर्स",
    "हिन्दी": "Class Central: {career} कोर्स",
    "राजस्थानी": "Class Central: {career} कोर्स",
    "भोजपुरी": "Class Central: {career} कोर्स",
    "বাংলা": "Class Central: {career} কোর্স",
    "ગુજરાતી": "Class Central: {career} કોર્સ",
    "অসমীয়া": "Class Central: {career} কোৰ্ছ",
    "ଓଡ଼ିଆ": "Class Central: {career} କୋର୍ସ",
    "मराठी": "Class Central: {career} कोर्सेस",
    "தமிழ்": "Class Central: {career} பாடநெறிகள்",
    "తెలుగు": "Class Central: {career} కోర్సులు",
    "ಕನ್ನಡ": "Class Central: {career} ಕೋರ್ಸುಗಳು",
    "മലയാളം": "Class Central: {career} കോഴ്സുകൾ"
  },
  "edX: Free {career} Courses": {
    "English": "edX: Free {career} Courses",
    "कश्मीरी": "edX: مفت {career} کورسز",
    "ਪੰਜਾਬੀ": "edX: ਮੁਫ਼ਤ {career} ਕੋਰਸ",
    "हरियाणवी": "edX: मुफ्त {career} कोर्स",
    "हिन्दी": "edX: मुफ्त {career} कोर्स",
    "राजस्थानी": "edX: मुफ्त {career} कोर्स",
    "भोजपुरी": "edX: मुफ्त {career} कोर्स",
    "বাংলা": "edX: ফ্রি {career} কোর্স",
    "ગુજરાતી": "edX: મફત {career} કોર્સ",
    "অসমীয়া": "edX: নিখৰচা {career} কোৰ্ছ",
    "ଓଡ଼ିଆ": "edX: ମାଗଣା {career} କୋର୍ସ",
    "मराठी": "edX: मोफत {career} कोर्सेस",
    "தமிழ்": "edX: இலவச {career} பாடநெறிகள்",
    "తెలుగు": "edX: ఉచిత {career} కోర్సులు",
    "ಕನ್ನಡ": "edX: ಉಚಿತ {career} ಕೋರ್ಸ್ಗಳು",
    "മലയാളം": "edX: സൗജന്യ {career} കോഴ്സുകൾ"
  }
};
const Map<String, List<String>> translations = {
  'enterJoinCode': [
    // Kashmiri (using a style similar to Urdu)
    'جوٚن کوڈ داخل کریں',
    // Punjabi (Gurmukhi)
    'ਜੋੜਨ ਕੋਡ ਦਰਜ ਕਰੋ',
    // Haryanvi (similar to Hindi)
    'जॉइन कोड भरें',
    // Hindi
    'जॉइन कोड दर्ज करें',
    // Rajasthani
    'जॉइन कोड डालो',
    // Bhojpuri
    'जॉइन कोड दर्ज करीं',
    // Bengali
    'যোগ কোড লিখুন',
    // Gujarati
    'જોઈન કોડ દાખલ કરો',
    // Assamese
    'যোগ কোড প্ৰৱেশ কৰক',
    // Odia
    'ଜୋଇନ୍ କୋଡ୍ ପ୍ରବେଶ କରନ୍ତୁ',
    // Marathi
    'जॉइन कोड प्रविष्ट करा',
    // Tamil
    'சேரும் குறியீட்டை உள்ளிடவும்',
    // Telugu
    'జాయిన్ కోడ్ నమోదు చేయండి',
    // Kannada
    'ಜೋನ್ ಕೋಡ್ ನಮೂದಿಸಿ',
    // Malayalam
    'ജോയിൻ കോഡ് നൽകുക',
    // English
    'Enter Join Code',
  ],
  'cancel': [
    'کینسل کریں',
    'ਰੱਦ ਕਰੋ',
    'रद्द कर दे',
    'रद्द करें',
    'रद्द करो',
    'रद्द करीं',
    'বাতিল করুন',
    'રદ્દ કરો',
    'বাতিল কৰক',
    'ବାତିଲ୍ କରନ୍ତୁ',
    'रद्द करा',
    'ரத்து செய்',
    'రద్దు చేయండి',
    'ರದ್ದುಮಾಡಿ',
    'റദ്ദാക്കുക',
    'Cancel',
  ],
  'join': [
    'جوٚن کریں',
    'ਜੋੜੋ',
    'जॉइन हो',
    'शामिल हों',
    'जॉइन करो',
    'जॉइन करीं',
    'যোগ দিন',
    'જોઇન કરો',
    'যোগ দিন',
    'ଯୋଗ ଦିଅନ୍ତୁ',
    'जॉइन करा',
    'சேரவும்',
    'జాయిన్ అవ్వండి',
    'ಜೋನ್ ಮಾಡಿ',
    'ചേർക്കുക',
    'Join',
  ],
  'incorrectJoinCode': [
    'غلط جوٚن کوڈ.',
    'ਗਲਤ ਜੋੜਨ ਕੋਡ।',
    'गलत जॉइन कोड।',
    'गलत जॉइन कोड।',
    'गलत जॉइन कोड।',
    'गलत जॉइन कोड।',
    'ভুল যোগ কোড।',
    'ખોટો જોડાણ કોડ.',
    'ভুল যোগ কোড।',
    'ଭୁଲ୍ ଜୋଇନ୍ କୋଡ୍।',
    'चुकीचा जॉइन कोड.',
    'தவறான சேரும் குறியீடு.',
    'తప్పు జాయిన్ కోడ్.',
    'ತಪ್ಪು ಜೋನ್ ಕೋಡ್.',
    'തെറ്റായ ജോയിൻ കോഡ്.',
    'Incorrect join code.',
  ],
  'createCommunity': [
    'کمیونٹی تشکیل دیں',
    'ਕਮਿਊਨਿਟੀ ਬਣਾਓ',
    'समुदाय बनाओ',
    'समुदाय बनाएँ',
    'समुदाय बनाओ',
    'समुदाय बनाईं',
    'কমিউনিটি তৈরি করুন',
    'સમુદાય બનાવો',
    'সম্প্ৰদায় সৃষ্টি কৰক',
    'ସମୁଦାୟ ସೃଜନ କରନ୍ତୁ',
    'समुदाय तयार करा',
    'சமூகத்தை உருவாக்கு',
    'సమూహాన్ని సృష్టించండి',
    'ಸಮುದಾಯವನ್ನು ರಚಿಸಿ',
    'സമൂഹം സൃഷ്ടിക്കുക',
    'Create Community',
  ],
  'name': [
    'نام',
    'ਨਾਂ',
    'नाम',
    'नाम',
    'नाम',
    'नाम',
    'নাম',
    'નામ',
    'নাম',
    'ନାମ',
    'नाव',
    'பெயர்',
    'పేరు',
    'ಹೆಸರು',
    'പേര്',
    'Name',
  ],
  'enterName': [
    'ایک نام داخل کریں',
    'ਇੱਕ ਨਾਮ ਦਰਜ ਕਰੋ',
    'एक नाम भरें',
    'एक नाम दर्ज करें',
    'एक नाम डालो',
    'एक नाम दर्ज करीं',
    'একটি নাম লিখুন',
    'એક નામ દાખલ કરો',
    'এখন নাম প্ৰৱেশ কৰক',
    'ଏକ ନାମ ପ୍ରବେଶ କରନ୍ତୁ',
    'एक नाव प्रविष्ट करा',
    'ஒரு பெயரை உள்ளிடவும்',
    'ఒక పేరు నమోదు చేయండి',
    'ಒಂದು ಹೆಸರನ್ನು ನಮೂದಿಸಿ',
    'ഒരു പേര് നൽകുക',
    'Enter a name',
  ],
  'description': [
    'تفصیل',
    'ਵੇਰਵਾ',
    'विवरण',
    'विवरण',
    'विवरण',
    'विवरण',
    'বর্ণনা',
    'વર્ણન',
    'বিৱৰণ',
    'ବର୍ଣ୍ଣନା',
    'वर्णन',
    'விவரம்',
    'వివరణ',
    'ವಿವರಣೆ',
    'വിവരണം',
    'Description',
  ],
  'enterDescription': [
    'ایک تفصیل داخل کریں',
    'ਇੱਕ ਵੇਰਵਾ ਦਰਜ ਕਰੋ',
    'एक विवरण भरें',
    'एक विवरण दर्ज करें',
    'एक विवरण डालो',
    'एक विवरण दर्ज करीं',
    'একটি বর্ণনা লিখুন',
    'એક વર્ણન દાખલ કરો',
    'এখন বিৱৰণ প্ৰৱেশ কৰক',
    'ଏକ ବର୍ଣ୍ଣନା ପ୍ରବେଶ କରନ୍ତୁ',
    'एक वर्णन प्रविष्ट करा',
    'ஒரு விவரத்தை உள்ளிடவும்',
    'ఒక వివరణ నమోదు చేయండి',
    'ಒಂದು ವಿವರಣೆಯನ್ನು ನಮೂದಿಸಿ',
    'ഒരു വിവരണം നൽകുക',
    'Enter a description',
  ],
  'selectImage': [
    'تصویر منتخب کریں',
    'ਤਸਵੀਰ ਚੁਣੋ',
    'चित्र चुनो',
    'चित्र चुनें',
    'चित्र चुनो',
    'चित्र चुनल जाव',
    'ছবি নির্বাচন করুন',
    'છબી પસંદ કરો',
    'চিত্ৰ বাচক কৰক',
    'ଛବି ବାଛନ୍ତୁ',
    'प्रतिमा निवडा',
    'படத்தை தேர்ந்தெடுக்கவும்',
    'చిత్రాన్ని ఎంచుకోండి',
    'ಚಿತ್ರ ಆಯ್ಕೆಮಾಡಿ',
    'ചിത്രം തിരഞ്ഞെടുക്കുക',
    'Select Image',
  ],
  'publicCommunity': [
    'عوامی کمیونٹی',
    'ਸਾਰਵਜਨਿਕ ਕਮਿਊਨਿਟੀ',
    'सार्वजनिक समुदाय',
    'सार्वजनिक समुदाय',
    'सार्वजनिक समुदाय',
    'सार्वजनिक समुदाय',
    'সার্বজনীন কমিউনিটি',
    'જાહેર સમુદાય',
    'সাৰ্বজনীন সম্প্ৰদায়',
    'ସାର୍ବଜନୀନ ସମୁଦାୟ',
    'सार्वजनिक समुदाय',
    'பொது சமூக',
    'ప్రజా సంఘం',
    'ಸಾರ್ವಜನಿಕ ಸಮುದಾಯ',
    'പൊതു സമൂഹം',
    'Public Community',
  ],
  'enterJoinCodeInvite': [
    'صرف دعوتی کمیونٹی کے لیے جوٚن کوڈ داخل کریں',
    'ਨਿਮੰਤ੍ਰਿਤ ਸਮੁਦਾਇ ਲਈ ਜੋੜਨ ਕੋਡ ਦਰਜ ਕਰੋ',
    'निमंत्रण वाली समुदाय के लिए जॉइन कोड दर्ज करें',
    'निमंत्रण-केवल समुदाय के लिए जॉइन कोड दर्ज करें',
    'निमंत्रण-केवल समुदाय के लिए जॉइन कोड डालो',
    'निमंत्रण-केवल समुदाय खातिर जॉइन कोड दर्ज करीं',
    'ইনভাইট-ওনলি কমিউনিটির জন্য যোগ কোড লিখুন',
    'નિમંત્રણ પર આધારિત સમુદાય માટે જોડાણ કોડ દાખલ કરો',
    'অহ্বানৰ বাবে বিশেষ সম্প্ৰদায়ৰ বাবে যোগ কোড প্ৰৱেশ কৰক',
    'ମାତ୍ର ଆମନ୍ତ୍ରିତ ସମୁଦାୟ ପାଇଁ ଜୋଇନ୍ କୋଡ୍ ପ୍ରବେଶ କରନ୍ତୁ',
    'फक्त निमंत्रणासाठीच्या समुदायासाठी जॉइन कोड प्रविष्ट करा',
    'அழைப்புக்கேற்ப சமூகத்திற்கு சேரும் குறியீட்டை உள்ளிடவும்',
    'ఆహ్వానితుల కోసం మాత్రమే ఉన్న కమ్యూనిటీకి జాయిన్ కోడ్ నమోదు చేయండి',
    'ಅಹ್ವಾನಿತ ಸಮುದಾಯಕ್ಕೆ ಸೇರಲು ಕೋಡ್ ನಮೂದಿಸಿ',
    'ആഹ്വാനമുള്ള സമുദായത്തിനുള്ള ജോയിൻ കോഡ് നൽകുക',
    'Enter a join code for invite-only community',
  ],
  'create': [
    'تخلیق کریں',
    'ਬਣਾਓ',
    'बनाओ',
    'बनाएँ',
    'बनाओ',
    'बनाईं',
    'তৈরি করুন',
    'બણાવો',
    'সৃষ্টি কৰক',
    'ତିଆରି କରନ୍ତୁ',
    'तयार करा',
    'உருவாக்கு',
    'సృష్టించండి',
    'ರಚಿಸಿ',
    'സൃഷ്ടിക്കുക',
    'Create',
  ],
  'joined': [
    'شامل ہو گئے',
    'ਸ਼ਾਮਿਲ ਹੋ ਚੁੱਕੇ',
    'शामिल हो गए',
    'शामिल हो गए',
    'शामिल हो गए',
    'जॉइन हो गइल',
    'যোগদান করা হয়েছে',
    'જોડાયા',
    'যোগদান কৰা হৈছে',
    'ଜୋଡି ହୋଇଛି',
    'जॉइन झाले',
    'சேர்ந்துவிட்டது',
    'చేరినది',
    'ಸೇರಿದೆ',
    'ചേര്‍ന്നു',
    'JOINED',
  ],
  'userNotLoggedIn': [
    'یوزر لاگ ان نہ ہوٙ',
    'ਵਰਤੋਂਕਾਰ ਲਾਗਿਨ ਨਹੀਂ ਕੀਤਾ।',
    'यूजर लॉग इन नहीं है।',
    'उपयोगकर्ता लॉग इन नहीं है।',
    'यूजर लॉग इन नहीं है।',
    'यूजर लॉग इन नइखे।',
    'ব্যবহারকারী লগ ইন করেনি।',
    'વપરાશકર્તા લોગિન નથી',
    'ব্যৱহাৰকাৰী লগ ইন কৰা নাই।',
    'ଉପଭୋକ୍ତା ଲଗଇନ୍ କରିନାହାନ୍ତି',
    'वापरकर्ता लॉग इन नाही आहे.',
    'பயனர் உள்நுழையவில்லை.',
    'వాడుకరి లాగిన్ కాలేదు.',
    'ಬಳಕೆದಾರ ಲಾಗಿನ್ ಆಗಿಲ್ಲ.',
    'ഉപയോക്താവ് ലോഗിൻ ചെയ്തിട്ടില്ല.',
    'User not logged in.',
  ],
  'noCommunitiesAvailable': [
    'کوئی کمیونٹی دستیاب نہیں',
    'ਕੋਈ ਕਮਿਊਨਿਟੀ ਉਪਲਬਧ ਨਹੀਂ',
    'कोई समुदाय उपलब्ध नहीं है',
    'कोई समुदाय उपलब्ध नहीं है',
    'कोई समुदाय उपलब्ध नहीं है',
    'कवनो समुदाय उपलब्ध नइखे',
    'কোনও কমিউনিটি উপলব্ধ নয়',
    'કોઈ સમુદાય ઉપલબ્ધ નથી',
    'কোনো সম্প্ৰদায় উপলব্ধ নাই',
    'କୌଣସି ସମୁଦାୟ ଉପଲବ୍ଧ ନୁହେଁ',
    'कोणतेही समुदाय उपलब्ध नाहीत',
    'எந்த சமூகமும் இல்லை',
    'ఏ కమ్యూనిటీ లభ్యం లేదు',
    'ಯಾವುದೇ ಸಮುದಾಯ ಲಭ್ಯವಿಲ್ಲ',
    'ഏതെങ്കിലും സമൂഹം ലഭ്യമല്ല',
    'No communities available',
  ],
  'noCommunitiesFound': [
    'کوئی کمیونٹی نہیں ملی',
    'ਕੋਈ ਕਮਿਊਨਿਟੀ ਨਹੀਂ ਮਿਲੀ',
    'कोई समुदाय नहीं मिला',
    'कोई समुदाय नहीं मिला',
    'कोई समुदाय नहीं मिला',
    'कवनो समुदाय ना मिलल',
    'কোনও কমিউনিটি পাওয়া যায়নি',
    'કોઈ સમુદાય મળ્યો નથી',
    'কোনো সম্প্ৰদায় পোৱা নগল',
    'କୌଣସି ସମୁଦାୟ ମିଳିନାହିଁ',
    'कोणतेही समुदाय सापडले नाहीत',
    'எந்த சமூகமும் கிடைக்கவில்லை',
    'ఏ కమ్యూనిటీ కనబడలేదు',
    'ಯಾವುದೇ ಸಮುದಾಯ ಕಂಡುಬಂದಿಲ್ಲ',
    'ഏതെങ്കിലും സമൂഹം കണ്ടെത്തിയിട്ടില്ല',
    'No communities found',
  ],
};

String translate(String key, int languageIndex) {
  return translations[key]?[languageIndex] ?? translations[key]?[15] ?? key;
}

class CommunityPage extends StatefulWidget {
  final int languageIndex;

  const CommunityPage({Key? key, required this.languageIndex})
      : super(key: key);

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final DatabaseReference _communitiesRef =
      FirebaseDatabase.instance.ref().child('communities');
  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  int coinBalance = 0;

  void initState() {
    super.initState();
    _loadUserData();
  }

  XFile? imageFile;
  Future<void> _loadUserData() async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (userId.isEmpty) {
      debugPrint("User is not authenticated.");
      return;
    }

    final DatabaseReference userRef =
    FirebaseDatabase.instance.ref().child('users').child(userId);
    final DataSnapshot snapshot = await userRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      setState(() {
        coinBalance = data['coins'] != null ? int.parse(data['coins'].toString()) : 0;
      });
    } else {
      setState(() {
        coinBalance = 0;
      });
      await userRef.set({'coins': 0});
    }
  }
  // Helper: Join community by adding the current user's uid to the members list
  Future<void> joinCommunity(Community community) async {
    if (currentUserId == null) return;
    final communityRef = _communitiesRef.child(community.key).child('members');
    try {
      await communityRef.update({currentUserId!: true});
      print('User $currentUserId joined community ${community.key}');
    } catch (e) {
      print('Error joining community: $e');
    }
  }

  String getLanguageFromIndex(int index) {
    switch (index) {
      case 0:
        return "कश्मीरी";
      case 1:
        return "ਪੰਜਾਬੀ";
      case 2:
        return "हरियाणवी";
      case 3:
        return "हिन्दी";
      case 4:
        return "राजस्थानी";
      case 5:
        return "भोजपुरी";
      case 6:
        return "বাংলা";
      case 7:
        return "ગુજરાતી";
      case 8:
        return "অসমীয়া";
      case 9:
        return "ଓଡ଼ିଆ";
      case 10:
        return "मराठी";
      case 11:
        return "தமிழ்";
      case 12:
        return "తెలుగు";
      case 13:
        return "ಕನ್ನಡ";
      case 14:
        return "മലയാളം";
      case 15:
      default:
        return "English";
    }
  }
  int getLanguageIndex(String lang) {
    switch (lang) {
      case "कश्मीरी":
        return 0;
      case "ਪੰਜਾਬੀ":
        return 1;
      case "हरियाणवी":
        return 2;
      case "हिन्दी":
        return 3;
      case "राजस्थानी":
        return 4;
      case "भोजपुरी":
        return 5;
      case "বাংলা":
        return 6;
      case "ગુજરાતી":
        return 7;
      case "অসমীয়া":
        return 8;
      case "ଓଡ଼ିଆ":
        return 9;
      case "मराठी":
        return 10;
      case "தமிழ்":
        return 11;
      case "తెలుగు":
        return 12;
      case "ಕನ್ನಡ":
        return 13;
      case "മലയാളം":
        return 14;
      case "English":
      default:
        return 15;
    }
  }

  String _tr(String key, {Map<String, String>? params}) {
    final translations = localizedTexts[key];
    String lang=getLanguageFromIndex(widget.languageIndex);
    String translated = translations?[lang] ?? translations?["English"] ?? key;
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        translated = translated.replaceAll('{$paramKey}', paramValue);
      });
    }
    return translated;
  }

  // If the community is invite-only, ask for join code.
  Future<void> _showJoinCodeDialog(Community community) async {
    String enteredCode = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101010),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          translate('enterJoinCode', widget.languageIndex),
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          onChanged: (value) {
            enteredCode = value;
          },
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: translate('join', widget.languageIndex) +
                ' ' +
                translate('joinCode', widget.languageIndex),
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF5BC0EB)),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BC0EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    translate('cancel', widget.languageIndex),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BC0EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (enteredCode.trim() == community.joinCode) {
                      await joinCommunity(community);
                      Navigator.of(context).pop();
                      setState(() {}); // refresh UI
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            translate(
                                'incorrectJoinCode', widget.languageIndex),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    translate('join', widget.languageIndex),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Future<void> _awardCoins(int coins) async {
    setState(() {
      coinBalance += coins;
    });
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final DatabaseReference ref =
    FirebaseDatabase.instance.ref().child('users').child(userId);
    await ref.update({'coins': coinBalance});
  }
  void _showCoinPopup(int coinsAwarded) async {
    await showRewardPopup<String>(
      context,
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monetization_on,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              Text(
                _tr('Congratulations!'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _tr('You have received {coins} coins!',
                    params: {"coins": coinsAwarded.toString()}),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFFD1D1D1),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5BC0EB),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _tr('Awesome!'),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Create community dialog with refined UI.
 /* Future<void> _showCreateCommunityDialog() async {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String description = '';
    bool isPublic = true;
    String joinCode = '';

    Future<void> _pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          imageFile = pickedFile;
        });
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            backgroundColor: const Color(0xFF101010),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: Text(
              translate('createCommunity', widget.languageIndex),
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: translate('name', widget.languageIndex),
                        labelStyle: const TextStyle(color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[800]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Color(0xFF5BC0EB)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) => name = value,
                      validator: (value) => value == null || value.isEmpty
                          ? translate('enterName', widget.languageIndex)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText:
                            translate('description', widget.languageIndex),
                        labelStyle: const TextStyle(color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[800]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Color(0xFF5BC0EB)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) => description = value,
                      validator: (value) => value == null || value.isEmpty
                          ? translate('enterDescription', widget.languageIndex)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5BC0EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.image, color: Colors.white),
                        label: Text(
                          translate('selectImage', widget.languageIndex),
                          style: const TextStyle(color: Colors.white),
                        ),
                        onPressed: () async {
                          await _pickImage();
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: Text(
                        translate('publicCommunity', widget.languageIndex),
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: isPublic,
                      activeColor: const Color(0xFF5BC0EB),
                      onChanged: (value) {
                        setStateSB(() {
                          isPublic = value;
                        });
                      },
                    ),
                    if (!isPublic)
                      Column(
                        children: [
                          const SizedBox(height: 10),
                          TextFormField(
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: translate(
                                      'join', widget.languageIndex) +
                                  ' ' +
                                  translate('joinCode', widget.languageIndex),
                              labelStyle: const TextStyle(color: Colors.white),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey[800]!),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Color(0xFF5BC0EB)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (value) => joinCode = value,
                            validator: (value) => (!isPublic &&
                                    (value == null || value.isEmpty))
                                ? translate(
                                    'enterJoinCodeInvite', widget.languageIndex)
                                : null,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BC0EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        translate('cancel', widget.languageIndex),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2), // Added spacing between buttons
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BC0EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          if (currentUserId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  translate(
                                      'userNotLoggedIn', widget.languageIndex),
                                ),
                              ),
                            );
                            return;
                          }
                          final newCommunityRef = _communitiesRef.push();
                          String imageUrl = '';
                          // Convert image to Base64 string if selected.
                          if (imageFile != null) {
                            try {
                              final bytes = await imageFile!.readAsBytes();
                              imageUrl = base64Encode(bytes);
                            } catch (e) {
                              print('Error converting image: $e');
                            }
                          }
                          await newCommunityRef.set({
                            'name': name,
                            'description': description,
                            'imageUrl': imageUrl,
                            'isPublic': isPublic,
                            'joinCode': isPublic ? '' : joinCode,
                            'members': {currentUserId!: true},
                            'createdAt': DateTime.now().millisecondsSinceEpoch,
                          });
                          print(
                              'Community created with key: ${newCommunityRef.key}');
                          Navigator.of(context).pop();
                          setState(() {}); // refresh UI to show new community
                        }
                      },
                      child: Text(
                        translate('create', widget.languageIndex),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }*/
  Future<void> _showCreateCommunityDialog() async {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String description = '';
    bool isPublic = true;
    String joinCode = '';

    Future<void> _pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          imageFile = pickedFile;
        });
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            backgroundColor: const Color(0xFF101010),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: Text(
              translate('createCommunity', widget.languageIndex),
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: translate('name', widget.languageIndex),
                        labelStyle: const TextStyle(color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[800]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFF5BC0EB)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) => name = value,
                      validator: (value) =>
                      value == null || value.isEmpty ? translate('enterName', widget.languageIndex) : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: translate('description', widget.languageIndex),
                        labelStyle: const TextStyle(color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[800]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFF5BC0EB)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) => description = value,
                      validator: (value) => value == null || value.isEmpty
                          ? translate('enterDescription', widget.languageIndex)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5BC0EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.image, color: Colors.white),
                        label: Text(
                          translate('selectImage', widget.languageIndex),
                          style: const TextStyle(color: Colors.white),
                        ),
                        onPressed: () async {
                          await _pickImage();
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: Text(
                        translate('publicCommunity', widget.languageIndex),
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: isPublic,
                      activeColor: const Color(0xFF5BC0EB),
                      onChanged: (value) {
                        setStateSB(() {
                          isPublic = value;
                        });
                      },
                    ),
                    if (!isPublic)
                      Column(
                        children: [
                          const SizedBox(height: 10),
                          TextFormField(
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: translate('join', widget.languageIndex) +
                                  ' ' +
                                  translate('joinCode', widget.languageIndex),
                              labelStyle: const TextStyle(color: Colors.white),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey[800]!),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Color(0xFF5BC0EB)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (value) => joinCode = value,
                            validator: (value) => (!isPublic && (value == null || value.isEmpty))
                                ? translate('enterJoinCodeInvite', widget.languageIndex)
                                : null,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BC0EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        translate('cancel', widget.languageIndex),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BC0EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          if (currentUserId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(translate('userNotLoggedIn', widget.languageIndex)),
                              ),
                            );
                            return;
                          }
                          final newCommunityRef = _communitiesRef.push();
                          String imageUrl = '';
                          // Convert image to Base64 string if selected.
                          if (imageFile != null) {
                            try {
                              final bytes = await imageFile!.readAsBytes();
                              imageUrl = base64Encode(bytes);
                            } catch (e) {
                              print('Error converting image: $e');
                            }
                          }
                          await newCommunityRef.set({
                            'name': name,
                            'description': description,
                            'imageUrl': imageUrl,
                            'isPublic': isPublic,
                            'joinCode': isPublic ? '' : joinCode,
                            'members': {currentUserId!: true},
                            'createdAt': DateTime.now().millisecondsSinceEpoch,
                          });
                          print('Community created with key: ${newCommunityRef.key}');
                          Navigator.of(context).pop();

                          // Award coins based on community type.
                          final int coinsAwarded = isPublic ? 20 : 10;
                          await _awardCoins(coinsAwarded);
                          _showCoinPopup(coinsAwarded);

                          setState(() {}); // Refresh UI to show new community.
                        }
                      },
                      child: Text(
                        translate('create', widget.languageIndex),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
  // Build each community card with refined UI.
  Widget _buildCommunityCard(Community community) {
    final bool isJoined = community.members != null &&
        community.members!.containsKey(currentUserId);
    return Card(
      color: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (isJoined) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommunityChatPage(
                    community: community, languageIndex: widget.languageIndex),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Community image at the top (decodes the Base64 string)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: community.imageUrl.isNotEmpty
                  ? Image.memory(
                      base64Decode(community.imageUrl),
                      height: 150,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 150,
                      color: Colors.grey[800],
                      child: const Icon(Icons.group,
                          color: Colors.white, size: 50),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and JOINED badge if applicable
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          community.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isJoined)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5BC0EB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            translate('joined', widget.languageIndex),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description with ellipsis.
                  Text(
                    community.description,
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Join button if not already a member
            if (!isJoined)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BC0EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (community.isPublic) {
                      await joinCommunity(community);
                      setState(() {});
                    } else {
                      await _showJoinCodeDialog(community);
                    }
                  },
                  child: Text(
                    translate('join', widget.languageIndex),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build list view for communities.
  Widget _buildCommunityList(List<Community> communities) {
    if (communities.isEmpty) {
      return Center(
        child: Text(
          translate('noCommunitiesAvailable', widget.languageIndex),
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: communities.length,
      itemBuilder: (context, index) {
        return _buildCommunityCard(communities[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: StreamBuilder(
          stream: _communitiesRef.onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BC0EB)),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
              return Center(
                child: Text(
                  translate('noCommunitiesFound', widget.languageIndex),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            Map<dynamic, dynamic> communitiesMap =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            List<Community> communities = [];
            communitiesMap.forEach((key, value) {
              communities.add(Community.fromData(key, value));
            });
            return _buildCommunityList(communities);
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF5BC0EB),
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: _showCreateCommunityDialog,
        ),
      ),
    );
  }
}
