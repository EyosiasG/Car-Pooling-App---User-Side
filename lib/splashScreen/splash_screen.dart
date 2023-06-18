import 'dart:async';
import 'package:car_pool_driver/Constants/styles/colors.dart';
import 'package:flutter/material.dart';
import '../authentication/login_screen.dart';
import '../global/global.dart';
import '../mainScreens/main_screen.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({Key? key}) : super(key: key);

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  startTimer() {
    Timer(const Duration(seconds: 3), () async {
      if (fAuth.currentUser != null) {
        currentFirebaseUser = fAuth.currentUser;
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => const MainScreen()));
      } else {
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => LoginScreen()));
      }
      //send user to home screen
    });
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
          color: ColorsConst.white,
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("images/splashScreen.jpg"),
              const SizedBox(
                height: 10,
              ),
              const Text("Ride Together,",
                  style: TextStyle(
                      fontSize: 24,
                      color: ColorsConst.black,
                      fontWeight: FontWeight.bold)),
              const SizedBox(
                height: 5,
              ),
              const Text("Share Together,",
                  style: TextStyle(
                      fontSize: 24,
                      color: ColorsConst.black,
                      fontWeight: FontWeight.bold)),
              const SizedBox(
                height: 5,
              ),
              const Text("With our ride sharing app,",
                  style: TextStyle(
                      fontSize: 24,
                      color: ColorsConst.black,
                      fontWeight: FontWeight.bold))
            ],
          ))),
    );
  }
}
