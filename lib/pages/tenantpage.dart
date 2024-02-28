// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:easy_search_bar/easy_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../model/property.dart';

class TenantPage extends StatefulWidget {
  TenantPage({super.key, this.tenant});
  Tenant? tenant;

  @override
  State<TenantPage> createState() => _TenantPageState();
}

class _TenantPageState extends State<TenantPage> {
  final lastNameController = TextEditingController();

  final firstNameController = TextEditingController();

  final phoneNumberController= TextEditingController();

  final emailController= TextEditingController();

  final accountNumberController = TextEditingController();

  String? searchValue;
  Map<String, Tenant> tenantsMap = {};

  late PropertyModel propertyModel;
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
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    if (widget.tenant == null) widget.tenant = Tenant.nullTenant();
    else setTenant(widget!.tenant);
    propertyModel = context.watch<PropertyModel>();
    propertyModel.allTenants.forEach((element) {
      tenantsMap[element.firstName + " " + element.lastName] = element;
    });

  }

  @override
  Widget build(BuildContext context) {




    return MaterialApp(
      title: 'Tenant Info',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () => Navigator.of(context).pop(widget!.tenant),
            ),
            title: const Text('Tenant Info'),
          ),

      body: SingleChildScrollView(
        child: Container(


            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                    height: 56,
                    width: 330,
                    child: EasySearchBar(
                        title: const Text('Search Tenant'),
                        onSearch: (value) => setState(() => searchValue = value),
                        actions: [
                          IconButton(icon: const Icon(Icons.person), onPressed: () {})
                        ],
                        isFloating: true,
                        backgroundColor: Colors.white,
                        showClearSearchIcon: true,
                        openOverlayOnSearch: true,
                        onSuggestionTap: (data) => setTenant(tenantsMap[data]),
                        asyncSuggestions: (value) async => await _handleSearch(value))),
                getContents(),
                OutlinedButton(
                  onPressed: () {

                    Navigator.pop(context, widget!.tenant);
                  },
                  style: ElevatedButton.styleFrom(elevation: 5
                    //backgroundColor: Colors.yellow,
                  ),
                  child: SizedBox(
                      width: 300,
                      child: Text(
                        'Use this Tenant ',
                        textAlign: TextAlign.center,
                      )),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget getContents() {
    return Column(children: [
      SizedBox(
        height: 15,
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
        height: 55,
        width: 360,
        child: TextFormField(
          keyboardType: TextInputType.name,
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
        height: 55,
        width: 360,
        child: TextFormField(
          keyboardType: TextInputType.name,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.all(10.0),

            hintText: 'Bank Account',
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
        height: 55,
        width: 360,
        child: TextFormField(
          keyboardType: TextInputType.phone,
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
          controller: emailController,
        ),
      ),
      SizedBox(
        height: 30,
      ),
      OutlinedButton(
        onPressed: () {
          var ten = Tenant(
              lastNameController.text,
              firstNameController.text,
              accountNumberController.text,
              phoneNumberController.text,
              emailController.text);
          if (widget.tenant != null) ten.id = widget.tenant!.id;
          propertyModel.addTenant(ten);
          Navigator.pop(context, ten);
        },
        style: ElevatedButton.styleFrom(elevation: 5
            //backgroundColor: Colors.yellow,
            ),
        child: SizedBox(
            width: 300,
            child: Text(
              'Save and Use this Tenant ',
              textAlign: TextAlign.center,
            )),
      )
    ]);
  }

  setTenant(Tenant? data) {
    lastNameController.text = data!.lastName;
    firstNameController.text = data!.firstName;
    phoneNumberController.text = data!.phoneNumber;
    accountNumberController.text = data!.bankAccountId;
    emailController.text = data!.email;
    widget.tenant = data;
  }

  final List<String> _results = [];


  Future<List<String>> _handleSearch(String input) async {
    _results.clear();
    for (var str in tenantsMap.keys) {
      if (str.toLowerCase().contains(input.toLowerCase())) {
        setState(() {
          _results.add(str);
        });
      }
    }
    return _results;
  }
}
