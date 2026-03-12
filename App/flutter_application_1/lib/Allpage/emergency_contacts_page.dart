import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  late final CollectionReference _contactsRef;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser!;
    _contactsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('emergency_contacts');
  }

  Future<void> _showAddDialog([DocumentSnapshot? doc]) async {
    final nameCtrl = TextEditingController(text: doc?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: doc?['phone'] ?? '');
    final relationCtrl = TextEditingController(text: doc?['relation'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc == null ? 'เพิ่มเบอร์ฉุกเฉิน' : 'แก้ไขเบอร์ฉุกเฉิน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'เบอร์โทรศัพท์'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationCtrl,
              decoration: const InputDecoration(labelText: 'ความสัมพันธ์ (เช่น พ่อ, แม่, เพื่อน)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (doc == null) {
        await _contactsRef.add({
          'name': nameCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'relation': relationCtrl.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await doc.reference.update({
          'name': nameCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'relation': relationCtrl.text.trim(),
        });
      }
    }
  }

  Future<void> _deleteContact(DocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบรายชื่อ'),
        content: Text('ต้องการลบ ${doc['name']} ออกจากเบอร์ฉุกเฉิน?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เบอร์ฉุกเฉินส่วนตัว'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _contactsRef.orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('เกิดข้อผิดพลาด'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.contacts_outlined,
                      size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('ยังไม่มีรายชื่อเบอร์ฉุกเฉิน',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มเบอร์ใหม่'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 48),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    doc['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${doc['phone']} (${doc['relation']})'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: AppTheme.textSecondary),
                        onPressed: () => _showAddDialog(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.primary),
                        onPressed: () => _deleteContact(doc),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
