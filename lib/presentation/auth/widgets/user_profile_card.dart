import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/user.dart';

class UserProfileCard extends StatelessWidget {
  final User user;

  const UserProfileCard({super.key, required this.user});

  String _formatDateTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    final formatter = DateFormat('dd/MM/yyyy \'at\' HH:mm');
    return formatter.format(localDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_box_outlined,
                    color: Colors.blue[600],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Profile Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Profile Information Rows
            _ProfileInfoRow(
              icon: Icons.person_outline,
              label: 'Username',
              value: user.username,
            ),

            _ProfileInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
            ),

            if (user.firstName != null)
              _ProfileInfoRow(
                icon: Icons.badge_outlined,
                label: 'First Name',
                value: user.firstName!,
              ),

            if (user.lastName != null)
              _ProfileInfoRow(
                icon: Icons.badge_outlined,
                label: 'Last Name',
                value: user.lastName!,
              ),

            _ProfileInfoRow(
              icon: Icons.anchor,
              label: 'Member Since',
              value: _formatDateTime(user.createdAt),
            ),

            if (user.lastLogin != null)
              _ProfileInfoRow(
                icon: Icons.access_time,
                label: 'Last Login',
                value: _formatDateTime(user.lastLogin!),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon with blue circular background
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 16),

          // Label
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),

          // Value
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue[600],
              ),
              textAlign: TextAlign.right,
            ),
          ),

          const SizedBox(width: 8),

          // Forward arrow
          Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
