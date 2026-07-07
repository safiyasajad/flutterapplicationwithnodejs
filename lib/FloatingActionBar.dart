import 'package:flutter/material.dart';
import 'package:flutterapplicationwithnodejs/dashboard.dart';

class Floatingactionbar extends StatelessWidget {
  const Floatingactionbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('Order History'),
),
      //floating action button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your action here
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.black, // Set the background color of the FAB
        foregroundColor: Colors.white, // Set the icon color of the FAB
        // elevation: 6.0, // Set the elevation of the FAB
        shape: const CircleBorder(), // Set the shape of the FAB
     ),


      //bottom navigation bar
      bottomNavigationBar: BottomAppBar(
        notchMargin: 6.0,
        shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            Expanded(
              child: IconButton(
                iconSize: 32,
                icon: const Icon(Icons.restaurant_menu),
                onPressed: () {Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Floatingactionbar(),
                    ),
                  );
                },
              ),
            ),

            const VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 10,
              endIndent: 10,
            ),

            Expanded(
              child: IconButton(
                iconSize: 32,
                icon: const Icon(Icons.home),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Dashboard(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}