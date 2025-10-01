// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get Firestore instance
  FirebaseFirestore get db => _db;

  // Generic collection reference
  CollectionReference collection(String path) => _db.collection(path);

  // Generic document reference
  DocumentReference doc(String path) => _db.doc(path);

  // Batch write
  WriteBatch batch() => _db.batch();

  // Transaction
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
  }) =>
      _db.runTransaction(transactionHandler, timeout: timeout);
}










