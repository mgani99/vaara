
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/model/property.dart';
import 'package:my_app/pages/PageStatics.dart';
import 'package:my_app/pages/taptoexpand.dart';
import 'package:provider/provider.dart';
import 'package:my_app/services/TransactionService.dart';

@immutable
class LeaseDetailsPage extends StatefulWidget {

  LeaseDetails leaseDetails;
  Tenant tenant;
  bool editMode;

  LeaseDetailsPage({super.key, required this.leaseDetails, required this.tenant, required this.editMode});

  @override
  State<LeaseDetailsPage> createState() => _LeaseDetailsPage();
}

class _LeaseDetailsPage extends State<LeaseDetailsPage> {

  final leaseStartDateController = TextEditingController();
  final leaseEndDateController = TextEditingController();
  final securityDepositController = TextEditingController();
  final rentAmountController = TextEditingController();


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    leaseStartDateController.dispose();
    leaseEndDateController.dispose();
    securityDepositController.dispose();
    rentAmountController.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //paymentDateController.text = DateFormat(PropertyModel.PAYMENT_DATE_FORMAT).format(DateTime.now());
    if (widget.leaseDetails != null) {
      leaseStartDateController.text = widget.leaseDetails!.startDate;
      leaseEndDateController.text = widget.leaseDetails!.endDate;
      rentAmountController.text = widget.leaseDetails!.rent.toString();
      securityDepositController.text = widget.leaseDetails!.securityDeposit.toString();
    }
  }


  @override
  void didChangeDependencies () {
    super.didChangeDependencies();

    //paymentDateController.text = DateFormat(PageStatics.PAYMENT_DATE_FORMAT).format(widget.prop_tx.dateOfTx);

  }




  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyModel>(
        builder: (context,props, child)
        {

          return Scaffold(
            appBar: AppBar(leading: BackButton(onPressed: () => Navigator.of(context).pop()),title: const Text("Lease Details")),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(

                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [

                      SizedBox(
                        height: 55,
                        width: 360,
                        child: TextFormField(
                          keyboardType: TextInputType.datetime,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(10.0),

                            hintText: 'Lease Start Date',
                            //filled: true,
                            //fillColor: const Color(0xfff1f1f1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                          ),
                          controller: leaseStartDateController,
                        ),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      SizedBox(
                        height: 55,
                        width: 360,
                        child: TextFormField(
                          keyboardType: TextInputType.datetime,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(10.0),

                            hintText: 'Lease End Date',
                            //filled: true,
                            //fillColor: const Color(0xfff1f1f1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                          ),
                          controller: leaseEndDateController,
                        ),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      SizedBox(
                        height: 55,
                        child: TextFormField(
                          keyboardType: TextInputType.numberWithOptions(
                              signed: false, decimal: false),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(10.0),

                            hintText: 'Rent Amount',
                            //filled: true,
                            //fillColor: const Color(0xfff1f1f1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                          ),
                          controller: rentAmountController,
                        ),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      SizedBox(
                        height: 55,
                        width: 360,
                        child: TextFormField(
                          keyboardType: TextInputType.numberWithOptions(
                              signed: false, decimal: false),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(10.0),

                            hintText: 'Secruity Amount',
                            //filled: true,
                            //fillColor: const Color(0xfff1f1f1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                          ),
                          controller: securityDepositController,
                        ),
                      ),
                    ]
                ),
              ),),);
        }
    );


  }


}

/*
Card(
                          elevation: 8,
                            child: ListTile(
                                title:Text(DateFormat(PageStatics.DATE_IN_TX_PAGE).format(widget.txSummary.txs[index].dateOfTx),
                                    style: const TextStyle(fontSize: 14)),

                                subtitle: Text(" ${widget.txSummary.txs[index].transactionType} " ,
                                    style: const TextStyle(fontSize: 16)),

                                isThreeLine: true,
                                dense: true,
                                leading: const CircleAvatar(
                                  backgroundImage: AssetImage(
                                    "assets/transaction.png",),
                                ),
                                trailing:
                                Column(children: [
                                  Text(" ${widget.txSummary.txs[index].debitOrCredit} : \$${widget.txSummary.txs[index].amount.toString()} ",
                                    //@todo get rent
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text("Balance : ${widget.txSummary.txs[index].balance.toStringAsFixed(2)} ",
                                    //@todo get rent
                                    style: const TextStyle(fontSize: 16),
                                  ),

                                ])

                            ))
 */