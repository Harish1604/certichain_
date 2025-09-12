import 'package:flutter/material.dart';

class CertificateTile extends StatelessWidget {
  final String fileName;
  final String studentName;
  final String rollNo;
  final String? date;
  final VoidCallback? onTap;

  const CertificateTile({
    super.key,
    required this.fileName,
    required this.studentName,
    required this.rollNo,
    this.date,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
            "$studentName • $rollNo${date != null ? '\n$date' : ''}",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),

        ),
      ),
    );
  }
}
