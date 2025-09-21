import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'colors.dart';
import 'web.dart';
import 'category_box.dart';
import 'feature_item.dart';
import 'recommend_item.dart';
import 'dart:convert' as convert;
import 'category_page.dart';
import 'profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'enrollment_service.dart';

// Export for CategoryPage
export 'home.dart';

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
        "Master the art of creating intuitive and visually appealing user interfaces. This comprehensive UI/UX Design course covers user-centered design principles, wireframing, prototyping, and user research methodologies. Learn to create engaging digital experiences that combine beautiful design with functional usability. Whether you're designing mobile apps, websites, or software interfaces, this course will equip you with industry-standard tools and techniques used by professional designers. Develop a portfolio-worthy project and gain the skills needed to excel in the growing field of UX/UI design.",
    "category": "Design",
    "instructor": "Buyyarapu Vishal",
    "difficulty": "Beginner",
    "prerequisites": ["Basic computer skills"],
    "lectures": [
      "Introduction to UI/UX",
      "Design Principles",
      "Wireframing",
      "Prototyping",
      "User Research",
      "Final Project"
    ],
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
        "Embark on your programming journey with this comprehensive course covering fundamental and advanced programming concepts. From basic syntax to complex algorithms, you'll learn multiple programming paradigms including procedural, object-oriented, and functional programming. Master debugging techniques, code optimization, and best practices used in professional software development. This course includes hands-on projects where you'll build real applications, creating a strong foundation for any programming language you choose to specialize in. Perfect for beginners looking to start a career in software development or seasoned programmers wanting to solidify their foundational knowledge.",
    "category": "Coding",
    "instructor": "Sayyad Qamar",
    "difficulty": "Intermediate",
    "prerequisites": ["Basic coding knowledge", "Logic thinking"],
    "lectures": [
      "Introduction to Programming",
      "Variables and Data Types",
      "Control Structures",
      "Functions and Methods",
      "Object-Oriented Programming",
      "Debugging Techniques",
      "Project Development",
      "Best Practices",
      "Code Optimization",
      "Advanced Topics",
      "Final Project"
    ],
  },
  {
    "id": 102,
    "name": "English Writing",
    "image":
        "https://images.unsplash.com/photo-1503676260728-1c00da094a0b?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fFZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹100.00",
    "duration": "12 hours",
    "session": "4 lessons",
    "review": "4.5",
    "is_favorited": false,
    "description":
        "Elevate your written English communication skills with this specialized writing course. Learn the fundamentals of grammar, punctuation, and sentence structure while developing creativity in expressing your thoughts through written words. Master various writing styles including academic writing, creative writing, professional correspondence, and technical documentation. This course emphasizes clarity, conciseness, and impact in written communication. Through practical exercises and feedback, you'll improve your writing confidence and ability to convey ideas effectively in both personal and professional contexts. Perfect for students, professionals, and anyone looking to enhance their writing proficiency.",
    "category": "Education",
    "instructor": "Gajanan",
    "difficulty": "Beginner",
    "prerequisites": ["Basic English knowledge"],
    "lectures": [
      "Introduction to Writing",
      "Grammar Essentials",
      "Creative Writing Techniques",
      "Professional Writing Tips"
    ],
  },
  {
    "id": 103,
    "name": "Photography",
    "image":
        "https://images.unsplash.com/photo-1472393365320-db77a5abbecc?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fVZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹100.00",
    "duration": "4 hours",
    "session": "3 lessons",
    "review": "4.5",
    "is_favorited": false,
    "description":
        "Unlock your creative potential and master the fundamental principles of photography. This course covers essential camera techniques, composition rules, and lighting fundamentals that transform ordinary shots into extraordinary images. Learn about exposure, focus, depth of field, and the creative use of light and shadow. Whether using a professional DSLR camera or a smartphone, you'll learn to capture stunning photographs in various conditions. This course is perfect for hobbyists, aspiring photographers, and content creators looking to elevate their visual storytelling skills and create impactful images.",
    "category": "Art",
    "instructor": "Thilak Murugam",
    "difficulty": "Beginner",
    "prerequisites": ["Camera or phone"],
    "lectures": ["Camera Basics", "Composition Rules", "Lighting Techniques"],
  },
  {
    "id": 104,
    "name": "Guitar Class",
    "image":
        "https://images.unsplash.com/photo-1549298240-0d8e60513026?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fVZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹150.00",
    "duration": "12 hours",
    "session": "4 lessons",
    "review": "5",
    "is_favorited": false,
    "description":
        "Begin your musical journey with comprehensive guitar instruction designed for beginners. Learn proper holding techniques, basic chords, and fundamental music theory essential for guitar playing. Master rhythm and timing while building muscle memory through progressive exercises. This course includes practice routines, song learning, and performance techniques that will help you develop confidence on the instrument. Whether you dream of playing in a band, performing solo, or simply enjoying music as a hobby, this course provides a solid foundation for guitar mastery. Includes common guitar songs to practice and maintain motivation throughout your learning journey.",
    "category": "Music",
    "instructor": "Kharishma Shaik",
    "difficulty": "Beginner",
    "prerequisites": ["Guitar", "Basic music theory"],
    "lectures": [
      "Holding the Guitar",
      "Basic Chords",
      "Simple Songs",
      "Rhythm and Timing"
    ],
  },
  // Additional courses to reach 25 total
  {
    "id": 105,
    "name": "Web Design",
    "image":
        "https://images.unsplash.com/photo-1596638787647-904d822d751e?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹200.00",
    "duration": "15 hours",
    "session": "8 lessons",
    "review": "4.2",
    "is_favorited": false,
    "description":
        "Build modern, responsive websites that engage users and deliver exceptional digital experiences. This comprehensive web design course covers everything from fundamental HTML and CSS to advanced layout techniques and responsive design principles. Learn how to create visually stunning websites that are both beautiful and functional across all devices. Master industry-standard design tools and techniques used by professional web designers. You'll create a complete portfolio website while learning about color theory, typography, user experience, and modern web design trends. Perfect for aspiring web designers, entrepreneurs looking to launch their online presence, or developers wanting to improve their design skills.",
    "category": "Design",
    "instructor": "Sarath",
    "difficulty": "Beginner",
    "prerequisites": ["Basic computer skills", "Internet browser knowledge"],
    "lectures": [
      "Introduction to Web Design",
      "HTML Basics",
      "CSS Fundamentals",
      "Layout Design",
      "Responsive Design",
      "Design Tools",
      "Color Theory",
      "Publishing Your Website"
    ],
  },
  {
    "id": 106,
    "name": "Python Programming",
    "image":
        "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹250.00",
    "duration": "18 hours",
    "session": "10 lessons",
    "review": "4.8",
    "is_favorited": false,
    "description":
        "Master Python, one of the world's most popular programming languages, and unlock endless possibilities in software development, data science, and automation. This comprehensive Python course takes you from beginner basics to intermediate proficiency, covering everything from fundamental programming concepts to advanced Python features. Learn to think like a programmer while building real-world projects including data analysis scripts, automation tools, and web applications. Explore Python's vast ecosystem of libraries and frameworks. Whether you're interested in web development, data science, artificial intelligence, or general purpose programming, Python is your perfect starting point. Develop skills that are highly valued in today's tech industry.",
    "category": "Coding",
    "instructor": "Ryan Gabriel",
    "difficulty": "Intermediate",
    "prerequisites": ["Basic programming knowledge", "Basic coding"],
    "lectures": [
      "Introduction to Python",
      "Installation and Setup",
      "Variables and Data Types",
      "Control Flow",
      "Functions and Methods",
      "Lists and Dictionaries",
      "File Handling",
      "Object-Oriented Programming",
      "Libraries and Modules",
      "Final Project"
    ],
  },
  {
    "id": 107,
    "name": "JavaScript Basics",
    "image":
        "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹180.00",
    "duration": "14 hours",
    "session": "7 lessons",
    "review": "4.6",
    "is_favorited": false,
    "description":
        "Dive into the language that powers the modern web and bring websites to life with interactive functionality. JavaScript is the backbone of web development, enabling dynamic content, interactive forms, animations, and complex web applications. This course covers JavaScript fundamentals including variables, functions, objects, and DOM manipulation, progressing to asynchronous programming, API integration, and modern ES6+ features. Learn how to make your websites interactive and responsive to user actions. Build practical projects including an interactive web application and games. Whether you're a web designer wanting to add functionality or a developer expanding your skills, JavaScript is essential for modern web development.",
    "category": "Coding",
    "instructor": "Buyyarapu Vishal",
    "difficulty": "Beginner",
    "prerequisites": ["Basic HTML knowledge", "Basic CSS"],
    "lectures": [
      "Introduction to JavaScript",
      "Variables and Data Types",
      "Functions and Events",
      "DOM Manipulation",
      "Web API Integration",
      "Async Programming",
      "Project Building"
    ],
  },
  {
    "id": 108,
    "name": "Mathematics",
    "image":
        "https://images.unsplash.com/photo-1503676260728-1c00da094a0b?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fFZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹120.00",
    "duration": "16 hours",
    "session": "9 lessons",
    "review": "4.4",
    "is_favorited": false,
    "description":
        "Strengthen your mathematical foundations and develop critical thinking skills that form the basis of science, engineering, and analytical professions. This advanced mathematics course covers essential concepts from algebra and calculus to differential equations and linear algebra. Master problem-solving techniques and mathematical reasoning through practical applications. Explore statistical analysis, probability theory, and mathematical proofs. Whether you're preparing for college-level mathematics, engineering studies, or simply want to strengthen your analytical skills, this course provides the depth and rigor needed for advanced mathematical studies. Learn to approach problems systematically and develop the mathematical intuition necessary for technical fields.",
    "category": "Education",
    "instructor": "Sayyad Qamar",
    "difficulty": "Advanced",
    "prerequisites": ["Basic algebra knowledge", "Calculus basics"],
    "lectures": [
      "Algebra Review",
      "Calculus Fundamentals",
      "Geometry Concepts",
      "Differential Equations",
      "Linear Algebra",
      "Statistics",
      "Probability Theory",
      "Mathematical Proofs",
      "Advanced Topics"
    ],
  },
  {
    "id": 109,
    "name": "Science Lab",
    "image":
        "https://images.unsplash.com/photo-1503676260728-1c00da094a0b?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fFZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹140.00",
    "duration": "22 hours",
    "session": "11 lessons",
    "review": "4.7",
    "is_favorited": false,
    "description":
        "Experience hands-on science through comprehensive laboratory work and gain practical understanding of scientific principles across multiple disciplines. This lab-intensive course combines theoretical knowledge with practical experimentation, covering chemistry, physics, and biology through carefully designed laboratory exercises. Learn essential safety protocols and laboratory techniques while conducting real experiments. Master scientific observation, measurement, and analysis skills. From chemical reactions and ecosystem studies to physics demonstrations and biological investigations, you'll develop the skills necessary for scientific research and analytical thinking. Perfect for students preparing for STEM careers or anyone interested in understanding the scientific method through direct experimentation.",
    "category": "Education",
    "instructor": "Gajanan",
    "difficulty": "Intermediate",
    "prerequisites": ["Basic science knowledge", "Laboratory safety"],
    "lectures": [
      "Lab Safety and Protocols",
      "Chemistry Experiments",
      "Physics Measurements",
      "Biology Microscopy",
      "Data Analysis Basics",
      "Scientific Research Methods",
      "Environmental Studies",
      "Material Science",
      "Physics in Action",
      "Biological Processes",
      "Final Lab Report"
    ],
  },
  {
    "id": 110,
    "name": "Digital Art",
    "image":
        "https://images.unsplash.com/photo-1472393365320-db77a5abbecc?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fVZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹130.00",
    "duration": "8 hours",
    "session": "5 lessons",
    "review": "4.3",
    "is_favorited": false,
    "description":
        "Transform your creativity into digital masterpieces using cutting-edge digital art techniques and industry-standard software. This course covers the fundamentals of digital illustration, from basic sketches to complex compositions using professional digital tools. Learn about digital brushes, layering techniques, color theory in digital spaces, and creating stunning digital portraits and illustrations. Perfect for aspiring digital artists, illustrators, and anyone looking to express their creativity through digital means. Build a strong foundation in digital art that can be applied to concept art, graphic novels, and commercial illustration projects.",
    "category": "Art",
    "instructor": "Srimanth Reddy",
    "difficulty": "Beginner",
    "prerequisites": ["Tablet/stylus", "Digital drawing software"],
    "lectures": [
      "Digital Drawing Basics",
      "Color Theory in Digital Art",
      "Digital Painting Techniques",
      "Working with Layers",
      "Creating Digital Portraits"
    ],
  },
  {
    "id": 111,
    "name": "Vocal Training",
    "image":
        "https://images.unsplash.com/photo-1549298240-0d8e60513026?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fVZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹160.00",
    "duration": "16 hours",
    "session": "8 lessons",
    "review": "4.9",
    "is_favorited": false,
    "description":
        "Develop a strong, expressive voice and enhance your singing abilities through comprehensive vocal training techniques. This course covers proper breathing methods, vocal warmup routines, pitch training, and performance techniques essential for singers at any level. Learn about vocal health, stage presence, and musical interpretation while building confidence in your vocal abilities. Whether you're preparing for auditions, looking to join a choir, or simply want to sing better for personal enjoyment, this course provides the technical foundation and practical skills needed to excel. Focus on tone quality, range expansion, and expressive performance techniques.",
    "category": "Music",
    "instructor": "Kharishma Shaik",
    "difficulty": "Intermediate",
    "prerequisites": ["Basic singing ability", "Music terminology"],
    "lectures": [
      "Breathing Techniques",
      "Voice Warm-ups",
      "Pitch Training",
      "Rhythm and Timing",
      "Song Interpretation",
      "Performance Practice",
      "Vocal Health",
      "Stage Presence"
    ],
  },
  {
    "id": 112,
    "name": "Piano Lessons",
    "image":
        "https://images.unsplash.com/photo-1549298240-0d8e60513026?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fVZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹180.00",
    "duration": "20 hours",
    "session": "12 lessons",
    "review": "4.5",
    "is_favorited": false,
    "description":
        "Begin your musical journey on the piano with structured, progressive instruction designed for beginners and intermediate players. Learn to read sheet music, master proper hand positioning, and develop technical proficiency through scales and arpeggios. Explore classical and contemporary repertoire while building finger independence and musical interpretation skills. This comprehensive course covers everything from basic note reading and rhythm exercises to complex chord progressions and performance preparation. Develop your musical ear, sight-reading abilities, and performance confidence while creating a lifelong skill that brings joy and therapeutic benefits.",
    "category": "Music",
    "instructor": "Kharishma Shaik",
    "difficulty": "Beginner",
    "prerequisites": ["Piano keyboard", "Sheet music basics"],
    "lectures": [
      "Introduction to Piano",
      "Basic Note Reading",
      "Finger Positioning",
      "Scales and Arpeggios",
      "Rhythm Exercises",
      "Simple Melodies",
      "Chord Progressions",
      "Hand Independence",
      "Musical Dynamics",
      "Ear Training",
      "Sight Reading",
      "Final Performance"
    ],
  },
  {
    "id": 113,
    "name": "Video Editing",
    "image":
        "https://images.unsplash.com/photo-1596638787647-904d822d751e?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹170.00",
    "duration": "12 hours",
    "session": "6 lessons",
    "review": "4.1",
    "is_favorited": false,
    "description":
        "Master the art of video storytelling through professional video editing techniques and industry-standard software. Learn to transform raw footage into compelling narratives using cutting-edge editing tools, transitions, and visual effects. This course covers timeline management, audio editing, color correction, and export techniques for various platforms. Whether you're creating content for social media, documentaries, marketing videos, or personal projects, you'll learn how to tell stories effectively through the editing process. Develop an understanding of pacing, visual flow, and audience engagement while building skills that are in high demand across the creative industries and content creation field.",
    "category": "Design",
    "instructor": "Sarath",
    "difficulty": "Beginner",
    "prerequisites": ["Basic computer skills", "Video files"],
    "lectures": [
      "Video Editing Software Overview",
      "Timeline and Workspace",
      "Cutting and Trimming",
      "Transitions and Effects",
      "Audio Editing",
      "Export and Finalizing"
    ],
  },
  {
    "id": 114,
    "name": "Mobile App Development",
    "image":
        "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹350.00",
    "duration": "25 hours",
    "session": "15 lessons",
    "review": "4.7",
    "is_favorited": false,
    "description":
        "Dive deep into mobile app development and create cross-platform applications that work seamlessly on both iOS and Android devices. This advanced course covers the complete mobile development lifecycle, from initial concept to deployment, using modern frameworks like Flutter and Dart. Learn about UI/UX design for mobile interfaces, state management, API integration, database handling, and advanced features like push notifications and in-app purchases. Master testing methodologies, performance optimization, and app store deployment processes. Perfect for aspiring mobile developers, startups, and experienced developers looking to expand their cross-platform development skills.",
    "category": "Coding",
    "instructor": "Ryan Gabriel",
    "difficulty": "Advanced",
    "prerequisites": ["Programming basics", "OOP concepts"],
    "lectures": [
      "App Development Fundamentals",
      "UI/UX for Mobile Apps",
      "Dart Programming",
      "Flutter Framework",
      "State Management",
      "API Integration",
      "Database Handling",
      "Authentication",
      "App Performance",
      "Testing Mobile Apps",
      "Deployment",
      "Push Notifications",
      "In-App Purchases",
      "App Maintenance",
      "Advanced Features"
    ],
  },
  {
    "id": 115,
    "name": "History Studies",
    "image":
        "https://images.unsplash.com/photo-1503676260728-1c00da094a0b?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fVZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹90.00",
    "duration": "18 hours",
    "session": "10 lessons",
    "review": "4.0",
    "is_favorited": false,
    "description":
        "Explore the fascinating tapestry of human history and develop analytical skills to understand our collective past. This comprehensive history course covers major civilizations, historical events, and their lasting impact on modern society. From ancient civilizations through world wars to contemporary events, you'll learn about historical analysis methods, research techniques, and critical thinking skills. Understand the socio-political, economic, and cultural forces that shaped the world we live in today. Perfect for history enthusiasts, students preparing for academic pursuits, or anyone interested in gaining a deeper understanding of historical contexts and their relevance to current global issues.",
    "category": "Education",
    "instructor": "Gajanan",
    "difficulty": "Intermediate",
    "prerequisites": ["Basic history knowledge", "Reading skills"],
    "lectures": [
      "Ancient Civilizations",
      "The Middle Ages",
      "The Age of Exploration",
      "Industrial Revolution",
      "Modern History",
      "World Wars",
      "Post-War Era",
      "Contemporary History",
      "Historical Analysis Methods",
      "Research Projects"
    ],
  },
  {
    "id": 116,
    "name": "Watercolor Painting",
    "image":
        "https://images.unsplash.com/photo-1472393365320-db77a5abbecc?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fVZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹110.00",
    "duration": "6 hours",
    "session": "4 lessons",
    "review": "4.6",
    "is_favorited": false,
    "description":
        "Discover the unique beauty and fluidity of watercolor painting, learning both traditional and contemporary techniques. This course covers fundamental watercolor skills including brush control, color mixing, and creating washes, progressing to landscape and nature painting. Learn to work with watercolor's unique properties including transparency, granulation, and bleeding effects to create expressive, luminous artworks. Master techniques for controlling water flow, creating texture, and building layers while exploring both realistic and impressionistic approaches. Perfect for beginners seeking a relaxing yet expressive art form, or artists wanting to add watercolor skills to their repertoire.",
    "category": "Art",
    "instructor": "Srimanth Reddy",
    "difficulty": "Beginner",
    "prerequisites": ["Watercolor brushes", "Paper", "Colors"],
    "lectures": [
      "Watercolor Basics",
      "Color Mixing Techniques",
      "Brush Control and Strokes",
      "Creating Landscapes"
    ],
  },
  {
    "id": 117,
    "name": "Drum Lessons",
    "image":
        "https://images.unsplash.com/photo-1549298240-0d8e60513026?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fVZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹140.00",
    "duration": "14 hours",
    "session": "6 lessons",
    "review": "4.4",
    "is_favorited": false,
    "description":
        "Master the rhythmic foundation of music with comprehensive drum instruction covering all essential drumming techniques. Learn proper drum setup, grip techniques, and fundamental patterns that form the basis of all rhythmic music. Develop coordination between bass and snare drums while mastering fills, accents, and dynamic playing. This course covers both rudimental and contemporary drumming approaches, including basic music theory related to rhythm and timing. Whether you aspire to play in a band, perform in concerts, or simply enjoy creating beats, you'll develop the fundamental skills and confidence needed to keep the groove going in any musical setting.",
    "category": "Music",
    "instructor": "Kharishma Shaik",
    "difficulty": "Beginner",
    "prerequisites": ["Drum set", "Basic coordination"],
    "lectures": [
      "Drum Setup and Sticks",
      "Basic Drum Strokes",
      "Simple Rhythms",
      "Bass and Snare Coordination",
      "Fills and Accents",
      "Basic Drum Patterns"
    ],
  },
  {
    "id": 118,
    "name": "Mobile Graphic Design",
    "image":
        "https://images.unsplash.com/photo-1596638787647-904d822d751e?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹180.00",
    "duration": "13 hours",
    "session": "7 lessons",
    "review": "4.3",
    "is_favorited": false,
    "description":
        "Design stunning visual experiences optimized specifically for mobile devices and touch interfaces. This specialized design course focuses on the unique challenges and opportunities of mobile design, including responsive layouts, touch-friendly interfaces, and gesture-based interactions. Learn to create effective app interfaces, user experience flows, and mobile advertising graphics using industry-standard design tools. Cover topics like mobile app UI patterns, gesture design, mobile typography, and adaptive design principles. Master prototyping techniques and user testing methodologies specifically for mobile platforms. Essential skills for designers working in the booming mobile app and digital product market.",
    "category": "Design",
    "instructor": "Sarath",
    "difficulty": "Intermediate",
    "prerequisites": ["Basic design tools", "Graphic design basics"],
    "lectures": [
      "Mobile Design Fundamentals",
      "Responsive Layouts",
      "App Interface Design",
      "User Experience Flow",
      "Design Tools for Mobile",
      "Prototyping Apps",
      "Final Mobile Design Project"
    ],
  },
  {
    "id": 119,
    "name": "Data Structures",
    "image":
        "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fGZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹220.00",
    "duration": "22 hours",
    "session": "11 lessons",
    "review": "4.8",
    "is_favorited": false,
    "description":
        "Master the fundamental building blocks of efficient programming with this comprehensive data structures course. Learn how to organize and manage data effectively to create fast, scalable applications. Explore essential data structures including arrays, linked lists, stacks, queues, trees, graphs, and hash tables. Understand time complexity analysis to measure algorithmic efficiency. Master sorting and searching algorithms, along with advanced concepts like dynamic programming and memory management. This course includes hands-on projects implementing real-world data structure applications, making you proficient in problem-solving techniques essential for technical interviews and software development careers.",
    "category": "Coding",
    "instructor": "Ryan Gabriel",
    "difficulty": "Advanced",
    "prerequisites": ["Programming basics", "Algorithms knowledge"],
    "lectures": [
      "Introduction to Data Structures",
      "Arrays and Linked Lists",
      "Stacks and Queues",
      "Trees and Binary Trees",
      "Hash Tables",
      "Graphs and Traversal",
      "Sorting and Searching Algorithms",
      "Dynamic Programming",
      "Time Complexity Analysis",
      "Memory Management",
      "Advanced Data Structure Projects"
    ],
  },
  {
    "id": 120,
    "name": "Physics Fundamentals",
    "image":
        "https://images.unsplash.com/photo-1503676260728-1c00da094a0b?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fFZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹160.00",
    "duration": "19 hours",
    "session": "12 lessons",
    "review": "4.2",
    "is_favorited": false,
    "description":
        "Dive deep into the laws governing our universe with this comprehensive physics fundamentals course. Master classical mechanics, including Newton's laws, energy conservation, and motion principles. Explore thermodynamics, electricity and magnetism, waves and oscillations, and optics. Learn about modern physics concepts including quantum mechanics and nuclear physics. This course emphasizes both theoretical understanding and practical applications, with hands-on experiments and problem-solving exercises. Perfect for students pursuing STEM careers, teachers, or anyone fascinated by how the natural world works. Develop analytical thinking and mathematical modeling skills applicable to engineering, research, and everyday problem-solving.",
    "category": "Education",
    "instructor": "Sayyad Qamar",
    "difficulty": "Intermediate",
    "prerequisites": ["Basic mathematics", "Scientific mindset"],
    "lectures": [
      "Mechanics: Motion and Forces",
      "Newton's Laws",
      "Energy and Power",
      "Thermodynamics Basics",
      "Electricity and Magnetism",
      "Waves and Oscillations",
      "Light and Optics",
      "Modern Physics Introduction",
      "Quantum Physics",
      "Nuclear Physics",
      "Experimental Physics",
      "Advanced Physics Applications"
    ],
  },
  {
    "id": 121,
    "name": "Sketching Techniques",
    "image":
        "https://images.unsplash.com/photo-1472393365320-db77a5abbecc?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fVZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹95.00",
    "duration": "7 hours",
    "session": "4 lessons",
    "review": "4.5",
    "is_favorited": false,
    "description":
        "Develop your ability to quickly capture observations and ideas on paper with professional sketching techniques. Learn fundamental drawing principles including line work, shape construction, and perspective drawing. Master quick sketching methods for capturing motion, expressions, and complex scenes in minutes. Explore various media and tools to create expressive sketches. This course is perfect for designers, architects, artists, and anyone looking to improve visual communication skills. Build confidence in visual thinking and learn to use sketching as a powerful tool for ideation, problem-solving, and documentation. Start your artistic journey with foundational skills that apply to design, illustration, and creative professions.",
    "category": "Art",
    "instructor": "Thilak Murugam",
    "difficulty": "Beginner",
    "prerequisites": [
      "Drawing pencil",
      "Sketchbook",
      "Basic observation skills"
    ],
    "lectures": [
      "Sketching Basics and Tools",
      "Line and Shape Practice",
      "Perspective Drawing",
      "Quick Sketching Techniques"
    ],
  },
  {
    "id": 122,
    "name": "Music Theory",
    "image":
        "https://images.unsplash.com/photo-1549298240-0d8e60513026?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fVZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹130.00",
    "duration": "11 hours",
    "session": "6 lessons",
    "review": "4.7",
    "is_favorited": false,
    "description":
        "Unlock the language of music with comprehensive music theory instruction that builds a foundation for any musical pursuit. Learn to read and understand music notation, scales, keys, and chord construction. Master rhythm theory, harmony, and harmonic progressions. Understand composition principles and how music is structured. Perfect for musicians, producers, composers, and music enthusiasts who want to deepen their understanding of musical language. This course is essential for performers, songwriters, and producers who want to communicate effectively through music. Develop analytical listening skills and learn to apply theoretical concepts to real musical compositions and improvisations.",
    "category": "Music",
    "instructor": "Kharishma Shaik",
    "difficulty": "Intermediate",
    "prerequisites": ["Basic music knowledge", "Ability to read notes"],
    "lectures": [
      "Reading Music Notation",
      "Scales and Keys",
      "Chord Construction",
      "Harmony and Harmony Progressions",
      "Rhythm Theory",
      "Music Composition Basics"
    ],
  },
  {
    "id": 123,
    "name": "Advanced Photoshoop",
    "image":
        "https://images.unsplash.com/photo-1472393365320-db77a5abbecc?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fVZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹80.00",
    "duration": "5 hours",
    "session": "3 lessons",
    "review": "4.1",
    "is_favorited": false,
    "description":
        "Take your Photoshop skills to professional levels with advanced compositing and editing techniques. Master complex layer management, advanced masking techniques, and professional photo manipulation methods. Learn to create stunning composites, remove objects seamlessly, and enhance images creatively. Explore digital painting techniques, color grading, and advanced retouching methods used by professional photographers and designers. Perfect for photographers, designers, and digital artists looking to master industry-standard post-processing workflows. Develop skills that open doors to professional photo editing, advertising, and digital art creation. Requires existing Photoshop knowledge for optimal learning experience.",
    "category": "Art",
    "instructor": "Buyyarapu Vishal",
    "difficulty": "Advanced",
    "prerequisites": ["Photoshop basics", "Creativity"],
    "lectures": [
      "Advanced Layer Techniques",
      "Complex Compositing",
      "Professional Photo Editing"
    ],
  },
];

