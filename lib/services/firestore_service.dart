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
      rethrow;
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

  Future<void> addDebt({
    required String type,
    required double amount,
    required String currency,
    required String debtor,
    required String description,
    required DateTime date,
  }) async {
    print(
      "addDebt called with: Type: $type, Amount: $amount, Currency: $currency, Debtor: $debtor, Description: $description",
    );
    if (currentUserId == null) {
      print("Error: currentUserId is null");
      return;
    }
    try {
      print("Adding debt to Firestore...");
      await _firestore.collection('debts').add({
        'userId': currentUserId,
        'type': type,
        'amount': amount,
        'currency': currency,
        'debtor': debtor,
        'description': description,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Debt added to Firestore successfully");
    } catch (e) {
      print("Error in Firestore add operation: $e");
      rethrow;
    }
  }

  Future<void> updateDebt({
    required String id,
    required String type,
    required double amount,
    required String currency,
    required String debtor,
    required String description,
    required DateTime date,
  }) async {
    await _firestore.collection('debts').doc(id).update({
      'type': type,
      'amount': amount,
      'currency': currency,
      'debtor': debtor,
      'description': description,
      'date': Timestamp.fromDate(date),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDebt(String id) async {
    await _firestore.collection('debts').doc(id).delete();
  }

  Stream<QuerySnapshot> getDebts() {
    if (currentUserId == null) {
      return Stream.empty();
    }
    return _firestore
        .collection('debts')
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

  Stream<QuerySnapshot> getBudgetGoals() {
    if (currentUserId == null) {
      return Stream.empty();
    }
    return _firestore
        .collection('budget_goals')
        .where('userId', isEqualTo: currentUserId)
        .snapshots();
  }

  Future<void> addBudgetGoal({
    required String category,
    required double amount,
    required String currency,
    required String notes,
  }) async {
    print(
      "addBudgetGoal called with: Category: $category, Amount: $amount, Currency: $currency, Notes: $notes",
    );
    if (currentUserId == null) {
      print("Error: currentUserId is null");
      return;
    }
    try {
      final existingBudget =
          await _firestore
              .collection('budget_goals')
              .where('userId', isEqualTo: currentUserId)
              .where('category', isEqualTo: category)
              .get();
      if (existingBudget.docs.isNotEmpty) {
        throw Exception(
          'Budget for $category already exists. Please edit the existing one.',
        );
      }
      print("Adding budget goal to Firestore");
      await _firestore.collection('budget_goals').add({
        'userId': currentUserId,
        'category': category,
        'amount': amount,
        'currency': currency,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Budget goal added to Firestore successfully");
    } catch (e) {
      print("Error in Firestore add operation: $e");
      rethrow;
    }
  }

  Future<void> updateBudgetGoal({
    required String id,
    required String category,
    required double amount,
    required String currency,
    required String notes,
  }) async {
    try {
      await _firestore.collection('budget_goals').doc(id).update({
        'category': category,
        'amount': amount,
        'currency': currency,
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating budget goal: $e");
      rethrow;
    }
  }

  Future<void> deleteBudgetGoal(String id) async {
    try {
      await _firestore.collection('budget_goals').doc(id).delete();
    } catch (e) {
      print("Error deleting budget goal: $e");
      rethrow;
    }
  }

  Future<DocumentSnapshot?> getBudgetGoalByCategory(String category) async {
    if (currentUserId == null) {
      return null;
    }
    try {
      final snapshot =
          await _firestore
              .collection('budget_goals')
              .where('userId', isEqualTo: currentUserId)
              .where('category', isEqualTo: category)
              .get();
      return snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
    } catch (e) {
      print("Error getting budget goal: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllBudgetGoals() async {
    if (currentUserId == null) {
      return [];
    }
    try {
      final snapshot =
          await _firestore
              .collection('budget_goals')
              .where('userId', isEqualTo: currentUserId)
              .get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print("Error getting all budget goals: $e");
      return [];
    }
  }

  Future<double> getTotalBudget(String preferredCurrency) async {
    if (currentUserId == null) {
      return 0.0;
    }
    try {
      final budgetGoals = await getAllBudgetGoals();
      double totalBudget = 0.0;
      for (final budget in budgetGoals) {
        final double amount = budget['amount'] as double;
        final String currency = budget['currency'] as String;
        double convertedAmount = amount;
        if (currency != preferredCurrency) {
          try {
            convertedAmount = await convertCurrency(
              amount,
              currency,
              preferredCurrency,
            );
          } catch (e) {
            print("Currency conversion failed: $e");
            convertedAmount = amount;
          }
        }
        totalBudget += convertedAmount;
      }
      return totalBudget;
    } catch (e) {
      print("Error calculating total budget: $e");
      return 0.0;
    }
  }

  Future<double> getTotalSpentAcrossCategories(String preferredCurrency) async {
    if (currentUserId == null) {
      return 0.0;
    }
    try {
      final transactions =
          await _firestore
              .collection('transactions')
              .where('userId', isEqualTo: currentUserId)
              .where('type', isEqualTo: 'expense')
              .get();
      double totalSpent = 0.0;
      for (final doc in transactions.docs) {
        final data = doc.data();
        final double amount = data['amount'] as double;
        final String currency = data['currency'] as String;
        double convertedAmount = amount;
        if (currency != preferredCurrency) {
          try {
            convertedAmount = await convertCurrency(
              amount,
              currency,
              preferredCurrency,
            );
          } catch (e) {
            print("Currency conversion failed: $e");
            convertedAmount = amount;
          }
        }
        totalSpent += convertedAmount;
      }
      return totalSpent;
    } catch (e) {
      print("Error calculating total spent: $e");
      return 0.0;
    }
  }

  Future<Map<String, Map<String, double>>> getBudgetSummary(
    String preferredCurrency,
  ) async {
    if (currentUserId == null) {
      return {};
    }
    try {
      final budgetGoals = await getAllBudgetGoals();
      final Map<String, Map<String, double>> summary = {};
      final categories = [
        'Food',
        'Transportation',
        'Housing',
        'Entertainment',
        'Utilities',
        'Healthcare',
        'Shopping',
        'Other',
      ];
      for (final category in categories) {
        summary[category] = {'budget': 0.0, 'spent': 0.0, 'remaining': 0.0};
      }

      for (final budget in budgetGoals) {
        final String category = budget['category'] as String;
        final double amount = budget['amount'] as double;
        final String currency = budget['currency'] as String;
        double convertedAmount = amount;
        if (currency != preferredCurrency) {
          try {
            convertedAmount = await convertCurrency(
              amount,
              currency,
              preferredCurrency,
            );
          } catch (e) {
            print("Currency conversion failed for budget: $e");
            convertedAmount = amount;
          }
        }
        summary[category]!['budget'] = convertedAmount;
      }
      final transactions =
          await _firestore
              .collection('transactions')
              .where('userId', isEqualTo: currentUserId)
              .where('type', isEqualTo: 'expense')
              .get();
      for (final doc in transactions.docs) {
        final data = doc.data();
        final String category = data['category'] as String;
        final double amount = data['amount'] as double;
        final String currency = data['currency'] as String;
        double convertedAmount = amount;
        if (currency != preferredCurrency) {
          try {
            convertedAmount = await convertCurrency(
              amount,
              currency,
              preferredCurrency,
            );
          } catch (e) {
            print("Currency conversion failed for transaction: $e");
            convertedAmount = amount;
          }
        }
        if (summary.containsKey(category)) {
          summary[category]!['spent'] =
              (summary[category]!['spent'] ?? 0.0) + convertedAmount;
        }
      }
      for (final category in summary.keys) {
        final budget = summary[category]!['budget']!;
        final spent = summary[category]!['spent']!;
        summary[category]!['remaining'] = budget - spent;
      }
      return summary;
    } catch (e) {
      print("Error getting budget summary: $e");
      return {};
    }
  }
}
