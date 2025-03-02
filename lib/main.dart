


// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs


import 'package:intl/intl.dart';
import 'package:my_app/model/property.dart';
import 'package:my_app/pages/PageStatics.dart';
import 'package:my_app/pages/addexpense.dart';
import 'package:my_app/pages/allproperty.dart';
import 'package:my_app/pages/repair.dart';
import 'package:my_app/pages/expensespage.dart';
import 'package:my_app/pages/issue.dart';
import 'package:my_app/pages/login.dart';
import 'package:my_app/pages/newissue.dart';
import 'package:my_app/pages/newproperty.dart';
import 'package:my_app/pages/rentpayment.dart';
import 'package:my_app/services/TransactionService.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';



void main()  async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());

}
class MyApp extends StatelessWidget {

  MyApp({super.key});
  String currentMonth = "";
  @override
  void initState() {

  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    print('in main build');
    return ChangeNotifierProvider<PropertyModel>(
        create : (context) {var p= PropertyModel();
        p.loadPriorityProperties();p.loadOtherProperties();
        return p;},
        child : MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          routerConfig: router(),
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          //home: const MyHomePage(title: 'Flutter Demo Home Page'),
        ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;



  @override
  State<MyHomePage> createState() => _MyApp();
}
GoRouter router() {
  return GoRouter(
    initialLocation: '/main',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) =>  const MyLogin(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const  MyHomePage(title: "Reapp"),
      ),
    ],
  );
}
class _MyApp extends State<MyHomePage> {
  int _selectedIndex =0;
  late void Function(String) myMethod;

