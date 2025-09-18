import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../widgets/events/event_card.dart';
import 'event_details_screen.dart';

class PersonalEventsTab extends StatefulWidget {
  const PersonalEventsTab({super.key});

  @override
  // تم تحويل الحالة إلى عامة ليمكن الوصول إليها من الخارج
  PersonalEventsTabState createState() => PersonalEventsTabState();
}

// تم تحويل اسم الكلاس إلى عام (Public) بإزالة الشرطة السفلية
class PersonalEventsTabState extends State<PersonalEventsTab> {
  // دالة عامة لتحديث الواجهة يمكن استدعاؤها من الخارج
  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  // دالة للانتقال إلى تفاصيل المناسبة وتحديث القائمة عند العودة
  void _navigateToDetails(Map<String, dynamic> event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(event: event),
      ),
    ).then((_) {
      // عند العودة من شاشة التفاصيل، قم بتحديث هذه الشاشة
      refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    // استخدام StreamBuilder للاستماع للتغيرات في قاعدة البيانات تلقائياً
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('events')
          .stream(primaryKey: ['id'])
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('event_date', ascending: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }
        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد مناسبات بعد.\nاضغط على علامة + لإضافة مناسبة جديدة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            refresh();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(
                event: event,
                onTap: () => _navigateToDetails(event),
              );
            },
          ),
        );
      },
    );
  }
}

