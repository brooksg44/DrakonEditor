# Revision History

This repository tracks a fork of DRAKON Editor 1.31 with an added
IEC 61131-3 Structured Text (ST) code generator. Changes are listed
newest first, relative to the upstream 1.31 baseline.

## 2026-07-17 — Native CASE statements from Select icons (`a10b46f`)

- `generators/st.tcl`: the ST generator now emits real `CASE <expr> OF
  ... ELSE ... END_CASE;` blocks for Select/Case icons. Previously the
  generator registered the CASE callbacks but used the framework path
  that rewires Select icons into nested IF chains, so they never fired.
  It now uses the tree ("to") generation path, rewiring loop icons
  explicitly since that path skips them.
- `scripts/generators.tcl`: `merge_trees` (used by the tree path)
  learned to pass `loop` and `continue` nodes through, so diagrams with
  loops work alongside native CASE. Previously it errored on any loop.
- `examples/ST/LampControl.drn` / `.st`: new minimal Select/Case
  example — a PROGRAM that drives three lamp outputs from an INT
  `mode` input. The Select icon becomes `CASE mode OF`, each Case icon
  a value label, and the empty rightmost Case icon the `ELSE` branch.
- `examples/ST/IntroSFC_Case.st`: regenerated; the step dispatcher is
  now `CASE step OF` instead of an IF chain. Note that with the tree
  path, code after the branches merge (the Outputs section) is inlined
  into each case — semantically identical, but longer output.

## 2026-07-16 — Repository README (`4588d1e`)

- `README.md`: project overview and usage notes for the fork.

## 2026-07-16 — IEC 61131-3 Structured Text generator (`121c363`)

- `generators/st.tcl`: registers the "IEC 61131-3 ST" language.
  Generates PROGRAM / FUNCTION / FUNCTION_BLOCK POUs with
  VAR_INPUT / VAR_OUTPUT / VAR_IN_OUT / VAR sections and structured
  IF / WHILE / EXIT bodies (no GOTO; uses the no-goto solver).
  The formal parameters icon is parsed line by line: `program`,
  `function_block` (or `fb`), `returns <TYPE>`, section keywords
  (`in` / `out` / `in_out` / `var`), and `<name> : <TYPE>`
  declarations. Loop icons accept `for i = 1 to 10 [by 2]`.
  File-description sections `=== header ===` and `=== footer ===`
  are copied verbatim into the output.
- `examples/ST/IntroSFC.drn` / `.st`: scan-cycle sequencer translated
  from a GRAFCET chart (one BOOL per step).
- `examples/ST/IntroSFC_Case.drn` / `.st`: the same machine as a
  silhouette/case automaton dispatching on a `step` variable.
- `docs/ST/README.md`: install, usage, and sharing instructions.
- `drakon.command`: macOS launcher script.

## 2026-07-16 — DRAKON Editor 1.31 baseline (`8f9f918`)

- Unmodified upstream DRAKON Editor 1.31 sources
  (Tcl/Tk editor, bundled code generators, examples, and docs).
