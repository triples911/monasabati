import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import 'friend_profile_screen.dart'; // استيراد الشاشة الجديدة

class FriendsListTab extends StatefulWidget {
  const FriendsListTab({super.key});
  @override
  _FriendsListTabState createState() => _FriendsListTabState();
}

class _FriendsListTabState extends State<FriendsListTab> {
  final _friendCodeController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    _friendsFuture = _fetchFriends();
  }

  Future<void> _addFriend() async {
    final friendCode = _friendCodeController.text.trim();
    if (friendCode.isEmpty) return;
    try {
      final response = await supabase
          .from('profiles')
          .select('id')
          .eq('friend_code', friendCode)
          .single();
      final friendId = response['id'];
      final myId = supabase.auth.currentUser!.id;
      if (friendId == myId) {
        if (mounted) {
          showInfoDialog(context,
              title: 'خطأ',
              content: 'لا يمكنك إضافة نفسك كصديق.',
              isError: true);
        }
        return;
      }

      await supabase
          .from('friends')
          .insert({'user_1_id': myId, 'user_2_id': friendId});
      _friendCodeController.clear();
      if (mounted) {
        showInfoDialog(context,
            title: 'نجاح', content: 'تم إرسال طلب الصداقة بنجاح!');
      }
    } catch (e) {
      if (mounted) {
        showInfoDialog(context,
            title: 'خطأ',
            content: 'الكود غير صحيح أو أن الطلب موجود مسبقاً.',
            isError: true);
      }
    }
  }

  Future<void> _refreshFriends() async {
    setState(() {
      _friendsFuture = _fetchFriends();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchFriends() async {
    final myId = supabase.auth.currentUser!.id;
    final response = await supabase.from('friends').select('user_1_id, user_2_id').or(
        'and(user_1_id.eq.$myId,status.eq.accepted),and(user_2_id.eq.$myId,status.eq.accepted)');

    final friendIds = response
        .map<String>((friend) =>
            friend['user_1_id'] == myId ? friend['user_2_id'] : friend['user_1_id'])
        .toList();

    if (friendIds.isEmpty) return [];

    return await supabase
        .from('profiles')
        .select('id, full_name, avatar_url')
        .inFilter('id', friendIds);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshFriends,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('إضافة صديق جديد',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _friendCodeController,
                      decoration: const InputDecoration(
                          labelText: 'أدخل كود الصداقة هنا',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _addFriend,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('إضافة'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _friendsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('خطأ: ${snapshot.error}'));
              }
              final friends = snapshot.data ?? [];
              if (friends.isEmpty) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('ليس لديك أصدقاء بعد',
                            style: TextStyle(color: Colors.grey))));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('قائمة الأصدقاء (${friends.length})',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: friend['avatar_url'] != null
                                ? NetworkImage(friend['avatar_url'])
                                : null,
                            child: friend['avatar_url'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(friend['full_name'] ?? 'لا يوجد اسم'),
                          onTap: () {
                            // الانتقال إلى شاشة الملف الشخصي للصديق
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FriendProfileScreen(
                                  friendId: friend['id'],
                                  friendName:
                                      friend['full_name'] ?? 'ملف شخصي',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          )
        ],
      ),
    );
  }
}

