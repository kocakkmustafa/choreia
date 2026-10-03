import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const String approvedCoreSourceArchiveSha256 =
    'ff314571318d7e6026455b310c45ef10ccc3df3ae828434505f5043e8dcb02b5';
const String approvedCoreSourceManifestSha256 =
    '1408182ae6ee4c274a20d7af77aee174e1c47d2e38829580212bdd077a52a416';
const String approvedCoreSourcePatchSha256 =
    'ccdddad09a66e3be4d3dd11796add90f9c1f4c86977fa5cc2579de3e09472e0b';

enum CoreSourcePreviewFailure {
  approvedManifestUnavailable,
  manifestShaMismatch,
  manifestMetadataMismatch,
  archiveUnavailable,
  archiveShaMismatch,
  sourceTreeMismatch,
  sourceFileMismatch,
  sourceModeMismatch,
  packageConfigUnavailable,
  packageConfigMismatch,
  mixedPackageRoot,
  packageVersionMismatch,
}

class CoreSourcePreviewException implements Exception {
  const CoreSourcePreviewException(this.failure, this.detail);

  final CoreSourcePreviewFailure failure;
  final String detail;

  @override
  String toString() => 'CoreSourcePreviewException(${failure.name}): $detail';
}

/// Source preparation identity only. No published Git SHA or release acceptance.
class CoreSourcePreviewNotice {
  CoreSourcePreviewNotice(Map<String, Map<String, String>> packages)
      : motionPackagesByConfig = Map<String, Map<String, String>>.unmodifiable(
          packages.map(
            (String key, Map<String, String> value) =>
                MapEntry<String, Map<String, String>>(
              key,
              Map<String, String>.unmodifiable(value),
            ),
          ),
        );

  final String status = 'SOURCE_PREVIEW_ONLY';
  final String? publishedSha = null;
  final int sourceFileCount = 329;
  final String archiveSha256 = approvedCoreSourceArchiveSha256;
  final String manifestSha256 = approvedCoreSourceManifestSha256;
  final String patchSha256 = approvedCoreSourcePatchSha256;
  final Map<String, Map<String, String>> motionPackagesByConfig;
}

Never _reject(CoreSourcePreviewFailure failure, String detail) =>
    throw CoreSourcePreviewException(failure, detail);

String _digest(List<int> bytes) => sha256.convert(bytes).toString();

/// The external archive must itself have the literal, independently approved
/// digest. A manifest's self-declared digest never substitutes for these bytes.
void verifyApprovedCoreArchive(File archive) {
  if (FileSystemEntity.typeSync(archive.path, followLinks: false) !=
      FileSystemEntityType.file) {
    _reject(
      CoreSourcePreviewFailure.archiveUnavailable,
      'Approved external source archive is unavailable or is not a file.',
    );
  }
  if (_digest(archive.readAsBytesSync()) != approvedCoreSourceArchiveSha256) {
    _reject(
      CoreSourcePreviewFailure.archiveShaMismatch,
      'External source archive bytes do not match the approved identity.',
    );
  }
}

String _relative(Directory root, String path) {
  final String prefix = '${root.absolute.path}${Platform.pathSeparator}';
  if (!path.startsWith(prefix)) {
    _reject(
      CoreSourcePreviewFailure.sourceTreeMismatch,
      'Source entry escaped the candidate root.',
    );
  }
  return path.substring(prefix.length).replaceAll(Platform.pathSeparator, '/');
}

String _yamlScalar(File file, String key) {
  final RegExpMatch? match = RegExp(
    '^$key: ([^\\r\\n]+)\$',
    multiLine: true,
  ).firstMatch(file.readAsStringSync());
  if (match == null) {
    _reject(
      CoreSourcePreviewFailure.packageVersionMismatch,
      'Package pubspec is missing $key.',
    );
  }
  return match.group(1)!.trim();
}

