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
        userPoints = ((snapshot.value ?? 0) as num).toInt();
      });
    }
  }

  void _redeemReward(Map<String, dynamic> reward) async {
    if (userPoints >= reward['cost']) {
      String userEmail = '';

      bool confirm = await showDialog(
        context: context,
        builder: (context) {
          TextEditingController emailController = TextEditingController();
          return AlertDialog(
            title: Text('Confirm Redemption'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Redeem ${reward['name']} for ${reward['cost']} points?'),
                SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'Your Email (required)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  userEmail = emailController.text;
                  Navigator.of(context).pop(true);
                },
                child: Text('Confirm'),
              ),
            ],
          );
        },
      );

      if (confirm == true && userEmail.isNotEmpty) {
        // Deduct points
        setState(() {
          userPoints -= (reward['cost'] as num).toInt();
        });
        await _database.child('plant1/points').set(userPoints);

        // Log redemption info
        await _database.child('redemptions').push().set({
          'reward': reward['name'],
          'cost': reward['cost'],
          'userEmail': userEmail,
          'timestamp': DateTime.now().toIso8601String(),
        });

        // Call backend/email service here (example below)
        print("Send email: User redeemed ${reward['name']} - contact: $userEmail");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reward redeemed! An administrator will contact you shortly.')),
        );
      } else if (userEmail.isEmpty && confirm == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter an email address to redeem.')),
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
                        onPressed: () => _redeemReward(reward),
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
