# System Pipeline Flowchart - LaTeX Files

This directory contains **three professional flowchart versions** in LaTeX/TikZ format, ready to include in your research paper.

## 📊 Available Versions

| File | Format | Best For | Dimensions |
|------|--------|----------|-----------|
| [system_pipeline_flowchart.tex](system_pipeline_flowchart.tex) | Two-column vertical | IEEE, ACM double-column papers | `figure*` (spans both columns) |
| [system_pipeline_flowchart_compact.tex](system_pipeline_flowchart_compact.tex) | Single-column vertical | Single-column papers, space-constrained layouts | `figure` (single column) |
| [system_pipeline_flowchart_horizontal.tex](system_pipeline_flowchart_horizontal.tex) | Horizontal landscape | Presentations, slides, wide-format papers | `figure*` (full width) |

---

## 🚀 Quick Start

### 1. Add Required Packages to Your Paper Preamble

```latex
\documentclass{IEEEtran}  % or your conference/journal class

\usepackage{tikz}
\usetikzlibrary{shapes.geometric, arrows.meta, positioning, fit, backgrounds}
\usepackage{graphicx}
```

### 2. Include the Flowchart in Your Document

**For two-column papers (IEEE, ACM):**
```latex
\section{Methodology}
Our pipeline consists of seven phases as shown in Figure~\ref{fig:system_pipeline}.

\input{system_pipeline_flowchart}
```

**For single-column papers:**
```latex
\section{Methodology}
Our approach is illustrated in Figure~\ref{fig:pipeline_compact}.

\input{system_pipeline_flowchart_compact}
```

**For presentations/slides:**
```latex
\begin{frame}{System Pipeline}
\input{system_pipeline_flowchart_horizontal}
\end{frame}
```

### 3. Compile Your Paper

```bash
pdflatex your_paper.tex
```

---

## 📋 Detailed Comparison

### Version 1: Two-Column Vertical (Default)
**File:** [system_pipeline_flowchart.tex](system_pipeline_flowchart.tex)

**Features:**
- ✅ Spans both columns in two-column layouts
- ✅ Shows all 7 phases with detailed process flows
- ✅ Includes annotations for key decisions
- ✅ Background boxes for visual grouping
- ✅ Decision diamond with feedback loop
- ✅ Comprehensive metric annotations

**Use When:**
- Publishing in IEEE Transactions, ACM Conferences (double-column format)
- You have sufficient vertical space (full page)
- You want maximum detail and clarity

**Label:** `\label{fig:system_pipeline}`

---

### Version 2: Single-Column Compact
**File:** [system_pipeline_flowchart_compact.tex](system_pipeline_flowchart_compact.tex)

**Features:**
- ✅ Fits in a single column
- ✅ Streamlined vertical flow
- ✅ Essential information only
- ✅ Parallel execution annotation
- ✅ Smaller fonts for space efficiency
- ✅ Drop shadows for visual appeal

**Use When:**
- Space is limited (1-column width)
- Publishing in single-column journals
- You want a concise overview
- Supplementary material or appendix

**Label:** `\label{fig:pipeline_compact}`

---

### Version 3: Horizontal Landscape
**File:** [system_pipeline_flowchart_horizontal.tex](system_pipeline_flowchart_horizontal.tex)

**Features:**
- ✅ Left-to-right flow (natural reading order)
- ✅ All phases visible at once
- ✅ Includes legend for symbols
- ✅ Metrics box with target values
- ✅ Feedback loop clearly shown
- ✅ Ideal for presentations

**Use When:**
- Creating presentation slides
- Wide-format papers (landscape orientation)
- You want to emphasize sequential flow
- Poster presentations

**Label:** `\label{fig:pipeline_horizontal}`

---

## 🎨 Customization Guide

### Change Colors

```latex
% In the tikzpicture style definitions, modify:
phase/.style={fill=blue!20}     → fill=purple!20
process/.style={fill=orange!15} → fill=teal!15
data/.style={fill=green!15}     → fill=cyan!15
```

### Adjust Spacing

```latex
% Change node distance parameter:
node distance=0.8cm  → node distance=1.2cm  (more space)
node distance=0.5cm  → node distance=0.3cm  (less space)
```

### Modify Font Sizes

```latex
% In style definitions:
font=\small      → \footnotesize (smaller)
font=\scriptsize → \tiny         (smallest)
```

### Grayscale Version (for B&W printing)

Replace all color fills with grayscale:
```latex
fill=blue!20   → fill=black!10
fill=orange!15 → fill=black!15
fill=green!15  → fill=black!20
fill=yellow!20 → fill=black!5
```

### Add Border Thickness (optional)

```latex
% Increase border thickness in style definitions:
draw=black  → draw=black, line width=1pt
```

---

## 📐 Figure Placement Options

### LaTeX Placement Specifiers

