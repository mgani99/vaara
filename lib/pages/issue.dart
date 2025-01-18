
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/pages/PageStatics.dart';
import 'package:my_app/pages/newissue.dart';
import 'package:my_app/services/TransactionService.dart';
import 'package:provider/provider.dart';
import '../model/property.dart';


class IssuePage extends StatefulWidget {
  const IssuePage({super.key});

  @override
  IssuePageHome createState() => IssuePageHome();
}

class IssuePageHome extends State<IssuePage> {
  Map<String, int> rentalVal = {};
  late PropertyModel propertyModel;
  String issueStatus = "Open";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  @override
  void didChangeDependencies() {
    propertyModel = context.watch<PropertyModel>();
    initRentVal(propertyModel);
    getIssueList(0);//initialize w/ all first;
  }

  @override
  Widget build(BuildContext context) {
     TabBar upperTab =  TabBar(indicatorColor: Colors.white, tabs: <Tab>[
      Tab(child: Text("Open Issues", style: TextStyle(fontFamily: "BarlowBold", color: Colors.black, fontSize: 18))),
      Tab(child: Text("All Issues", style: TextStyle(fontFamily: "BarlowBold", color: Colors.black, fontSize: 18))),

    ],
   onTap:  (index) {setState(() {
     issueStatus = index ==0 ? "Open" : "All";
   });});


    return
      DefaultTabController(
        length: 2,
        child: Scaffold(
        appBar:  PreferredSize(
        preferredSize: Size(30, 220),
        child:  SizedBox(width: 40,height: 70,
          child: Card(
            elevation: 20.0,
            //color: Theme.of(context).primaryColor,
            child:upperTab),
        ),
        ),
          body:  TabBarView(
        children: [
        allIssue(),
        allIssue(),


        ],
      ),
        ),
      );
  }
  List<Issue> listOfIssueToShow = [];
  void getIssueList(int rentableId) {
    listOfIssueToShow = propertyModel.allIssues;
    if (rentableId != 0) {
      listOfIssueToShow = listOfIssueToShow.where((element) => element.rentableId ==
          rentableId).toList();
    }
    if ("Open" == issueStatus) {
      listOfIssueToShow = listOfIssueToShow.where((element) => element.status != PageStatics.COMPLETE_FOR_ISSUETYPEVALUE).toList();

    }

  }




