import 'package:flutter/material.dart';
import 'colors.dart';
import 'web.dart';
import 'category_box.dart';
import 'feature_item.dart';
import 'recommend_item.dart';
import 'dart:convert';

// Provided data lists.
List categories = [
  {"name": "All", "icon": "assets/icons/category/all.svg"},
  {"name": "Coding", "icon": "assets/icons/category/coding.svg"},
  {"name": "Education", "icon": "assets/icons/category/education.svg"},
  {"name": "Design", "icon": "assets/icons/category/design.svg"},
  {"name": "Business", "icon": "assets/icons/category/business.svg"},
  {"name": "Cooking", "icon": "assets/icons/category/cooking.svg"},
  {"name": "Music", "icon": "assets/icons/category/music.svg"},
  {"name": "Art", "icon": "assets/icons/category/art.svg"},
  {"name": "Finance", "icon": "assets/icons/category/finance.svg"},
];

List features = [
  {
    "id": 100,
    "name": "UI/UX Design",
    "image":
        "https://images.unsplash.com/photo-1596638787647-904d822d751e?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹150.00",
    "duration": "10 hours",
    "session": "6 lessons",
    "review": "4.5",
    "is_favorited": false,
    "description":
        "In publishing and graphic design, Lorem ipsum is a placeholder text commonly used to demonstrate the visual form of a document or a typeface without relying on meaningful content. Lorem ipsum may be used as a placeholder before the final copy is available.",
  },
  {
    "id": 101,
    "name": "Programming",
    "image":
        "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹300.00",
    "duration": "20 hours",
    "session": "12 lessons",
    "review": "5",
    "is_favorited": true,
    "description":
        "In publishing and graphic design, Lorem ipsum is a placeholder text commonly used to demonstrate the visual form of a document or a typeface without relying on meaningful content. Lorem ipsum may be used as a placeholder before the final copy is available.",
  },
  {
    "id": 102,
    "name": "English Writing",
    "image":
        "https://images.unsplash.com/photo-1503676260728-1c00da094a0b?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹100.00",
    "duration": "12 hours",
    "session": "4 lessons",
    "review": "4.5",
    "is_favorited": false,
    "description":
        "In publishing and graphic design, Lorem ipsum is a placeholder text commonly used to demonstrate the visual form of a document or a typeface without relying on meaningful content. Lorem ipsum may be used as a placeholder before the final copy is available.",
  },
  {
    "id": 103,
    "name": "Photography",
    "image":
        "https://images.unsplash.com/photo-1472393365320-db77a5abbecc?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹100.00",
    "duration": "4 hours",
    "session": "3 lessons",
    "review": "4.5",
    "is_favorited": false,
    "description":
        "In publishing and graphic design, Lorem ipsum is a placeholder text commonly used to demonstrate the visual form of a document or a typeface without relying on meaningful content. Lorem ipsum may be used as a placeholder before the final copy is available.",
  },
  {
    "id": 104,
    "name": "Guitar Class",
    "image":
        "https://images.unsplash.com/photo-1549298240-0d8e60513026?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹150.00",
    "duration": "12 hours",
    "session": "4 lessons",
    "review": "5",
    "is_favorited": false,
    "description":
        "In publishing and graphic design, Lorem ipsum is a placeholder text commonly used to demonstrate the visual form of a document or a typeface without relying on meaningful content. Lorem ipsum may be used as a placeholder before the final copy is available.",
  },
];

List recommends = [
  {
    "id": 105,
    "name": "Painting",
    "image":
        "https://images.unsplash.com/photo-1596548438137-d51ea5c83ca5?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹60.00",
    "duration": "12 hours",
    "session": "8 lessons",
    "review": "4.5",
    "is_favorited": false,
    "description":
        "In publishing and graphic design, Lorem ipsum is a placeholder text commonly used to demonstrate the visual form of a document or a typeface without relying on meaningful content. Lorem ipsum may be used as a placeholder before the final copy is available.",
  },
  {
    "id": 106,
    "name": "Social Media",
    "image":
        "https://images.unsplash.com/photo-1611162617213-7d7a39e9b1d7?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹100.00",
    "duration": "6 hours",
    "session": "4 lessons",
    "review": "4",
    "is_favorited": false,
    "description":
        "In publishing and graphic design, Lorem ipsum is a placeholder text commonly used to demonstrate the visual form of a document or a typeface without relying on meaningful content. Lorem ipsum may be used as a placeholder before the final copy is available.",
  },
  {
    "id": 107,
    "name": "Caster",
    "image":
        "https://images.unsplash.com/photo-1554446422-d05db23719d2?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹90.00",
    "duration": "8 hours",
    "session": "4 lessons",
    "review": "4.5",
    "is_favorited": false,
    "description":
        "In publishing and graphic design, Lorem ipsum is a placeholder text commonly used to demonstrate the visual form of a document or a typeface without relying on meaningful content. Lorem ipsum may be used as a placeholder before the final copy is available.",
  },
  {
    "id": 108,
    "name": "Management",
    "image":
        "https://images.unsplash.com/photo-1542626991-cbc4e32524cc?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹150.00",
    "duration": "9 hours",
    "session": "5 lessons",
    "review": "4.5",
    "is_favorited": false,
    "description":
        "In publishing and graphic design, Lorem ipsum is a placeholder text commonly used to demonstrate the visual form of a document or a typeface without relying on meaningful content. Lorem ipsum may be used as a placeholder before the final copy is available.",
  }
];

