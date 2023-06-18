import 'package:car_pool_driver/Constants/styles/colors.dart';
import 'package:car_pool_driver/Constants/widgets/loading.dart';
import 'package:car_pool_driver/Views/tabPages/bookedTripDetails.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:car_pool_driver/Views/data%20handler/app_data.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../Models/request.dart';
import '../../Models/trip.dart';
import '../../global/global.dart';
import '../assistants/assistant_methods.dart';
import '../trips/searchPickUp.dart';
import '../trips/search_screen.dart';
import 'available_drivers.dart';

class GetRequests {
  final databaseReference = FirebaseDatabase.instance.ref('requests');

  Future<List<Request>> getRequests() async {
    List<Request> itemList = [];
    // Get a reference to the Firebase database

    try {
      // Retrieve all items with the specified color
      final dataSnapshot = await databaseReference
          .orderByChild('userID')
          .equalTo(currentFirebaseUser!.uid.toString())
          .once();

      // Convert the retrieved data to a list of Item objects

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
}

class Dashboard extends StatefulWidget {
  static const String idScreen = "dashboard";

  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final GetRequests getRequests = GetRequests();
  List<Request> requests = [];
  List<Request> acceptedRequest = [];
  User? currentUser;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  late GoogleMapController newgoogleMapController;
  static const CameraPosition _kGooglePlex =
      CameraPosition(target: LatLng(9.1450, 40.4897), zoom: 1);

  List<LatLng> pLineCoordinates = [];

  Set<Polyline> polylineSet = {};

  late Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingMap = 0;
  bool isLoading = false;
  String? price;

  TextEditingController pickUpLocationController = TextEditingController();
  TextEditingController destinationLocationController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController latitudeController = TextEditingController();
  TextEditingController longitudeController = TextEditingController();
  TextEditingController destinationLatitudeController = TextEditingController();
  TextEditingController destinationLongitudeController =
      TextEditingController();

  late String passengers;
  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  @override
  void initState() {
    super.initState();
    isLoading = true;
    getRequest().then((_) {
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> getRequest() async {
    List<Request> requests = await getRequests.getRequests();
    setState(() {
      this.requests = requests;
      for (var r in requests) {
        if (r.status == 'accepted') acceptedRequest.add(r);
      }
    });
  }

  void locatePosition() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition =
        CameraPosition(target: latLngPosition, zoom: 20.0);
    newgoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    // ignore: use_build_context_synchronously
    String address =
        // ignore: use_build_context_synchronously
        await AssistantMethods.searchCoordinateAddress(position, context);
  }
  Future<void> refresh() async {
    isLoading = true;
    acceptedRequest.clear();
    getRequest().then((_) {
      setState(() {
        isLoading = false;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    String? pickUpLocation =
        Provider.of<AppData>(context).pickUpLocation?.placeName;
    pickUpLocationController.text = (pickUpLocation.toString() == 'null')
        ? 'Retrieving Location...'
        : pickUpLocation.toString();
    String? destination =
        Provider.of<AppData>(context).dropOffLocation?.placeName;
    destinationLocationController.text = (destination.toString() == 'null')
        ? 'Enter Destination'
        : destination.toString();
    double? locationLatitude =
        Provider.of<AppData>(context).pickUpLocation?.latitude;
    latitudeController.text = locationLatitude.toString();
    double? locationLongitude =
        Provider.of<AppData>(context).pickUpLocation?.longitude;
    longitudeController.text = locationLongitude.toString();
    double? destinationLatitude =
        Provider.of<AppData>(context).dropOffLocation?.latitude;
    destinationLatitudeController.text = destinationLatitude.toString();
    double? destinationLongitude =
        Provider.of<AppData>(context).dropOffLocation?.longitude;
    destinationLongitudeController.text = destinationLongitude.toString();
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: refresh,
        child: Stack(
          children: [
            GoogleMap(
              padding: EdgeInsets.only(bottom: bottomPaddingMap),
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
                setState(() {
                  bottomPaddingMap = 300.0;
                });
                locatePosition();
              },
            ),
            Positioned(
              left: 0.0,
              top: 0.0,
              right: 0.0,
              bottom: 0.0,
              child: Container(
                  color: ColorsConst.white,
                  child: Stack(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.45,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("images/bg.jpg"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: Align(
                          child: SizedBox(
                            height: 250,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              elevation: 10.0,
                              child: Column(children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: <Widget>[
                                      Image.asset(
                                        "images/PickUpDestination.png",
                                        width: 20,
                                        height: 160,
                                      ),
                                      Flexible(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 15.0),
                                          child: Column(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        8.0, 15.0, 8.0, 8.0),
                                                child: TextFormField(
                                                  controller:
                                                  pickUpLocationController,
                                                  decoration: const InputDecoration(

                                                      enabledBorder:
                                                      UnderlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color: Colors
                                                                .greenAccent),
                                                      ),
                                                      focusedBorder:
                                                      UnderlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color: Colors
                                                                  .greenAccent)),
                                                      labelText: "Pick-Up",
                                                      hintStyle: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 16,
                                                      )),

                                                  style: const TextStyle(
                                                      fontSize: 14.0),
                                                  readOnly: true,
                                                  onTap: () async {
                                                    var res = await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: ((context) =>
                                                            const SearchPickUpScreen())));
                                                    if (res ==
                                                        "obtainDirection") {
                                                      await getPlaceDirection();
                                                    }
                                                  },
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        8.0, 3.0, 8.0, 8.0),
                                                child: TextFormField(
                                                  controller:
                                                      destinationLocationController,
                                                  decoration:
                                                      const InputDecoration(
                                                          enabledBorder:
                                                              UnderlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: ColorsConst
                                                                    .greenAccent),
                                                          ),
                                                          focusedBorder: UnderlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: ColorsConst
                                                                      .greenAccent)),
                                                          labelText: 'Drop-Off',
                                                          hintStyle: TextStyle(
                                                            color:
                                                                ColorsConst.grey,
                                                            fontSize: 16,
                                                          )),
                                                  style: const TextStyle(
                                                      fontSize: 14.0),
                                                  readOnly: true,
                                                  onTap: () async {
                                                    if (pickUpLocationController.text
                                                        .toString() ==
                                                        'Retrieving Location...') {
                                                      showDialog(
                                                        context: context,
                                                        builder: (BuildContext context) {
                                                          return AlertDialog(
                                                            content: const Text(
                                                                'Retrieving Location, Please wait.'),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.of(context).pop();
                                                                },
                                                                child: const Text('OK'),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    } else {
                                                      var res = await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: ((context) =>
                                                              const SearchScreen())));
                                                      if (res == "obtainDirection") {
                                                        await getPlaceDirection();
                                                      }
                                                    }
                                                  },
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                        padding: const EdgeInsets.all(0),
                                        height: 80,
                                        width: double.infinity,
                                        child: ElevatedButton(
                                            style: ButtonStyle(
                                              elevation:
                                                  MaterialStateProperty.all(4.0),
                                              backgroundColor:
                                                  MaterialStateProperty.all(
                                                      ColorsConst.greenAccent),
                                            ),
                                            onPressed: () {
                                              if (destinationLocationController
                                                          .text
                                                          .toString() ==
                                                      'null' ||
                                                  destinationLocationController
                                                          .text
                                                          .toString() ==
                                                      'Enter Destination') {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      content: const Text(
                                                          'Enter Destination first!!'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(context)
                                                                .pop();
                                                          },
                                                          child: const Text('OK'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              } else {
                                                Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            AvailableDrivers(
                                                              userLatPos:
                                                                  latitudeController
                                                                      .text,
                                                              userLongPos:
                                                                  longitudeController
                                                                      .text,
                                                              userDestinationLatPos:
                                                                  destinationLatitudeController
                                                                      .text,
                                                              userDestinationLongPos:
                                                                  destinationLongitudeController
                                                                      .text,
                                                              destinationLocation:
                                                                  destinationLocationController
                                                                      .text,
                                                            )));
                                              }
                                            },
                                            child: const Text(
                                              "Search",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18),
                                            ))),
                                  ),
                                )
                              ]),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: <Widget>[
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.625,
                          ),
                          if (isLoading)
                            const Padding(
                              padding: EdgeInsets.all(15.0),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            Expanded(
                                child: ListView.builder(
                                    itemCount: (acceptedRequest.isEmpty)
                                        ? 1
                                        : acceptedRequest.length,
                                    itemBuilder: (context, index) {
                                      if (acceptedRequest.isEmpty) {
                                        return Center(
                                          child: Column(
                                            children: [
                                              Image.asset(
                                                "images/noBook.jpg",
                                                height: 140,
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              const Text(
                                                "YOU HAVE NO BOOKED TRIPS FOR NOW!!!",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        Future<String?> pickUp =
                                            getPickUpLoctionString(
                                                acceptedRequest[index]);
                                        Future<String?> date =
                                            getPickUpDate(acceptedRequest[index]);

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              left: 25.0, right: 20.0),
                                          child: Column(
                                            children: [
                                              ListTile(
                                                  title: FutureBuilder<String?>(
                                                    future: pickUp,
                                                    builder:
                                                        (BuildContext context,
                                                            AsyncSnapshot<String?>
                                                                snapshot) {
                                                      if (snapshot.hasData) {
                                                        return Text(
                                                          'To: ${snapshot.data}',
                                                          style: const TextStyle(
                                                              fontSize: 14),
                                                        );
                                                      } else {
                                                        return const Text(
                                                            'Retrieving Location...');
                                                      }
                                                    },
                                                  ),
                                                  subtitle:
                                                      FutureBuilder<String?>(
                                                    future: date,
                                                    builder:
                                                        (BuildContext context,
                                                            AsyncSnapshot<String?>
                                                                snapshot) {
                                                      if (snapshot.hasData) {
                                                        return Text(
                                                          'On ${snapshot.data}',
                                                          style: const TextStyle(
                                                              fontSize: 14),
                                                        );
                                                      } else {
                                                        return const Text(
                                                            'Retrieving Location...');
                                                      }
                                                    },
                                                  ),
                                                  trailing:
                                                      Icon(Icons.navigate_next),
                                                  onTap: () {
                                                    Navigator.of(context)
                                                        .push(MaterialPageRoute(
                                                      builder: (context) =>
                                                          MyBookedTrips(
                                                              request:
                                                                  acceptedRequest[
                                                                      index]),
                                                    ));
                                                  }),
                                              const Divider(),
                                            ],
                                          ),
                                        );
                                      }
                                    })),
                        ],
                      ),
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> getPickUpLoctionString(Request request) async {
    final ref = FirebaseDatabase.instance.ref();
    final snapshot =
        await ref.child('trips/${request.tripID}/destinationLocation').get();
    if (snapshot.exists) {
      return snapshot.value.toString();
    } else {
      return '';
    }
  }

  Future<String> getPickUpDate(Request request) async {
    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child('trips/${request.tripID}/date').get();
    final snapshot2 = await ref.child('trips/${request.tripID}/time').get();
    if (snapshot.exists && snapshot2.exists) {
      return '${formatDate(snapshot.value.toString())} at ${snapshot2.value}';
    } else {
      return '';
    }
  }

  String formatDate(String inputStr) {
    // Convert the input string to a DateTime object
    DateTime date = DateTime.parse(inputStr);

    // Format the DateTime object as a String in the desired format
    String formattedStr = DateFormat('EE, MMM d y').format(date);

    return formattedStr;
  }

  Future<void> getPlaceDirection() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;

    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickUpLatLng = LatLng(initialPos!.latitude, initialPos.longitude);
    var dropOffLatLng = LatLng(finalPos!.latitude, finalPos.longitude);
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            LoadingScreen(message: "Please wait...."));
    var details = await AssistantMethods.obtainDirectionDetails(
        pickUpLatLng, dropOffLatLng);

    // ignore: use_build_context_synchronously
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
        color: Colors.pink,
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
          northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
          northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }

    newgoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocationMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow:
            InfoWindow(title: initialPos.placeName, snippet: "My location"),
        position: pickUpLatLng,
        markerId: const MarkerId(
          "pickUpId",
        ));
    Marker dropOffLocationMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
            InfoWindow(title: finalPos.placeName, snippet: "My destination"),
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
  }
}
