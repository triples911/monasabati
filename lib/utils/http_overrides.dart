import 'dart:io';

// هذا الكلاس يقوم بتجاوز التحقق من شهادات SSL.
// يستخدم لحل مشكلة "HandshakeException" التي قد تظهر في بيئة التطوير.
// تحذير: لا تستخدم هذا الكود في النسخة الإنتاجية (Production) أبداً.
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

// دالة لتطبيق الكلاس أعلاه
void applyHttpOverrides() {
  HttpOverrides.global = MyHttpOverrides();
}
