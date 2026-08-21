import 'package:flutter/material.dart';
import 'package:my_app/property/domain/property_model.dart';
import 'package:my_app/session/app_data.dart';
import 'package:provider/provider.dart';

import '../../route/route_constants.dart';

class MultiFamilyUnitGrid extends StatelessWidget {
  final String propertyId;
  final List<UnitModel> units;
  final Map<String, LeaseDetailsModel?> leases;

  const MultiFamilyUnitGrid({
    super.key,
    required this.propertyId,
    required this.units,
    required this.leases,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: units.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,          // 1 per row (full width)
        childAspectRatio: 3.8,      // height of each row
      ),
      itemBuilder: (context, index) {
        final unit = units[index];
        final lease = leases[unit.unitId];

        final tenantName = (lease != null && lease.tenantIds.isNotEmpty)
            ? lease.tenantIds
            .map((tid) => context.read<AppSession>().tenantCache[tid]?.name)
            .where((name) => name != null)
            .first ?? "No Tenant"
            : "No Tenant";

        final rent = lease?.rentAmount ?? 0.0;

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              propertyDetailsRoute,
              arguments: propertyId,
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // LEFT SIDE — Unit Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${unit.bedrooms} bd / ${unit.bathrooms?.toStringAsFixed(1)} ba",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${unit.sqft?.toStringAsFixed(0) ?? "0"} sqft",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),

                // RIGHT SIDE — Tenant + Rent
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tenantName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "\$${rent.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
