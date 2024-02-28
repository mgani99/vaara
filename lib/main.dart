


// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs


import 'package:my_app/model/property.dart';
import 'package:my_app/pages/allproperty.dart';
import 'package:my_app/pages/expense.dart';
import 'package:my_app/pages/login.dart';
import 'package:my_app/pages/newissue.dart';
import 'package:my_app/pages/newproperty.dart';
import 'package:my_app/pages/rentpayment.dart';
import 'package:my_app/pages/repair.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';



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

  List<Widget> getActions(int body) {
    switch (body) {
      case 1:
        return [
          IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>   NewProperty(rentable: RentableModel.nullCardViewModel(), insertMode: true,)),
                );
              }
          ),

         // Home Screen
          ];
      case 2:
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
      default:
        return [];
        // Settings Screen
    }
  }
  PreferredSizeWidget _buildAppBarTitle(int index, PropertyModel props) {


    switch (index) {
      case 0:
        return AppBar(
          title: const Text("Income"),
          toolbarHeight: 55.0,

          elevation: 8,
          );


      case 1:
        return AppBar(
          title: const Text("Properties"),
          actions: getActions(_selectedIndex),
          elevation: 8,
        );
        break;
      case 2:
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
  static const List<Widget> _pages = <Widget>[

    RentPaymentPage(),
    ListViewHome(),
    //ExpensesPage(),
    RepairPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      print("index $index");
    });
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
              child: _pages.elementAt(_selectedIndex),
            ),
            bottomNavigationBar: BottomNavigationBar(

              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.currency_exchange_rounded),
                  label: 'Income',

                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_work_rounded),
                  label: 'Properties',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_rounded),
                  label: 'Expenses',
                ),

              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,

            ),
          );
        }
    );
  }
}
/*


import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      /*theme: ThemeData(
        r: Colors.blue,
      ),*/
      home: MyHomePage(),
    );
  }
}




class MyHomePage extends StatelessWidget {
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(

              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.all(Radius.circular(15.0))),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.home_repair_service_outlined),
                    title: const Text('37-54 89th St, Apt 1'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[Text(
                      'Plumbing Issue' ,style: TextStyle(color: Colors.black.withOpacity(0.8)),),
                      Text(
                        'Contractor: Jose' ,style: TextStyle(color: Colors.black.withOpacity(0.8)),),
                    ],

                    ),
                    trailing: Column(children:[Text("Jan 24th, 2004",style: TextStyle(color: Colors.black.withOpacity(0.8),fontSize: 14),
                    ),Text("\$200",style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 14),)]),
                    //isThreeLine: true,

                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Bathroom plumbing was leaking, required a new plumbing line',
                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                    ),
                  ),
                  ButtonBar(
                    alignment: MainAxisAlignment.start,
                    children: [
                      TextButton(


                        onPressed: () {
                          // Perform some action
                        },
                        child: const Text('ACTION 1', style: TextStyle(color:  Color(0xFF6200EE),)),
                      ),
                      TextButton(
                        //textColor: const Color(0xFF6200EE),
                        onPressed: () {
                          // Perform some action
                        },
                        child: const Text('ACTION 2', style: TextStyle(color:  Color(0xFF6200EE),)),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ExpansionTile(

                      backgroundColor: Colors.white,
                      title: Row(children :[SizedBox(width: 90,), Text('Show Images', style: TextStyle(color:  Color(0xFF6200EE),))]),
                      //subtitle: ,
                      trailing: SizedBox(width: 1,),
                      children: getImages(),


                    ),
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.all(Radius.circular(15.0))),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.arrow_drop_down_circle),
                    title: const Text('Card title 2'),
                    subtitle: Text(
                      'Secondary Text',
                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Greyhound divisively hello coldly wonderfully marginally far upon excluding.',
                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                    ),
                  ),
                  ButtonBar(
                    alignment: MainAxisAlignment.start,
                    children: [
                      TextButton(
                        //textColor: const Color(0xFF6200EE),
                        onPressed: () {
                          // Perform some action
                        },
                        child: const Text('ACTION 1', style: TextStyle(color:  Color(0xFF6200EE),)),
                      ),
                      TextButton(
                       // textColor: const Color(0xFF6200EE),
                        onPressed: () {
                          // Perform some action
                        },
                        child: const Text('ACTION 2', style: TextStyle(color:  Color(0xFF6200EE),)),
                      ),
                    ],
                  ),
                  Image.asset('assets/home2.png'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> getImages() {
    print('getting');
    return [
      Card(child:Image.asset('assets/home2.png')),
      Card(child: Image.asset('assets/home2.png')),
    ];
  }
}
*/