List recommends = [
  {
    "id": 105,
    "name": "Painting",
    "image":
        "https://images.unsplash.com/photo-1596548438137-d51ea5c83ca5?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fFZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹60.00",
    "duration": "12 hours",
    "session": "8 lessons",
    "review": "4.5",
    "is_favorited": false,
    "description":
        "Explore the expressive world of painting and develop your artistic skills across multiple mediums and techniques. Learn fundamental principles of composition, color theory, and visual storytelling while discovering various painting styles from classical to contemporary. Master different tools and materials while understanding how to convey emotion and narrative through visual art. This comprehensive course covers drawing foundations, color mixing, texture creation, and finishing techniques. Perfect for beginners looking to begin their artistic journey or intermediate painters wanting to expand their skills. Create a portfolio that showcases your artistic growth and personal style development.",
    "category": "Art",
    "instructor": "Srimanth Reddy",
    "difficulty": "Beginner",
    "prerequisites": ["Paint brushes", "Canvas", "Colors"],
    "lectures": [
      "Color Mixing Basics",
      "Brush Techniques",
      "Creating Textures",
      "Portrait Painting",
      "Landscape Art",
      "Abstract Painting",
      "Watercolor Techniques",
      "Final Project"
    ],
  },
  {
    "id": 106,
    "name": "Social Media",
    "image":
        "https://images.unsplash.com/photo-1611162617213-7d7a39e9b1d7?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fVZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹100.00",
    "duration": "6 hours",
    "session": "4 lessons",
    "review": "4",
    "is_favorited": false,
    "description":
        "Master the art of social media marketing and digital engagement in today's connected world. Learn strategic content creation, platform optimization, audience building, and growth hacking techniques used by successful brands and influencers. Understand algorithm mechanics, engagement best practices, and analytical insights that drive results. This course covers comprehensive strategies for platforms like Instagram, TikTok, LinkedIn, and Twitter, teaching you how to create compelling content calendars, manage online communities, and leverage social media for business growth. Essential skills for marketers, entrepreneurs, and content creators in the digital age.",
    "category": "Business",
    "instructor": "Ryan Gabriel",
    "difficulty": "Beginner",
    "prerequisites": ["Internet access", "Basic computer skills"],
    "lectures": [
      "Social Media Platforms Overview",
      "Content Creation Strategies",
      "Engagement Best Practices",
      "Analytics and Growth Tracking"
    ],
  },
  {
    "id": 107,
    "name": "Caster",
    "image":
        "https://images.unsplash.com/photo-1554446422-d05db23719d2?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fVZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹90.00",
    "duration": "8 hours",
    "session": "4 lessons",
    "review": "4.5",
    "is_favorited": false,
    "description":
        "Learn the professional skills of casting directors and talent management in entertainment industries. Understand talent evaluation, casting processes, and audition techniques used in theater, film, and television production. This course covers character analysis, performer assessment, script breakdown, and effective communication with actors and directors. Gain insights into the creative and business aspects of casting, including budget considerations, union regulations, and industry networking. Perfect for aspiring casting directors, theater professionals, production managers, and anyone interested in talent acquisition and entertainment production. Develop the critical eye and interpersonal skills essential for successful casting decisions.",
    "category": "Business",
    "instructor": "Buyyarapu Vishal",
    "difficulty": "Intermediate",
    "prerequisites": ["Basic business concepts", "Communication skills"],
    "lectures": [
      "Casting Fundamentals",
      "Role Analysis and Selection",
      "Audition Techniques",
      "Casting Best Practices"
    ],
  },
  {
    "id": 108,
    "name": "Management",
    "image":
        "https://images.unsplash.com/photo-1542626991-cbc4e32524cc?ixid=MXwxMjA3fDB8MHxzZWFyY2h8MTF8fVZhc2hpb258ZW58MHx8MHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60",
    "price": "\₹150.00",
    "duration": "9 hours",
    "session": "5 lessons",
    "review": "4.5",
    "is_favorited": false,
    "description":
        "Develop essential leadership and management skills for today's dynamic business environment. Learn strategic planning, team building, conflict resolution, and performance management techniques that drive organizational success. This comprehensive course covers modern management theories, communication strategies, and decision-making frameworks used by successful leaders. Explore project management methodologies, change management, and employee motivation techniques. Gain practical skills in delegation, time management, and strategic thinking necessary for managerial roles. Perfect for aspiring managers, team leaders, and professionals looking to advance their careers through effective leadership and management competencies.",
    "category": "Business",
    "instructor": "Sarath",
    "difficulty": "Intermediate",
    "prerequisites": ["Prior work experience", "Basic communication skills"],
    "lectures": [
      "Management Fundamentals",
      "Team Leadership",
      "Project Management",
      "Decision Making",
      "Performance Optimization"
    ],
  }
];

