import 'package:car_pool_driver/Constants/styles/colors.dart';
import 'package:flutter/material.dart';

class ProfileWidget extends StatelessWidget {
  final String imagePath;
  final VoidCallback onClicked;

  const ProfileWidget(
      {Key? key, required this.imagePath, required this.onClicked})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Center(
        child: Stack(
      children: [
        buildImage(),
      ],
    ));
  }

  Widget buildImage() {
    final image = NetworkImage(imagePath);

    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: Ink.image(
          image: image,
          fit: BoxFit.cover,
          width: 132,
          height: 132,
          child: InkWell(onTap: onClicked),
        ),
      ),
    );
  }

  Widget buildEditIcon(Color color) => buildCircle(
        color: color,
        child: const Icon(
          Icons.edit,
          color: ColorsConst.greenAccent,
          size: 20,
        ),
      );

  Widget buildCircle({
    required Widget child,
    required Color color,
  }) =>
      ClipOval(
        child: Container(
          padding: const EdgeInsets.all(8.0),
          color: color,
          child: child,
        ),
      );
}
