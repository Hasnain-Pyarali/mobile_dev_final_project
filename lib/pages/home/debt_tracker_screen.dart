import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DebtTrackerScreen extends StatefulWidget {
  const DebtTrackerScreen({super.key});
  @override
  State<DebtTrackerScreen> createState() => _DebtTrackerScreenState();
}

class _DebtTrackerScreenState extends State<DebtTrackerScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _preferredCurrency = 'USD';
  bool _isConverting = false;
  var listCurrency = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'INR', 'CNY'];
  Future<void> _loadPreferredCurrency() async {
    final currency = await _firestoreService.getPreferredCurrency();
    setState(() {
      _preferredCurrency = currency;
    });
  }

  // VARIABLE FORM
  final formkeySave = GlobalKey<FormState>();
  final formkeyUpdate = GlobalKey<FormState>();
  String type = 'debt';
  // String currency = _preferredCurrency;
  String currency = 'USD';
  DateTime datenow = DateTime.now();
  TextEditingController controllerAmount = TextEditingController();
  TextEditingController controllerDebtor = TextEditingController();
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

  // SAVE STTATE
  void saveFinance() async {
    print("Save button pressed");
    if (formkeySave.currentState!.validate()) {
      print("Form validated");
      // print("Form saved - Type: $type, Amount: ${controllerAmount.text}, Currency: $currency, Debtor: $debtor, Description: $description");
      try {
        print("Attempting to add debt...");
        await _firestoreService.addDebt(
          type: type,
          amount: double.parse(controllerAmount.text),
          currency: currency,
          debtor: controllerDebtor.text,
          description: controllerDescription.text,
          date: datenow,
        );
        print("Debt added successfully");
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        print("Error adding debt: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    } else {
      print("Form validation failed");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: Form Validation Failed')));
    }
  }

  // UPDATE STATE
  void updateFinance(id) async {
    if (formkeyUpdate.currentState!.validate()) {
      formkeyUpdate.currentState!.save();
      await _firestoreService.updateDebt(
        id: id,
        type: type,
        amount: double.parse(controllerAmount.text),
        currency: currency,
        debtor: controllerDebtor.text,
        description: controllerDescription.text,
        date: datenow,
      );
      if (context.mounted) Navigator.pop(context);
    }
  }

  // DELETE STATE
  void deleteFinance(id) async {
    await _firestoreService.deleteDebt(id);
    if (context.mounted) Navigator.pop(context);
  }

  // CLEAR STATE / INITIAL STATE
  void initialState() {
    setState(() {
      type = 'debt';
      currency = 'USD';
      datenow = DateTime.now();
      controllerAmount.clear();
      controllerDescription.clear();
    });
  }

  Future<void> _convertAllDebts() async {
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
              stream: _firestoreService.getDebts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No debts yet. Add one!'));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildDebtItem(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAddDebtDialog(context), child: const Icon(Icons.add)),
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
                  return DropdownMenuItem<String>(value: value, child: Text(value));
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
              : TextButton.icon(onPressed: _convertAllDebts, icon: const Icon(Icons.currency_exchange), label: const Text('Convert All')),
        ],
      ),
    );
  }

  Widget _buildDebtItem(String id, Map<String, dynamic> data) {
    final bool isDebt = data['type'] == 'debt';
    final double amount = data['amount'] as double;
    final String currency = data['currency'] as String;
    final String debtor = data['debtor'] as String;
    final String description = data['description'] as String;
    final Timestamp timestamp = data['date'] as Timestamp;
    final DateTime date = timestamp.toDate();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: isDebt ? Colors.red : Colors.green, child: Icon(isDebt ? Icons.remove : Icons.add, color: Colors.white)),
        title: Text(description, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${DateFormat('MMM dd, yyyy').format(date)} • $debtor'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isDebt ? '-' : '+'} ${amount.toStringAsFixed(2)} $currency',
              style: TextStyle(fontWeight: FontWeight.bold, color: isDebt ? Colors.red : Colors.green),
            ),
            if (currency != _preferredCurrency)
              FutureBuilder<double>(
                future: _firestoreService.convertCurrency(amount, currency, _preferredCurrency!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Converting...', style: TextStyle(fontSize: 12));
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text('Conversion error', style: TextStyle(fontSize: 12));
                  }
                  return Text(
                    '(${isDebt ? '-' : '+'} ${snapshot.data!.toStringAsFixed(2)} $_preferredCurrency)',
                    style: TextStyle(fontSize: 12, color: isDebt ? Colors.red[300] : Colors.green[300]),
                  );
                },
              ),
          ],
        ),
        onTap: () => _showDebtOptions(context, id, data),
      ),
    );
  }

  void _showDebtOptions(BuildContext context, String id, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Debt'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDebtDialog(context, id, data);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Debt', style: TextStyle(color: Colors.red)),
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
          title: const Text('Delete Debt'),
          content: const Text('Are you sure you want to delete this debt?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
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

  void _showAddDebtDialog(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in to add debts')));
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
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
              child: Form(
                key: formkeySave,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Add Debt', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Debt'),
                            value: 'debt',
                            groupValue: type,
                            onChanged: (value) {
                              setState(() {
                                type = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Credit'),
                            value: 'credit',
                            groupValue: type,
                            onChanged: (value) {
                              setState(() {
                                type = value!;
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
                            decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
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
                            decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder()),
                            value: currency,
                            items:
                                listCurrency.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(value: value, child: Text(value));
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
                    TextFormField(
                      controller: controllerDebtor,
                      decoration: const InputDecoration(labelText: 'Debtor', border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a debtor';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllerDescription,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
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
                        decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
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
                        ElevatedButton(onPressed: saveFinance, child: const Text('SAVE')),
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

  void _showEditDebtDialog(BuildContext context, String id, Map<String, dynamic> data) {
    setState(() {
      type = data['type'];
      currency = data['currency'];
      datenow = (data['date'] as Timestamp).toDate();
      controllerAmount.text = data['amount'].toString();
      controllerDebtor.text = data['debtor'];
      controllerDescription.text = data['description'];
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
              child: Form(
                key: formkeyUpdate,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Edit Debt', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Debt'),
                            value: 'debt',
                            groupValue: type,
                            onChanged: (value) {
                              setState(() {
                                type = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Credit'),
                            value: 'credit',
                            groupValue: type,
                            onChanged: (value) {
                              setState(() {
                                type = value!;
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
                            decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
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
                            decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder()),
                            value: currency,
                            items:
                                listCurrency.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(value: value, child: Text(value));
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
                    TextFormField(
                      controller: controllerDescription,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a debtor';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllerDebtor,
                      decoration: const InputDecoration(labelText: 'Debtor', border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a debtor';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllerDescription,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
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
                        decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
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
