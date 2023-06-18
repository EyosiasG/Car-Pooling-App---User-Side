import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../Constants/styles/colors.dart';
import '../../Constants/widgets/text_field.dart';
import '../../global/global.dart';
import '../../widgets/progress_dialog.dart';
import '../assistants/assistant_methods.dart';

import '../data handler/app_data.dart';
import '../trips/search_screen.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({Key? key}) : super(key: key);

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  DatabaseReference tripsRef = FirebaseDatabase.instance.ref().child("trips");
  static const String idScreen = "dashboard";
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

  String? price;

  TextEditingController pickUpLocationController = TextEditingController();
  TextEditingController destinationLocationController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController latitudeController = TextEditingController();
  TextEditingController longitudeController = TextEditingController();
  TextEditingController destinationLatitudeController = TextEditingController();
  TextEditingController destinationLongitudeController =
      TextEditingController();
  TextEditingController pickUpLocationEditingController =
      TextEditingController();
  TextEditingController dropOffLocationEditingController =
      TextEditingController();

  late String passengers;
  final _formKey = GlobalKey<FormState>();
  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};
  late String destinationCheck;

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

  var _selectedSeats = 0;
  var _dateTime = DateTime.now();
  var _timeOfDay = TimeOfDay.now();

  saveTripInfo() async {
    Map driverTripMap = {};
    FirebaseDatabase.instance.ref().child("trips").push().set({
      "pick_up": pickUpLocationEditingController.text.trim(),
      "drop_off": dropOffLocationEditingController.text.trim(),
      "seats": _selectedSeats.toString(),
      "date": _dateTime.toString(),
      "time": _timeOfDay.toString(),
      "driver_id": currentFirebaseUser!.uid.toString(),
    });

    Fluttertoast.showToast(msg: "Trip Details has been saved");
  }

  void _showDatePicker(BuildContext context) {
    showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2024))
        .then((value) {
      setState(() {
        _dateTime = value!;
      });
    });
  }

  void _showTimePicker(BuildContext context) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((value) {
      _timeOfDay = value!;
    });
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat.yMMMEd().format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /* appBar: AppBar(
        actions: [
          Provider.of<AppData>(context).dropOffLocation != null
              ? ElevatedButton(
                  onPressed: () {
                    _saveToFirebase(context);
                  },
                  child: const Text("Save car pool"))
              : const Text("Please add a destination"),
        ],
      ),*/
      body: Builder(builder: (BuildContext newContext) {
        return Stack(
          children: [
            // ignore: sized_box_for_whitespace
            Container(
              height: MediaQuery.of(context).size.height,
              child: GoogleMap(
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
            ),
            Positioned(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20)),
                        border: Border.all(color: ColorsConst.greenAccent),
                        color: ColorsConst.white,
                      ),
                      height: 250,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(25.0),
                          child: Column(children: [
                            Row(
                              children: <Widget>[
                                Image.asset(
                                  "images/PickUpDestination.png",
                                  width: 20,
                                  height: 105,
                                ),
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 20.0),
                                    child: Column(
                                      children: [
                                        TextFieldForm(
                                          text: "Pick-Up Location",
                                          controller: pickUpLocationController,
                                          capitalization:
                                              TextCapitalization.none,
                                          textInputType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        TextField(
                                          readOnly: true,
                                          onTap: () async {
                                            var res = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: ((newContext) =>
                                                        const SearchScreen())));
                                            if (res == "obtainDirection") {
                                              await getPlaceDirection();
                                            }
                                          },
                                          controller:
                                              destinationLocationController,
                                          decoration: const InputDecoration(
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: ColorsConst
                                                        .greenAccent),
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: ColorsConst
                                                              .greenAccent)),
                                              label: Text('Drop Off'),
                                              labelStyle: TextStyle(
                                                color: ColorsConst.grey,
                                                fontSize: 16,
                                              ),
                                              hintStyle: TextStyle(
                                                color: ColorsConst.grey,
                                                fontSize: 16,
                                              )),
                                          style:
                                              const TextStyle(fontSize: 17.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            SizedBox(
                              height: 50,
                              width: 350,
                              child: ElevatedButton(
                                  onPressed: () {
                                    _saveToFirebase(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorsConst.greenAccent,
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                        //to set border radius to button
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  child: const Text(
                                    "Add Trip",
                                    style: TextStyle(
                                      color: ColorsConst.white,
                                      fontSize: 18,
                                    ),
                                  )),
                            ),
                            ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: ((context) =>
                                              const HomeTabPage())));
                                },
                                child: const Text('HomePage'))
                          ]),
                        ),
                      ))),
            ),
          ],
        );
      }),
    );
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
            ProgressDialog(message: "Please wait...."));
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

  Future<void> _saveToFirebase(BuildContext context) async {
    String dropdownvalue = '1 passenger';
    var currentSelectedValue;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Center(child: Text("Add a pool")),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: pickUpLocationController,
                      enabled: false,
                      decoration: InputDecoration(
                        enabledBorder: const UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: ColorsConst.greenAccent),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: ColorsConst.greenAccent)),
                        labelText:
                            Provider.of<AppData>(context).pickUpLocation != null
                                ? Provider.of<AppData>(context)
                                    .pickUpLocation!
                                    .placeName
                                : 'Wait while fetching your location',
                      ),
                    ),
                    const SizedBox(
                      height: 13.0,
                    ),
                    TextFormField(
                      controller: destinationLocationController,
                      enabled: false,
                      decoration: InputDecoration(
                        enabledBorder: const UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: ColorsConst.greenAccent),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: ColorsConst.greenAccent)),
                        labelText:
                            Provider.of<AppData>(context).dropOffLocation !=
                                    null
                                ? Provider.of<AppData>(context)
                                    .dropOffLocation!
                                    .placeName
                                : 'Wait for fetch',
                      ),
                    ),
                    const SizedBox(
                      height: 13.0,
                    ),
                    ButtonTheme(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null ? 'Passengers' : null,
                          value: currentSelectedValue,
                          hint: const Text('Passengers'),
                          onChanged: (newValue) {
                            setState(() {
                              currentSelectedValue = newValue;
                              this.passengers = newValue!;
                            });
                          },
                          items: <String>[
                            '1 Passenger',
                            '2 Passengers',
                            '3 Passengers',
                            '4 Passengers',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 13.0,
                    ),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Price per passenger',
                      ),
                      onChanged: (value) {
                        this.price = value;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              MaterialButton(
                color: ColorsConst.red,
                textColor: ColorsConst.white,
                child: const Text('Cancel'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              MaterialButton(
                color: ColorsConst.greenAccent,
                textColor: ColorsConst.white,
                child: const Text('Save'),
                onPressed: () {
                  setState(() {
                    _saveCarPool();
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

  Future<void> _saveCarPool() async {
    int index = 0;
    final _auth = FirebaseAuth.instance;
    Timer timestamp;

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return ProgressDialog(message: "Adding to the pool...");
            });
        await tripsRef.child("${DateTime.now().microsecondsSinceEpoch}").set({
          "pickUpLocation": pickUpLocationController.text.toString(),
          "destinationLocation": destinationLocationController.text.toString(),
          "locationLatitude": latitudeController.text,
          "locationLongitude": longitudeController.text,
          "destinationLatitude": destinationLatitudeController.text,
          "destinationLongitude": destinationLongitudeController.text,
          "price": price,
          "passengers": passengers,
          "driver_id": _auth.currentUser?.uid.toString(),
        });
        Navigator.pop(context);
        // ignore: use_build_context_synchronously
        Fluttertoast.showToast(msg: "Congratulations,your pool has been added");
      } catch (ex) {
        print("Your error is $ex");
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "Pool has not been added");
      }
    }
  }
}
