import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'start_screen.dart';
import 'question_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'web.dart';
int getLanguageIndex(String lang) {
  switch (lang) {
    case "کشميري":
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

class AccountPage extends StatefulWidget {
  final int languageIndex;
  const AccountPage({Key? key, required this.languageIndex}) : super(key: key);
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // Define the icon color as a constant variable.
  final Color iconColor = const Color(0xFF5BC0EB);
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  int coinBalance = 0;
  final Map<int, Map<String, String>> translations = {
    0: {
      "profile": "پروفائل",
      "user": "صارف",
      "courses": "کورس",
      "hours": "گھنٹے",
      "rating": "5.0",
      "changePreferences": "ترجیحات بدلو",
      "rewards": "انعامات",
      "notification": "اطلاع",
      "privacy policy": "رازداری کی پالیسی",
      "logout": "لاگ آؤٹ",
    },
    1: {
      "profile": "ਪ੍ਰੋਫ਼ਾਈਲ",
      "user": "ਉਪਭੋਗਤਾ",
      "courses": "ਕੋਰਸ",
      "hours": "ਘੰਟੇ",
      "rating": "5.0",
      "changePreferences": "ਤਰਜੀਹਾਂ ਬਦਲੋ",
      "rewards": "ਇਨਾਮ",
      "notification": "ਸੂਚਨਾਵਾਂ",
      "privacy policy": "ਰਹੱਸਯਤਾ ਦੀ ਨੀਤੀ",
      "logout": "ਲੋਗ ਆਉਟ",
    },
    2: {
      "profile": "प्रोफ़ाइल",
      "user": "यूजर",
      "courses": "कोर्स",
      "hours": "घंटे",
      "rating": "5.0",
      "changePreferences": "बदलियो प्राथमिकताएं",
      "rewards": "इनाम",
      "notification": "सूचनाएं",
      "privacy policy": "गोपनीयता नीति",
      "logout": "लॉग आउट",
    },
    3: {
      "profile": "प्रोफ़ाइल",
      "user": "उपयोगकर्ता",
      "courses": "कोर्स",
      "hours": "घंटे",
      "rating": "5.0",
      "changePreferences": "प्राथमिकताएँ बदलें",
      "rewards": "इनाम",
      "notification": "सूचनाएं",
      "privacy policy": "गोपनीयता नीति",
      "logout": "लॉग आउट",
    },
    4: {
      "profile": "प्रोफ़ाइल",
      "user": "उपयोगकर्ता",
      "courses": "कोर्स",
      "hours": "घंटा",
      "rating": "5.0",
      "changePreferences": "पसंद बदलो",
      "rewards": "इनाम",
      "notification": "सूचनाएं",
      "privacy policy": "गोपनीयता नीति",
      "logout": "लॉग आउट",
    },
    5: {
      "profile": "प्रोफ़ाइल",
      "user": "यूजर",
      "courses": "कोर्स",
      "hours": "घंटा",
      "rating": "5.0",
      "changePreferences": "पसंद बदलीं",
      "rewards": "इनाम",
      "notification": "सूचना",
      "privacy policy": "गोपनीयता नीति",
      "logout": "लॉग आउट",
    },
    6: {
      "profile": "প্রোফাইল",
      "user": "ব্যবহারকারী",
      "courses": "কোর্স",
      "hours": "ঘণ্টা",
      "rating": "5.0",
      "changePreferences": "পছন্দ পরিবর্তন করুন",
      "rewards": "পুরস্কার",
      "notification": "বিজ্ঞপ্তি",
      "privacy policy": "গোপনীয়তা নীতি",
      "logout": "লগ আউট",
    },
    7: {
      "profile": "પ્રોફાઈલ",
      "user": "વપરાશકર્તા",
      "courses": "કોર્સ",
      "hours": "કલાકો",
      "rating": "5.0",
      "changePreferences": "પ્રાધાન્ય બદલો",
      "rewards": "ઇનામ",
      "notification": "સૂચના",
      "privacy policy": "ગોપનીયતા નીતિ",
      "logout": "લોગ આઉટ",
    },
    8: {
      "profile": "প্ৰফাইল",
      "user": "ব্যৱহাৰকাৰী",
      "courses": "কোৰ্ছ",
      "hours": "ঘণ্টা",
      "rating": "5.0",
      "changePreferences": "পছন্দ সলনি কৰক",
      "rewards": "পুৰস্কাৰ",
      "notification": "সুচনা",
      "privacy policy": "গোপনীয়তা নীতি",
      "logout": "লগ আউট",
    },
    9: {
      "profile": "ପ୍ରୋଫାଇଲ",
      "user": "ଉପଯୋଗକର୍ତ୍ତା",
      "courses": "କୋର୍ସ",
      "hours": "ଘଣ୍ଟା",
      "rating": "5.0",
      "changePreferences": "ପସନ୍ଦ ବଦଳାନ୍ତୁ",
      "rewards": "ପୁରସ୍କାର",
      "notification": "ସୂଚନା",
      "privacy policy": "ଗୋପନୀୟତା ନୀତି",
      "logout": "ଲଗ ଆଉଟ",
    },
    10: {
      "profile": "प्रोफाइल",
      "user": "वापरकर्ता",
      "courses": "कोर्सेस",
      "hours": "तास",
      "rating": "5.0",
      "changePreferences": "प्राधान्य बदला",
      "rewards": "बक्षीस",
      "notification": "सूचना",
      "privacy policy": "गोपनीयता धोरण",
      "logout": "लॉग आउट",
    },
    11: {
      "profile": "சுயவிவரம்",
      "user": "பயனர்",
      "courses": "பாடநெறிகள்",
      "hours": "மணித்தியாலங்கள்",
      "rating": "5.0",
      "changePreferences": "விருப்பங்களை மாற்று",
      "rewards": "பரிசுகள்",
      "notification": "அறிவிப்பு",
      "privacy policy": "தனியுரிமைக் கொள்கை",
      "logout": "வெளியேறு",
    },
    12: {
      "profile": "ప్రొఫైల్",
      "user": "వినియోగదారు",
      "courses": "కోర్సులు",
      "hours": "గంటలు",
      "rating": "5.0",
      "changePreferences": "అభిరుచులు మార్చు",
      "rewards": "బహుమతులు",
      "notification": "నోటిఫికేషన్",
      "privacy policy": "గోప్యతా విధానం",
      "logout": "లాగ్ అవుట్",
    },
    13: {
      "profile": "ಪ್ರೊಫೈಲ್",
      "user": "ಬಳಕೆದಾರ",
      "courses": "ಕೋರ್ಸುಗಳು",
      "hours": "ಗಂಟೆಗಳು",
      "rating": "5.0",
      "changePreferences": "ಆಸಕ್ತಿಗಳನ್ನು ಬದಲಾಯಿಸಿ",
      "rewards": "ಪ್ರಶಂಸೆ",
      "notification": "ಅಧಿಸೂಚನೆ",
      "privacy policy": "ಗೋಪ್ಯತಾ ನೀತಿ",
      "logout": "ಲಾಗ್ ಔಟ್",
    },
    14: {
      "profile": "പ്രൊഫൈല്‍",
      "user": "ഉപയോക്താവ്",
      "courses": "കോഴ്സുകൾ",
      "hours": "മണിക്കൂറുകൾ",
      "rating": "5.0",
      "changePreferences": "പ്രധാന്യം മാറ്റുക",
      "rewards": "പ്രതിഫലം",
      "notification": "അറിയിപ്പ്",
      "privacy policy": "സ്വകാര്യത നയം",
      "logout": "ലോഗ്ഔട്ട്",
    },
    15: {
      "profile": "Profile",
      "user": "User",
      "courses": "courses",
      "hours": "hours",
      "rating": "5.0",
      "changePreferences": "Change Preferences",
      "rewards": "Rewards",
      "notification": "Notification",
      "privacy policy": "Privacy Policy",
      "logout": "Log Out",
    },
  };
  String t(String key) {
    return translations[widget.languageIndex]?[key] ??
        translations[15]![key] ??
        key;
  }
  void initState() {
    super.initState();
    _loadUserData();
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
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(t("profile"),                  style: const TextStyle(
          fontSize: 20.0,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Column(
          children: [
            _buildProfile(),
            const SizedBox(height: 20),
            _buildRecord(),
            const SizedBox(height: 20),
            _buildSection1(),
            const SizedBox(height: 20),
            _buildSection2(),
            const SizedBox(height: 20),
            _buildSection3(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      children: [
        CustomImage(
          user?.photoURL ?? "assets/images/default_profile.png",
          width: 70,
          height: 70,
          radius: 20,
        ),
        const SizedBox(height: 10),
        Text(
          user?.displayName ?? t("user"),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFFD1D1D1),
          ),
        ),
      ],
    );
  }

  Widget _buildRecord() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SettingBox(
            title: "0 ${t("courses")}",
            icon: "assets/icons/work.svg",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SettingBox(
            title: "0 ${t("hours")}",
            icon: "assets/icons/time.svg",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SettingBox(
            title: t("rating"),
            icon: "assets/icons/star.svg",
          ),
        ),
      ],
    );
  }

  // Section 1: Contains "Change Preferences" and "Rewards".
  Widget _buildSection1() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          SettingItem(
            title: t("changePreferences"),
            leadingIcon: "assets/icons/setting.svg",
            bgIconColor: iconColor,
            onTap: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final currentUserId = user.uid;
                final dbRef = FirebaseDatabase.instance
                    .ref()
                    .child('surveyResponses')
                    .child(currentUserId);
                await dbRef.remove();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const QuestionScreen(),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          // Rewards item with extra trailing icon.
          SettingItem(
            title: t("rewards"),
            leadingIcon: "assets/icons/wallet.svg",
            bgIconColor: iconColor,
            trailingWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  coinBalance.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Image.asset(
                  'assets/images/coins.png',
                  width: 20,
                  height: 20,
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      RewardsScreen(languageIndex: widget.languageIndex),
                ),
              );
            },
          )
          ,




        ],
      ),
    );
  }

  // Section 2: Contains "Notification" and "Privacy".
  Widget _buildSection2() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          SettingItem(
            title: t("notification"),
            leadingIcon: "assets/icons/bell.svg",
            bgIconColor: iconColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      NotificationScreen(languageIndex: widget.languageIndex),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          SettingItem(
            title: t("privacy policy"),
            leadingIcon: "assets/icons/shield.svg",
            bgIconColor: iconColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => InAppWebViewScreen(
                    url: "https://www.termsfeed.com/live/27cdd66b-ca31-4f83-81df-1d2a173b3315",
                    title: t("privacy policy"),
                  ),
                ),
              );
            },

          ),
        ],
      ),
    );
  }

  // Section 3: Log Out.
  Widget _buildSection3() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(5),
      ),
      child: SettingItem(
        title: t("logout"),
        leadingIcon: "assets/icons/logout.svg",
        bgIconColor: iconColor,
        onTap: () async {
          await FirebaseAuth.instance.signOut();
          await _googleSignIn.signOut();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const StartScreen(),
              ),
            );
          }
        },
      ),
    );
  }
}

