
// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:my_app/model/property.dart';
import 'package:my_app/pages/PageStatics.dart';
import 'package:my_app/pages/addexpense.dart';
import 'package:my_app/pages/propertydetailspage.dart';
import 'package:my_app/pages/transactionpage.dart';
import 'package:provider/provider.dart';
import 'newissue.dart';
import 'newproperty.dart';
import 'dart:ui' as UI;


class AllExpensesPage extends StatefulWidget {
  const AllExpensesPage();

  @override
  _AllExpensesPage createState() => _AllExpensesPage();
}

class _AllExpensesPage extends State<AllExpensesPage> {
  late PropertyModel propertyModel;
  List<Expense>currentMonthExpenses=[];
  List<Property> propWithExpenses = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
   // super.didChangeDependencies();
    propertyModel = context.watch<PropertyModel>();
    DateTime dt = DateFormat(PageStatics.DATE_FORMAT).parse(
        propertyModel.currentMonth);
    DateTime nextMonth = DateTime(dt.year, dt.month+1, dt.day);
    currentMonthExpenses = propertyModel.allExpenses.where((
        element) => element.dateOfExpense.isAfter(dt) && element.dateOfExpense.isBefore(nextMonth)).toList();
    print("number of expense for ${dt} is : ${currentMonthExpenses.length}");
  }


  Widget _buildTotalCard(PropertyModel props) {
    propWithExpenses =[];
    NumberFormat numberFormat = NumberFormat("#,##0", "en_US");
    double totalExpenses = 0.0;
    props.allProps.forEach((property) {
      List<Expense> thisPropExpenses = getExpensesForProp(property);
      double expense = thisPropExpenses.fold(
          0.0, (previousValue, expense) => previousValue + expense.amount);
      if (expense > 0) {
        totalExpenses = totalExpenses + expense;
        this.propWithExpenses.add(property);
      }

    });


    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        //margin: EdgeInsets.all(10.0),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(

              height: 80,
              //width: MediaQuery
               //   .of(context)
              //    .size
               //   .width - 5,
              child: Center(child:Text("\$" + numberFormat.format(totalExpenses), style: TextStyle(fontSize: 24, color: Colors.red))),
          ),

        ],
      ),
    );
  }


  List<Expense> getExpensesForProp(Property prop) {
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
                      color: Colors.white10,
                      margin: EdgeInsets.all(2.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(1.0))),
                      elevation: 4,

                      child: _buildTotalCard(props),
                    ),
                    Expanded(
                        child:
                        ListView.builder(
                          // physics: NeverScrollableScrollPhysics(),
                            itemCount: propWithExpenses.length,
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
                                              title: _buildTitle((getExpensesForProp(propWithExpenses[index])), propWithExpenses[index]),
                                              //subtitle: ,
                                              //trailing: SizedBox(width: 1,),
                                              children: getTransactionList((getExpensesForProp(propWithExpenses[index])), props
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
            MaterialPageRoute(builder: (context) =>  expense.category != "Repair" ?  AddExpenseScreen(expense: expense,editMode: true):
            NewIssue(newIssue: propertyModel.getIssue(expense.issueId),insertMode:false

              //insertMode: true,
              //UploadingImageToFirebaseStorage()

            )));},
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
    if (totalExpenses > 0)
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
    return Container();


  }
}