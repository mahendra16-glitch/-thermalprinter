import '../models/printer_device.dart';
import 'bluetooth_printer_adapter.dart';
import 'usb_printer_adapter.dart';
import 'network_printer_adapter.dart';

abstract class PrinterAdapter {
  PrinterDevice get device;

  Future<bool> connect();
  Future<void> disconnect();
  Future<bool> isConnected();
  Future<void> sendRawBytes(List<int> bytes);

  factory PrinterAdapter.forDevice(PrinterDevice device) {
    switch (device.connectionType) {
      case ConnectionType.bluetooth:
        return BluetoothPrinterAdapter(device);
      case ConnectionType.usb:
        return UsbPrinterAdapter(device);
      case ConnectionType.network:
        return NetworkPrinterAdapter(device);
    }
  }
}
