import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../widgets/events/event_card.dart';
import 'event_details_screen.dart';

class PersonalEventsTab extends StatefulWidget {
  final ValueChanged<Set<int>> onSelectionChanged;

  const PersonalEventsTab({super.key, required this.onSelectionChanged});

  @override
  PersonalEventsTabState createState() => PersonalEventsTabState();
}

class PersonalEventsTabState extends State<PersonalEventsTab> {
  // --- [ BEGIN RADICAL FIX ] ---
  // We will now manage the list of events directly in the state.
  List<Map<String, dynamic>>? _events;
  Future<void>? _fetchEventsFuture;
  Set<int> _selectedEventIds = {};
  bool get _isSelectionMode => _selectedEventIds.isNotEmpty;
  // --- [ END RADICAL FIX ] ---

  @override
  void initState() {
    super.initState();
    // Fetch events only once on initial load
    _fetchEventsFuture = _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final data = await supabase
          .from('events')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('event_date', ascending: true);
      if (mounted) {
        setState(() {
          _events = data;
        });
      }
    } catch (e) {
      if (mounted) {
        // You might want to show an error message here
        debugPrint("Error fetching events: $e");
      }
    }
  }

  // --- [ BEGIN RADICAL FIX ] ---
  // Public method to be called from the parent widget to instantly remove events
  void removeEventsFromUI(Set<int> idsToRemove) {
    if (_events == null) return;
    setState(() {
      _events!.removeWhere((event) => idsToRemove.contains(event['id']));
      // Clear selection after deletion
      _selectedEventIds.clear();
      widget.onSelectionChanged(_selectedEventIds);
    });
  }

  void refresh() {
    clearSelection();
    setState(() {
      _fetchEventsFuture = _fetchEvents();
    });
  }
  // --- [ END RADICAL FIX ] ---

  void _handleTap(Map<String, dynamic> event) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedEventIds.contains(event['id'])) {
          _selectedEventIds.remove(event['id']);
        } else {
          _selectedEventIds.add(event['id']);
        }
        widget.onSelectionChanged(_selectedEventIds);
      });
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => EventDetailsScreen(event: event),
      )).then((_) => refresh());
    }
  }

  void _handleLongPress(Map<String, dynamic> event) {
    setState(() {
      if (!_selectedEventIds.contains(event['id'])) {
        _selectedEventIds.add(event['id']);
      }
      widget.onSelectionChanged(_selectedEventIds);
    });
  }

  void clearSelection() {
    setState(() {
      _selectedEventIds.clear();
      widget.onSelectionChanged(_selectedEventIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => refresh(),
      child: FutureBuilder(
        future: _fetchEventsFuture,
        builder: (context, snapshot) {
          // Show loading indicator only on the first load
          if (_events == null &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          // Use the state variable as the source of truth for the UI
          final events = _events ?? [];

          if (events.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد مناسبات بعد.\nاضغط على علامة + لإضافة مناسبة جديدة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isSelected = _selectedEventIds.contains(event['id']);
              return EventCard(
                event: event,
                isSelected: isSelected,
                onTap: () => _handleTap(event),
                onLongPress: () => _handleLongPress(event),
              );
            },
          );
        },
      ),
    );
  }
}

