/// App-owned v2l source identity. Matching these bytes does not authorize
/// release media or a learner-skill verdict.
abstract final class ChoreiaSourceProjectionPin {
  static const appId = 'choreia';
  static const coursePath = 'content/salsa_on1_course.json';
  static const slicePath =
      'content/motion_content/choreia.source-slice.v1.json';
  static const projectionPath =
      'content/motion_content/choreia.source-projection.v1.json';

  static const courseSha256 =
      'b96ba7c9e83c84c229500f2e896dd3641d55833aa53843e94a6f9f90f92d4ca7';
  static const sliceSha256 =
      '7218bdf4f109844ee4c79367e3ae105c0530ac388a1732574c0d7d26b0c9d7a3';
  static const projectionSha256 =
      'b9c731a1801ae46a27bdfdc97cbc96eeeb0f2dc291e01e81ea64d86c29765a15';
  static const sourceCatalogSha256 =
      '791bfea8e1479307794bcf8799cf703a7a840bcd3058c1a0d7fdf065d32d8594';
  // Preproduction source manifest, not an independently approved release root.
  static const sourceManifestSha256 =
      'd887683c9a9b9bdb8d4ab7c51cdc5a5b4b4de6a918079e4cfd9cf543e9751e60';

  static const lessonCount = 48;
  static const sceneCount = 436;
  static const variantCount = 872;
  static const heldCount = 0;
}
