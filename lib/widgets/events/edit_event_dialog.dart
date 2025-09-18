import 'package:flutter/material.dart';
import '../../utils/helpers.dart';

class EditEventDialog extends StatefulWidget {
  final Map<String, dynamic> event;
  const EditEventDialog({super.key, required this.event});
  @override
  _EditEventDialogState createState() => _EditEventDialogState();
}

class _EditEventDialogState extends State<EditEventDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _dateController = TextEditingController();
  DateTime? _selectedDate;
  bool _loading = false;
  late bool _isPublic;

  // [بداية الإضافة]
  // إضافة متغيرات الحالة للميزات المطلوبة
  late bool _isRecurring;
  late bool _enableReminder;
  late final TextEditingController _reminderController;
  // [نهاية الإضافة]

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event['name']);
    _selectedDate = DateTime.parse(widget.event['event_date']);
    _dateController.text = displayDateStringForLabel(context, _selectedDate!);
    _isPublic = widget.event['is_public'] ?? false;

    // [بداية الإضافة]
    // تهيئة قيم المتغيرات من بيانات المناسبة الحالية
    _isRecurring = widget.event['is_recurring'] ?? false;
    _enableReminder =
        widget.event['reminder_days'] != null && widget.event['reminder_days'] > 0;
    _reminderController =
        TextEditingController(text: (widget.event['reminder_days'] ?? 1).toString());
    // [نهاية الإضافة]
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reminderController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _updateEvent() async {
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
      final updatedEventData = {
        'name': _nameController.text.trim(),
        'event_date': _selectedDate!.toIso8601String(),
        'is_public': _isPublic,
        // [بداية الإضافة]
        // إضافة الحقول الجديدة إلى بيانات التحديث
        'reminder_days':
            _enableReminder ? int.parse(_reminderController.text.trim()) : 0,
        'is_recurring': _isRecurring,
        // [نهاية الإضافة]
      };
      await supabase
          .from('events')
          .update(updatedEventData)
          .eq('id', widget.event['id']);
      if (mounted) {
        Navigator.pop(context, {...widget.event, ...updatedEventData});
        showInfoDialog(context,
            title: 'نجاح', content: 'تم تعديل المناسبة بنجاح.');
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
              const Text('تعديل المناسبة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      onPressed: _updateEvent,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white),
                      child: const Text('حفظ التعديلات'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