/// Only this literal-approved tree may satisfy the explicit test-only preview.
/// [candidateRoot] relocates a controlled fixture, never the accepted identity.
CoreSourcePreviewNotice verifyApprovedCoreSourcePreview({
  Directory? candidateRoot,
  File? approvedArchive,
}) {
  final Directory root = (candidateRoot ?? Directory('..')).absolute;
  final File approvedManifest = File(
    '${root.path}/APPROVED-CORE-SOURCE.manifest.json',
  );
  if (FileSystemEntity.typeSync(approvedManifest.path, followLinks: false) !=
      FileSystemEntityType.file) {
    _reject(
      CoreSourcePreviewFailure.approvedManifestUnavailable,
      'The independently approved source manifest is required.',
    );
  }
  final List<int> manifestBytes = approvedManifest.readAsBytesSync();
  if (_digest(manifestBytes) != approvedCoreSourceManifestSha256) {
    _reject(
      CoreSourcePreviewFailure.manifestShaMismatch,
      'Source manifest bytes do not match the literal approved identity.',
    );
  }
  final Map<String, dynamic> manifest =
      jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>;
  final Map<String, dynamic> archive =
      manifest['archive'] as Map<String, dynamic>;
  final List<dynamic> files = manifest['allFiles'] as List<dynamic>;
  if (manifest['releaseSha'] != null ||
      manifest['sourcePatchSha256'] != approvedCoreSourcePatchSha256 ||
      archive['sha256'] != approvedCoreSourceArchiveSha256 ||
      manifest['sourceFileCount'] != 329 ||
      files.length != 329) {
    _reject(
      CoreSourcePreviewFailure.manifestMetadataMismatch,
      'Manifest must describe the approved unpublished 329-file source.',
    );
  }
  // Relocation changes only the archive location; literal digest and size
  // remain mandatory, including for repository-local historical fixtures.
  final File archiveFile = approvedArchive ?? File(archive['path'] as String);
  verifyApprovedCoreArchive(archiveFile);
  if (archiveFile.lengthSync() != archive['bytes']) {
    _reject(
      CoreSourcePreviewFailure.manifestMetadataMismatch,
      'Approved archive size differs from the source manifest.',
    );
  }

  final Directory source = Directory('${root.path}/core-source');
  if (FileSystemEntity.typeSync(source.path, followLinks: false) !=
      FileSystemEntityType.directory) {
    _reject(
      CoreSourcePreviewFailure.sourceTreeMismatch,
      'Candidate core-source must be a regular directory.',
    );
  }
  final Map<String, Map<String, dynamic>> expected =
      <String, Map<String, dynamic>>{};
  for (final dynamic raw in files) {
    final Map<String, dynamic> row = raw as Map<String, dynamic>;
    final String path = row['path'] as String;
    if (path.startsWith('/') ||
        path.split('/').any((String part) => part == '..' || part.isEmpty) ||
        expected.containsKey(path)) {
      _reject(
        CoreSourcePreviewFailure.manifestMetadataMismatch,
        'Manifest source paths must be unique relative paths.',
      );
    }
    expected[path] = row;
  }
  final Set<String> actual = <String>{};
  int actualBytes = 0;
  void visit(Directory directory) {
    for (final FileSystemEntity entry in directory.listSync(
      followLinks: false,
    )) {
      final String path = _relative(source, entry.absolute.path);
      if (entry is Directory) {
        visit(entry);
      } else if (entry is File) {
        actual.add(path);
        final Map<String, dynamic>? row = expected[path];
        if (row == null) {
          _reject(
            CoreSourcePreviewFailure.sourceTreeMismatch,
            'Unmanifested source file: $path',
          );
        }
        final List<int> bytes = entry.readAsBytesSync();
        actualBytes += bytes.length;
        if (bytes.length != row['bytes'] || _digest(bytes) != row['sha256']) {
          _reject(
            CoreSourcePreviewFailure.sourceFileMismatch,
            'Source byte identity differs: $path',
          );
        }
        final bool executable = (entry.statSync().mode & 0x49) != 0;
        if (executable != row['executable']) {
          _reject(
            CoreSourcePreviewFailure.sourceModeMismatch,
            'Source executable-bit identity differs: $path',
          );
        }
      } else {
        _reject(
          CoreSourcePreviewFailure.sourceTreeMismatch,
          'Source symlink or nonregular entry is forbidden: $path',
        );
      }
    }
  }

  visit(source);
  if (actual.length != expected.length ||
      !actual.containsAll(expected.keys) ||
      actualBytes != manifest['sourceBytes']) {
    _reject(
      CoreSourcePreviewFailure.sourceTreeMismatch,
      'Actual source membership must equal all 329 manifest files.',
    );
  }

  final Map<String, Directory> packageRoots = <String, Directory>{};
  final Map<String, String> versions = <String, String>{};
  for (final FileSystemEntity entry in Directory(
    '${source.path}/packages',
  ).listSync(followLinks: false)) {
    if (entry is! Directory) {
      continue;
    }
    final File pubspec = File('${entry.path}/pubspec.yaml');
    final String name = _yamlScalar(pubspec, 'name');
    if (!name.startsWith('motion_') || packageRoots.containsKey(name)) {
      _reject(
        CoreSourcePreviewFailure.packageConfigMismatch,
        'Source package names must be unique Motion package names.',
      );
    }
    packageRoots[name] = entry;
    versions[name] = _yamlScalar(pubspec, 'version');
  }

  final Map<String, Map<String, String>> packagesByConfig =
      <String, Map<String, String>>{};
  final Set<String> configRoots = <String>{
    '${root.path}/app',
    '${root.path}/app/packages/choreia_engine',
  };
  if (FileSystemEntity.typeSync('${root.path}/app', followLinks: false) !=
      FileSystemEntityType.directory) {
    _reject(
      CoreSourcePreviewFailure.packageConfigUnavailable,
      'The app consumer root must be a regular directory.',
    );
  }
  for (final FileSystemEntity entry in Directory(
    '${root.path}/app',
  ).listSync(recursive: true, followLinks: false)) {
    final bool configPath = entry.path.endsWith(
      '/.dart_tool/package_config.json',
    );
    // A directory link can conceal another consumer from this no-follow scan.
    // A linked config must not disappear merely because it is not a File.
    if (entry is Link &&
        (configPath ||
            entry.path.endsWith('/.dart_tool') ||
            FileSystemEntity.typeSync(entry.path) ==
                FileSystemEntityType.directory)) {
      _reject(
        CoreSourcePreviewFailure.packageConfigUnavailable,
        'A linked entry prevents complete consumer-config discovery.',
      );
    }
    if (configPath) {
      if (entry is! File) {
        _reject(
          CoreSourcePreviewFailure.packageConfigUnavailable,
          'Every discovered consumer config must be a regular file.',
        );
      }
      configRoots.add(entry.parent.parent.path);
    }
  }
  for (final String consumerPath in configRoots) {
    final Directory consumer = Directory(consumerPath);
    final File config = File('${consumer.path}/.dart_tool/package_config.json');
    if (FileSystemEntity.typeSync(config.path, followLinks: false) !=
        FileSystemEntityType.file) {
      _reject(
        CoreSourcePreviewFailure.packageConfigUnavailable,
        'Consumer package_config is required: ${_relative(root, consumer.path)}',
      );
    }
    final Map<String, dynamic> parsed =
        jsonDecode(config.readAsStringSync()) as Map<String, dynamic>;
    if (parsed['configVersion'] != 2) {
      _reject(
        CoreSourcePreviewFailure.packageConfigMismatch,
        'Unsupported package_config version.',
      );
    }
    final Map<String, String> used = <String, String>{};
    for (final dynamic raw in parsed['packages'] as List<dynamic>) {
      final Map<String, dynamic> row = raw as Map<String, dynamic>;
      final String name = row['name'] as String;
      if (!name.startsWith('motion_')) {
        continue;
      }
      final Directory? expectedRoot = packageRoots[name];
      if (expectedRoot == null ||
          used.containsKey(name) ||
          row['packageUri'] != 'lib/') {
        _reject(
          CoreSourcePreviewFailure.packageConfigMismatch,
          'Unknown, duplicate, or redirected Motion package: $name',
        );
      }
      final Uri resolved = config.absolute.uri.resolve(
        row['rootUri'] as String,
      );
      if (resolved.scheme != 'file' ||
          !Directory.fromUri(resolved).existsSync() ||
          Directory.fromUri(resolved).resolveSymbolicLinksSync() !=
              expectedRoot.resolveSymbolicLinksSync()) {
        _reject(
          CoreSourcePreviewFailure.mixedPackageRoot,
          'Motion package_config root must use this exact source tree: $name',
        );
      }
      final File usedPubspec = File(
        '${Directory.fromUri(resolved).path}/pubspec.yaml',
      );
      if (_yamlScalar(usedPubspec, 'name') != name ||
          _yamlScalar(usedPubspec, 'version') != versions[name]) {
        _reject(
          CoreSourcePreviewFailure.packageVersionMismatch,
          'Motion package pubspec version does not match the verified tree: $name',
        );
      }
      used[name] = versions[name]!;
    }
    packagesByConfig[_relative(root, consumer.path)] = used;
  }
  final Set<String> appDirectMotion =
      RegExp(r'^  (motion_[a-z_]+):', multiLine: true)
          .allMatches(File('${root.path}/app/pubspec.yaml').readAsStringSync())
          .map((RegExpMatch match) => match.group(1)!)
          .toSet();
  if (appDirectMotion.isEmpty ||
      !packagesByConfig['app']!.keys.toSet().containsAll(appDirectMotion)) {
    _reject(
      CoreSourcePreviewFailure.packageConfigMismatch,
      'App package_config must contain every declared Motion dependency.',
    );
  }
  if (packagesByConfig['app/packages/choreia_engine']!.isNotEmpty) {
    _reject(
      CoreSourcePreviewFailure.packageConfigMismatch,
      'The standalone engine has no Motion dependency.',
    );
  }
  return CoreSourcePreviewNotice(packagesByConfig);
}