class HomePage extends StatefulWidget {
  final int
      langIndex; // 0: Kashmiri, 1: Punjabi, 2: Haryanvi, 3: Hindi, 4: Rajasthani, 5: Bhojpuri, 6: Bengali, 7: Gujarati, 8: Assamese, 9: Odia, 10: Marathi, 11: Tamil, 12: Telugu, 13: Kannada, 14: Malayalam, 15: English

  const HomePage({Key? key, required this.langIndex}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<ResultData1> futureResult;

  // Localized headings for all languages.
  final Map<int, Map<String, String>> localizedHeadings = {
    0: {
      // Kashmiri
      'categories': '',
      'featured': 'نمایاں',
      'recommended': 'سفارش کی گئی',
    },
    1: {
      // Punjabi
      'categories': '',
      'featured': 'ਮੁੱਖ',
      'recommended': 'ਸਿਫਾਰਸ਼ ਕੀਤੀ',
    },
    2: {
      // Haryanvi
      'categories': '',
      'featured': 'विशेष',
      'recommended': 'सिफारिश',
    },
    3: {
      // Hindi
      'categories': '',
      'featured': 'विशेष',
      'recommended': 'सिफारिश',
    },
    4: {
      // Rajasthani
      'categories': '',
      'featured': 'विशेष',
      'recommended': 'सिफारिश',
    },
    5: {
      // Bhojpuri
      'categories': '',
      'featured': 'विशेष',
      'recommended': 'सिफारिश',
    },
    6: {
      // Bengali
      'categories': '',
      'featured': 'বৈশিষ্ট্যযুক্ত',
      'recommended': 'সুপারিশকৃত',
    },
    7: {
      // Gujarati
      'categories': '',
      'featured': 'ફીચર્ડ',
      'recommended': 'સૂચવાયેલ',
    },
    8: {
      // Assamese
      'categories': '',
      'featured': 'বৈশিষ্ট্যযুক্ত',
      'recommended': 'সুপাৰিশ',
    },
    9: {
      // Odia
      'categories': '',
      'featured': 'ବିଶେଷ',
      'recommended': 'ସୁପାରିଶ',
    },
    10: {
      // Marathi
      'categories': '',
      'featured': 'विशेष',
      'recommended': 'शिफारस',
    },
    11: {
      // Tamil
      'categories': '',
      'featured': 'முக்கியமான',
      'recommended': 'பரிந்துரைக்கப்பட்டது',
    },
    12: {
      // Telugu
      'categories': '',
      'featured': 'ప్రధాన',
      'recommended': 'సిఫార్సు చేయబడింది',
    },
    13: {
      // Kannada
      'categories': '',
      'featured': 'ವಿಶೇಷ',
      'recommended': 'ಶಿಫಾರಸು ಮಾಡಲಾಗಿದೆ',
    },
    14: {
      // Malayalam
      'categories': '',
      'featured': 'പ്രധാന',
      'recommended': 'ശിപാർശ ചെയ്തത്',
    },
    15: {
      // English
      'categories': '',
      'featured': 'Featured',
      'recommended': 'Recommended',
    },
  };

  // Category name translations for all languages.
  final Map<int, Map<String, String>> categoryTranslations = {
    0: {
      // Kashmiri
      "All": "سڀ",
      "Coding": "کوڈنگ",
      "Education": "تعلیم",
      "Design": "ڈیزائن",
      "Business": "کاروبار",
      "Cooking": "پکانا",
      "Music": "موسیقی",
      "Art": "فن",
      "Finance": "مالیات",
    },
    1: {
      // Punjabi
      "All": "ਸਭ",
      "Coding": "ਕੋਡਿੰਗ",
      "Education": "ਸਿੱਖਿਆ",
      "Design": "ਡਿਜ਼ਾਇਨ",
      "Business": "ਵਪਾਰ",
      "Cooking": "ਰਸੋਈ",
      "Music": "ਸੰਗੀਤ",
      "Art": "ਕਲਾ",
      "Finance": "ਵਿੱਤ",
    },
    2: {
      // Haryanvi
      "All": "सभी",
      "Coding": "कोडिंग",
      "Education": "शिक्षा",
      "Design": "डिज़ाइन",
      "Business": "व्यापार",
      "Cooking": "पकाना",
      "Music": "संगीत",
      "Art": "कला",
      "Finance": "वित्त",
    },
    3: {
      // Hindi
      "All": "सभी",
      "Coding": "कोडिंग",
      "Education": "शिक्षा",
      "Design": "डिज़ाइन",
      "Business": "व्यापार",
      "Cooking": "खाना",
      "Music": "संगीत",
      "Art": "कला",
      "Finance": "वित्त",
    },
    4: {
      // Rajasthani
      "All": "सभी",
      "Coding": "कोडिंग",
      "Education": "शिक्षा",
      "Design": "डिज़ाइन",
      "Business": "व्यापार",
      "Cooking": "खाना",
      "Music": "संगीत",
      "Art": "कला",
      "Finance": "वित्त",
    },
    5: {
      // Bhojpuri
      "All": "सभी",
      "Coding": "कोडिंग",
      "Education": "शिक्षा",
      "Design": "डिज़ाइन",
      "Business": "व्यापार",
      "Cooking": "खाना",
      "Music": "संगीत",
      "Art": "कला",
      "Finance": "वित्त",
    },
    6: {
      // Bengali
      "All": "সব",
      "Coding": "কোডিং",
      "Education": "শিক্ষা",
      "Design": "ডিজাইন",
      "Business": "ব্যবসা",
      "Cooking": "রান্না",
      "Music": "সঙ্গীত",
      "Art": "কলা",
      "Finance": "অর্থনীতি",
    },
    7: {
      // Gujarati
      "All": "બધા",
      "Coding": "કોડિંગ",
      "Education": "શિક્ષણ",
      "Design": "ડિઝાઇન",
      "Business": "વ્યવસાય",
      "Cooking": "રસોઈ",
      "Music": "સંગીત",
      "Art": "કલા",
      "Finance": "નાણાકીય",
    },
    8: {
      // Assamese
      "All": "সকলো",
      "Coding": "কোডিং",
      "Education": "শিক্ষা",
      "Design": "ডিজাইন",
      "Business": "ব্যৱসায়",
      "Cooking": "ৰান্ধনি",
      "Music": "সংগীত",
      "Art": "শিল্প",
      "Finance": "আর্থিক",
    },
    9: {
      // Odia
      "All": "ସମସ୍ତ",
      "Coding": "କୋଡିଂ",
      "Education": "ଶିକ୍ଷା",
      "Design": "ଡିଜାଇନ୍",
      "Business": "ବ୍ୟବସାୟ",
      "Cooking": "ରାନ୍ଧଣ",
      "Music": "ସଙ୍ଗୀତ",
      "Art": "ଶିଳ୍ପ",
      "Finance": "ଆର୍ଥିକ",
    },
    10: {
      // Marathi
      "All": "सर्व",
      "Coding": "कोडिंग",
      "Education": "शिक्षण",
      "Design": "डिझाईन",
      "Business": "व्यवसाय",
      "Cooking": "स्वयंपाक",
      "Music": "संगीत",
      "Art": "कला",
      "Finance": "आर्थिक",
    },
    11: {
      // Tamil
      "All": "அனைத்தும்",
      "Coding": "கோடிங்",
      "Education": "கல்வி",
      "Design": "வடிவமைப்பு",
      "Business": "வணிகம்",
      "Cooking": "சமையல்",
      "Music": "இசை",
      "Art": "கலை",
      "Finance": "நிதி",
    },
    12: {
      // Telugu
      "All": "అన్నీ",
      "Coding": "కోడింగ్",
      "Education": "విద్య",
      "Design": "డిజైన్",
      "Business": "వ్యాపారం",
      "Cooking": "వంట",
      "Music": "సంగీతం",
      "Art": "కళ",
      "Finance": "ఆర్థిక",
    },
    13: {
      // Kannada
      "All": "ಎಲ್ಲ",
      "Coding": "ಕೋಡಿಂಗ್",
      "Education": "ಶಿಕ್ಷಣ",
      "Design": "ಡಿಸೈನ್",
      "Business": "ವ್ಯವಹಾರ",
      "Cooking": "ಅಡುಗೆ",
      "Music": "ಸಂಗೀತ",
      "Art": "ಕಲಾ",
      "Finance": "ಆರ್ಥಿಕ",
    },
    14: {
      // Malayalam
      "All": "എല്ലാം",
      "Coding": "കോഡിംഗ്",
      "Education": "വിദ്യാഭ്യാസം",
      "Design": "ഡിസൈൻ",
      "Business": "ബിസിനസ്",
      "Cooking": "പാചകം",
      "Music": "സംഗീതം",
      "Art": "കല",
      "Finance": "ഫിനാൻസ്",
    },
    15: {
      // English
      "All": "All",
      "Coding": "Coding",
      "Education": "Education",
      "Design": "Design",
      "Business": "Business",
      "Cooking": "Cooking",
      "Music": "Music",
      "Art": "Art",
      "Finance": "Finance",
    },
  };

  // Feature translations for all languages.
  final Map<int, Map<String, String>> featureTranslations = {
    0: {
      // Kashmiri
      "UI/UX Design": "یو آئی/یو ایکس ڈیزائن",
      "Programming": "پروگرامنگ",
      "English Writing": "انگریزی تحریر",
      "Photography": "فوٹوگرافی",
      "Guitar Class": "گیٹار کلاس",
    },
    1: {
      // Punjabi
      "UI/UX Design": "ਯੂਆਈ/ਯੂਐਕਸ ਡਿਜ਼ਾਈਨ",
      "Programming": "ਪ੍ਰੋਗ੍ਰਾਮਿੰਗ",
      "English Writing": "ਅੰਗਰੇਜ਼ੀ ਲਿਖਾਈ",
      "Photography": "ਫੋਟੋਗ੍ਰਾਫੀ",
      "Guitar Class": "ਗੀਟਾਰ ਕਲਾਸ",
    },
    2: {
      // Haryanvi
      "UI/UX Design": "यूआई/यूएक्स डिज़ाइन",
      "Programming": "प्रोग्रामिंग",
      "English Writing": "अंग्रेज़ी लेखन",
      "Photography": "फोटोग्राफी",
      "Guitar Class": "गिटार कक्षा",
    },
    3: {
      // Hindi
      "UI/UX Design": "यूआई/यूएक्स डिज़ाइन",
      "Programming": "प्रोग्रामिंग",
      "English Writing": "अंग्रेज़ी लेखन",
      "Photography": "फोटोग्राफी",
      "Guitar Class": "गिटार कक्षा",
    },
    4: {
      // Rajasthani
      "UI/UX Design": "यूआई/यूएक्स डिज़ाइन",
      "Programming": "प्रोग्रामिंग",
      "English Writing": "अंग्रेज़ी लेखन",
      "Photography": "फोटोग्राफी",
      "Guitar Class": "गिटार कक्षा",
    },
    5: {
      // Bhojpuri
      "UI/UX Design": "यूआई/यूएक्स डिज़ाइन",
      "Programming": "प्रोग्रामिंग",
      "English Writing": "अंग्रेज़ी लेखन",
      "Photography": "फोटोग्राफी",
      "Guitar Class": "गिटार कक्षा",
    },
    6: {
      // Bengali
      "UI/UX Design": "ইউআই/ইউএক্স ডিজাইন",
      "Programming": "প্রোগ্রামিং",
      "English Writing": "ইংরেজি লেখা",
      "Photography": "ফটোগ্রাফি",
      "Guitar Class": "গিটার ক্লাস",
    },
    7: {
      // Gujarati
      "UI/UX Design": "યુઆઈ/યુએક્સ ડિઝાઇન",
      "Programming": "પ્રોગ્રામિંગ",
      "English Writing": "અંગ્રેજી લેખન",
      "Photography": "ફોટોગ્રાફી",
      "Guitar Class": "ગિટાર ક્લાસ",
    },
    8: {
      // Assamese
      "UI/UX Design": "ইউআই/ইউএক্স ডিজাইন",
      "Programming": "প্ৰগ্ৰামিং",
      "English Writing": "ইংৰাজী লিখন",
      "Photography": "ফটোগ্ৰাফী",
      "Guitar Class": "গিটাৰ ক্লাছ",
    },
    9: {
      // Odia
      "UI/UX Design": "ୟୁଆଇ/ୟୁଏକ୍ସ ଡିଜାଇନ୍",
      "Programming": "ପ୍ରୋଗ୍ରାମିଂ",
      "English Writing": "ଇଂରାଜୀ ଲେଖନ",
      "Photography": "ଫଟୋଗ୍ରାଫି",
      "Guitar Class": "ଗିଟାର କ୍ଲାସ୍",
    },
    10: {
      // Marathi
      "UI/UX Design": "यूआई/यूएक्स डिझाईन",
      "Programming": "प्रोग्रामिंग",
      "English Writing": "इंग्रजी लेखन",
      "Photography": "फोटोग्राफी",
      "Guitar Class": "गिटार वर्ग",
    },
    11: {
      // Tamil
      "UI/UX Design": "யூஐ/யூஎக்ஸ் வடிவமைப்பு",
      "Programming": "ப்ரோக்ராமிங்",
      "English Writing": "ஆங்கில எழுத்து",
      "Photography": "புகைப்படக்கலை",
      "Guitar Class": "கித்தார் வகுப்பு",
    },
    12: {
      // Telugu
      "UI/UX Design": "యూ ఐ/యూ ఎక్స్ డిజైన్",
      "Programming": "ప్రోగ్రామింగ్",
      "English Writing": "ఆంగ్ల రచన",
      "Photography": "ఫోటోగ్రఫీ",
      "Guitar Class": "గిటార్ క్లాస్",
    },
    13: {
      // Kannada
      "UI/UX Design": "ಯುಐ/ಯುಎಕ್ಸ್ ವಿನ್ಯಾಸ",
      "Programming": "ಪ್ರೋಗ್ರಾಮಿಂಗ್",
      "English Writing": "ಇಂಗ್ಲೀಷ್ ಬರಹ",
      "Photography": "ಫೋಟೋಗ್ರಫಿ",
      "Guitar Class": "ಗಿಟಾರ್ ತರಗತಿ",
    },
    14: {
      // Malayalam
      "UI/UX Design": "യൂഐ/യൂഎക്സ് ഡിസൈൻ",
      "Programming": "പ്രോഗ്രാമിംഗ്",
      "English Writing": "ഇംഗ്ലീഷ് എഴുത്ത്",
      "Photography": "ഫോട്ടോഗ്രഫി",
      "Guitar Class": "ഗിറ്റാർ ക്ലാസ്",
    },
    15: {
      // English
      "UI/UX Design": "UI/UX Design",
      "Programming": "Programming",
      "English Writing": "English Writing",
      "Photography": "Photography",
      "Guitar Class": "Guitar Class",
    },
  };

  // Recommend translations for all languages.
  final Map<int, Map<String, String>> recommendTranslations = {
    0: {
      // Kashmiri
      "Painting": "پینٹنگ",
      "Social Media": "سوشل میڈیا",
      "Caster": "کیسٹر",
      "Management": "انتظام",
    },
    1: {
      // Punjabi
      "Painting": "ਪੇਂਟਿੰਗ",
      "Social Media": "ਸੋਸ਼ਲ ਮੀਡੀਆ",
      "Caster": "ਕੇਸਟਰ",
      "Management": "ਪ੍ਰਬੰਧਨ",
    },
    2: {
      // Haryanvi
      "Painting": "पेंटिंग",
      "Social Media": "सोशल मीडिया",
      "Caster": "कैस्टर",
      "Management": "प्रबंधन",
    },
    3: {
      // Hindi
      "Painting": "पेंटिंग",
      "Social Media": "सोशल मीडिया",
      "Caster": "कैस्टर",
      "Management": "प्रबंधन",
    },
    4: {
      // Rajasthani
      "Painting": "पेंटिंग",
      "Social Media": "सोशल मीडिया",
      "Caster": "कैस्टर",
      "Management": "प्रबंधन",
    },
    5: {
      // Bhojpuri
      "Painting": "पेंटिंग",
      "Social Media": "सोशल मीडिया",
      "Caster": "कैस्टर",
      "Management": "प्रबंधन",
    },
    6: {
      // Bengali
      "Painting": "চিত্রাঙ্কন",
      "Social Media": "সোশ্যাল মিডিয়া",
      "Caster": "কাস্টার",
      "Management": "পরিচালনা",
    },
    7: {
      // Gujarati
      "Painting": "પેન્ટિંગ",
      "Social Media": "સોશિયલ મીડિયા",
      "Caster": "કાસ્ટર",
      "Management": "વ્યવસ્થાપન",
    },
    8: {
      // Assamese
      "Painting": "পেইন্টিং",
      "Social Media": "চ’চিয়েল মিডিয়া",
      "Caster": "কাষ্টাৰ",
      "Management": "ব্যৱস্থাপনা",
    },
    9: {
      // Odia
      "Painting": "ପେଣ୍ଟିଂ",
      "Social Media": "ସୋସିଆଲ୍ ମିଡିଆ",
      "Caster": "କ୍ୟାଷ୍ଟର",
      "Management": "ପରିଚାଳନା",
    },
    10: {
      // Marathi
      "Painting": "चित्रकला",
      "Social Media": "सोशल मीडिया",
      "Caster": "कॅस्टर",
      "Management": "व्यवस्थापन",
    },
    11: {
      // Tamil
      "Painting": "வண்ணம்",
      "Social Media": "சமூகவலை",
      "Caster": "கேஸ்டர்",
      "Management": "மேலாண்மை",
    },
    12: {
      // Telugu
      "Painting": "పెయింటింగ్",
      "Social Media": "సోష‌ల్ మీడియా",
      "Caster": "కాస్టర్",
      "Management": "నిర్వహణ",
    },
    13: {
      // Kannada
      "Painting": "ಚಿತ್ತಾರ",
      "Social Media": "ಸೋಶಿಯಲ್ ಮೀಡಿಯಾ",
      "Caster": "ಕ್ಯಾಸ್ಟರ್",
      "Management": "ನಿರ್ವಹಣೆ",
    },
    14: {
      // Malayalam
      "Painting": "ചിത്രരചന",
      "Social Media": "സോഷ്യൽ മീഡിയ",
      "Caster": "കാസ്റ്റർ",
      "Management": "മാനേജ്മെന്റ്",
    },
    15: {
      // English
      "Painting": "Painting",
      "Social Media": "Social Media",
      "Caster": "Caster",
      "Management": "Management",
    },
  };

  // Unit translations for all languages.
  final Map<int, Map<String, String>> unitTranslations = {
    0: {
      // Kashmiri
      "hours": "گھنٹے",
      "lessons": "سبق",
    },
    1: {
      // Punjabi
      "hours": "ਘੰਟੇ",
      "lessons": "ਪਾਠ",
    },
    2: {
      // Haryanvi
      "hours": "घंटे",
      "lessons": "पाठ",
    },
    3: {
      // Hindi
      "hours": "घंटे",
      "lessons": "पाठ",
    },
    4: {
      // Rajasthani
      "hours": "घंटे",
      "lessons": "पाठ",
    },
    5: {
      // Bhojpuri
      "hours": "घंटे",
      "lessons": "पाठ",
    },
    6: {
      // Bengali
      "hours": "ঘণ্টা",
      "lessons": "পাঠ",
    },
    7: {
      // Gujarati
      "hours": "કલાક",
      "lessons": "પાઠ",
    },
    8: {
      // Assamese
      "hours": "ঘণ্টা",
      "lessons": "পাঠ",
    },
    9: {
      // Odia
      "hours": "ଘଣ୍ଟା",
      "lessons": "ପାଠ",
    },
    10: {
      // Marathi
      "hours": "तास",
      "lessons": "पाठ",
    },
    11: {
      // Tamil
      "hours": "மணிநேரம்",
      "lessons": "பாடம்",
    },
    12: {
      // Telugu
      "hours": "గంటలు",
      "lessons": "పాఠాలు",
    },
    13: {
      // Kannada
      "hours": "ಗಂಟೆಗಳು",
      "lessons": "ಪಾಠಗಳು",
    },
    14: {
      // Malayalam
      "hours": "മണിക്കൂറുകൾ",
      "lessons": "പാഠങ്ങൾ",
    },
    15: {
      // English
      "hours": "hours",
      "lessons": "lessons",
    },
  };

  // Description translations for all languages.
  final Map<int, String> descriptionTranslations = {
    0: "اشاعت اور گرافک ڈیزائن میں، Lorem ipsum ایک placeholder متن ہے جو کسی دستاویز یا ٹائپ فیس کی بصری شکل کو ظاہر کرنے کے لیے استعمال ہوتا ہے بغیر کسی بامعنی مواد کے۔ Lorem ipsum کو حتمی کاپی دستیاب ہونے سے پہلے placeholder کے طور پر استعمال کیا جا سکتا ہے۔",
    1: "ਪਬਲਿਸ਼ਿੰਗ ਅਤੇ ਗ੍ਰਾਫਿਕ ਡਿਜ਼ਾਈਨ ਵਿੱਚ, Lorem ipsum ਇੱਕ placeholder ਟੈਕਸਟ ਹੈ ਜੋ ਦਸਤਾਵੇਜ਼ ਜਾਂ ਟਾਇਪਫੇਸ ਦੀ ਵਿਜ਼ੂਅਲ ਫਾਰਮ ਨੂੰ ਦਰਸਾਉਂਦਾ ਹੈ ਬਿਨਾਂ ਮਾਣਹੀਂ ਸਮੱਗਰੀ 'ਤੇ ਨਿਰਭਰ ਹੋਏ। Lorem ipsum ਨੂੰ ਅੰਤਿਮ ਨਕਲ ਤੋਂ ਪਹਿਲਾਂ placeholder ਵਜੋਂ ਵਰਤਿਆ ਜਾ ਸਕਦਾ ਹੈ।",
    2: "प्रकाशन और ग्राफिक डिज़ाइन में, Lorem ipsum एक प्लेसहोल्डर टेक्स्ट है जिसका उपयोग दस्तावेज़ या टाइपफेस के दृश्य रूप को प्रदर्शित करने के लिए किया जाता है बिना सार्थक सामग्री पर निर्भर हुए। Lorem ipsum का उपयोग अंतिम प्रति उपलब्ध होने से पहले प्लेसहोल्डर के रूप में किया जा सकता है।",
    3: "प्रकाशन और ग्राफिक डिज़ाइन में, Lorem ipsum एक प्लेसहोल्डर टेक्स्ट है जिसका उपयोग दस्तावेज़ या टाइपफेस के दृश्य रूप को प्रदर्शित करने के लिए किया जाता है बिना सार्थक सामग्री पर निर्भर हुए। Lorem ipsum का उपयोग अंतिम प्रति उपलब्ध होने से पहले प्लेसहोल्डर के रूप में किया जा सकता है।",
    4: "प्रकाशन और ग्राफिक डिज़ाइन में, Lorem ipsum एक प्लेसहोल्डर टेक्स्ट है जिसका उपयोग दस्तावेज़ या टाइपफेस के दृश्य रूप को प्रदर्शित करने के लिए किया जाता है बिना सार्थक सामग्री पर निर्भर हुए। Lorem ipsum का उपयोग अंतिम प्रति उपलब्ध होने से पहले प्लेसहोल्डर के रूप में किया जा सकता है।",
    5: "प्रकाशन और ग्राफिक डिज़ाइन में, Lorem ipsum एक प्लेसहोल्डर टेक्स्ट है जिसका उपयोग दस्तावेज़ या टाइपफेस के दृश्य रूप को प्रदर्शित करने के लिए किया जाता है बिना सार्थक सामग्री पर निर्भर हुए। Lorem ipsum का उपयोग अंतिम प्रति उपलब्ध होने से पहले प्लेसहोल्डर के रूप में किया जा सकता है।",
    6: "প্রকাশনা এবং গ্রাফিক ডিজাইন-এ, Lorem ipsum একটি placeholder টেক্সট যা একটি ডকুমেন্ট বা টাইপফেসের ভিজ্যুয়াল ফর্ম প্রদর্শনের জন্য ব্যবহৃত হয়, অর্থপূর্ণ বিষয়বস্তু ছাড়া। Lorem ipsum চূড়ান্ত কপি উপলব্ধ হওয়ার আগে placeholder হিসেবে ব্যবহার করা যায়।",
    7: "પ્રકાશન અને ગ્રાફિક ડિઝાઇનમાં, Lorem ipsum એક placeholder ટેક્સ્ટ છે જે દસ્તાવેજ અથવા ટાઇપફેસના દૃશ્યરૂપને દર્શાવે છે, અર્થપૂર્ણ સામગ્રી પર આધાર રાખ્યા વગર. Lorem ipsum અંતિમ નકલ ઉપલબ્ધ થવા પહેલા placeholder તરીકે ઉપયોગ કરી શકાય છે.",
    8: "প্ৰকাশ আৰু গ্ৰাফিক ডিজাইনত, Lorem ipsum এটা placeholder পাঠ, যি কোনো নথি বা টাইপফেচৰ ভিজ্যুৱেল ৰূপ দেখুৱাবলৈ ব্যৱহৃত হয়, অৰ্থপূর্ণ সামগ্ৰী নোহোৱাকৈ। Lorem ipsum চূড়ান্ত প্ৰতিলিপি উপলব্ধ হোৱাৰ পূৰ্বে placeholder হিচাপে ব্যৱহাৰ কৰিব পৰা যায়।",
    9: "ପ୍ରକାଶନ ଏବଂ ଗ୍ରାଫିକ୍ ଡିଜାଇନରେ, Lorem ipsum ଏକ placeholder ପାଠ୍ୟ, ଯାହା ଏକ ଦଲିଲ ବା ଟାଇପଫେସର ଭିଜୁଆଲ୍ ଫର୍ମକୁ ଦେଖାଏ, ଅର୍ଥପୂର୍ଣ୍ଣ ବିଷୟବସ୍ତୁ ବିନା। Lorem ipsum ଅନ୍ତିମ କପି ଉପଲବ୍ଧ ହେବା ପୂର୍ବରୁ placeholder ଭାବେ ବ୍ୟବହୃତ ହୋଇପାରେ।",
    10: "प्रकाशन आणि ग्राफिक डिझाइनमध्ये, Lorem ipsum हा एक placeholder मजकूर आहे जो दस्तऐवज किंवा टायपफेसच्या दृश्यात्मक रूपाचे प्रदर्शन करण्यासाठी वापरला जातो, कोणत्याही अर्थपूर्ण मजकुरावर अवलंबून न राहता. Lorem ipsum अंतिम प्रती उपलब्ध होण्यापूर्वी placeholder म्हणून वापरला जाऊ शकतो.",
    11: "பதிப்பகம் மற்றும் கிராஃபிக் வடிவமைப்பில், Lorem ipsum என்பது ஒரு placeholder உரை, இது ஆவணத்தின் அல்லது டைப்ஃபேஸின் காட்சி வடிவத்தை, பொருத்தமான உள்ளடக்கமின்றி, வெளிப்படுத்த பயன்படுத்தப்படுகிறது. இறுதி பிரதிக்கு முன் Lorem ipsum placeholder ஆக பயன்படுத்தப்படுகிறது.",
    12: "ప్రచురణ మరియు గ్రాఫిక్ డిజైన్‌లో, Lorem ipsum అనేది ఒక placeholder పాఠ్యం, ఇది దస్తావేజి లేదా టైప్ఫేస్ యొక్క దృశ్య రూపాన్ని, అర్థవంతమైన విషయానికి ఆధారపడకుండా, ప్రదర్శించడానికి ఉపయోగించబడుతుంది. Lorem ipsum చివరి ప్రతిని అందుబాటులోకి రాకముందు placeholder గా ఉపయోగించవచ్చు.",
    13: "ಪ್ರಕಾಶನ ಮತ್ತು ಗ್ರಾಫಿಕ್ ವಿನ್ಯಾಸದಲ್ಲಿ, Lorem ipsum ಒಂದು placeholder ಪಠ್ಯವಾಗಿದ್ದು, ಇದು ದಾಖಲೆ ಅಥವಾ ಟೈಪ್ಫೇಸ್‌ನ ದೃಶ್ಯ ರೂಪವನ್ನು, ಅರ್ಥಪೂರ್ಣ ವಿಷಯವಿಲ್ಲದೆ, ಪ್ರದರ್ಶಿಸುತ್ತದೆ. Lorem ipsum ಅಂತಿಮ ಪ್ರತಿಯನ್ನು ಲಭ್ಯವಾಗುವ ಮೊದಲು placeholder ಆಗಿ ಬಳಸಬಹುದು.",
    14: "പ്രസിദ്ധീകരണത്തിലും ഗ്രാഫിക് ഡിസൈനിലും, Lorem ipsum ഒരു placeholder വാചകമാണിത്, ഏതെങ്കിലും അർത്ഥമുള്ള ഉള്ളടക്കത്തെ ആശ്രയിക്കാതെ ഒരു ഡോക്യുമെന്റിന്റെയും ടൈപ്പ്ഫേസിന്റെയും ദൃശ്യമൂരം പ്രകടിപ്പിക്കാൻ ഉപയോഗിക്കുന്നു. Lorem ipsum അവസാന പ്രതി ലഭിക്കുന്നതിന് മുമ്പ് placeholder ആയി ഉപയോഗിക്കാം.",
    15: "In publishing and graphic design, Lorem ipsum is a placeholder text commonly used to demonstrate the visual form of a document or a typeface without relying on meaningful content. Lorem ipsum may be used as a placeholder before the final copy is available.",
  };

  Map<String, String> get currentHeadings {
    return localizedHeadings[widget.langIndex] ?? localizedHeadings[15]!;
  }

  Map<String, String> get currentCategoryTranslations {
    return categoryTranslations[widget.langIndex] ?? categoryTranslations[15]!;
  }

  Map<String, String> get currentFeatureTranslations {
    return featureTranslations[widget.langIndex] ?? featureTranslations[15]!;
  }

  Map<String, String> get currentRecommendTranslations {
    return recommendTranslations[widget.langIndex] ??
        recommendTranslations[15]!;
  }

  Map<String, String> get currentUnitTranslations {
    return unitTranslations[widget.langIndex] ?? unitTranslations[15]!;
  }

  String get currentDescriptionTranslation {
    return descriptionTranslations[widget.langIndex] ??
        descriptionTranslations[15]!;
  }

  @override
  void initState() {
    super.initState();
    futureResult = fetchHomeData();
  }

  Future<ResultData1> fetchHomeData() async {
    await Future.delayed(const Duration(seconds: 1));
    final String dummyJson = '''
    {
      "Language Prefernce": "English",
      "dummyKey": ["dummyValue1", "dummyValue2"]
    }
    ''';
    return ResultData1.fromJson(dummyJson);
  }

  // Convert categories data using translations.
  List getLocalizedCategories() {
    return categories.map((item) {
      final translatedName =
          currentCategoryTranslations[item['name']] ?? item['name'];
      return {
        "name": translatedName,
        "icon": item['icon'],
      };
    }).toList();
  }

  // Helper function to translate duration/session strings.
  String translateUnit(String text) {
    final parts = text.split(" ");
    if (parts.length == 2) {
      final number = parts[0];
      final unit = parts[1];
      final translatedUnit = currentUnitTranslations[unit] ?? unit;
      return "$number $translatedUnit";
    }
    return text;
  }
  void openVideo(BuildContext context, int index) {
    final List<String> urls = [
      "https://vimeo.com/1070732701/558b21900f",
      "https://vimeo.com/1070650026/ee8ceda97d",
      "https://vimeo.com/1070731552/e1f08a9102",
      "https://vimeo.com/1070732193/5401e265ec",
      "https://vimeo.com/1070732479/5b389160ef",
      "https://vimeo.com/1070732193/5401e265ec",
      "https://vimeo.com/1070733130/aa190bee5a",
      "https://vimeo.com/1070733568/3ef905f411",
      "https://vimeo.com/1070733877/e159f1d5af",
      "https://vimeo.com/1070734145/9c25564d81",
      "https://vimeo.com/1070734390/58520c7b1d",
      "https://vimeo.com/1070734810/2528c2adee",
      "https://vimeo.com/1070735257/3daf9fea49",
      "https://vimeo.com/1070735634/ad8d6935d9",
      "https://vimeo.com/1070735980/98400943c6",
      "https://vimeo.com/1070736587/c5fa59aa6e"
    ];

    if (index >= 0 && index < urls.length) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InAppWebViewScreen(
            url: urls[index],
            title: "Video",
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid video index.")),
      );
    }
  }

