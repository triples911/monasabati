import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/profile_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/events/add_event_dialog.dart';
import 'personal_events_tab.dart';
import 'friends_events_tab.dart';

class EventsHubScreen extends StatefulWidget {
  const EventsHubScreen({super.key});

  @override
  State<EventsHubScreen> createState() => _EventsHubScreenState();
}

class _EventsHubScreenState extends State<EventsHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<PersonalEventsTabState> _personalEventsKey = GlobalKey();
  final GlobalKey<FriendsEventsTabState> _friendsEventsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // لإعادة بناء الزر العائم عند تغيير التبويب
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEventDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: AddEventDialog(
            // [مهم] عند الإضافة من تبويب الأصدقاء، اجعل المناسبة عامة بشكل افتراضي
            startAsPublic: _tabController.index == 1,
          )),
    ).then((eventAdded) {
      if (eventAdded == true) {
        // تحديث القائمة المناسبة بعد الإضافة
        if (_tabController.index == 0) {
          _personalEventsKey.currentState?.refresh();
        } else {
          // المناسبة الشخصية قد تكون عامة أيضاً، لذا نحدث القائمتين
          _personalEventsKey.currentState?.refresh();
          _friendsEventsKey.currentState?.refresh();
        }
      }
    });
  }

  Future<void> _showDeleteAllConfirmationDialog() async {
    final eventsExist = await supabase
        .from('events')
        .select('id')
        .eq('user_id', supabase.auth.currentUser!.id)
        .limit(1);

    if (eventsExist.isEmpty && mounted) {
      showInfoDialog(context,
          title: 'لا يوجد مناسبات', content: 'قائمة المناسبات فارغة بالفعل.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
            'هل أنت متأكد من رغبتك في حذف جميع مناسباتك؟ لا يمكن التراجع عن هذا الإجراء.'),
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
          context.read<ProfileProvider>().fetchProfileData();
          _personalEventsKey.currentState?.refresh();
          showInfoDialog(context,
              title: 'نجاح', content: 'تم حذف جميع مناسباتك.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المناسبات'),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'حذف جميع المناسبات',
              onPressed: _showDeleteAllConfirmationDialog,
            ),
          if (_tabController.index == 1)
             IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث مناسبات الأصدقاء',
              onPressed: () => _friendsEventsKey.currentState?.refresh(),
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
          PersonalEventsTab(key: _personalEventsKey),
          FriendsEventsTab(key: _friendsEventsKey),
        ],
      ),
       floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        tooltip: 'إضافة مناسبة',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