// A simple CustomImage widget implementation.
class CustomImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final double radius;

  const CustomImage(
      this.imageUrl, {
        Key? key,
        required this.width,
        required this.height,
        this.radius = 0,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey,
            child: const Icon(Icons.person, size: 40),
          );
        },
      ),
    );
  }
}

class SettingBox extends StatelessWidget {
  const SettingBox({
    Key? key,
    required this.title,
    required this.icon,
    this.color = const Color(0xFFFFFFFF),
  }) : super(key: key);

  final String title;
  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A2A2A).withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            icon,
            color: color,
            width: 22,
            height: 22,
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }
}

class SettingItem extends StatelessWidget {
  final String? leadingIcon;
  final Color leadingIconColor;
  final Color bgIconColor;
  final String title;
  final GestureTapCallback? onTap;
  final Widget? trailingWidget;

  const SettingItem({
    Key? key,
    required this.title,
    this.onTap,
    this.leadingIcon,
    this.leadingIconColor = const Color(0xFFFFFFFF),
    this.bgIconColor = const Color(0xFF5BC0EB),
    this.trailingWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: leadingIcon != null ? _buildItemWithPrefixIcon() : _buildItem(),
      ),
    );
  }

  Widget _buildPrefixIcon() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bgIconColor,
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset(
        leadingIcon!,
        color: leadingIconColor,
        width: 22,
        height: 22,
      ),
    );
  }

  Widget _buildItemWithPrefixIcon() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPrefixIcon(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFFFFFFF),
            ),
          ),
        ),
        trailingWidget ??
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFB0B0B0),
              size: 17,
            )
      ],
    );
  }

  Widget _buildItem() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFFFFFFF),
            ),
          ),
        ),
        trailingWidget ??
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFB0B0B0),
              size: 17,
            )
      ],
    );
  }
}



