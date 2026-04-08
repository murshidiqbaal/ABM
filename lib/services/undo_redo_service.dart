import 'package:_abm/dbmodels/models.dart';
import 'package:_abm/services/database_service.dart';
import 'package:flutter/material.dart';

// Abstract Command class
abstract class Command {
  String get name;
  Future<void> execute();
  Future<void> undo();
}

class ToggleStudentSelectionCommand extends Command {
  final Student student;
  final DatabaseService service;
  // Snapshots
  final bool oldIsSelected;
  final double? oldBalance;
  final String oldPaymentMethod;
  final bool newIsSelected;

  ToggleStudentSelectionCommand(this.student, this.service)
      : oldIsSelected = student.isSelected,
        oldBalance = student.balance,
        oldPaymentMethod = student.paymentMethod,
        newIsSelected = !student.isSelected;

  @override
  String get name => newIsSelected ? 'Mark Student' : 'Unmark Student';

  @override
  Future<void> execute() async {
    // We assume the student object is modified in memory by the caller for optimistic UI
    // But here we enforce the DB update
    student.isSelected = newIsSelected;
    if (!newIsSelected) {
      student.paymentMethod = '';
      student.balance = null;
    } else {
      // Logic from StudentListScreen
      student.balance = null;
    }
    await service.updateStudent(student);
  }

  @override
  Future<void> undo() async {
    student.isSelected = oldIsSelected;
    student.balance = oldBalance;
    student.paymentMethod = oldPaymentMethod;
    await service.updateStudent(student);
  }
}

class DeleteStudentCommand extends Command {
  final Student student;
  final int collectionId;
  final DatabaseService service;
  // We need to store everything to restore it
  late final Student _backup;

  DeleteStudentCommand(this.student, this.collectionId, this.service) {
    _backup = Student(
        name: student.name,
        isSelected: student.isSelected,
        studentsWithLessThanAmount: student.studentsWithLessThanAmount,
        balance: student.balance,
        paymentMethod: student.paymentMethod,
        collectionId: student.collectionId,
        id: null // ID will be new on restore
        );
  }

  @override
  String get name => 'Delete Student';

  @override
  Future<void> execute() async {
    if (student.id != null) {
      await service.deleteStudent(student.id!);
    }
  }

  @override
  Future<void> undo() async {
    await service.addStudents(collectionId, [_backup]);
  }
}

class UpdateStudentPaymentCommand extends Command {
  final Student student;
  final DatabaseService service;
  final double? oldBalance;
  final String oldPaymentMethod;
  final double? newBalance;
  final String newPaymentMethod;

  UpdateStudentPaymentCommand({
    required this.student,
    required this.service,
    required this.oldBalance,
    required this.oldPaymentMethod,
    required this.newBalance,
    required this.newPaymentMethod,
  });

  @override
  String get name => 'Update Payment';

  @override
  Future<void> execute() async {
    student.balance = newBalance;
    student.paymentMethod = newPaymentMethod;
    await service.updateStudent(student);
  }

  @override
  Future<void> undo() async {
    student.balance = oldBalance;
    student.paymentMethod = oldPaymentMethod;
    await service.updateStudent(student);
  }
}

class DeleteCollectionCommand extends Command {
  final Collection collection;
  final DatabaseService service;
  List<Student> _studentBackup = [];

  DeleteCollectionCommand(this.collection, this.service);

  // Must call this before execute to ensure we have data
  Future<void> prepare() async {
    if (collection.id != null) {
      try {
        final students = await service.getStudentsStream(collection.id!).first;
        _studentBackup = students;
      } catch (e) {
        debugPrint("Error backing up students: $e");
      }
    }
  }

  @override
  String get name => 'Delete List';

  @override
  Future<void> execute() async {
    if (collection.id != null) {
      await service.deleteCollection(collection.id!);
    }
  }

  @override
  Future<void> undo() async {
    await service.addCollection(
        collection.title, collection.amount, _studentBackup);
  }
}

// Global Manager
class UndoRedoManager extends ChangeNotifier {
  static final UndoRedoManager _instance = UndoRedoManager._internal();
  factory UndoRedoManager() => _instance;
  UndoRedoManager._internal();

  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void addCommand(Command command) {
    _undoStack.add(command);
    _redoStack.clear();
    notifyListeners();
  }

  Future<void> undo() async {
    if (!canUndo) return;
    final command = _undoStack.removeLast();
    await command.undo();
    _redoStack.add(command);
    notifyListeners();
  }

  Future<void> redo() async {
    if (!canRedo) return;
    final command = _redoStack.removeLast();
    await command.execute();
    _undoStack.add(command);
    notifyListeners();
  }
}
