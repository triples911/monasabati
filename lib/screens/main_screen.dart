import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import 'events/events_hub_screen.dart';
import 'friends/friends_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // تعريف الصفحات والشاشات هنا
  static const List<Widget> _pages = <Widget>[
    EventsHubScreen(), // الشاشة الجديدة التي تحتوي على التبويبات
    FriendsScreen(),
    ProfileScreen()
  ];

  // [بداية الإصلاح]
  // تم تعديل العناوين لتناسب الشاشات الجديدة التي لها عناوينها الخاصة
  static const List<String?> _pageTitles = <String?>[
    null, // شاشة المناسبات لها عنوانها الخاص الآن
    null, // شاشة الأصدقاء لها عنوانها الخاص الآن
    null, // شاشة الملف الشخصي لها عنوانها الخاص الآن
  ];
  // [نهاية الإصلاح]


  // [بداية الإصلاح]
  // تم حذف دالة initState بالكامل لأن طلب البيانات لم يعد يحدث هنا
  // [نهاية الإصلاح]


  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final currentTitle = _pageTitles[_selectedIndex];
    return Scaffold(
      // [بداية الإصلاح]
      // يتم عرض الشريط العلوي فقط إذا كان هناك عنوان محدد لهذه الصفحة
      appBar: currentTitle != null
          ? AppBar(
              title: Text(currentTitle),
            )
          : null,
      // [نهاية الإصلاح]
      drawer: const AppDrawer(),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'الرئيسية'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt),
              label: 'الأصدقاء'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'ملفي'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      // زر الإضافة العائم لم يعد موجوداً هنا، بل تم نقله إلى شاشة المناسبات
    );
  }
}

