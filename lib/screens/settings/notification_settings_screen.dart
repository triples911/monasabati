import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _allNotifications = true;
  bool _friendNotifications = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التحكم في الإشعارات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('جميع الإشعارات'),
            subtitle: const Text('تفعيل أو تعطيل كل إشعارات التطبيق'),
            value: _allNotifications,
            onChanged: (val) => setState(() => _allNotifications = val),
          ),
          SwitchListTile(
            title: const Text('إشعارات الأصدقاء'),
            subtitle:
                const Text('تلقي إشعارات عند إضافة مناسبات جديدة من الأصدقاء'),
            value: _friendNotifications,
            onChanged: (val) => setState(() => _friendNotifications = val),
          ),
        ],
      ),
    );
  }
}
