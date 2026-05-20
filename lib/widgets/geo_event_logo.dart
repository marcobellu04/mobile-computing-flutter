import 'package:flutter/material.dart';

class GeoEventLogo extends StatelessWidget {
  final double fontSize;
  final Color color;

  const GeoEventLogo({
    super.key,
    this.fontSize = 28,
    // Di default usa il tuo lilla/viola vibrante per la Home o altre pagine chiare
    this.color = const Color.fromARGB(255, 185, 80, 255),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          "GE",
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -1,
          ),
        ),
        Transform.translate(
          offset: Offset(0, -fontSize * 0.05),
          child: Icon(
            Icons.location_on,
            size: fontSize * 1.1,
            color: color,
          ),
        ),
        Text(
          "EVENT",
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}