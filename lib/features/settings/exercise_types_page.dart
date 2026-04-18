import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseCategory {
  final String id;
  final String name;
  final String imagePath;
  final Color color;

  const ExerciseCategory({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.color,
  });
}

const _defaultCategories = [
  ExerciseCategory(
    id: 'running',
    name: 'Running',
    imagePath: 'assets/images/exercises/running.jpg',
    color: Colors.blue,
  ),
  ExerciseCategory(
    id: 'strength',
    name: 'Strength',
    imagePath: 'assets/images/exercises/strength.jpg',
    color: Colors.red,
  ),
  ExerciseCategory(
    id: 'cardio',
    name: 'Cardio',
    imagePath: 'assets/images/exercises/cardio.jpg',
    color: Colors.orange,
  ),
  ExerciseCategory(
    id: 'stretching',
    name: 'Stretching',
    imagePath: 'assets/images/exercises/stretching.jpg',
    color: Colors.purple,
  ),
];

class ExerciseTypesPage extends StatefulWidget {
  const ExerciseTypesPage({super.key});

  @override
  State<ExerciseTypesPage> createState() => _ExerciseTypesPageState();
}

class _ExerciseTypesPageState extends State<ExerciseTypesPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Types'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(),
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text('Please sign in to manage exercises'))
          : StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(userId)
            .collection('exercises')
            .orderBy('name')
            .snapshots()
            .handleError((_) => <QuerySnapshot>[]),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildCategoriesOnly();
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final customExercises = snapshot.data?.docs ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: _defaultCategories.map((cat) => _buildCategoryCard(cat)).toList(),
              ),
              if (customExercises.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Custom Exercises',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...customExercises.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: Text(data['name'] ?? 'Unknown'),
                    subtitle: Text(data['category'] ?? 'No category'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _delete(doc.id),
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoriesOnly() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Categories',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: _defaultCategories.map((cat) => _buildCategoryCard(cat)).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(ExerciseCategory category) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            category.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: category.color.withValues(alpha: 0.3),
              child: Icon(Icons.fitness_center, size: 48, color: category.color),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    String category = 'strength';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: category,
              items: const [
                DropdownMenuItem(value: 'running', child: Text('Running')),
                DropdownMenuItem(value: 'strength', child: Text('Strength')),
                DropdownMenuItem(value: 'cardio', child: Text('Cardio')),
                DropdownMenuItem(value: 'stretching', child: Text('Stretching')),
              ],
              onChanged: (v) => category = v ?? 'strength',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.isEmpty) return;
              final name = controller.text;
              Navigator.pop(context);
              _firestore.collection('users').doc(_auth.currentUser?.uid).collection('exercises').add({
                'name': name,
                'category': category,
                'createdAt': FieldValue.serverTimestamp(),
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(String id) async {
    await _firestore.collection('users').doc(_auth.currentUser?.uid).collection('exercises').doc(id).delete();
  }
}
