import 'package:flutter/material.dart';

class CertificateTile extends StatelessWidget {
  final String fileName;
  final String studentName;
  final String rollNo;
  final String date;

  const CertificateTile({
    super.key,
    required this.fileName,
    required this.studentName,
    required this.rollNo,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.purpleAccent),
        title: Text(
          fileName,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "$studentName • Roll: $rollNo\n$date",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Colors.white70, size: 16),
      ),
    );
  }
}
