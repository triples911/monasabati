import 'package:flutter/material.dart';
import 'common/countdown_circle.dart';
import '../../utils/helpers.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  // إضافة متغير لاستقبال دالة الضغط على البطاقة
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.onTap, // إضافته للمُنشئ
  });

  @override
  Widget build(BuildContext context) {
    final eventDate = DateTime.parse(event['event_date']);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final daysRemaining = eventDay.difference(today).inDays;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: InkWell(
        // استدعاء الدالة التي تم تمريرها من الشاشة الرئيسية
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event['name'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    displayDateWidget(context, eventDate),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              CountdownCircle(days: daysRemaining),
            ],
          ),
        ),
      ),
    );
  }
}

