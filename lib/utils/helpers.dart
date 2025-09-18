import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// اختصار للوصول إلى Supabase client
final supabase = Supabase.instance.client;

/// دالة لتنسيق التاريخ بالشكل "YYYY/MM/DD"
String formatDate(DateTime date) {
  return "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";
}

/// ويدجت لعرض التاريخ الميلادي بتنسيق مميز
Widget displayDateWidget(BuildContext context, DateTime gregorianDate) {
  String gregorianStr = formatDate(gregorianDate);
  TextStyle highlightedStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).textTheme.bodyLarge?.color,
  );
  return Text(gregorianStr, style: highlightedStyle);
}

/// دالة ترجع التاريخ كنص لاستخدامه في الحقول النصية
String displayDateStringForLabel(BuildContext context, DateTime gregorianDate) {
  return formatDate(gregorianDate);
}

/// دالة عامة لعرض نافذة معلومات أو خطأ
Future<void> showInfoDialog(BuildContext context,
    {required String title, required String content, bool isError = false}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content, textDirection: TextDirection.rtl),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('حسنًا',
              style: TextStyle(
                  color: isError ? Colors.red : Theme.of(context).primaryColor)),
        ),
      ],
    ),
  );
}