  // Convert features data using translations.
  List getLocalizedFeatures() {
    return features.map((item) {
      final translatedName =
          currentFeatureTranslations[item['name']] ?? item['name'];
      return {
        ...item,
        "name": translatedName,
        "duration": translateUnit(item["duration"]),
        "session": translateUnit(item["session"]),
        "description": currentDescriptionTranslation,
      };
    }).toList();
  }

  // Convert recommends data using translations.
  List getLocalizedRecommends() {
    return recommends.map((item) {
      final translatedName =
          currentRecommendTranslations[item['name']] ?? item['name'];
      return {
        ...item,
        "name": translatedName,
        "duration": translateUnit(item["duration"]),
        "session": translateUnit(item["session"]),
        "description": currentDescriptionTranslation,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: FutureBuilder<ResultData1>(
        future: futureResult,
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: 18.5)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildBody(),
                  childCount: 1,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    final localizedCategories = getLocalizedCategories();
    final localizedFeatures = getLocalizedFeatures();
    final localizedRecommends = getLocalizedRecommends();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories Section
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(15, 10, 0, 10),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...List.generate(
                  localizedCategories.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: CategoryBox(
                      selectedColor: Colors.white,
                      data: localizedCategories[index],
                      //langIndex: widget.langIndex,
                      onTap: null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 23.5),
          // Featured Section
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
            child: Text(
              currentHeadings['featured']!,
              style: TextStyle(
                color: AppColor.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 24,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 15),
            child: Row(
              children: List.generate(
                localizedFeatures.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: FeatureItem(
                    data: localizedFeatures[index],
                    videoIndex: widget.langIndex,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 23.5),
          // Recommended Section
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentHeadings['recommended']!,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textColor,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(15, 5, 0, 5),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                localizedRecommends.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: RecommendItem(
                    data: localizedRecommends[index],
                    index: widget.langIndex,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResultData1 {
  final Map<String, List<String>> result;
  final String? language;

  ResultData1({required this.result, this.language});

  factory ResultData1.fromJson(String jsonString) {
    jsonString = jsonString.trim();
    if (jsonString.startsWith("```")) {
      final startIndex = jsonString.indexOf('{');
      final endIndex = jsonString.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        jsonString = jsonString.substring(startIndex, endIndex + 1);
      }
    }
    final Map<String, dynamic> rawMap = jsonDecode(jsonString);
    String? lang;
    if (rawMap.containsKey("Language Prefernce")) {
      lang = rawMap["Language Prefernce"].toString();
      rawMap.remove("Language Prefernce");
    }
    final resultMap = <String, List<String>>{};
    rawMap.forEach((key, value) {
      if (value is List) {
        final items = value.map((item) => item.toString()).toList();
        resultMap[key] = items;
      }
    });
    return ResultData1(result: resultMap, language: lang);
  }
}
