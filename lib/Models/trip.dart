class TripsModel {
  final String tripID;
  final String driverID;
  final String pickUpLatPos;
  final String pickUpLongPos;
  final String dropOffLatPos;
  final String dropOffLongPos;
  final double pickUpDistance;
  final double dropOffDistance;
  final String destinationLocation;
  final String pickUpLocation;
  final String price;
  final List<String> userIDs;
  final String date;
  final String time;
  final String availableSeats;
  final String passengers;
  final String status;

  const TripsModel({
    required this.tripID,
    required this.driverID,
    required this.pickUpLatPos,
    required this.pickUpLongPos,
    required this.dropOffLatPos,
    required this.dropOffLongPos,
    required this.pickUpDistance,
    required this.dropOffDistance,
    required this.destinationLocation,
    required this.pickUpLocation,
    required this.userIDs,
    required this.price,
    required this.date,
    required this.time,
    required this.availableSeats,
    required this.passengers,
    required this.status
  });
}
