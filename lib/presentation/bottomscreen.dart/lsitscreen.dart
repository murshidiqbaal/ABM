import 'package:_abm/presentation/mydrawer.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:slide_to_act/slide_to_act.dart';

import '../../constants/mytextfield.dart';
import '../../constants/student_data.dart';
import '../../dbmodels/models.dart';
import '../../services/database_service.dart';
import '../create_list_screen.dart';
import '../studentlist.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  void _addItem(String name, String amount) async {
    final List<Student> students = masterStudentList
        .map((studentName) => Student(
              name: studentName,
              isSelected: false,
              studentsWithLessThanAmount: [],
              balance: 0.0,
              paymentMethod: '',
            ))
        .toList();

    await _databaseService.addCollection(name, amount, students);
    setState(() {});
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Collection'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            MyTextField(
              HintText: 'Enter title',
              Controller: _titleController,
              LabelText: const Text('Title'),
              ObscureText: false,
              KeyBoardType: TextInputType.text,
            ),
            const SizedBox(height: 10),
            MyTextField(
              HintText: 'Enter amount',
              Controller: _amountController,
              LabelText: const Text('Amount'),
              ObscureText: false,
              KeyBoardType: TextInputType.number,
            ),
          ]),
          actions: [
            SlideAction(
              text: 'Slide to create',
              textStyle: const TextStyle(color: Colors.white, fontSize: 16),
              innerColor: Colors.purple,
              outerColor: Colors.purple.shade300,
              sliderButtonIcon: const Icon(Icons.create),
              onSubmit: () {
                if (_titleController.text.isNotEmpty &&
                    _amountController.text.isNotEmpty) {
                  _addItem(_titleController.text, _amountController.text);
                  _titleController.clear();
                  _amountController.clear();
                  Navigator.of(context).pop();
                }
                return null;
              },
              animationDuration: const Duration(milliseconds: 800),
            ),
          ],
        );
      },
    );
  }

  void _shareCollection(Collection collection) {
    String text =
        '*Collection:* ${collection.title}\n*Amount:* ${collection.amount}\n(Open collection to view details)';
    Share.share(text, subject: 'Collection Report');
  }

  Future<void> _confirmDelete(Collection collection) async {
    if (collection.id == null) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${collection.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _databaseService.deleteCollection(collection.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _editCollection(Collection collection) async {
    final TextEditingController titleController =
        TextEditingController(text: collection.title);
    final TextEditingController amountController =
        TextEditingController(text: collection.amount);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'List Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                try {
                  await _databaseService.updateCollection(
                    collection.id!,
                    titleController.text,
                    amountController.text.isEmpty ? '0' : amountController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('List updated successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating list: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Center(
          child: AvatarGlow(
            duration: const Duration(seconds: 2),
            glowColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.blueAccent
                : const Color.fromARGB(255, 224, 207, 50),
            child: Text(
              'A B M',
              style: GoogleFonts.anaheim(
                  color: Theme.of(context).appBarTheme.titleTextStyle?.color ??
                      Colors.black87),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Collection>>(
              stream: _databaseService.getCollectionsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final collections = snapshot.data ?? [];

                if (collections.isEmpty) {
                  return const Center(child: Text('No collections added.'));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.separated(
                    separatorBuilder: (context, index) => const SizedBox(),
                    itemCount: collections.length,
                    itemBuilder: (context, index) {
                      final collection = collections[index];

                      return Slidable(
                        startActionPane: ActionPane(
                          motion: const StretchMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                _editCollection(collection);
                              },
                              backgroundColor: Colors.blueAccent,
                              icon: Icons.edit_note_rounded,
                              label: 'Edit',
                            ),
                          ],
                        ),
                        endActionPane: ActionPane(
                          motion: const StretchMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                _shareCollection(collection);
                              },
                              backgroundColor: Colors.blue,
                              icon: Icons.share,
                            ),
                            SlidableAction(
                              onPressed: ((context) {
                                _confirmDelete(collection);
                              }),
                              backgroundColor: Colors.red,
                              icon: Icons.delete,
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Theme.of(context).cardColor,
                            ),
                            child: ListTile(
                              textColor: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              trailing: Text(
                                '₹${collection.amount}',
                                style: GoogleFonts.poppins(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                              ),
                              title: Text(
                                collection.title,
                                style: GoogleFonts.bodoniModa(
                                    fontSize: 24,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                              ),
                              subtitle: StreamBuilder<Map<String, int>>(
                                stream: _databaseService
                                    .getCollectionStatsStream(collection.id!),
                                builder: (context, statsSnapshot) {
                                  if (statsSnapshot.hasData) {
                                    final total = statsSnapshot.data!['total'];
                                    final paid = statsSnapshot.data!['paid'];
                                    return Text(
                                      '$paid/$total Paid',
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: statsSnapshot.hasData
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant),
                                    );
                                  }
                                  return Text(
                                    'Loading...',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                                  );
                                },
                              ),
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => StudentListScreen(
                                    collection: collection,
                                    title: collection.title,
                                    amount: collection.amount,
                                    studentsWithLessThanAmount: [],
                                  ),
                                ));
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (Theme.of(context).brightness == Brightness.dark) {
            // Dark Theme: New Custom List Creation
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreateListScreen()));
          } else {
            // Light Theme: Old Add Item Dialog (Slide to Create)
            _showAddItemDialog();
          }
        },
        label: const Text('Create List'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
