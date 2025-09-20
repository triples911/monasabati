import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import 'common/countdown_circle.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const EventCard({
    super.key,
    required this.event,
    this.isSelected = false,
    required this.onTap,
    this.onLongPress,
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
      clipBehavior: Clip.antiAlias,
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
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
                    const SizedBox(height: 8),
                    Text(
                      formatDate(eventDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  CountdownCircle(days: daysRemaining),
                  if (isSelected)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

