#!/bin/bash
# merge-guide.sh — Assemble tous les modules en un guide CCNA complet
# Usage : bash scripts/merge-guide.sh [output_path]

set -euo pipefail

OUTPUT="${1:-exports/CCNA-GUIDE-COMPLET.md}"
MODULES_DIR="modules"
LABS_DIR="labs"
QUIZZES_DIR="quizzes"

mkdir -p "$(dirname "$OUTPUT")"

echo "🔧 Assemblage du guide CCNA..."

# Header
cat > "$OUTPUT" << 'HEADER'
# Guide CCNA 200-301 v1.1 — Formation Complète

> **Version** : 1.0
> **Alignement** : Cisco CCNA 200-301 v1.1 + NetAcad
> **Durée estimée** : 10 semaines

---

## Table des matières

<!-- TOC auto-générée par pandoc ou éditeur MD -->

---

HEADER

# Modules dans l'ordre
for i in 1 2 3 4 5 6; do
    MODULE_FILE=$(find "$MODULES_DIR" -name "MODULE-${i}-*.md" 2>/dev/null | head -1)
    if [ -n "$MODULE_FILE" ]; then
        echo -e "\n\n---\n\n" >> "$OUTPUT"
        cat "$MODULE_FILE" >> "$OUTPUT"
        echo "  ✅ Module $i ajouté"
    else
        echo "  ⚠️  Module $i non trouvé dans $MODULES_DIR/"
    fi
done

# Annexes — Labs supplémentaires
if [ -d "$LABS_DIR" ] && [ "$(ls -A "$LABS_DIR" 2>/dev/null)" ]; then
    echo -e "\n\n---\n\n# Annexe A — Labs Complémentaires\n" >> "$OUTPUT"
    for lab in "$LABS_DIR"/LAB-*.md; do
        [ -f "$lab" ] && cat "$lab" >> "$OUTPUT" && echo "" >> "$OUTPUT"
    done
    echo "  ✅ Labs annexés"
fi

# Annexes — Exercices transversaux
if [ -d "$QUIZZES_DIR" ] && [ "$(ls -A "$QUIZZES_DIR" 2>/dev/null)" ]; then
    echo -e "\n\n---\n\n# Annexe B — Évaluations Transversales\n" >> "$OUTPUT"
    for quiz in "$QUIZZES_DIR"/*.md; do
        [ -f "$quiz" ] && cat "$quiz" >> "$OUTPUT" && echo "" >> "$OUTPUT"
    done
    echo "  ✅ Quizzes/Exam blanc annexés"
fi

# Glossaire
if [ -f "references/glossaire.md" ]; then
    echo -e "\n\n---\n\n" >> "$OUTPUT"
    cat "references/glossaire.md" >> "$OUTPUT"
    echo "  ✅ Glossaire ajouté"
fi

# Stats
WORDS=$(wc -w < "$OUTPUT")
LINES=$(wc -l < "$OUTPUT")
PAGES_EST=$((WORDS / 350))  # ~350 mots/page en format guide

echo ""
echo "📊 Statistiques :"
echo "   Mots     : $WORDS"
echo "   Lignes   : $LINES"
echo "   Pages est: ~${PAGES_EST} pages"
echo "   Fichier  : $OUTPUT"
echo ""
echo "✅ Guide assemblé avec succès"
