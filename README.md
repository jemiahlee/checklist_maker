# checklist_maker

Build printable two-column checklist pages from a CSV file.

- `checklist.cls` is a LaTeX document class that lays out two balanced columns: shaded section headings, checkbox items with dot leaders and bold responses, italic notes, and a running header and footer.
- `make_checklist.pl` is a Perl script that converts a CSV file into a `.tex` document that uses the class.

## Requirements

- Perl 5 (core modules only)
- A TeX distribution with `pdflatex`. The class uses `geometry`, `multicol`, `amssymb`, `xcolor`, `fancyhdr`, `needspace` and `etoolbox`, all of which ship with TeX Live and MacTeX.

## Quick start

```sh
./make_checklist.pl -o example.tex example.csv
pdflatex example.tex
```

`checklist.cls` must be in the same directory as the `.tex` file (or on your TeX search path) when you run `pdflatex`.

## Input format

Three columns: `type,text,response`. The header row is optional.

| type | text | response |
|---|---|---|
| `title` | document title | |
| `subtitle` | shown at the right of the page header | |
| `revision` | shown in the page footer | |
| `section` | shaded section heading | |
| `item` (or blank) | challenge | response; may be empty for a plain checkbox |
| `note` | indented italic note | |
| `colbreak` | | starts a new column |
| `pagebreak` | | starts a new page |

```csv
type,text,response
title,Cessna 172 Checklist,
subtitle,Normal procedures,
revision,"Rev 1, 2026-11-03",
section,Preflight - Cabin,
item,Master switch,ON
item,"Seats, belts, shoulder harnesses",ADJUST & LOCK
note,Verify fuel on both tanks.,
colbreak,,
```

Rules:

- Fields that contain commas, quotes or newlines must be double-quoted, with `""` for a literal quote.
- Short rows are fine: missing trailing columns are treated as empty.
- Blank rows are ignored, and so are rows whose type starts with `#`.
- Text is escaped for LaTeX, so `& % $ # _` are safe. The flip side is that you can't embed raw LaTeX.
- A bad row stops the script with its line number: an unknown type, an `item` with no text, or an unterminated quote.

## Script options

```
make_checklist.pl [options] [input.csv]

  -o, --output FILE   write to FILE instead of stdout
  --landscape         landscape pages
  --a4                A4 paper (default is US letter)
  -h, --help          show this help
```

With no input file, the script reads standard input.

## Using the class directly

You can skip the script and write LaTeX by hand:

```latex
\documentclass[letterpaper]{checklist}   % also: a4paper, landscape

\title{My Checklist}
\checklistsubtitle{Normal procedures}
\checklistrevision{Rev 1}

\begin{document}
\begin{checklist}
\checksection{Before Start}
\checkitem{Master switch}{ON}
\checkitem{Visually inspect control surfaces}{}
\checknote{Check for ice.}
\checkcolumnbreak
\checkpagebreak
\end{checklist}
\end{document}
```

## Files

| File | Purpose |
|---|---|
| `checklist.cls` | LaTeX class |
| `make_checklist.pl` | CSV to `.tex` converter |
| `example.csv` | sample input |
| `example.tex` | the generated output for the sample |
