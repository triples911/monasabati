import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/profile_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/events/common/countdown_circle.dart';
import '../../widgets/events/edit_event_dialog.dart';

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  const EventDetailsScreen({super.key, required this.event});
  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late Map<String, dynamic> _currentEvent;
  bool _needsRefresh = false;

  @override
  void initState() {
    super.initState();
    _currentEvent = Map.from(widget.event);
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذه المناسبة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف'),
              style: TextButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final profileProvider =
            Provider.of<ProfileProvider>(context, listen: false);

        await supabase
            .from('events')
            .delete()
            .match({'id': _currentEvent['id']});

        profileProvider.decrementEventCount();
        _needsRefresh = true;

        if (mounted) {
          Navigator.of(context).pop(_needsRefresh);
        }
      } catch (e) {
        if (mounted) {
          showInfoDialog(context,
              title: 'خطأ', content: 'فشل الحذف: $e', isError: true);
        }
      }
    }
  }

  void _editEvent() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: EditEventDialog(event: _currentEvent),
      ),
    ).then((updatedEvent) {
      if (updatedEvent != null && mounted) {
        setState(() => _currentEvent = updatedEvent);
        _needsRefresh = true;
      }
    });
  }

  void _shareEvent() {
    final eventDate = DateTime.parse(_currentEvent['event_date']);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final daysRemaining = eventDay.difference(today).inDays;

    Share.share(
      'تذكير بمناسبة: ${_currentEvent['name']} بتاريخ ${formatDate(eventDate)}. الأيام المتبقية: $daysRemaining أيام!',
      subject: 'مناسبة: ${_currentEvent['name']}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventDate = DateTime.parse(_currentEvent['event_date']);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final daysRemaining = eventDay.difference(today).inDays;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _needsRefresh);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentEvent['name']),
          actions: [
            IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: _deleteEvent,
                tooltip: 'حذف'),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CountdownCircle(days: daysRemaining),
              const SizedBox(height: 20),
              Text(_currentEvent['name'],
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              displayDateWidget(context, eventDate),
              const SizedBox(height: 40),
              // [بداية الإضافة]
              // إعادة عرض تفاصيل التذكير والتكرار
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_active_outlined),
                      title: const Text('التذكير'),
                      subtitle: Text(
                          (_currentEvent['reminder_days'] ?? 0) > 0
                              ? 'قبل ${_currentEvent['reminder_days']} أيام'
                              : 'التذكير غير مفعل'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.repeat),
                      title: const Text('التكرار'),
                      subtitle: Text(
                          (_currentEvent['is_recurring'] ?? false) ? 'سنوياً' : 'مرة واحدة فقط'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.public),
                      title: const Text('المشاركة مع الأصدقاء'),
                      subtitle:
                          Text(_currentEvent['is_public'] ?? false ? 'نعم' : 'لا'),
                    ),
                  ],
                ),
              ),
              // [نهاية الإضافة]
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareEvent,
                      icon: const Icon(Icons.share),
                      label: const Text('مشاركة'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _editEvent,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('تعديل'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

