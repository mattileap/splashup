import 'package:flutter/material.dart';

void main() {
  runApp(const SplashUpApp());
}

class SplashUpApp extends StatelessWidget {
  const SplashUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplashUp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
      home: const TeamsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  // This is a placeholder list. We will replace this with data from Firebase.
  final List<String> _teams = [
    "Varsity Boys",
    "Junior Dolphins",
    "Morning Masters"
  ];

  void _addTeam() {
    // This is where we will open a dialog to add a new team.
    // For now, it just prints a message to the debug console.
    print("Add Team button pressed!");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController teamNameController = TextEditingController();
        return AlertDialog(
          title: const Text('Add New Team'),
          content: TextField(
            controller: teamNameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Team Name',
              hintText: 'e.g., Varsity Girls',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
              onPressed: () {
                // TODO: Add logic to save the team to Firebase
                final newTeamName = teamNameController.text;
                if (newTeamName.isNotEmpty) {
                  print("New Team: $newTeamName");
                  // For now, we just add to the local list to see the UI update.
                  setState(() {
                    _teams.add(newTeamName);
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
      ),
      body: _teams.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_add_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No teams yet.',
                    style: TextStyle(fontSize: 22, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first team!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _teams.length,
              itemBuilder: (context, index) {
                final teamName = _teams[index];
                return Card(
                  elevation: 2.0,
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(Icons.group_work, color: Colors.blue),
                    ),
                    title: Text(
                      teamName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // TODO: Navigate to the list of athletes for this team.
                      print("$teamName tapped!");
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTeam,
        tooltip: 'Add Team',
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
