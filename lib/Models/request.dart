class Request{
  final String requestID;
  final String tripID;
  final String driverID;
  final String userID;
  final String status;

  const Request({
    required this.requestID,
    required this.tripID,
    required this.driverID,
    required this.userID,
    required this.status,
  });
}