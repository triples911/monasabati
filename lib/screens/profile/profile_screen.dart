import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/helpers.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfileData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showSettingsModal(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Wrap(
              children: <Widget>[
                ListTile(
                  title: Text(
                    'الإعدادات',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                SwitchListTile(
                  title: const Text('الوضع الداكن'),
                  value: isDarkMode,
                  onChanged: (value) {
                    setModalState(() {
                      isDarkMode = value;
                    });
                    themeProvider.toggleTheme(value);
                  },
                  secondary: const Icon(Icons.color_lens_outlined),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red[400]),
                  title: const Text('تسجيل الخروج'),
                  onTap: () async {
                    Navigator.of(modalContext).pop();
                    profileProvider.clearDataOnSignOut();
                    await supabase.auth.signOut();
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditNameDialog(
      BuildContext context, String currentName) async {
    _nameController.text = currentName;
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الاسم'),
        content: TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'أدخل الاسم الجديد'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_nameController.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      final profileProvider = context.read<ProfileProvider>();
      try {
        await supabase
            .from('profiles')
            .update({'full_name': newName})
            .eq('id', supabase.auth.currentUser!.id);
        profileProvider.updateFullName(newName);
      } catch (e) {
        if (mounted) {
          showInfoDialog(context,
              title: 'خطأ', content: 'فشل تحديث الاسم', isError: true);
        }
      }
    }
  }

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final imageFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (imageFile == null) return;

    final profileProvider = context.read<ProfileProvider>();
    final oldAvatarUrl = profileProvider.avatarUrl;

    try {
      final userId = supabase.auth.currentUser!.id;
      final file = File(imageFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '$userId/$fileName';

      // 1. Upload new image
      await supabase.storage.from('avatars').upload(filePath, file);

      // 2. Get new image public URL
      final newImageUrl =
          supabase.storage.from('avatars').getPublicUrl(filePath);

      // 3. Update database
      await supabase
          .from('profiles')
          .update({'avatar_url': newImageUrl}).eq('id', userId);

      // 4. If update is successful, delete old image from storage
      if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
        final oldPath = Uri.parse(oldAvatarUrl).pathSegments.last;
        // A more robust way to get the path
        final oldImagePath = oldAvatarUrl.split('/avatars/').last;
        if(oldImagePath.isNotEmpty) {
          await supabase.storage.from('avatars').remove([oldImagePath]);
        }
      }

      // 5. Update UI
      if (mounted) profileProvider.updateAvatar(newImageUrl);
    } catch (e) {
      if (mounted) {
        showInfoDialog(context,
            title: 'خطأ', content: 'فشل رفع الصورة: ${e.toString()}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'الإعدادات',
            onPressed: () => _showSettingsModal(context),
          ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.loading && provider.fullName == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => provider.fetchProfileData(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    )
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchProfileData(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _uploadAvatar,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.grey.shade300,
                                    backgroundImage: provider.avatarUrl != null
                                        ? NetworkImage(provider.avatarUrl!)
                                        : null,
                                    child: provider.avatarUrl == null
                                        ? Icon(Icons.person,
                                            size: 60,
                                            color: Colors.grey.shade600)
                                        : null,
                                  ),
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                    child: const Icon(Icons.edit,
                                        color: Colors.black, size: 20),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () => _showEditNameDialog(
                                  context, provider.fullName ?? ''),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    provider.fullName ?? 'مستخدم',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.edit_outlined, size: 20),
                                ],
                              ),
                            ),
                            Text(
                              supabase.auth.currentUser?.email ??
                                  'لا يوجد بريد إلكتروني',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('الإحصائيات',
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    Card(
                      child: IntrinsicHeight(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard('المناسبات',
                                provider.stats['events'].toString(), Icons.event),
                            const VerticalDivider(
                                width: 1,
                                thickness: 1,
                                indent: 10,
                                endIndent: 10),
                            _buildStatCard(
                                'الأصدقاء',
                                provider.stats['friends'].toString(),
                                Icons.people),
                          ],
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(count,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

