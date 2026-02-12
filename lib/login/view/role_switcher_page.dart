import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/session/user_role.dart';
import 'package:my_app/login/service/role_resolver.dart';

class RoleSwitcherSheet extends StatelessWidget {
  final List<String> orgIds;

  const RoleSwitcherSheet({
    super.key,
    required this.orgIds,
  });

  @override
  Widget build(BuildContext context) {
    final session = context.read<AppSession>();
    final roleResolver = context.read<RoleResolver>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Switch Organization",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            ...orgIds.map((orgId) {
              final isActive = session.activeOrgId == orgId;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.blue.withOpacity(0.08)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Text(
                    "Organization: $orgId",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: isActive
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () async {
                    session.setActiveOrg(orgId);

                    final resolvedRole = await roleResolver.resolveRole(
                      userId: session.userId!,
                      orgId: orgId,
                    );

                    session.setActiveRole(resolvedRole);

                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