class RewardsScreen extends StatelessWidget {
  final int languageIndex;
  RewardsScreen({Key? key, required this.languageIndex}) : super(key: key);

  final Map<int, Map<String, String>> translations = {
    0: {
      "rewards": "انعامات",
      "rewardsContent": "یہ وہ جگہ ہے جہاں آپ اپنے انعامات کا سراغ لگا سکتے ہیں۔ ہمارے انعامی سکے بلاکچین کے ذریعے محفوظ ہیں اور جلد ہی دوسرے پلیٹ فارمز پر مصنوعات خریدنے اور انہیں تبدیل کرنے کے لیے قابل تجارت بنائے جائیں گے۔",
    },
    1: {
      "rewards": "ਇਨਾਮ",
      "rewardsContent": "ਇੱਥੇ ਤੁਸੀਂ ਆਪਣੇ ਇਨਾਮਾਂ ਦੀ ਟਰੈਕਿੰਗ ਕਰ ਸਕਦੇ ਹੋ। ਸਾਡੇ ਇਨਾਮੀ ਸਿੱਕੇ ਬਲਾਕਚੇਨ ਦੁਆਰਾ ਬੈਕ ਕੀਤੇ ਗਏ ਹਨ ਅਤੇ ਜਲਦ ਹੀ ਉਨ੍ਹਾਂ ਨੂੰ ਹੋਰ ਪਲੇਟਫਾਰਮਾਂ 'ਤੇ ਉਤਪਾਦ ਖਰੀਦਣ ਅਤੇ ਬਦਲਣ ਲਈ ਵਪਾਰਯੋਗ ਬਣਾਇਆ ਜਾਵੇਗਾ।",
    },
    2: {
      "rewards": "इनाम",
      "rewardsContent": "यह वह जगह है जहां आप अपने इनामों को ट्रैक कर सकते हैं। हमारे इनामी सिक्के ब्लॉकचेन द्वारा समर्थित हैं और जल्द ही अन्य प्लेटफार्मों पर उत्पाद खरीदने और उन्हें बदलने के लिए व्यापार योग्य बनाए जाएंगे।",
    },
    3: {
      "rewards": "इनाम",
      "rewardsContent": "यह वह जगह है जहां आप अपने इनामों को ट्रैक कर सकते हैं। हमारे इनामी सिक्के ब्लॉकचेन द्वारा समर्थित हैं और जल्द ही अन्य प्लेटफार्मों पर उत्पाद खरीदने और उन्हें बदलने के लिए व्यापार योग्य बनाए जाएंगे।",
    },
    4: {
      "rewards": "इनाम",
      "rewardsContent": "ई जगह बा जहाँ रउआ आपन इनाम के ट्रैक कर सकेनी। हमार इनामी सिक्का ब्लॉकचेन से समर्थित बा अउर जल्दी ही ओह के अन्य प्लेटफार्म पर उत्पाद खरीदे आ बदले खातिर ट्रेडेबल बनावल जाई।",
    },
    5: {
      "rewards": "इनाम",
      "rewardsContent": "ई जगह बा जहाँ रउआ आपन इनाम ट्रैक कर सकेनी। हमनी के इनामी सिक्का ब्लॉकचेन से समर्थित बा अउर जल्दी ही अन्य प्लेटफार्म पर उत्पाद खरीदे आ बदले खातिर ट्रेडेबल बनावल जाई।",
    },
    6: {
      "rewards": "পুরস্কার",
      "rewardsContent": "এখানে আপনি আপনার পুরস্কার ট্র্যাক করতে পারেন। আমাদের পুরস্কার কয়েন ব্লকচেইনের মাধ্যমে সুরক্ষিত এবং শীঘ্রই অন্যান্য প্ল্যাটফর্মে পণ্য কেনার এবং পরিবর্তনের জন্য বিনিময়যোগ্য করা হবে।",
    },
    7: {
      "rewards": "ઇનામ",
      "rewardsContent": "આ તે જગ્યા છે જ્યાં તમે તમારા ઇનામોનું ટ્રેકિંગ કરી શકો છો. અમારા ઇનામી સિક્કા બ્લોકચેઇન દ્વારા સપોર્ટેડ છે અને ટૂંક સમયમાં અન્ય પ્લેટફોર્મ પર ઉત્પાદનો ખરીદવા અને તેમને બદલવા માટે વેપારી બનાવવામાં આવશે.",
    },
    8: {
      "rewards": "পুৰস্কাৰ",
      "rewardsContent": "এইটো সেই স্থান য'ত আপুনি আপোনাৰ পুৰস্কাৰ অনুসৰণ কৰিব পাৰে। আমাৰ পুৰস্কাৰ মুদ্ৰা ব্লকচেইন দ্বাৰা সমৰ্থিত আৰু শীঘ্ৰেই আন প্লেটফৰ্মত সামগ্ৰী কিনিবলৈ আৰু সলনি কৰিবলৈ ব্যৱসায়যোগ্য হ'ব।",
    },
    9: {
      "rewards": "ପୁରସ୍କାର",
      "rewardsContent": "ଏଠି ଆପଣ ଆପଣଙ୍କର ପୁରସ୍କାର ଟ୍ର୍ୟାକ୍ କରିପାରିବେ। ଆମର ପୁରସ୍କାର ସିକ୍କାଗୁଡ଼ିକ ବ୍ଲକଚେନ୍ ଦ୍ଵାରା ଦିଆଯାଇଛି ଏବଂ ଶୀଘ୍ର ଅନ୍ୟାନ୍ୟ ପ୍ଲାଟଫର୍ମରେ ପଦାର୍ଥ କ୍ରୟ ଏବଂ ପରିବର୍ତ୍ତନ ପାଇଁ ବ୍ୟବସାୟ ଯୋଗ୍ୟ ହେବ।",
    },
    10: {
      "rewards": "बक्षीस",
      "rewardsContent": "ही ती जागा आहे जिथे तुम्ही तुमच्या बक्षीसांचे ट्रॅकिंग करू शकता. आमची बक्षीस नाणी ब्लॉकचेनने समर्थित आहेत आणि लवकरच ती इतर प्लॅटफॉर्मवर उत्पादने खरेदी करण्यासाठी आणि एक्सचेंज करण्यासाठी व्यापारयोग्य केली जातील.",
    },
    11: {
      "rewards": "பரிசுகள்",
      "rewardsContent": "இது நீங்கள் உங்கள் பரிசுகளை கண்காணிக்கக்கூடிய இடம். எங்கள் பரிசு நாணயங்கள் பிளாக்செயினால் ஆதரிக்கப்படுகின்றன மற்றும் விரைவில் பிற தளங்களில் பொருட்களை வாங்கவும் பரிமாறவும் வணிகத்திற்காக மாற்றப்படும்.",
    },
    12: {
      "rewards": "బహుమతులు",
      "rewardsContent": "ఇది మీరు మీ బహుమతులను ట్రాక్ చేయగలిగే స్థలం. మా బహుమతుల నాణేలు బ్లాక్‌చైన్ ద్వారా మద్దతు పొందాయి మరియు త్వరలో ఇతర ప్లాట్‌ఫారమ్‌లపై ఉత్పత్తులను కొనుగోలు చేయడానికి మరియు మార్చడానికి ట్రేడబుల్‌గా మారతాయి.",
    },
    13: {
      "rewards": "ಪ್ರಶಂಸೆ",
      "rewardsContent": "ಇದು ನೀವು ನಿಮ್ಮ ಪ್ರಶಸ್ತಿಗಳನ್ನು ಹಿಂಬಾಲಿಸಬಹುದಾದ ಸ್ಥಳ. ನಮ್ಮ ಪ್ರಶಸ್ತಿ ನಾಣ್ಯಗಳು ಬ್ಲಾಕ್‌ಚೈನ್ ಮೂಲಕ ಬೆಂಬಲಿತವಾಗಿವೆ ಮತ್ತು ಬೇರೆ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್‌ಗಳಲ್ಲಿ ಉತ್ಪನ್ನಗಳನ್ನು ಖರೀದಿಸಲು ಮತ್ತು ವಿನಿಮಯ ಮಾಡಲು ಶೀಘ್ರದಲ್ಲೇ ವ್ಯಾಪಾರಯೋಗ್ಯವಾಗುತ್ತವೆ.",
    },
    14: {
      "rewards": "പ്രതിഫലം",
      "rewardsContent": "ഇത് നിങ്ങൾക്ക് നിങ്ങളുടെ പ്രതിഫലങ്ങൾ ട്രാക്ക് ചെയ്യാൻ കഴിയുന്ന സ്ഥലം. ഞങ്ങളുടെ പ്രതിഫല നാണയങ്ങൾ ബ്ലോക്ക്ചെയിനിന്റെ പിന്തുണയോടെ ഉണ്ട്, എത്രയും വേഗം മറ്റ് പ്ലാറ്റ്ഫോമുകളിൽ ഉൽപ്പന്നങ്ങൾ വാങ്ങുന്നതിനും വിനിമയം നടത്തുന്നതിനുമായി വ്യാപാരയോഗ്യമാകും.",
    },
    15: {
      "rewards": "Rewards",
      "rewardsContent": "This is where you can track your rewards. Our reward coins are backed by blockchain and will soon be made tradable to buy products on other platforms and convert them.",
    },
  };

