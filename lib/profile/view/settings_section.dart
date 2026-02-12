import 'package:flutter/material.dart';


class SettingsSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<SettingsItem> items;

  const SettingsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.2)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: Icon(widget.icon, color: Colors.grey),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.normal,
          ),
        ),
        initiallyExpanded: expanded,
        onExpansionChanged: (v) => setState(() => expanded = v),
        children: widget.items,
      ),
    );
  }
}



class SettingsItem extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const SettingsItem({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(fontFamily: 'Roboto'),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
