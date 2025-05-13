import 'package:flutter/material.dart';

class ReusableDatePicker extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const ReusableDatePicker({
    super.key,
    required this.controller,
    this.label = 'Select Date',
    this.initialDate,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(labelText: label),
      onTap: () async {
        final now = DateTime.now();
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate ?? now,
          firstDate: firstDate ?? DateTime(now.year),
          lastDate: lastDate ?? DateTime(2100),
        );
        if (pickedDate != null) {
          controller.text = pickedDate.toLocal().toString().split(' ')[0];
        }
      },
    );
  }
}
