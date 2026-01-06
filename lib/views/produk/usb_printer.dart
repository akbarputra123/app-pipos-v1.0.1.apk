import 'package:flutter/services.dart';

class UsbPrinter {
  static const MethodChannel _channel = MethodChannel('usb_printer');

  static Future<bool> requestUsbPermission() async {
    return await _channel.invokeMethod('requestUsbPermission');
  }

  static Future<List<String>> getUsbDevices() async {
    final List list = await _channel.invokeMethod('getUsbDevices');
    return list.cast<String>();
  }

  static Future<bool> printBarcodeWithName({
    required String name,
    required String barcode,
    required String deviceName,
  }) async {
    return await _channel.invokeMethod(
      'printBarcodeWithName',
      {
        'name': name,
        'barcode': barcode,
        'deviceName': deviceName,
      },
    );
  }

  static Future<bool> printReceipt({
  required String text,
  required String deviceName,
}) async {
  return await _channel.invokeMethod(
    'printReceipt',
    {
      'text': text,
      'deviceName': deviceName,
    },
  );
}

}
