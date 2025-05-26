import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseIncomeScreen extends StatelessWidget {
  const ExpenseIncomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> transactions = [
      {
        'id': '1',
        'type': 'expense',
        'amount': 25.99,
        'category': 'Food',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'description': 'Lunch at restaurant',
      },
      {
        'id': '2',
        'type': 'income',
        'amount': 1200.00,
        'category': 'Salary',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'description': 'Monthly salary',
      },
      {
        'id': '3',
        'type': 'expense',
        'amount': 35.50,
        'category': 'Transportation',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'description': 'Uber ride',
      },
      {
        'id': '4',
        'type': 'expense',
        'amount': 120.75,
        'category': 'Shopping',
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'description': 'Clothes shopping',
      },
      {
        'id': '5',
        'type': 'income',
        'amount': 50.00,
        'category': 'Refund',
        'date': DateTime.now().subtract(const Duration(days: 4)),
        'description': 'Return item refund',
      },
    ];
    final double totalIncome = transactions
        .where((transaction) => transaction['type'] == 'income')
        .fold(
          0.0,
          (sum, transaction) => sum + (transaction['amount'] as double),
        );
    final double totalExpense = transactions
        .where((transaction) => transaction['type'] == 'expense')
        .fold(
          0.0,
          (sum, transaction) => sum + (transaction['amount'] as double),
        );
    final double balance = totalIncome - totalExpense;
    return Scaffold(
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Current Balance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.currency_exchange),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Currency converter will be implemented later',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        tooltip: 'Convert Currency',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: balance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryItem(
                        label: 'Income',
                        amount: totalIncome,
                        color: Colors.green,
                        icon: Icons.arrow_upward,
                      ),
                      _SummaryItem(
                        label: 'Expenses',
                        amount: totalExpense,
                        color: Colors.red,
                        icon: Icons.arrow_downward,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'View all transactions will be implemented later',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return _TransactionItem(transaction: transaction);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  const _TransactionItem({required this.transaction});
  @override
  Widget build(BuildContext context) {
    final bool isExpense = transaction['type'] == 'expense';
    final DateFormat formatter = DateFormat('MMM dd, yyyy');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isExpense ? Colors.red.shade100 : Colors.green.shade100,
          child: Icon(
            isExpense ? Icons.remove : Icons.add,
            color: isExpense ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          transaction['category'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${formatter.format(transaction['date'])} • ${transaction['description']}',
        ),
        trailing: Text(
          '${isExpense ? '-' : '+'}\$${transaction['amount'].toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isExpense ? Colors.red : Colors.green,
          ),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction details will be implemented later'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
