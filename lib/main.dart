import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'LingTab'),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Transaction Object
class Transaction {
  final int id;
  final double amount;
  final String description;
  final DateTime date;
  final bool repayment;

  const Transaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.repayment,
  });

  factory Transaction.fromJSON(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: double.parse(json['amount']),
      description: json['description'],
      date: DateTime.parse(json['date']),
      repayment: json['repayment'],
    );
  }
}

// Account Balance Object
class AccountBalance {
  final double balance;
  final List<Transaction> transactions;

  const AccountBalance({
    required this.balance,
    required this.transactions,
  });

  factory AccountBalance.fromJSON(Map<String, dynamic> json) {
    var transactionsList = (json['transactions'] as List)
        .map((transaction) => Transaction.fromJSON(transaction))
        .toList();

    return AccountBalance(
      balance: json['balance'],
      transactions: transactionsList,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<AccountBalance> futureAccountBalance;

  Future<AccountBalance> fetchBalance() async {
    final response =
        await http.get(Uri.parse('http://sid.local:1080/api/transactions'));

    print(response.body);
    if (response.statusCode == 200) {
      return AccountBalance.fromJSON(
          jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load account balance.');
    }
  }

  void refreshBalance() {
    setState(() {
      futureAccountBalance = fetchBalance();
    });
  }

  @override
  void initState() {
    super.initState();
    futureAccountBalance = fetchBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              const Text(
                'Account balance:',
                textAlign: TextAlign.center,
              ),
              FutureBuilder<AccountBalance>(
                future: futureAccountBalance,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (snapshot.hasData) {
                    return Expanded(
                      child: Column(
                        children: [
                          Text(
                            "£${snapshot.data!.balance.toStringAsFixed(2)}",
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 16),
                          const Text('Recent Transactions:'),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: snapshot.data!.transactions.length,
                              itemBuilder: (context, index) {
                                final transaction =
                                    snapshot.data!.transactions[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    title: Text(transaction.description),
                                    subtitle: Text(
                                        'Date: ${transaction.date.toLocal()}'),
                                    trailing: Text(
                                      "£${transaction.amount.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        color: transaction.repayment
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const Text('No data available.');
                  }
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: refreshBalance,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
