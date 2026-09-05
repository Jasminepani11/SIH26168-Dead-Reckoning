import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          children: [
            const Text(
              'SETTINGS',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Configure your navigation experience',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),

            const SizedBox(height: 28),

            const _SectionTitle('NAVIGATION'),

            _SettingTile(
              icon: Icons.record_voice_over_outlined,
              title: 'Voice Guidance',
              subtitle: 'Turn-by-turn voice instructions',
              trailing: Switch(
                value: true,
                onChanged: null,
              ),
            ),

            _SettingTile(
              icon: Icons.vibration_outlined,
              title: 'Haptic Feedback',
              subtitle: 'Vibration during navigation',
              trailing: Switch(
                value: true,
                onChanged: null,
              ),
            ),

            const SizedBox(height: 24),

            const _SectionTitle('SENSORS'),

            _SettingTile(
              icon: Icons.sensors_outlined,
              title: 'Sensor Diagnostics',
              subtitle: 'View connected phone sensors',
              trailing: const Icon(
                Icons.chevron_right,
                color: Color(0xFF8A94A6),
              ),
            ),

            _SettingTile(
              icon: Icons.explore_outlined,
              title: 'Calibration',
              subtitle: 'Calibrate navigation sensors',
              trailing: const Icon(
                Icons.chevron_right,
                color: Color(0xFF8A94A6),
              ),
            ),

            const SizedBox(height: 24),

            const _SectionTitle('ABOUT'),

            _SettingTile(
              icon: Icons.info_outline,
              title: 'DRIFT',
              subtitle: 'GPS-Denied Intelligent Navigation',
              trailing: const Text(
                'v1.0.0',
                style: TextStyle(
                  color: Color(0xFF8A94A6),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 2,
          color: Color(0xFF00E5FF),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11161D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF00E5FF),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A94A6),
                  ),
                ),
              ],
            ),
          ),

          trailing,
        ],
      ),
    );
  }
}