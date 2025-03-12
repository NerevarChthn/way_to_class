import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class Toast {
  //Implementierung der Sogenannten Toasts -> Meldungen
  static void successToast(String desc) {
    toastification.show(
      title: Text('Erfolg!'),
      description: Text(desc),
      autoCloseDuration: const Duration(seconds: 5),
      type: ToastificationType.success,
      style: ToastificationStyle.minimal,
      showProgressBar: false,
      alignment: Alignment.bottomRight,
    );
  }

  static void errorToast(String desc) {
    toastification.show(
      title: Text('Fehler!'),
      description: Text(desc),
      autoCloseDuration: const Duration(seconds: 5),
      type: ToastificationType.error,
      style: ToastificationStyle.minimal,
      showProgressBar: false,
      alignment: Alignment.bottomRight,
    );
  }

  static void infoToast(String desc) {
    toastification.show(
      title: Text('Info!'),
      description: Text(desc),
      autoCloseDuration: const Duration(seconds: 5),
      type: ToastificationType.info,
      style: ToastificationStyle.minimal,
      showProgressBar: false,
      alignment: Alignment.bottomRight,
    );
  }
}
