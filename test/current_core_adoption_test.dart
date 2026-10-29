import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const currentMotionSha = '5b15308ea2a89dd5adebe29635f8e7b18fff68e4';

bool hasLocalMotionOverrides([String? source]) {
  final file = File('pubspec_overrides.yaml');
  source ??= file.existsSync() ? file.readAsStringSync() : '';
  return RegExp(r'^  motion_[a-z_]+:', multiLine: true).hasMatch(source);
}

void verifyResolvedPublishedMotionGraph(
    Map<String, dynamic> config, Uri configUri, String lock) {
  final rows = (config['packages'] as List)
      .cast<Map<String, dynamic>>()
      .where((row) => (row['name'] as String).startsWith('motion_'))
      .toList();
  expect(rows, isNotEmpty);
  final first =
      Directory.fromUri(configUri.resolve(rows.first['rootUri'] as String));
  final root = first.parent.parent.resolveSymbolicLinksSync();
  final head = Process.runSync('git', ['-C', root, 'rev-parse', 'HEAD']);
  expect(head.exitCode, 0,
      reason: 'Selected Core must be an actual Git checkout');
  final clean = Process.runSync(
      'git', ['-C', root, 'diff', '--quiet', 'HEAD', '--', 'packages']);
  expect(clean.exitCode, 0,
      reason: 'Selected Core source must equal its commit');
  verifyPublishedMotionGraph(config, configUri, lock, root,
      actualCommit: (head.stdout as String).trim());
  for (final row in rows) {
    final name = row['name'] as String;
    final spec = File('$root/packages/$name/pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version: ([0-9.]+)$', multiLine: true)
        .firstMatch(spec)
        ?.group(1);
    expect(version, isNotNull);
    final block = RegExp('^  ${RegExp.escape(name)}:\\n(?:(?!^  \\S).)*',
            multiLine: true, dotAll: true)
        .firstMatch(lock)!
        .group(0)!;
    expect(block, contains('    version: "$version"'));
  }
}

void verifyPublishedMotionGraph(Map<String, dynamic> config, Uri configUri,
    String lock, String expectedRoot,
    {required String actualCommit}) {
  expect(actualCommit, currentMotionSha,
      reason: 'Actual checkout HEAD must equal the approved Core commit');
  final rows = (config['packages'] as List)
      .cast<Map<String, dynamic>>()
      .where((row) => (row['name'] as String).startsWith('motion_'))
      .toList();
  expect(rows, isNotEmpty);
  for (final row in rows) {
    final name = row['name'] as String;
    final actual =
        Directory.fromUri(configUri.resolve(row['rootUri'] as String))
            .absolute
            .path;
    final selected = Directory(actual);
    final canonical =
        selected.existsSync() ? selected.resolveSymbolicLinksSync() : actual;
    expect(canonical, '$expectedRoot/packages/$name');
    final block = RegExp('^  ${RegExp.escape(name)}:\\n(?:(?!^  \\S).)*',
            multiLine: true, dotAll: true)
        .firstMatch(lock)
        ?.group(0);
    expect(block, isNotNull, reason: '$name must have an actual lock entry');
    expect(block, contains('    source: git'));
    for (final field in ['ref', 'resolved-ref']) {
      expect(
          RegExp("""^      $field: (?:$currentMotionSha|"$currentMotionSha"|'$currentMotionSha')\$""",
                  multiLine: true)
              .allMatches(block!),
          hasLength(1));
    }
    expect(block, contains('      path: "packages/$name"'));
    expect(
        block,
        contains(
            '      url: "https://github.com/kocakkmustafa/motion-core.git"'));
  }
}

void verifyCurrentMotionGraph() {
  final file = File('.dart_tool/package_config.json').absolute;
  final config = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  if (hasLocalMotionOverrides()) {
    final expected =
        Directory('../motion-core').absolute.resolveSymbolicLinksSync();
    final source = File('pubspec_overrides.yaml').readAsStringSync();
    final rows = (config['packages'] as List)
        .cast<Map<String, dynamic>>()
        .where((row) => (row['name'] as String).startsWith('motion_'))
        .toList();
    expect(rows, isNotEmpty);
    for (final row in rows) {
      final name = row['name'] as String;
      expect(source, contains('  $name:\n    path: $expected/packages/$name'));
      final actual =
          Directory.fromUri(file.uri.resolve(row['rootUri'] as String))
              .resolveSymbolicLinksSync();
      expect(actual, '$expected/packages/$name');
    }
    return;
  }

  verifyResolvedPublishedMotionGraph(
      config, file.uri, File('pubspec.lock').readAsStringSync());
}

