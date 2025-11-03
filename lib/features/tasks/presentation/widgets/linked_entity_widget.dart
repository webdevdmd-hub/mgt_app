import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mgt_app/features/leads/domain/entities/leads_entity.dart';
import 'package:mgt_app/features/leads/presentation/providers/lead_provider.dart';
import 'package:mgt_app/features/projects/domain/entities/project_entity.dart';
import 'package:mgt_app/features/projects/presentation/providers/project_provider.dart';

class LinkedEntityWidget extends ConsumerWidget {
  final String linkedId;
  final String linkedType;

  const LinkedEntityWidget({
    super.key,
    required this.linkedId,
    required this.linkedType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = linkedType == 'lead'
        ? ref.watch(getLeadProvider(linkedId))
        : ref.watch(getProjectProvider(linkedId));

    return asyncValue.when(
      data: (data) {
        if (data == null) {
          return const SizedBox.shrink(); // Or a placeholder if preferred
        }
        String entityName;
        IconData entityIcon;
        Color entityColor;

        if (linkedType == 'lead') {
          entityName = (data as LeadEntity).name;
          entityIcon = Icons.person_outline;
          entityColor = Colors.green.shade700;
        } else if (linkedType == 'project') {
          entityName = (data as ProjectEntity).name;
          entityIcon = Icons.business_center_outlined;
          entityColor = Colors.blue.shade700;
        } else {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: entityColor.withAlpha((0.1 * 255).toInt()),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: entityColor.withAlpha((0.3 * 255).toInt())),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(entityIcon, size: 14, color: entityColor),
              const SizedBox(width: 6),
              Text(
                '${linkedType[0].toUpperCase() + linkedType.substring(1)}: $entityName',
                style: TextStyle(
                  fontSize: 12,
                  color: entityColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(), // Or a loading indicator
      error: (error, stackTrace) => const SizedBox.shrink(), // Or an error indicator
    );
  }
}