  List<Widget> getActions(int body) {
    switch (body) {
      case 2:
        return [
          IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>   NewProperty(rentable: RentableModel.nullCardViewModel(), insertMode: true,)),
                  //MaterialPageRoute(builder: (context) =>   AddExpenseScreen()),
                );
              }
          ),

          // Home Screen
        ];
      case 3:
        return [
          IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            NewIssue(newIssue: Issue.nullIssue(),insertMode:true

                              //insertMode: true,
                              //UploadingImageToFirebaseStorage()

                            )));
              }),
        ];
      case 1:
        return [
          IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>   AddExpenseScreen(expense: Expense.nullExpense(), editMode: false,)),);
              }),


        ];
      default:
        return [];
    // Settings Screen
    }
  }
  PreferredSizeWidget _buildAppBarTitle(int index, PropertyModel props) {

    switch (index) {
      case 0:
        return AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Income"),
              const SizedBox(width: 30),
              Expanded(
                child: TextField(
                  onChanged: (str) { myMethod.call(str);},
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFFFFFFF),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15.0),
                    /* -- Text and Icon -- */
                    hintText: "Search Units...",
                    hintStyle: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFFB3B1B1),
                    ), // TextStyle
                    suffixIcon: const Icon(
                      Icons.search,
                      size: 26,
                      color: Colors.black54,
                    ), // Icon
                    /* -- Border Styling -- */
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(45.0),
                      borderSide: const BorderSide(
                        width: 2.0,
                        color: Color(0xFFFF0000),
                      ), // BorderSide
                    ), // OutlineInputBorder
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(45.0),
                      borderSide: const BorderSide(
                        width: 2.0,
                        color: Colors.grey,
                      ), // BorderSide
                    ), // OutlineInputBorder
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(45.0),
                      borderSide: const BorderSide(
                        width: 2.0,
                        color: Colors.grey,
                      ), // BorderSide
                    ), // OutlineInputBorder
                  ), // InputDecoration
                ), // TextField
              ), // Expanded
            ],
          ),
          toolbarHeight: 55.0,

          elevation: 8,

        );


      case 2:
        return AppBar(
          title: const Text("Properties"),
          actions: getActions(_selectedIndex),
          elevation: 8,
        );
        break;
      case 1:
        return AppBar(
          title: const Text("Expenses"),
          actions: getActions(_selectedIndex),
          elevation: 8,
        );

      case 3:
        return AppBar(
          title: const Text("Repair"),
          actions: getActions(_selectedIndex),
          elevation: 8,
        );
    }
    return AppBar();
  }
  static List<Widget> _pages = <Widget>[
    Container(),
    AllExpensesPage(),
    ListViewHome(),

    IssuePage(),
    //RepairPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      print("index $index");
    });
  }
  Drawer getDrawer(int index, PropertyModel props) {

    switch (index) {
      case 0:
        return Drawer(
          child: SafeArea(
            right: false,
            child:
            Padding(
              padding: const EdgeInsets.all(1.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[

                  IconButton(onPressed: () {showPrevMonth(props);}, icon: Icon(Icons.skip_previous),),
                  Text(DateFormat("MMMM").format(DateFormat(PageStatics.DATE_FORMAT).parse(props.currentMonth)),
                      style:  TextStyle(fontSize: 16,fontStyle: FontStyle.italic,fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () {showNextMonth(props);}, icon: Icon(Icons.skip_next),),
                  SizedBox(width: 5,),

                  OutlinedButton(child: Text("Roll Month",style:  TextStyle(fontSize: 14,)),


                    onPressed: (){TransactionService.addAutoExpenses(props.allAutoCalculator, props);props.rollDate();  props.setTxMap();
                    setState(() {
                      props.currentMonth;
                    });},
                  ),
                ],
              ),


            ),

          ),
        );
      default:
        return Drawer();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyModel>(
        builder: (context, props, child) {
          return Scaffold(
            // appBar: AppBar(
            //
            //   // title: _buildAppBarTitle(_selectedIndex),
            //   // actions: getActions(_selectedIndex),
            //   // elevation: 8,
            // ),
              appBar: _buildAppBarTitle(_selectedIndex,props),
              body: Center(
                child: (_selectedIndex == 0) ? RentPaymentPage(builder: (BuildContext context, void Function(String) methodFromChild) {
                  myMethod = methodFromChild;
                },): _pages.elementAt(_selectedIndex),
                //_pages.elementAt(_selectedIndex),

              ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,

                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.currency_exchange_rounded),
                    label: 'Income',

                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.data_exploration_outlined),
                    label: 'Expenses',

                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_work_rounded),
                    label: 'Properties',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.account_balance_rounded),
                    label: 'Repair',
                  ),

                ],
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,

              ),
              drawer: getDrawer(_selectedIndex, props)

          );
        }
    );
  }
  void showNextMonth(PropertyModel props) {

   DateTime dt = DateFormat(PageStatics.DATE_FORMAT).parse(props.currentMonth);
    dt = DateTime(dt.year, dt.month +1, dt.day);
    props.currentMonth = DateFormat(PageStatics.DATE_FORMAT).format(dt);
    props.setTxMap();
    setState(() {
      props.currentMonth;
    });

  }
  void showPrevMonth(PropertyModel props) {
    DateTime dt = DateFormat(PageStatics.DATE_FORMAT).parse(props.currentMonth);
    dt = DateTime(dt.year, dt.month -1, dt.day);
    props.currentMonth = DateFormat(PageStatics.DATE_FORMAT).format(dt);
    props.setTxMap();
    setState(() {
      props.currentMonth;
    });
  }
}


/*
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:example/config.dart';
import 'package:flutter/material.dart';
import 'package:google_drive_client/google_drive_client.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  final GoogleDriveClient client = GoogleDriveClient(Dio(), getAccessToken: () async => Config.ACCESS_TOKEN);
  final String id = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            FlatButton(
              child: Text('list'),
              onPressed: () async {
                print(await client.list());
              },
            ),
            FlatButton(
              child: Text('create'),
              onPressed: () async {
                final File file = File((await getTemporaryDirectory()).path + '/testing2');
                file.writeAsStringSync("contents");
                var meta = GoogleDriveFileUploadMetaData(name: 'testing');
                print(await client.create(meta, file));
              },
            ),
            FlatButton(
              child: Text('delete'),
              onPressed: () async {
                await client.delete(id);
              },
            ),
            FlatButton(
              child: Text('download'),
              onPressed: () async {
                await client.download(id, 'testing');
              },
            ),
            FlatButton(
              child: Text('get'),
              onPressed: () async {
                print(await client.get(id));
              },
            ),
          ],
        ),
      ),
    );
  }
}
 */