  String? rentalNameKey;
  Widget allIssue() {

    setState(() {
      getIssueList(rentalVal[rentalNameKey] ?? 0 );
      listOfIssueToShow;
    });
    return Consumer<PropertyModel>(builder: (context, props, child) {


    String searchValue;
    return Container(
      // elevation: 6,
      //margin: EdgeInsets.all(4.0),
      //appBar: new PreferredSize(preferredSize: tab.preferredSize,
        child:
        //print("length of all props ${props.allCards.length}");
        Column(children: [
          SizedBox(height: 15,),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Filter", style: TextStyle
              (fontSize: 16),),
            SizedBox(width: 5,),
            SizedBox(
                height: 55,
                width: 280,
                child: DropdownButtonFormField<String>(
                  value: rentalNameKey,

                  elevation: 25,
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
                    "Select Issue with Rental*",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,

                        fontWeight: FontWeight.w600),
                  ),
                  onChanged: (String? value) {
                    setState(() {
                      rentalNameKey = value!;
                      int val = rentalVal[rentalNameKey]?? 0;
                      getIssueList(val );
                    });
                  },
                )),
          ],
        ),
          SizedBox(height: 15,),
          Expanded(

              child: ListView.builder(
                  itemCount: listOfIssueToShow.length,
                  
                  itemBuilder: (context, index) {
                    var issue = listOfIssueToShow[index];
                    var prop = propertyModel.getRentableModel(listOfIssueToShow[index].rentableId);
                    
                    String propertyName = prop.propName + ", " + prop.unitName;
                    var result =
                    props.allContractors.where((element) => element.id == issue.contractorId);
                    Contractor contractor =
                    (result.length > 0) ? result.first : Contractor.nullContractor();
                    if (contractor == null) contractor = Contractor.nullContractor();
                    return InkWell(
                      child:
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Card(

                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(15.0))),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Icon(Icons.home_repair_service_outlined),
                                  title:  Text('$propertyName'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children:[Text(
                                      '${issue.title}' ,style: TextStyle(color: Colors.black.withOpacity(0.8)),),
                                      Text(
                                        'Contractor: ${contractor.firstName + " " + contractor.lastName}' ,style: TextStyle(color: Colors.black.withOpacity(0.8)),),
                                    ],

                                  ),
                                  trailing: Column(children:[Text(DateFormat("MMM dd, yy").format(issue.dateOfIssue),style: TextStyle(color: Colors.black.withOpacity(0.8),fontSize: 14),
                                  ),Text("\$${(issue.materialCost + issue.laborCost).toStringAsFixed(0)}",style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 14),)]),
                                  //isThreeLine: true,

                                ),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(

                                    padding: const EdgeInsets.all(4.0),
                                    child: Text(
                                      '${issue.description}',
                                      style: TextStyle(color: Colors.black.withOpacity(0.6), ),
                                    ),
                                  ),
                                ),
                                getConditionalContainer(issue),



                              ],
                            ),
                          ),
                        ),

                    );
                  })),
        ]));
    });
  }
  List<Widget> getImages(Issue issue) {
    return [
      
      
      Card(
        
        margin: const EdgeInsets.only(right: 7, top: 0, bottom: 7),
        elevation: 7,
        child: FutureBuilder(
          future: TransactionService.fetchImages(issue),
          builder: (context, AsyncSnapshot<List<String>> snapshot) {
            if (snapshot.hasData){
              List<Widget> ws =[];
              snapshot.data!.forEach((element) {
                  ws.add(Image.network(element));
                });
            return Column(children: ws,);}



            // Return your "Sin Foto" text here.
           return Text("No image");
          },
        ))];
  }
  void initRentVal(PropertyModel propertyModel) {
    rentalVal['All'] = 0;
    propertyModel.allCards.forEach((element) {
      rentalVal.addAll({element.propName + " " + element.unitName: element.id});
    });

  }

  void setIssueStatus(int index) {
    setState(() {
      issueStatus = index == 0 ? "Open" : "All";
    });
  }

 Widget getConditionalContainer(Issue issue)  {
    String paidStatus = (issue.paidStatus == PageStatics.PAID)?"Mark Unpaid" : "Mark Paid";
    List<String> imageUrls = [];
    TransactionService.fetchImages(issue).then((value) => imageUrls = value);
    final children = [

    ButtonBar(
      alignment: MainAxisAlignment.spaceEvenly,

      children: [
        (issueStatus == "Open")? TextButton(


          onPressed: () {
            // Perform some action
          },
          child: const Text('  Mark\nComplete', style: TextStyle(color:  Color(0xFF6200EE),)),
        ) : Container(),
        FittedBox(
          child: TextButton(
          
          
            onPressed: () {
          
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          NewIssue(newIssue: issue,insertMode:false
          
                            //insertMode: true,
                            //UploadingImageToFirebaseStorage()
          
                          )));
            },
            child: const Text('Edit', style: TextStyle(color:  Color(0xFF6200EE),)),
          ),
        ),
        (issueStatus == "Open")? TextButton(
          //textColor: const Color(0xFF6200EE),
          onPressed: () {
            // Perform some action
          },
          child: Text(paidStatus, style: TextStyle(color:  Color(0xFF6200EE),)),
        ) : Container(),
        TextButton(
          //textColor: const Color(0xFF6200EE),
          onPressed: () {

            TransactionService.deleteImage(issue);
            propertyModel.removeIssue(issue);
            // Perform some action
          },
          child: Text("Delete", style: TextStyle(color:  Color(0xFF6200EE),)),
        ),

      ],
    ) ,

      Center(
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: ExpansionTile(
            // leading: SizedBox(width: 30,),
            backgroundColor: Colors.white,
            title: Text('Show Images', style: TextStyle(color:  Color(0xFF6200EE),)),
            //subtitle: ,
            trailing: SizedBox(width: 1,),
            children: getImages(issue),


          ),
        ),
      )
    ];
    return SingleChildScrollView(
      child: Column(
        children: children,
      ),
    );
  }

}
