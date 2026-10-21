# Localization source checks

Run these commands from the Choreia `app/` directory. They need only Python's
standard library; no Flutter/Dart SDK, network, workspace seed or Git HEAD is
used. Run after all translation/source writers have finished.

```sh
python3 -B tool/l10n/validate_catalogs.py
python3 -B tool/l10n/generate_bases.py
python3 -B tool/l10n/ui_inventory.py
```

The validator exits **0** for PASS or **1** for FAIL and prints JSON. It checks:

- All fourteen locale files: EN, TR, es-419, pt-BR, DE, FR, JA, AR, IT, KO, ID, PL, HI and zh-Hans.
- Course/index: one key per unique English course-source text (1121 after the
  2026-10-21 Line Dance/Latin/short-form extension), unique IDs, `course.` + the first 16 hex characters
  of SHA-256 of the exact UTF-8 English source, and English/index identity.
- UI: the English asset defines the current key set; no fixed UI count.
- Catalog: 430 keys. Every asset must contain nonempty string keys/values;
  locale key sets, placeholder occurrence counts and ASCII URI tokens must
  match English. English UI/catalog values must equal their source keys.
- Bound English literals found by `ui_inventory.inventory()` must appear in
  the UI/course/catalog union or the explicitly listed Progress source keys.
- Generated EN/TR UI and TR catalog Dart map **values** must match JSON. The
  restricted generated-map reader tolerates Dart formatting and escaped `$`;
  it does not execute Dart. Canonical formatting differences are informational.

The 35 explicit Progress source keys are inventory coverage exceptions, not a
validation of the hand-authored Progress locale maps. Maintain that list when
Progress copy changes and run the separate Dart parity/widget tests. The source
inventory supports known literal patterns only; it does not infer dynamic or
unbound text. URI matching follows ASCII RFC 3986 characters, not Unicode IRIs.

Inventory commands write **nothing by default**. To print all rows or save to
an explicitly chosen file:

```sh
python3 -B tool/l10n/ui_inventory.py --json
python3 -B tool/l10n/ui_inventory.py --output /tmp/choreia-ui-inventory.json
```

The `inventory()` import API remains read-only. No dated workspace output path
is built into the tool. Explicit `--output` creates its parent directory if
needed and replaces that named destination, so choose a new path when preserving
an earlier inventory.

The base helper also writes no files. It can emit deterministic Dart source to
stdout for review:

```sh
python3 -B tool/l10n/generate_bases.py --emit ui
python3 -B tool/l10n/generate_bases.py --emit catalog
```

Both the validator and base helper accept `--app-dir PATH` for synthetic local
fixtures or a caller-selected checkout. They never consult `workspace/` or Git.

**A source/asset PASS does not establish** Flutter compilation, widget layout,
physical-device behavior, font shaping, RTL or screen-reader behavior,
native-speaker translation quality, cultural review or physical-instruction
acceptance. Those remain separate acceptance work.
