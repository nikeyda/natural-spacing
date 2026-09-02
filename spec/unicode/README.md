# Unicode data workflow

Rules v1 is pinned to Unicode 17.0.0. `17.0.0/sources.json` records the official source URLs, byte counts, and SHA-256 digests. The full upstream data set is intentionally not vendored.

`17.0.0/GraphemeBreakTest.txt` is the narrow exception: the official conformance data is tracked so segmentation tests can run offline. Its pinned size and SHA-256 are checked before its cases are used. Unicode's license is retained in `../LICENSE.txt`.

`17.0.0/classification-ranges.json` is a generated, language-neutral artifact containing the exact Latin, Han, mark, and whitespace ranges used by the rules v1 classifier.

`17.0.0/grapheme-segmentation.json` is the language-neutral Unicode 17 segmentation artifact. It contains the category ranges, pair masks, and Indic linker set derived from `unicode-segmenter` 0.17.3 under its MIT license. The Kotlin core renders this artifact into native source and validates the result against all 766 pinned official cases.

## Reproduce the generated artifacts

Place `Scripts.txt`, `ScriptExtensions.txt`, `PropList.txt`, and `UnicodeData.txt` from Unicode 17.0.0 in one local directory. The generator rejects files that do not match the pinned byte counts and hashes.

```sh
npm run unicode:generate -- /path/to/ucd-17
npm run unicode:check -- /path/to/ucd-17
npm run grapheme:generate
npm run grapheme:check
```

The first command rewrites the language-neutral artifact and the TypeScript, Swift, Kotlin, C#, and Dart tables. The second recomputes them without writing and fails if any tracked file is stale.

Normal repository validation does not require downloaded UCD files:

```sh
npm run validate:unicode
```

This checks that every native table is an exact rendering of the tracked language-neutral artifact. `npm run validate` also validates the artifact's shape, scalar bounds, ordering, disjointness, and maximal compression.

The grapheme generator requires the exact `unicode-segmenter` version pinned in the workspace lockfile. Its `--check` mode reconstructs the language-neutral data from that package and rejects stale artifacts; normal validation verifies the checked-in artifact and every generated native table without downloading Unicode data.

## Unicode upgrade checklist

1. Pin the new official UCD and emoji source URLs, byte counts, and SHA-256 digests.
2. Update the specification's Unicode version and review whether property definitions changed.
3. Update the generator version and regenerate the language-neutral artifact.
4. Upgrade or regenerate extended-grapheme segmentation for the same Unicode version.
5. Add fixtures for changed or newly assigned scalars at relevant boundaries.
6. Regenerate every language-specific table and run all conformance suites.
7. Update the compatibility matrix; do not claim platform support from core tests alone.
