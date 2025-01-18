

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:my_app/model/property.dart';

import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:path_provider/path_provider.dart';

import '../services/GoogleDriveService.dart';
import 'package:googleapis/gmail/v1.dart' as gMail;


@immutable
class SMSMsgPage extends StatefulWidget {

  LeaseDetails leaseDetails;
  Tenant tenant;
  double balance;

  SMSMsgPage({super.key, required this.leaseDetails, required this.tenant, required this.balance});

  @override
  State<SMSMsgPage> createState() => _SMSMsgPage();
}

class _SMSMsgPage extends State<SMSMsgPage> {

  final leaseStartDateController = TextEditingController();
  final leaseEndDateController = TextEditingController();
  final securityDepositController = TextEditingController();
  final rentAmountController = TextEditingController();
  NumberFormat numberFormat = NumberFormat("#,##0", "en_US");
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _driveService = DriveService();
  String? _fileId;



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
      leaseEndDateController.text = "${widget.tenant.firstName}, Please note as of today you owe \$${numberFormat.format(widget.balance.abs())}. "
          "Failure to pay immediately will result in Late fee and/or eviction. When are you going to be current?";
      rentAmountController.text = widget.leaseDetails!.rent.toString();
      securityDepositController.text = widget.leaseDetails!.securityDeposit.toString();
    }

  }


  @override
  void didChangeDependencies () {
    super.didChangeDependencies();

    //paymentDateController.text = DateFormat(PageStatics.PAYMENT_DATE_FORMAT).format(widget.prop_tx.dateOfTx);

  }






/*  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyModel>(
        builder: (context,props, child)
        {

          return Scaffold(
            appBar: AppBar(leading: BackButton(onPressed: () => Navigator.of(context).pop()),title: const Text("Send Reminder SMS to Tenant")),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(

                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [

                      SizedBox(
                        height: 55,
                        width: 360,
                        child: Text("Send Msg to  ${widget.tenant.firstName} at ${widget.tenant.phoneNumber}"),
                        ),

                      SizedBox(
                        height: 15,
                      ),
                      SizedBox(
                        height: 255,
                        width: 360,
                        child: TextFormField(
                          keyboardType: TextInputType.text,
                          maxLines: 5,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(10.0),

                            hintText: 'enter sms message',
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
                      OutlinedButton(onPressed: () {sendMsg(widget.tenant.phoneNumber);}, child: Text("Send")),
                    ]
                ),
              ),),);
        }
    );


  }
*/

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key:  _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          "GoogleDriveHandlerExampleApp",
        ),
        centerTitle: true,
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _messages,
              child: const Text(
                "Get file from google drive",
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showLoader() {
    showDialog(
      context: _scaffoldKey.currentContext!,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          width: 200,
          height: 200,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(_scaffoldKey.currentContext!)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
  void _closeLoader() {
    Navigator.pop(_scaffoldKey.currentContext!);
  }
  Future<void> _uploadFile() async {
    _showLoader();

    // 1. create a file to upload
    final dir = await getApplicationDocumentsDirectory();
    final filePath = path.join(dir.path, 'upload.txt');
    final file = File(filePath);
    await file.writeAsString('Hello World!!!');

    // 2. upload file to drive
    _fileId = await _driveService.uploadFile('upload.txt', filePath);

    _closeLoader();

    if (_fileId == null) {
      _showSnackbar('Failed to upload the file!');
    } else {
      _showSnackbar('File successfully uploaded: $_fileId');
    }
  }

  Future<void> _messages() async {
    _showLoader();

    // 2. upload file to drive
    _fileId = await _driveService.getMessages("test");

    _closeLoader();

    if (_fileId == null) {
      _showSnackbar('Failed to upload the file!');
    } else {
      _showSnackbar('File successfully uploaded: $_fileId');
    }
  }


}
