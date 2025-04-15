import 'package:flutter/material.dart';
import '../model/cs.dart';

class CusServTile extends StatelessWidget {
  final CusServ rep;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CusServTile({
    super.key,
    required this.rep,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getPriorityColor() {
    switch (rep.priorityName.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getDivisionIcon() {
    switch (rep.divisionDepartmentName.toLowerCase()) {
      case 'billing':
        return Icons.attach_money;
      case 'tech':
        return Icons.computer;
      case 'ops':
        return Icons.settings;
      case 'sales':
        return Icons.shopping_cart;
      default:
        return Icons.business;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();
    final divisionIcon = _getDivisionIcon();
    final double rating = double.tryParse(rep.rating) ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: priorityColor.withOpacity(0.3), width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority indicator
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.priority_high,
                    color: priorityColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),

                // Title and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rep.titleIssues,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              rep.priorityName,
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: priorityColor.withOpacity(0.1),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 14,
                              );
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),

            // Description
            if (rep.descriptionIssues.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                rep.descriptionIssues,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const Divider(height: 24),

            // Footer with division and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Division info
                Row(
                  children: [
                    Icon(divisionIcon, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      rep.divisionDepartmentName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),

                // Quick action buttons
                Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.edit,
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
