import 'package:flutter/material.dart';
import 'score_page.dart';
import 'reward_shop_page.dart';
import 'reward_manage_page.dart';

class PointsCenterPage extends StatelessWidget {
  const PointsCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('积分中心'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.stars),
                text: '积分总览',
              ),
              Tab(
                icon: Icon(Icons.shopping_bag_outlined),
                text: '积分商店',
              ),
              Tab(
                icon: Icon(Icons.edit_note),
                text: '商店管理',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ScorePage(),
            RewardShopPage(),
            RewardManagePage(),
          ],
        ),
      ),
    );
  }
}