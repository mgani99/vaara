// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:my_app/model/property.dart';
import 'package:my_app/pages/PageStatics.dart';
import 'package:provider/provider.dart';
import 'newproperty.dart';
import 'dart:ui' as UI;


class ListViewHome extends StatefulWidget {
  const ListViewHome();

  @override
  _ListViewHome createState() => _ListViewHome();
}

class _ListViewHome extends State<ListViewHome> {
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

    List<RentableModel> allRentable = propertyModel.allCards
        .where((element) => element.propId == property.id)
        .toList();
    var totalRent = allRentable.fold(0.0, (sum, next) => sum + next.rent);
    List<PropertyTransaction> thisYrsTx = propertyModel.allTxs.where((element) => element.dateOfTx.isAfter(DateTime(DateTime.now().year-1,12,31)) && 
        element.dateOfTx.isBefore(DateTime(DateTime.now().year+1,1,1)) && element.debitOrCredit == PageStatics.DEBIT_FOR_DEBIT_OR_CREDIT).toList();
    List<PropertyTransaction> ytdIncomeList = [];


    List<Issue> thisYrsExpenses = propertyModel.allIssues..where((element) => element.dateOfIssue.isAfter(DateTime(DateTime.now().year-1,12,31)) &&
        element.dateOfIssue.isBefore(DateTime(DateTime.now().year+1,1,1)) && element.status == PageStatics.COMPLETE_FOR_ISSUETYPEVALUE).toList();
    List<Issue> ytdExpensesList = [];
    allRentable.forEach((rent_element) {
      ytdIncomeList.addAll(thisYrsTx.where((element) => element.rentableId == rent_element.id).toList());
      ytdExpensesList.addAll(thisYrsExpenses.where((element) => element.rentableId == rent_element.id).toList());
    });
    double ytdIncome = ytdIncomeList.fold(0.0,(previousValue, element) => previousValue + element.amount );
    double ytdExpense = ytdExpensesList.fold(0.0,(previousValue, element) => previousValue + element.laborCost + element.materialCost );
    double net = ytdIncome - ytdExpense;
    var subheading = '\$${totalRent.toStringAsFixed(0)} per month';
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
              subtitle: Text("\$${oCcy.format(totalRent)} per month", style: TextStyle(color: Colors.blue)),
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
                                  rentable: allRentable[0],
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
