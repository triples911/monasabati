import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../widgets/events/friend_event_card.dart';

class FriendsEventsTab extends StatefulWidget {
  const FriendsEventsTab({super.key});

  @override
  // تم تحويل الحالة إلى عامة ليمكن الوصول إليها من الخارج
  FriendsEventsTabState createState() => FriendsEventsTabState();
}

// تم تحويل اسم الكلاس إلى عام (Public) بإزالة الشرطة السفلية
class FriendsEventsTabState extends State<FriendsEventsTab> {
  late Future<List<Map<String, dynamic>>> _friendsEventsFuture;

  @override
  void initState() {
    super.initState();
    _friendsEventsFuture = _fetchFriendsEvents();
  }

  Future<List<Map<String, dynamic>>> _fetchFriendsEvents() async {
    final myId = supabase.auth.currentUser!.id;
    try {
      final data = await supabase
          .from('events')
          .select('*, profiles(full_name, avatar_url)')
          .not('user_id', 'eq', myId)
          .eq('is_public', true)
          .order('event_date', ascending: true);
      return data;
    } catch (e) {
      debugPrint('Error fetching friends events: $e');
      throw Exception('Failed to load friends events');
    }
  }

  // دالة عامة لتحديث الواجهة يمكن استدعاؤها من الخارج
  Future<void> refresh() async {
    if (mounted) {
      setState(() {
        _friendsEventsFuture = _fetchFriendsEvents();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _friendsEventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('حدث خطأ في جلب البيانات.'),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: refresh, child: const Text('إعادة المحاولة'))
              ],
            ),
          );
        }
        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                 Center(
                  child: Text(
                    'لا توجد مناسبات عامة من أصدقائك حالياً.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return FriendEventCard(event: event);
            },
          ),
        );
      },
    );
  }
}

