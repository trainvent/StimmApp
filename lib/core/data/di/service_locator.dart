import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:stimmapp/core/data/services/auth_service.dart' as auth_service;
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/data/services/storage_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  FirebaseFirestore? _database;
  DatabaseService? _databaseService;
  StorageService? _storageService;
  FirebaseAuth? _auth;
  auth_service.AuthService? _authService;

  void init() {
    final app = Firebase.app();
    final database = FirebaseFirestore.instanceFor(app: app);
    final auth = FirebaseAuth.instanceFor(app: app);
    _database = database;
    _databaseService = DatabaseService(database);
    _auth = auth;
    // Create a new instance directly, avoiding the global variable conflict
    _authService = auth_service.AuthService();
    _storageService = StorageService(FirebaseStorage.instanceFor(app: app));
  }

  FirebaseFirestore get database =>
      _database ?? (throw StateError('ServiceLocator.database not initialized'));
  DatabaseService get databaseService => _databaseService ??
      (throw StateError('ServiceLocator.databaseService not initialized'));
  FirebaseAuth get auth =>
      _auth ?? (throw StateError('ServiceLocator.auth not initialized'));
  auth_service.AuthService get authService =>
      _authService ?? auth_service.authService;
  StorageService get storageService => _storageService ??
      (throw StateError('ServiceLocator.storageService not initialized'));

  @visibleForTesting
  void setDatabaseForTest(FirebaseFirestore database) {
    _database = database;
    _databaseService = DatabaseService(database);
  }

  @visibleForTesting
  void setStorageForTest(FirebaseStorage storage) {
    _storageService = StorageService(storage);
  }

  @visibleForTesting
  void setAuthServiceForTest(auth_service.AuthService authService) {
    _authService = authService;
  }
}

final locator = ServiceLocator();
