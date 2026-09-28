import 'dart:convert';

import 'package:choreia/app/course/salsa_course.dart';
import 'package:choreia/app/flutter_bundle_content_asset_reader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_content/motion_content.dart';

const String _manifestPath = 'content/motion_content/manifest.json';
const String _coursePath = 'content/salsa_on1_course.json';
// Current reviewed working-tree asset; an authored change requires a repin.
const int _courseByteLength = 361125;
const String _courseSha256 =
    'bceece2f4264963578e0414985a34c55a45103b286c2b87e12bece711e693a83';

final class _ManifestOverlayBundle extends CachingAssetBundle {
  _ManifestOverlayBundle(this.manifestBytes);

  final Uint8List manifestBytes;
  final List<String> requestedPaths = <String>[];

  @override
  Future<ByteData> load(String key) {
    requestedPaths.add(key);
    if (key == _manifestPath) {
      return Future<ByteData>.value(
        ByteData.view(
          manifestBytes.buffer,
          manifestBytes.offsetInBytes,
          manifestBytes.lengthInBytes,
        ),
      );
    }
    return rootBundle.load(key);
  }
}

Uint8List _manifestBytes({String? assetPath, String? assetSha256}) {
  final Map<String, Object?> manifest = <String, Object?>{
    'schemaVersion': 1,
    'contentVersion': '1.0.0',
    'appId': 'com.yulalab.choreia',
    'minimumCoreContract': '1.0.0',
    'locales': <String>['tr', 'en'],
    'courses': <Object?>[
      <String, Object?>{
        'id': 'salsa-bridge-test',
        'order': 0,
        'visibility': 'free',
        'title': <String, String>{'tr': 'Salsa', 'en': 'Salsa'},
        'description': <String, String>{
          'tr': 'Paket doğrulama testi',
          'en': 'Bundle verification test',
        },
        'lessonIds': <String>['salsa-asset-test'],
      },
    ],
    'lessons': <Object?>[
      <String, Object?>{
        'id': 'salsa-asset-test',
        'type': 'practice',
        'title': <String, String>{'tr': 'Ders', 'en': 'Lesson'},
        'description': <String, String>{'tr': 'Test', 'en': 'Test'},
        'instruction': <String, String>{'tr': 'Oku', 'en': 'Read'},
        'accessibilityLabel': <String, String>{
          'tr': 'Dersi aç',
          'en': 'Open lesson',
        },
        'modelIds': <String>[],
        'assetIds': <String>['salsa-asset'],
      },
    ],
    'models': <Object?>[],
    'assets': <Object?>[
      <String, Object?>{
        'id': 'salsa-asset',
        'path': assetPath ?? _coursePath,
        'byteLength': _courseByteLength,
        'sha256': assetSha256 ?? _courseSha256,
      },
    ],
  };
  manifest['catalogDigest'] = computeCatalogDigest(manifest);
  return Uint8List.fromList(utf8.encode(jsonEncode(manifest)));
}

ContentBundleLoader _loader(_ManifestOverlayBundle bundle) =>
    ContentBundleLoader(
      reader: FlutterBundleContentAssetReader(bundle: bundle),
      expectedAppId: 'com.yulalab.choreia',
      currentCoreContract: SemanticVersion.parse('1.0.0'),
      manifestPath: _manifestPath,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads pinned Salsa bytes and parses the active course', () async {
    final _ManifestOverlayBundle bundle =
        _ManifestOverlayBundle(_manifestBytes());
    final ContentLoadResult result = await _loader(bundle).load();

    expect(result, isA<ContentReady>());
    final ContentReady ready = result as ContentReady;
    expect(ready.catalog.manifest.assets.single.path, _coursePath);
    expect(bundle.requestedPaths, <String>[_manifestPath, _coursePath]);

    final Uint8List bytes = await ready.assets.read(_coursePath);
    expect(bytes.length, _courseByteLength);
    expect(computeSha256Hex(bytes), _courseSha256);
    final SalsaCourse course = SalsaCourse.fromJson(
      (jsonDecode(utf8.decode(bytes)) as Map).cast<String, dynamic>(),
    );
    expect(course.id, 'salsa_on1_solo');
    expect(course.modules, hasLength(8));
    expect(course.lessons, hasLength(48));
    expect(bundle.requestedPaths.last, _coursePath);
  });

  test('wrong pinned hash blocks course before exposure', () async {
    final _ManifestOverlayBundle bundle = _ManifestOverlayBundle(
      _manifestBytes(assetSha256: List<String>.filled(64, '0').join()),
    );
    final ContentLoadResult result = await _loader(bundle).load();

    expect(result, isA<ContentBlocked>());
    expect(
      (result as ContentBlocked).error.code,
      ContentErrorCode.hashMismatch,
    );
  });

  test('unsafe manifest path blocks without a course bundle read', () async {
    final _ManifestOverlayBundle bundle = _ManifestOverlayBundle(
      _manifestBytes(assetPath: 'content/../private.json'),
    );
    final ContentLoadResult result = await _loader(bundle).load();

    expect(result, isA<ContentBlocked>());
    expect(
      (result as ContentBlocked).error.code,
      ContentErrorCode.unsafePath,
    );
    expect(bundle.requestedPaths, <String>[_manifestPath]);
  });

  test('direct reader rejects unsafe path before Flutter lookup', () async {
    final _ManifestOverlayBundle bundle =
        _ManifestOverlayBundle(_manifestBytes());
    final FlutterBundleContentAssetReader reader =
        FlutterBundleContentAssetReader(bundle: bundle);

    await expectLater(
      reader.read('../private.json'),
      throwsA(
        isA<ContentException>().having(
          (ContentException error) => error.error.code,
          'code',
          ContentErrorCode.unsafePath,
        ),
      ),
    );
    expect(bundle.requestedPaths, isEmpty);
  });
}
