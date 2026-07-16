# Sharing the IEC 61131-3 ST Generator for DRAKON Editor

This document explains how to package the Structured Text (ST) code
generator, install it into another DRAKON Editor, and use it. It is
written so you can hand this file to another user together with the
generator.

## What it is

A code generator that turns DRAKON diagrams into IEC 61131-3
Structured Text (`.st` files) for PLC programming. It registers the
language **"IEC 61131-3 ST"** in DRAKON Editor and produces
`PROGRAM` / `FUNCTION` / `FUNCTION_BLOCK` declarations with proper
`VAR_INPUT` / `VAR_OUTPUT` / `VAR_IN_OUT` / `VAR` sections and
structured `IF` / `WHILE` / `EXIT` bodies. Because ST has no `GOTO`,
the generator uses the editor's structured ("no goto") solver and
reports an error if a diagram cannot be expressed as structured code.

## Files to share

| File | Purpose |
|------|---------|
| `generators/st.tcl` | The generator itself (required) |
| `docs/ST/README.md` | This document |
| `examples/ST/IntroSFC.drn` / `.st` | Example: SFC/GRAFCET as a scan-cycle sequencer (one BOOL per step) |
| `examples/ST/IntroSFC_Case.drn` / `.st` | Example: the same SFC as a silhouette (case/automaton) machine |

To package everything from the DRAKON Editor directory:

```sh
zip -r drakon-st-generator.zip generators/st.tcl docs/ST examples/ST
```

The examples are optional but recommended — they open in the editor
and show the diagram conventions in working form.

## Installation (for the recipient)

Requirements: DRAKON Editor 1.31 (or a compatible 1.x version) running
on Tcl/Tk 8.6. No other dependencies — the generator is a single Tcl
file.

1. Locate your DRAKON Editor installation directory (the folder that
   contains `drakon_editor.tcl` and a `generators/` subfolder).
2. Copy `st.tcl` into the `generators/` subfolder. Copy the `examples/ST`
   and `docs/ST` folders anywhere convenient (their location does not
   matter).
3. Restart DRAKON Editor. The editor loads every `.tcl` file in
   `generators/` at startup, so no registration step is needed.

### Verify the installation

- Open DRAKON Editor, create or open a file, then open
  **File → File properties...** The **Language** list should now contain
  `IEC 61131-3 ST`.
- Or open `examples/ST/IntroSFC.drn` and run **DRAKON → Generate code**
  (Ctrl+B). An `IntroSFC.st` file should appear next to the `.drn` file.
- Command line check:

  ```sh
  tclsh8.6 drakon_gen.tcl -in examples/ST/IntroSFC.drn
  ```

## Using the generator

Select `IEC 61131-3 ST` as the language in **File → File properties...**
Each diagram becomes one POU (program organization unit).

**Parameters icon** (the box to the right of the diagram header), one
declaration per line:

```
program                  <- or: function_block (fb); default is FUNCTION
returns DINT             <- return type; implies FUNCTION
in                       <- section switches: in / out / in_out / var
Speed : INT
out
Ready : BOOL
var
count : DINT := 0
delayTimer : TON
```

- `in` (VAR_INPUT) is the default section; initializers like
  `n : INT := 5` are allowed.
- Local variables are **not** inferred from the body — declare them
  under a `var` line, as ST requires typed declarations.
- A first line of `#comment` skips the diagram entirely.

**Action icons** hold plain ST statements — write the semicolons
yourself: `x := x + 1;`

**If icons** hold ST boolean expressions (no semicolon): `x > 3`

**Loop start icons** accept either form:

```
for i = 1 to 10          (optionally: for i = 10 to 2 by -2)
i := 1; i <= 10; i := i + 1
```

`foreach` is not supported and is rejected with a message.

**Choice (select/case) icons** work in both DRAKON modes: an expression
compared against case values with `=`, or the `Select` keyword with full
conditions in the cases.

**File description sections** `=== header ===` and `=== footer ===`
(File → File description...) are copied verbatim to the top and bottom
of the generated file.

### Limitations

- No `GOTO` in ST means heavily tangled diagrams cannot be generated;
  the error message names the offending diagram. Restructure it (the
  silhouette form usually helps).
- The state-machine ("state machine" marker) diagrams supported by some
  other generators are not implemented for ST.
- Generated `FUNCTION` POUs default to `: VOID` when no `returns` line
  is given; some IEC implementations require a real return type there.

## The examples

Both examples implement the same GRAFCET/SFC chart (a 12-step sequence
with an OR-branch, a three-track parallel AND-section, a stored action,
and a 15 s timed transition), translated in two idiomatic ways:

- **IntroSFC** — textbook SFC translation: one BOOL per step
  (`X1..X12`), transition flags computed first for simultaneous
  evolution, then step updates and output assignments. Call once per
  PLC scan.
- **IntroSFC_Case** — DRAKON silhouette (automaton) style: a single
  `step` variable dispatched through a Choice icon (an IF/ELSIF cascade
  in the generated ST — the structured equivalent of `CASE`), one
  silhouette branch per step, and a shared `Outputs` branch.

## Contributing it upstream

DRAKON Editor is public domain (except some bundled third-party
components), and `st.tcl` follows the same convention — recipients may
use and modify it freely. If you want every DRAKON Editor user to get
the generator out of the box, offer it to the upstream project:
https://drakon-editor.sourceforge.net/ (source repository linked from
the site). A generator submission is simply the `generators/st.tcl`
file plus, ideally, an example `.drn`.
