import 'package:flutter/material.dart';
import 'long_term_history_page.dart';
import 'long_term_page.dart';

class LongTermCenterPage extends StatelessWidget {
  const LongTermCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TabBarWrapper(),
        body: TabBarView(
          children: [
            LongTermPage(),
            LongTermHistoryPage(),
          ],
        ),
      ),
    );
  }
}

class TabBarWrapper extends StatelessWidget implements PreferredSizeWidget {
  const TabBarWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('长期计划中心'),
      bottom: const TabBar(
        tabs: [
          Tab(
            icon: Icon(Icons.flag),
            text: '长期计划',
          ),
          Tab(
            icon: Icon(Icons.history),
            text: '历史记录',
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);
}