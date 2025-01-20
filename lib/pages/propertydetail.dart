import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import '../model/property.dart';





class PropertDetailsPage extends StatefulWidget {
  const PropertDetailsPage({super.key});

  @override
  PropertyDetailsPageHome createState() => PropertyDetailsPageHome();
}

class PropertyDetailsPageHome extends State<PropertDetailsPage> {
  Map<String, int> rentalVal = {};
  //late PropertyModel propertyModel;
  String issueStatus = "Open";
  final widgetKey1 = GlobalKey();
  final widgetKey2 = GlobalKey();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  @override
  void didChangeDependencies() {

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: getTitle()

      ),
    );
  }


  List<Widget> getTitle() {

    return [


          Container(

             height: 150,
             width :  MediaQuery.of(context).size.width-5,
             child:  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children:[
              _buildUserStatsItem("23", "Rented", "0", "Vacant",Colors.blue[200]!),
               _buildUserStatsItem("5", "Paid Full", "18", "Paid Partial",Colors.green[200]!),
               _buildUserStatsItem("\$21,000", "Recieved", "\$21,900", "Balance", Colors.purple[200]!),
            ])
          ),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.blue[200],
              border: Border(
                  left: BorderSide(color: Colors.blue[200]!, width: 3.0),
                  top: BorderSide(color: Colors.blue[200]!, width: 3.0),
                  right: BorderSide(color: Colors.blue[200]!, width: 3.0)),
              image: DecorationImage(image: CachedNetworkImageProvider("https://photos.zillowstatic.com/fp/38717538eade4f49410d749d0d884b74-cc_ft_768.webp"),
              fit : BoxFit.cover),
            ),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blueGrey.withOpacity(0.8),
                    Colors.blueGrey.withOpacity(0.6),

                  ],
                  stops: [0.0,1],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight
                )
              ),
              child:  Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.only(top:2,left: 10),
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children:[Icon(Icons.home, color: Colors.white,),Text("Pine Ridge Rd", style: TextStyle(fontSize: 18,color: Colors.white),),]),
                        SizedBox(height: 5,),
                        FittedBox(fit: BoxFit.contain, child: Text("3702 Pine Ridge Rd, Orland FL 32808", style: TextStyle(color: Colors.white,fontSize: 16),)),

                        Row(children:[Text("1 Unit\u27394Beds\u27392.5Ba\u27391500 ft ", style: TextStyle(color: Colors.white,fontSize: 14),),
                        Spacer(),
                        IconButton(onPressed: (){}, icon: Icon(Icons.more_vert,color: Colors.white,),)])
                    ],
                ),
              ),
            ),
            ),),

      Card(
        elevation: 4,
        margin: EdgeInsets.zero,
        color: Colors.white,

        shape:
        Border( bottom: BorderSide(color: Colors.blue[200]!, width: 3.0),
            right: BorderSide(color: Colors.blue[200]!, width: 3.0)
        ),
        child: InkWell(
          onTap: (){},
          onDoubleTap: (){print('double tap');},
          child: Row(
            children: [
              Container(
                width: 50,
                height: 110,
                child:Center(
                  child: RotatedBox(
                      quarterTurns: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                          Text("Main Unit", style: TextStyle(fontSize: 14, color: Colors.black),),
                          FittedBox(fit: BoxFit.contain, child: Text("Pine Ridge Rd", style: TextStyle(fontSize:12,color: Colors.black.withOpacity(0.5)),)),
                        ],
                      )),
                ),
                decoration: BoxDecoration(
                    color: Colors.blue[200],
                    borderRadius:
                    BorderRadius.horizontal(left: Radius.zero)),
              ),
              Container(
                width: MediaQuery.of(context).size.width-110,
                height: 110,

                decoration: BoxDecoration(
                    //color: Colors.white70,
                    borderRadius:
                    BorderRadius.horizontal(right: Radius.zero)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0,4,4,4),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[RichText(text: TextSpan(text: "Sarai Pola", style: TextStyle(fontSize: 18, color: Colors.black),
                          children:[
                          TextSpan(text: "  (\$1,500/monthly)", style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.6)))])),

                  Row(children: [Icon(Icons.key_rounded,color: Colors.grey.withOpacity(0.6),),
                    Text(" 2/1/24 - 2/1/25 (Yearly)", style: TextStyle(color: Colors.black.withOpacity(0.6)),),
                  //Spacer(),

                  ]),
                  Text("\$200.00", style: TextStyle(fontSize: 18),),
                        Text("Tenant Balance", style: TextStyle(color: Colors.black.withOpacity(0.6))),

                      ]),
                ),
              ),
              Container(width:30, height: 110, child:
              GestureDetector(
                key: widgetKey1,
                child: IconButton(onPressed: (){
          showMenu(
            items: <PopupMenuEntry>[
              PopupMenuItem(
                //value: this._index,
                child: Row(
                  children: const [Text("Context item 23")],
                ),
              )
            ],
            context: context,
            position: _getRelativeRect(widgetKey1),
          );
                }, icon: Icon(Icons.more_vert_sharp, color: Colors.black.withOpacity(0.6),)),
              )),
            ],
          ),
        ),
      ),
      SizedBox(height: 5,),
      Card(
        margin: EdgeInsets.fromLTRB(0,8,0,0),
        elevation: 8,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.green[200],
            border: Border(
                left: BorderSide(color: Colors.green[200]!, width: 3.0),
                top: BorderSide(color: Colors.green[200]!, width: 3.0),
                right: BorderSide(color: Colors.green[200]!, width: 3.0)),
            image: DecorationImage(image: CachedNetworkImageProvider("https://photos.zillowstatic.com/fp/eac57ce7f97b0498027423bfbe7cbc54-cc_ft_384.webp"),
                fit : BoxFit.cover),
          ),
          child: Container(
            height: 140,

            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [
                      Colors.blueGrey.withOpacity(0.8),
                      Colors.blueGrey.withOpacity(0.6),
        
                    ],
                    stops: [0.0,1],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight
                )
            ),
            child:  Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.only(top:2,left: 10),
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children:[Icon(Icons.home, color: Colors.white,),Text("89th St", style: TextStyle(fontSize: 18,color: Colors.white),),]),
                    SizedBox(height: 5,),
                    FittedBox(fit: BoxFit.contain,child: Text("37-54 89th St,Jackson Heights NY 11372", style: TextStyle(color: Colors.white,fontSize: 16),)),
        
                    Row(children:[Text("5 Units\u273911Beds\u27395Ba\u27393700 ft ", style: TextStyle(color: Colors.white,fontSize: 14),),
                      Spacer(),
                      IconButton(onPressed: (){}, icon: Icon(Icons.more_vert,color: Colors.white,),)])
                  ],
                ),
              ),
            ),
          ),),
      ),

      Card(
        elevation: 4,
        margin: EdgeInsets.zero,
        color: Colors.white,

        shape:
           Border( bottom: BorderSide(color: Colors.green[200]!, width: 3.0),
               right: BorderSide(color: Colors.green[200]!, width: 3.0)
        ),
        child: InkWell(
          onTap: (){},
          onDoubleTap: (){print('double tap');},
          child: Row(
            children: [
              Container(
                width: 50,
                height: 110,
                child:Center(
                  child: RotatedBox(
                      quarterTurns: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                          Text("Basement", style: TextStyle(fontSize: 14, color: Colors.black),),
                          FittedBox(fit: BoxFit.contain,child: Text("89th St", style: TextStyle(fontSize:12,color: Colors.black.withOpacity(0.5)),)),
                        ],
                      )),
                ),
                decoration: BoxDecoration(
                    color: Colors.green[200],
                    borderRadius:
                    BorderRadius.horizontal(left: Radius.zero)),
              ),
              Container(
                width: MediaQuery.of(context).size.width-110,
                height: 110,

                decoration: BoxDecoration(
                  //color: Colors.white70,
                    borderRadius:
                    BorderRadius.horizontal(right: Radius.zero)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0,4,4,4),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[RichText(text: TextSpan(text: "Miguel Karman", style: TextStyle(fontSize: 18, color: Colors.black),
                          children:[
                            TextSpan(text: "  (\$2,000/monthly)", style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.6)))])),

                        Row(children: [Icon(Icons.key_rounded,color: Colors.grey.withOpacity(0.6),),
                          Text(" 1/1/24 - 1/1/25 (Yearly)", style: TextStyle(color: Colors.black.withOpacity(0.6)),),
                          //Spacer(),

                        ]),
                        Text("\$200.00", style: TextStyle(fontSize: 18),),
                        Text("Tenant Balance", style: TextStyle(color: Colors.black.withOpacity(0.6))),

                      ]),
                ),
              ),
              Container(width:30, height: 110, child:
              GestureDetector(
                key: widgetKey1,
                child: IconButton(onPressed: (){
                  showMenu(
                    items: <PopupMenuEntry>[
                      PopupMenuItem(
                        //value: this._index,
                        child: Row(
                          children: const [Text("Context item 23")],
                        ),
                      )
                    ],
                    context: context,
                    position: _getRelativeRect(widgetKey1),
                  );
                }, icon: Icon(Icons.more_vert_sharp, color: Colors.black.withOpacity(0.6),)),
              )),
            ],
          ),
        ),
      ),

    ];

  }

  _buildUserStatsItem(String s, String t, String s2, String t2, Color c) {
    return Container(
      decoration: BoxDecoration(
        color: c,
      ),
      height: 130,
      width: (MediaQuery.of(context).size.width/3)-15,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(s, style: TextStyle(fontSize: 16, color: Colors.black)),
          SizedBox(height: 5),
          Text(t, style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(.5))),
          SizedBox(height: 10,),
          Text(s2, style: TextStyle(fontSize: 16, color: Colors.black)),
          SizedBox(height: 5),
          Text(t2, style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(.5))),

        ],
      ),
    );
  }

  RelativeRect _getRelativeRect(GlobalKey key){
    return RelativeRect.fromSize(
        _getWidgetGlobalRect(key), const Size(200, 200));
  }

  Rect _getWidgetGlobalRect(GlobalKey key) {
    final RenderBox renderBox =
    key.currentContext!.findRenderObject() as RenderBox;
    var offset = renderBox.localToGlobal(Offset.zero);
    debugPrint('Widget position: ${offset.dx} ${offset.dy}');
    return Rect.fromLTWH(offset.dx / 3.1, offset.dy * 1.05,
        renderBox.size.width, renderBox.size.height);
  }
}


