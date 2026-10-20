/// App-local text-revision byte evidence using the v2l wire format.
/// Historical opaque refs remain unresolved in the separate evidence record.
/// No media, expert/physical/model approval or learner-skill verdict follows.
abstract final class ChoreiaSourceProjectionPin {
  static const appId = 'choreia';
  static const coursePath = 'content/salsa_on1_course.json';
  static const slicePath =
      'content/motion_content/choreia.source-slice.v1.json';
  static const projectionPath =
      'content/motion_content/choreia.source-projection.v1.json';

  static const courseSha256 =
      '284d429656ec8ca56fd10674685cf61069d157a6ee985eb764818ae9db11907d';
  static const sliceSha256 =
      'a0b73771ef94639988c83ced2621338ccc12b75204e876216bf71f4a2e0c698d';
  static const projectionSha256 =
      '7f41392feb363e27902d6061e4ba99c58ef10823e6f4e35e0b0f17f5639046b3';
  static const sourceCatalogSha256 =
      '6a1a1ebf201b05e72562b447373a907639896e2327d1d2c1eef9f8c6c44fc54f';
  // Preproduction source manifest, not an independently approved release root.
  static const sourceManifestSha256 =
      'ef6eaa2ba38d0b3abdc7300e6bbf7af419ec9484c1fbd7dca8de174ddadb0adc';

  static const lessonCount = 48;
  static const sceneCount = 436;
  static const variantCount = 872;
  static const heldCount = 0;
}
