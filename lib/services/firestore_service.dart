import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _exchangeApiKey = 'a96282a4b234811e0af5a867';
  final String _exchangeApiBaseUrl = 'https://v6.exchangerate-api.com/v6/';
  String? get currentUserId => _auth.currentUser?.uid;
  Future<void> createUserProfile(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName ?? user.email?.split('@')[0] ?? 'User',
      'preferredCurrency': 'USD',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePreferredCurrency(String currency) async {
    if (currentUserId == null) {
      return;
    }
    await _firestore.collection('users').doc(currentUserId).update({
      'preferredCurrency': currency,
    });
  }

  Future<String> getPreferredCurrency() async {
    if (currentUserId == null) {
      return 'USD';
    }
    final doc = await _firestore.collection('users').doc(currentUserId).get();
    return doc.data()?['preferredCurrency'] ?? 'USD';
  }

  Future<void> addTransaction({
    required String type,
    required double amount,
    required String currency,
    required String category,
    required String description,
    required DateTime date,
  }) async {
    print(
      "addTransaction called with: Type: $type, Amount: $amount, Currency: $currency, Category: $category, Description: $description",
    );
    if (currentUserId == null) {
      print("Error: currentUserId is null");
      return;
    }
    try {
      print("Adding transaction to Firestore...");
      await _firestore.collection('transactions').add({
        'userId': currentUserId,
        'type': type,
        'amount': amount,
        'currency': currency,
        'category': category,
        'description': description,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Transaction added to Firestore successfully");
    } catch (e) {
      print("Error in Firestore add operation: $e");
      throw e;
    }
  }

  Future<void> updateTransaction({
    required String id,
    required String type,
    required double amount,
    required String currency,
    required String category,
    required String description,
    required DateTime date,
  }) async {
    await _firestore.collection('transactions').doc(id).update({
      'type': type,
      'amount': amount,
      'currency': currency,
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTransaction(String id) async {
    await _firestore.collection('transactions').doc(id).delete();
  }

  Stream<QuerySnapshot> getTransactions() {
    if (currentUserId == null) {
      return Stream.empty();
    }
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: currentUserId)
        .snapshots();
  }

  Future<Map<String, dynamic>> getExchangeRate(String baseCurrency) async {
    final url = '$_exchangeApiBaseUrl$_exchangeApiKey/latest/$baseCurrency';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['conversion_rates'];
    } else {
      throw Exception('Failed to load exchange rates');
    }
  }

  Future<double> convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency == toCurrency) {
      return amount;
    }
    final rates = await getExchangeRate(fromCurrency);
    final rate = rates[toCurrency];
    if (rate == null) {
      throw Exception('Exchange rate not found for $toCurrency');
    }
    return amount * rate;
  }
}
