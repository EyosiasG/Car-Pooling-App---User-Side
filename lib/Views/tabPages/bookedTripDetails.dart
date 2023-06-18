import 'dart:async';
import 'dart:math';

import 'package:car_pool_driver/Models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../Constants/widgets/loading.dart';
import '../../Models/driver.dart';
import '../../Models/request.dart';
import '../../Models/trip.dart';
import '../../widgets/progress_dialog.dart';
import '../assistants/assistant_methods.dart';
import '../data handler/app_data.dart';

class MyBookedTrips extends StatefulWidget {
  final Request request;

  const MyBookedTrips({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  State<MyBookedTrips> createState() => _MyBookedTripsState();
}

class _MyBookedTripsState extends State<MyBookedTrips> {
  User? currentUser;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  late GoogleMapController newgoogleMapController;
  static const CameraPosition _kGooglePlex =
      CameraPosition(target: LatLng(9.1450, 40.4897), zoom: 1);

  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};
  String driverImage = "";
  String name = "";
  List<Driver> driver = [];
  List<TripsModel> trip = [];
  List<Passenger> passenger = [];
  bool isLoading = false;

  Future<void> getPlaceDirection() async {
    final snapshot = await FirebaseDatabase.instance
        .reference()
        .child('trips')
        .child(widget.request.tripID)
        .once();
    if (snapshot.snapshot.value != null) {
      Map<dynamic, dynamic>? tripData =
          snapshot.snapshot.value as Map<dynamic, dynamic>?;
      if (tripData != null) {
        var pickUpLatLng = LatLng(double.parse(tripData['locationLatitude']),
            double.parse(tripData['locationLongitude']));
        var dropOffLatLng = LatLng(
            double.parse(tripData['destinationLatitude']),
            double.parse(tripData['destinationLongitude']));
        showDialog(
            context: context,
            builder: (BuildContext context) =>
                LoadingScreen(message: "Please wait...."));
        var details = await AssistantMethods.obtainDirectionDetails(
            pickUpLatLng, dropOffLatLng);

        Navigator.pop(context);

        PolylinePoints polylinePoints = PolylinePoints();
        List<PointLatLng> decodePolylinePointsResult =
            polylinePoints.decodePolyline(details!.encodedPoints.toString());
        pLineCoordinates.clear();
        if (decodePolylinePointsResult.isNotEmpty) {
          decodePolylinePointsResult.forEach((PointLatLng pointLatLng) {
            pLineCoordinates
                .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
          });
        }
        polylineSet.clear();
        setState(() {
          Polyline polyline = Polyline(
            color: Colors.greenAccent,
            polylineId: const PolylineId("PolylineID"),
            jointType: JointType.round,
            points: pLineCoordinates,
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            geodesic: true,
          );
          polylineSet.add(polyline);
        });

        LatLngBounds latLngBounds;
        if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
            pickUpLatLng.longitude > dropOffLatLng.longitude) {
          latLngBounds =
              LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
        } else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
          latLngBounds = LatLngBounds(
              southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
              northeast:
                  LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
        } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
          latLngBounds = LatLngBounds(
              southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
              northeast:
                  LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
        } else {
          latLngBounds =
              LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
        }

        newgoogleMapController
            .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

        Marker pickUpLocationMarker = Marker(
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
                title: tripData['pickUpLocation'], snippet: "My location"),
            position: pickUpLatLng,
            markerId: const MarkerId(
              "pickUpId",
            ));
        Marker dropOffLocationMarker = Marker(
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
                title: tripData['destinationLocation'],
                snippet: "My destination"),
            position: dropOffLatLng,
            markerId: const MarkerId(
              "dropOffId",
            ));

        setState(() {
          markersSet.add(pickUpLocationMarker);
          markersSet.add(dropOffLocationMarker);
        });

        Circle pickUpLocCircle = Circle(
            fillColor: Colors.blueAccent,
            center: pickUpLatLng,
            radius: 12.0,
            strokeWidth: 4,
            strokeColor: Colors.yellowAccent,
            circleId: const CircleId("pickUpId"));

        Circle dropOffLocCircle = Circle(
            fillColor: Colors.deepPurple,
            center: dropOffLatLng,
            radius: 12.0,
            strokeWidth: 4,
            strokeColor: Colors.deepPurple,
            circleId: const CircleId("dropOffId"));

        setState(() {
          circlesSet.add(pickUpLocCircle);
          circlesSet.add(dropOffLocCircle);
        });
      } else {
        // Handle the case where the userData is null
      }
    } else {
      // Handle the case where the snapshot is null or doesn't contain any data
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isLoading = true;
    getDrivers().then((_) {
      // Set the isLoading flag to false when the data has been retrieved
      setState(() {
        isLoading = false;
      });
    });
    getTrips();
    // getPassengers();
  }

  Future<void> getDrivers() async {
    List<Driver> driver = await getDriver();
    setState(() {
      this.driver = driver;
    });
  }

  Future<void> getTrips() async {
    List<TripsModel> trip = await getTrip();
    setState(() {
      this.trip = trip;
    });
  }

  /*Future<void> getPassengers() async {
    List<Passenger> passenger = await getUser(trip[0].userIDs[0].replaceAll(new RegExp(r'[^\w\s]+'),'').trim());
    setState(() {
      this.passenger = passenger;
    });
  }*/

  final databaseReference = FirebaseDatabase.instance.ref('drivers');

  Future<List<Driver>> getDriver() async {
    List<Driver> itemList = [];
    // Get a reference to the Firebase database

    try {
      // Retrieve all items with the specified color
      final dataSnapshot = await databaseReference
          .orderByChild('id')
          .equalTo(widget.request.driverID)
          .once();

      // Convert the retrieved data to a list of Item objects

      Map<dynamic, dynamic> values =
          dataSnapshot.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        final item = Driver(
            id: value['id'],
            imagePath: value['driver_image'],
            name: value['name'],
            email: value['email'],
            phone: value['phone'],
            totalMileage: '6.4km',
            carMake: value['car_make'],
            carModel: value['car_model'],
            carYear: value['car_year'],
            carPlateNo: value['car_plateNo'],
            carColor: value['car_color'],
            rating: '',
            noOfRatings: '');
        itemList.add(item);
      });
    } catch (e) {
      // Log the error and return an empty list
      print('Error: $e');
    }
    return itemList;
  }

  final tripRef = FirebaseDatabase.instance.ref('trips');

  Future<List<TripsModel>> getTrip() async {
    List<TripsModel> itemList = [];

    try {
      final dataSnapshot = await tripRef
          .orderByChild('tripID')
          .equalTo(widget.request.tripID)
          .once();

      Map<dynamic, dynamic> values =
          dataSnapshot.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        List<String> passengerIDs = value['passengerIDs'] != null
            ? value['passengerIDs'].toString().split(',')
            : [];
        passengerIDs = passengerIDs
            .map((id) => id.replaceAll(new RegExp(r'[\[\]\s]'), ''))
            .toList();
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
          price: '0',
          userIDs: passengerIDs,
          date: value['date'],
          time: value['time'],
          availableSeats: value['availableSeats'],
          passengers: value['passengers'],
          status: value['status'],
        );
        itemList.add(item);
      });
    } catch (e) {
      print('Error: $e');
    }
    return itemList;
  }

  final ref = FirebaseDatabase.instance.ref('trips');
  final driverRef = FirebaseDatabase.instance.ref('drivers');

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
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top:4.0),
          child: Text(
            'Trip History',
            style: TextStyle(
                color: Colors.black),
          ),
        ),
      ),
      body: Column(children: [
        const SizedBox(
          height: 15,
        ),
        StreamBuilder(
          stream: driverRef.child(widget.request.driverID).onValue,
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
              return buildDriverDetails(driver);
            }
          },
        ),
        Container(
          height: 250,
          child: Stack(
            children: [
              GoogleMap(
                myLocationEnabled: true,
                polylines: polylineSet,
                zoomGesturesEnabled: true,
                markers: markersSet,
                circles: circlesSet,
                zoomControlsEnabled: false,
                mapType: MapType.normal,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: true,
                initialCameraPosition: _kGooglePlex,
                onMapCreated: (GoogleMapController controller) {
                  _controllerGoogleMap.complete(controller);
                  newgoogleMapController = controller;
                  getPlaceDirection();
                },
              ),
            ],
          ),
        ),
        StreamBuilder(
          stream: ref.child(widget.request.tripID).onValue,
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: ProgressDialog(message: 'Processing ....'));
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData ||
                snapshot.data?.snapshot?.value == null) {
              return Container();
            } else {
              Map<dynamic, dynamic> trip = snapshot.data.snapshot.value;
              return buildTripDetails(trip);
            }
          },
        ),
      ]),
    );
  }

  Widget buildTripDetails(Map<dynamic, dynamic> trip) => Column(
        children: [
          Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(children: [
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
                      //'Lideta Condominium',
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
                        color: Colors.grey,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                ]),
                const SizedBox(
                  height: 20,
                ),
              ])),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip['time']),
                    Text(formatDate(trip['date'].toString())),
                  ],
                ),
                RatingBarIndicator(
                  itemBuilder: (context, index) => const Icon(
                    Icons.person,
                    color: Colors.greenAccent,
                  ),
                  rating: double.parse(trip['passengers'][0]) -
                      double.parse(trip['availableSeats']),
                  itemSize: 18,
                  itemCount: 4,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(
                  child: Column(
                    children: [
                      const Text('Distance'),
                      Text(
                          '${estimateDistance(double.parse(trip['locationLatitude']), double.parse(trip['locationLongitude']), double.parse(trip['destinationLatitude']), double.parse(trip['destinationLongitude'])).toStringAsPrecision(2)} Km'),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const Text('Estimated Cost'),
                Text(trip['estimatedCost']),
                const SizedBox(
                  height: 30,
                ),
              ]),
            ],
          ),
          Column(
            children: [
              if (widget.request.status == 'accepted')
                SizedBox(
                  height: 50,
                  width: 300,
                  child: ElevatedButton(
                    onPressed: () {
                      cancelRequest();
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.redAccent,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Cancel Ride',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else
                Text('Total Fare : ${double.parse(trip['fare']).toStringAsPrecision(2)} birr', style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600,
                ),)

            ],
          ),
        ],
      );

  double estimateDistance(
      double pickUpLat, double pickUpLong, double destLat, double destLong) {
    double distance, earthRadius = 6371;
    double lat1Rad = degreesToRadians(pickUpLat);
    double lon1Rad = degreesToRadians(pickUpLong);
    double lat2Rad = degreesToRadians(destLat);
    double lon2Rad = degreesToRadians(destLong);

    double latDiff = lat2Rad - lat1Rad;
    double lonDiff = lon2Rad - lon1Rad;

    num havLat = pow(sin(latDiff / 2), 2);
    num havLon = pow(sin(lonDiff / 2), 2);

    double hav = havLat + havLon * cos(lat1Rad) * cos(lat2Rad);

    distance = 2 * earthRadius * asin(sqrt(hav));

    return distance;
  }

  String formatDate(String inputStr) {
    // Convert the input string to a DateTime object
    DateTime date = DateTime.parse(inputStr);

    // Format the DateTime object as a String in the desired format
    String formattedStr = DateFormat('EEEE, MMMM, d y').format(date);

    return formattedStr;
  }

  double degreesToRadians(double degrees) {
    // Helper function to convert degrees to radians
    return degrees * pi / 180;
  }

  Widget buildDriverDetails(Map<dynamic, dynamic> driver) => Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(driver['driver_image']),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          )),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0.0, 0, 3.0, 0),
                            child: Text(driver['car_color']),
                          ),
                          Text('${driver['car_make']} ${driver['car_model']}'),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: RatingBarIndicator(
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          rating: double.parse(driver['averageRating']),
                          itemSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: () {
                //requestRide(trips[index]);
              },
              icon: const Icon(
                Icons.call,
                size: 30,
                color: Colors.greenAccent,
              ),
            ),
          ),
        ],
      );

  Future<void> cancelRequest() async {
    FirebaseDatabase.instance
        .ref("requests")
        .child(widget.request.requestID)
        .update({"status": "cancelled"});

    List<Object?> seats = [];
    final ref = FirebaseDatabase.instance.ref();
    final snapshot =
        await ref.child('trips/${widget.request.tripID}/passengerIDs').get();
    if (snapshot.exists) {
      seats = snapshot.value as List<Object?>? ?? [];
    } else {
      const AlertDialog(semanticLabel: 'No data available.');
    }
    String availableSeats;
    int i = 0;
    for (var seat in seats) {
      if (seat == widget.request.userID) {
        final snapshot = await ref
            .child('trips/${widget.request.tripID}/availableSeats')
            .get();
        if (snapshot.exists) {
          availableSeats = snapshot.value.toString();
          FirebaseDatabase.instance
              .ref("trips")
              .child(widget.request.tripID)
              .update({
            "availableSeats": (int.parse(availableSeats) + 1).toString()
          });
          FirebaseDatabase.instance
              .ref("trips")
              .child(widget.request.tripID)
              .child("passengerIDs")
              .update({"$i": ""});
        } else {
          const AlertDialog(semanticLabel: 'No data available.');
        }
      }
    }
    Fluttertoast.showToast(msg: "Request Cancelled");
  }
}
