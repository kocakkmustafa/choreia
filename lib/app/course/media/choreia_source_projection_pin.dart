/// App-owned authored revision using the v2l wire format. Matching these bytes does not authorize
/// release media or a learner-skill verdict.
abstract final class ChoreiaSourceProjectionPin {
  static const appId = 'choreia';
  static const coursePath = 'content/salsa_on1_course.json';
  static const slicePath =
      'content/motion_content/choreia.source-slice.v1.json';
  static const projectionPath =
      'content/motion_content/choreia.source-projection.v1.json';

  static const courseSha256 =
      'd04ef4c413c6db0ca8858c1cf11d231cd9614adecff71aa41cc752481007cbfc';
  static const sliceSha256 =
      '7c62bacdfee106acc06dba4a950ecf6b23f5a0d0ea976f56ec309ea15bc077fb';
  static const projectionSha256 =
      'af0e7bb0a865914722774e7b806e2236e963dcdd2cda1ddf3e6664eac556a69c';
  static const sourceCatalogSha256 =
      'a6072c7e16edf43c812b508a8904ae0bf4cd0ce70842b0affc51e7514f751982';
  // Preproduction source manifest, not an independently approved release root.
  static const sourceManifestSha256 =
      'c98bde343ed0529d0717ca70b56cae529e0fbededecdbaf4ef6934230c324b64';

  static const lessonCount = 48;
  static const sceneCount = 436;
  static const variantCount = 872;
  static const heldCount = 0;
}
