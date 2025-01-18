// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/pages/PageStatics.dart';
import 'package:my_app/pages/tenantpage.dart';
import 'package:provider/provider.dart';
import '../model/property.dart';

class UnitDetailsPage extends StatefulWidget {
  UnitDetailsPage({
    super.key,this.tenant, this.leaseDetails, this.unit, required this.insertMode
  });

  Tenant? tenant;
  LeaseDetails? leaseDetails;
  Unit? unit;
  bool insertMode;
  bool? singleUnit;
  String? mainAddress;



  @override
  State<UnitDetailsPage> createState() => _UnitDetailsPageState();
}


class _UnitDetailsPageState extends State<UnitDetailsPage> {
  final unitNameController = TextEditingController();
  final unitTypeController = TextEditingController();
  final unitAddressController = TextEditingController();

  final bedroomsController = TextEditingController();
  final bathroomsController = TextEditingController();
  final livingSpaceController = TextEditingController();

  final leaseStartDateController = TextEditingController();
  final leaseEndDateController = TextEditingController();
  final securityDepositController = TextEditingController();
  final rentAmountController = TextEditingController();


  final tenantFirstNameController = TextEditingController();
  final tenantLastNameController= TextEditingController();
  final tenantAccountNumberController= TextEditingController();
  final tenantPhoneNumberController= TextEditingController();
  final tenantEmailController= TextEditingController();

  int currentStep = 0;
  late PropertyModel propertyModel;
  String searchValue = "";
  Map<String, Tenant> contractorsMap = {};


