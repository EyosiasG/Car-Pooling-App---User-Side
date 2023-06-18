import 'package:flutter/material.dart';

import '../Constants/styles/colors.dart';

// ignore: must_be_immutable
class ProgressDialog extends StatelessWidget {
  String? message;
  ProgressDialog({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
        backgroundColor: Colors.white,
        child: Container(
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 6.0,
                    ),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          ColorsConst.greenAccent),
                    ),
                    const SizedBox(width: 26.0),
                    Text(
                      message!,
                      style: const TextStyle(
                        color: ColorsConst.grey,
                        fontSize: 12,
                      ),
                    )
                  ],
                ))));
  }
}
