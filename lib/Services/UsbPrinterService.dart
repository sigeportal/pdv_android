import 'package:flutter/services.dart';

class UsbPrinterDevice {
  final int vendorId;
  final int productId;
  final String name;

  const UsbPrinterDevice({
    required this.vendorId,
    required this.productId,
    required this.name,
  });

  String get id => '$vendorId:$productId';

  factory UsbPrinterDevice.fromMap(Map<dynamic, dynamic> map) {
    final vendorId = map['vendorId'] as int;
    final productId = map['productId'] as int;
    final description = (map['name'] as String?)?.trim();

    return UsbPrinterDevice(
      vendorId: vendorId,
      productId: productId,
      name: description == null || description.isEmpty
          ? 'USB $vendorId:$productId'
          : description,
    );
  }
}

class UsbPrinterService {
  static const MethodChannel _channel =
      MethodChannel('com.portal.pdvlanchonetes/usb_printer');

  static Future<List<UsbPrinterDevice>> getDevices() async {
    final result =
        await _channel.invokeMethod<List<dynamic>>('getUsbDevices') ?? [];

    return result
        .map((device) => UsbPrinterDevice.fromMap(device as Map))
        .toList();
  }

  static Future<void> write({
    required int vendorId,
    required int productId,
    required List<int> bytes,
  }) async {
    await _channel.invokeMethod<void>('writeUsb', {
      'vendorId': vendorId,
      'productId': productId,
      'data': Uint8List.fromList(bytes),
    });
  }

  static Future<void> test({
    required int vendorId,
    required int productId,
  }) async {
    // Reset, centraliza, imprime uma linha de teste e avanca o papel.
    await write(
      vendorId: vendorId,
      productId: productId,
      bytes: [
        0x1B,
        0x40,
        0x1B,
        0x61,
        0x01,
        ...'TESTE IMPRESSORA USB\n\n\n'.codeUnits,
      ],
    );
  }
}
