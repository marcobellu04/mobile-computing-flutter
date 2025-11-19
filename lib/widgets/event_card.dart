import 'package:flutter/material.dart';
import 'rounded_card.dart';

class EventCard extends StatelessWidget {
  final String title;
  final String date;
  final int attendees;
  final VoidCallback? onTap;  // callback per tap sulla card

  const EventCard({
    super.key,
    required this.title,
    required this.date,
    required this.attendees,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: RoundedCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(20), // Deve corrispondere a RoundedCard
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Data: $date',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  'Partecipanti: $attendees',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
