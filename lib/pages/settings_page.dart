import 'package:flutter/material.dart';
import 'package:way_to_class/service/toast.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool setting1 = false;
  bool setting2 = false;
  bool setting3 = false;

  void saveSettings() {
    // Hier könnte man die Einstellungen speichern
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Einstellungen gespeichert!')));
  }

  Widget buildSetting(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Icon(icon, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18)),
            ],
          ),
          Switch(
            trackColor:
                value
                    ? WidgetStatePropertyAll(Color(0xFF9B006E)) // Wenn an, Blau
                    : WidgetStatePropertyAll(Color(0xFFD56BA6)),
            thumbColor: WidgetStatePropertyAll(Colors.white),
            trackOutlineColor: WidgetStatePropertyAll(Colors.white),
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blueGrey,
        title: const Text(
          'Einstellungen',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildSetting('Gemini', Icons.psychology_alt_outlined, setting1, (
            val,
          ) {
            setState(() => setting1 = val);
          }),
          buildSetting('Cache', Icons.archive_outlined, setting2, (val) {
            setState(() => setting2 = val);
          }),
          buildSetting('Dark Mode', Icons.dark_mode, setting3, (val) {
            setState(() => setting3 = val);
          }),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.blueGrey),
            ),
            onPressed: () => Toast.successToast("Erfolgreich gespeichert"),
            child: const Text(
              'Speichern',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
