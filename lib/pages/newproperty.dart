import 'package:easy_search_bar/easy_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:my_app/pages/tenantpage.dart';
import 'package:my_app/pages/unitdetailspage.dart';
import 'package:provider/provider.dart';
import 'package:my_app/model/property.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;


class NewProperty extends StatefulWidget {
  final RentableModel rentable;
  bool insertMode = true;
   NewProperty({super.key, required this.rentable, required this.insertMode});
  @override
  State<NewProperty> createState() => _NewPropertyState();
}

class _NewPropertyState extends State<NewProperty> {
  int currentStep = 0;
  String zpid = "";
  Property property = Property.nullProperty();
  late PropertyModel propertyModel;

  final propertyTypeController = TextEditingController();
  final propertyNameController = TextEditingController();
  final propertyAddressController = TextEditingController();
  final propertyImageURLController = TextEditingController();
  final numberOfUnitController = TextEditingController();
  final pictureURLController = TextEditingController();
  List<Map<String, dynamic>> _units = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    propertyModel = context.watch<PropertyModel>();
    if (!widget.insertMode) {
      property = propertyModel.getProperty(widget.rentable.propId);
      for (var unitId in property.unitIds) {
        var unit = propertyModel.getUnit(unitId);
        LeaseDetails aLeaseDetail = propertyModel.getLeaseDetail(
            unit.currentLeaseId);
        var tenant = propertyModel.getTenant(aLeaseDetail.tenantIds[0]);

        //@todo support multiple tenant
        Map<String, dynamic> _aUnit = {};
        _aUnit['Unit'] = unit;
        _aUnit['LeaseDetails'] = aLeaseDetail;
        _aUnit['Tenant'] = tenant;
        _units.add(_aUnit);
      }

      setState(() {
        propertyNameController.text = widget.rentable.propName;
        propertyAddressController.text = widget.rentable.propAddress;
        propertyTypeController.text = property.propertyType;
        _units;
        numberOfUnitController.text = _units.length.toString();
        pictureURLController.text = property.pictureURL;
      });
    }
  }

  @override
  void dispose() {

    // Clean up the controller when the widget is disposed.
    propertyNameController.dispose();
    propertyAddressController.dispose();
    numberOfUnitController.dispose();
    propertyTypeController.dispose();
    super.dispose();
  }

  //final propertyNameController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    ControlsDetails? t;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: widget.rentable.propName == ""
              ? const Text('Add New Property')
              : const Text('Update Property '),

        ),
        body: Stack(


            children: [

              Padding(
                padding: const EdgeInsets.only(bottom: 20),
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
                                child: (currentStep == getSteps().length - 1)? const Text('Save') : const Text("Next"),
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




  void saveOrUpdate() {
    var p = Property(name: propertyNameController.text,
        address: propertyAddressController.text,
        unitIds: [],
        propertyType: propertyTypeController.text);
    p.pictureURL = pictureURLController.text;
    if (!widget.insertMode) p.id = property.id;
    for (int i = 0; i < _units.length; i++) {
     Map<String, dynamic> _aUnit = _units[i];
      LeaseDetails leaseDetails = _aUnit['LeaseDetails'];
      Unit unit = _aUnit['Unit'];
      Tenant tenant = _aUnit['Tenant'];
      p.unitIds.add(unit.id);
      RentableModel rentables;
      if (widget.insertMode) {
        rentables = RentableModel(propName: p.name,
            propAddress: p.address,
            rent: leaseDetails.rent,
            propId: p.id,
            unitName: unit.name,
            unitId: unit.id,
            leaseDetailsId: leaseDetails.id,
            tenantId: tenant.id);
      }
      else {
        rentables = widget.rentable;

      }
      rentables.pictureURL = p.pictureURL;
      rentables.livingSpace = unit.livingSpace;
      rentables.bedrooms = unit.bedrooms;
      rentables.bathrooms = unit.bathrooms;

      propertyModel.addRentables(rentables);
      propertyModel.addLeaseDetail(leaseDetails);
      propertyModel.addUnit(unit);
      propertyModel.addTenant(tenant);
    }

    propertyModel.add(p);
    Navigator.pop(context);
  }






  void _addUnit(int unitCount) {
  if (_units.length >= unitCount) return;
  var count = unitCount - _units.length;
    for (int i=0;i<count;i++)
      _units.add({});
    setState(() {
      _units;
    });
  }
  TextField _generateTextField(TextEditingController controller, String hint,
      TextInputType input) {




    return TextField(
      controller: controller,
      keyboardType: input,
      decoration: InputDecoration(
        //border: OutlineInputBorder(),
        labelText: hint,
      ),
    );
  }

  Widget _listViewCards() {
    return SizedBox(
      height: 480,
      child: ListView.builder(
          itemCount: _units.length,
          itemBuilder: (context, index) {
            return InkWell(
                onTap: () {print('tapp inkwell');},
                child: buildCard(_units[index], context, index));
          }
      ),
    );

  }

  void _unitCardPressed({required int index, Unit? unit, LeaseDetails? ld, Tenant? tenant}) async{
    print("tapped");
    final Map<String, dynamic> returnedData = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => UnitDetailsPage(tenant: tenant, leaseDetails: ld, unit: unit,insertMode:widget.insertMode
            )));setState(() {
      if (returnedData != null && returnedData.isNotEmpty) {
        _units[index] = returnedData;
      }
    });
  }
  Card buildCard(Map<String,dynamic> _unit, BuildContext context, int index) {
    bool cardEmpty = (_unit == null || _unit.isEmpty);
    if (cardEmpty) return
        Card(
            child:
            TextButton(
                child: const Text('Enter Unit and Lease Details', style: TextStyle(color: Colors.redAccent),)  ,
                onPressed: () async{     _unitCardPressed(index: index);       }));
    else {
      var unit = _unit['Unit'];
      LeaseDetails ld = _unit['LeaseDetails'];
      Tenant tenant = _unit['Tenant'];
      var subheading = '\$${ld.rent.toStringAsFixed(0)} per month';
      var heading = "${unit.unitType}: ${unit.name}";
      
      return Card(
          elevation: 4.0,
          child: Column(
            children: [
              ListTile(
                title: Text(heading),
                subtitle: Text(subheading),
                trailing: Column(children:[Text(""),Text("${unit.bedrooms} bed, ${unit.bathrooms} bath"),Text("${unit.livingSpace} sqr ft")])
              ),
              Container(
                  padding: EdgeInsets.all(16.0),
                  alignment: Alignment.centerLeft,
                  child: Column(children: [
                     Row(children: [
                      Text("Lease Start"),
                      Spacer(),
                      Text("${ld.startDate}",
                        style: TextStyle(color: Colors.blue),
                      )
                    ]),
                    Divider(),
                    Row(children: [
                      Text("Lease End"),
                      Spacer(),
                      Text("${ld.endDate}",
                        style: TextStyle(color: Colors.blue),
                      )
                    ]),
                    Divider(),
                    Row(children: [
                      Text("Security Deposit"),
                      Spacer(),
                      Text("\$${ld.securityDeposit.toStringAsFixed(0)}",
                        style: TextStyle(color: Colors.blue),
                      )
                    ]),
                    Divider(),
                    Row(children: [
                      Text("Tenant"),
                      Spacer(),
                      Text("${tenant.firstName} ${tenant.lastName}",
                        style: TextStyle(color: Colors.blue),
                      )
                    ])
                  ])),
              ButtonBar(
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextButton.icon(
                      onPressed: () {_unitCardPressed(index: index,
                      unit: unit, tenant: tenant, ld: ld);},
                      icon: Icon(
                        Icons.mode_edit,
                        color: Colors.green,
                      ),
                      label: Text(
                        "Edit Unit",
                        style: TextStyle(color: Color(0xFF6200EE)),
                      ),
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextButton.icon(
                      onPressed: () {setState(() {
                        _units.removeAt(index);
                      });},
                      icon: Icon(
                        Icons.delete_outline_sharp,
                        color: Colors.redAccent,
                      ),
                      label: Text(
                        "Delete Unit",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),

            ],
          ));
    }



  }

  String? searchValue;

  List<Step> getSteps() {
    return <Step>[
      Step(
          state: currentStep > 0 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 0,
          title: const Text("Basic\n Info"),
          content:
          SizedBox(
            height: 585,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                (widget.insertMode) ?SizedBox(
                    height: 56,
                    width: 330,
                    child: EasySearchBar(
                        title: const Text('Address'),
                        onSearch: (value) =>
                            setState(() => searchValue = value),
                        actions: [
                          IconButton(
                              icon: const Icon(Icons.bungalow_outlined),
                              onPressed: () {})
                        ],
                        isFloating: true,
                        backgroundColor: Colors.white,
                        showClearSearchIcon: true,
                        openOverlayOnSearch: true,
                        onSuggestionTap: (data) => setAddress(data),
                        asyncSuggestions: (value) async =>
                        await _handleSearch(value))) : Container(),
                SizedBox(
                  height: 15,
                ),
                SizedBox(
                  height: 55,
                  width: 360,
                  child: TextFormField(
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),

                      hintText: 'Address*',
                      //filled: true,
                      //fillColor: const Color(0xfff1f1f1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    controller: propertyAddressController,
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                SizedBox(
                  height: 55,
                  width: 360,
                  child: TextFormField(
                    readOnly: !widget.insertMode,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),

                      hintText: 'Property Name*',
                      //filled: true,
                      //fillColor: const Color(0xfff1f1f1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    controller: propertyNameController,
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                SizedBox(
                  height: 55,
                  width: 360,
                  child: TextFormField(
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),

                      hintText: 'Property Type*',
                      //filled: true,
                      //fillColor: const Color(0xfff1f1f1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    controller:propertyTypeController,
                  ),
                ),

                SizedBox(height: 15,),
            SizedBox(
              height: 55,
              width: 360,
              child:
              TextFormField(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(10.0),

                  hintText: 'Picture URL',
                  //filled: true,
                  //fillColor: const Color(0xfff1f1f1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                ),
                controller: pictureURLController,
              ),


            )],),
          )
      ),

      Step(
          state: currentStep > 1 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 1,
          title:  Text(" Unit\nDetails"),
          content: SizedBox(

              height: 585,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [



                        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children:[
                          SizedBox(
                            width: 260, height: 45,
                            child: TextFormField(
                                 decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(10.0),

                                hintText: 'Add Rentable Units',
                                //filled: true,
                                //fillColor: const Color(0xfff1f1f1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                              ),
                              controller: numberOfUnitController,
                            ),
                          ),
                          TextButton(onPressed: (){_addUnit(int.parse(numberOfUnitController.text));}, child: Text("Total Units"))]),
                        SizedBox(height: 15,),





                       // _addTile(),
                        _listViewCards(),
                    ]
                    ),
              ),
            ),
      Step(
          state: currentStep > 1 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 1,
          title: Text("Mortgage & \n Insurance"),
          content: SizedBox(
              height: 585,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start, children: [
                SizedBox(
                  height: 15,
                ),
                SizedBox(
                  height: 55,
                  width: 360,
                  child: TextFormField(
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),

                      hintText: 'Mortgage and Insurance*',
                      //filled: true,
                      //fillColor: const Color(0xfff1f1f1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    controller:propertyTypeController,
                  ),
                ),
              ]))),
    ];
  }

  setAddress(String data) {
    zpid = listOfAddress[data]!;
    propertyAddressController.text = data;
    if (zpid != null) {
      searchZillow(zpid);
    }

  }

  Map<String, String> listOfAddress = {};

  Future<List<String>> _handleSearch(String value) async {
    listOfAddress.clear();
    if (value.length > 12) {
      String url =
      "https://zillow-com4.p.rapidapi.com/properties/auto-complete?location=${value.replaceAll(' ', '%20')}";
      Map<String, String> requestHeaders = {
        "Content-Type": "application/json",
        "X-RapidAPI-Key": "c7eeed3c65msh4df3affb64a5fa3p18214cjsn2d3cb1e0fbd8",
        "X-RapidAPI-Host": "zillow-com4.p.rapidapi.com",

      };
      final response = await http.get(Uri.parse(url), headers: requestHeaders);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data != null && data['data'] != null) {
          List<dynamic> result = data['data'];
          result.forEach((element) {
            //listOfAddress.add(element['display']);
            if (element['metaData'] != null && element['metaData']['zpid'] != null && element['display'] != null)
               listOfAddress[element['display']] =element['metaData']['zpid'].toString();
          });
        }
      }
    }
    return listOfAddress.keys.toList();
  }

  void searchZillow(String zpid) async {
    /*client.prepare("GET", "https://zillow56.p.rapidapi.com/property?zpid=31956986")
        .setHeader("X-RapidAPI-Key", "c7eeed3c65msh4df3affb64a5fa3p18214cjsn2d3cb1e0fbd8")
        .setHeader("X-RapidAPI-Host", "zillow56.p.rapidapi.com")
        .execute()
        .toCompletableFuture()
        .thenAccept(System.out::println)
        .join();*/
    String url =
        "https://zillow56.p.rapidapi.com/property?zpid=${zpid.replaceAll(' ', '%20')}";
    Map<String, String> requestHeaders = {
      "Content-Type": "application/json",
      "X-RapidAPI-Key": "c7eeed3c65msh4df3affb64a5fa3p18214cjsn2d3cb1e0fbd8",
      "X-RapidAPI-Host": "zillow56.p.rapidapi.com",

    };
    final response = await http.get(Uri.parse(url), headers: requestHeaders);

    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      var val = (body != null) ? body['homeType'] : " ";
      if (body!= null) {
        val = val + " bathroom" + ((body['bathrooms'] != null)
            ? body['bathrooms'].toString()
            : " ");
        val = val + " bedroom" + ((body['bedrooms'] != null) ? body['bedrooms'].toString() : "");
        val = val + " livingArea" + ((body['livingArea'] != null)
            ? body['livingArea'].toString()
            : "");
        propertyNameController.text =
        (body['address'] != null && body['address']['streetAddress'] != null)
            ? body['address']['streetAddress']
            : "";

        propertyTypeController.text = val;
        propertyImageURLController.text =
        (body['streetView'] != null && body['streetView']['addressSources'] != null && (body['streetView']['addressSources']).length >2) ?
        (body['streetView']['addressSources'])[2]['url'] : "";
      }


    }

  }

  List<Step> getUnitSteps() {
    List<Step> retVal = [];
    for (int i=0; i< int.parse(numberOfUnitController.text);i++) {
      retVal.add(Step(
          state: currentStep > i+1 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 1+i,
          title:  Text("Unit Details for $i"),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 15,
              ),
              SizedBox(
                height: 45,
                width: 360,
                child: TextFormField(
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
                  controller: propertyAddressController,
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

                    hintText: 'Unit Type',
                    //filled: true,
                    //fillColor: const Color(0xfff1f1f1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  controller: propertyNameController,
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

                    hintText: 'Bedrooms',
                    //filled: true,
                    //fillColor: const Color(0xfff1f1f1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  controller: propertyTypeController,
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

                    hintText: 'Bathroom',
                    //filled: true,
                    //fillColor: const Color(0xfff1f1f1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  //controller: phoneNumberController,
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

                    hintText: 'Living Area',
                    //filled: true,
                    //fillColor: const Color(0xfff1f1f1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  // controller: emailController,
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

                    hintText: 'Lease Start Date',
                    //filled: true,
                    //fillColor: const Color(0xfff1f1f1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  // controller: emailController,
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

                    hintText: 'Lease End Date',
                    //filled: true,
                    //fillColor: const Color(0xfff1f1f1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  // controller: emailController,
                ),
              ),
            ],
          )));
      }
      return retVal;
    }

  Widget getListViewer() {
    return ListView.builder(
        itemCount:  2,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              print("tapped");
            },
            child: Card(

              child: ListTile(

                  title: Text("test" ,
                  style: TextStyle(fontSize: 14)),

                  leading: const CircleAvatar(
                      backgroundImage: AssetImage(
                          "assets/home2.png", ),
                  ),
                  ),)
            ,
          );
        });
  }

}
