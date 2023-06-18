import 'package:car_pool_driver/Models/address.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../Constants/styles/colors.dart';
import '../../Constants/styles/styles.dart';
import '../../Constants/widgets/loading.dart';
import '../../Models/place_predictions.dart';
import '../../config_map.dart';
import '../../widgets/progress_dialog.dart';
import '../assistants/assistant_methods.dart';
import '../assistants/request_assistant.dart';
import '../data handler/app_data.dart';

class SearchPickUpScreen extends StatefulWidget {
  const SearchPickUpScreen({super.key});

  @override
  State<SearchPickUpScreen> createState() => _SearchPickUpScreenState();
}

class _SearchPickUpScreenState extends State<SearchPickUpScreen> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  bool _isLoading = false;
  TextEditingController destinationTextEditingController =
  TextEditingController();
  late Position currentPosition;


  List<PlacePredictions> placePredictionList = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          searchBar(context),
          (placePredictionList.isNotEmpty)
              ? Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 8.0, horizontal: 16.0),
            child: ListView.separated(
              padding: const EdgeInsets.all(8.0),
              itemBuilder: (context, index) {
                return PredictionTile(
                    placePredictions: placePredictionList[index]);
              },
              separatorBuilder: (BuildContext context, int index) =>
              const Divider(),
              itemCount: placePredictionList.length,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
            ),
          )
              : Container(),
        ],
      ),
    );
  }

  Widget searchBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black,
            blurRadius: 6.0,
            spreadRadius: 0.5,
            offset: Offset(0.7, 0.7))
      ]),
      height: 300.0,
      child: Padding(
        padding: const EdgeInsets.only(
            left: 25.0, top: 35.0, right: 25.0, bottom: 20.0),
        child: Column(children: [
          const SizedBox(
            height: 5.0,
          ),
          Stack(
            children: [
              GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.arrow_back)),
              const Center(
                  child: Text(
                    "Set Pick Up",
                    style: TextStyle(fontSize: 18.0),
                  ))
            ],
          ),
          const SizedBox(
            height: 16.0,
          ),
          Row(
            children: [
              Expanded(
                // ignore: avoid_unnecessary_containers
                  child: Container(
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: TextFormField(
                        onChanged: (val) {
                          findPlace(val);
                        },
                        decoration: InputDecoration(
                          enabledBorder: StylesConst.textBorder,
                          focusedBorder: StylesConst.textBorder,
                          filled: true,
                          label: const Text(
                            "Pick-Up",
                            style: TextStyle(fontSize: 17),
                          ),
                          labelStyle: StylesConst.labelStyle,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              pickUpTextEditingController.clear();
                            },
                          ),
                        ),
                        controller: pickUpTextEditingController,
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ))
            ],
          ),
          const SizedBox(
            height: 10.0,
          ),
        Column(
          children: [
            // Add your UI widgets here
            TextButton(
              onPressed: () {
                locatePosition();
              },
              style: TextButton.styleFrom(
                primary: Colors.blue, // button text color
                backgroundColor: Colors.white, // button background color
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    // button border radius
                    side: BorderSide(color: Colors.greenAccent) // button border
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0), // button padding
              ),
              child: Row(
                children: const [
                  Icon(Icons.location_on, color: Colors.greenAccent),
                  // leading icon
                  SizedBox(width: 8.0),
                  // space between icon and text
                  Text("Set current Location",
                      style: TextStyle(fontSize: 14.0, color: Colors.greenAccent)),
                  // button text
                ],
              ),
            ),
            if (_isLoading)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Column(
                  children: const [
                    CircularProgressIndicator(),
                  ],
                ),
              ),
          ],
        ),
        ])
      ),
    );
  }

  void locatePosition() async {
    try {
      setState(() {
        _isLoading = true;
      });

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPosition = position;

      String address = await AssistantMethods.searchCoordinateAddress(
        position,
        context,
      );

      String? pickUpLocation =
          Provider.of<AppData>(context, listen: false)
              .pickUpLocation
              ?.placeName;
      pickUpTextEditingController.text = (pickUpLocation.toString() == 'null')
          ? 'Retrieving Location...'
          : pickUpLocation.toString();

      Address currentAddress = Address(
        placeFormattedAddress: address.toString(),
        placeName: pickUpLocation.toString(),
        placeId: '',
        latitude: position.latitude,
        longitude: position.longitude,
      );

      Provider.of<AppData>(context, listen: false)
          .updatePickUpLocationAddress(currentAddress);

      Navigator.pop(context);
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  void findPlace(String placeName) async {
    if (placeName.length > 1) {
      String autoCompleteUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=1234567890&components=country:et";

      var res = await RequestAssistant.getRequest(autoCompleteUrl);

      if (res == "failed") {
        return;
      }

      if (res["status"] == "OK") {
        var predictions = res["predictions"];

        var placesList = (predictions as List)
            .map((e) => PlacePredictions.fromJson(e))
            .toList();

        setState(() {
          placePredictionList = placesList;
        });
      }
    }
  }
}

class PredictionTile extends StatelessWidget {
  final PlacePredictions placePredictions;
  const PredictionTile({Key? key, required this.placePredictions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_unnecessary_containers
    return TextButton(
      onPressed: () {
        getPlaceAddress(placePredictions.place_id, context);
      },
      child: Container(
        child: Column(children: [
          const SizedBox(
            width: 10.0,
          ),
          Row(
            children: [
              const SizedBox(
                width: 14.0,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 8.0,
                    ),
                    Text(placePredictions.main_text,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16.0)),
                    const SizedBox(
                      height: 2.0,
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(
            width: 10.0,
          ),
        ]),
      ),
    );
  }

  void getPlaceAddress(String placeID, context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return LoadingScreen(message: "Retrieving, please wait...");
        });
    String placeDetailsURL =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeID&key=$mapKey";
    var res = await RequestAssistant.getRequest(placeDetailsURL);

    Navigator.pop(context);

    if (res == "failed") {
      return;
    }
    if (res["status"] == "OK") {
      Address address = Address(
          placeFormattedAddress: res["result"]["formatted_address"],
          placeName: res["result"]["name"],
          placeId: placeID,
          latitude: res["result"]["geometry"]["location"]["lat"],
          longitude: res["result"]["geometry"]["location"]["lng"]);

      Provider.of<AppData>(context, listen: false)
          .updatePickUpLocationAddress(address);

      Navigator.pop(context, "obtainDirection");
    }
  }
}
