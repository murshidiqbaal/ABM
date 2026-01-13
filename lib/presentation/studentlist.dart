// ignore_for_file: unused_element

import 'package:_abm/constants/mytextfield.dart';
import 'package:_abm/utils/share_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/student_data.dart';
import '../dbmodels/models.dart';
import '../services/database_service.dart';

class StudentListScreen extends StatefulWidget {
  final Collection collection;

  const StudentListScreen({
    super.key,
    required this.collection,
    required String title,
    required String amount,
    required List<Student> studentsWithLessThanAmount,
  });

  @override
  // ignore: library_private_types_in_public_api
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  // State for search and UI
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _balanceController = TextEditingController();
  bool _isSearching = false;

  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    // No local calculation needed, StreamBuilder handles it
  }

  // Helper to calculate totals from a list of students
  Map<String, int> _calculateTotals(
      List<Student> students, String currentAmount) {
    int total = 0;
    int count = 0;
    int surplus = 0; // + value
    int deficit = 0; // - value

    int amountModel = int.tryParse(currentAmount) ?? 0;

    for (var student in students) {
      if (student.isSelected) {
        double paidAmount = student.balance ?? amountModel.toDouble();

        // Use amountModel (Expectation) for Total, so deficits don't reduce it.
        total += amountModel;

        int diff = (paidAmount - amountModel).toInt();

        if (diff > 0) {
          surplus += diff;
        } else if (diff < 0) {
          deficit += diff.abs();
        }
        count++;
      }
    }
    return {
      'totalSum': total,
      'surplus': surplus,
      'deficit': deficit,
      'selectedCount': count,
    };
  }

  void _toggleSelection(Student student) {
    // Optimistic Update
    setState(() {
      final newSelected = !student.isSelected;
      student.isSelected = newSelected;

      // Logic from original: if deselected, clear payment info
      if (!newSelected) {
        student.paymentMethod = '';
        student.balance = null;
      } else {
        // Fix: Reset balance to null (Full Payment) when selected
        // This prevents immediate negative value increment.
        student.balance = null;
      }
    });

    // Update in Supabase
    _databaseService.updateStudent(student).then((_) {
      // Optional: Show payment dialog if selected
      if (student.isSelected) {
        _showPaymentDialog(student);
      }
    });
  }

  Future<void> _deleteStudent(Student student) async {
    if (student.id != null) {
      await _databaseService.deleteStudent(student.id!);
      setState(() {});
    }
  }

  void _showAddStudentsDialog() {
    Set<String> selectedNewStudents = {};
    String dialogSearchQuery = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          final filteredMasterList = masterStudentList
              .where((name) =>
                  name.toLowerCase().contains(dialogSearchQuery.toLowerCase()))
              .toList();

          return AlertDialog(
            title: const Text('Add Students'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) {
                      setState(() {
                        dialogSearchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredMasterList.length,
                      itemBuilder: (context, index) {
                        final name = filteredMasterList[index];
                        final isSelected = selectedNewStudents.contains(name);
                        return CheckboxListTile(
                          title: Text(name),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selectedNewStudents.add(name);
                              } else {
                                selectedNewStudents.remove(name);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedNewStudents.isNotEmpty &&
                      widget.collection.id != null) {
                    final newStudents = selectedNewStudents.map((name) {
                      return Student(
                        name: name,
                        isSelected: false,
                        studentsWithLessThanAmount: [],
                        balance: 0.0,
                        paymentMethod: '',
                      );
                    }).toList();

                    await _databaseService.addStudents(
                        widget.collection.id!, newStudents);
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Added ${newStudents.length} students to list')),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showPaymentDialog(Student student) {
    _balanceController.text = student.balance?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) {
        int? selector;
        // Pre-fill selector based on current method
        if (student.paymentMethod == 'GPay') selector = 1;
        if (student.paymentMethod == 'Liquid') selector = 2;

        return StatefulBuilder(// Use StatefulBuilder to update dialog state
            builder: (context, setDialogState) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('GPay'),
                  trailing: selector == 1
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    setDialogState(() {
                      selector = 1;
                    });
                  },
                ),
                ListTile(
                  title: const Text('Liquid'),
                  trailing: selector == 2
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () {
                    setDialogState(() {
                      selector = 2;
                    });
                  },
                ),
                MyTextField(
                  HintText: 'Type amount',
                  Controller: _balanceController,
                  LabelText: const Text('Correption'),
                  ObscureText: false,
                  KeyBoardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Update Student object properties
                  student.balance = double.tryParse(_balanceController.text);

                  if (selector == 1) {
                    student.paymentMethod = 'GPay';
                  } else if (selector == 2) {
                    student.paymentMethod = 'Liquid';
                  }

                  _databaseService.updateStudent(student);

                  _balanceController.clear();
                  Navigator.pop(context);

                  // Optimistic UI Update AFTER dialog closes
                  setState(() {});
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _deleteCollection(int id) async {
    try {
      await _databaseService.deleteCollection(id);
      if (mounted) {
        Navigator.pop(context); // Leave screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('List deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting list: $e')),
        );
      }
    }
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

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Collection?>(
        stream: _databaseService
            .getCollectionStream(widget.collection.id!)
            .handleError((_) => null),
        builder: (context, colSnapshot) {
          if (colSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          final currentCollection = colSnapshot.data;

          if (currentCollection == null) {
            return const Scaffold(
                body: Center(child: Text("List not found or deleted.")));
          }

          return StreamBuilder<List<Student>>(
              stream: _databaseService.getStudentsStream(currentCollection.id!),
              builder: (context, snapshot) {
                List<Student> allStudents = [];
                List<Student> filteredStudents = [];

                if (snapshot.hasData) {
                  allStudents = snapshot.data!;
                  if (_searchController.text.isNotEmpty) {
                    filteredStudents = allStudents
                        .where((student) => student.name
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase()))
                        .toList();
                  } else {
                    filteredStudents = allStudents;
                  }
                }

                final totals =
                    _calculateTotals(allStudents, currentCollection.amount);

                final exportCollection = Collection(
                    title: currentCollection.title,
                    amount: currentCollection.amount,
                    studentList: allStudents,
                    id: currentCollection.id);

                return Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  appBar: AppBar(
                    backgroundColor:
                        Theme.of(context).appBarTheme.backgroundColor,
                    title: _isSearching
                        ? TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search here...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface),
                            onChanged: (query) {
                              setState(() {}); // Trigger rebuild to filter
                            },
                            autofocus: true,
                          )
                        : Text(
                            '${currentCollection.title.toUpperCase()}  ${currentCollection.amount}₹',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _toggleSearch,
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: _showAddStudentsDialog,
                        tooltip: 'Add Students',
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'text') {
                            shareCollectionAsText(exportCollection);
                          } else if (value == 'excel') {
                            generateAndShareExcel(exportCollection);
                          } else if (value == 'copy') {
                            copyCollectionToClipboard(
                                context, exportCollection);
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'text',
                            child: ListTile(
                              leading: Icon(Icons.share, color: Colors.blue),
                              title: Text('Share as Text'),
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'excel',
                            child: ListTile(
                              leading:
                                  Icon(Icons.table_chart, color: Colors.green),
                              title: Text('Export to Excel'),
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'copy',
                            child: ListTile(
                              leading: Icon(Icons.copy, color: Colors.orange),
                              title: Text('Copy to Clipboard'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  body: Column(
                    children: [
                      Expanded(
                        child: snapshot.hasError
                            ? Center(child: Text('Error: ${snapshot.error}'))
                            : (snapshot.connectionState ==
                                    ConnectionState.waiting)
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : filteredStudents.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No student found',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                              fontSize: 18),
                                        ),
                                      )
                                    : RefreshIndicator(
                                        onRefresh: () async {
                                          setState(() {});
                                        },
                                        child: ListView.builder(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          controller: _scrollController,
                                          itemCount: filteredStudents.length,
                                          itemBuilder: (context, index) {
                                            final student =
                                                filteredStudents[index];

                                            return Slidable(
                                              // key: ValueKey(student.id),
                                              endActionPane: ActionPane(
                                                motion: const ScrollMotion(),
                                                children: [
                                                  SlidableAction(
                                                    onPressed: (context) {
                                                      _deleteStudent(student);
                                                    },
                                                    backgroundColor: Colors.red,
                                                    foregroundColor:
                                                        Colors.white,
                                                    icon: Icons.delete,
                                                    label: 'Delete',
                                                  ),
                                                ],
                                              ),
                                              child: ListTile(
                                                title: Row(
                                                  children: [
                                                    Text(
                                                      '${index + 1}.  ',
                                                      style: TextStyle(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .onSurfaceVariant),
                                                    ),
                                                    Text(
                                                      student.name,
                                                      style: GoogleFonts
                                                          .electrolize(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurface),
                                                    ),
                                                  ],
                                                ),
                                                subtitle: student.paymentMethod
                                                        .isNotEmpty
                                                    ? Row(
                                                        children: [
                                                          Text(
                                                            'Payment: ${student.paymentMethod}  ',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  student.paymentMethod ==
                                                                          'GPay'
                                                                      ? Colors
                                                                          .green
                                                                      : Colors
                                                                          .blue,
                                                            ),
                                                          ),
                                                          if (student
                                                              .paymentMethod
                                                              .isNotEmpty)
                                                            Builder(builder:
                                                                (context) {
                                                              // Logic: Treat null balance as Full Payment (Expected Amount)
                                                              double expected =
                                                                  double.tryParse(
                                                                          currentCollection
                                                                              .amount) ??
                                                                      0.0;
                                                              double paid =
                                                                  student.balance ??
                                                                      expected;

                                                              int diff = (paid -
                                                                      expected)
                                                                  .toInt();

                                                              // Only show difference if there IS a difference
                                                              if (diff == 0) {
                                                                return const SizedBox
                                                                    .shrink();
                                                              }

                                                              return Text(
                                                                diff > 0
                                                                    ? '+$diff'
                                                                    : '$diff',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 14,
                                                                  color: diff >
                                                                          0
                                                                      ? Colors
                                                                          .green
                                                                      : Colors
                                                                          .red,
                                                                ),
                                                              );
                                                            }),
                                                        ],
                                                      )
                                                    : null,
                                                trailing: Checkbox(
                                                  value: student.isSelected,
                                                  onChanged: (bool? value) {
                                                    _toggleSelection(student);
                                                  },
                                                  fillColor: WidgetStateProperty
                                                      .resolveWith((states) {
                                                    if (states.contains(
                                                        WidgetState.selected)) {
                                                      return Colors.blueAccent;
                                                    }
                                                    return Colors.grey;
                                                  }),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: BottomAppBar(
                    color: Theme.of(context).appBarTheme.backgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total (${totals['selectedCount']}) :',
                            style: TextStyle(
                                fontSize: 20,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color),
                          ),
                          Row(
                            children: [
                              if ((totals['surplus'] ?? 0) > 0)
                                Text(
                                  '+${totals['surplus']} ',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if ((totals['deficit'] ?? 0) > 0)
                                Text(
                                  '-${totals['deficit']} ',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              Text(
                                ' ₹${totals['totalSum']}',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              });
        });
  }
}
