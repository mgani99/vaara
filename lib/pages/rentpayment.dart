// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:js/js.dart';
import 'package:flutter/material.dart';
import 'package:my_app/model/property.dart';
import 'package:my_app/pages/PageStatics.dart';
import 'package:my_app/pages/transactionpage.dart';
import 'package:provider/provider.dart';

import '../services/TransactionService.dart';

class RentPaymentPage extends StatefulWidget {

  const RentPaymentPage();
  @override
  RentPaymentHome createState() => RentPaymentHome();
}
class RentPaymentHome extends State<RentPaymentPage> {

  //DateTime currentMonth = DateTime.now();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  @override
  Widget build(BuildContext context) {


    return Consumer<PropertyModel>(
        builder: (context,props, child) {

          return Container(
           // elevation: 6,
          //margin: EdgeInsets.all(4.0),
               child:
               //print("length of all props ${props.allCards.length}");
           Column(
             children: [
               Card(
                 color: Colors.greenAccent,
                 margin: EdgeInsets.all(12.0),
                 shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.all(Radius.circular(2.0))),
                elevation: 8,

                 child: _buildTtotalCard(props),
               ),
               Expanded(
                   child:
              ListView.builder(
                 // physics: NeverScrollableScrollPhysics(),
                itemCount: props.txMap.length,
                itemBuilder: (context, index) {
                  return InkWell(
                  onDoubleTap: ()   {
                    TransactionSummary txSummary = props.txMap[index];
                    if (txSummary.balance *-1== txSummary.rent) {

                      PropertyTransaction atx = PropertyTransaction(
                          debitOrCredit: PageStatics
                              .DEBIT_FOR_DEBIT_OR_CREDIT,
                          transactionType: PageStatics
                              .RENT_FOR_PAYMENTTYPEVALUE,
                          rentableId: txSummary.rentableId,
                          dateOfTx: DateFormat(PropertyModel.PAYMENT_DATE_FORMAT)
                              .parse(DateFormat(PropertyModel.PAYMENT_DATE_FORMAT).format(DateTime.now())),

                          amount: txSummary.rent,
                          payingMethod: "Zelle",
                          paidBy: props
                              .getTenantForTxSummary(txSummary)
                              .id,
                          balance: 0.0,
                          comment: "Paid through Default method");
                      TransactionService.insertTransaction(
                          txSummary, atx, props);
                    }
                    else if (txSummary.txs.length == 1 &&
                    PageStatics.DEBIT_FOR_DEBIT_OR_CREDIT == txSummary.txs[0].debitOrCredit && txSummary.balance == 0.0){
                      TransactionService.deleteTransaction(txSummary, txSummary.txs[0], props);
                    }

                    },
                  child: Center(
                      child:
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(15.0))),
                          elevation: 6,
                          margin: EdgeInsets.all(6.0),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ExpansionTile(
                              backgroundColor: Colors.white,
                              title: _buildTitle(props.txMap[index], props),
                              //subtitle: ,
                              trailing: SizedBox(width: 1,),
                              children: getTransactionList(props.txMap[index],props),
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




    List<Widget> getTransactionList(TransactionSummary tx, PropertyModel props) {
    List<Widget> retVal = [];
    for (PropertyTransaction item in tx.txs) {
      bool credit = (PageStatics.CREDIT_FOR_DEBIT_OR_CREDIT == item.debitOrCredit);
      retVal.add(_buildTxTitle(tx,item));
     }
    return retVal;
  }

  Widget _buildTxTitle(TransactionSummary txSummary, PropertyTransaction tx) {
    return Card(

      //color: Colors.light,
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Row(
                children: <Widget>[
                  Text(" ${tx.transactionType} " ,
                    style: const TextStyle(fontSize: 14,),),
                  Spacer(flex: 2),
                  Text(" ${tx.debitOrCredit}   : \$${tx.amount.toStringAsFixed(2)} ",
                    //@todo get rent
                    style: const TextStyle(fontSize: 14,),
                  ),
                ],
              ),
            ),
          // Text(""),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                  children: <Widget>[
                    Text(" ${DateFormat(PageStatics.DATE_IN_TX_PAGE).format(tx.dateOfTx)}",
                        style: const TextStyle(fontSize: 14)),
                    Spacer(flex: 2),
                    Text("Balance : ${tx.balance.toStringAsFixed(2)} ",
                        //@todo get rent
                        style: const TextStyle(fontSize: 14,)),
                  ]),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children:[
                  Spacer(),
                  TextButton(onPressed: (){Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>  TransactionPage(tx_summary : txSummary, prop_tx: tx,
                          tenant: Tenant.nullTenant(),editMode: true)));}, child: Text("Edit")),

              ]

              ),
            )
          ],
        ),
      ),
    );


  }

  Widget _buildTtotalCard( PropertyModel props) {

    int totalPaidInFull = 0;
    double totalExpected = 0.0;
    double received = 0.0;
    double balance = 0.0;


    for (int i=0;i<props.txMap.length;i++) {
        if (props.txMap[i].balance == 0) ++totalPaidInFull;
        totalExpected = totalExpected + props.txMap[i].rent + props.txMap[i].totalCredit;
        received = received + props.txMap[i].totalDebit;
    }
    balance = totalExpected - received;
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        //margin: EdgeInsets.all(10.0),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Spacer(),
                IconButton(onPressed: () {showPrevMonth(props);}, icon: Icon(Icons.skip_previous),),
                Text(DateFormat("MMMM").format(DateFormat(PageStatics.DATE_FORMAT).parse(props.currentMonth)),
                    style:  TextStyle(fontSize: 16,fontStyle: FontStyle.italic,fontWeight: FontWeight.bold)),
                IconButton(onPressed: () {showNextMonth(props);}, icon: Icon(Icons.skip_next),),
                Spacer(),

              ],
            ),


          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Spacer(),

                TextButton(child: Text("Roll", style:  TextStyle(fontSize: 14,fontStyle: FontStyle.italic,fontWeight: FontWeight.bold)),
                    onPressed: (){props.rollDate();  props.setTxMap();
                    setState(() {
                      props.currentMonth;
                    });},
                    ),

                Spacer(),

              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text("Total Rentables: ${props.allCards.length} " ,
                  style: const TextStyle(fontSize: 14,),),
                Spacer(),
                Text("Paid in Full: ${totalPaidInFull}",
                  style: const TextStyle(fontSize: 14,),),
                //@todo get rent


              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text("Expected:\$${ totalExpected.toStringAsFixed(0)} " ,
                  style: const TextStyle(fontSize: 14,),),
                Spacer(),
                Text("Recieved :\$${received.toStringAsFixed(0)}", style: const TextStyle(fontSize: 14,),),
                //@todo get rent


              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text("Remaining \$${balance.toStringAsFixed(0)}" ,
                  style:  TextStyle(fontSize: 16,fontStyle: FontStyle.italic,fontWeight: FontWeight.bold)),
                Spacer(),
                Text("Remaining : ${(balance/totalExpected*100).toStringAsFixed(0)}%",
                  style: const TextStyle(fontSize: 16,fontStyle: FontStyle.italic,fontWeight: FontWeight.bold),),
                //@todo get rent


              ],
            ),
          ),
          //Text(""),



        ],
      ),
    );


  }

  Widget _buildTitle(TransactionSummary tx, PropertyModel props) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text("${tx.rentableName} " ,
              style: const TextStyle(fontSize: 16,fontWeight: FontWeight.bold) ,),
            Text(""),
              //@todo get rent


          ],
        ),
        Divider(
            color: Colors.black,
          endIndent: 2,
          thickness: 1,
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text("Rent:${tx.rent.toStringAsFixed(2)}" ,
                style: const TextStyle(fontSize: 14,),),
              Spacer(),
              Text("Due: ${(tx.totalCredit + tx.rent).toStringAsFixed(2)}", style: const TextStyle(fontSize: 14,),),
              //@todo get rent


            ],
          ),
        ),
        //Text(""),
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text("Adjust: ${tx.totalCredit.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 14)),
                Spacer(),
                Text(" Paid: ${tx.totalDebit.toStringAsFixed(2)}",
                    //@todo get rent
                    style: const TextStyle(fontSize: 14,)),
              ]),
        ),

        Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              TextButton(child: Text("Add", style: const TextStyle(fontSize: 14,)),onPressed: () {
                Tenant tenant = props.getTenantForTxSummary(tx);
                Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  TransactionPage(tx_summary: tx, prop_tx: PropertyTransaction(transactionType: "Rent",
                    rentableId: tx.rentableId, payingMethod: "Zelle", paidBy: tenant.id, dateOfTx: DateTime.now(),amount: 0.0, comment: "", debitOrCredit: "Debit", balance: 0.0 ),
                  tenant: tenant,editMode: false)));}),

              Spacer(),
              Text("Balance: ${tx.balance.toStringAsFixed(2)} ",
                  //@todo get rent
                  style:  TextStyle(fontSize: 14,color: (tx.balance < 0 ? Colors.red : Colors.black)),),
              Icon(Icons.arrow_drop_down)
            ]),

      ],
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





