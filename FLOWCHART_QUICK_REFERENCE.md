# Flowchart Quick Reference Card

## ⚡ Ultra-Quick Start

### Step 1: Add to Preamble
```latex
\usepackage{tikz}
\usetikzlibrary{shapes.geometric, arrows.meta, positioning, fit, backgrounds}
```

### Step 2: Include in Document
```latex
\input{system_pipeline_flowchart}  % Two-column version
```

### Step 3: Compile
```bash
pdflatex your_paper.tex
```

---

## 📁 File Selection Guide

| Your Paper Format | Use This File |
|-------------------|---------------|
| IEEE double-column | `system_pipeline_flowchart.tex` |
| ACM double-column | `system_pipeline_flowchart.tex` |
| Single-column journal | `system_pipeline_flowchart_compact.tex` |
| Presentation slides | `system_pipeline_flowchart_horizontal.tex` |
| Poster | `system_pipeline_flowchart_horizontal.tex` |

---

## 🔧 Common Fixes

### Problem: Figure too large
```latex
% Add scaling:
\begin{tikzpicture}[scale=0.8, every node/.style={scale=0.8}]
```

### Problem: Missing TikZ library error
```latex
% Add to preamble:
\usetikzlibrary{shapes.geometric, arrows.meta, positioning, fit, backgrounds}
```

### Problem: Text overlapping
```latex
% In style definitions, increase:
minimum width=4cm   % was 3cm
minimum height=1cm  % was 0.6cm
```

---

## 🎨 Quick Customization

### Change All Colors to Grayscale
Replace in all three `.tex` files:
```latex
fill=blue!20   → fill=black!10
fill=orange!15 → fill=black!15
fill=green!15  → fill=black!20
fill=yellow!20 → fill=black!5
```

### Make Fonts Smaller
In style definitions:
```latex
font=\small      → font=\footnotesize
font=\scriptsize → font=\tiny
```

### Make Arrows Thicker
```latex
arrow/.style={-{Stealth[length=2mm]}, thick}
→
arrow/.style={-{Stealth[length=3mm]}, very thick}
```

---

## 📝 Figure Labels

- Two-column: `\ref{fig:system_pipeline}`
- Compact: `\ref{fig:pipeline_compact}`
- Horizontal: `\ref{fig:pipeline_horizontal}`

---

## ✅ Checklist Before Submission

- [ ] Flowchart compiles without errors
- [ ] Figure reference works correctly
- [ ] Caption text is appropriate
- [ ] All text is readable at printed size
- [ ] Colors work in grayscale (if required)
- [ ] Figure fits on page properly
- [ ] File paths are correct in `\input{}`

---

## 🆘 Emergency Contacts

**Compilation Error?**
1. Check TikZ libraries loaded
2. Verify file path in `\input{}`
3. Try compiling twice (for references)

**Layout Issue?**
1. Try different figure placement: `[t]`, `[h]`, `[t!]`
2. Scale down: add `scale=0.8` to tikzpicture options
3. Use compact version instead

**Need Help?**
- See: [FLOWCHART_README.md](FLOWCHART_README.md) for detailed guide
- See: [flowchart_usage_guide.tex](flowchart_usage_guide.tex) for full example
- Test with: [test_flowchart.tex](test_flowchart.tex)

---

## 📦 All Files

1. `system_pipeline_flowchart.tex` - Two-column (main)
2. `system_pipeline_flowchart_compact.tex` - Single-column
3. `system_pipeline_flowchart_horizontal.tex` - Landscape
4. `test_flowchart.tex` - Test compilation
5. `FLOWCHART_README.md` - Full documentation
6. `flowchart_usage_guide.tex` - Complete example
7. `FLOWCHART_QUICK_REFERENCE.md` - This file

**Recommended for most papers:** Use file #1 (`system_pipeline_flowchart.tex`)
