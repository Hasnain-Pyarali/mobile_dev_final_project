import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetGoalsScreen extends StatefulWidget {
  const BudgetGoalsScreen({super.key});
  @override
  State<BudgetGoalsScreen> createState() => _BudgetGoalsScreenState();
}

class _BudgetGoalsScreenState extends State<BudgetGoalsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _preferredCurrency = 'USD';
  bool _isConverting = false;
  var listCurrency = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'INR',
    'CNY',
    'IDR',
  ];
  var listCategory = [
    'Food',
    'Transportation',
    'Housing',
    'Entertainment',
    'Utilities',
    'Healthcare',
    'Shopping',
    'Other',
  ];
  final formKeySave = GlobalKey<FormState>();
  final formKeyUpdate = GlobalKey<FormState>();
  String selectedCategory = 'Food';
  String selectedCurrency = 'USD';
  TextEditingController controllerAmount = TextEditingController();
  TextEditingController controllerNotes = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadPreferredCurrency();
  }

  Future<void> _loadPreferredCurrency() async {
    final currency = await _firestoreService.getPreferredCurrency();
    setState(() {
      _preferredCurrency = currency;
      selectedCurrency = currency ?? 'USD';
    });
  }

  Future<void> _convertAllBudgets() async {
    setState(() {
      _isConverting = true;
    });
    try {
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      setState(() {
        _isConverting = false;
      });
    }
  }

  Future<double> _calculateSpentAmount(String category) async {
    final transactions = await _firestoreService.getTransactions().first;
    double totalSpent = 0.0;
    for (var doc in transactions.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['type'] == 'expense' && data['category'] == category) {
        final double amount = data['amount'] as double;
        final String currency = data['currency'] as String;
        double convertedAmount = amount;
        if (currency != _preferredCurrency) {
          try {
            convertedAmount = await _firestoreService.convertCurrency(
              amount,
              currency,
              _preferredCurrency!,
            );
          } catch (e) {
            convertedAmount = amount;
          }
        }
        totalSpent += convertedAmount;
      }
    }
    return totalSpent;
  }

  void _saveBudget() async {
    if (formKeySave.currentState!.validate()) {
      try {
        await _firestoreService.addBudgetGoal(
          category: selectedCategory,
          amount: double.parse(controllerAmount.text),
          currency: selectedCurrency,
          notes: controllerNotes.text,
        );
        if (context.mounted) {
          Navigator.pop(context);
          _clearForm();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _updateBudget(String id) async {
    if (formKeyUpdate.currentState!.validate()) {
      try {
        await _firestoreService.updateBudgetGoal(
          id: id,
          category: selectedCategory,
          amount: double.parse(controllerAmount.text),
          currency: selectedCurrency,
          notes: controllerNotes.text,
        );
        if (context.mounted) {
          Navigator.pop(context);
          _clearForm();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _deleteBudget(String id) async {
    try {
      await _firestoreService.deleteBudgetGoal(id);
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _clearForm() {
    setState(() {
      selectedCategory = 'Food';
      selectedCurrency = _preferredCurrency ?? 'USD';
      controllerAmount.clear();
      controllerNotes.clear();
    });
  }

  void _showCategoryTransactions(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CategoryTransactionsScreen(
              category: category,
              preferredCurrency: _preferredCurrency ?? 'USD',
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildCurrencySelector(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getBudgetGoals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final budgetDocs = snapshot.data?.docs ?? [];
                if (budgetDocs.isEmpty) {
                  return const SizedBox.shrink();
                }
                final budgetsWithData =
                    budgetDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {'id': doc.id, 'data': data};
                    }).toList();
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: budgetsWithData.length,
                  itemBuilder: (context, index) {
                    final budgetItem = budgetsWithData[index];
                    final budgetData =
                        budgetItem['data'] as Map<String, dynamic>;
                    final budgetId = budgetItem['id'] as String;
                    final category = budgetData['category'] as String;
                    return _buildBudgetCard(category, budgetData, budgetId);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Text('Preferred Currency:'),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _preferredCurrency,
            items:
                listCurrency.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (String? newValue) async {
              if (newValue != null) {
                setState(() {
                  _preferredCurrency = newValue;
                });
                await _firestoreService.updatePreferredCurrency(newValue);
              }
            },
          ),
          const Spacer(),
          _isConverting
              ? const CircularProgressIndicator()
              : TextButton.icon(
                onPressed: _convertAllBudgets,
                icon: const Icon(Icons.currency_exchange),
                label: const Text('Convert All'),
              ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(
    String category,
    Map<String, dynamic>? budgetData,
    String? budgetId,
  ) {
    final bool hasBudget = budgetData != null;
    return FutureBuilder<double>(
      future: _calculateSpentAmount(category),
      builder: (context, spentSnapshot) {
        if (spentSnapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }
        final double spentAmount = spentSnapshot.data ?? 0.0;
        if (!hasBudget) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () => _showCategoryTransactions(category),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed:
                              () => _showAddBudgetDialog(category: category),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No budget set - Unlimited',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Spent: ${spentAmount.toStringAsFixed(2)} ${_preferredCurrency ?? 'USD'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final double budgetAmount = budgetData['amount'] as double;
        final String budgetCurrency = budgetData['currency'] as String;
        final String notes = budgetData['notes'] as String? ?? '';
        return FutureBuilder<double>(
          future:
              budgetCurrency != _preferredCurrency
                  ? _firestoreService.convertCurrency(
                    budgetAmount,
                    budgetCurrency,
                    _preferredCurrency!,
                  )
                  : Future.value(budgetAmount),
          builder: (context, budgetSnapshot) {
            final double convertedBudget = budgetSnapshot.data ?? budgetAmount;
            final double percentage =
                convertedBudget > 0 ? (spentAmount / convertedBudget) * 100 : 0;
            final double remaining = convertedBudget - spentAmount;
            final bool isOverBudget = spentAmount > convertedBudget;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => _showCategoryTransactions(category),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditBudgetDialog(budgetId!, budgetData);
                              } else if (value == 'delete') {
                                _showDeleteConfirmation(budgetId!);
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                          ),
                        ],
                      ),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          notes,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Budget: ${convertedBudget.toStringAsFixed(2)} ${_preferredCurrency ?? 'USD'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isOverBudget ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverBudget ? Colors.red : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Spent: ${spentAmount.toStringAsFixed(2)} ${_preferredCurrency ?? 'USD'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            '${isOverBudget ? 'Over by' : 'Remaining'}: ${remaining.abs().toStringAsFixed(2)} ${_preferredCurrency ?? 'USD'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isOverBudget ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddBudgetDialog({String? category}) {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add budgets')),
      );
      return;
    }
    _clearForm();
    if (category != null) {
      selectedCategory = category;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Form(
                key: formKeySave,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add Budget Goal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedCategory,
                      items:
                          listCategory.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: controllerAmount,
                            decoration: const InputDecoration(
                              labelText: 'Budget Amount',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an amount';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedCurrency,
                            items:
                                listCurrency.map<DropdownMenuItem<String>>((
                                  String value,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedCurrency = newValue!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllerNotes,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _clearForm();
                          },
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveBudget,
                          child: const Text('SAVE'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditBudgetDialog(String id, Map<String, dynamic> data) {
    setState(() {
      selectedCategory = data['category'];
      selectedCurrency = data['currency'];
      controllerAmount.text = data['amount'].toString();
      controllerNotes.text = data['notes'] ?? '';
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Form(
                key: formKeyUpdate,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Edit Budget Goal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedCategory,
                      items:
                          listCategory.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: controllerAmount,
                            decoration: const InputDecoration(
                              labelText: 'Budget Amount',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an amount';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedCurrency,
                            items:
                                listCurrency.map<DropdownMenuItem<String>>((
                                  String value,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedCurrency = newValue!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllerNotes,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _clearForm();
                          },
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _updateBudget(id),
                          child: const Text('UPDATE'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Budget Goal'),
          content: const Text(
            'Are you sure you want to delete this budget goal?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => _deleteBudget(id),
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class CategoryTransactionsScreen extends StatelessWidget {
  final String category;
  final String preferredCurrency;
  const CategoryTransactionsScreen({
    super.key,
    required this.category,
    required this.preferredCurrency,
  });
  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: Text('$category Transactions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No transactions found'));
          }
          final allDocs = snapshot.data!.docs;
          final categoryDocs =
              allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['type'] == 'expense' &&
                    data['category'] == category;
              }).toList();
          if (categoryDocs.isEmpty) {
            return Center(
              child: Text('No expenses found for $category category'),
            );
          }
          categoryDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aDate = (aData['date'] as Timestamp).toDate();
            final bDate = (bData['date'] as Timestamp).toDate();
            return bDate.compareTo(aDate);
          });
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categoryDocs.length,
            itemBuilder: (context, index) {
              final doc = categoryDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildTransactionItem(data, firestoreService);
            },
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(
    Map<String, dynamic> data,
    FirestoreService firestoreService,
  ) {
    final double amount = data['amount'] as double;
    final String currency = data['currency'] as String;
    final String description = data['description'] as String;
    final Timestamp timestamp = data['date'] as Timestamp;
    final DateTime date = timestamp.toDate();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red,
          child: const Icon(Icons.remove, color: Colors.white),
        ),
        title: Text(
          description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(DateFormat('MMM dd, yyyy').format(date)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '- ${amount.toStringAsFixed(2)} $currency',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            if (currency != preferredCurrency)
              FutureBuilder<double>(
                future: firestoreService.convertCurrency(
                  amount,
                  currency,
                  preferredCurrency,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Converting...',
                      style: TextStyle(fontSize: 12),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text('Error', style: TextStyle(fontSize: 12));
                  }
                  return Text(
                    '(- ${snapshot.data!.toStringAsFixed(2)} $preferredCurrency)',
                    style: TextStyle(fontSize: 12, color: Colors.red[300]),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
