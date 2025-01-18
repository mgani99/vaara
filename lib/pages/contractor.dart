// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:standard_searchbar/new/standard_search_anchor.dart';
import 'package:standard_searchbar/new/standard_search_bar.dart';
import 'package:standard_searchbar/new/standard_suggestion.dart';
import 'package:standard_searchbar/new/standard_suggestions.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/property.dart';

class ContractorPage extends StatefulWidget {
  ContractorPage({
    super.key,this.contractor
  });

  Contractor? contractor;


  @override
  State<ContractorPage> createState() => _ContractorPageState();
}

class _ContractorPageState extends State<ContractorPage> {
  final lastNameController = TextEditingController();

  final firstNameController = TextEditingController();

  final phoneNumberController = TextEditingController();

  final emailController = TextEditingController();

  final accountNumberController = TextEditingController();

  late PropertyModel propertyModel;
  String searchValue = "";
  Map<String, Contractor> contractorsMap = {};

  @override
  void dispose() {
    lastNameController.dispose();
    firstNameController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    accountNumberController.dispose();
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
    propertyModel.allContractors.forEach((element) {
      contractorsMap[element.firstName + " " + element.lastName] = element;
    });
    if (widget.contractor == null) {
      widget.contractor = Contractor.nullContractor();
    }

  }

  @override
  Widget build(BuildContext context) {
    var propertyModel = context.watch<PropertyModel>();
    lastNameController.text = widget.contractor!.lastName;
    firstNameController.text = widget.contractor!.firstName;
    phoneNumberController.text = widget.contractor!.mobilePhone;
    accountNumberController.text = widget.contractor!.bankAccount;
    emailController.text = widget.contractor!.email;

    return MaterialApp(
        title: 'Contractors Info',
        theme: ThemeData(primarySwatch: Colors.orange),
        home: Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Contractor Info'),
          ),
          body: Padding(
            padding: EdgeInsets.all(30.0),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                        height: 56,
                        width: 330,
                        child: StandardSearchBar(
                          )),
                    SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      height: 45,
                      width: 360,
                      child: TextFormField(
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(10.0),

                          hintText: 'First Name',
                          //filled: true,
                          //fillColor: const Color(0xfff1f1f1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        controller: firstNameController,
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

                          hintText: 'Last Name',
                          //filled: true,
                          //fillColor: const Color(0xfff1f1f1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        controller: lastNameController,
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

                          hintText: 'Account Number',
                          //filled: true,
                          //fillColor: const Color(0xfff1f1f1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        controller: accountNumberController,
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

                          hintText: 'Phone Number',
                          //filled: true,
                          //fillColor: const Color(0xfff1f1f1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        controller: phoneNumberController,
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

                          hintText: 'Email Address',
                          //filled: true,
                          //fillColor: const Color(0xfff1f1f1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        controller: emailController,
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    ),

                    OutlinedButton(
                      onPressed: () {
                        widget.contractor!.lastName = lastNameController.text;

                        widget.contractor!.firstName =firstNameController.text ;
                         widget.contractor!.mobilePhone =   phoneNumberController.text ;
                        widget.contractor!.bankAccount =     accountNumberController.text;
                         widget.contractor!.email   = emailController.text;
                        propertyModel.addContractor(widget.contractor!);
                            Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(elevation: 5
                          //backgroundColor: Colors.yellow,
                          ),
                      child: SizedBox(
                          width: 300,
                          child: Text(
                            'Edit Contractor',
                            textAlign: TextAlign.center,
                          )),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        var cont = Contractor(
                                 lastName: lastNameController.text,
                                 firstName: firstNameController.text,
                                 mobilePhone: phoneNumberController.text);
                             cont.email = emailController.text;
                             cont.bankAccount = accountNumberController.text;
                             propertyModel.addContractor(cont);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(elevation: 5
                          //backgroundColor: Colors.yellow,
                          ),
                      child: SizedBox(
                          width: 300,
                          child: Text(
                            'Add New Contractor',
                            textAlign: TextAlign.center,
                          )),
                    )
                  ],
                ),
              ),
            ),
          ),
        ));
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
      widget.contractor = contractorsMap[data]!;
    });
  }
}
