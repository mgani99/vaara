import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_search_bar/easy_search_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/pages/PageStatics.dart';
import 'package:my_app/pages/newissue.dart';
import 'package:my_app/services/TransactionService.dart';
import 'package:provider/provider.dart';
import '../model/property.dart';
import 'dart:ui' as UI;


class RepairPage extends StatefulWidget {
  const RepairPage({super.key});

  @override
  RepairPageHome createState() => RepairPageHome();
}

class RepairPageHome extends State<RepairPage> {
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
        ListTile(
          splashColor: Colors.blue[100],
          title: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            //color:Colors.blue[100],
            //shape: MediaQuery.removePadding(context: context, child: child),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Container(
                  width: 140,
                  height: 140.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(image: CachedNetworkImageProvider("https://photos.zillowstatic.com/fp/38717538eade4f49410d749d0d884b74-cc_ft_768.webp"),
                      fit: BoxFit.cover,)
                    ),
                         ),
              Spacer(),
              Align(
                alignment: Alignment.topRight,
                child: Container(
                    padding: EdgeInsets.all(16.0),
                    alignment: Alignment.topRight,
                  child : Row(children:[Icon(Icons.home),Text("3340 Basie Pl"),])),
              )])),
        ),

          /*Container(
            height: 100,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children:[

                  Text("3340 Basie Pl, Orland FL 32808"),]),

          ),]))*/

        Card(
          color:Colors.blue[100],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Container(
            color: Colors.blue[100],
            width: 550,
            height: 120,
            child: Center(
              child: RotatedBox(
                  quarterTurns: 3,
                  child: Text("Main Unit")
              ),
            ),
          ),
         // title: Text("Tabith Norfus"),

        ),






    ];

  }

}
