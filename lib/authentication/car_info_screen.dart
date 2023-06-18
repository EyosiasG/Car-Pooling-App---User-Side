import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';
import '../Constants/styles/colors.dart';
import '../global/global.dart';
import '../splashScreen/splash_screen.dart';

class CarInfoScreen extends StatefulWidget {
  const CarInfoScreen({Key? key}) : super(key: key);

  @override
  State<CarInfoScreen> createState() => _CarInfoScreenState();
}

class _CarInfoScreenState extends State<CarInfoScreen> {
  TextEditingController carModelTextEditingController = TextEditingController();
  TextEditingController carNumberTextEditingController =
      TextEditingController();
  TextEditingController carColorTextEditingController = TextEditingController();

  List<String> carTypesList = ["uber-x", "uber-go", "bike"];
  String? selectedCarType;

  saveCarInfo() {
    Map driverCarInfoMap = {
      "car_color": carColorTextEditingController.text.trim(),
      "car_number": carNumberTextEditingController.text.trim(),
      "car_model": carModelTextEditingController.text.trim(),
      "type": selectedCarType,
    };

    DatabaseReference driverRef =
        FirebaseDatabase.instance.ref().child("drivers");
    driverRef
        .child(currentFirebaseUser!.uid)
        .child("car_details")
        .set(driverCarInfoMap);

    Fluttertoast.showToast(msg: "Car Details has been saved");
    Navigator.push(
        context, MaterialPageRoute(builder: (c) => const MySplashScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsConst.white,
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(
              height: 24,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Image.asset("images/splashScreen.jpg"),
            ),
            const SizedBox(
              height: 10,
            ),
            const Text("Car Details,",
                style: TextStyle(
                    fontSize: 24,
                    color: ColorsConst.black,
                    fontWeight: FontWeight.bold)),
            const SizedBox(
              height: 20,
            ),
            TextField(
              controller: carModelTextEditingController,
              style: const TextStyle(color: ColorsConst.grey),
              decoration: InputDecoration(
                labelText: "Car Model",
                hintText: "Car Model",
                enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ColorsConst.grey),
                    borderRadius: BorderRadius.circular(10.0)),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: ColorsConst.grey)),
                hintStyle: const TextStyle(
                  color: ColorsConst.grey,
                  fontSize: 10,
                ),
                labelStyle: const TextStyle(
                  color: ColorsConst.grey,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: carNumberTextEditingController,
              style: const TextStyle(color: ColorsConst.grey),
              decoration: InputDecoration(
                labelText: "Plate No",
                hintText: "Plate No",
                enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ColorsConst.grey),
                    borderRadius: BorderRadius.circular(10.0)),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: ColorsConst.grey)),
                hintStyle: const TextStyle(
                  color: ColorsConst.grey,
                  fontSize: 10,
                ),
                labelStyle: const TextStyle(
                  color: ColorsConst.grey,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: carColorTextEditingController,
              style: const TextStyle(color: ColorsConst.grey),
              decoration: InputDecoration(
                labelText: "Car Color",
                hintText: "Car Color",
                enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ColorsConst.grey),
                    borderRadius: BorderRadius.circular(10.0)),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: ColorsConst.grey)),
                hintStyle: const TextStyle(
                  color: ColorsConst.grey,
                  fontSize: 10,
                ),
                labelStyle: const TextStyle(
                  color: ColorsConst.grey,
                  fontSize: 16,
                ),
              ),
            ),
            DropdownButton(
                hint: const Text("Choose Car Type",
                    style: TextStyle(fontSize: 14.0, color: ColorsConst.black)),
                value: selectedCarType,
                onChanged: (newValue) {
                  setState(() {
                    selectedCarType = newValue.toString();
                  });
                },
                items: carTypesList.map((car) {
                  return DropdownMenuItem(
                    value: car,
                    child: Text(
                      car,
                      style: const TextStyle(color: ColorsConst.grey),
                    ),
                  );
                }).toList()),
            SizedBox(
              height: 50,
              width: 300,
              child: ElevatedButton(
                  onPressed: () {
                    if (carColorTextEditingController.text.isNotEmpty &&
                        carNumberTextEditingController.text.isNotEmpty &&
                        carModelTextEditingController.text.isNotEmpty &&
                        // ignore: unrelated_type_equality_checks
                        selectedCarType != Null) {
                      saveCarInfo();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsConst.greenAccent,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        //to set border radius to button
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      color: ColorsConst.white,
                      fontSize: 18,
                    ),
                  )),
            )
          ],
        ),
      )),
    );
  }
}
