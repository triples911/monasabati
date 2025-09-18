import 'package:flutter/material.dart';
import '../utils/helpers.dart';

/// Provider لإدارة بيانات ملف المستخدم
class ProfileProvider extends ChangeNotifier {
  String? _avatarUrl;
  String? get avatarUrl => _avatarUrl;

  String? _fullName;
  String? get fullName => _fullName;

  Map<String, int> _stats = {'events': 0, 'friends': 0};
  Map<String, int> get stats => _stats;

  bool _loading = true;
  bool get loading => _loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// دالة لمسح بيانات المستخدم عند تسجيل الخروج
  void clearDataOnSignOut() {
    _avatarUrl = null;
    _fullName = null;
    _stats = {'events': 0, 'friends': 0};
    _loading = true;
    _errorMessage = null;
    // لا نستخدم notifyListeners() هنا لتجنب إعادة بناء الواجهة دون داعٍ
  }

  /// جلب بيانات الملف الشخصي والإحصائيات من Supabase
  Future<void> fetchProfileData() async {
    // [بداية الإصلاح]
    // نبدأ دائماً بتعيين حالة التحميل وإعلام الواجهة فوراً
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser!.id;

      final results = await Future.wait<dynamic>([
        supabase
            .from('profiles')
            .select('avatar_url, full_name')
            .eq('id', userId)
            .single(),
        supabase.rpc('count_user_events', params: {'user_id_param': userId}),
        supabase.rpc('count_user_friends', params: {'user_id_param': userId}),
      ]);

      final profileData = results[0] as Map<String, dynamic>;
      _avatarUrl = profileData['avatar_url'];
      _fullName = profileData['full_name'];
      _stats['events'] = results[1] as int;
      _stats['friends'] = results[2] as int;
    } catch (e) {
      // في حالة حدوث خطأ، نقوم بطباعته في الطرفية للمساعدة في التشخيص
      debugPrint("Error fetching profile data: ${e.toString()}");
      _errorMessage =
          'فشل تحميل البيانات. الرجاء التحقق من الصلاحيات أو اتصالك بالإنترنت.';
    } finally {
      // في النهاية، سواء نجحت العملية أو فشلت، نوقف التحميل ونعلم الواجهة
      _loading = false;
      notifyListeners();
    }
    // [نهاية الإصلاح]
  }

  /// زيادة عدد المناسبات (للتحديث الفوري للواجهة)
  void incrementEventCount() {
    _stats['events'] = (_stats['events'] ?? 0) + 1;
    notifyListeners();
  }

  /// تقليل عدد المناسبات (للتحديث الفوري للواجهة)
  void decrementEventCount() {
    if ((_stats['events'] ?? 0) > 0) {
      _stats['events'] = _stats['events']! - 1;
      notifyListeners();
    }
  }

  /// تحديث الصورة الرمزية
  void updateAvatar(String newUrl) {
    _avatarUrl = newUrl;
    notifyListeners();
  }

  /// تحديث الاسم الكامل
  void updateFullName(String newName) {
    _fullName = newName;
    notifyListeners();
  }
}

