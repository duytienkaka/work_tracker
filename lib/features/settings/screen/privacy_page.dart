import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Work Tracker hoạt động hoàn toàn offline. Dữ liệu của bạn được lưu local trên thiết bị và không được gửi đến máy chủ nào.',
            ),
            SizedBox(height: 12),
            Text(
              'Ứng dụng chỉ sử dụng quyền lưu trữ để xuất file CSV khi bạn chọn.',
            ),
          ],
        ),
      ),
    );
  }
}
