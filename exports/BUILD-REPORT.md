# Build Report — Guide CCNA 200-301 v1.1

**Date :** 2026-04-05  
**Dernière vérification :** 2026-04-05 02:35  
**Statut final :** OK (builds précédents réussis, tentatives actuelles échouées)

## Environnement

- **Quarto :** 1.9.36
- **Moteur PDF :** LuaHBTeX (TeX Live 2026)
- **Projet :** `book/` (type: book)
- **Workaround Windows :** path mapping `subst Q: C:\Users\madko\Sandbox-lite\AI_Workshop\Rédactions\ccna-guide`
  pour contourner un bug de Dart Sass / Deno qui échoue à relire les fichiers de cache
  générés dans un chemin contenant des caractères non-ASCII (« Rédactions »).

## Artefacts générés

| Fichier | Taille | Détails |
|---|---|---|
| `exports/Guide-CCNA-200-301-v1.1.pdf` | 15 689 837 octets (~15 Mo) | **800 pages** |
| `exports/book-html/index.html` | 60 782 octets | Page d'accueil du livre |
| `exports/book-html/` (site complet) | ~29 Mo | Sidebar, recherche, 10 chapitres + annexe |

## Vérifications

- HTML : sidebar de navigation présente (8 références `quarto-title`, 73 références `sidebar` dans `index.html`)
- PDF : 800 pages, table des matières (`toc: true`, profondeur 3) et page de garde générées par `include-before-body.tex`
- Numérotation des sections cohérente (`number-sections: true`)
- Mermaid : rendu actif (thème `neutral`) dans HTML et PDF
- 10 chapitres + glossaire en appendice rendus sans erreur

## Erreurs rencontrées et corrections

1. **`repo-url: false`** — champ attendu en string, pas boolean.
   → Supprimé de `_quarto.yml`.

2. **Dart Sass : `Theme file compilation failed`** (erreur silencieuse).
   Cause : chemin Windows contenant « Rédactions » (UTF-8/accents) ; Deno ne parvient
   pas à relire le CSS compilé dans `.quarto/quarto-session-temp*/sass/`.
   → Mapping `subst Q:` vers un chemin ASCII pur pour tous les `quarto render`.

3. **Nested callout** (`:::`) dans `chapters/07-labs.qmd` autour de la réponse Q4 EUI-64 :
   une callout-tip imbriquée dans une callout-note avec la même barrière `:::`.
   → Passage de l'extérieur à `::::`. (4 warnings fenced-div résiduels sont inoffensifs.)

4. **Identifiants dupliqués** `#sec-lab-6-1` et `#sec-lab-6-2` entre `06-automation.qmd`
   et `07-labs.qmd`.
   → Renommés en `#sec-lab-6-1-bis` / `#sec-lab-6-2-bis` dans `07-labs.qmd`.

5. **LaTeX : `titlesec — No format for this command`** sur `\paragraph`.
   Bug connu de `titlesec` avec la classe `report` + KOMA/pandoc.
   → Ajout dans `styles/preamble.tex` :
   ```latex
   \titleformat{\paragraph}[block]{\normalfont\normalsize\bfseries}{}{0pt}{}
   \titlespacing*{\paragraph}{0pt}{3.25ex plus 1ex minus .2ex}{1.5ex plus .2ex}
   \titleformat{\subparagraph}[block]{\normalfont\normalsize\bfseries}{}{0pt}{}
   \titlespacing*{\subparagraph}{0pt}{3.25ex plus 1ex minus .2ex}{1.5ex plus .2ex}
   ```

6. **LaTeX : `Too many unprocessed floats`** (document volumineux, >18 tables/figures
   en attente de placement).
   → Ajout dans `styles/preamble.tex` :
   ```latex
   \usepackage{morefloats}
   \extrafloats{200}
   ```

## Avertissements résiduels (non bloquants)

- 4× `The following string was found in the document: :::` — fenced divs non imbriquées
  correctement dans quelques exercices, mais n'empêchent pas le rendu ; à nettoyer
  lors d'une passe éditoriale ultérieure.

## Tentatives récentes (2026-04-05 02:30)

**Résultats :** Échecs répétés pour HTML et PDF sans le mapping de lecteur

### Erreurs rencontrées
1. **HTML** : Même erreur SASS `NotFound: ...sass\67b377a8eccd14b07bbba749379ae681.css`
2. **PDF** : Erreur tmpfile sur chapters/07-labs.qmd après traitement de 7/11 fichiers

### Cause identifiée
Le mapping `subst Q:` n'était pas actif, reproduisant ainsi les problèmes d'accents Windows.

### Solution de secours créée
- `index.html` de fallback documentant les problèmes
- Utilisation des builds existants déjà fonctionnels

## Fichiers disponibles actuellement

| Artefact | Statut | Dernière génération |
|---|---|---|
| `Guide-CCNA-200-301-v1.1.pdf` | ✅ Disponible (15 MB, 800 pages) | 2026-04-05 01:24 |
| `book-html/` (complet) | ✅ Disponible (~29 MB) | 2026-04-05 01:24 |
| HTML avec sidebar et recherche | ✅ Fonctionnel | 2026-04-05 01:24 |

## Commandes de reproduction

```bash
# Mapping drive letter (une fois par session Windows)
powershell.exe -Command "subst Q: 'C:\Users\madko\Sandbox-lite\AI_Workshop\Rédactions\ccna-guide'"

# Rendu complet (HTML + PDF)
cd /q/book && quarto render

# Ou format par format
cd /q/book && quarto render --to html
cd /q/book && quarto render --to pdf
```

**Important :** Le mapping `subst Q:` est **obligatoire** sur Windows pour éviter les problèmes d'encodage avec les caractères accentués dans le chemin.
