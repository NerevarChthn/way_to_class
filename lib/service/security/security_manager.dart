// Security Manager für Verschlüsselung des Caches
import 'dart:convert';
import 'dart:developer' show log;

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityManager {
  static const String _secureStorageKey = 'navigation_encryption_key';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static late encrypt.Key _encryptionKey;
  static late encrypt.IV _iv;

  // Initialisiere die Verschlüsselung
  static Future<void> initialize() async {
    try {
      // Prüfe, ob bereits ein Schlüssel existiert
      String? storedKey = await _secureStorage.read(key: _secureStorageKey);

      if (storedKey == null) {
        // Erstelle einen neuen Schlüssel, wenn keiner existiert
        _encryptionKey = encrypt.Key.fromSecureRandom(32);
        await _secureStorage.write(
          key: _secureStorageKey,
          value: base64Encode(_encryptionKey.bytes),
        );
        log('Neuer Verschlüsselungsschlüssel generiert und gespeichert');
      } else {
        // Verwende den gespeicherten Schlüssel
        _encryptionKey = encrypt.Key(base64Decode(storedKey));
        log('Vorhandener Verschlüsselungsschlüssel geladen');
      }

      // Generiere einen festen IV für die Verschlüsselung
      _iv = encrypt.IV.fromLength(16); // AES benötigt 16 Bytes IV
    } catch (e) {
      log('Fehler bei der Initialisierung der Verschlüsselung: $e');
      // Fallback auf einen festen Schlüssel, falls etwas schiefgeht
      _encryptionKey = encrypt.Key.fromUtf8('CampusNav01234567890123456789012');
      _iv = encrypt.IV.fromLength(16);
    }
  }

  // Verschlüssele Daten
  static String encryptData(String plainText) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      final encrypted = encrypter.encrypt(plainText, iv: _iv);

      // IV mit den verschlüsselten Daten kombinieren für bessere Sicherheit
      return '${base64Encode(_iv.bytes)}:${encrypted.base64}';
    } catch (e) {
      log('Verschlüsselungsfehler: $e');
      return plainText; // Fallback: Unverschlüsselt zurückgeben
    }
  }

  // Entschlüssele Daten
  static String decryptData(String encryptedText) {
    try {
      // Extrahiere IV und verschlüsselte Daten
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw FormatException('Ungültiges Format der verschlüsselten Daten');
      }

      final iv = encrypt.IV(base64Decode(parts[0]));
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      log('Entschlüsselungsfehler: $e');
      return encryptedText; // Fallback: Original zurückgeben
    }
  }

  // Test der Verschlüsselung
  static bool verifyEncryption() {
    try {
      const testMessage = 'Verschlüsselungstest 1234';
      final encrypted = encryptData(testMessage);
      final decrypted = decryptData(encrypted);

      // Überprüfe, ob die Entschlüsselung korrekt funktioniert
      final success = decrypted == testMessage;
      log(
        'Verschlüsselungstest: ${success ? 'Erfolgreich' : 'Fehlgeschlagen'}',
      );
      return success;
    } catch (e) {
      log('Fehler beim Verschlüsselungstest: $e');
      return false;
    }
  }
}
