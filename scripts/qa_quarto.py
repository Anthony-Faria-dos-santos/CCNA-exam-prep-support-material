#!/usr/bin/env python3
"""
qa_quarto.py — QA complète du projet Quarto CCNA avant rendu.

Vérifie structure, headings, callouts, mermaid, images, cross-refs, liens,
code blocks, couverture exam topics et statistiques.

Usage : python3 scripts/qa_quarto.py
Exit  : 0 = OK, 1 = erreurs bloquantes, 2 = warnings seulement
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path
from collections import defaultdict

# ---------------------------------------------------------------------------
# Chemins projet
# ---------------------------------------------------------------------------
ROOT = Path(__file__).resolve().parent.parent
BOOK = ROOT / "book"
QUARTO_YML = BOOK / "_quarto.yml"
CHAPTERS_DIR = BOOK / "chapters"
ASSETS_IMAGES = BOOK / "assets" / "images"
ASSETS_DIAGRAMS = BOOK / "assets" / "diagrams"
REFS_TOPICS = ROOT / "references" / "exam-topics.md"
REPORT = ROOT / "exports" / "QA-REPORT.md"

# Collecte d'erreurs / warnings
errors: list[str] = []
warnings: list[str] = []
info: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)


def warn(msg: str) -> None:
    warnings.append(msg)


# ---------------------------------------------------------------------------
# 1. STRUCTURE — lire _quarto.yml et vérifier fichiers
# ---------------------------------------------------------------------------
def parse_quarto_yml() -> list[Path]:
    """Extrait tous les chemins .qmd listés dans _quarto.yml (sans dép. yaml)."""
    text = QUARTO_YML.read_text(encoding="utf-8")
    # Capture tous les chemins .qmd mentionnés
    rels = re.findall(r"([A-Za-z0-9_/.\-]+\.qmd)", text)
    return [BOOK / r for r in rels]


def check_structure() -> tuple[list[Path], list[Path]]:
    listed = parse_quarto_yml()
    # existence
    for p in listed:
        if not p.exists():
            err(f"[STRUCTURE] Fichier listé dans _quarto.yml introuvable : {p.relative_to(BOOK)}")

    # fichiers réels
    actual = sorted(CHAPTERS_DIR.glob("*.qmd"))
    listed_set = {p.resolve() for p in listed}
    for p in actual:
        if p.resolve() not in listed_set:
            err(f"[STRUCTURE] Fichier orphelin (non référencé dans _quarto.yml) : {p.relative_to(BOOK)}")

    qmd_files = [p for p in listed if p.exists() and p.suffix == ".qmd"]
    return qmd_files, actual


# ---------------------------------------------------------------------------
# 2. HEADINGS
# ---------------------------------------------------------------------------
HEADING_RE = re.compile(r"^(#{1,6})\s+(.+?)\s*(?:\{[^}]*\})?\s*$")


def strip_code_blocks(lines: list[str]) -> list[str]:
    """Retourne les lignes hors blocs ```...``` ."""
    out = []
    in_fence = False
    fence_char = None
    for line in lines:
        stripped = line.lstrip()
        if not in_fence and (stripped.startswith("```") or stripped.startswith("~~~")):
            in_fence = True
            fence_char = stripped[:3]
            out.append("")  # placeholder
            continue
        if in_fence and stripped.startswith(fence_char):
            in_fence = False
            out.append("")
            continue
        if in_fence:
            out.append("")
        else:
            out.append(line)
    return out


def check_headings(qmd: Path) -> None:
    rel = qmd.relative_to(BOOK)
    lines = qmd.read_text(encoding="utf-8").splitlines()
    no_code = strip_code_blocks(lines)

    prev_level = 0
    seen: dict[str, int] = {}
    for i, line in enumerate(no_code, start=1):
        m = HEADING_RE.match(line)
        if not m:
            continue
        level = len(m.group(1))
        title = m.group(2).strip()

        if level == 1:
            err(f"[HEADINGS] {rel}:{i} — h1 interdit dans un chapitre (réservé au frontmatter) : '{title}'")

        if prev_level and level > prev_level + 1:
            err(f"[HEADINGS] {rel}:{i} — saut de niveau h{prev_level} → h{level} : '{title}'")

        key = f"h{level}:{title.lower()}"
        if key in seen:
            warn(f"[HEADINGS] {rel}:{i} — heading dupliqué h{level} '{title}' (première occurrence l.{seen[key]})")
        else:
            seen[key] = i

        prev_level = level


# ---------------------------------------------------------------------------
# 3. CALLOUTS
# ---------------------------------------------------------------------------
CALLOUT_OPEN_RE = re.compile(r"^:::+\s*\{?\.callout-(\w+)")
FENCE_DIV_OPEN_RE = re.compile(r"^(:{3,})\s*(\S.*)?$")
FENCE_DIV_CLOSE_RE = re.compile(r"^(:{3,})\s*$")
STD_CALLOUTS = {"tip", "warning", "note", "important", "caution"}


def check_callouts(qmd: Path) -> None:
    rel = qmd.relative_to(BOOK)
    lines = qmd.read_text(encoding="utf-8").splitlines()
    no_code = strip_code_blocks(lines)

    stack: list[tuple[int, str]] = []  # (line, type or '')
    for i, line in enumerate(no_code, start=1):
        # Close
        mc = FENCE_DIV_CLOSE_RE.match(line.strip())
        if mc and stack:
            stack.pop()
            continue
        # Open (a div with attrs)
        mo = FENCE_DIV_OPEN_RE.match(line.strip())
        if mo and mo.group(2):
            # divs opening
            content = mo.group(2).strip()
            co = CALLOUT_OPEN_RE.match(line.strip())
            ctype = ""
            if co:
                ctype = co.group(1).lower()
                if ctype not in STD_CALLOUTS:
                    warn(f"[CALLOUTS] {rel}:{i} — type non standard '{ctype}' (attendu: {', '.join(sorted(STD_CALLOUTS))})")
            stack.append((i, ctype))
        elif mo and not mo.group(2):
            # pure closing (already handled above but safety)
            if stack:
                stack.pop()

    for ln, ctype in stack:
        err(f"[CALLOUTS] {rel}:{ln} — bloc ::: non fermé (type='{ctype or 'div'}')")


# ---------------------------------------------------------------------------
# 4. MERMAID
# ---------------------------------------------------------------------------
MERMAID_OPEN_RE = re.compile(r"^```\{mermaid\}\s*$")
INCLUDE_MMD_RE = re.compile(r"\{\{<\s*include\s+([^>}]+\.mmd)\s*>\}\}")


def check_mermaid(qmd_files: list[Path]) -> set[Path]:
    referenced_mmd: set[Path] = set()
    for qmd in qmd_files:
        rel = qmd.relative_to(BOOK)
        lines = qmd.read_text(encoding="utf-8").splitlines()
        # mermaid blocks syntactic closure (reuse generic code block check later)
        in_mer = False
        open_line = 0
        for i, line in enumerate(lines, start=1):
            if not in_mer and MERMAID_OPEN_RE.match(line):
                in_mer = True
                open_line = i
                continue
            if in_mer and line.strip().startswith("```"):
                in_mer = False
        if in_mer:
            err(f"[MERMAID] {rel}:{open_line} — bloc ```{{mermaid}} non fermé")

        # includes
        text = "\n".join(lines)
        for m in INCLUDE_MMD_RE.finditer(text):
            path = (qmd.parent / m.group(1)).resolve()
            if not path.exists():
                err(f"[MERMAID] {rel} — include .mmd introuvable : {m.group(1)}")
            else:
                referenced_mmd.add(path)

    # orphelins
    if ASSETS_DIAGRAMS.exists():
        for mmd in ASSETS_DIAGRAMS.glob("*.mmd"):
            if mmd.resolve() not in referenced_mmd:
                warn(f"[MERMAID] Fichier .mmd non référencé : {mmd.relative_to(BOOK)}")
    return referenced_mmd


# ---------------------------------------------------------------------------
# 5. IMAGES
# ---------------------------------------------------------------------------
IMG_MD_RE = re.compile(r"!\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
IMG_HTML_RE = re.compile(r"<img[^>]+src=[\"']([^\"']+)[\"']", re.IGNORECASE)


def check_images(qmd_files: list[Path]) -> None:
    referenced: set[Path] = set()
    for qmd in qmd_files:
        rel = qmd.relative_to(BOOK)
        text = qmd.read_text(encoding="utf-8")
        paths = IMG_MD_RE.findall(text) + IMG_HTML_RE.findall(text)
        for p in paths:
            if p.startswith(("http://", "https://", "data:")):
                continue
            full = (qmd.parent / p).resolve()
            if not full.exists():
                err(f"[IMAGES] {rel} — image introuvable : {p}")
            else:
                referenced.add(full)

    if ASSETS_IMAGES.exists():
        for img in ASSETS_IMAGES.rglob("*"):
            if img.is_file() and img.suffix.lower() in {".png", ".jpg", ".jpeg", ".svg", ".gif", ".webp"}:
                if img.resolve() not in referenced:
                    warn(f"[IMAGES] Image non référencée : {img.relative_to(BOOK)}")


# ---------------------------------------------------------------------------
# 6. CROSS-REFERENCES
# ---------------------------------------------------------------------------
# Labels via {#sec-xxx} / {#fig-xxx} / {#tbl-xxx}, ou via %%| label: pour mermaid,
# ou via #| label: pour code cells.
LABEL_INLINE_RE = re.compile(r"\{#((?:sec|fig|tbl|lst|eq|thm)-[\w:-]+)[^}]*\}")
LABEL_YAML_RE = re.compile(r"^\s*(?:%%\|\s*|#\|\s*)label:\s*[\"']?((?:sec|fig|tbl|lst|eq|thm)-[\w:-]+)", re.MULTILINE)
REF_RE = re.compile(r"(?<![\w`])@((?:sec|fig|tbl|lst|eq|thm)-[\w:-]+)")


def check_crossrefs(qmd_files: list[Path]) -> None:
    labels: dict[str, Path] = {}
    refs: list[tuple[str, Path, int]] = []

    for qmd in qmd_files:
        text = qmd.read_text(encoding="utf-8")
        for m in LABEL_INLINE_RE.finditer(text):
            labels.setdefault(m.group(1), qmd)
        for m in LABEL_YAML_RE.finditer(text):
            labels.setdefault(m.group(1), qmd)
        for i, line in enumerate(text.splitlines(), start=1):
            # ignore inside inline code backticks approximately
            for m in REF_RE.finditer(line):
                refs.append((m.group(1), qmd, i))

    for ref, qmd, ln in refs:
        if ref not in labels:
            err(f"[CROSSREFS] {qmd.relative_to(BOOK)}:{ln} — référence @{ref} sans label correspondant")


# ---------------------------------------------------------------------------
# 7. LIENS internes
# ---------------------------------------------------------------------------
LINK_RE = re.compile(r"(?<!!)\[([^\]]+)\]\(([^)\s]+?)(?:\s+\"[^\"]*\")?\)")


def check_links(qmd_files: list[Path]) -> None:
    for qmd in qmd_files:
        rel = qmd.relative_to(BOOK)
        text = qmd.read_text(encoding="utf-8")
        for m in LINK_RE.finditer(text):
            target = m.group(2)
            if target.startswith(("http://", "https://", "mailto:", "#", "tel:")):
                continue
            if target.startswith("@"):  # cross-ref bizarre
                continue
            # lien fichier relatif
            frag = None
            if "#" in target:
                target_path, frag = target.split("#", 1)
            else:
                target_path = target
            if not target_path:
                continue
            full = (qmd.parent / target_path).resolve()
            if not full.exists():
                err(f"[LIENS] {rel} — lien cassé : {target}")


# ---------------------------------------------------------------------------
# 8. CODE BLOCKS — fermeture
# ---------------------------------------------------------------------------
def check_code_blocks(qmd: Path) -> None:
    rel = qmd.relative_to(BOOK)
    lines = qmd.read_text(encoding="utf-8").splitlines()
    in_fence = False
    open_line = 0
    for i, line in enumerate(lines, start=1):
        if line.lstrip().startswith("```"):
            if not in_fence:
                in_fence = True
                open_line = i
            else:
                in_fence = False
    if in_fence:
        err(f"[CODE] {rel}:{open_line} — bloc ``` non fermé")


# ---------------------------------------------------------------------------
# 9. COUVERTURE EXAM TOPICS
# ---------------------------------------------------------------------------
def extract_topic_ids(text: str) -> set[str]:
    return set(re.findall(r"(?:^|\s)(\d+\.\d+)(?:\s|$|\.|\b)", text, re.MULTILINE))


def check_coverage(qmd_files: list[Path]) -> None:
    if not REFS_TOPICS.exists():
        warn(f"[COVERAGE] {REFS_TOPICS.relative_to(ROOT)} introuvable — skip")
        return
    expected = extract_topic_ids(REFS_TOPICS.read_text(encoding="utf-8"))
    # restreindre 1.x à 6.x
    expected = {t for t in expected if t.split(".")[0] in {"1", "2", "3", "4", "5", "6"}}

    covered: set[str] = set()
    per_chapter: dict[str, set[str]] = {}
    for qmd in qmd_files:
        ids = extract_topic_ids(qmd.read_text(encoding="utf-8"))
        ids = {t for t in ids if t.split(".")[0] in {"1", "2", "3", "4", "5", "6"}}
        per_chapter[qmd.name] = ids
        covered |= ids

    missing = expected - covered
    for tid in sorted(missing, key=lambda x: [int(n) for n in x.split(".")]):
        err(f"[COVERAGE] Topic CCNA {tid} absent de tous les chapitres")
    info.append(f"Coverage : {len(expected) - len(missing)}/{len(expected)} topics CCNA couverts")


# ---------------------------------------------------------------------------
# 10. STATS
# ---------------------------------------------------------------------------
def compute_stats(qmd_files: list[Path]) -> list[dict]:
    stats = []
    for qmd in qmd_files:
        text = qmd.read_text(encoding="utf-8")
        no_code_lines = strip_code_blocks(text.splitlines())
        words = sum(len(l.split()) for l in no_code_lines)
        # heuristiques exercices / labs / quiz
        exercises = len(re.findall(r"(?im)^\s*#{2,4}\s*(?:exercice|exercise)\b", text))
        labs = len(re.findall(r"(?im)^\s*#{2,4}\s*lab\b", text))
        questions = len(re.findall(r"(?im)^\s*(?:\*\*)?(?:question|q)\s*\d+", text))
        pages_est = round(words / 350)  # ~350 mots / page A4
        stats.append({
            "file": qmd.relative_to(BOOK).as_posix(),
            "words": words,
            "exercises": exercises,
            "labs": labs,
            "questions": questions,
            "pages_est": pages_est,
        })
    return stats


# ---------------------------------------------------------------------------
# Rapport
# ---------------------------------------------------------------------------
def write_report(stats: list[dict]) -> None:
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    lines: list[str] = []
    lines.append("# QA Report — Guide CCNA Quarto")
    lines.append("")
    lines.append(f"- Erreurs bloquantes : **{len(errors)}**")
    lines.append(f"- Warnings : **{len(warnings)}**")
    lines.append("")
    for i in info:
        lines.append(f"> {i}")
    lines.append("")

    if errors:
        lines.append("## Erreurs bloquantes")
        lines.append("")
        for e in errors:
            lines.append(f"- {e}")
        lines.append("")
    else:
        lines.append("## Erreurs bloquantes")
        lines.append("")
        lines.append("_Aucune._")
        lines.append("")

    if warnings:
        lines.append("## Warnings")
        lines.append("")
        for w in warnings:
            lines.append(f"- {w}")
        lines.append("")
    else:
        lines.append("## Warnings")
        lines.append("")
        lines.append("_Aucun._")
        lines.append("")

    lines.append("## Statistiques par chapitre")
    lines.append("")
    lines.append("| Fichier | Mots | Exercices | Labs | Questions | Pages (est.) |")
    lines.append("|---|---:|---:|---:|---:|---:|")
    tot_w = tot_ex = tot_lab = tot_q = tot_p = 0
    for s in stats:
        lines.append(
            f"| {s['file']} | {s['words']} | {s['exercises']} | {s['labs']} | {s['questions']} | {s['pages_est']} |"
        )
        tot_w += s["words"]
        tot_ex += s["exercises"]
        tot_lab += s["labs"]
        tot_q += s["questions"]
        tot_p += s["pages_est"]
    lines.append(f"| **TOTAL** | **{tot_w}** | **{tot_ex}** | **{tot_lab}** | **{tot_q}** | **{tot_p}** |")
    lines.append("")

    REPORT.write_text("\n".join(lines), encoding="utf-8")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> int:
    if not QUARTO_YML.exists():
        print(f"ERREUR : {QUARTO_YML} introuvable")
        return 1

    qmd_files, _ = check_structure()

    for qmd in qmd_files:
        check_headings(qmd)
        check_callouts(qmd)
        check_code_blocks(qmd)

    check_mermaid(qmd_files)
    check_images(qmd_files)
    check_crossrefs(qmd_files)
    check_links(qmd_files)
    check_coverage(qmd_files)

    stats = compute_stats(qmd_files)
    write_report(stats)

    # Console summary
    print("=" * 60)
    print(f"QA Quarto — {len(errors)} erreur(s), {len(warnings)} warning(s)")
    print(f"Rapport : {REPORT}")
    print("=" * 60)
    for e in errors[:20]:
        print(f"  ERR  {e}")
    if len(errors) > 20:
        print(f"  ... +{len(errors) - 20} erreurs (voir rapport)")
    for w in warnings[:10]:
        print(f"  WARN {w}")
    if len(warnings) > 10:
        print(f"  ... +{len(warnings) - 10} warnings (voir rapport)")

    if errors:
        return 1
    if warnings:
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
