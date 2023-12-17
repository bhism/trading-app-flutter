import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyTabs(),
    );
  }
}

class MyTabs extends StatefulWidget {
  @override
  _MyTabsState createState() => _MyTabsState();
}

class _MyTabsState extends State<MyTabs> {
  var tab1Data;
  var tab2Data;
  double price = 0.0;
  int quantity = 0;
  double totalInvestment = 0.0;
  double profitOrLoss = 0.0;
  double totalValue = 0.0;
  Color textColor = Colors.green;
  final String apiUrl = 'http://10.0.2.2:5000/get_accumulated_data';

  @override
  void initState() {
    super.initState();
    fetchData();
    Timer.periodic(Duration(seconds: 1), (Timer t) {
      fetchData();
    });
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          price = data[0]["feeds"]["NSE_EQ|INE002A01018"]["ff"]["marketFF"]
              ["ltpc"]["ltp"];
          tab1Data = data;
          tab2Data = data;
        });
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void buyStock(int quantity) {
    // Calculate the total investment
    setState(() {
      totalInvestment = price * quantity;
    });
  }

  double calculateProfitOrLoss(int quantity) {
    // Calculate profit or loss based on the current price and quantity
    var ff;
    setState(() {
      totalValue = price * quantity;
      ff = totalValue - totalInvestment;
    });
    return ff;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            MaterialButton(
              onPressed: () {
                setState(() {
                  price = 0;
                  totalInvestment = 0;
                  textColor = Colors.green;
                  // profitOrLoss = 0;
                  quantity = 0;
                  totalValue = 0;
                  profitOrLoss = calculateProfitOrLoss(quantity);
                });
              },
              child: Text("Reset"),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Tab 1'),
              Tab(text: 'Tab 2'),
            ],
          ),
          title: Text('Data Fetching Tabs'),
        ),
        body: TabBarView(
          children: [
            buildTab(price, quantity),
            buildTab(price, quantity),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Buy Stock"),
                  content: Column(
                    children: <Widget>[
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: "Enter Quantity"),
                        onChanged: (value) {
                          setState(() {
                            quantity = int.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    Text("Total Investment: $totalInvestment"),
                    ElevatedButton(
                      child: Text("Buy"),
                      onPressed: () {
                        buyStock(quantity);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  Widget buildTab(double price, int quantity) {
    setState(() {
      profitOrLoss = calculateProfitOrLoss(quantity);
    });
    textColor = profitOrLoss >= 0 ? Colors.green : Colors.red;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("Reliance Price: $price"),
        Text("total Investment: $totalInvestment"),
        Text(
          "Profit or Loss: $profitOrLoss",
          style: TextStyle(color: textColor),
        ),
      ],
    );
  }
}
