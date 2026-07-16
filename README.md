# DRAKON Editor + IEC 61131-3 Structured Text Generator

[DRAKON Editor](https://drakon-editor.sourceforge.net/) 1.31 — a free
visual editor for DRAKON flowcharts — extended with a code generator for
**IEC 61131-3 Structured Text (ST)**, the textual language of PLC
programming.

Draw the logic as a DRAKON diagram, pick `IEC 61131-3 ST` as the file
language, and generate `PROGRAM` / `FUNCTION` / `FUNCTION_BLOCK` POUs
with proper `VAR_INPUT` / `VAR_OUTPUT` / `VAR_IN_OUT` / `VAR` sections
and structured `IF` / `WHILE` / `EXIT` bodies — no `GOTO`, as ST
requires.

## The ST generator

| Where | What |
|-------|------|
| [`generators/st.tcl`](generators/st.tcl) | The generator (a single Tcl file) |
| [`docs/ST/README.md`](docs/ST/README.md) | Installation, usage conventions, limitations, and how to share it |
| [`examples/ST/`](examples/ST) | Two working examples with their generated `.st` output |

The examples implement the same GRAFCET/SFC chart (12 steps, an
OR-branch, a three-track parallel AND-section, a stored action, and a
15 s timed transition) in two idiomatic ways:

- **`IntroSFC.drn`** — textbook SFC translation: one BOOL per step,
  transition flags evaluated first, then step updates and output
  assignments; call once per PLC scan.
- **`IntroSFC_Case.drn`** — DRAKON silhouette (automaton) style: a
  single `step` variable dispatched through a Choice icon, one branch
  per step.

### Quick start

```sh
# GUI: File -> File properties... -> Language: IEC 61131-3 ST,
# then DRAKON -> Generate code (Ctrl+B).

# Command line:
tclsh8.6 drakon_gen.tcl -in examples/ST/IntroSFC.drn
```

Only the ST generator needs sharing to use it in another DRAKON Editor
installation — copy `generators/st.tcl` into that installation's
`generators/` folder and restart. Details in
[`docs/ST/README.md`](docs/ST/README.md).

## Running DRAKON Editor

DRAKON Editor needs Tcl/Tk 8.6 with the tcllib (`snit`), `sqlite3`, and
`Img` packages:

```sh
wish8.6 drakon_editor.tcl
```

See [`readme.html`](readme.html) for the upstream documentation,
supported target languages, and version history. On macOS, `Img` is not
packaged by Homebrew/conda — build [tkimg](https://sourceforge.net/projects/tkimg/)
from source against your Tcl/Tk, or use the included `drakon.command`
launcher as a starting point.

## License

DRAKON Editor is **public domain** (except some bundled third-party
components: pdf4tcl, Liberation fonts). The ST generator and examples
follow the same convention — use and modify them freely.

Upstream authors: Stepan Mitkin, Alexander Ilyin, Maas-Maarten Zeeman,
Vasil Dyadov, Vasili Bachiashvili.
