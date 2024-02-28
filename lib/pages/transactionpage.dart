
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/model/property.dart';
import 'package:my_app/pages/PageStatics.dart';
import 'package:my_app/pages/taptoexpand.dart';
import 'package:provider/provider.dart';
import 'package:my_app/services/TransactionService.dart';

@immutable
class TransactionPage extends StatefulWidget {
  PropertyTransaction prop_tx;
  TransactionSummary tx_summary;
  Tenant tenant;
  bool editMode;

  TransactionPage({super.key, required this.tx_summary, required this.prop_tx, required this.tenant, required this.editMode});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String paymentTypeValue = PageStatics.RENT_FOR_PAYMENTTYPEVALUE;
  String paymentMethodType = "Zelle";
  String debitOrCredit = PageStatics.DEBIT_FOR_DEBIT_OR_CREDIT;
  final paymentDateController =  TextEditingController();
  final amountController =  TextEditingController();
  final paymentType =  TextEditingController();
  final  commentController=  TextEditingController();

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    paymentDateController.dispose();
    amountController.dispose();
    paymentType.dispose();
    commentController.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    paymentDateController.text = DateFormat(PropertyModel.PAYMENT_DATE_FORMAT).format(DateTime.now());
  }


  @override
  void didChangeDependencies () {
    super.didChangeDependencies();
    paymentTypeValue = widget.prop_tx.transactionType;
    paymentMethodType = widget.prop_tx.payingMethod;
    debitOrCredit = widget.prop_tx.debitOrCredit;
    //paymentDateController.text = DateFormat(PageStatics.PAYMENT_DATE_FORMAT).format(widget.prop_tx.dateOfTx);
    amountController.text =  widget.prop_tx.amount.toString();
    paymentType.text =  widget.prop_tx.transactionType;
    commentController.text =  widget.prop_tx.comment;
  }




  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyModel>(
        builder: (context,props, child)
        {

          return Scaffold(
            appBar: AppBar(leading: BackButton(onPressed: () => Navigator.of(context).pop()),title: const Text("New Fee or Payment")),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Amount',
                      ),
                      controller: amountController,
                    ),
                    DropdownButton<String>(
                      value: paymentTypeValue,
                      elevation: 5,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.black),

                      items: <String>[
                        PageStatics.RENT_FOR_PAYMENTTYPEVALUE,
                        'Security Deposit',
                        'Late Fee',
                        'Damage Fee',
                        'Co-payment',
                        'Other Fee',
                        'Roll',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      hint: const Text(
                        "Select payment type",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      onChanged: (String? value) {
                        setState(() {
                          paymentTypeValue = value!;
                        });
                      },
                    ),

                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Comment',
                      ),
                      //obscureText: true,
                      controller: commentController,
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: paymentMethodType,
                      style: const TextStyle(color: Colors.black),

                      items: <String>[
                        'Zelle',
                        'Check Deposited',
                        'Live Check',
                        'Cashiers Check/Cash',
                        'Other',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      hint: const Text(
                        "Paying Method",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      onChanged: (String? value) {
                        setState(() {
                          paymentMethodType = value!;
                        });
                      },
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: debitOrCredit,
                      elevation: 5,
                      style: const TextStyle(color: Colors.black),

                      items: <String>[
                        PageStatics.DEBIT_FOR_DEBIT_OR_CREDIT,
                        PageStatics.CREDIT_FOR_DEBIT_OR_CREDIT,
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      hint: const Text(
                        "Pays or Owes",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      onChanged: (String? value) {
                        setState(() {
                          debitOrCredit = value!;
                        });
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Date',
                      ),
                      //obscureText: true,
                      controller: paymentDateController,
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    Align(
                        alignment: Alignment.center, child: Row(children: [
                      const SizedBox(
                        width: 100,
                      ),
                      ElevatedButton(
                        onPressed: () {

                          double balance = 0.0;
                          PropertyTransaction _tx = PropertyTransaction(
                              debitOrCredit: debitOrCredit,
                              transactionType: paymentTypeValue,
                              rentableId: widget.prop_tx.rentableId,
                              dateOfTx: DateFormat(PropertyModel.PAYMENT_DATE_FORMAT)
                                  .parse(paymentDateController.text),
                              amount: double.parse(amountController.text),
                              payingMethod: paymentMethodType,
                              paidBy: widget.tenant.id,
                              balance: balance,
                              comment: commentController.text);
                          if (widget.editMode) {
                            _tx.id = widget.prop_tx.id;
                            TransactionService.editTransaction(widget.tx_summary, _tx, props);

                          }

                          else
                          {
                            TransactionService.insertTransaction(widget.tx_summary, _tx,

                                props);
                          }

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                        ),
                        child: const Text('Save'),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      if (widget.editMode) ElevatedButton(
                        onPressed: () {

                          TransactionService.deleteTransaction(widget.tx_summary, widget.prop_tx, props);

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                        ),
                        child: const Text('Delete'),
                      ),

                    ])),


                  ],
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