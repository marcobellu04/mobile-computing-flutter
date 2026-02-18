import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import 'event_detail_screen.dart';

class AllEventsPage extends StatelessWidget {
  const AllEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventProvider>().events;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tutti gli Eventi", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 50, height: 50, color: Colors.amber[100],
                  child: (event.imagePath != null && File(event.imagePath!).existsSync())
                      ? Image.file(File(event.imagePath!), fit: BoxFit.cover)
                      : const Icon(Icons.event, color: Colors.amber),
                ),
              ),
              title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${event.date.day}/${event.date.month} - ${event.zone ?? ''}"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))),
            ),
          );
        },
      ),
    );
  }
}