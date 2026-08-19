import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habit_harbor/presentation/auth/home_screen.dart';

import '../../../application/goal/goal_bloc.dart';
import '../../../domain/entities/user.dart';
import '../profile_screen.dart';
import '../../goals/history_details_screen.dart';

class BottomNavbar extends StatefulWidget {
  final User user;

  const BottomNavbar({Key? key, required this.user}) : super(key: key);

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  static const Color kAccent = Color(0xFF5B3DF5);
  int _currentIndex = 0;

  // ✅ Built once, not rebuilt on every tab switch — IndexedStack keeps
  // each screen's State alive (so HomeScreen's cached goals, History's
  // loaded analytics, etc. all survive switching tabs and coming back).
  late final List<Widget> _screens = [
    HomeScreen(user: widget.user),
    BlocProvider.value(
      value: context.read<GoalBloc>(),
      child: const HistoryDetailsScreen(),
    ),
    ProfileScreen(user: widget.user),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: kAccent,
        unselectedItemColor: Colors.grey[500],
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
