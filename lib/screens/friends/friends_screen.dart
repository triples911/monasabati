import 'package:flutter/material.dart';
import 'friend_requests_tab.dart';
import 'friends_list_tab.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // [بداية التعديل] - إضافة Scaffold و AppBar خاص بهذه الشاشة
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأصدقاء'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الأصدقاء'),
            Tab(text: 'الطلبات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FriendsListTab(),
          FriendRequestsTab(),
        ],
      ),
    );
    // [نهاية التعديل]
  }
}

