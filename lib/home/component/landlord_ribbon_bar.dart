import 'package:flutter/material.dart';

class LandlordRibbonBar extends StatelessWidget {
  final VoidCallback onAddProperty;
  final VoidCallback onAddUnit;
  final VoidCallback onMore;

  const LandlordRibbonBar({
    super.key,
    required this.onAddProperty,
    required this.onAddUnit,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAddProperty,
                icon: const Icon(Icons.home_work_outlined),
                label: const Text("Add Property"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAddUnit,
                icon: const Icon(Icons.meeting_room_outlined),
                label: const Text("Add Unit"),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: onMore,
              icon: const Icon(Icons.more_horiz),
              tooltip: "More actions",
            ),
          ],
        ),
      ),
    );
  }
}
