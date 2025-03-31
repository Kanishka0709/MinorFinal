import 'package:flutter/material.dart';

class VolunteerRescuesPage extends StatelessWidget {
  const VolunteerRescuesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rescues'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: 10, // Placeholder count
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.pets, color: Colors.white),
              ),
              title: Text('Rescue #${index + 1}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${DateTime.now().subtract(Duration(days: index)).toString().split(' ')[0]}'),
                  const Text('Status: Completed'),
                  const Text('Location: Sample Address'),
                ],
              ),
              isThreeLine: true,
              trailing: Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
              onTap: () {
                // TODO: Show rescue details
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new rescue
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
} 