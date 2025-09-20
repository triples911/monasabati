import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/profile_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/events/add_event_dialog.dart';
import 'friends_events_tab.dart';
import 'personal_events_tab.dart';

class EventsHubScreen extends StatefulWidget {
  const EventsHubScreen({super.key});

  @override
  EventsHubScreenState createState() => EventsHubScreenState();
}

class EventsHubScreenState extends State<EventsHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<PersonalEventsTabState> _personalTabKey =
      GlobalKey<PersonalEventsTabState>();
  Set<int> _selectedPersonalEvents = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_selectedPersonalEvents.isNotEmpty) {
        _cancelSelection();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onSelectionChanged(Set<int> selectedIds) {
    setState(() {
      _selectedPersonalEvents = selectedIds;
    });
  }

  void _cancelSelection() {
    _personalTabKey.currentState?.clearSelection();
  }

  Future<void> _deleteSelectedEvents() async {
    final count = _selectedPersonalEvents.length;
    if (count == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من رغبتك في حذف $count مناسبات محددة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await supabase
            .from('events')
            .delete()
            .inFilter('id', _selectedPersonalEvents.toList());

        // --- [ BEGIN RADICAL FIX ] ---
        // Instead of a slow refresh, instantly remove the items from the UI.
        if (mounted) {
          _personalTabKey.currentState
              ?.removeEventsFromUI(_selectedPersonalEvents);
        }
        // --- [ END RADICAL FIX ] ---

        final profileProvider = context.read<ProfileProvider>();
        for (int i = 0; i < count; i++) {
          profileProvider.decrementEventCount();
        }

        if (mounted) {
          showInfoDialog(context,
              title: 'نجاح', content: 'تم حذف المناسبات المحددة.');
          // The selection is now cleared automatically inside removeEventsFromUI
          // _cancelSelection();
        }
      } catch (e) {
        if (mounted) {
          showInfoDialog(context,
              title: 'خطأ',
              content: 'فشل حذف المناسبات: $e',
              isError: true);
        }
      }
    }
  }

  Future<void> _showDeleteAllConfirmationDialog() async {
    final count = await supabase
        .from('events')
        .count()
        .eq('user_id', supabase.auth.currentUser!.id);

    if (count == 0 && mounted) {
      showInfoDialog(context,
          title: 'لا يوجد مناسبات', content: 'قائمة المناسبات فارغة بالفعل.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
            'هل أنت متأكد من رغبتك في حذف جميع المناسبات؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف الكل'),
              style: TextButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await supabase
            .from('events')
            .delete()
            .eq('user_id', supabase.auth.currentUser!.id);
        if (mounted) {
          Provider.of<ProfileProvider>(context, listen: false)
              .fetchProfileData();
          _personalTabKey.currentState?.refresh();
          showInfoDialog(context,
              title: 'نجاح', content: 'تم حذف جميع المناسبات.');
        }
      } catch (e) {
        if (mounted) {
          showInfoDialog(context,
              title: 'خطأ',
              content: 'فشل حذف المناسبات: $e',
              isError: true);
        }
      }
    }
  }

  void _showAddEventDialog(BuildContext context) {
    bool isPublicTab = _tabController.index == 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: AddEventDialog(startAsPublic: isPublicTab)),
    ).then((result) {
      // If an event was added, refresh the list
      if (result == true) {
        _personalTabKey.currentState?.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelectionMode =
        _selectedPersonalEvents.isNotEmpty && _tabController.index == 0;

    return Scaffold(
      appBar: AppBar(
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelSelection,
                tooltip: 'إلغاء التحديد',
              )
            : null,
        title: Text(isSelectionMode
            ? '${_selectedPersonalEvents.length} محدد'
            : 'المناسبات'),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'حذف المحدد',
              onPressed: _deleteSelectedEvents,
            )
          else if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'حذف جميع المناسبات',
              onPressed: _showDeleteAllConfirmationDialog,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'مناسباتي'),
            Tab(text: 'مناسبات الأصدقاء'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PersonalEventsTab(
            key: _personalTabKey,
            onSelectionChanged: _onSelectionChanged,
          ),
          const FriendsEventsTab(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context),
        tooltip: 'إضافة مناسبة',
        child: const Icon(Icons.add),
      ),
    );
  }
}

