import 'package:supabase_flutter/supabase_flutter.dart';

import '../dbmodels/models.dart';

class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final String _collectionsTable = 'collections';
  final String _studentsTable = 'students';

  // --- Collections ---

  /// Fetch all collections ordered by creation time (descending)
  Stream<List<Collection>> getCollectionsStream() {
    return _client
        .from(_collectionsTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((maps) => maps.map((map) => Collection.fromJson(map)).toList());
  }

  /// Add a new collection and its initial list of students
  Future<void> addCollection(
      String title, String amount, List<Student> students) async {
    // 1. Insert Collection
    final collectionResponse = await _client
        .from(_collectionsTable)
        .insert({
          'title': title,
          'amount': amount,
        })
        .select()
        .single();

    final newCollectionId = collectionResponse['id'] as int;

    // 2. Prepare Students with the new collection_id
    final studentsData = students.map((student) {
      final json = student.toJson();
      json['collection_id'] = newCollectionId;
      return json;
    }).toList();

    // 3. Insert Students
    await _client.from(_studentsTable).insert(studentsData);
  }

  /// Delete a collection (Cascade delete should handle students if configured in DB)
  /// Otherwise, we manually delete students first.
  Future<void> deleteCollection(int id) async {
    await _client.from(_collectionsTable).delete().eq('id', id);
  }

  /// Update an existing collection
  Future<void> updateCollection(int id, String title, String amount) async {
    await _client.from(_collectionsTable).update({
      'title': title,
      'amount': amount,
    }).eq('id', id);
  }

  // --- Students ---

  /// Fetch students for a specific collection
  Stream<List<Student>> getStudentsStream(int collectionId) {
    return _client
        .from(_studentsTable)
        .stream(primaryKey: ['id'])
        .eq('collection_id', collectionId)
        .order('id',
            ascending:
                true) // Maintain order if implied by insertion, or add an index field
        .map((maps) => maps.map((map) => Student.fromJson(map)).toList());
  }

  /// Get counts (Total, Paid) for a collection
  Stream<Map<String, int>> getCollectionStatsStream(int collectionId) {
    return _client
        .from(_studentsTable)
        .stream(primaryKey: ['id'])
        .eq('collection_id', collectionId)
        .map((maps) {
          final total = maps.length;
          final paid = maps.where((map) => map['is_selected'] == true).length;
          return {'total': total, 'paid': paid};
        });
  }

  /// Update a student's selection, payment, or balance
  Future<void> updateStudent(Student student) async {
    if (student.id == null) return;
    await _client.from(_studentsTable).update({
      'is_selected': student.isSelected,
      'payment_method': student.paymentMethod,
      'balance': student.balance,
      // 'name': student.name, // If names are editable
    }).eq('id', student.id!);
  }

  /// Delete a student from a collection
  Future<void> deleteStudent(int studentId) async {
    await _client.from(_studentsTable).delete().eq('id', studentId);
  }

  /// Add new students to an existing collection
  Future<void> addStudents(int collectionId, List<Student> students) async {
    final studentsData = students.map((student) {
      final json = student.toJson();
      json['collection_id'] = collectionId;
      return json;
    }).toList();
    await _client.from(_studentsTable).insert(studentsData);
  }
}
