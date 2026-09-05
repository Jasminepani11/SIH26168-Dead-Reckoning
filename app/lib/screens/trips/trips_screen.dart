import 'package:flutter/material.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        title: const Text(
          'Trips',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _TripCard(
            location: 'GITAM University',
            date: 'Today',
            duration: '18 min',
            distance: '1.4 km',
            steps: '1,842 steps',
          ),

          _TripCard(
            location: 'Home',
            date: 'Yesterday',
            duration: '24 min',
            distance: '2.1 km',
            steps: '2,736 steps',
          ),

          SizedBox(height: 30),

          Center(
            child: Text(
              'NO MORE TRIPS',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2,
                color: Color(0xFF505866),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final String location;
  final String date;
  final String duration;
  final String distance;
  final String steps;

  const _TripCard({
    required this.location,
    required this.date,
    required this.duration,
    required this.distance,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF11161D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Trip icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              color: Color(0xFF00E5FF),
              size: 25,
            ),
          ),

          const SizedBox(width: 16),

          // Trip information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '$date • $duration • $distance',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A94A6),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  steps,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF00E5FF),
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF505866),
          ),
        ],
      ),
    );
  }
}