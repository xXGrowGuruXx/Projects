import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class MongoDBService {
  static const String _connectionString = 
      'mongodb+srv://xXGrowGuruXx:Accamea&Ria2019@dataset.3ovfuh4.mongodb.net/?appName=Dataset';
  static const String _databaseName = 'imker_tagebuch';
  static const String _usersCollection = 'users';
  
  Db? _db;
  DbCollection? _users;
  bool _isConnected = false;
  
  bool get isConnected => _isConnected;
  
  Future<void> connect() async {
    if (_isConnected) return;
    
    try {
      _db = await Db.create(_connectionString);
      await _db!.open();
      _users = _db!.collection(_usersCollection);
      _isConnected = true;
      debugPrint('MongoDB connected successfully');
    } catch (e) {
      debugPrint('MongoDB connection error: $e');
      _isConnected = false;
    }
  }
  
  Future<void> disconnect() async {
    if (_db != null && _isConnected) {
      await _db!.close();
      _isConnected = false;
      debugPrint('MongoDB disconnected');
    }
  }
  
  Future<UserModel?> getUser(String userId) async {
    if (!_isConnected) await connect();
    
    try {
      final userData = await _users!.findOne(where.eq('id', userId));
      if (userData != null) {
        return UserModel.fromMap(userData);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }
  
  Future<void> saveUser(UserModel user) async {
    if (!_isConnected) await connect();
    
    try {
      final existingUser = await _users!.findOne(where.eq('id', user.id));
      
      if (existingUser != null) {
        // Update existing user
        await _users!.update(
          where.eq('id', user.id),
          user.toMap(),
        );
      } else {
        // Insert new user
        await _users!.insert(user.toMap());
      }
      
      debugPrint('User saved successfully: ${user.email}');
    } catch (e) {
      debugPrint('Error saving user: $e');
    }
  }
  
  Future<void> updateUserRole(String userId, String newRole) async {
    if (!_isConnected) await connect();
    
    try {
      await _users!.update(
        where.eq('id', userId),
        modify.set('role', newRole),
      );
      debugPrint('User role updated to: $newRole');
    } catch (e) {
      debugPrint('Error updating user role: $e');
    }
  }
  
  Future<void> updateCloudBackup(String userId, bool enabled) async {
    if (!_isConnected) await connect();
    
    try {
      await _users!.update(
        where.eq('id', userId),
        modify.set('cloudBackupEnabled', enabled),
      );
      debugPrint('Cloud backup updated: $enabled');
    } catch (e) {
      debugPrint('Error updating cloud backup: $e');
    }
  }
  
  Future<void> deleteUser(String userId) async {
    if (!_isConnected) await connect();
    
    try {
      await _users!.remove(where.eq('id', userId));
      debugPrint('User deleted successfully');
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
  }
  
  Future<void> updateLastLogin(String userId) async {
    if (!_isConnected) await connect();
    
    try {
      await _users!.update(
        where.eq('id', userId),
        modify.set('lastLogin', DateTime.now().toIso8601String()),
      );
    } catch (e) {
      debugPrint('Error updating last login: $e');
    }
  }
  
  Future<List<UserModel>> getAllUsers() async {
    if (!_isConnected) await connect();
    
    try {
      final usersData = await _users!.find().toList();
      return usersData.map((data) => UserModel.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }
}
