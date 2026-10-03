import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';

import 'support/core_source_preview_guard.dart';

Matcher failsWith(CoreSourcePreviewFailure failure) => throwsA(
      isA<CoreSourcePreviewException>().having(
        (CoreSourcePreviewException error) => error.failure,
        'failure',
        failure,
      ),
    );

void _copyTree(Directory source, Directory destination) {
  final ProcessResult copy = Process.runSync('cp', <String>[
    '-Rp',
    source.path,
    destination.path,
  ]);
  if (copy.exitCode != 0) {
    throw StateError('Controlled source fixture copy failed: ${copy.stderr}');
  }
}

class _PreviewFixture {
  _PreviewFixture(Directory candidate) {
    root = Directory.systemTemp.createTempSync('choreia-core-preview-');
    File('${candidate.path}/APPROVED-CORE-SOURCE.manifest.json')
        .copySync('${root.path}/APPROVED-CORE-SOURCE.manifest.json');
    core.createSync();
    final ProcessResult extract = Process.runSync('tar', <String>[
      '-xzf',
      '${candidate.path}/approved-source.tar.gz',
      '-C',
      core.path,
    ]);
    if (extract.exitCode != 0) {
      throw StateError('Pinned fixture extraction failed: ${extract.stderr}');
    }
    File('${candidate.path}/approved-source.tar.gz')
        .copySync('${root.path}/approved-source.tar.gz');
    Directory('${root.path}/app/packages/choreia_engine')
        .createSync(recursive: true);
    File('${candidate.path}/app/pubspec.yaml')
        .copySync('${root.path}/app/pubspec.yaml');
    File('${candidate.path}/app/packages/choreia_engine/pubspec.yaml')
        .copySync('${root.path}/app/packages/choreia_engine/pubspec.yaml');
    final List<Map<String, String>> motionPackages = <Map<String, String>>[];
    for (final FileSystemEntity package in Directory(
      '${core.path}/packages',
    ).listSync()) {
      if (package is! Directory) {
        continue;
      }
      final String pubspec =
          File('${package.path}/pubspec.yaml').readAsStringSync();
      final String name = RegExp(
        r'^name: (motion_[a-z_]+)$',
        multiLine: true,
      ).firstMatch(pubspec)!.group(1)!;
      motionPackages.add(<String, String>{
        'name': name,
        'rootUri': '../../core-source/packages/$name/',
        'packageUri': 'lib/',
        'languageVersion': '3.11',
      });
    }
    writeConfig('app', motionPackages);
    // The standalone engine's actual descriptor has no Motion dependency.
    writeConfig('app/packages/choreia_engine', <Map<String, String>>[]);
  }

  late final Directory root;
  Directory get core => Directory('${root.path}/core-source');

  void writeConfig(String consumer, List<Map<String, String>> packages) {
    final File config = File(
      '${root.path}/$consumer/.dart_tool/package_config.json',
    );
    config.parent.createSync(recursive: true);
    config.writeAsStringSync(
      jsonEncode(<String, Object>{'configVersion': 2, 'packages': packages}),
    );
  }

