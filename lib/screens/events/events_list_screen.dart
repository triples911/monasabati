import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../widgets/events/event_card.dart';
import 'event_details_screen.dart'; // استيراد شاشة التفاصيل

// تم تحويل الويدجت إلى StatefulWidget للسماح بإعادة تحميل البيانات يدوياً
class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  // جعل الكلاس State عاماً (public) للوصول إليه من الشاشة الرئيسية
  EventsListScreenState createState() => EventsListScreenState();
}

class EventsListScreenState extends State<EventsListScreen> {
  // استخدام Future للاحتفاظ ببيانات المناسبات بدلاً من Stream
  late Future<List<Map<String, dynamic>>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    // جلب البيانات الأولية عند بدء تشغيل الشاشة
    _eventsFuture = _fetchEvents();
  }

  // دالة لجلب المناسبات من Supabase
  Future<List<Map<String, dynamic>>> _fetchEvents() async {
    final userId = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('events')
        .select()
        .eq('user_id', userId)
        .order('event_date', ascending: true);
    return data;
  }

  // دالة عامة (public) لتحديث القائمة، يمكن استدعاؤها من الخارج
  Future<void> refreshEvents() async {
    // استدعاء setState سيؤدي إلى إعادة بناء FutureBuilder بالبيانات الجديدة
    setState(() {
      _eventsFuture = _fetchEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    // استبدال StreamBuilder بـ FutureBuilder
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }
        final events = snapshot.data ?? [];

        // إضافة RefreshIndicator للسماح بالسحب للتحديث
        return RefreshIndicator(
          onRefresh: refreshEvents, // استدعاء دالة التحديث عند السحب
          child: events.isEmpty
              ? Stack(
                  children: [
                    // جعل القائمة الفارغة قابلة للسحب أيضاً
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                    ),
                    const Center(
                      child: Text(
                        'لا توجد مناسبات بعد.\nاضغط على علامة + لإضافة مناسبة جديدة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    // --- [بداية التعديل] ---
                    // تم نقل منطق التنقل إلى هنا للتحكم في عملية التحديث
                    return EventCard(
                      event: event,
                      onTap: () async {
                        // الانتقال إلى شاشة التفاصيل وانتظار نتيجة
                        final refreshNeeded = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EventDetailsScreen(event: event),
                          ),
                        );

                        // إذا كانت النتيجة "true"، فهذا يعني أنه تم حذف عنصر
                        // ويجب تحديث القائمة
                        if (refreshNeeded == true && mounted) {
                          refreshEvents();
                        }
                      },
                    );
                    // --- [نهاية التعديل] ---
                  },
                ),
        );
      },
    );
  }
}

