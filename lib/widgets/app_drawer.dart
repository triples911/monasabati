import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../utils/helpers.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Text('الإعدادات',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          SwitchListTile(
            title: const Text('الوضع الداكن'),
            value: isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(value),
            secondary: const Icon(Icons.color_lens_outlined),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('التحكم في الإشعارات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red[400]),
            title: const Text('تسجيل الخروج'),
            onTap: () async {
              // تخزين البروفايدر قبل إغلاق السياق لتجنب الأخطاء
              final profileProvider =
                  Provider.of<ProfileProvider>(context, listen: false);
              Navigator.pop(context); // إغلاق القائمة الجانبية

              // مسح بيانات المستخدم الحالية من الحالة
              profileProvider.clearDataOnSignOut();

              // تسجيل الخروج من Supabase
              await supabase.auth.signOut();
            },
          ),
        ],
      ),
    );
  }
}
