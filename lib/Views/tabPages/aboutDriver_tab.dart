import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../Models/trip.dart';
import '../../widgets/progress_dialog.dart';

class AboutDriver extends StatefulWidget {
  final String driverID;


  const AboutDriver({Key? key, required this.driverID}) : super(key: key);

  @override
  State<AboutDriver> createState() => _AboutDriverState();
}

class _AboutDriverState extends State<AboutDriver> {
  final ref = FirebaseDatabase.instance.ref('drivers');
  final databaseReference = FirebaseDatabase.instance.ref('trips');
  List<TripsModel> trips = [];
  List<TripsModel> driverTrips = [];
  bool isLoading = false;

  Future<List<TripsModel>> getItemsByDriverID(
      String driverID) async {
    List<TripsModel> itemList = [];
    // Get a reference to the Firebase database

    try {
      final dataSnapshot = await databaseReference
          .orderByChild('driver_id')
          .equalTo(driverID)
          .once();

      Map<dynamic, dynamic> values =
      dataSnapshot.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        final item = TripsModel(
            tripID: value['tripID'],
            driverID: value['driver_id'],
            pickUpLatPos: value['locationLatitude'],
            pickUpLongPos: value['locationLongitude'],
            dropOffLatPos: value['destinationLatitude'],
            dropOffLongPos: value['destinationLongitude'],
            pickUpDistance: 0,
            dropOffDistance: 0,
            destinationLocation: value['destinationLocation'],
            pickUpLocation: value['pickUpLocation'],
            userIDs: [],
            price: value['estimatedCost'],
            date: value['date'],
            time: value['time'],
            availableSeats: value['availableSeats'].toString(),
            passengers: value['passengers'].toString(),
            status: value['status']);
        itemList.add(item);
      });
    } catch (e) {
      // Log the error and return an empty list
      print('Error: $e');
    }

    return itemList;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isLoading = true;
    getTrips().then((_) {
      setState(() {
        isLoading = false;
      });
    });

  }

  Future<void> getTrips() async {
    List<TripsModel> trips = await getItemsByDriverID(widget.driverID);
    setState(() {
      this.trips = trips;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.greenAccent,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top:4.0),
          child: Text(
            'About Driver',
            style: TextStyle(
                color: Colors.black),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder(
        stream: ref.child(widget.driverID).onValue,
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return Center(child: ProgressDialog(message: 'Processing ....'));
          } else {
            Map<dynamic, dynamic> driver = snapshot.data.snapshot.value;
            return buildDriverDetails(driver);
          }
        },
      ),
    );
  }

  buildDriverDetails(Map<dynamic, dynamic> driver) => SingleChildScrollView(
    child: Flexible(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Aligns the widgets in the center
        children: <Widget>[
          const SizedBox(
            height: 30,
          ),
          CircleAvatar(
            backgroundImage: NetworkImage(driver['driver_image']),
            radius: 60,
          ),
          const SizedBox(
            height: 20,
          ),
          Text(driver['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          Text(driver['email'], style: const TextStyle(color: Colors.grey)),
          const SizedBox(
            height: 25,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  const SizedBox(
                    width: 3,
                  ),
                  Text(double.parse(driver['averageRating']).toStringAsPrecision(2),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(
                width: 50,
              ),
              Row(
                children: [Text(driver['noOfRatings'] + ' ratings')],
              )
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.directions_bus_filled_rounded,
                color: Colors.grey,
              ),
              const SizedBox(
                width: 10,
              ),
              Text(driver['car_color'] + ' ' + driver['car_make'] + ' ' + driver['car_model']),
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.numbers,
                color: Colors.grey,
              ),
              const SizedBox(
                width: 10,
              ),
              Text(driver['car_plateNo']),
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          Divider(),
          const SizedBox(
            height: 5,
          ),
          Text(
            'Trips',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          Stack(
            children:[
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            ListTile(
                              title: Text(trips[index].destinationLocation.toString(),
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                ),),
                              subtitle: Text(trips[index].date + ' at ' + trips[index].time),
                              leading: Icon(Icons.location_searching_sharp, color: Colors.greenAccent),
                            ),
                            Divider(),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ]
          ),
        ],
      ),
    ),
  );
}
