import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../main.dart';
import '../../Constants/styles/colors.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key, required this.userKey});

  final String userKey;

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void getUserData() async {
    DataSnapshot userUpdateRef = await userRef.child(widget.userKey).get();
    Map userData = userUpdateRef.value as Map;
    nameController.text = userData['name'];
    phoneController.text = userData['phone'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorsConst.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close),
          color: ColorsConst.black,
        ),
        title: const Text(
          "Update your profile",
          style: TextStyle(color: ColorsConst.black),
        ),
        elevation: 0,
      ),
      body: textFields(context),
    );
  }

  Widget textFields(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        child: Padding(
          padding: const EdgeInsets.only(left: 18.0, right: 18.0, top: 10.0),
          child: Column(
            children: [
              TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: ColorsConst.grey),
                  decoration: InputDecoration(
                    labelText: "Name",
                    hintText: "Name",
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
                  )),
              const SizedBox(
                height: 15.0,
              ),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: ColorsConst.grey),
                decoration: InputDecoration(
                    labelText: "Phone",
                    hintText: "Phone",
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
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                onPressed: () {
                  Map<String, String> users = {
                    'name': nameController.text,
                    'phone': phoneController.text,
                  };
                  try {
                    userRef.child(widget.userKey).update(users).then((value) =>
                        {
                          Fluttertoast.showToast(
                              msg: "User information updated"),
                          Navigator.pop(context)
                        });
                  } catch (exp) {
                    Fluttertoast.showToast(msg: "Error updating $exp");
                  }
                },
                child: const Text("Update my profile"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