  List<Map<String, String>> appPackages() {
    final Map<String, dynamic> parsed = jsonDecode(
      File('${root.path}/app/.dart_tool/package_config.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    return (parsed['packages'] as List<dynamic>)
        .map(
          (dynamic row) =>
              Map<String, String>.from(row as Map<String, dynamic>),
        )
        .toList();
  }

  CoreSourcePreviewNotice verify() => verifyApprovedCoreSourcePreview(
        candidateRoot: root,
        approvedArchive: File('${root.path}/approved-source.tar.gz'),
      );

  void close() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}

void main() {
  // Historical immutable V4 guard remains a separate source identity contract.
  final Directory candidate = Directory('test/fixtures/core_source_preview_v4');
  final List<_PreviewFixture> fixtures = <_PreviewFixture>[];
  _PreviewFixture fixture() {
    final _PreviewFixture value = _PreviewFixture(candidate);
    fixtures.add(value);
    return value;
  }

  tearDown(() {
    for (final _PreviewFixture value in fixtures) {
      value.close();
    }
    fixtures.clear();
  });

  test(
    'approved complete source/config identity yields only a typed preview',
    () {
      final CoreSourcePreviewNotice notice = fixture().verify();
      expect(notice.status, 'SOURCE_PREVIEW_ONLY');
      expect(notice.publishedSha, isNull);
      expect(notice.sourceFileCount, 329);
      expect(notice.archiveSha256, approvedCoreSourceArchiveSha256);
      expect(notice.manifestSha256, approvedCoreSourceManifestSha256);
      expect(notice.patchSha256, approvedCoreSourcePatchSha256);
      expect(notice.motionPackagesByConfig['app']!['motion_core'], '0.12.0');
      expect(notice.motionPackagesByConfig['app']!['motion_camera'], '0.2.0');
      expect(notice.motionPackagesByConfig['app']!['motion_account'], '0.2.0');
      expect(
        notice.motionPackagesByConfig['app/packages/choreia_engine'],
        isEmpty,
      );
      expect(
        () => notice.motionPackagesByConfig['app']!['motion_core'] = '0.11.0',
        throwsUnsupportedError,
      );
    },
  );

  test(
    'mixed roots fail even when the external package has identical bytes',
    () {
      final _PreviewFixture value = fixture();
      final Directory outside = Directory('${value.root.path}/other-tree');
      _copyTree(Directory('${value.core.path}/packages/motion_core'), outside);
      final List<Map<String, String>> packages = value.appPackages();
      packages.singleWhere(
        (Map<String, String> row) => row['name'] == 'motion_core',
      )['rootUri'] = outside.uri.toString();
      value.writeConfig('app', packages);
      expect(
        value.verify,
        failsWith(CoreSourcePreviewFailure.mixedPackageRoot),
      );
    },
  );

  test(
    'one changed manifest byte cannot approve otherwise identical source',
    () {
      final _PreviewFixture value = fixture();
      File('${value.root.path}/APPROVED-CORE-SOURCE.manifest.json')
          .writeAsStringSync('\n', mode: FileMode.append);
      expect(
        value.verify,
        failsWith(CoreSourcePreviewFailure.manifestShaMismatch),
      );
    },
  );

  test('every actual consumer config is checked for mixed Motion roots', () {
    final _PreviewFixture value = fixture();
    final Directory outside = Directory('${value.root.path}/other-tree');
    _copyTree(Directory('${value.core.path}/packages/motion_core'), outside);
    value.writeConfig('app/third_party/video_player', <Map<String, String>>[
      <String, String>{
        'name': 'motion_core',
        'rootUri': outside.uri.toString(),
        'packageUri': 'lib/',
        'languageVersion': '3.11',
      },
    ]);
    expect(value.verify, failsWith(CoreSourcePreviewFailure.mixedPackageRoot));
  });

  for (final String hidden in <String>[
    'config-file',
    'config-directory',
    'consumer-directory',
  ]) {
    test('linked $hidden cannot hide an additional mixed-root consumer', () {
      final _PreviewFixture value = fixture();
      final Directory outside = Directory('${value.root.path}/other-tree');
      _copyTree(Directory('${value.core.path}/packages/motion_core'), outside);
      value.writeConfig('app/third_party/video_player', <Map<String, String>>[
        <String, String>{
          'name': 'motion_core',
          'rootUri': outside.uri.toString(),
          'packageUri': 'lib/',
          'languageVersion': '3.11',
        },
      ]);
      final File config = File(
        '${value.root.path}/app/third_party/video_player/.dart_tool/package_config.json',
      );
      if (hidden == 'config-file') {
        final File target = config.renameSync(
          '${value.root.path}/linked-package-config.json',
        );
        Link(config.path).createSync(target.path);
      } else if (hidden == 'config-directory') {
        final String original = config.parent.path;
        final Directory target = config.parent.renameSync(
          '${value.root.path}/linked-dart-tool',
        );
        Link(original).createSync(target.path);
      } else {
        final Directory consumer = config.parent.parent;
        final String original = consumer.path;
        final Directory target = consumer.renameSync(
          '${value.root.path}/linked-consumer',
        );
        Link(original).createSync(target.path);
      }
      expect(
        value.verify,
        failsWith(CoreSourcePreviewFailure.packageConfigUnavailable),
      );
    });
  }

  test('linked app root cannot substitute a borrowed consumer tree', () {
    final _PreviewFixture value = fixture();
    final Directory app = Directory('${value.root.path}/app');
    final Directory target = app.renameSync('${value.root.path}/borrowed-app');
    Link(app.path).createSync(target.path);
    expect(
      value.verify,
      failsWith(CoreSourcePreviewFailure.packageConfigUnavailable),
    );
  });

  test(
    'one changed source byte fails before package version can be trusted',
    () {
      final _PreviewFixture value = fixture();
      File('${value.core.path}/packages/motion_core/pubspec.yaml')
          .writeAsStringSync('\n', mode: FileMode.append);
      expect(
        value.verify,
        failsWith(CoreSourcePreviewFailure.sourceFileMismatch),
      );
    },
  );

  test('old 329-file v1 source is rejected by the approved v2 identity', () {
    final _PreviewFixture value = fixture();
    final File delta = File('${candidate.path}/old-source-delta.tar.gz');
    expect(
      sha256.convert(delta.readAsBytesSync()).toString(),
      '9f7cbd4465bd0db482e0dc5417c2ef9bfdbd32f54c12b9608477bb8c0a41971c',
    );
    final ProcessResult extract = Process.runSync('tar', <String>[
      '-xzf',
      delta.path,
      '-C',
      value.core.path,
    ]);
    expect(extract.exitCode, 0);
    final File oldManifest = File('${candidate.path}/old-source-manifest.json');
    expect(
      sha256.convert(oldManifest.readAsBytesSync()).toString(),
      '45118535009c9f95689c10ddf8418608255fe1a27eec6f9cc29026e3eb6f2cb6',
    );
    final List<dynamic> rows =
        jsonDecode(oldManifest.readAsStringSync()) as List<dynamic>;
    expect(
      value.core
          .listSync(recursive: true, followLinks: false)
          .whereType<File>(),
      hasLength(329),
      reason: 'The reconstructed fixture is the complete old 329-file source.',
    );
    for (final dynamic raw in rows) {
      final Map<String, dynamic> row = raw as Map<String, dynamic>;
      final File member = File('${value.core.path}/${row['path']}');
      expect(
        sha256.convert(member.readAsBytesSync()).toString(),
        row['sha256'],
      );
      expect((member.statSync().mode & 0x49) != 0, row['executable']);
    }
    expect(
      value.verify,
      failsWith(CoreSourcePreviewFailure.sourceFileMismatch),
    );
  });

  test(
    'source self-description without the approved external manifest fails',
    () {
      final _PreviewFixture value = fixture();
      final File manifest = File(
        '${value.root.path}/APPROVED-CORE-SOURCE.manifest.json',
      );
      manifest.renameSync(
        '${value.root.path}/self-declared-source.manifest.json',
      );
      expect(
        value.verify,
        failsWith(CoreSourcePreviewFailure.approvedManifestUnavailable),
      );
    },
  );

  test(
    'actual external archive bytes cannot be replaced by a declared hash',
    () {
      final _PreviewFixture value = fixture();
      final File archive = File('${value.root.path}/unapproved-source.tar.gz')
        ..writeAsStringSync(approvedCoreSourceArchiveSha256);
      expect(
        () => verifyApprovedCoreArchive(archive),
        failsWith(CoreSourcePreviewFailure.archiveShaMismatch),
      );
      expect(
        () => verifyApprovedCoreArchive(
          File('${value.root.path}/missing.tar.gz'),
        ),
        failsWith(CoreSourcePreviewFailure.archiveUnavailable),
      );
    },
  );

  test('extra source/config artifact cannot hide outside the 329-file manifest',
      () {
    final _PreviewFixture value = fixture();
    final File extra = File(
      '${value.core.path}/packages/motion_core/.dart_tool/package_config.json',
    );
    extra.parent.createSync(recursive: true);
    extra.writeAsStringSync('{}');
    expect(
      value.verify,
      failsWith(CoreSourcePreviewFailure.sourceTreeMismatch),
    );
  });

  test(
    'missing source member fails the complete 329-file membership check',
    () {
      final _PreviewFixture value = fixture();
      File('${value.core.path}/.gitignore').deleteSync();
      expect(
        value.verify,
        failsWith(CoreSourcePreviewFailure.sourceTreeMismatch),
      );
    },
  );

  test('source executable-bit drift fails even with identical file bytes', () {
    final _PreviewFixture value = fixture();
    final String path = '${value.core.path}/tools/consumer_matrix.sh';
    final ProcessResult chmod = Process.runSync('chmod', <String>['644', path]);
    expect(
      chmod.exitCode,
      0,
      reason: 'Only the controlled fixture mode changes.',
    );
    expect(
      value.verify,
      failsWith(CoreSourcePreviewFailure.sourceModeMismatch),
    );
  });

  test('symlink source member cannot borrow approved bytes from elsewhere', () {
    final _PreviewFixture value = fixture();
    final File member = File('${value.core.path}/.gitignore');
    final File elsewhere = member.copySync(
      '${value.root.path}/borrowed-gitignore',
    );
    member.deleteSync();
    Link(member.path).createSync(elsewhere.path);
    expect(
      value.verify,
      failsWith(CoreSourcePreviewFailure.sourceTreeMismatch),
    );
  });

  test(
    'Motion packageUri cannot redirect imports away from the verified lib',
    () {
      final _PreviewFixture value = fixture();
      final List<Map<String, String>> packages = value.appPackages();
      packages.first['packageUri'] = '../';
      value.writeConfig('app', packages);
      expect(
        value.verify,
        failsWith(CoreSourcePreviewFailure.packageConfigMismatch),
      );
    },
  );

  test(
    'missing declared Motion dependency fails instead of a vacuous config pass',
    () {
      final _PreviewFixture value = fixture();
      final List<Map<String, String>> packages = value.appPackages()
        ..removeWhere(
          (Map<String, String> row) => row['name'] == 'motion_camera',
        );
      value.writeConfig('app', packages);
      expect(
        value.verify,
        failsWith(CoreSourcePreviewFailure.packageConfigMismatch),
      );
    },
  );

  test('engine does not gain invented Motion packages in a source preview', () {
    final _PreviewFixture value = fixture();
    value.writeConfig('app/packages/choreia_engine', <Map<String, String>>[
      <String, String>{
        'name': 'motion_core',
        'rootUri': '../../../../core-source/packages/motion_core/',
        'packageUri': 'lib/',
        'languageVersion': '3.11',
      },
    ]);
    expect(
      value.verify,
      failsWith(CoreSourcePreviewFailure.packageConfigMismatch),
    );
  });

  test('missing consumer config fails rather than omitting its Motion check',
      () {
    final _PreviewFixture value = fixture();
    File(
      '${value.root.path}/app/packages/choreia_engine/.dart_tool/package_config.json',
    ).deleteSync();
    expect(
      value.verify,
      failsWith(CoreSourcePreviewFailure.packageConfigUnavailable),
    );
  });
}
