// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:my_app/model/property.dart';
import 'package:my_app/pages/PageStatics.dart';
import 'package:my_app/pages/smsmsgpage.dart';
import 'package:my_app/pages/transactionpage.dart';
import 'package:provider/provider.dart';
import 'package:my_app/pages/leasedetailspage.dart';

import '../services/TransactionService.dart';
typedef MyBuilder = void Function(
    BuildContext context, void Function(String) methodFromChild);
class RentPaymentPage extends StatefulWidget {
  final MyBuilder builder;

  const RentPaymentPage({Key? key, required this.builder}) : super(key: key);
  @override
  RentPaymentHome createState() => RentPaymentHome();
}
class RentPaymentHome extends State<RentPaymentPage> {
  //DateTime currentMonth = DateTime.now();
  late PropertyModel props;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();


  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    props = context.watch<PropertyModel>();
  }
  String key = "";
  void childMethod(String searchVal) {
    setState(() {key=searchVal;getTxSummaryListFiltered(searchVal, props);filtering;});
  }
  @override
  Widget build(BuildContext context) {
    widget.builder.call(context, childMethod);

    return Consumer<PropertyModel>(
        builder: (context,props, child) {

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
                itemCount:  (filtering ? listOfSearchFilter : getTxSummaryList(props) ).length,
                itemBuilder: (context, index) {
                  return InkWell(
                  onDoubleTap: ()   {
                    TransactionSummary txSummary = (filtering ? listOfSearchFilter :  getTxSummaryList(props))[index];
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
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(15.0))),
                          elevation: 3,
                          margin: EdgeInsets.all(4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ExpansionTile(
                              backgroundColor: Colors.white,
                              title: _buildTitle((filtering? listOfSearchFilter : getTxSummaryList(props))[index],props),
                              //subtitle: ,
                              //trailing: SizedBox(width: 1,),
                              children:
                              getTransactionList((filtering? listOfSearchFilter : getTxSummaryList(props))[index],props),
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
    retVal.add(_buildTxTitleTail(tx, props));
    return retVal;
  }

  Widget _buildTxTitle(TransactionSummary txSummary, PropertyTransaction tx) {
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
            MaterialPageRoute(builder: (context) =>  TransactionPage(tx_summary : txSummary, prop_tx: tx,
                tenant: Tenant.nullTenant(),editMode: true)));},
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Row(
                    children: <Widget>[
                      Text(getTransactionDetails( tx.transactionType,tx.debitOrCredit),
                        style: const TextStyle(fontSize: 14,),),
                      Spacer(flex: 1),
                      Text("\$${tx.amount.toStringAsFixed(2)} ",
                        //@todo get rent
                        style: const TextStyle(fontSize: 14,),
                      )
                    ]),
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Row(
                  children: <Widget>[

                    Text(" ${DateFormat(PageStatics.DATE_IN_TX_PAGE).format(tx.dateOfTx)}",
                        style: const TextStyle(fontSize: 14)),
                    Spacer(flex: 1),

                    Text("${tx.balance.toStringAsFixed(2)} ",
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


  Widget _buildTotalCard( PropertyModel props) {

    int totalPaidInFull = 0;
    double totalExpected = 0.0;
    double received = 0.0;
    double balance = 0.0;
    NumberFormat numberFormat = NumberFormat("#,##0", "en_US");


    for (int i=0;i<props.txMap.length;i++) {
        if (props.txMap[i].balance == 0) ++totalPaidInFull;
        totalExpected = totalExpected + props.txMap[i].rent + props.txMap[i].totalCredit;
        received = received + props.txMap[i].totalDebit;
        if (props.txMap[i].balance < 0)
          balance = balance +props.txMap[i].balance;
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
              width :  MediaQuery.of(context).size.width-5,
              child:  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:[
                    _buildUserStatsItem("${props.txMap.length}", "Unit Rented", "\$${(numberFormat.format(totalExpected))}", "Expected",Colors.blue[200]!, 0, props),
                    _buildUserStatsItem("${totalPaidInFull}", "Paid Full", "\$${(numberFormat.format(received))}", "Received",Colors.green[200]!,1,props),
                    _buildUserStatsItem("${props.txMap.length - totalPaidInFull}", "Partially Paid", "\$${(numberFormat.format(balance.abs()))}", "Balance", Colors.purple[200]!,2,props),
                  ])
          ),

        ],
      ),
    );


  }
   int chosenBox = 0;
  _buildUserStatsItem(String s, String t, String s2, String t2, Color c, int index, PropertyModel prop) {

    return InkWell(
      onTap: () { setState(() {chosenBox = index;getTxSummaryList(prop);getTxSummaryListFiltered(key, props);

      });},
      child: Container(
        decoration: BoxDecoration(
          color: c,
          border: chosenBox == index?  Border.all(color: Colors.blue, width: 3) :Border.all(color: Colors.white) ,
        ),
        height: 130,
        width: (MediaQuery.of(context).size.width/3)-15,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(s, style: TextStyle(fontSize: 16, color: Colors.black)),
            SizedBox(height: 5),
            Text(t, style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(.7))),
            SizedBox(height: 10,),
            Text(s2, style: TextStyle(fontSize: 16, color: Colors.black)),
            SizedBox(height: 5),
            Text(t2, style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(.7))),

          ],
        ),
      ),
    );
  }

  bool filtering = false;
  List<TransactionSummary> listOfSearchFilter = [];
  List<TransactionSummary> getTxSummaryListFiltered(String key, PropertyModel props) {
    listOfSearchFilter = [];
    if (key.length >= 2)
      filtering = true;
    else {
      filtering = false;key="";
      return listOfSearchFilter = [];
      }
      listOfTxSummaryToShow.forEach((element) {
        if (element.tokens[key.toUpperCase()] == 1) { //first search by unit names, then tenant name
          listOfSearchFilter.add(element);
        }
        else {
          Tenant tenant = props.getTenantForTxSummary(element);
          if (tenant.tokens[key.toUpperCase()] ==1) {
            listOfSearchFilter.add(element);
          }
        }
      });
      return listOfSearchFilter;
    }


  List<TransactionSummary> listOfTxSummaryToShow = [];
  List<TransactionSummary> getTxSummaryList(PropertyModel props) {
    listOfTxSummaryToShow = props.txMap;
    if (chosenBox == 1) {
      listOfTxSummaryToShow =
          props.txMap.where((element) => element.balance >= 0).toList();
    }
    else if (chosenBox == 2) {
      listOfTxSummaryToShow =
          props.txMap.where((element) => element.balance < 0).toList();
    }

    return listOfTxSummaryToShow;
  }

  Widget _buildTxTitleTail(TransactionSummary tx, PropertyModel props) {
    return Card(

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
                    IconButton(
                      //  label: Text("", style: const TextStyle(fontSize: 12,)),
                        onPressed: () {
                          Tenant tenant = props.getTenantForTxSummary(tx);
                          Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>  TransactionPage(tx_summary: tx, prop_tx: PropertyTransaction(transactionType: "Rent",
                              rentableId: tx.rentableId, payingMethod: "Zelle", paidBy: tenant.id, dateOfTx: DateTime.now(),amount: 0.0, comment: "", debitOrCredit: "Debit", balance: 0.0 ),
                              tenant: tenant,editMode: false)));},
                          icon: const Icon(Icons.monetization_on_sharp),),
                    Spacer(flex: 1),
                    IconButton(
                      //label: Text("",  style: const TextStyle(fontSize: 12,)),
                      onPressed: () {
                        Tenant tenant = props.getTenantForTxSummary(tx);
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>  LeaseDetailsPage(leaseDetails: props.getLeaseDetailsForTxSummary(tx),
                                tenant: tenant,editMode: false)));},
                      icon : const Icon(Icons.edit_document)

                    ),

                    Spacer(flex: 1),
                    IconButton(
                        //label: Text("",  style: const TextStyle(fontSize: 12,)),
                        onPressed: () {
                          Tenant tenant = props.getTenantForTxSummary(tx);
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) =>  SMSMsgPage(leaseDetails: props.getLeaseDetailsForTxSummary(tx),
                                  tenant: tenant,balance: tx.balance)));},
                        icon : const Icon(Icons.sms_rounded)

                    ),
                  ])
            ),
            ],
        ),
      ),
    );


  }



  Widget _buildTitle(TransactionSummary tx, PropertyModel props) {
    Tenant tenant = props.getTenantForTxSummary(tx);
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
                  Text("${tx.rentableName} " ,
                    style: const TextStyle(fontSize: 16,fontWeight: FontWeight.bold) ,),
                  Spacer(),
                  Text("\$${(tx.balance).abs().toStringAsFixed(0)} ",
                    //@todo get rent
                    style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: (tx.balance < 0 ? Colors.red : Colors.black)),),
                    //@todo get rent


                ],
              ),
            ),

            Padding(padding: const EdgeInsets.all(2.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text("${tenant.firstName} ${tenant.lastName} " ,
                    style: const TextStyle(fontSize: 12) ,),
                  Spacer(),
                  Text("Balance", style: const TextStyle(fontSize: 12) ,),
                ], ),)


          ],
        ),
      ),
    );


  }






  RelativeRect _getRelativeRect(GlobalKey key){
    return RelativeRect.fromSize(
        _getWidgetGlobalRect(key), const Size(200, 200));
  }

  Rect _getWidgetGlobalRect(GlobalKey key) {
    final RenderBox renderBox =
    key.currentContext!.findRenderObject() as RenderBox;
    var offset = renderBox.localToGlobal(Offset.zero);
    debugPrint('Widget position: ${offset.dx} ${offset.dy}');
    return Rect.fromLTWH(offset.dx / 3.1, offset.dy * 1.05,
        renderBox.size.width, renderBox.size.height);
  }

  String getTransactionDetails(String transactionType, String debitOrCredit) {
    if (PageStatics.ROLL_FOR_PAYMENTTYPEVALUE == transactionType)
      return "Rolled from Prior Month";
    else {
      return transactionType + " " + (PageStatics.CREDIT_FOR_DEBIT_OR_CREDIT == debitOrCredit ? "Charged " : " Paid");
    }
  }

}







