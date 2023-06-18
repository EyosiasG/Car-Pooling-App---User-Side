import 'package:car_pool_driver/Views/trips/trips_card.dart';
import 'package:flutter/material.dart';

class TripList extends StatelessWidget {
  static const String idScreen = "tripList";
  const TripList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: TripCards(),
    );
  }
}
