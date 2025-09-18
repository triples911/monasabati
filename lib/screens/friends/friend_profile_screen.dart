import 'package:flutter/material.dart';
import '../../utils/helpers.dart';

class FriendProfileScreen extends StatefulWidget {
  final String friendId;
  final String friendName; // لتمرير الاسم وعرضه فوراً في العنوان

  const FriendProfileScreen({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFriendData();
  }

  Future<void> _fetchFriendData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // [بداية الإصلاح]
      // تعريف قائمة الـ Futures بشكل صريح لتجنب أخطاء التحويل التلقائي للأنواع
      final futures = <Future<dynamic>>[
        supabase
            .from('profiles')
            .select('avatar_url, full_name')
            .eq('id', widget.friendId)
            .single(),
        supabase.rpc('count_public_user_events',
            params: {'user_id_param': widget.friendId}),
        supabase.rpc('count_user_friends',
            params: {'user_id_param': widget.friendId}),
      ];

      // جلب جميع البيانات المطلوبة في نفس الوقت
      final results = await Future.wait(futures);
      // [نهاية الإصلاح]

      if (!mounted) return;

      final profile = results[0] as Map<String, dynamic>;
      final publicEventsCount = results[1] as int;
      final friendsCount = results[2] as int;

      setState(() {
        _profileData = {
          ...profile,
          'events': publicEventsCount,
          'friends': friendsCount,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "حدث خطأ أثناء جلب بيانات الصديق: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friendName),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchFriendData,
              child: const Text('إعادة المحاولة'),
            )
          ],
        ),
      );
    }

    if (_profileData == null) {
      return const Center(child: Text('لم يتم العثور على بيانات الملف الشخصي.'));
    }

    final avatarUrl = _profileData!['avatar_url'];
    final fullName = _profileData!['full_name'];
    final eventsCount = _profileData!['events']?.toString() ?? '0';
    final friendsCount = _profileData!['friends']?.toString() ?? '0';

    return RefreshIndicator(
      onRefresh: _fetchFriendData,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Icon(Icons.person,
                            size: 60, color: Colors.grey.shade600)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName ?? 'لا يوجد اسم',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                  child: Text('الإحصائيات',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                const Divider(indent: 20, endIndent: 20),
                IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                          'المناسبات العامة', eventsCount, Icons.event),
                      const VerticalDivider(
                          width: 1, thickness: 1, indent: 10, endIndent: 10),
                      _buildStatCard('الأصدقاء', friendsCount, Icons.people),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(count,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

