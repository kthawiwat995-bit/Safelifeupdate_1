import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'emergency_contacts_page.dart';
import 'medical_info_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ออกจากระบบ',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/signin');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'ผู้ใช้';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: const Icon(Icons.person, size: 56, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 4),
          Text(user?.email ?? '',
              style: const TextStyle(color: AppTheme.textSecondary)),
          
          const SizedBox(height: 40),

          // ── Menus ──
          _buildMenu(
            context,
            icon: Icons.medical_information_outlined,
            title: 'ข้อมูลการแพทย์ส่วนตัว',
            subtitle: 'กรุ๊ปเลือด, ประวัติการแพ้ยา',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MedicalInfoPage()),
            ),
          ),
          const SizedBox(height: 12),
          _buildMenu(
            context,
            icon: Icons.contact_phone_outlined,
            title: 'เบอร์ฉุกเฉินส่วนตัว',
            subtitle: 'รายชื่อผู้ติดต่อยามฉุกเฉิน',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmergencyContactsPage()),
            ),
          ),

          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout),
              label: const Text('ออกจากระบบ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.divider, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
