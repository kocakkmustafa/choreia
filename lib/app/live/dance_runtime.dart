import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:motion_content/motion_content.dart' show computeSha256Hex;

import 'pose_model.dart';

enum DanceCapabilityStatus { calibrationRequired, unsupported, incompatible }

/// An app-local provider binding. An installed pose extractor is not an
/// independently validated dance assessor. Schema 1 cannot enable judgments.
final class DanceProviderBinding {
  const DanceProviderBinding(this.status, {this.diagnosticAngles = false});
  final DanceCapabilityStatus status;
  final bool diagnosticAngles;
  bool get stepIdentity => false;
  bool get beatTiming => false;
  bool get physicalSupport => false;
  bool get allowsScoring => false;
}

final class DanceRuntimeManifest {
  DanceRuntimeManifest._(this.version, this._tasks);
  static const path = 'content/dance_runtime.v1.json';
  static const protocol = 'choreia-cycle-v1';
  final String version;
  final Map<String, Map<String, dynamic>> _tasks;

  factory DanceRuntimeManifest.parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    if (json['schemaVersion'] != 1 ||
        json['providerProtocol'] != protocol ||
        json['version'] is! String ||
        !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(json['version'] as String) ||
        json['modelId'] != PoseModelPin.modelId ||
        json['modelSha256'] != PoseModelPin.sha256 ||
        json['calibration'] != null ||
        json['evaluation'] != null ||
        json['tasks'] is! List) {
      throw const FormatException('Incompatible dance runtime');
    }
    final tasks = <String, Map<String, dynamic>>{};
    for (final value in json['tasks'] as List) {
      final row = (value as Map).cast<String, dynamic>();
      final id = row['stepId'];
      if (id is! String ||
          id.isEmpty ||
          tasks.containsKey(id) ||
          row['status'] != 'calibrationRequired' ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch('${row['referenceSha256']}') ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch('${row['stepSha256']}')) {
        throw const FormatException('Invalid dance task');
      }
      tasks[id] = Map.unmodifiable(row);
    }
    if (tasks.isEmpty) throw const FormatException('Empty dance runtime');
    return DanceRuntimeManifest._(
        json['version'] as String, Map.unmodifiable(tasks));
  }

  DanceProviderBinding bind(
      {required String stepId,
      required Uint8List referenceBytes,
      required Uint8List stepBytes}) {
    final row = _tasks[stepId];
    if (row == null) {
      return const DanceProviderBinding(DanceCapabilityStatus.unsupported);
    }
    if (row['referenceSha256'] != computeSha256Hex(referenceBytes) ||
        row['stepSha256'] != computeSha256Hex(stepBytes)) {
      return const DanceProviderBinding(DanceCapabilityStatus.incompatible);
    }
    return const DanceProviderBinding(DanceCapabilityStatus.calibrationRequired,
        diagnosticAngles: true);
  }

  /// No network, remote activation, previous-version fallback or fixture
  /// provider. Failure preserves written lessons and closes live diagnostics.
  static Future<DanceProviderBinding> loadBinding(
      {required AssetBundle bundle,
      required String stepId,
      required String stepPath}) async {
    try {
      final manifest =
          DanceRuntimeManifest.parse(await bundle.loadString(path));
      if (!manifest._tasks.containsKey(stepId)) {
        return const DanceProviderBinding(DanceCapabilityStatus.unsupported);
      }
      final reference = await bundle.load('content/references/$stepId.json');
      final step = await bundle.load(stepPath);
      return manifest.bind(
          stepId: stepId,
          referenceBytes: reference.buffer
              .asUint8List(reference.offsetInBytes, reference.lengthInBytes),
          stepBytes:
              step.buffer.asUint8List(step.offsetInBytes, step.lengthInBytes));
    } on Object {
      return const DanceProviderBinding(DanceCapabilityStatus.incompatible);
    }
  }
}
