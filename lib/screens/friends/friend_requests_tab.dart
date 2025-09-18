import 'package:flutter/material.dart';
import '../../utils/helpers.dart';

class FriendRequestsTab extends StatefulWidget {
  const FriendRequestsTab({super.key});
  @override
  _FriendRequestsTabState createState() => _FriendRequestsTabState();
}

class _FriendRequestsTabState extends State<FriendRequestsTab> {
  late Future<List<Map<String, dynamic>>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _fetchFriendRequests();
  }

  Future<List<Map<String, dynamic>>> _fetchFriendRequests() async {
    final myId = supabase.auth.currentUser!.id;
    final requestRelations = await supabase
        .from('friends')
        .select('id, user_1_id')
        .eq('user_2_id', myId)
        .eq('status', 'pending');
    if (requestRelations.isEmpty) return [];

    final requestorIds =
        requestRelations.map<String>((req) => req['user_1_id']).toList();
    final profiles = await supabase
        .from('profiles')
        .select('id, full_name, avatar_url') // --- [تم التعديل] ---
        .inFilter('id', requestorIds);

    return profiles.map((profile) {
      final relation =
          requestRelations.firstWhere((rel) => rel['user_1_id'] == profile['id']);
      return {...profile, 'friendship_id': relation['id']};
    }).toList();
  }

  Future<void> _updateRequest(int friendshipId, String status) async {
    try {
      await supabase
          .from('friends')
          .update({'status': status}).eq('id', friendshipId);
      if (mounted) {
        showInfoDialog(context, title: 'نجاح', content: 'تم تحديث الطلب');
        _refreshRequests(); // تحديث القائمة بعد قبول أو رفض الطلب
      }
    } catch (e) {
      if (mounted) {
        showInfoDialog(context,
            title: 'خطأ', content: 'حدث خطأ ما', isError: true);
      }
    }
  }

  Future<void> _refreshRequests() async {
    setState(() {
      _requestsFuture = _fetchFriendRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshRequests,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: const Center(
                        child: Text('لا توجد طلبات صداقة حالياً',
                            style: TextStyle(color: Colors.grey))),
                  ),
                );
              }
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: request['avatar_url'] != null
                        ? NetworkImage(request['avatar_url'])
                        : null,
                    child: request['avatar_url'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(request['full_name'] ?? 'لا يوجد اسم'), // --- [تم التعديل] ---
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () =>
                              _updateRequest(request['friendship_id'], 'accepted')),
                      IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () =>
                              _updateRequest(request['friendship_id'], 'declined')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

