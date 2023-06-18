// ignore_for_file: must_be_immutable
import 'package:car_pool_driver/Constants/styles/colors.dart';
import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  String message;
  LoadingScreen({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorsConst.white,
      child: Container(
        margin: const EdgeInsets.all(15.0),
        width: double.infinity,
        decoration: BoxDecoration(
            color: ColorsConst.white, borderRadius: BorderRadius.circular(6.0)),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(children: [
            const SizedBox(
              width: 6.0,
            ),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ColorsConst.black),
            ),
            const SizedBox(
              width: 26.0,
            ),
            Text(
              message,
              style: const TextStyle(color: ColorsConst.black, fontSize: 10.0),
            ),
          ]),
        ),
      ),
    );
  }
}
