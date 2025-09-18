import 'package:flutter/material.dart';
// import '../../utils/helpers.dart';
import '../../widgets/events/common/countdown_circle.dart';

class FriendEventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const FriendEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final eventDate = DateTime.parse(event['event_date']);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final daysRemaining = eventDay.difference(today).inDays;

    // [بداية التعديل] - طريقة جديدة لجلب بيانات المنشئ
    // البيانات الآن تأتي ككائن متداخل (nested object) من استعلام Flutter
    final creatorData = event['profiles'] as Map<String, dynamic>?;
    final creatorName = creatorData?['full_name'] ?? 'صديق';
    final creatorAvatar = creatorData?['avatar_url'];
    // [نهاية التعديل]

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  creatorAvatar != null ? NetworkImage(creatorAvatar) : null,
              child: creatorAvatar == null
                  ? const Icon(Icons.person_outline)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'بواسطة: $creatorName',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            CountdownCircle(days: daysRemaining),
          ],
        ),
      ),
    );
  }
}

