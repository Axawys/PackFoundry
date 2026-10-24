import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pack_foundry/core/services/flutter_locator.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pack_foundry_flutter_');
  });

  tearDown(() => root.delete(recursive: true));

  Future<File> fakeFlutter(String sdkFolder) async {
    final file = File('${root.path}/$sdkFolder/bin/flutter');
    await file.create(recursive: true);
    return file;
  }

  test('falls back to the managed SDK when flutter is not on PATH', () async {
    final managed = await fakeFlutter('data/pack_foundry/flutter');
    final locator = FlutterLocator(
      environment: {
        'PATH': '/usr/bin:/bin',
        'HOME': '${root.path}/home',
        'XDG_DATA_HOME': '${root.path}/data',
      },
    );

    expect(locator.find()?.path, managed.path);
  });

  test('prefers flutter from PATH over other installs', () async {
    final onPath = await fakeFlutter('custom');
    await fakeFlutter('home/development/flutter');
    await fakeFlutter('data/pack_foundry/flutter');
    final locator = FlutterLocator(
      environment: {
        'PATH': '/usr/bin:${onPath.parent.path}',
        'HOME': '${root.path}/home',
        'XDG_DATA_HOME': '${root.path}/data',
      },
    );

    expect(locator.find()?.path, onPath.path);
  });

  test('finds FLUTTER_ROOT and usual home folders', () async {
    final inHome = await fakeFlutter('home/development/flutter');
    final environment = {
      'PATH': '/usr/bin',
      'HOME': '${root.path}/home',
      'XDG_DATA_HOME': '${root.path}/data',
    };
    expect(FlutterLocator(environment: environment).find()?.path, inHome.path);

    final fromRoot = await fakeFlutter('sdk-root');
    expect(
      FlutterLocator(
        environment: {
          ...environment,
          'FLUTTER_ROOT': fromRoot.parent.parent.path,
        },
      ).find()?.path,
      fromRoot.path,
    );
  });

  test('returns null when no SDK exists', () {
    final locator = FlutterLocator(
      environment: {
        'PATH': '${root.path}/empty',
        'HOME': '${root.path}/home',
        'XDG_DATA_HOME': '${root.path}/data',
      },
    );

    expect(locator.find(), isNull);
  });

  test('puts the SDK bin folder first on PATH for child processes', () {
    final locator = FlutterLocator(environment: {'PATH': '/usr/bin:/bin'});

    expect(
      locator.environmentFor(File('/opt/flutter/bin/flutter'))['PATH'],
      '/opt/flutter/bin:/usr/bin:/bin',
    );
  });
}
