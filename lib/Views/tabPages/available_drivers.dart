import 'dart:convert';
import 'dart:math';

import 'package:car_pool_driver/Views/tabPages/payment_web_view.dart';
import 'package:car_pool_driver/widgets/progress_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../Constants/styles/colors.dart';
import '../../Models/driver.dart';
import '../../Models/request.dart';
import '../../Models/trip.dart';
import '../../global/global.dart';
import 'package:http/http.dart' as http;

import '../../main.dart';
import 'aboutDriver_tab.dart';

class GetDrivers {
  final databaseReference = FirebaseDatabase.instance.ref('drivers');

  Future<List<Driver>> getDriver() async {
    List<Driver> itemList = [];
    // Get a reference to the Firebase database

    try {

      final dataSnapshot = await databaseReference.once();

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
            rating: value['averageRating'],
            noOfRatings: value['noOfRatings']);
        itemList.add(item);
      });
    } catch (e) {
      // Log the error and return an empty list
      print('Error: $e');
    }
    return itemList;
  }
}

class AvailableDrivers extends StatefulWidget {
  final String userLatPos;
  final String userLongPos;
  final String userDestinationLatPos;
  final String userDestinationLongPos;
  final String destinationLocation;

  const AvailableDrivers({
    Key? key,
    required this.userLatPos,
    required this.userLongPos,
    required this.userDestinationLatPos,
    required this.userDestinationLongPos,
    required this.destinationLocation,
  }) : super(
          key: key,
        );

  @override
  State<AvailableDrivers> createState() => _AvailableDriversState();
}





class _AvailableDriversState extends State<AvailableDrivers> {
  final GetDrivers getAllDrivers = GetDrivers();
  List<TripsModel> trips = [];
  List<Driver> drivers = [];
  List<TripsModel> closeTrips = [];
  Driver? dr;
  bool isTripLoading = false;
  bool isDriverLoading = false;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  List<bool> _isCancelButtonClickedList = [];

  @override
  void initState() {
    super.initState();
    isTripLoading = true;
    isDriverLoading = true;
    getTrips().then((_) {
      setState(() {
        isTripLoading = false;
      });
    });
    getDrivers().then((_) {
      setState(() {
        isDriverLoading = false;
      });
    });


  }
  final databaseReference = FirebaseDatabase.instance.ref('trips');

