import 'package:flutter/material.dart';

class GeoEventLogo extends StatelessWidget {
  final double fontSize;
  final Color color;

  const GeoEventLogo({
    super.key, 
    this.fontSize = 28, 
    // MODIFICA: Nuovo colore Viola/Lilla vibrante
    this.color = const Color.fromARGB(255, 185, 80, 255), 
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start, // Allineato a sinistra per la Home
      children: [
        Text(
          "GE",
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900, // Equivale a 'black'
            color: color,
            letterSpacing: -1,
          ),
        ),
        // Il segnaposto che fa da "O"
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