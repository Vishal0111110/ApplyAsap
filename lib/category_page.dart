import 'package:flutter/material.dart';
import 'recommend_item.dart';
import 'feature_item.dart';
import 'colors.dart';
// Import the data lists
import 'home.dart'; // Assuming the lists are exported

class CategoryPage extends StatefulWidget {
  final String category;
  final int langIndex;

  const CategoryPage(
      {Key? key, required this.category, required this.langIndex})
      : super(key: key);

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  // Duplicate translations from home.dart for simple implementation
  final List<Map<String, dynamic>> typedFeatures =
      features.cast<Map<String, dynamic>>();
  final List<Map<String, dynamic>> typedRecommends =
      recommends.cast<Map<String, dynamic>>();

  final Map<int, Map<String, String>> featureTranslations = {
    // Same as in home.dart
    0: {
      "UI/UX Design": "یو آئی/یو ایکس ڈیزائن",
      "Programming": "پروگرامنگ",
      "English Writing": "انگریزی تحریر",
      "Photography": "فوٹوگرافی",
      "Guitar Class": "گیٹار کلاس",
    },
    1: {
      "UI/UX Design": "ਯੂਆਈ/ਯੂਐਕਸ ਡਿਜ਼ਾਈਨ",
      "Programming": "ਪ੍ਰੋਗ੍ਰਾਮਿੰਗ",
      "English Writing": "ਅੰਗਰੇਜ਼ੀ ਲਿਖਾਈ",
      "Photography": "ਫੋਟੋਗ੍ਰਾਫੀ",
      "Guitar Class": "ਗੀਟਾਰ ਕਲਾਸ",
    },
    // ... Add all other language indices, copying from home.dart
    3: {
      "UI/UX Design": "यूआई/यूएक्स डिज़ाइन",
      "Programming": "प्रोग्रामिंग",
      "English Writing": "अंग्रेज़ी लेखन",
      "Photography": "फोटोग्राफी",
      "Guitar Class": "गिटार कक्षा",
    },
    // For brevity, only include essential ones or add all
    15: {
      "UI/UX Design": "UI/UX Design",
      "Programming": "Programming",
      "English Writing": "English Writing",
      "Photography": "Photography",
      "Guitar Class": "Guitar Class",
    },
  };

  final Map<int, Map<String, String>> recommendTranslations = {
    0: {
      "Painting": "پینٹنگ",
      "Social Media": "سوشل میڈیا",
      "Caster": "کیسٹر",
      "Management": "انتظام",
    },
    1: {
      "Painting": "ਪੇਂਟਿੰਗ",
      "Social Media": "ਸੋਸ਼ਲ ਮੀਡੀਆ",
      "Caster": "ਕੇਸਟਰ",
      "Management": "ਪ੍ਰਬੰਧਨ",
    },
    3: {
      "Painting": "पेंटिंग",
      "Social Media": "सोशल मीडिया",
      "Caster": "कैस्टर",
      "Management": "प्रबंधन",
    },
    15: {
      "Painting": "Painting",
      "Social Media": "Social Media",
      "Caster": "Caster",
      "Management": "Management",
    },
  };

  final Map<int, Map<String, String>> unitTranslations = {
    0: {"hours": "گھنٹے", "lessons": "سبق"},
    1: {"hours": "ਘੰਟੇ", "lessons": "ਪਾਠ"},
    3: {"hours": "घंटे", "lessons": "पाठ"},
    15: {"hours": "hours", "lessons": "lessons"},
  };

