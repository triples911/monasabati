import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/helpers.dart';

class AddEventDialog extends StatefulWidget {
  final bool startAsPublic;
  const AddEventDialog({super.key, this.startAsPublic = false});
  @override
  _AddEventDialogState createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _reminderController = TextEditingController(text: '1');
  final _dateController = TextEditingController();
  DateTime? _selectedDate;
  late bool _isPublic;

  // [بداية الإضافة]
  // إعادة إضافة متغيرات الحالة للميزات المطلوبة
  bool _isRecurring = false;
  bool _enableReminder = true;
  // [نهاية الإضافة]

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _isPublic = widget.startAsPublic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reminderController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _addEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      showInfoDialog(context,
          title: 'خطأ',
          content: 'الرجاء تحديد تاريخ المناسبة',
          isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await supabase.from('events').insert({
        'user_id': supabase.auth.currentUser!.id,
        'name': _nameController.text.trim(),
        'event_date': _selectedDate!.toIso8601String(),
        'is_public': _isPublic,
        // [بداية الإضافة]
        // إضافة الحقول الجديدة إلى قاعدة البيانات عند الحفظ
        'reminder_days':
            _enableReminder ? int.parse(_reminderController.text.trim()) : 0,
        'is_recurring': _isRecurring,
        // [نهاية الإضافة]
      });
      if (mounted) {
        context.read<ProfileProvider>().incrementEventCount();
        Navigator.pop(context, true); // إرجاع true للإشارة إلى النجاح
        showInfoDialog(context,
            title: 'نجاح', content: 'تمت إضافة المناسبة بنجاح');
      }
    } catch (e) {
      if (mounted) {
        showInfoDialog(context,
            title: 'خطأ', content: 'حدث خطأ: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = displayDateStringForLabel(context, _selectedDate!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                  widget.startAsPublic
                      ? 'إضافة مناسبة عامة'
                      : 'إضافة مناسبة جديدة',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'اسم المناسبة', border: OutlineInputBorder()),
                  validator: (v) =>
                      v!.isEmpty ? 'لا يمكن ترك الاسم فارغاً' : null),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  hintText: 'تاريخ المناسبة',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _pickDate,
              ),
              // [بداية الإضافة]
              // إعادة إضافة واجهة المستخدم الخاصة بالتذكير والمناسبات المتكررة
              SwitchListTile(
                title: const Text('تفعيل التذكير'),
                value: _enableReminder,
                onChanged: (v) => setState(() => _enableReminder = v),
                contentPadding: EdgeInsets.zero,
              ),
              Visibility(
                visible: _enableReminder,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: TextFormField(
                      controller: _reminderController,
                      decoration: const InputDecoration(
                          labelText: 'تذكير قبل (أيام)',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (!_enableReminder) return null;
                        return v == null ||
                                v.isEmpty ||
                                int.tryParse(v) == null
                            ? 'أدخل رقماً صحيحاً'
                            : null;
                      }),
                ),
              ),
              SwitchListTile(
                  title: const Text('مناسبة متكررة (سنوياً)'),
                  value: _isRecurring,
                  onChanged: (v) => setState(() => _isRecurring = v),
                  contentPadding: EdgeInsets.zero),
              // [نهاية الإضافة]
              SwitchListTile(
                  title: const Text('مناسبة عامة (للأصدقاء)'),
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                  contentPadding: EdgeInsets.zero),
              const SizedBox(height: 20),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _addEvent,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white),
                      child: const Text('حفظ المناسبة'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

