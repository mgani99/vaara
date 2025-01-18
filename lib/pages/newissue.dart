

import 'dart:io';


import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_app/model/property.dart';
import 'package:my_app/pages/contractor.dart';
import 'package:provider/provider.dart';
import 'package:standard_searchbar/old/standard_searchbar.dart';
import '../services/TransactionService.dart';
import 'PageStatics.dart';


class NewIssue extends StatefulWidget {
  bool insertMode = true;
  Issue? newIssue;
  NewIssue({super.key,required this.newIssue, required this.insertMode});
  @override
  _NewIssueState createState() => _NewIssueState();
}



class _NewIssueState extends State<NewIssue> {
  int currentStep = 0;

  bool hide = false;
  String? searchValue;
  Contractor? contractor;
  String paymentStatus = "Not Paid";
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final dateOfIssueController = TextEditingController();
  final laborCostController = TextEditingController();
  final materialCostController = TextEditingController();
  final commentController = TextEditingController();
  final contractorController = TextEditingController();
  late PropertyModel propertyModel;
  Map<String, int> rentalVal = {};
  String? issueStatus;

  String getButtonText() {
    if (currentStep == 0 )return '';
    else if (currentStep == 1) return "Skip";
    else return "Cancel";
  }

  @override
  void dispose() {
    // TODO: implement dispose


    titleController.dispose();
    descriptionController.dispose();
    dateOfIssueController.dispose();
    laborCostController.dispose();
    commentController.dispose();
    contractorController.dispose();
    materialCostController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    ControlsDetails? t;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            "New Issue ",
          ),
          centerTitle: true,
        ),
        body: Stack(


          children: [

            Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Stepper(
              type: StepperType.horizontal,
              controlsBuilder: (BuildContext ctx, ControlsDetails dtl){
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
                          ])],
                      //Pos
                    );
                  },


              currentStep: currentStep,
              onStepCancel: () => currentStep == 0
                  ? null
                  : setState(() {
                currentStep -= 1;
              }),

              onStepContinue: () {
                bool isLastStep = (currentStep == getSteps().length - 1);
                if (isLastStep) {
                  saveOrUpdateIssue();
                  //Do something with this information
                } else {
                  setState(() {
                    currentStep += 1;
                  });
                }
              },
              onStepTapped: (step) => setState(() {
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

  void saveOrUpdateIssue() async{
    Issue? newIssue;
    if (widget.insertMode) {
     newIssue =   Issue(title: titleController.text,
          description: descriptionController.text,
          rentableId: rentalVal[rentalNameKey] ?? 0,
          dateOfIssue: DateFormat(PropertyModel.PAYMENT_DATE_FORMAT).parse(
              dateOfIssueController.text),
          status: issueStatus!);
    }
    else {
      newIssue = widget.newIssue;
      newIssue!.description = descriptionController.text;
      newIssue!.status = issueStatus!;
    }
    newIssue.materialCost = double.parse(materialCostController.text.isNotEmpty ? materialCostController.text : "0.0");
    newIssue.laborCost = double.parse(laborCostController.text.isNotEmpty ? laborCostController.text : "0.0");
    newIssue.contractorId = contractor!.id;
    newIssue.paidStatus = paymentStatus ?? "";
    //newIssue.comment = commentController.text;
    if (images != null && images.length> 0) {
       TransactionService.handleUploadImage(newIssue, images).then((value) => newIssue!.imageUrls=value);
      //newIssue.imageUrls = urls;
    }

    propertyModel.addIssue(newIssue);
    Navigator.pop(context);
  }

  final List<String> _results = [];
  Map<String, Contractor> contractorsMap = {};
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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    dateOfIssueController.text = DateFormat(PropertyModel.PAYMENT_DATE_FORMAT).format(DateTime.now());
  }
  @override
  void didChangeDependencies() {
    propertyModel = context.watch<PropertyModel>();
    propertyModel.allCards.forEach((element) {
      rentalVal.addAll({element.propName + " " + element.unitName: element.id});
    });
    propertyModel.allContractors.forEach((element) {
      contractorsMap[element.firstName + " " + element.lastName] = element;
    });

    if (!widget.insertMode)  {
      setState(() {
        titleController.text = widget.newIssue!.title;

        descriptionController.text = widget.newIssue!.description;
        dateOfIssueController.text = DateFormat(PropertyModel.PAYMENT_DATE_FORMAT).format(widget.newIssue!.dateOfIssue);
        laborCostController.text = widget.newIssue!.laborCost.toString();
        materialCostController.text = widget.newIssue!.materialCost.toString();
        commentController.text = widget.newIssue!.comment;
        paymentStatus = widget.newIssue!.paidStatus;
        rentalNameKey = getRentValue(widget.newIssue!.rentableId);
        var result =  propertyModel.allContractors.where((element) => element.id == widget.newIssue!.contractorId);
        contractor= (result.length > 0 ) ? result.first : Contractor.nullContractor();
        contractorController.text = contractor!.firstName + " " + contractor!.lastName;
        issueStatus = widget.newIssue!.status!.isEmpty ? null : widget.newIssue!.status;
        //@todo image edit.

      });


    }
  }




  String getRentValue(int rentableId) {
    String retVal = rentalVal.keys.first;
    rentalVal.forEach((key, value) {if (value == rentableId) retVal = key; });
    return retVal;
  }
  String? rentalNameKey;

    List<Step> getSteps() {
      return <Step>[
        Step(
          state: currentStep > 0 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 0,
          title: const Text("Issue"),

          content: Column(
            children:  [
              SizedBox(
                height: 55,
                width: 360,
                child: DropdownButtonFormField<String>(
                  value: rentalNameKey,

                  elevation: 5,
                  isExpanded: true,
                  //style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(10.0),

                    hintText: 'Select Rental Unit',
                    //filled: true,
                    //fillColor: const Color(0xfff1f1f1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),),

                  items: rentalVal.keys.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      alignment: AlignmentDirectional.center,
                      child: Text(value),
                    );
                  }).toList(),
                  hint: const Text(
                    "Which Rental has Issue*",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        //color: Colors.black,
                        fontSize: 16,

                        fontWeight: FontWeight.w600),
                  ),
                  onChanged: (String? value) {
                    setState(() {
                      rentalNameKey = value!;
                    });
                  },
                ),
              ),
              SizedBox(height: 10),
              CustomInput(
                hint: "Title *",
                mandatory : true,
                editMode: !widget.insertMode,
                controller: titleController,
                inputBorder: OutlineInputBorder(),
              ),

              CustomInput(
                hint: "Issue Date*",
                mandatory: true,
                editMode: !widget.insertMode,
                controller: dateOfIssueController,
                inputBorder: OutlineInputBorder(),
              ),
              CustomInput(
                hint: "Issue Description",
                controller: descriptionController,
                inputType: TextInputType.multiline,
                inputBorder: OutlineInputBorder(),
              ),
              SizedBox(
                height: 55,width: 360,
                child: DropdownButtonFormField<String>(
                  value: issueStatus,
                  elevation: 5,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(10.0),
                    hintText: 'Issue Status',
                    //filled: true,
                    //fillColor: const Color(0xfff1f1f1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),),

                  items: <String>[
                    PageStatics.OPEN_FOR_ISSUETYPEVALUE,
                    'Pending',
                    'Complete',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  hint: const Text(
                    "Select Issue Status",
                    style: TextStyle(
                        //color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  onChanged: (String? value) {
                    setState(() {
                      issueStatus = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Step(

          state: currentStep > 1 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 1,
          title: const Text("Pictures"),
          content: Column(
            children: <Widget>[

              Container(
                margin: const EdgeInsets.only(top: 80),
                child: Column(
                  children: <Widget>[

                    SizedBox(height: 20.0),



                          Container(
                            //height: double.infinity,
                            margin: const EdgeInsets.only(
                                left: 30.0, right: 30.0, top: 10.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30.0),
                              child: !images.isEmpty
                                  ? Column(children: getImages())
                                  : TextButton(
                                child: Icon(
                                  Icons.add_a_photo,
                                  size: 50,
                                ),
                                onPressed: pickImage,
                              ),
                            ),
                          ),



                   // uploadImageButton(context),
                  ],
                ),
              ),
            ],
          ),
        ),
        Step(
          state: currentStep > 2 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 2,
          title: const Text("Contractor"),

          content: Column(

            children:  [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                  children: [SizedBox(
                  height: 56,
                  width: 240,
                  child: StandardSearchBar(
                      )),
              SizedBox(height: 15,),
              FloatingActionButton(onPressed:() {print('pressed');
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ContractorPage(

                            //insertMode: true,
                            //UploadingImageToFirebaseStorage()

                          )));
                }, child: Icon(Icons.add_circle)),
              ]),
              SizedBox(
                height: 100,
              child: Card(
                  child:(contractor== null? Container(): _buildTitle(contractor!))),
              ),
              SizedBox(height: 15,),
              CustomInput(
                hint: "Labor Cost",
                controller: laborCostController,
                inputBorder: OutlineInputBorder(),
              ),
              CustomInput(
                hint: "Material Cost",
                controller: materialCostController,
                inputBorder: OutlineInputBorder(),
              ),
              SizedBox(
                height: 45,width: 360,
                child: DropdownButtonFormField<String>(
                  value:paymentStatus,
                  elevation: 5,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(10.0),

                    hintText: 'Payment Status',
                    //filled: true,
                    //fillColor: const Color(0xfff1f1f1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),),

                  items: <String>[
                    PageStatics.PAID,
                    'Not Paid',

                  ].map<DropdownMenuItem<String>>((String? value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value!),
                    );
                  }).toList(),
                  hint: const Text(
                    "Select Payment Status",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  onChanged: (String? value) {
                    setState(() {
                      paymentStatus = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ];
    }
  File? _imageFile;




  setContractor(data) {
    print(data);
    setState(() {
      contractor = contractorsMap[data]!;
    });
  }

  final picker = ImagePicker();
  List<File> images=[];
  Future pickImage() async {


    final pickedFile = await ImagePicker().pickMultiImage(
      imageQuality: 70,
      maxWidth: 1440,

    );
    pickedFile!.forEach((image) {
      setState(() {
        images!.add(File(image.path));
      });

    });
    //getImage(source: ImageSource.camera);

  }




  Widget uploadImageButton(BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          Container(
            padding:
            const EdgeInsets.symmetric(vertical: 5.0, horizontal: 16.0),
            margin: const EdgeInsets.only(
                top: 30, left: 20.0, right: 20.0, bottom: 20.0),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [yellow, orange],
                ),
                borderRadius: BorderRadius.circular(30.0)),
            child: TextButton(
              onPressed: () => {},
              child: Text(
                "Upload Image",
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getButtonRow(ControlsDetails dtls) {

    return Row(children: <Widget>[
    Expanded(
    child: Container(
    color: Colors.amber,
    height: 100,

    ),
    ),
    Expanded(
    child: Container(
    color: Colors.amber,
    height: 100,
      child: ElevatedButton(
          style: ButtonStyle(
              shape: MaterialStateProperty.all(const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(17),
                      bottomRight: Radius.circular(17),
                      topLeft: Radius.circular(17),
                      topRight: Radius.circular(0)))

              ),),


          onPressed: dtls.onStepContinue,
          child: Container(
              alignment: Alignment.center,
              margin:
              const EdgeInsets.symmetric(horizontal: 140, vertical: 20),
              child: const Text(
                'Next',
                style: TextStyle(fontSize: 14),
              ))),
    ),
    )]);
  }

  Widget _buildTitle(Contractor contractor) {


      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                "${contractor.firstName + " " + contractor.lastName} ",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Text("${contractor.mobilePhone}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
              //@todo get rent
            ],
          ),

           Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
            ButtonBar(
            alignment: MainAxisAlignment.spaceEvenly,

              children: [
                TextButton(
    //textColor: const Color(0xFF6200EE),
                  onPressed: () {propertyModel.removeContractor(contractor);  },
                  child: Text("Delete", style: TextStyle(color:  Color(0xFF6200EE),)),
                 ),
                TextButton(


           onPressed: () {

             Navigator.push(
                  context,
                       MaterialPageRoute(
                           builder: (context) =>
                               ContractorPage(contractor: contractor,)



               ));
            },
             child: const Text('Edit', style: TextStyle(color: Color(0xFF6200EE),)),
             ),
              ],
            ),
          ],)

        ],
      );
    }

  List<Widget>

  getImages() {

    List<Widget> retVal = [];
    images.forEach((element) => retVal.add(Image.file(element)));
    return retVal;

  }
}



class CustomInput extends StatelessWidget {
  //final ValueChanged<String>? onChanged;
  final String? hint;
  final InputBorder? inputBorder;
  final TextEditingController? controller;
  final bool? mandatory ;
  final TextInputType? inputType;
  final bool editMode;
  const CustomInput({Key? key, this.hint, this.inputBorder, this.controller, this.mandatory, this.inputType, this.editMode = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    FontWeight fw = (mandatory != null && mandatory == true) ? FontWeight.bold : FontWeight.normal;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      child: TextField(
        //onChanged: (v) => onChanged!(v),
        decoration: InputDecoration(hintText: hint!, border: inputBorder,
            hintStyle:  TextStyle(fontWeight: fw)),
        controller: controller,
        readOnly: editMode,
        keyboardType: inputType,
        maxLines: (inputType == TextInputType.multiline) ?  null :  1,
        // validator: (value) {
        //   if (mandatory != null && mandatory == true) {
        //   if (value!.isEmpty || value.length < 1) {
        //   return 'Please enter value';
        //   }}},
      ),
    );
  }
}

class CustomBtn extends StatelessWidget {
  final Function? callback;
  final Widget? title;
  CustomBtn({Key? key, this.title, this.callback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          color: Colors.blue,
          child: TextButton(
            onPressed: () => callback!(),
            child: title!,
          ),
        ),
      ),
    );
  }
}

final Color yellow = Color(0xfffbc31b);
final Color orange = Color(0xfffb6900);