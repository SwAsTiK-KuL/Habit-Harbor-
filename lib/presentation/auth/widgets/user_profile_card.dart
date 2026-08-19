import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/user.dart';

class UserProfileCard extends StatelessWidget {
  final User user;
  static const Color kAccent = Color(0xFF5B3DF5);

  const UserProfileCard({super.key, required this.user});

  String _formatDateTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    final formatter = DateFormat('dd/MM/yyyy \'at\' HH:mm');
    return formatter.format(localDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
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
                  color: kAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_box_outlined,
                  color: kAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Profile Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

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
            icon: Icons.anchor_rounded,
            label: 'Member Since',
            value: _formatDateTime(user.createdAt),
          ),
          if (user.lastLogin != null)
            _ProfileInfoRow(
              icon: Icons.access_time_rounded,
              label: 'Last Login',
              value: _formatDateTime(user.lastLogin!),
              isLast: true,
            ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  static const Color kAccent = Color(0xFF5B3DF5);

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Icon in tinted purple square
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: kAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: kAccent),
          ),
          const SizedBox(width: 14),

          // Label
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),

          // Value
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
