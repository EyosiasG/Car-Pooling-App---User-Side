import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../Constants/styles/colors.dart';
import '../../global/global.dart';
import '../../widgets/progress_dialog.dart';

class MyFeedback extends StatefulWidget {
  const MyFeedback({Key? key}) : super(key: key);

  @override
  State<MyFeedback> createState() => _MyFeedbackState();
}

class _MyFeedbackState extends State<MyFeedback> {
  TextEditingController feedbackTextEditingController = TextEditingController();
  List<String> supportType = [
    "Feedback",
    "Driver Attitude",
    "Item Lost",
    "About our app",
    "Other"
  ];
  String? selectedSupportType;

  validateForm() {
    if (selectedSupportType == null) {
      Fluttertoast.showToast(msg: "Select a title.");
    } else if (feedbackTextEditingController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Feedback Field is empty");
    } else {
      saveFeedbackInfo();
    }
  }

  saveFeedbackInfo() async {
    String feedbackID = DateTime.now().microsecondsSinceEpoch.toString() +
        currentFirebaseUser!.uid.toString();
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext c) {
          return ProgressDialog(
            message: "Processing, Please wait...",
          );
        });
    Map feedbackMap = {
      "feedbackID": feedbackID,
      "clientType": "Passenger",
      "userID": currentFirebaseUser!.uid.toString(),
      "title": selectedSupportType,
      "feedback": feedbackTextEditingController.text.toString(),
    };

    DatabaseReference driverRef =
        FirebaseDatabase.instance.ref().child("feedbacks");
    driverRef.child(feedbackID).set(feedbackMap);

    Fluttertoast.showToast(msg: "Feedback has been sent");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                "images/support.jpg",
                height: 350,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Title',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  DropdownButtonFormField(
                    hint: const Text("Choose Type",
                        style:
                            TextStyle(fontSize: 14.0, color: ColorsConst.grey)),
                    value: selectedSupportType,
                    onChanged: (newValue) {
                      setState(() {
                        selectedSupportType = newValue.toString();
                      });
                    },
                    items: supportType.map((support) {
                      return DropdownMenuItem(
                        value: support,
                        child: Text(
                          support,
                          style: const TextStyle(color: ColorsConst.grey),
                        ),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: ColorsConst.grey),
                          borderRadius: BorderRadius.circular(10.0)),
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: ColorsConst.grey)),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    'Feedback',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  TextField(
                    controller: feedbackTextEditingController,
                    minLines: 3,
                    // Set this
                    maxLines: 6,
                    // and this
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: "Tell us you will help us a lot!!",
                      enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: ColorsConst.grey),
                          borderRadius: BorderRadius.circular(10.0)),
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: ColorsConst.grey)),
                      hintStyle: const TextStyle(
                        color: ColorsConst.grey,
                        fontSize: 16,
                      ),
                      labelStyle: const TextStyle(
                        color: ColorsConst.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Center(
                    child: SizedBox(
                      height: 60,
                      width: 300,
                      child: ElevatedButton(
                          onPressed: () {
                            validateForm();
                            //Navigator.push(context, MaterialPageRoute(builder: (c)=> CarInfoScreen()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorsConst.greenAccent,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                //to set border radius to button
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            "Send Feedback",
                            style: TextStyle(
                              color: ColorsConst.white,
                              fontSize: 18,
                            ),
                          )),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