  @override
  void dispose() {
    unitNameController.dispose();
    unitTypeController.dispose();
    leaseStartDateController.dispose();
    leaseEndDateController.dispose();
    securityDepositController.dispose();
    rentAmountController.dispose();
    unitAddressController.dispose();


    bedroomsController.dispose();
    bathroomsController.dispose();
    livingSpaceController.dispose();



    tenantFirstNameController.dispose();
    tenantLastNameController.dispose();
    tenantAccountNumberController.dispose();
    tenantPhoneNumberController.dispose();
    tenantEmailController.dispose();


    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    propertyModel = context.watch<PropertyModel>();
    propertyModel.allTenants.forEach((element) {
      contractorsMap[element.firstName + " " + element.lastName] = element;
    });
    if (widget.unit != null) {
      unitNameController.text = widget.unit!.name;
      unitTypeController.text = widget.unit!.unitType;
      unitAddressController.text = widget.unit!.address;

      bathroomsController.text = widget.unit!.bathrooms.toString();
      bedroomsController.text = widget.unit!.bedrooms.toString();
      livingSpaceController.text = widget.unit!.livingSpace.toString();
    }
    if (widget.leaseDetails != null) {
      leaseStartDateController.text = widget.leaseDetails!.startDate;
      leaseEndDateController.text = widget.leaseDetails!.endDate;
      rentAmountController.text = widget.leaseDetails!.rent.toString();
      securityDepositController.text = widget.leaseDetails!.securityDeposit.toString();
    }
    if (widget.tenant != null) {
       tenantFirstNameController.text = widget.tenant!.firstName;
       tenantLastNameController.text = widget.tenant!.lastName;
       tenantAccountNumberController.text = widget.tenant!.bankAccountId;
       tenantPhoneNumberController.text = widget.tenant!.phoneNumber;
       tenantEmailController.text = widget.tenant!.email;
    }


  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          title:  Text('Unit Details'),

          centerTitle: false,
        ),
        body: Stack(


            children: [

              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Stepper(
                  type: StepperType.horizontal,
                  controlsBuilder: (BuildContext ctx, ControlsDetails dtl) {
                    return Stack(
                      children: [Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: TextButton(
                                onPressed: dtl.onStepCancel,
                                child: const Text('BACK'),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: TextButton(
                                onPressed: dtl.onStepContinue,
                                child: const Text('NEXT'),
                              ),
                            ),
                          ])
                      ],
                      //Pos
                    );
                  },


                  currentStep: currentStep,
                  onStepCancel: () =>
                  currentStep == 0
                      ? null
                      : setState(() {
                    currentStep -= 1;
                  }),

                  onStepContinue: () {
                    bool isLastStep = (currentStep == getSteps().length - 1);
                    if (isLastStep) {
                      saveOrUpdate();
                      //Do something with this information
                    } else {
                      setState(() {
                        currentStep += 1;
                      });
                    }
                  },
                  onStepTapped: (step) =>
                      setState(() {
                        currentStep = step;
                      }),
                  steps: getSteps(),
                ),
              ),
              //Positioned(left: 0,right: 0, bottom: 16,child: getButtonRow(t!)),
            ]
        ),
      ),
    );

  }


  List<Step> getSteps() {
    return <Step>[
    Step(


        state: currentStep > 0 ? StepState.complete : StepState.indexed,
        isActive: currentStep >= 0,
        title: Text("Unit Details"),

        content:
         Container(
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [

                SizedBox(
                  height: 55,
                  width: 360,
                  child: TextFormField(
                    keyboardType: TextInputType.name,
                    readOnly: !widget.insertMode,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),

                      hintText: 'Unit Name',
                      //filled: true,
                      //fillColor: const Color(0xfff1f1f1),

                      border: OutlineInputBorder(

                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    controller: unitNameController,
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                SizedBox(
                  height: 55,
                  width: 360,
                  child: TextFormField(
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),

                      hintText: 'Unit Type e.g Apartment, Garage, Parking',
                      //filled: true,
                      //fillColor: const Color(0xfff1f1f1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    controller: unitTypeController,
                  ),
                ),
            SizedBox(
              height: 15,
            ),
                SizedBox(
                  height: 45,
                  width: 360,
                  child: TextFormField(
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),

                      hintText: 'Unit Address',
                      //filled: true,
                      //fillColor: const Color(0xfff1f1f1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    controller: unitAddressController,
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
            SizedBox(
                height: 55,
                width: 360,
                child: TextFormField(
                  keyboardType: TextInputType.numberWithOptions(),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(10.0),

                    hintText: 'Bedrooms',
                    //filled: true,
                    //fillColor: const Color(0xfff1f1f1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  controller: bedroomsController,
                ),),
            SizedBox(
              height: 15,
            ),
            SizedBox(
                height: 55,
                width: 360,
                child: TextFormField(
                  keyboardType: TextInputType.numberWithOptions(),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(10.0),

                    hintText: 'Bathrooms',
                    //filled: true,
                    //fillColor: const Color(0xfff1f1f1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  controller: bathroomsController,
                ),),
            SizedBox(
              height: 15,
            ),
            SizedBox(
                height: 55,
                width: 360,
                child: TextFormField(
                  keyboardType: TextInputType.numberWithOptions(),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(10.0),

                    hintText: 'Living Space',
                    //filled: true,
                    //fillColor: const Color(0xfff1f1f1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  controller: livingSpaceController,
                ),),
                ]
                ),))),

                Step(
                state: currentStep > 1 ? StepState.complete : StepState.indexed,
    isActive: currentStep >= 1,
    title: Text("Lease"),

    content:
    Container(
    padding: const EdgeInsets.all(20.0),
    child: SingleChildScrollView(
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
                  ]),))),
      Step(
    state: currentStep > 2 ? StepState.complete : StepState.indexed,
    isActive: currentStep >= 2,
    title: Text("Tenant"),

    content:
    Container(
    padding: const EdgeInsets.all(20.0),
    child: SingleChildScrollView(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [

                SizedBox(
                  height: 15,
                ),
                SizedBox(
                  height: 55,
                  width: 360,
                  child: TextFormField(
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),

                      hintText: 'First Name*',
                      //filled: true,
                      //fillColor: const Color(0xfff1f1f1),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    controller: tenantFirstNameController,
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                SizedBox(
                  height: 55,
                  width: 360,
                  child: TextFormField(
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),

                      hintText: 'Last Name*',
                      //filled: true,
                      //fillColor: const Color(0xfff1f1f1),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    controller: tenantLastNameController,
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                SizedBox(
                  height: 55,
                  width: 360,
                  child: TextFormField(
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),

                      hintText: 'Phone Number*',
                      //filled: true,
                      //fillColor: const Color(0xfff1f1f1),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    controller: tenantPhoneNumberController,
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                SizedBox(
                  height: 55,
                  width: 360,
                  child: TextFormField(
                    keyboardType: TextInputType.numberWithOptions(),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),

                      hintText: 'Account Number*',
                      //filled: true,
                      //fillColor: const Color(0xfff1f1f1),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    controller: tenantAccountNumberController,
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                SizedBox(
                  height: 55,
                  width: 360,
                  child: TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),

                      hintText: 'Email',
                      //filled: true,
                      //fillColor: const Color(0xfff1f1f1),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    controller: tenantEmailController,
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
              ],
            ),
          ),
        ),
      )
    ];
  }

  final List<String> _results = [];

  Future<List<String>> _handleSearch(String input) async {
    _results.clear();
    for (var str in contractorsMap.keys) {
      if (str.toLowerCase().contains(input.toLowerCase())) {
        setState(() {
          _results.add(str);
        });
      }
    }
    return _results;
  }

  setContractor(data) {
    print(data);
    setState(() {
      widget.tenant = contractorsMap[data]!;
    });
  }

  void saveOrUpdate() {
    var aTenant = Tenant(tenantLastNameController.text, tenantFirstNameController.text,tenantAccountNumberController.text, tenantPhoneNumberController.text, tenantEmailController.text);
    if (widget.tenant != null)
      aTenant.id = widget!.tenant!.id;

    var ld =LeaseDetails(leaseStartDateController.text,
          leaseEndDateController.text,[ aTenant!.id], double.parse(rentAmountController.text),
          double.parse(securityDepositController.text));
    if (widget.leaseDetails != null)ld.id= widget.leaseDetails!.id;
    var newUnit = Unit(unitTypeController.text, [], ld.id,unitNameController.text);
    newUnit.livingSpace = int.parse(livingSpaceController.text != null ? livingSpaceController.text : "0");
    newUnit.bedrooms = int.parse(bedroomsController.text != null ? bedroomsController.text : "0");
    newUnit.bathrooms = double.parse(bathroomsController.text != null ? bathroomsController.text : "0.0");
    newUnit.address = unitAddressController.text;
    newUnit.tenantId = aTenant.id;
    (widget!.unit != null) ?newUnit.unitTypeId = widget!.unit!.unitTypeId : newUnit.unitTypeId = 1;
    newUnit.rent = ld.rent;




    if (widget!.unit != null) newUnit.id = widget!.unit!.id;
    Map<String, dynamic> returnData = {};
    returnData['Tenant'] = aTenant;
    returnData['LeaseDetails'] = ld;
    returnData['Unit'] = newUnit;
    Navigator.pop(context, returnData);
  }
}
