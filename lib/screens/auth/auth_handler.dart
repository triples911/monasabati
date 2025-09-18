import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/helpers.dart';
import '../main_screen.dart';
import 'auth_screen.dart';

/// ويدجت يحدد ما إذا كان المستخدم مسجلاً دخوله أم لا
/// ويعرض الشاشة المناسبة (شاشة الدخول أو الشاشة الرئيسية)
class AuthHandler extends StatelessWidget {
  const AuthHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.session != null) {
          return const MainScreen();
        }
        return const AuthScreen();
      },
    );
  }
}
