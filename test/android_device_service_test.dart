import 'package:flutter_test/flutter_test.dart';

import 'package:pack_foundry/core/services/android_device_service.dart';

void main() {
  test('parses attached devices with their model and state', () {
    final devices = parseAdbDevices('''
List of devices attached
R58M123ABC             device product:a52qnaeea model:SM_A525F device:a52q transport_id:2
emulator-5554          device product:sdk_gphone64_x86_64 model:sdk_gphone64_x86_64 transport_id:3
''');

    expect(devices.length, 2);
    expect(devices.first.serial, 'R58M123ABC');
    expect(devices.first.isAuthorized, isTrue);
    expect(devices.first.label, 'SM A525F (R58M123ABC)');
    expect(devices.last.serial, 'emulator-5554');
  });

  test('keeps devices that still wait for the USB debugging prompt', () {
    final devices = parseAdbDevices('''
* daemon not running; starting now at tcp:5037
* daemon started successfully
List of devices attached
R58M123ABC             unauthorized usb:1-3
''');

    expect(devices.length, 1);
    expect(devices.single.isAuthorized, isFalse);
    expect(devices.single.isUnauthorized, isTrue);
    // No model is reported before the handshake, so the serial has to carry it.
    expect(devices.single.label, 'R58M123ABC');
  });

  test('reports no devices for an empty adb table', () {
    expect(parseAdbDevices('List of devices attached\n\n'), isEmpty);
  });
}
