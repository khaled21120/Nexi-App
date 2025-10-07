import 'package:flutter/material.dart';
import 'package:nexi/features/auth/data/models/user_model.dart';

class PeopleListItem extends StatelessWidget {
  const PeopleListItem({
    super.key,
    required this.isSelected,
    required this.user,
    required this.onTap,
  });
  final bool isSelected;
  final UserModel user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).primaryColor.withValues(alpha:0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha:0.3)
              : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            color: isSelected ? Colors.white : Colors.grey.shade600,
            size: 20,
          ),
        ),
        title: Text(
          user.name ?? "Unknown User",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        subtitle: Text(
          user.email ?? "",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade400,
              width: 2,
            ),
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
          ),
          child: isSelected
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
        onTap: onTap,
      ),
    );
  }
}