void main() {
  test(
      'all actual Motion package URIs resolve the current declared Core source',
      verifyCurrentMotionGraph);
  test('a real alternate cache alias keeps Git commit and source identity', () {
    final configFile = File('.dart_tool/package_config.json').absolute;
    final config =
        jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
    final rows = (config['packages'] as List).cast<Map<String, dynamic>>();
    final first =
        rows.firstWhere((row) => (row['name'] as String).startsWith('motion_'));
    final root =
        Directory.fromUri(configFile.uri.resolve(first['rootUri'] as String))
            .parent
            .parent
            .resolveSymbolicLinksSync();
    final temporary =
        Directory.systemTemp.createTempSync('motion-cache-alias-');
    try {
      final alias = Link('${temporary.path}/different-pub-cache-layout');
      alias.createSync(root);
      final alternate = <String, dynamic>{
        'packages': [
          for (final row in rows)
            <String, dynamic>{
              ...row,
              if ((row['name'] as String).startsWith('motion_'))
                'rootUri': Directory('${alias.path}/packages/${row['name']}')
                    .uri
                    .toString(),
            },
        ]
      };
      verifyResolvedPublishedMotionGraph(
          alternate, configFile.uri, File('pubspec.lock').readAsStringSync());
    } finally {
      temporary.deleteSync(recursive: true);
    }
  });
  test('header-only override is not local Core mode', () {
    expect(hasLocalMotionOverrides('dependency_overrides:\n'), isFalse);
    expect(
        hasLocalMotionOverrides(
            'dependency_overrides:\n  motion_core:\n    path: ../motion-core\n'),
        isTrue);
  });
  test('published graph rejects wrong resolved SHA, URI, and malformed lock',
      () {
    const root = '/fixture/git/motion-core-$currentMotionSha';
    final config = <String, dynamic>{
      'packages': [
        {'name': 'motion_core', 'rootUri': '$root/packages/motion_core'}
      ]
    };
    const lock = '  motion_core:\n    description:\n'
        '      path: "packages/motion_core"\n'
        '      ref: "$currentMotionSha"\n'
        '      resolved-ref: "$currentMotionSha"\n'
        '      url: "https://github.com/kocakkmustafa/motion-core.git"\n'
        '    source: git\n    version: "0.12.0"\n';
    final uri = Uri.file('/fixture/.dart_tool/package_config.json');
    verifyPublishedMotionGraph(config, uri, lock, root,
        actualCommit: currentMotionSha);
    const alternateRoot = '/other/custom/cache/repository-checkout';
    final alternate = <String, dynamic>{
      'packages': [
        {
          'name': 'motion_core',
          'rootUri': '$alternateRoot/packages/motion_core'
        }
      ]
    };
    verifyPublishedMotionGraph(alternate, uri, lock, alternateRoot,
        actualCommit: currentMotionSha);
    expect(
        () => verifyPublishedMotionGraph(config, uri, lock, root,
            actualCommit: '1' * 40),
        throwsA(isA<TestFailure>()));

    for (final bad in [
      lock.replaceFirst(
          'resolved-ref: "$currentMotionSha"', 'resolved-ref: "${'1' * 40}"'),
      'packages:\n'
    ]) {
      expect(
          () => verifyPublishedMotionGraph(config, uri, bad, root,
              actualCommit: currentMotionSha),
          throwsA(isA<TestFailure>()));
    }
    final wrong = <String, dynamic>{
      'packages': [
        {'name': 'motion_core', 'rootUri': '/fixture/local/motion_core'}
      ]
    };
    expect(
        () => verifyPublishedMotionGraph(wrong, uri, lock, root,
            actualCommit: currentMotionSha),
        throwsA(isA<TestFailure>()));
  });
}
