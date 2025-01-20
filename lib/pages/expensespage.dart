
// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:my_app/model/property.dart';
import 'package:my_app/pages/PageStatics.dart';
import 'package:my_app/pages/addexpense.dart';
import 'package:my_app/pages/propertydetailspage.dart';
import 'package:my_app/pages/transactionpage.dart';
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
  Widget buildOld(BuildContext context) {
    DateTime dt = DateFormat(PageStatics.DATE_FORMAT).parse(
        propertyModel.currentMonth);
    List<Expense> currentMonthExpenses = propertyModel.allExpenses.where((
        element) => element.dateOfExpense.isAfter(dt)).toList();
    List<PropertyTransaction> ytdIncomeList = [];


    List<Issue> ytdExpensesList = [];

    double ytdIncome = ytdIncomeList.fold(
        0.0, (previousValue, element) => previousValue + element.amount);
    double ytdExpense = currentMonthExpenses.fold(
        0.0, (previousValue, element) => previousValue + element.amount);
    double net = ytdIncome - ytdExpense;


    final oCcy = NumberFormat("#,##0", "en_US");
    return Consumer<PropertyModel>(builder: (context, props, child) {
      //print("length of all props ${props.allCards.length}");

      return Container(
        child: Column(
          children: [
            Card(child: Text("Total ${ytdExpense}")),
            ListView.builder(
                itemCount: props.allProps.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      print("tapped");
                    },
                    child: Column(
                        children: [

                          buildTotalCard(props.allProps[index], context,
                              currentMonthExpenses)
                        ]),
                  );
                }),
          ],
        ),
      );
    });
  }

  Card buildTotalCard(Property property, BuildContext context,
      List<Expense> currentExpenses) {
    print('property ${property.id}');


    List<Expense> thisPropExpenses = currentExpenses.where((element) =>
    element.propertyId == property.id).toList();
    double totalExpenses = thisPropExpenses.fold(
        0.0, (previousValue, element) => previousValue + element.amount);
    return Card(
        color: Colors.grey,
        margin: EdgeInsets.all(2.0),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(1.0))),
        elevation: 8,

        child: Column(
            children: [
              Text("${property.name } ${totalExpenses}")
            ]
        ));
  }


  Widget _buildTotalCard(PropertyModel props) {
    int totalPaidInFull = 0;
    double totalExpected = 0.0;
    double received = 0.0;
    double balance = 0.0;
    NumberFormat numberFormat = NumberFormat("#,##0", "en_US");


    for (int i = 0; i < props.txMap.length; i++) {
      if (props.txMap[i].balance == 0) ++totalPaidInFull;
      totalExpected =
          totalExpected + props.txMap[i].rent + props.txMap[i].totalCredit;
      received = received + props.txMap[i].totalDebit;
      if (props.txMap[i].balance < 0)
        balance = balance + props.txMap[i].balance;
    }
    //balance = totalExpected - received;
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        //margin: EdgeInsets.all(10.0),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(

              height: 150,
              width: MediaQuery
                  .of(context)
                  .size
                  .width - 5,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildUserStatsItem(
                        "${props.txMap.length}",
                        "Unit Rented",
                        "\$${(numberFormat.format(totalExpected))}",
                        "Expected",
                        Colors.blue[200]!,
                        0,
                        props),
                    _buildUserStatsItem(
                        "${totalPaidInFull}",
                        "Paid Full",
                        "\$${(numberFormat.format(received))}",
                        "Received",
                        Colors.green[200]!,
                        1,
                        props),
                    _buildUserStatsItem(
                        "${props.txMap.length - totalPaidInFull}",
                        "Partially Paid",
                        "\$${(numberFormat.format(balance.abs()))}",
                        "Balance",
                        Colors.purple[200]!,
                        2,
                        props),
                  ])
          ),

        ],
      ),
    );
  }

  _buildUserStatsItem(String s, String t, String s2, String t2, Color c,
      int index, PropertyModel prop) {
    return InkWell(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: c,
          border: Border.all(color: Colors.blue, width: 3),
        ),
        height: 130,
        width: (MediaQuery
            .of(context)
            .size
            .width / 3) - 15,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(s, style: TextStyle(fontSize: 16, color: Colors.black)),
            SizedBox(height: 5),
            Text(t, style: TextStyle(
                fontSize: 14, color: Colors.black.withOpacity(.7))),
            SizedBox(height: 10,),
            Text(s2, style: TextStyle(fontSize: 16, color: Colors.black)),
            SizedBox(height: 5),
            Text(t2, style: TextStyle(
                fontSize: 14, color: Colors.black.withOpacity(.7))),

          ],
        ),
      ),
    );
  }

  List<Expense> getExpensesForProp(Property prop) {
    DateTime dt = DateFormat(PageStatics.DATE_FORMAT).parse(
        propertyModel.currentMonth);
    DateTime nextMonth = DateTime(dt.year, dt.month+1, dt.day);
    List<Expense> currentMonthExpenses = propertyModel.allExpenses.where((
        element) => element.dateOfExpense.isAfter(dt) && element.dateOfExpense.isBefore(nextMonth)).toList();
    List<Expense> thisPropExpenses = currentMonthExpenses.where((element) =>
    element.propertyId == prop.id).toList();
    return thisPropExpenses;
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyModel>(
        builder: (context, props, child) {
          return Container(
            //elevation: 6,
            //margin: EdgeInsets.all(4.0),
              child:
              //print("length of all props ${props.allCards.length}");
              Column(
                  children: [
                    Card(
                      color: Colors.grey,
                      margin: EdgeInsets.all(2.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(1.0))),
                      elevation: 8,

                      child: _buildTotalCard(props),
                    ),
                    Expanded(
                        child:
                        ListView.builder(
                          // physics: NeverScrollableScrollPhysics(),
                            itemCount: props.allProps.length,
                            itemBuilder: (context, index) {
                              return InkWell(

                                  child: Center(
                                      child:
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 1),
                                        child: Card(
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(15.0))),
                                          elevation: 3,
                                          margin: EdgeInsets.all(4.0),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: ExpansionTile(
                                              backgroundColor: Colors.white,
                                              title: _buildTitle((getExpensesForProp(props.allProps[index])), props.allProps[index]),
                                              //subtitle: ,
                                              //trailing: SizedBox(width: 1,),
                                              children: getTransactionList((getExpensesForProp(props.allProps[index])), props
                                              ),
                                            ),
                                          ),
                                        ),


                                      )

                                  )
                              );
                            })),
                  ]
              )
          );
        }
    );
  }

  List<Widget> getTransactionList(List<Expense> expenses, PropertyModel props) {
    List<Widget> retVal = [];
    for (Expense item in expenses ) {
      //bool credit = (PageStatics.CREDIT_FOR_DEBIT_OR_CREDIT == item.debitOrCredit);
      retVal.add(_buildTxTitle(item));
    }
    //retVal.add(_buildTxTitleTail(tx, props));
    return retVal;
  }

  Widget _buildTxTitle(Expense expense) {
    return Card(

      //color: Colors.light,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(1.0))),
      elevation: 1,
      margin: EdgeInsets.all(1),
      //onPress: () {},

      child: InkWell(
        onTap: () {Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  AddExpenseScreen(expense: expense,editMode: true)));},
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Row(
                    children: <Widget>[
                      Text("${expense.category} ",
                        style: const TextStyle(fontSize: 14,),),
                      Spacer(flex: 1),
                      Text("\$${expense.amount.toStringAsFixed(2)} ",
                        //@todo get rent
                        style: const TextStyle(fontSize: 14,),
                      )
                    ]),
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Row(
                  children: <Widget>[

                    Text(" ${DateFormat(PageStatics.DATE_IN_TX_PAGE).format(expense.dateOfExpense)}",
                        style: const TextStyle(fontSize: 14)),
                    Spacer(flex: 1),

                    Text("${expense.amount.toStringAsFixed(2)} ",
                        //@todo get rent
                        style: const TextStyle(fontSize: 14,)),
                  ],
                ),
              ),
              // Text(""),


            ],
          ),
        ),
      ),
    );


  }
  Widget _buildTitle(List<Expense> expenses, Property prop) {
    // Tenant tenant = props.getTenantForTxSummary(tx);
    double totalExpenses = expenses.fold(
        0.0, (previousValue, element) => previousValue + element.amount);
    return Container(

      //width: MediaQuery.of(context).size.width * 0.95,

      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(prop.name,
                    style: const TextStyle(fontSize: 16,fontWeight: FontWeight.bold) ,),
                  Spacer(),
                  Text("\$${(totalExpenses).abs().toStringAsFixed(0)} ",
                    //@todo get rent
                    style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: (totalExpenses < 0 ? Colors.red : Colors.black)),),
                  //@todo get rent


                ],
              ),
            ),]),)


    );


  }
}