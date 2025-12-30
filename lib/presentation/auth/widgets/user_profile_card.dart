import 'package:flutter/material.dart';

import '../../../domain/entities/user.dart';

class UserProfileCard extends StatelessWidget {
  final User user;

  const UserProfileCard({Key? key, required this.user}) : super(key: key);

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_box_outlined,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Profile Information',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _ProfileInfoRow(
              icon: Icons.person_outline,
              label: 'Username',
              value: user.username,
            ),
            const SizedBox(height: 16),

            _ProfileInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
            ),
            const SizedBox(height: 16),

            if (user.firstName != null) ...[
              _ProfileInfoRow(
                icon: Icons.badge_outlined,
                label: 'First Name',
                value: user.firstName!,
              ),
              const SizedBox(height: 16),
            ],

            if (user.lastName != null) ...[
              _ProfileInfoRow(
                icon: Icons.badge_outlined,
                label: 'Last Name',
                value: user.lastName!,
              ),
              const SizedBox(height: 16),
            ],

            _ProfileInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Member Since',
              value: _formatDateTime(user.createdAt),
            ),

            if (user.lastLogin != null) ...[
              const SizedBox(height: 16),
              _ProfileInfoRow(
                icon: Icons.schedule_outlined,
                label: 'Last Login',
                value: _formatDateTime(user.lastLogin!),
              ),
            ],
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
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
