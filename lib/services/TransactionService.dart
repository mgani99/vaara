
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:my_app/model/property.dart';
import 'package:my_app/pages/PageStatics.dart';

class TransactionService{


  static double getTotalPaid(List<PropertyTransaction> allTxs) {
    double retVal = 0.0;
    allTxs.forEach((element) {
      if (element.debitOrCredit == 'Pays') {
        retVal = retVal + element.amount;
      }
    });

    return retVal;
  }
  static double getTotalPaidForMonth(List<PropertyTransaction> allTxs, String mmYY) {
    double retVal = 0.0;
    DateTime dt = DateFormat(PageStatics.DATE_FORMAT).parse(mmYY);
    allTxs.forEach((element) {
      if (element.debitOrCredit == PageStatics.DEBIT_FOR_DEBIT_OR_CREDIT && element.dateOfTx.month == dt.month) {
        retVal = retVal + element.amount;
      }
    });

    return retVal;
  }

  static void insertTransaction(TransactionSummary ts, PropertyTransaction tx, PropertyModel model) {

    //@todo for month
      if (tx.debitOrCredit == PageStatics.CREDIT_FOR_DEBIT_OR_CREDIT) ts.totalCredit = ts.totalCredit + tx.amount;
      else ts.totalDebit = ts.totalDebit + tx.amount;
      ts.balance = ts.totalDebit -(ts.totalCredit+ts.rent) ;
      tx.balance = ts.totalDebit -(ts.totalCredit+ts.rent);
      ts.txs.add(tx);
      int index = model.txMap.indexOf(ts);
      if (index != -1) model.txMap.remove(ts);
      ts.txs.sort();
      model.addTransactionSummary(ts, ts.monthAndYear);
      model.txMap.sort();

    model.addTransaction(tx);

  }

  static Future<List<String>> handleUploadImage(Issue issueDtls, List<File> images) async {

    final storageRef = FirebaseStorage.instance.ref();
    List<String> retVal = [];
    for (int i = 0; i < images.length; i++) {
      try {
        final mountainImagesRef = storageRef.child("Reapp/images/${issueDtls.rentableId}/${issueDtls.id}/${i}_before.jpg");
        /*mountainImagesRef.putFile(images[i]).then((taskSnapshot) {
          if (taskSnapshot == TaskState.success) {
            FirebaseStorage.instance
                .ref(images[i].path)
                .getDownloadURL()
                .then((url) {
              print("Here is the URL of Image $url");
               retVal.add(url);
            }).catchError((onError) {
              print("Got Error $onError");
            });
          }
        });*/
        mountainImagesRef.putFile(images[i]).then((p0) {
          print('****** Status $p0');

        });

      } catch (e) {
        print(e);
      }

    }
    return retVal;
  }

  static Future<List<String>> fetchImages(
      Issue issue) async {
      final docRef = FirebaseStorage.instance.ref().child('Reapp').child('images')
          .child(issue.rentableId.toString())
          .child(issue.id.toString());
      final listResult = await docRef.listAll();
      final urls = <String>[];
      for (var item in listResult.items) {
        urls.add(await item.getDownloadURL());
      }
      return Future.value(urls);
  }

  static void recalculateTxTree(TransactionSummary txSummary, PropertyModel props) {
    double balance = txSummary.rent*-1;
    int index = 0;
    double totalDebit = 0.0;
    double totalCredit=0.0;
    txSummary.txs.forEach((element) {
    if (element.debitOrCredit == PageStatics.DEBIT_FOR_DEBIT_OR_CREDIT) {
      balance = balance + element.amount ;
      totalDebit = totalDebit + element.amount;

    }
    else {
      balance = balance - element.amount;
      totalCredit = totalCredit + element.amount;
    }
    element.balance = balance;
    txSummary.txs.replaceRange(index, ++index, [element]);
    props.addTransaction(element);
    });
    txSummary.totalCredit = totalCredit;
    txSummary.totalDebit = totalDebit;
    txSummary.balance = txSummary.totalDebit - (txSummary.totalCredit+txSummary.rent);
  }

  static void updateTxSummary(TransactionSummary txSummary, PropertyTransaction tx, PropertyModel props) {
    int index = props.txMap.indexOf(txSummary);
    if (index != -1) props.txMap.remove(txSummary);

    props.addTransactionSummary(txSummary, txSummary.monthAndYear);
    props.txMap.sort();

  }

  static void deleteTransaction(TransactionSummary txSummary, PropertyTransaction tx, PropertyModel props) {


    txSummary.txs.remove(tx);
    recalculateTxTree(txSummary, props);
    updateTxSummary(txSummary, tx, props);
    txSummary.txs.sort();

    //@todo recalculate txSummary and traverse backward to current month.

    props.removeTransaction(tx);

  }

  static void editTransaction(TransactionSummary tx_summary, PropertyTransaction prop_tx, PropertyModel props) {
    int index = tx_summary.txs.indexOf(prop_tx);
    tx_summary.txs.replaceRange(index, ++index, [prop_tx]);
    recalculateTxTree(tx_summary,props);
    updateTxSummary(tx_summary, prop_tx, props);
  }

  static void deleteImage(Issue issue) async {

   ListResult list =  await FirebaseStorage.instance.ref().child('Reapp').child('images')
        .child(issue.rentableId.toString())
        .child(issue.id.toString()).listAll();

   for (Reference item in list.items) {
      FirebaseStorage.instance.ref().child(item.fullPath).delete();
   }
   FirebaseStorage.instance.ref().child('Reapp').child('images')
       .child(issue.rentableId.toString())
       .child(issue.id.toString()).delete();

  }


  static void addAutoExpenses(List<AutoCalculator> allAutoCalculators, PropertyModel propModel) {
    List<AutoCalculator> updatedAC = [];
    allAutoCalculators.forEach((element) {
      if (element.activeFlag) {
        final amount = element.mapVal['Balance'] * element.mapVal['Rate'] *0.01 /12;
        final dateOfExpense = DateTime(element.dateOfEvent.year, element.dateOfEvent.month+element.frequency , element.dateOfEvent.day);
        final newExpense = Expense(category: element.calculatorType, unitId: 0, propertyId: element.propertyId,
            amount: amount, dateOfExpense: dateOfExpense);

        element.mapVal['Balance'] = element.mapVal['Balance'] - (element.mapVal['PaymentAmt'] - amount);
        element.dateOfEvent = dateOfExpense;
        propModel.addExpense(newExpense);
        updatedAC.add(element);
      }
    });
    updatedAC.forEach((element) {
      propModel.addAutoCalculator(element);
    });
  }



}