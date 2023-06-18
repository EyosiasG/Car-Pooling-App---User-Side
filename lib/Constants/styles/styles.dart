import 'package:car_pool_driver/Constants/styles/colors.dart';
import 'package:flutter/material.dart';

class StylesConst {
  static final ButtonStyle buttonTheme = ButtonStyle(
      backgroundColor: MaterialStateProperty.all(Colors.blue[700]),
      shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))));
  static final OutlineInputBorder textBorder = OutlineInputBorder(
    borderSide: const BorderSide(
      width: 0.0,
      color: Colors.transparent,
    ),
    borderRadius: BorderRadius.circular(18.0),
  );
  static const TextStyle labelStyle =
      TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600);

  static const TextStyle hintStyle = TextStyle(
    color: ColorsConst.blueGrey,
    fontSize: 10.0,
  );
}
