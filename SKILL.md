---
name: ccna-guide
description: |
  Générateur de guide CCNA 200-301 v1.1 exhaustif, pédagogique, aligné NetAcad et exam topics Cisco.
  Produit des modules complets avec théorie, exercices CLI, labs Packet Tracer, quizzes et exam blanc.
  
  DÉCLENCHER : génération guide CCNA, module CCNA, exercices réseau, labs Cisco, préparation certification CCNA,
  cours networking, formation réseau, guide NetAcad, CCNA study guide.
  
  INTER-SKILLS OBLIGATOIRES :
  - ghost-writer : TOUJOURS avant rédaction de contenu
  - docx/pdf : pour export final
  - context-handoff : entre chaque module
  - token-optimizer : appliqué par défaut
  - notion-memory : log progression
  
  NE PAS DÉCLENCHER : questions ponctuelles réseau, debug config Cisco, cours non-CCNA.
  EN triggers: CCNA guide, CCNA study, networking course, Cisco certification, NetAcad, exam prep.
---

# CCNA Guide Generator

Génère un guide de formation CCNA 200-301 v1.1 complet par modules itératifs.

## Pré-requis

Avant toute génération, charger :
1. `ghost-writer` → `core-rules.md` + `syntax-voice.md` + `french.md` + `document-types.md`
2. Ce skill → `references/exam-topics.md` (mapping officiel)
3. Ce skill → `references/pedagogy-rules.md` (règles pédagogiques)
4. Le template approprié dans `templates/`

## Workflow

### Phase PLAN
Lire `references/exam-topics.md`. Générer `MASTER-OUTLINE.md` avec structure complète,
topic IDs, estimations pages, liste exercices/labs, planning 10 semaines.

### Phase GENERATE (1 module par session)
Pour chaque module N :
1. Charger `MASTER-OUTLINE.md` (sections module N uniquement)
2. Charger `references/exam-topics.md` (domain N)
3. Charger `templates/module-template.md`
4. Appliquer ghost-writer
5. Générer `modules/MODULE-N-[nom].md`
6. Générer `HANDOFF-MODULE-N.md` via context-handoff

### Phase ENRICH
Générer labs (`labs/`) et quizzes (`quizzes/`) séparément.

### Phase ASSEMBLE
Exécuter `scripts/merge-guide.sh` pour fusionner.

### Phase EXPORT
Utiliser skill `docx` ou `pandoc` pour DOCX/PDF.

### Phase VALIDATE
Exécuter `scripts/coverage-check.py` pour vérifier couverture 100%.

## Règles de contenu

| Règle | Détail |
|-------|--------|
| Chaque section commence par | Objectif exam (topic ID + verbe Cisco) |
| Ratio théorie/pratique | 60/40 minimum |
| Exercices par topic | 1 minimum, 2 si >3 pages |
| Labs par module | 2 minimum, 4 pour module 3 |
| Quiz par module | 10-15 questions format examen |
| Point exam | 1 encadré par section (pièges courants) |
| Cross-references | Liens vers topics liés d'autres modules |
| CLI outputs | Au moins 1 commande show avec output par section |
| Schémas | Description textuelle (placeholder pour images) |

## Fichiers de référence

| Fichier | Quand charger |
|---------|---------------|
| `references/exam-topics.md` | Phase PLAN + chaque module |
| `references/pedagogy-rules.md` | Phase GENERATE |
| `references/lab-templates.md` | Phase ENRICH |
| `templates/module-template.md` | Phase GENERATE |
| `templates/lab-template.md` | Phase ENRICH |
| `templates/quiz-template.md` | Phase ENRICH |
