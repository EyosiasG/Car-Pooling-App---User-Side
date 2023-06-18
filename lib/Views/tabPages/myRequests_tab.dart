import 'package:car_pool_driver/Models/request.dart';
import 'package:car_pool_driver/global/global.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../Constants/styles/colors.dart';
import '../../widgets/progress_dialog.dart';


class MyRequests extends StatefulWidget {
  const MyRequests({Key? key}) : super(key: key);

  @override
  State<MyRequests> createState() => _MyRequestsState();
}

class _MyRequestsState extends State<MyRequests> {
  List<Request> requests = [];
  List<Request> pendingRequests = [];
  bool isCancelled = false;
  List<bool> _isCancelButtonClickedList = [];
  String buttonText = 'Cancel';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    isLoading = true;
    getRequests().then((_) {
      setState(() {
        isLoading = false;
      });
    });
    _isCancelButtonClickedList = List.filled(pendingRequests.length, false);

  }

  final databaseReference = FirebaseDatabase.instance.ref('requests');

  Future<List<Request>> getPendingRequests() async {
    List<Request> itemList = [];

    try {


      final dataSnapshot = await databaseReference
          .orderByChild('userID')
          .equalTo(currentFirebaseUser!.uid)
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
      print('Error: $e');
    }
    return itemList;
  }

  Future<void> getRequests() async {
    List<Request> requests = await getPendingRequests();
    setState(() {
      this.requests = requests;
      for(var r in requests){
        if (r.status == 'pending') pendingRequests.add(r);
      }
      _isCancelButtonClickedList = List.filled(pendingRequests.length, false);
    });
  }

  final ref = FirebaseDatabase.instance.ref('trips');
  final driverRef = FirebaseDatabase.instance.ref('drivers');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: (pendingRequests.isEmpty) ? Colors.white : const Color(0xFFEDEDED),
      body: Stack(
        children: [
              if(isLoading)
                ProgressDialog(message: "Processing....",)
              else
                (pendingRequests.isEmpty) ?
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "images/noRequests.jpg",
                          height: 250,
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        const Text(
                          "YOU HAVE NO PENDING REQUESTS !!!",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.blueGrey, fontSize: 18),
                        ),
                      ],
                    ),
                  ):
                  ListView.builder(
                      itemCount: pendingRequests.length,
                      itemBuilder: (context, index) {
                        return StreamBuilder(
                          stream: ref.child(pendingRequests[index].tripID).onValue,
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
                              return buildDriverData(index, trip);
                            }
                          },
                        );
                      }),
            ],
          ),
    );
  }

  Widget buildTripDetail(int index) => StreamBuilder(
        stream: ref.child(pendingRequests[index].tripID).onValue,
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
            return buildDriverData(index, trip);
          }
        },
      );

  Widget buildDriverData(int index, Map<dynamic, dynamic> trip) =>
      StreamBuilder(
        stream: driverRef.child(pendingRequests[index].driverID).onValue,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData ||
              snapshot.data?.snapshot?.value == null) {
            return Container();
          } else {
            Map<dynamic, dynamic> driver = snapshot.data.snapshot.value;
            return buildList(index, trip, driver);
          }
        },
      );

  Widget buildList(int index, Map<dynamic, dynamic> trip,
          Map<dynamic, dynamic> driver) =>
      Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: ColorsConst.white, borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Row(children: [
            Image.asset(
              "images/PickUpDestination.png",
              width: 40,
              height: 50,
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 250),
                child: Text(
                  trip['destinationLocation'],
                  style: const TextStyle(
                    fontSize: 16,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Divider(),
              Container(
                constraints: const BoxConstraints(maxWidth: 250),
                child: Text(
                  trip['pickUpLocation'],
                  style: const TextStyle(
                    color: ColorsConst.grey,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
            ])
          ]),
          const SizedBox(
            height: 30,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip['time']),
                  Text(trip['date']),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          const Divider(),
          Row(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      driver['driver_image'],
                    ),
                    radius: 25,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(driver['name'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            )),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0.0, 0, 3.0, 0),
                          child: Text(driver['phone']),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                height: 40,
                width: 125,
                child: ElevatedButton(
                  onPressed:
                  //acceptRequest(requests[index]);
                  _isCancelButtonClickedList[index]
                      ? null
                      : () => _onCancelButtonPressed(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsConst.greenAccent,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    _isCancelButtonClickedList[index]
                        ? 'Cancelled'
                        : 'Cancel',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ]),
      );

  void cancelRequest(Request request) {
    FirebaseDatabase.instance
        .ref("requests")
        .child(request.requestID)
        .update({"status": "cancelled"});

    Fluttertoast.showToast(msg: "Request Cancelled");

  }
  void _onCancelButtonPressed(int index) async {
    setState(() {
      _isCancelButtonClickedList[index] = true;
    });
    cancelRequest(pendingRequests[index]);
  }
}
