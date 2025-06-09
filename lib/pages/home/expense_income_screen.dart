import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseIncomeScreen extends StatefulWidget {
  const ExpenseIncomeScreen({super.key});
  @override
  State<ExpenseIncomeScreen> createState() => _ExpenseIncomeScreenState();
}

class _ExpenseIncomeScreenState extends State<ExpenseIncomeScreen> {
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
  Future<void> _loadPreferredCurrency() async {
    final currency = await _firestoreService.getPreferredCurrency();
    setState(() {
      _preferredCurrency = currency;
    });
  }

  Future<double> _calculateTotalBalance(List<DocumentSnapshot> docs) async {
    double totalBalance = 0.0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final double amount = data['amount'] as double;
      final String currency = data['currency'] as String;
      final String type = data['type'] as String;
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
      if (type == 'income') {
        totalBalance += convertedAmount;
      } else if (type == 'expense') {
        totalBalance -= convertedAmount;
      }
    }
    return totalBalance;
  }

  Future<double> _calculateTotalIncome(List<DocumentSnapshot> docs) async {
    double totalIncome = 0.0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final double amount = data['amount'] as double;
      final String currency = data['currency'] as String;
      final String type = data['type'] as String;
      if (type == 'income') {
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
        totalIncome += convertedAmount;
      }
    }
    return totalIncome;
  }

  Future<double> _calculateTotalExpenses(List<DocumentSnapshot> docs) async {
    double totalExpenses = 0.0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final double amount = data['amount'] as double;
      final String currency = data['currency'] as String;
      final String type = data['type'] as String;
      if (type == 'expense') {
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
        totalExpenses += convertedAmount;
      }
    }
    return totalExpenses;
  }

  // VARIABLE FORM
  final formkeySave = GlobalKey<FormState>();
  final formkeyUpdate = GlobalKey<FormState>();
  String type = 'expense';
  String category = 'Food';
  String currency = 'USD';
  DateTime datenow = DateTime.now();
  TextEditingController controllerAmount = TextEditingController();
  TextEditingController controllerDescription = TextEditingController();
  // DATE PICKER
  void changeDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: datenow,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() {
        datenow = pickedDate;
      });
    }
  }

  // onChangeCategoryFormSave
  void onChangeCategory(bool isNew) {
    if (type == 'expense') {
      setState(() {
        listCategory.clear();
        listCategory = [
          'Food',
          'Transportation',
          'Housing',
          'Entertainment',
          'Utilities',
          'Healthcare',
          'Shopping',
          'Other',
        ];
        if (isNew) {
          category = 'Food';
        }
      });
    } else if (type == 'income') {
      listCategory.clear();
      listCategory = ['Salary', 'Investment', 'Gift', 'Refund', 'Other'];
      if (isNew) {
        category = 'Salary';
      }
    }
  }

  // SAVE STTATE
  void saveFinance() async {
    print("Save button pressed");
    if (formkeySave.currentState!.validate()) {
      print("Form validated");
      // print("Form saved - Type: $type, Amount: ${controllerAmount.text}, Currency: $currency, Category: $category, Description: $description");
      try {
        print("Attempting to add transaction...");
        await _firestoreService.addTransaction(
          type: type,
          amount: double.parse(controllerAmount.text),
          currency: currency,
          category: category,
          description: controllerDescription.text,
          date: datenow,
        );
        print("Transaction added successfully");
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        print("Error adding transaction: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    } else {
      print("Form validation failed");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: Form Validation Failed')));
    }
  }

  // UPDATE STATE
  void updateFinance(id) async {
    if (formkeyUpdate.currentState!.validate()) {
      formkeyUpdate.currentState!.save();
      await _firestoreService.updateTransaction(
        id: id,
        type: type,
        amount: double.parse(controllerAmount.text),
        currency: currency,
        category: category,
        description: controllerDescription.text,
        date: datenow,
      );
      if (context.mounted) Navigator.pop(context);
    }
  }

  // DELETE STATE
  void deleteFinance(id) async {
    await _firestoreService.deleteTransaction(id);
    if (context.mounted) Navigator.pop(context);
  }

  // CLEAR STATE / INITIAL STATE
  void initialState() {
    setState(() {
      type = 'expense';
      currency = 'USD';
      datenow = DateTime.now();
      controllerAmount.clear();
      controllerDescription.clear();
      listCategory = [
        'Food',
        'Transportation',
        'Housing',
        'Entertainment',
        'Utilities',
        'Healthcare',
        'Shopping',
        'Other',
      ];
      category = 'Food';
    });
  }

  Future<void> _convertAllTransactions() async {
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

  @override
  void initState() {
    super.initState();
    _loadPreferredCurrency();
    final user = FirebaseAuth.instance.currentUser;
    print("Current user: ${user?.uid ?? 'Not authenticated'}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildCurrencySelector(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No transactions yet. Add one!'),
                  );
                }
                final docs = snapshot.data!.docs;
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aDate = (aData['date'] as Timestamp).toDate();
                  final bDate = (bData['date'] as Timestamp).toDate();
                  return bDate.compareTo(aDate);
                });
                return Column(
                  children: [
                    FutureBuilder<List<double>>(
                      future: Future.wait([
                        _calculateTotalBalance(docs),
                        _calculateTotalIncome(docs),
                        _calculateTotalExpenses(docs),
                      ]),
                      builder: (context, futureSnapshot) {
                        if (futureSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (futureSnapshot.hasError ||
                            !futureSnapshot.hasData) {
                          return Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text('Error calculating totals'),
                            ),
                          );
                        }
                        final totals = futureSnapshot.data!;
                        final totalBalance = totals[0];
                        final totalIncome = totals[1];
                        final totalExpenses = totals[2];
                        return _buildTotalBalanceCard(
                          totalBalance,
                          totalIncome,
                          totalExpenses,
                        );
                      },
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildTransactionItem(doc.id, data);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTotalBalanceCard(
    double totalBalance,
    double totalIncome,
    double totalExpenses,
  ) {
    final isPositive = totalBalance >= 0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isPositive
                  ? [Colors.green.shade400, Colors.green.shade600]
                  : [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? Colors.green : Colors.red),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${isPositive ? '' : '-'}${totalBalance.abs().toStringAsFixed(2)} ${_preferredCurrency ?? 'USD'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Icon(Icons.arrow_downward, color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    'Income',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    '${totalIncome.toStringAsFixed(2)} ${_preferredCurrency ?? 'USD'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(height: 40, width: 1, color: Colors.white),
              Column(
                children: [
                  Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    'Expenses',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    '${totalExpenses.toStringAsFixed(2)} ${_preferredCurrency ?? 'USD'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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
                onPressed: _convertAllTransactions,
                icon: const Icon(Icons.currency_exchange),
                label: const Text('Convert All'),
              ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String id, Map<String, dynamic> data) {
    final bool isExpense = data['type'] == 'expense';
    final double amount = data['amount'] as double;
    final String currency = data['currency'] as String;
    final String category = data['category'] as String;
    final String description = data['description'] as String;
    final Timestamp timestamp = data['date'] as Timestamp;
    final DateTime date = timestamp.toDate();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpense ? Colors.red : Colors.green,
          child: Icon(
            isExpense ? Icons.remove : Icons.add,
            color: Colors.white,
          ),
        ),
        title: Text(
          description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${DateFormat('MMM dd, yyyy').format(date)} • $category',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isExpense ? '-' : '+'} ${amount.toStringAsFixed(2)} $currency',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isExpense ? Colors.red : Colors.green,
              ),
            ),
            if (currency != _preferredCurrency)
              FutureBuilder<double>(
                future: _firestoreService.convertCurrency(
                  amount,
                  currency,
                  _preferredCurrency!,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Converting...',
                      style: TextStyle(fontSize: 12),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text(
                      'Conversion error',
                      style: TextStyle(fontSize: 12),
                    );
                  }
                  return Text(
                    '(${isExpense ? '-' : '+'} ${snapshot.data!.toStringAsFixed(2)} $_preferredCurrency)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpense ? Colors.red[300] : Colors.green[300],
                    ),
                  );
                },
              ),
          ],
        ),
        onTap: () => _showTransactionOptions(context, id, data),
      ),
    );
  }

  void _showTransactionOptions(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Transaction'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditTransactionDialog(context, id, data);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Transaction',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text(
            'Are you sure you want to delete this transaction?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                deleteFinance(id);
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to add transactions'),
        ),
      );
      return;
    }
    // final formKey = GlobalKey<FormState>();
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
                key: formkeySave,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add Transaction',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Expense'),
                            value: 'expense',
                            groupValue: type,
                            onChanged: (value) {
                              setState(() {
                                type = value!;
                                onChangeCategory(true);
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Income'),
                            value: 'income',
                            groupValue: type,
                            onChanged: (value) {
                              setState(() {
                                type = value!;
                                onChangeCategory(true);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: controllerAmount,
                            decoration: const InputDecoration(
                              labelText: 'Amount',
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
                            value: currency,
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
                                currency = newValue!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      value: category,
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
                          category = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllerDescription,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: changeDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(DateFormat('MMM dd, yyyy').format(datenow)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            initialState();
                          },
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: saveFinance,
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

  void _showEditTransactionDialog(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) {
    setState(() {
      type = data['type'];
      category = data['category'];
      currency = data['currency'];
      datenow = (data['date'] as Timestamp).toDate();
      controllerAmount.text = data['amount'].toString();
      controllerDescription.text = data['description'];
      onChangeCategory(false);
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
                key: formkeyUpdate,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Edit Transaction',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Expense'),
                            value: 'expense',
                            groupValue: type,
                            onChanged: (value) {
                              setState(() {
                                type = value!;
                                onChangeCategory(true);
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Income'),
                            value: 'income',
                            groupValue: type,
                            onChanged: (value) {
                              setState(() {
                                type = value!;
                                onChangeCategory(true);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: controllerAmount,
                            decoration: const InputDecoration(
                              labelText: 'Amount',
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
                            value: currency,
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
                                currency = newValue!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      value: category,
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
                          category = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllerDescription,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: changeDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(DateFormat('MMM dd, yyyy').format(datenow)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            initialState();
                          },
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            updateFinance(id);
                          },
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
}
