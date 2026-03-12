import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MedicalInfoPage extends StatefulWidget {
  const MedicalInfoPage({super.key});

  @override
  State<MedicalInfoPage> createState() => _MedicalInfoPageState();
}

class _MedicalInfoPageState extends State<MedicalInfoPage> {
  final _diseaseCtrl = TextEditingController();
  final _allergyCtrl = TextEditingController();
  final _medicationCtrl = TextEditingController();

  String _bloodType = 'ไม่ระบุ';
  bool _loading = true;
  bool _saving = false;

  final _bloodTypes = ['ไม่ระบุ', 'A', 'B', 'O', 'AB', 'A-', 'B-', 'O-', 'AB-'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('medical_info')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _bloodType = data['bloodType'] ?? 'ไม่ระบุ';
          _diseaseCtrl.text = data['disease'] ?? '';
          _allergyCtrl.text = data['allergy'] ?? '';
          _medicationCtrl.text = data['medication'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading medical info: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('medical_info')
          .set({
        'bloodType': _bloodType,
        'disease': _diseaseCtrl.text.trim(),
        'allergy': _allergyCtrl.text.trim(),
        'medication': _medicationCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกข้อมูลสำเร็จ'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving medical info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _diseaseCtrl.dispose();
    _allergyCtrl.dispose();
    _medicationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลการแพทย์ส่วนตัว'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blood Type
                  const Text('กรุ๊ปเลือด',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      )),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _bloodType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: _bloodTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _bloodType = v);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Disease
                  const Text('โรคประจำตัว',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      )),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _diseaseCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'เช่น เบาหวาน, ความดันสูง (ไม่มีให้เว้นว่าง)',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Allergy
                  const Text('ประวัติการแพ้ยา / แพ้อาหาร',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      )),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _allergyCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'เช่น แพ้กุ้ง, อาการแพ้ Penicillin',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Medication
                  const Text('ยาที่กำลังทานอยู่',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      )),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _medicationCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'ระบุชื่อยาและขนาดยาที่ทานประจำ',
                    ),
                  ),

                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveData,
                      child: _saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('บันทึกข้อมูล'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