  Future<List<TripsModel>> getItemsByDestination(
      String destinationLocation) async {
    List<TripsModel> itemList = [];
    // Get a reference to the Firebase database

    try {
      final dataSnapshot = await databaseReference
          .orderByChild('destinationLocation')
          .equalTo(destinationLocation)
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
  Future<void> getDrivers() async {
    List<Driver> drivers = await getAllDrivers.getDriver();
    setState(() {
      this.drivers = drivers;
    });
  }
  Future<void> getTrips() async {
    List<TripsModel> trips = await getItemsByDestination(widget.destinationLocation);
    setState(() {
      this.trips = trips;
    });
    int i = 0;
    for(var t in trips){
      double distance = calculateDistance(
          double.parse(widget.userLatPos),
          double.parse(widget.userLongPos),
          double.parse(t.pickUpLatPos),
          double.parse(t.pickUpLongPos));
      print(distance);

      if(distance< 2.0 && t.availableSeats != '0' && t.status == 'scheduled'){

        closeTrips.add(t);
        print(closeTrips[i].destinationLocation);
        i++;
      }
    }
    _isCancelButtonClickedList = List.filled(closeTrips.length, false);
  }
  final requestRef = FirebaseDatabase.instance.ref('requests');
  Future<void> rateDriver() {
    List<TripsModel> trips = [];
    double? _rating;
    IconData? _selectedIcon;

    return showDialog(
        context: context,
        builder: (builder) {
          return AlertDialog(
            title: const Center(
              child: Text(
                'Rate your driver',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder(
                  stream: requestRef.orderByChild('userID').equalTo(currentFirebaseUser!.uid).onValue,
                  builder: (context, AsyncSnapshot snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData ||
                        snapshot.data?.snapshot?.value == null) {
                      return Container();
                    } else {
                      Map<dynamic, dynamic> requests = snapshot.data.snapshot.value;
                      Request? item;
                      requests.forEach((key, value) {
                        if(value['status'] == 'accepted'){
                          item = Request(
                              tripID: value['tripID'],
                              driverID: value['driverID'],
                              requestID: value['requestID'],
                              userID: value['userID'],
                              status: value['status']
                          );
                        }
                      });
                      return buildDriverRating(item);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text(
                  'Ok',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
  double? _rating;
  IconData? _selectedIcon;
  final driverRef = FirebaseDatabase.instance.ref('drivers');
  Widget buildDriverRating(Request? req) =>   StreamBuilder(
    stream: driverRef.child(req!.driverID).onValue,
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
        return RatingBar.builder(
          initialRating: _rating ?? 0.0,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          itemSize: 25,
          itemPadding:
          const EdgeInsets.symmetric(horizontal: 8),
          itemBuilder: (context, _) => Icon(
            _selectedIcon ?? Icons.star,
            color: ColorsConst.amber,
          ),
          onRatingUpdate: (rating) async {
            _rating = rating;
            double? avgRating;
            String? numberOfRatings;
            final ref =
            FirebaseDatabase.instance.ref('drivers');
            final snapshot = await ref
                .child(req.driverID)
                .child('averageRating')
                .get();
            if (snapshot.exists) {
              avgRating =
                  double.parse(snapshot.value.toString());
            } else {
              const AlertDialog(
                  semanticLabel: 'No data available.');
            }

            final snapshot2 = await ref
                .child(req.driverID)
                .child('noOfRatings')
                .get();
            numberOfRatings = snapshot2.value.toString();

            avgRating =
                ((avgRating! * int.parse(numberOfRatings)) +
                    _rating!) /
                    (int.parse(numberOfRatings) + 1);

            FirebaseDatabase.instance
                .ref("drivers")
                .child(req.driverID)
                .update(
                {"averageRating": avgRating.toString()});
            FirebaseDatabase.instance
                .ref("drivers")
                .child(req.driverID)
                .update({
              "noOfRatings":
              (int.parse(numberOfRatings) + 1).toString()
            });

            setState(() {});
          },
        );
      }
    },
  );


  String getDistance(String driverDestLat, String driverDestLong) {
    double distance = calculateDistance(
        double.parse(widget.userLatPos),
        double.parse(widget.userLongPos),
        double.parse(driverDestLat),
        double.parse(driverDestLong));
    return distance.toString();
  }

  @override
  Widget build(BuildContext context) {
    Driver dr;
    double? _rating;
    IconData? _selectedIcon;
    return Scaffold(
        appBar: AppBar(
          backgroundColor:  (closeTrips.isEmpty) ? Colors.white : const Color(0xFFEDEDED),
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
              'Available Drivers',
              style: TextStyle(
                  color: Colors.black),
            ),
          ),
        ),
        backgroundColor:  (closeTrips.isEmpty) ? Colors.white : const Color(0xFFEDEDED),
        body: Stack(
          children: [
            if (isTripLoading || isDriverLoading)
              ProgressDialog(
                message: "Searching Drivers",
              )
            else
              (closeTrips.isEmpty) ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "images/noDrivers.jpg",
                        height: 300,
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      const Text(
                        "No drivers found :(",
                        style: TextStyle(
                            fontWeight: FontWeight.w500, color: Colors.blueGrey, fontSize: 18),
                      ),
                    ],
                  ),
                ):
                ListView.builder(
                    itemCount: closeTrips.length,
                    itemBuilder: (context, index) {
                      dr = getDriver(closeTrips[index].driverID);
                      double distance = calculateDistance(
                          double.parse(widget.userLatPos),
                          double.parse(widget.userLongPos),
                          double.parse(closeTrips[index].pickUpLatPos),
                          double.parse(closeTrips[index].pickUpLongPos));
                      double arrivalTime = calculateArrivalTime(distance);

                      return Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: ColorsConst.white,
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(children: [
                          Row(children: [
                            Image.asset(
                              "images/PickUpDestination.png",
                              width: 40,
                              height: 50,
                            ),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    constraints:
                                        const BoxConstraints(maxWidth: 250),
                                    child: Text(
                                      closeTrips[index].destinationLocation.toString(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const Divider(),
                                  Container(
                                    constraints:
                                        const BoxConstraints(maxWidth: 250),
                                    child: Text(
                                      closeTrips[index].pickUpLocation.toString(),
                                      style: const TextStyle(
                                        color: ColorsConst.grey,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                ])
                          ]),
                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // ignore: avoid_unnecessary_containers
                                    Container(
                                      child: Column(
                                        children: [
                                          const Text('Distance'),
                                          Text(
                                              '${distance.toStringAsPrecision(6)} kms'),
                                        ],
                                      ),
                                    ),
                                  ]),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text('Cost'),
                                    Text('${closeTrips[index].price} br.'),
                                  ]),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('Arrival Time'),
                                  Container(
                                    constraints:
                                        const BoxConstraints(maxWidth: 100),
                                    child: Text(
                                      arrivalTime.toStringAsPrecision(2),
                                      style: const TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(closeTrips[index].time.toString()),
                                  Text(formatDate(closeTrips[index].date.toString())),
                                ],
                              ),
                              RatingBarIndicator(
                                itemBuilder: (context, index) => const Icon(
                                  Icons.person,
                                  color: ColorsConst.greenAccent,
                                ),
                                rating: int.parse(
                                        closeTrips[index].passengers.toString()[0]) -
                                    double.parse(closeTrips[index].availableSeats),
                                itemSize: 18,
                                itemCount: int.parse(
                                    closeTrips[index].passengers.toString()[0]),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          const Divider(),
                          Row(
                            children: [
                              GestureDetector(
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(dr.imagePath),
                                      radius: 25,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(dr.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                overflow: TextOverflow.ellipsis,
                                              )),
                                          Row(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.fromLTRB(
                                                    0.0, 0, 3.0, 0),
                                                child: Text(dr.carColor),
                                              ),
                                              Text('${dr.carMake} ${dr.carModel}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  )),
                                            ],
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(right: 10.0),
                                            child: RatingBarIndicator(
                                              itemBuilder: (context, index) =>
                                                  const Icon(
                                                Icons.star,
                                                color: ColorsConst.amber,
                                              ),
                                              rating: double.parse(dr.rating),
                                              itemSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                onTap: (){
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: ((context) =>
                                          AboutDriver(driverID: dr.id))));
                                },
                              ),
                              const Spacer(),
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
                                        ? 'Requested'
                                        : 'Request',
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // ElevatedButton(
                          //   onPressed: () {
                          //     Future<void> makePayment(
                          //         BuildContext context) async {
                          //       var headers = {
                          //         'Authorization':
                          //             'Bearer CHASECK_TEST-NHFsyWe3Vt3pE9Ke4evqbvwvXzjTc0uA',
                          //         'Content-Type': 'application/json'
                          //       };
                          //       var request = http.Request(
                          //           'POST',
                          //           Uri.parse(
                          //               'https://api.chapa.co/v1/transaction/initialize'));
                          //       request.body = json.encode({
                          //         "amount": "100",
                          //         "currency": "ETB",
                          //         "email": "ihs@gmail.com",
                          //         "first_name": "Abebech",
                          //         "phone_number": "0929209202",
                          //         "tx_ref": "2ewxxaaaaAwwq",
                          //         "callback_url":
                          //             "https://webhook.site/077164d6-29cb-40df-ba29-8a00e59a7e60",
                          //         "return_url": "https://www.google.com/",
                          //         "customization[title]":
                          //             "Payment for carpooling",
                          //         "customization[description]":
                          //             "Payment for Samson Sisay for carpooling"
                          //       });
                          //       request.headers.addAll(headers);
                          //
                          //       http.StreamedResponse response =
                          //           await request.send();
                          //
                          //       if (response.statusCode == 200) {
                          //         final responseBody =
                          //             await response.stream.bytesToString();
                          //         final responseJson = json.decode(responseBody);
                          //         final checkoutUrl =
                          //             responseJson['data']['checkout_url'];
                          //         // Navigate to the checkout URL
                          //         // ignore: use_build_context_synchronously
                          //         await Navigator.of(context).push(
                          //             MaterialPageRoute(
                          //                 builder: (_) =>
                          //                     WebViewScreen(checkoutUrl)));
                          //       } else {
                          //         print(response.reasonPhrase);
                          //         print(response.statusCode);
                          //       }
                          //     }
                          //
                          //     makePayment(context);
                          //   },
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: ColorsConst.greenAccent,
                          //     elevation: 3,
                          //     shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(10)),
                          //   ),
                          //   child: const Text(
                          //     'Pay online',
                          //     style: TextStyle(
                          //       fontSize: 16,
                          //     ),
                          //   ),
                          // ),
                          // RatingBar.builder(
                          //   initialRating: _rating ?? 0.0,
                          //   minRating: 1,
                          //   direction: Axis.horizontal,
                          //   allowHalfRating: false,
                          //   itemCount: 5,
                          //   itemSize: 50,
                          //   itemPadding:
                          //       const EdgeInsets.symmetric(horizontal: 8),
                          //   itemBuilder: (context, _) => Icon(
                          //     _selectedIcon ?? Icons.star,
                          //     color: ColorsConst.amber,
                          //   ),
                          //   onRatingUpdate: (rating) async {
                          //     _rating = rating;
                          //     double? avgRating;
                          //     String? numberOfRatings;
                          //     final ref =
                          //         FirebaseDatabase.instance.ref('drivers');
                          //     final snapshot = await ref
                          //         .child(closeTrips[index].driverID)
                          //         .child('averageRating')
                          //         .get();
                          //     if (snapshot.exists) {
                          //       avgRating =
                          //           double.parse(snapshot.value.toString());
                          //     } else {
                          //       const AlertDialog(
                          //           semanticLabel: 'No data available.');
                          //     }
                          //
                          //     final snapshot2 = await ref
                          //         .child(closeTrips[index].driverID)
                          //         .child('noOfRatings')
                          //         .get();
                          //     numberOfRatings = snapshot2.value.toString();
                          //
                          //     avgRating =
                          //         ((avgRating! * int.parse(numberOfRatings)) +
                          //                 _rating!) /
                          //             (int.parse(numberOfRatings) + 1);
                          //
                          //     FirebaseDatabase.instance
                          //         .ref("drivers")
                          //         .child(closeTrips[index].driverID)
                          //         .update(
                          //             {"averageRating": avgRating.toString()});
                          //     FirebaseDatabase.instance
                          //         .ref("drivers")
                          //         .child(closeTrips[index].driverID)
                          //         .update({
                          //       "noOfRatings":
                          //           (int.parse(numberOfRatings) + 1).toString()
                          //     });
                          //
                          //     setState(() {});
                          //   },
                          // ),
                        ]),
                      );
                    }),
          ],
        ));
  }

  Future<void> makePayment(BuildContext context) async {
    var headers = {
      'Authorization': 'Bearer CHASECK_TEST-NHFsyWe3Vt3pE9Ke4evqbvwvXzjTc0uA',
      'Content-Type': 'application/json'
    };
    var request = http.Request(
        'POST', Uri.parse('https://api.chapa.co/v1/transaction/initialize'));
    request.body = json.encode({
      "amount": "100",
      "currency": "ETB",
      "email": "tt@gmail.com",
      "first_name": "Samson",
      "last_name": "Sisay",
      "phone_number": "0911243697",
      "tx_ref": "sdadas2121ccxx",
      "callback_url":
          "https://webhook.site/077164d6-29cb-40df-ba29-8a00e59a7e60",
      "return_url": "https://www.google.com/",
      "customization[title]": "Payment for carpooling",
      "customization[description]": "Payment for Samson Sisay for carpooling"
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final responseJson = json.decode(responseBody);
      final checkoutUrl = responseJson['data']['checkout_url'];
      // Navigate to the checkout URL
      // ignore: use_build_context_synchronously
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => WebViewScreen(checkoutUrl)));
    } else {
      print(response.reasonPhrase);
      print(response.statusCode);
    }
  }

  String formatDate(String inputStr) {
    // Convert the input string to a DateTime object
    DateTime date = DateTime.parse(inputStr);

    // Format the DateTime object as a String in the desired format
    String formattedStr = DateFormat('EEEE, MMMM d y').format(date);

    return formattedStr;
  }

  double calculateDistance(
      double userLat, double userLong, double destLat, double destLong) {
    double distance, earthRadius = 6371;
    double lat1Rad = degreesToRadians(userLat);
    double lon1Rad = degreesToRadians(userLong);
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

  double degreesToRadians(double degrees) {
    // Helper function to convert degrees to radians
    return degrees * pi / 180;
  }

  Driver getDriver(String id) {
    Driver nullDriver = const Driver(
        id: '',
        imagePath: '',
        name: '',
        email: '',
        phone: '',
        totalMileage: '',
        carMake: '',
        carModel: '',
        carYear: '',
        carColor: '',
        carPlateNo: '',
        rating: '',
        noOfRatings: '');
    for (var driver in drivers) {
      if (driver.id == id) {
        return driver;
      }
    }
    return nullDriver;
  }

  double calculateArrivalTime(double distance) {
    double velocity = 30, arrivalTime;
    arrivalTime = (distance / velocity) * 60;
    return arrivalTime;
  }

  final CollectionReference statusCollection =
      FirebaseFirestore.instance.collection('requestStatus');

  void requestRide(TripsModel trip) async {
    String requestID = currentFirebaseUser!.uid + trip.tripID;

    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child('requests/$requestID').get();
    if (snapshot.exists) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Driver already requested'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              )
            ],
          );
        },
      );
    } else {
      FirebaseDatabase.instance.ref().child("requests").child(requestID).set({
        "requestID": requestID,
        "tripID": trip.tripID,
        "driverID": trip.driverID,
        "userID": currentFirebaseUser!.uid.toString(),
        "status": "pending",
      });
      Fluttertoast.showToast(msg: "Driver Requested");
      final DocumentReference newStatusRef = await statusCollection.add({
        'title': 'Request',
        'description':
        'A passenger has requested to pool to ${trip.destinationLocation}',
      });
    }

  }

  void _onCancelButtonPressed(int index) {
    setState(() {
      _isCancelButtonClickedList[index] = true;
    });

    requestRide(closeTrips[index]);
  }
}
