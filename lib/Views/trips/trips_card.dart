import 'package:car_pool_driver/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';

import '../../Constants/styles/colors.dart';

class TripCards extends StatelessWidget {
  TripCards({Key? key}) : super(key: key);
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return FirebaseAnimatedList(
      query: tripsRef.orderByChild("driver_id").equalTo(_auth.currentUser?.uid),
      shrinkWrap: true,
      itemBuilder: ((context, snapshot, animation, index) {
        Map pools = snapshot.value as Map;
        pools['key'] = snapshot.key;
        return ListTile(
          title: Column(
            children: [
              Text(pools['destinationLocation']),
              Text(pools['pickUpLocation']),
            ],
          ),
          subtitle: Text(pools['passengers']),
          trailing: Text(pools['estimatedCost']),
        );
      }),
    );
    // return Container(
    //   padding: const EdgeInsets.all(10.0),
    //   height: 220,
    //   width: double.maxFinite,
    //   child: Card(
    //     elevation: 2.0,
    //     child: Padding(
    //       padding: const EdgeInsets.all(8.0),
    //       child: Stack(
    //         children: [
    //           Align(
    //             alignment: Alignment.centerRight,
    //             child: Stack(
    //               children: <Widget>[
    //                 Padding(
    //                     padding: const EdgeInsets.only(left: 10, top: 5),
    //                     child: Column(
    //                       children: <Widget>[
    //                         Row(
    //                           children: <Widget>[
    //                             userIcon(),
    //                             const SizedBox(
    //                               height: 10,
    //                               width: 10,
    //                             ),
    //                             driverInfo(),
    //                             const Spacer(),
    //                             tripPrice(),
    //                             const SizedBox(
    //                               width: 10,
    //                             ),
    //                           ],
    //                         ),
    //                         Row(
    //                           children: <Widget>[locationAndDestination()],
    //                         )
    //                       ],
    //                     ))
    //               ],
    //             ),
    //           )
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }

  Widget userIcon() {
    return const Padding(
      padding: EdgeInsets.only(left: 1.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 20.0,
        ),
      ),
    );
  }

  Widget driverInfo() {
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: const TextSpan(
          text: "Abiy Zebene",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ColorsConst.black,
              fontSize: 17),
          children: <TextSpan>[
            TextSpan(
                text: "\nGrey Toyota Vitz",
                style: TextStyle(
                    color: ColorsConst.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            TextSpan(
                text: "\nA21124",
                style: TextStyle(
                    color: ColorsConst.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget tripPrice() {
    return const Align(
      alignment: Alignment.topRight,
      child: Text(
        "120 br.",
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ColorsConst.green,
            fontSize: 16),
      ),
    );
  }

  Widget locationAndDestination() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: Row(
          children: <Widget>[
            RichText(
              textAlign: TextAlign.left,
              text: const TextSpan(
                text: "\nStarting at: Mexico",
                style: TextStyle(
                    color: ColorsConst.grey,
                    fontSize: 18,
                    fontWeight: FontWeight.w500),
                children: <TextSpan>[
                  TextSpan(
                      text: "\nDestination: Arat Kilo",
                      style: TextStyle(
                          color: ColorsConst.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