  String t(String key) {
    return translations[languageIndex]?[key] ?? translations[15]![key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t("rewards"),
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            t("rewardsContent"),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20.0,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationScreen extends StatelessWidget {
  final int languageIndex;
  NotificationScreen({Key? key, required this.languageIndex}) : super(key: key);

  final Map<int, Map<String, String>> translations = {
    0: {
      "notification": "اطلاع",
      "notificationContent": "آپ کی اطلاعات یہاں ظاہر ہوں گی",
    },
    1: {
      "notification": "ਸੂਚਨਾਵਾਂ",
      "notificationContent": "ਤੁਹਾਡੀਆਂ ਸੂਚਨਾਵਾਂ ਇੱਥੇ ਦਿੱਖਣਗੀਆਂ",
    },
    2: {
      "notification": "सूचनाएं",
      "notificationContent": "आपकी सूचनाएं यहाँ दिखाई देंगी",
    },
    3: {
      "notification": "सूचनाएं",
      "notificationContent": "आपकी सूचनाएं यहाँ प्रदर्शित होंगी",
    },
    4: {
      "notification": "सूचनाएं",
      "notificationContent": "आपकी सूचनाएँ यहाँ दिखेंगी",
    },
    5: {
      "notification": "सूचना",
      "notificationContent": "रउवा के सूचना इहाँ देखाई",
    },
    6: {
      "notification": "বিজ্ঞপ্তি",
      "notificationContent": "আপনার বিজ্ঞপ্তিগুলি এখানে প্রদর্শিত হবে",
    },
    7: {
      "notification": "સૂચના",
      "notificationContent": "તમારી સૂચનાઓ અહીં દેખાશે",
    },
    8: {
      "notification": "সুচনা",
      "notificationContent": "আপোনাৰ সুচনাবোৰ ইয়াত দেখুৱা হব",
    },
    9: {
      "notification": "ସୂଚନା",
      "notificationContent": "ତମର ସୂଚନା ଏଠି ଦେଖାଯିବ",
    },
    10: {
      "notification": "सूचना",
      "notificationContent": "तुमच्या सूचना येथे दिसतील",
    },
    11: {
      "notification": "அறிவிப்பு",
      "notificationContent": "உங்கள் அறிவிப்புகள் இங்கே தோன்றும்",
    },
    12: {
      "notification": "నోటిఫికేషన్",
      "notificationContent": "మీ నోటిఫికేషన్లు ఇక్కడ కనిపిస్తాయి",
    },
    13: {
      "notification": "ಅಧಿಸೂಚನೆ",
      "notificationContent": "ನಿಮ್ಮ ಅಧಿಸೂಚನೆಗಳು ಇಲ್ಲಿ ಕಾಣಿಸಿಕೊಳ್ಳುತ್ತವೆ",
    },
    14: {
      "notification": "അറിയിപ്പ്",
      "notificationContent": "നിങ്ങളുടെ അറിയിപ്പുകൾ ഇവിടെ കാണിക്കും",
    },
    15: {
      "notification": "Notification",
      "notificationContent": "Your notifications will appear here",
    },
  };

  String t(String key) {
    return translations[languageIndex]?[key] ?? translations[15]![key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t("notification"),
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            t("notificationContent"),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20.0,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  final int languageIndex;
  PrivacyScreen({Key? key, required this.languageIndex}) : super(key: key);

  final Map<int, Map<String, String>> translations = {
    0: {
      "privacy": "رازداری",
      "privacyContent": "یہ رازداری کی سکرین ہے",
    },
    1: {
      "privacy": "ਗੋਪਨੀਯਤਾ",
      "privacyContent": "ਇਹ ਗੋਪਨੀਯਤਾ ਸਕ੍ਰੀਨ ਹੈ",
    },
    2: {
      "privacy": "निजी",
      "privacyContent": "यह निजी स्क्रीन से",
    },
    3: {
      "privacy": "गोपनीयता",
      "privacyContent": "यह गोपनीयता स्क्रीन है",
    },
    4: {
      "privacy": "निजी",
      "privacyContent": "ई निजी स्क्रीन है",
    },
    5: {
      "privacy": "निजी",
      "privacyContent": "ई निजी स्क्रीन बा",
    },
    6: {
      "privacy": "গোপনীয়তা",
      "privacyContent": "এটি গোপনীয়তার স্ক্রিন",
    },
    7: {
      "privacy": "ગોપનીયતા",
      "privacyContent": "આ ગોપનીયતા સ્ક્રીન છે",
    },
    8: {
      "privacy": "গোপনীয়তা",
      "privacyContent": "এইটো গোপনীয়তাৰ স্ক্ৰিন",
    },
    9: {
      "privacy": "ଗୋପନୀୟତା",
      "privacyContent": "ଏହା ଗୋପନୀୟତା ସ୍କ୍ରିନ୍",
    },
    10: {
      "privacy": "गोपनीयता",
      "privacyContent": "ही गोपनीयता स्क्रीन आहे",
    },
    11: {
      "privacy": "தனியுரிமை",
      "privacyContent": "இது தனியுரிமை திரை",
    },
    12: {
      "privacy": "గోప్యత",
      "privacyContent": "ఇది గోప్యత స్క్రీన్",
    },
    13: {
      "privacy": "ಗೋಪ್ಯತೆ",
      "privacyContent": "ಇದು ಗೋಪ್ಯತೆ ಪರದೆಯಾಗಿದೆ",
    },
    14: {
      "privacy": "സ്വകാര്യത",
      "privacyContent": "ഇത് സ്വകാര്യതയുടെ സ്ക്രീനാണ്",
    },
    15: {
      "privacy": "Privacy",
      "privacyContent": "This is the Privacy Screen",
    },
  };

  String t(String key) {
    return translations[languageIndex]?[key] ?? translations[15]![key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t("privacy"),
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            t("privacyContent"),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20.0,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
