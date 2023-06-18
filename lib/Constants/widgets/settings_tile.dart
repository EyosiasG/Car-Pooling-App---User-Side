import 'package:car_pool_driver/Constants/styles/colors.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class SettingsTiles extends StatelessWidget {
  String titleText;

  SettingsTiles({
    Key? key,
    required this.titleText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        titleText,
        style: const TextStyle(
            fontWeight: FontWeight.w500, color: ColorsConst.grey800),
      ),
    );
  }
}
