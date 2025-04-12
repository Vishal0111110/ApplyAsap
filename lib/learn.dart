import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'web.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:reward_popup/reward_popup.dart';
import 'question_data.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class CareerGeminiPage extends StatefulWidget {
  final String career;
  final QuestionData ans;
  final String lang;

  const CareerGeminiPage({
    Key? key,
    required this.career,
    required this.ans,
    required this.lang,
  }) : super(key: key);

  @override
  _CareerGeminiPageState createState() => _CareerGeminiPageState();
}

class _CareerGeminiPageState extends State<CareerGeminiPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, String>> freeCourseLinks = [];
  List<Question> questions = [];
  int coinBalance = 0;
  bool _isCoursesLoading = false;
  bool _isQuestionsLoading = false;
  late TabController _tabController;
  final TextEditingController _courseCustomController = TextEditingController();
  final TextEditingController _questionCustomController = TextEditingController();
  Map<String, dynamic> _submittedQuestions = {};

  late int languageIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    languageIndex = getLanguageIndex(widget.lang);
    _loadUserData(); // Load coin balance and submitted question data
    _initiateLinkGeminiCall();
    _initiateQuestionGeminiCall();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _courseCustomController.dispose();
    _questionCustomController.dispose();
    super.dispose();
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
    String translated = translations?[widget.lang] ?? translations?["English"] ?? key;
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        translated = translated.replaceAll('{$paramKey}', paramValue);
      });
    }
    return translated;
  }

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
    final DatabaseReference submittedRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId)
        .child('submittedQuestions');
    final DataSnapshot submittedSnapshot = await submittedRef.get();
    if (submittedSnapshot.exists) {
      final submittedData = submittedSnapshot.value as Map;
      setState(() {
        _submittedQuestions = Map<String, dynamic>.from(submittedData);
      });
    }
  }

  Future<void> _initiateLinkGeminiCall({String? customQuery}) async {
    setState(() {
      _isCoursesLoading = true;
    });

    try {
      String systemPrompt =
      (customQuery == null || customQuery.trim().isEmpty)
          ? "Provide specific free course links for the career domain '${widget.career}' in '${widget.lang}'. Include links from YouTube, Udemy, Coursera, ClassCentral, edX, FutureLearn, and any other reputable platforms. Return the results as a valid JSON array, where each item has a 'title' (string) and a 'url' (string)."
          : "Provide specific free course links related to '$customQuery' for the career domain '${widget.career}' in '${widget.lang}'. Include links from YouTube, Udemy, Coursera, ClassCentral, edX, FutureLearn, and any other reputable platforms. Return the results as a valid JSON array, where each item has a 'title' (string) and a 'url' (string).";

      String userPrompt =
      (customQuery == null || customQuery.trim().isEmpty)
          ? "Fetch free course links for '${widget.career}' in '${widget.lang}'."
          : "Generate free course links related to $customQuery for '${widget.career}' in '${widget.lang}'.";

      String freeCoursesResponse = await _fetchResultFromGemini(
        systemString: systemPrompt,
        userString: userPrompt,
      );
      debugPrint("Raw Gemini free course response: $freeCoursesResponse");

      final parsed = jsonDecode(freeCoursesResponse);
      if (parsed is List) {
        freeCourseLinks = List<Map<String, String>>.from(parsed.map((item) {
          return {
            'title': item['title'] as String,
            'url': item['url'] as String,
          };
        }));
      }
    } catch (e) {
      debugPrint("Error fetching Gemini free course links: $e");
    }

    if (freeCourseLinks.isEmpty) {
      freeCourseLinks = [
        {
          'title': _tr("YouTube: Free {career} Tutorials", params: {"career": widget.career}),
          'url': 'https://www.youtube.com/results?search_query=${widget.career}+tutorial+${widget.lang}'
        },
        {
          'title': _tr("Udemy: Free {career} Courses", params: {"career": widget.career}),
          'url': 'https://www.udemy.com/courses/free/?q=${widget.career}+${widget.lang}'
        },
        {
          'title': _tr("Coursera: Free {career} Courses", params: {"career": widget.career}),
          'url': 'https://www.coursera.org/courses?query=${widget.career}+${widget.lang}&price=free'
        },
        {
          'title': _tr("Class Central: {career} Courses", params: {"career": widget.career}),
          'url': 'https://www.classcentral.com/search?q=${widget.career}+${widget.lang}'
        },
        {
          'title': _tr("edX: Free {career} Courses", params: {"career": widget.career}),
          'url': 'https://www.edx.org/learn/${widget.career}?language=${widget.lang}'
        },
      ];
    }

    setState(() {
      _isCoursesLoading = false;
    });
  }


  Future<void> _initiateQuestionGeminiCall({String? customQuery, bool append = false}) async {
    setState(() {
      _isQuestionsLoading = true;
    });
    try {
      String systemPrompt = customQuery == null || customQuery.trim().isEmpty
          ? "Generate multiple choice practice questions for the career '${widget.career}'. Each question must be returned as a valid JSON object with keys: 'questionText', 'options' (an array of four strings), and 'correctOptionIndex' (an integer between 0 and 3). Return an array of these JSON objects."
          : "Generate multiple choice practice questions related to '$customQuery' for the career '${widget.career}'. Each question must be returned as a valid JSON object with keys: 'questionText', 'options' (an array of four strings), and 'correctOptionIndex' (an integer between 0 and 3). Return an array of these JSON objects.";

      String userPrompt = customQuery == null || customQuery.trim().isEmpty
          ? "Generate practice questions."
          : "Generate practice questions related to $customQuery.";

      String questionResponse = await _fetchResultFromGemini(
        systemString: systemPrompt,
        userString: userPrompt,
      );
      debugPrint("Raw Gemini question response: $questionResponse");
      final dynamic parsedResponse = jsonDecode(questionResponse);
      List<dynamic> questionListJson;
      if (parsedResponse is List) {
        questionListJson = parsedResponse;
      } else {
        throw Exception("Unexpected JSON format: Not a List");
      }
      List<Question> generatedQuestions = questionListJson.map((jsonItem) {
        return Question(
          questionText: jsonItem['questionText'] as String,
          options: List<String>.from(jsonItem['options'] as List),
          correctOptionIndex: jsonItem['correctOptionIndex'] as int,
        );
      }).toList();

      setState(() {
        if (append) {
          questions.addAll(generatedQuestions);
        } else {
          questions = generatedQuestions;
        }
      });
    } catch (e) {
      debugPrint("Error generating questions via Gemini: $e");
      setState(() {
        questions = [
          Question(
            questionText: _tr("What does Flutter primarily use for building UIs?"),
            options: [
              _tr("Dart"),
              _tr("JavaScript"),
              _tr("Kotlin"),
              _tr("Swift")
            ],
            correctOptionIndex: 0,
          ),
          Question(
            questionText: _tr("Which company developed Flutter?"),
            options: [
              _tr("Apple"),
              _tr("Google"),
              _tr("Microsoft"),
              _tr("Facebook")
            ],
            correctOptionIndex: 1,
          ),
          Question(
            questionText: _tr("What programming language is used with Flutter?"),
            options: [
              _tr("Dart"),
              _tr("Python"),
              _tr("Ruby"),
              _tr("C#")
            ],
            correctOptionIndex: 0,
          ),
        ];
      });
    }
    setState(() {
      _isQuestionsLoading = false;
    });
  }

  String _cleanGeminiResponse(String response) {
    response = response.trim();
    if (response.startsWith('```') && response.endsWith('```')) {
      response = response.substring(3, response.length - 3).trim();
    }
    int start = response.indexOf('[');
    int end = response.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      return response.substring(start, end + 1);
    }
    return response;
  }

  Future<String> _fetchResultFromGemini({
    required String systemString,
    required String userString,
  }) async {
    final apiKey = await rootBundle.loadString('assets/gemini.key');
    final endpoint =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=json&key=$apiKey";

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': 'system: $systemString'}
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': userString}
            ],
          },
        ],
        'safetySettings': [
          {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
        ],
        'generationConfig': {
          'candidateCount': 1,
          'temperature': 1.2,
          'topP': 0.8,
        },
      }),
    );

    debugPrint('Full Gemini JSON response: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      String text = jsonResponse['candidates'][0]['content']['parts'][0]['text'] as String;
      debugPrint('Extracted Gemini API response before cleaning: $text');
      text = _cleanGeminiResponse(text);
      debugPrint('Cleaned Gemini API response: $text');
      return text;
    } else {
      throw Exception('Failed to fetch Gemini result: ${response.body}');
    }
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


  Future<void> _saveSubmittedQuestion(String questionText, int selectedOption, bool answered) async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final String key = _keyFromQuestion(questionText);
    final DatabaseReference submittedRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId)
        .child('submittedQuestions')
        .child(key);
    await submittedRef.set({
      'selectedOptionIndex': selectedOption,
      'answered': answered,
    });
    setState(() {
      _submittedQuestions[key] = {
        'selectedOptionIndex': selectedOption,
        'answered': answered,
      };
    });
  }

  String _keyFromQuestion(String questionText) {
    return questionText.replaceAll(' ', '_');
  }

  void _checkIndividualAnswer(int questionIndex) {
    final question = questions[questionIndex];
    if (question.selectedOptionIndex == null || question.answered) return;

    bool isCorrect = question.selectedOptionIndex == question.correctOptionIndex;
    setState(() {
      question.answered = true;
    });
    _saveSubmittedQuestion(question.questionText, question.selectedOptionIndex!, true);
    if (isCorrect) {
      _awardCoins(5);
      _showCoinPopup(5);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Your answer is incorrect.'))),
      );
    }
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
                _tr('You have received {coins} coins!', params: {"coins": coinsAwarded.toString()}),
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

  void _showCorrectAnswer(int questionIndex) {
    final question = questions[questionIndex];
    if (!question.answered) return;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF101010),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tr('Correct Answer'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.options[question.correctOptionIndex],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
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
                      _tr('Continue'),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: const Color(0xFF000000),
          title: Text(
            _tr("Learn Now"),
            style: const TextStyle(
              fontSize: 20.0,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            indicatorColor: const Color(0xFF5BC0EB),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            tabs: [
              Tab(
                icon: const Icon(Icons.link, color: Colors.white),
                text: _tr("Free Courses"),
              ),
              Tab(
                icon: const Icon(Icons.question_answer, color: Colors.white),
                text: _tr("Practice Questions"),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFreeCoursesPage(),
            _buildPracticeQuestionsPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeCoursesPage() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Expanded(
            child: _isCoursesLoading
                ? const Center(
              child: SpinKitPouringHourGlassRefined(
                color: Color(0xFF5BC0EB),
                size: 120,
              ),
            )
                : freeCourseLinks.isNotEmpty
                ? ListView.separated(
              itemCount: freeCourseLinks.length,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.grey.shade800),
              itemBuilder: (context, index) {
                final link = freeCourseLinks[index];
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.shade800)),
                  color: const Color(0xFF1F1F1F),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      link['title']!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        link['url']!,
                        style: const TextStyle(color: Color(0xFF5BC0EB), fontSize: 14),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InAppWebViewScreen(
                              url: link['url']!, title: link['title']!),
                        ),
                      );
                    },
                  ),
                );
              },
            )
                : Center(
              child: Text(
                _tr('No courses found'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _courseCustomController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _tr("Enter a custom course query"),
                    hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                    filled: true,
                    fillColor: const Color(0xFF1F1F1F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade800),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5BC0EB),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  _initiateLinkGeminiCall(customQuery: _courseCustomController.text);
                },
                child: Text(
                  _tr("Generate"),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeQuestionsPage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 12.0),
      child: Column(
        children: [
          Expanded(
            child: _isQuestionsLoading
                ? const Center(
              child: SpinKitPouringHourGlassRefined(
                color: Color(0xFF5BC0EB),
                size: 120,
              ),
            )
                : ListView.separated(
              itemCount: questions.length,
              separatorBuilder: (context, index) =>
              const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final question = questions[index];
                return _buildQuestionCard(index, question);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5BC0EB),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      _initiateQuestionGeminiCall(append: true);
                    },
                    child: Text(
                      _tr("Generate More Questions"),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionCustomController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _tr("Enter a custom question query"),
                    hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                    filled: true,
                    fillColor: const Color(0xFF1F1F1F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade800),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5BC0EB),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  _initiateQuestionGeminiCall(customQuery: _questionCustomController.text);
                },
                child: Text(
                  _tr("Generate"),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int questionIndex, Question question) {
    final key = _keyFromQuestion(question.questionText);
    if (_submittedQuestions.containsKey(key)) {
      question.answered = true;
      question.selectedOptionIndex = _submittedQuestions[key]['selectedOptionIndex'];
    }
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade800)),
      color: const Color(0xFF1F1F1F),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.questionText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: List.generate(question.options.length, (optionIndex) {
                bool isSelected = question.selectedOptionIndex == optionIndex;
                return ChoiceChip(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  backgroundColor: const Color(0xFF323232),
                  label: Text(
                    question.options[optionIndex],
                    style: const TextStyle(color: Colors.white),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF5BC0EB),
                  onSelected: question.answered
                      ? null
                      : (selected) {
                    setState(() {
                      question.selectedOptionIndex = optionIndex;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: question.answered
                          ? Colors.green
                          : const Color(0xFF5BC0EB),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      if (!question.answered) {
                        _checkIndividualAnswer(questionIndex);
                      } else {
                        _showCorrectAnswer(questionIndex);
                      }
                    },
                    child: Text(
                      question.answered
                          ? _tr('Show Answer')
                          : _tr('Check Answer'),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class Question {
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  bool answered;
  int? selectedOptionIndex;

  Question({
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    this.answered = false,
    this.selectedOptionIndex,
  });
}