```latex
\begin{figure*}[t]   % Top of page (recommended)
\begin{figure*}[h]   % Here (approximately)
\begin{figure*}[b]   % Bottom of page
\begin{figure*}[p]   % Separate page
\begin{figure*}[t!]  % Top (force placement)
\begin{figure*}[H]   % Exactly here (requires \usepackage{float})
```

**Recommendation:** Use `[t]` for top placement in academic papers.

---

## 🔧 Troubleshooting

### Issue 1: Figure Too Large

**Solution:**
```latex
% Add scaling to the figure:
\begin{tikzpicture}[scale=0.8, every node/.style={scale=0.8}]
```

### Issue 2: Text Overlapping in Nodes

**Solution:**
```latex
% Increase minimum width/height:
minimum width=4cm   % Increase from 3cm
minimum height=0.8cm % Increase from 0.6cm
```

### Issue 3: Compilation Errors

**Common causes:**
- Missing TikZ library: Add to preamble
- Syntax error in modifications: Check brackets
- Missing packages: Install `texlive-pictures`

**Solution:**
```bash
# Install required LaTeX packages (Ubuntu/Debian):
sudo apt-get install texlive-pictures texlive-latex-extra

# Or update LaTeX distribution:
sudo tlmgr update --self --all
```

### Issue 4: Figure Not Appearing

**Solution:**
```latex
% Check file path is correct:
\input{./system_pipeline_flowchart}  % Add ./ for current directory

% Or use absolute path:
\input{/path/to/system_pipeline_flowchart}
```

### Issue 5: Caption Too Long

**Solution:**
```latex
% Use short caption for list of figures:
\caption[Short caption]{Long detailed caption that explains everything...}
```

---

## 📊 Example Caption

```latex
\caption{System pipeline for evaluating energy-aware slow test optimization.
The pipeline consists of seven phases: (1) identifying GitHub projects with
slow test fixes, (2) downloading before/after PR versions, (3) applying
mocking strategies using Claude Code, (4) measuring energy consumption across
N=10 runs with Energibridge, (5) verifying test coverage preservation,
(6) statistical analysis with outlier filtering, and (7) multi-project
aggregation. Optimizations are accepted only if coverage loss is below 10\%.}
```

---

## 📚 Referencing in Text

```latex
% Reference the figure in your text:
As illustrated in Figure~\ref{fig:system_pipeline}, our pipeline...

% For multiple references:
Figures~\ref{fig:system_pipeline} and~\ref{fig:results} show...

% With page reference:
See Figure~\ref{fig:system_pipeline} on page~\pageref{fig:system_pipeline}.
```

---

## 🎯 Complete Example

See [flowchart_usage_guide.tex](flowchart_usage_guide.tex) for a full working example with:
- Complete paper structure
- Preamble setup
- Section organization
- Figure placement
- Bibliography examples
- Compilation instructions

---

## 📦 Files Included

1. **system_pipeline_flowchart.tex** - Two-column vertical version
2. **system_pipeline_flowchart_compact.tex** - Single-column compact version
3. **system_pipeline_flowchart_horizontal.tex** - Horizontal landscape version
4. **flowchart_usage_guide.tex** - Complete usage guide with examples
5. **FLOWCHART_README.md** - This file

---

## 🎓 Recommended for Different Venues

| Venue Type | Recommended Version | Placement |
|------------|-------------------|-----------|
| IEEE Transactions | Two-column vertical | `figure*` at top of page |
| ACM Conferences | Two-column vertical | `figure*` at top of page |
| Springer LNCS | Single-column compact | `figure` in text |
| Elsevier Journals | Two-column vertical | `figure*` at top of page |
| ArXiv Preprints | Two-column vertical | `figure*` at top of page |
| Conference Presentations | Horizontal landscape | Full slide |
| Poster Presentations | Horizontal landscape | Large format |
| Technical Reports | Two-column vertical | `figure*` at top of page |

---

## 💡 Tips for Best Results

1. **Always use vector graphics** - TikZ produces scalable PDF output
2. **Compile twice** - LaTeX needs two passes for correct references
3. **Test with your template** - Verify with actual conference/journal LaTeX class
4. **Use consistent colors** - Match your paper's color scheme
5. **Check printed output** - Verify readability in grayscale if required
6. **Keep fonts readable** - Don't scale down below \tiny
7. **Proofread labels** - Check all phase numbers and names
8. **Verify arrows** - Ensure flow is clear and logical

---

## 📞 Support

If you encounter issues:
1. Check the [troubleshooting section](#-troubleshooting)
2. Review [flowchart_usage_guide.tex](flowchart_usage_guide.tex)
3. Verify all required packages are installed
4. Test with a minimal working example

---

## 📄 License

These LaTeX files are provided for research and academic use.
Feel free to modify and adapt for your publication needs.

---

## 🔄 Version History

- **v1.0** (2026-01-07): Initial release with three flowchart versions
  - Two-column vertical (full detail)
  - Single-column compact (space-efficient)
  - Horizontal landscape (presentation-ready)

---

**Happy Publishing! 📝✨**
