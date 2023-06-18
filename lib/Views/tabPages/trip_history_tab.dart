import 'dart:core';

import 'package:car_pool_driver/Models/request.dart';
import 'package:car_pool_driver/Models/trip.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../Constants/styles/colors.dart';
import '../../global/global.dart';
import '../../widgets/progress_dialog.dart';
import 'bookedTripDetails.dart';

class TripHistoryTabPage extends StatefulWidget {
  const TripHistoryTabPage({Key? key}) : super(key: key);

  @override
  State<TripHistoryTabPage> createState() => _TripHistoryTabPageState();
}





class _TripHistoryTabPageState extends State<TripHistoryTabPage> {
  List<Request> requests = [];
  List<Request> finishedRequests = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    isLoading = true;
    getFinishedRequests().then((_) {
      setState(() {
        isLoading = false;
      });
    });
  }
  final databaseReference = FirebaseDatabase.instance.ref('requests');
  Future<List<Request>> getRequests(String userID) async {
    List<Request> itemList = [];
    // Get a reference to the Firebase database

    try {

      final dataSnapshot = await databaseReference
          .orderByChild('userID')
          .equalTo(userID)
          .once();

      Map<dynamic, dynamic> values =
      dataSnapshot.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        final item = Request(
            requestID: value['requestID'],
            tripID: value['tripID'],
            driverID: value['driverID'],
            userID: value['userID'],
            status: value['status']);
        itemList.add(item);
      });
    } catch (e) {
      // Log the error and return an empty list
      print('Error: $e');
    }
    return itemList;
  }

  Future<void> getFinishedRequests() async {
    List<Request> requests = await getRequests(currentFirebaseUser!.uid.toString());
    setState(() {
      this.requests = requests;
      for (var r in requests) {
        if (r.status == 'finished' || r.status == 'cancelled') finishedRequests.add(r);
      }
    });
  }
  final ref = FirebaseDatabase.instance.ref('trips');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: (finishedRequests.isEmpty) ? Colors.white : const Color(0xFFEDEDED),
      body:Stack(
        children: [
          if(isLoading)
            ProgressDialog(message: "Processing....",)
          else
            Center(
              child: (finishedRequests.isEmpty) ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "images/noHistory.jpg",
                    height: 250,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text(
                    "YOU HAVE NO PAST BOOKED TRIPS !!!",
                    style: TextStyle(
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ): ListView.builder(
                  itemCount: finishedRequests.length,
                  itemBuilder: (context, index) {
                    return StreamBuilder(
                      stream: ref.child(finishedRequests[index].tripID).onValue,
                      builder: (context, AsyncSnapshot snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData ||
                            snapshot.data?.snapshot?.value == null) {
                          return Container();
                        } else {
                          Map<dynamic, dynamic> trip = snapshot.data.snapshot.value;
                          return buildTripDetails(trip, finishedRequests[index], index);
                        }
                      },
                    );
                  },
                ),
            )
        ] ,
      )
    );
  }

  Widget buildTripDetails(Map<dynamic, dynamic> trip, Request request, int index) => Column(
    children: [
      const SizedBox(height: 15,),
      ListTile(

        title: Text(
          trip['destinationLocation'],
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w100,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10,),
            Text(
              '${trip['date']} at ${trip['time']}',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            Text(
              request.status.toUpperCase(),
              style:
              TextStyle(fontSize: 14,
                  color: (request.status == 'finished') ? Colors.greenAccent : Colors.redAccent),
            ),
          ],
        ),
        trailing: const Icon(Icons.navigate_next),
        onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => MyBookedTrips(request: finishedRequests[index],),
           ));
        },
      ),
      const Padding(
        padding: EdgeInsets.all(8.0),
        child: Divider(
          color: ColorsConst.grey,
        ),
      ),
    ],
  );


}
