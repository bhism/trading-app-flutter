// import 'dart:js_interop';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
// import 'dart:convert';

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
  // Data variables for each tab
  var tab1Data;
  var tab2Data;
  var price;

  // Timer to fetch data every second
  Timer? timer;

  // API endpoint
  final String apiUrl = 'http://10.0.2.2:5000/get_accumulated_data';

  @override
  void initState() {
    super.initState();
    // Start fetching data on app initialization
    fetchData();
    // Schedule data fetching every second
    timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
      fetchData();
    });
  }

  @override
  void dispose() {
    // Dispose of the timer when the widget is disposed
    if (timer != null) {
      timer!.cancel();
    }
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        // final data = json.decode(response.body);
        final data = json.decode(response.body);
        // var k =
        print(">>>>>>>>>>>>>>>>>>>>>");
        // print(k[0]["feeds"]["NSE_EQ|INE002A01018"]["ff"]["marketFF"]["ltpc"]
        //     ["ltp"]);
        print(data[0]["feeds"]["NSE_EQ|INE002A01018"]["ff"]["marketFF"]["ltpc"]
            ["ltp"]);
        print(">>>>>>>>>>>>>>>>>>>>>");

        setState(() {
          // Clear previous data and update with new data
          // tab1Data = {};
          // tab2Data = {};
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
                });
              },
              child: Text("sdfsd"),
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
            buildTab(price),
            buildTab(price),
          ],
        ),
      ),
    );
  }

  // Widget buildTab(var data) {
  //   return ListView.builder(
  //     itemCount: data.length,
  //     itemBuilder: (context, index) {
  //       return ListTile(
  //         title: Text(data[index]),
  //       );
  //     },
  //   );
  // }

  Widget buildTab(var data) {
    print("????????????");
    print(data);
    print("????????????");

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("Reliance  : " + data.toString()),
      ],
    );
  }
}
