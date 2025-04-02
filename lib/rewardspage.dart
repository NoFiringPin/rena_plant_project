import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class RewardsPage extends StatefulWidget {
  @override
  _RewardsPageState createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  int userPoints = 0;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  final List<Map<String, dynamic>> rewards = [
    {'image': 'assets/item1.jpg', 'name': 'Watering Can', 'cost': 100},
    {'image': 'assets/item2.jpg', 'name': 'Fertilizer Pack', 'cost': 200},
    {'image': 'assets/item3.jpg', 'name': 'Plant Pot', 'cost': 300},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserPoints();
  }

  void _fetchUserPoints() async {
    final snapshot = await _database.child('plant1/points').get();
    if (snapshot.exists) {
      setState(() {
        userPoints = int.parse(snapshot.value.toString());
      });
    }
  }

  void _redeemReward(int cost) async {
    if (userPoints >= cost) {
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Redemption'),
          content: Text('Redeem this reward for $cost points?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Redeem'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        setState(() {
          userPoints -= cost;
        });
        await _database.child('plant1/points').set(userPoints);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reward redeemed!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not enough points to redeem this item.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rewards Redemption'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Your Points: $userPoints', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: rewards.length,
                itemBuilder: (context, index) {
                  final reward = rewards[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Image.asset(reward['image'], width: 50, height: 50),
                      title: Text(reward['name']),
                      subtitle: Text('Cost: ${reward['cost']} points'),
                      trailing: ElevatedButton(
                        onPressed: () => _redeemReward(reward['cost']),
                        child: Text('Redeem'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
