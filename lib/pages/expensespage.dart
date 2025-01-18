
// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:my_app/model/property.dart';
import 'package:my_app/pages/PageStatics.dart';
import 'package:my_app/pages/propertydetailspage.dart';
import 'package:provider/provider.dart';
import 'newproperty.dart';
import 'dart:ui' as UI;


class AllExpensesPage extends StatefulWidget {
  const AllExpensesPage();

  @override
  _AllExpensesPage createState() => _AllExpensesPage();
}

class _AllExpensesPage extends State<AllExpensesPage> {
  late PropertyModel propertyModel;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    propertyModel = context.watch<PropertyModel>();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyModel>(builder: (context, props, child) {
      //print("length of all props ${props.allCards.length}");
      return ListView.builder(
          itemCount: props.allProps.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                print("tapped");
              },
              child: buildCard(props.allProps[index], context),
            );
          });
    });
  }

  Card buildCard(Property property, BuildContext context) {
    print('property ${property.id}');
    List<Unit> allUnits = List<Unit>.generate(property.unitIds.length,
            (index) => propertyModel.getUnit(property.unitIds[index]));

    List<Expense> thisYrsExpenses = propertyModel.allExpenses.where((element) => element.dateOfExpense.isAfter(DateTime(DateTime.now().year-1,12,31))).toList();
    List<PropertyTransaction> ytdIncomeList = [];



    List<Issue> ytdExpensesList = [];

    double ytdIncome = ytdIncomeList.fold(0.0,(previousValue, element) => previousValue + element.amount );
    double ytdExpense = ytdExpensesList.fold(0.0,(previousValue, element) => previousValue + element.laborCost + element.materialCost );
    double net = ytdIncome - ytdExpense;
    var subheading = '\$${360000.toStringAsFixed(0)} per month';
    var heading = "${property.name} - ${allUnits.length} Unit";

    final oCcy =  NumberFormat("#,##0", "en_US");
/*
void main () {

  print("Eg. 1: ${oCcy.format(123456789.75)}");
     */

    return Card(
        elevation: 4.0,
        child: Column(
          children: [
            ListTile(

              title: Text(heading, style: TextStyle(fontSize:16)),
              subtitle: Text("\$${oCcy.format(35000)} per month", style: TextStyle(color: Colors.blue)),
              trailing: Column(children: [Text(""),
                Text("YTD Net \$${oCcy.format(net)}", style: TextStyle(color: Colors.blue,fontSize: 14)),
              ]),
            ),
            Container(
              height: 140.0,
              child: Ink.image(
                image: CachedNetworkImageProvider(property.pictureURL),
                fit: BoxFit.cover,
              ),
            ),
            Container(
                padding: EdgeInsets.all(16.0),
                alignment: Alignment.centerLeft,
                child: Column(children: [
                  Row(children: [
                    Text("YTD Income"),
                    Spacer(),
                    Text(
                      "\$${ytdIncome.toStringAsFixed(0)}",
                      style: TextStyle(color: Colors.blue),
                    )
                  ]),
                  Divider(),
                  Row(children: [
                    Text("YTD Expense"),
                    Spacer(),
                    Text(
                      "\$${ytdExpense.toStringAsFixed(0)}",
                      style: TextStyle(color: Colors.blue),
                    )
                  ])
                ])),
            ButtonBar(
              children: [
                TextButton(
                  child: const Text('Edit Property'),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NewProperty(
                              rentable: RentableModel.nullCardViewModel(),
                              insertMode: false,
                            )));
                  },
                ),
                Directionality(
                  textDirection: UI.TextDirection.ltr,
                  child: TextButton.icon(
                    onPressed: () {
                      print('share');
                    },
                    icon: Icon(
                      Icons.share,
                      color: Colors.green,
                    ),
                    label: Text(
                      "Share",
                      style: TextStyle(color: Color(0xFF6200EE)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ));
  }
}

     /* ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: box.length, // Number of transactions
              itemBuilder: (context, index) {
                // Retrieve the transaction at the current index
                final transaction = box.getAt(index) as Transaction;
                final isIncome =
                    transaction.isIncome; // Check if it's an income
                final formattedDate = DateFormat.yMMMd()
                    .format(transaction.date); // Format the date

                // Display each transaction inside a card
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  child: ListTile(
                    leading: Icon(
                      isIncome
                          ? Icons.arrow_upward
                          : Icons
                              .arrow_downward, // Icon depending on transaction type
                      color: isIncome
                          ? Colors.green
                          : Colors.red, // Color for income/expense
                    ),
                    title: Text(
                      transaction.category, // Transaction category name
                      // style: theme.textTheme.subtitle1, // Optional text styling
                    ),
                    subtitle: Text(formattedDate), // Formatted transaction date
                    trailing: Text(
                      isIncome
                          ? '+ \$${transaction.amount.toStringAsFixed(2)}' // Display income with plus sign
                          : '- \$${transaction.amount.toStringAsFixed(2)}', // Display expense with minus sign
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isIncome
                            ? Colors.green
                            : Colors.red, // Color based on transaction type
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      )*/