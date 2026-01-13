import 'package:_abm/constants/mytextfield.dart';
import 'package:_abm/constants/student_data.dart';
import 'package:_abm/dbmodels/models.dart';
import 'package:_abm/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateListScreen extends StatefulWidget {
  const CreateListScreen({super.key});

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final Set<String> _selectedNames = {};
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  String _searchQuery = '';

  List<String> get _filteredStudents {
    if (_searchQuery.isEmpty) {
      return masterStudentList;
    }
    return masterStudentList
        .where(
            (name) => name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _toggleSelection(String name) {
    setState(() {
      if (_selectedNames.contains(name)) {
        _selectedNames.remove(name);
      } else {
        _selectedNames.add(name);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedNames.length == _filteredStudents.length) {
        _selectedNames.clear();
      } else {
        _selectedNames.addAll(_filteredStudents);
      }
    });
  }

  void _showSaveDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Custom List'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyTextField(
                HintText: 'List Name (e.g. Picnic, Exam)',
                Controller: titleController,
                LabelText: const Text('List Name'),
                ObscureText: false,
                KeyBoardType: TextInputType.text,
              ),
              const SizedBox(height: 10),
              MyTextField(
                HintText: 'Amount per Student (Optional)',
                Controller: amountController,
                LabelText: const Text('Amount (₹)'),
                ObscureText: false,
                KeyBoardType: TextInputType.number,
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
                  final String amount = amountController.text.isEmpty
                      ? '0'
                      : amountController.text;

                  // Create Student objects
                  final List<Student> students = _selectedNames.map((name) {
                    return Student(
                      name: name,
                      isSelected: false,
                      studentsWithLessThanAmount: [], // Empty init
                      balance: 0.0, // Default balance
                      paymentMethod: '',
                    );
                  }).toList();

                  // Save to Supabase (or Hive via this service)
                  await _databaseService.addCollection(
                    titleController.text,
                    amount,
                    students,
                  );

                  if (context.mounted) {
                    Navigator.pop(context); // Close Dialog
                    Navigator.pop(context); // Return to previous screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Custom List Created!')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAllSelected = _filteredStudents.isNotEmpty &&
        _filteredStudents.every((name) => _selectedNames.contains(name));
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Create List (${_selectedNames.length})'),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          TextButton(
            onPressed: _selectAll,
            child: Text(
              isAllSelected ? 'Clear All' : 'Select All',
              style: TextStyle(
                color: isDarkMode
                    ? Colors.white
                    : Colors.black, // Fallback colors if theme fails
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // Student List
          Expanded(
            child: ListView.builder(
              itemCount: _filteredStudents.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final name = _filteredStudents[index];
                final isSelected = _selectedNames.contains(name);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 4.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: isSelected ? 4 : 1,
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Theme.of(context).cardColor,
                    child: ListTile(
                      onTap: () => _toggleSelection(name),
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleSelection(name),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.blueAccent;
                          }
                          return Colors.grey;
                        }),
                      ),
                      title: Text(
                        name,
                        style: GoogleFonts.electrolize(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: Colors.blueAccent)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),

          // Sticky Bottom Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedNames.length} selected',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _selectedNames.isEmpty ? null : _showSaveDialog,
                  icon: const Icon(Icons.save),
                  label: const Text('Create List'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