  final Map<int, String> descriptionTranslations = {
    0: "اشاعت اور گرافک ڈیزائن میں، Lorem ipsum ایک placeholder متن ہے جو کسی دستاویز یا ٹائپ فیس کی بصری شکل کو ظاہر کرنے کے لیے استعمال ہوتا ہے بغیر کسی بامعنی مواد کے۔ Lorem ipsum کو حتمی کاپی دستیاب ہونے سے پہلے placeholder کے طور پر استعمال کیا جا سکتا ہے۔",
    1: "ਪਬਲਿਸ਼ਿੰਗ ਅਤੇ ਗ੍ਰਾਫਿਕ ਡਿਜ਼ਾਈਨ ਵਿੱਚ, Lorem ipsum ਇੱਕ placeholder ਟੈਕਸਟ ਹੈ ਜੋ ਦਸਤਾਵੇਜ਼ ਜਾਂ ਟਾਇਪਫੇਸ ਦੀ ਵਿਜ਼ੂਅਲ ਫਾਰਮ ਨੂੰ ਦਰਸਾਉਂਦਾ ਹੈ ਬਿਨਾਂ ਮਾਣਹੀਂ ਸਮੱਗਰੀ 'ਤੇ ਨਿਰਭਰ ਹੋਏ। Lorem ipsum ਨੂੰ ਅੰਤਿਮ ਨਕਲ ਤੋਂ ਪਹਿਲਾਂ placeholder ਵਜੋਂ ਵਰਤਿਆ ਜਾ ਸਕਦਾ ਹੈ।",
    3: "प्रकाशन और ग्राफिक डिज़ाइन में, Lorem ipsum एक प्लेसहोल्डर टेक्स्ट है जिसका उपयोग दस्तावेज़ या टाइपफेस के दृश्य रूप को प्रदर्शित करने के लिए किया जाता है बिना सार्थक सामग्री पर निर्भर हुए। Lorem ipsum का उपयोग अंतिम प्रति उपलब्ध होने से पहले प्लेसहोल्डर के रूप में किया जा सकता है।",
    15: "In publishing and graphic design, Lorem ipsum is a placeholder text commonly used to demonstrate the visual form of a document or a typeface without relying on meaningful content. Lorem ipsum may be used as a placeholder before the final copy is available.",
  };

  List<Map<String, dynamic>> getLocalizedFeatures() {
    return typedFeatures.map((Map<String, dynamic> item) {
      final translatedName =
          featureTranslations[widget.langIndex]?[item['name']] ?? item['name'];
      final unitTrans =
          unitTranslations[widget.langIndex] ?? unitTranslations[15]!;
      String translateUnit(String text) {
        final parts = text.split(" ");
        if (parts.length == 2) {
          final number = parts[0];
          final unit = parts[1];
          final translatedUnit = unitTrans[unit] ?? unit;
          return "$number $translatedUnit";
        }
        return text;
      }

      return {
        ...item,
        "name": translatedName,
        "duration": translateUnit(item["duration"]),
        "session": translateUnit(item["session"]),
        "description": descriptionTranslations[widget.langIndex] ??
            descriptionTranslations[15]!,
      } as Map<String, dynamic>;
    }).toList();
  }

  List<Map<String, dynamic>> getLocalizedRecommends() {
    return typedRecommends.map((Map<String, dynamic> item) {
      final translatedName = recommendTranslations[widget.langIndex]
              ?[item['name']] ??
          item['name'];
      final unitTrans =
          unitTranslations[widget.langIndex] ?? unitTranslations[15]!;
      String translateUnit(String text) {
        final parts = text.split(" ");
        if (parts.length == 2) {
          final number = parts[0];
          final unit = parts[1];
          final translatedUnit = unitTrans[unit] ?? unit;
          return "$number $translatedUnit";
        }
        return text;
      }

      return {
        ...item,
        "name": translatedName,
        "duration": translateUnit(item["duration"]),
        "session": translateUnit(item["session"]),
        "description": descriptionTranslations[widget.langIndex] ??
            descriptionTranslations[15]!,
      } as Map<String, dynamic>;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Filter features and recommends by category
    final allFeatures = getLocalizedFeatures()
        .where((item) =>
            item['category'] == widget.category || widget.category == "All")
        .toList();
    final allRecommends = getLocalizedRecommends()
        .where((item) =>
            item['category'] == widget.category || widget.category == "All")
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.category,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF000000).withOpacity(0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF000000),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
              top: kToolbarHeight + 20, left: 15, right: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course count
              if (allFeatures.isNotEmpty || allRecommends.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '${allFeatures.length + allRecommends.length} Courses',
                    style: const TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

              if (allFeatures.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Featured Courses',
                    style: TextStyle(
                      color: AppColor.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: allFeatures
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: FeatureItem(
                                data: item,
                                videoIndex: widget.langIndex,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              if (allRecommends.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Recommended for You',
                    style: TextStyle(
                      color: AppColor.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allRecommends.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RecommendItem(
                        data: allRecommends[index],
                        index: widget.langIndex,
                      ),
                    );
                  },
                ),
              ],

              if (allFeatures.isEmpty && allRecommends.isEmpty)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.school_outlined,
                            color: Color(0xFF5BC0EB),
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No courses available',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Courses for ${widget.category} will be added soon.',
                          style: const TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