class HomePage extends StatefulWidget {
  final int
      langIndex; // 0: Kashmiri, 1: Punjabi, 2: Haryanvi, 3: Hindi, 4: Rajasthani, 5: Bhojpuri, 6: Bengali, 7: Gujarati, 8: Assamese, 9: Odia, 10: Marathi, 11: Tamil, 12: Telugu, 13: Kannada, 14: Malayalam, 15: English

  const HomePage({Key? key, required this.langIndex}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late Future<ResultData1> futureResult;
  String selectedCategory = "All";

  final EnrollmentService _enrollmentService = EnrollmentService();
  Set<String> _enrolledCourseIds = {};

  String getHomeTitle(int index) {
    // Use the same as result_screen's dashboardTitle1 for consistency
    switch (index) {
      case 3:
        return 'स्मार्ट लर्निंग';
      case 15:
        return 'Smart Learning';
      default:
        return 'Smart Learning';
    }
  }

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
      'featured': 'Recommended for You',
      'recommended': 'Featured',
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
    _loadEnrolledCourses();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh enrolled courses when app comes back into foreground
      _loadEnrolledCourses();
    }
  }

  Future<void> _loadEnrolledCourses() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('enrollments')
          .get();

      if (snapshot.exists && snapshot.value is Map) {
        final enrollments = snapshot.value as Map;
        setState(() {
          _enrolledCourseIds = enrollments.keys.cast<String>().toSet();
        });
      }
    } catch (e) {
      debugPrint('Error loading enrolled courses: $e');
    }
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

  Widget _buildStatCard(String count, String label) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColor.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5BC0EB).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: TextStyle(
              color: AppColor.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColor.labelColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List _getFilteredCourses() {
    final allFeatures = getLocalizedFeatures();
    final allRecommends = getLocalizedRecommends();

    final filteredFeatures = selectedCategory == "All"
        ? allFeatures
        : allFeatures
            .where((item) => item['category'] == selectedCategory)
            .toList();

    final filteredRecommends = selectedCategory == "All"
        ? allRecommends
        : allRecommends
            .where((item) => item['category'] == selectedCategory)
            .toList();

    return [...filteredFeatures, ...filteredRecommends];
  }

  // Convert categories data using translations.
  List getLocalizedCategories() {
    return categories.map((item) {
      final translatedName =
          currentCategoryTranslations[item['name']] ?? item['name'];
      return {
        "name": translatedName,
        "originalName": item['name'],
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
        "instructor": item["instructor"],
        "difficulty": item["difficulty"],
        "prerequisites": item["prerequisites"],
        "lectures": item["lectures"],
        "category": item["category"],
        "review": item["review"],
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
        "instructor": item["instructor"],
        "difficulty": item["difficulty"],
        "prerequisites": item["prerequisites"],
        "lectures": item["lectures"],
        "category": item["category"],
        "review": item["review"],
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
          return Container(
            color: const Color(0xFF000000),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Categories section moved to top
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(15, 10, 0, 20),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...List.generate(
                          getLocalizedCategories().length,
                          (index) {
                            final categories = getLocalizedCategories();
                            return Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: CategoryBox(
                                selectedColor: Colors.white,
                                data: categories[index],
                                isSelected: categories[index]['originalName'] ==
                                    selectedCategory,
                                onTap: () {
                                  setState(() {
                                    selectedCategory =
                                        categories[index]['originalName'];
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Compact welcome banner
                  Container(
                    height: 100,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColor.primary.withOpacity(0.9),
                          AppColor.secondary.withOpacity(0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF5BC0EB).withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.langIndex == 15
                                      ? 'Learn Today'
                                      : widget.langIndex == 3
                                          ? 'आज सीखें'
                                          : 'Learn Today',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.langIndex == 15
                                      ? 'Discover courses & start learning'
                                      : widget.langIndex == 3
                                          ? 'कोर्स खोजें और सीखना शुरू करें'
                                          : 'Start Learning',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF5BC0EB).withOpacity(0.8),
                                  AppColor.sky.withOpacity(0.6)
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Icon(
                              Icons.rocket_launch,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Compact stats section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _buildStatCard(
                              '10+',
                              widget.langIndex == 15
                                  ? 'Students'
                                  : widget.langIndex == 3
                                      ? 'विद्यार्थी'
                                      : 'Students'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                              '20+',
                              widget.langIndex == 15
                                  ? 'Courses'
                                  : widget.langIndex == 3
                                      ? 'कोर्स'
                                      : 'Courses'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                              '5+',
                              widget.langIndex == 15
                                  ? 'Tutors'
                                  : widget.langIndex == 3
                                      ? 'शिक्षक'
                                      : 'Tutors'),
                        ),
                      ],
                    ),
                  ),

                  _buildBody(),

                  // Promotional section - More compact design
                  Container(
                    height: 70,
                    margin: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                    decoration: BoxDecoration(
                      color: AppColor.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF5BC0EB).withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.primary.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.langIndex == 15
                                      ? 'Get Certified'
                                      : widget.langIndex == 3
                                          ? 'प्रमाणित करें'
                                          : 'Get Certified',
                                  style: TextStyle(
                                    color: AppColor.textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.langIndex == 15
                                      ? 'Complete courses & earn certificates'
                                      : widget.langIndex == 3
                                          ? 'कोर्स पूरा करें और प्रमाणपत्र अर्जित करें'
                                          : 'Earn Certificates',
                                  style: TextStyle(
                                    color: AppColor.labelColor,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColor.primary, AppColor.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom spacer for navigation bar
                  SizedBox(height: 120), // Extra bottom padding
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: _buildBodyContent(),
    );
  }

  Future<void> _onRefresh() async {
    // Reload enrolled courses and refresh the display
    await _loadEnrolledCourses();
    setState(() {});
  }

  Widget _buildBodyContent() {
    // Get localized features and recommends
    final allFeatures = getLocalizedFeatures();
    final allRecommends = getLocalizedRecommends();

    // Apply category filter
    final filteredFeatures = selectedCategory == "All"
        ? allFeatures
        : allFeatures
            .where((item) => item['category'] == selectedCategory)
            .toList();

    final filteredRecommends = selectedCategory == "All"
        ? allRecommends
        : allRecommends
            .where((item) => item['category'] == selectedCategory)
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommended for You Section
          if (filteredFeatures.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
              child: Text(
                currentHeadings['featured'] ?? 'Recommended for You',
                style: TextStyle(
                  color: AppColor.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
            ),
          if (filteredFeatures.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 15),
              child: Row(
                children: List.generate(
                  filteredFeatures.length,
                  (index) {
                    final course = filteredFeatures[index];
                    final courseId =
                        (course["id"] ?? course["name"] ?? "unknown_course")
                            .toString();
                    final isEnrolled = _enrolledCourseIds.contains(courseId);

                    // Ensure complete course data is passed (same as Featured section)
                    final completeCourseData = <String, dynamic>{
                      ...course.cast<String, dynamic>(),
                      "id":
                          course["id"] ?? index + 1000, // Ensure we have an ID
                      "originalName": course["originalName"] ?? course["name"],
                      "index": index, // Add index for navigation
                      "isEnrolled": isEnrolled,
                    };

                    return Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: FeatureItem(
                        data: completeCourseData,
                        videoIndex: widget.langIndex,
                        isEnrolled: isEnrolled,
                      ),
                    );
                  },
                ),
              ),
            ),
          if (filteredFeatures.isNotEmpty) const SizedBox(height: 15),

          // Featured Section
          if (filteredRecommends.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 5),
              child: Text(
                currentHeadings['recommended'] ?? 'Featured',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textColor,
                ),
              ),
            ),
          if (filteredRecommends.isNotEmpty)
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(15, 5, 0, 5),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  filteredRecommends.length,
                  (index) {
                    final course = filteredRecommends[index];
                    final courseId =
                        (course["id"] ?? course["name"] ?? "unknown_course")
                            .toString();
                    final isEnrolled = _enrolledCourseIds.contains(courseId);

                    // Ensure complete course data is passed
                    final completeCourseData = <String, dynamic>{
                      ...course.cast<String, dynamic>(),
                      "id":
                          course["id"] ?? index + 1000, // Ensure we have an ID
                      "originalName": course["originalName"] ?? course["name"],
                    };

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: RecommendItem(
                        data: completeCourseData,
                        index: widget.langIndex,
                        isEnrolled: isEnrolled,
                      ),
                    );
                  },
                ),
              ),
            ),

          // Empty state when no courses available for selected category
          if (filteredFeatures.isEmpty && filteredRecommends.isEmpty)
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
                      'Courses for $selectedCategory will be added soon.',
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
