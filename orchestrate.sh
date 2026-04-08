#!/bin/bash
# ============================================================================
# CCNA Guide — Orchestrateur Autonome pour Claude Code CLI
# ============================================================================
# Usage :
#   chmod +x orchestrate.sh
#   ./orchestrate.sh                  # Auto-détecte et complète le manquant
#   ./orchestrate.sh --skip-to N      # Reprendre à partir de l'étape N
#   ./orchestrate.sh --force           # Tout régénérer (ignore fichiers existants)
#
# Modèles :
#   Opus    → rédaction cours (modules, labs, quizzes, enrichissement)
#   Sonnet  → outillage (outline, glossaire, assemblage, Quarto init/convert/QA/render)
#
# Prérequis :
#   - Claude Code CLI installé et authentifié
#   - quarto installé (quarto install tinytex pour PDF)
# ============================================================================

set -euo pipefail

# === CONFIG ===
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULES_DIR="$PROJECT_DIR/modules"
LABS_DIR="$PROJECT_DIR/labs"
QUIZZES_DIR="$PROJECT_DIR/quizzes"
EXPORTS_DIR="$PROJECT_DIR/exports"
HANDOFFS_DIR="$PROJECT_DIR/handoffs"
LOGS_DIR="$PROJECT_DIR/logs"
QUARTO_DIR="$PROJECT_DIR/book"

# Modèles — Opus pour le contenu, Sonnet pour l'outillage
MODEL_CONTENT="claude-opus-4-6"
MODEL_TOOLING="claude-sonnet-4-20250514"

SKIP_TO="0"
FORCE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-to) SKIP_TO="${2:-0}"; shift 2 ;;
        --force)   FORCE=true; shift ;;
        *)         shift ;;
    esac
done

# === PROGRESSION PERSISTANTE ===
PROGRESS_FILE="$PROJECT_DIR/.progress"

if [ "$SKIP_TO" -eq 0 ] && [ "$FORCE" = false ] && [ -f "$PROGRESS_FILE" ]; then
    SAVED_STEP=$(cat "$PROGRESS_FILE" 2>/dev/null || echo "0")
    if [ "$SAVED_STEP" -gt 0 ]; then
        SKIP_TO="$SAVED_STEP"
        echo -e "\033[1;33m🔄 Reprise depuis l'étape $SAVED_STEP — pour tout relancer : ./orchestrate.sh --force\033[0m"
    fi
fi

if [ "$FORCE" = true ]; then
    echo -e "\033[1;33m🔥 Mode --force : régénération complète\033[0m"
    rm -f "$PROGRESS_FILE"
    SKIP_TO=0
fi

save_progress() { echo "$1" > "$PROGRESS_FILE"; }

# === COULEURS ===
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
ok()  { echo -e "${GREEN}✅ $1${NC}"; }
warn(){ echo -e "${YELLOW}⚠️  $1${NC}"; }
err() { echo -e "${RED}❌ $1${NC}"; }

init_dirs() {
    mkdir -p "$MODULES_DIR" "$LABS_DIR" "$QUIZZES_DIR" \
             "$EXPORTS_DIR" "$HANDOFFS_DIR" "$LOGS_DIR" \
             "$QUARTO_DIR/chapters" "$QUARTO_DIR/assets/images" \
             "$QUARTO_DIR/assets/diagrams" "$QUARTO_DIR/styles" \
             "$QUARTO_DIR/includes" "$QUARTO_DIR/_output"
}

# === RETRY ENGINE ===
MAX_RETRIES=5              # Pour erreurs non-rate-limit
RATE_LIMIT_WAIT=3600       # 1h entre chaque tentative rate-limit (pas 3h fixe)
MAX_RATE_RETRIES=20        # ~20h de patience max = couvre une nuit complète

run_claude() {
    local step_name="$1"
    local prompt="$2"
    local model="${3:-$MODEL_TOOLING}"
    local log_file="$LOGS_DIR/${step_name}.log"
    local attempt=0
    local rate_attempts=0
    local model_short="${model##*-}"

    while true; do
        attempt=$((attempt + 1))
        log "[$step_name] Tentative $attempt (${model_short})"

        local exit_code=0
        claude -p "$prompt" \
            --allowedTools "Bash,Read,Write,Edit" \
            --model "$model" \
            --dangerously-skip-permissions \
            --output-format text \
            < /dev/null \
            2>&1 | tee "$log_file" || exit_code=${PIPESTATUS[0]}

        # Succès
        if [ $exit_code -eq 0 ]; then
            ok "$step_name terminé (tentative $attempt, $model_short)"
            return 0
        fi

        # === RATE LIMIT / QUOTA : retry illimité avec backoff ===
        if grep -qi "rate.limit\|too.many.requests\|429\|capacity\|overloaded\|quota\|out of.*usage\|resets.*pm\|resets.*am" "$log_file" 2>/dev/null; then
            rate_attempts=$((rate_attempts + 1))
            if [ $rate_attempts -ge $MAX_RATE_RETRIES ]; then
                err "$step_name : rate limit après ${rate_attempts} tentatives (~${rate_attempts}h). Abandon."
                return 1
            fi

            # Backoff progressif : 1h, 1h, 1.5h, 1.5h, 2h, 2h...
            local wait_hours=$(( (rate_attempts + 1) / 2 ))
            [ $wait_hours -lt 1 ] && wait_hours=1
            [ $wait_hours -gt 3 ] && wait_hours=3
            local wait_secs=$((wait_hours * 3600))

            local now=$(date '+%H:%M')
            local resume=$(date -d "+${wait_secs} seconds" '+%H:%M' 2>/dev/null \
                        || date -v+${wait_secs}S '+%H:%M' 2>/dev/null \
                        || echo "+${wait_hours}h")

            warn "Rate limit (tentative rate #$rate_attempts). $now → reprise ~$resume (${wait_hours}h)"

            local remaining=$wait_secs
            while [ $remaining -gt 0 ]; do
                local mins=$((remaining / 60))
                log "  💤 Reprise dans ${mins}min..."
                local chunk=1800  # log toutes les 30 min
                [ $remaining -lt $chunk ] && chunk=$remaining
                sleep $chunk
                remaining=$((remaining - chunk))
            done
            warn "Réveil — nouvelle tentative..."
            continue

        # === CONTEXTE TROP LONG : fatal ===
        elif grep -qi "context.window\|token.limit\|too.long" "$log_file" 2>/dev/null; then
            err "$step_name : contexte trop long"
            return 1

        # === CONNEXION REFUSÉE : retry court ===
        elif grep -qi "ConnectionRefused\|Unable to connect" "$log_file" 2>/dev/null; then
            if [ $attempt -ge $MAX_RETRIES ]; then
                err "$step_name : connexion refusée après $MAX_RETRIES tentatives"
                return 1
            fi
            local wait=$((120 * attempt))
            warn "Connexion refusée. Retry dans ${wait}s..."
            sleep $wait

        # === AUTRE ERREUR : retry limité ===
        else
            if [ $attempt -ge $MAX_RETRIES ]; then
                err "$step_name : échec après $MAX_RETRIES tentatives"
                return 1
            fi
            local wait=$((60 * attempt))
            warn "Erreur (exit $exit_code). Retry dans ${wait}s..."
            sleep $wait
        fi
    done
}

# === QUALITY GATES ===

check_output() {
    local pattern="$1" description="$2"
    local found=$(find "$PROJECT_DIR" -path "$pattern" -size +100c 2>/dev/null | head -1)
    if [ -n "$found" ]; then
        ok "$description ($(wc -w < "$found")w) : $found"; return 0
    else
        err "$description introuvable : $pattern"; return 1
    fi
}

check_quality() {
    local filepath="$1" min_words="$2" description="$3"
    [ ! -f "$filepath" ] && { err "QG: $filepath introuvable"; return 1; }

    local words=$(wc -w < "$filepath")
    local mermaid=$(grep -c '```mermaid' "$filepath" 2>/dev/null || echo 0)
    local exercises=$(grep -ci 'exercice' "$filepath" 2>/dev/null || echo 0)
    local points=$(grep -ci 'point.exam' "$filepath" 2>/dev/null || echo 0)
    local pass=true

    [ "$words" -lt "$min_words" ] && { warn "QG $description : ${words}w < ${min_words}w"; pass=false; } \
                                   || ok "QG $description : ${words}w"
    [ "$mermaid" -lt 3 ] && { warn "QG $description : ${mermaid} mermaid < 3"; pass=false; } \
                          || ok "QG $description : ${mermaid} mermaid"

    log "  📊 $description : ${words}w | ${mermaid} mermaid | ${exercises} exos | ${points} pts exam"
    [ "$pass" = false ] && return 1 || return 0
}

# ============================================================================
# PROMPTS — CONTENU (utilisés avec Opus)
# ============================================================================

CONTENT_RULES="
══════════════════════════════════════════════════════════════
  CE GUIDE EST UN VRAI COURS COMPLET, PAS UN RÉSUMÉ
══════════════════════════════════════════════════════════════

Tu travailles dans : $PROJECT_DIR
Lis references/exam-topics.md, pedagogy-rules.md, visual-conventions.md et templates/ AVANT de rédiger.

Tu rédiges un MANUEL DE FORMATION. Un étudiant doit pouvoir passer le CCNA en ne lisant QUE ce guide.

PROFONDEUR :
- Chaque protocole : fonctionnement interne, format paquets, échanges étape par étape, cas réels
- Chaque commande CLI : syntaxe complète, output RÉALISTE NON TRONQUÉ, interprétation ligne par ligne
- Chaque tableau comparatif : minimum 5-6 critères
- Chaque exercice : scénario entreprise réaliste (nom, contexte métier, contraintes)

INTERDIT :
- 'Consultez la documentation Cisco' / 'dépasse le cadre'
- Sections de 3 lignes / listes sans explication / descriptions superficielles

MERMAID OBLIGATOIRE :
- Topologies : graph LR/TD avec routeurs, switches, IPs sur les liens
- Protocoles : sequenceDiagram (OSPF Hello, TCP 3-way, DHCP DORA)
- Décisions : flowchart pour troubleshooting, algorithmes routage
- États : stateDiagram pour STP, OSPF adjacency
- Max 25 lignes/diagramme, labels français, IPs sur liens
- Chaque diagramme : titre (### ou ####) + légende (1-2 lignes après)

STYLE : français naturel, tutoiement, analogies concrètes, pas de patterns IA.
Chaque section : topic ID Cisco + CLI + output + Point exam + exercice + cross-ref.
"

generate_module_prompt() {
    local N=$1
    local NAMES=("" "Network Fundamentals" "Network Access" "IP Connectivity" "IP Services" "Security Fundamentals" "Automation and Programmability")
    local NAME="${NAMES[$N]}"
    local WEIGHTS=("" "20" "20" "25" "10" "15" "10")
    local W="${WEIGHTS[$N]}"
    local MINS=("" "6000" "6000" "9000" "4000" "5500" "4000")
    local MW="${MINS[$N]}"

    local HANDOFF=""
    if [ $N -gt 1 ] && [ -f "$HANDOFFS_DIR/HANDOFF-MODULE-$((N-1)).md" ]; then
        HANDOFF="Lis le handoff précédent : $HANDOFFS_DIR/HANDOFF-MODULE-$((N-1)).md"
    fi

    local SPECS=""
    case $N in
    1) SPECS="
MERMAID : OSI vs TCP/IP, 2-tier/3-tier/spine-leaf (3 graphs), encapsulation, trame Ethernet,
TCP 3-way handshake, TCP vs UDP, classes IPv4 + RFC1918, en-têtes IPv4 vs IPv6, SOHO vs Enterprise,
MAC learning sequenceDiagram. Total : 10 minimum.

PROFONDEUR : Subnetting (1.6) = 4 pages min (méthode nombre magique, /24→/28→VLSM, 5 exercices).
IPv6 (1.8-1.9) = EUI-64 pas-à-pas, ND Protocol 5 messages ICMPv6.
Wireless (1.11) = tableau 802.11 a/b/g/n/ac/ax + canaux 2.4GHz.
Topic 1.14 GenAI networking = NOUVEAU v1.1."
    ;;
    2) SPECS="
MERMAID : topologie VLAN multi-switch, tag 802.1Q (TPID/PCP/DEI/VID), DTP stateDiagram,
LACP sequenceDiagram, STP complet (3+ switches, root bridge, ports, coûts),
états STP stateDiagram, Wi-Fi split-MAC/CAPWAP, FlexConnect vs Local. Total : 8 minimum.

PROFONDEUR : STP/RSTP (2.5) = 4 pages min (élection root bridge, Bridge ID, coûts, exercice).
VLANs (2.1) = config multi-switch complète + voice VLAN.
WLC GUI (2.9) = schéma interface annotée."
    ;;
    3) SPECS="
MODULE LE PLUS IMPORTANT (25%). MINIMUM 9000 MOTS.

MERMAID : table de routage annotée, longest prefix match flowchart,
router-on-a-stick topologie, routes statiques (3 types comparés),
OSPF adjacency stateDiagram (7 états), OSPF DR/BDR sequenceDiagram,
OSPF paquets flowchart, OSPF coût topologie, OSPF single-area topologie,
FHRP/HSRP topologie. Total : 10 minimum.

PROFONDEUR : OSPF (3.4) = 8 PAGES MIN. 5 types paquets, 7 états, élection DR/BDR,
config (network, router-id, passive-interface, cost), show ip ospf neighbor/interface/database/route
OUTPUTS COMPLETS, 5 erreurs courantes, 4 exercices.
Routing table (3.1-3.2) = show ip route COMPLET chaque ligne expliquée.
Static routes (3.3) = toutes variantes (next-hop, exit-if, floating, default)."
    ;;
    4) SPECS="
MERMAID : NAT inside/outside topologie, NAT flowchart (static/dynamic/PAT),
DHCP DORA sequenceDiagram, DHCP relay topologie, DNS résolution sequenceDiagram,
NTP hiérarchie stratum, QoS flowchart, syslog 8 niveaux. Total : 8 minimum.

PROFONDEUR : NAT/PAT (4.1) = show ip nat translations/statistics complets.
DHCP (4.3, 4.6) = DORA paquet par paquet, config server + relay.
QoS (4.7) = analogies (ambulance = priority queue)."
    ;;
    5) SPECS="
MERMAID : taxonomie menaces flowchart, VPN IPsec tunnel,
ACL processing flowchart (séquentiel, implicit deny), ACL placement topologie,
DHCP snooping sequenceDiagram, DAI vérification, port security stateDiagram,
RADIUS vs TACACS+ flowchart, WPA/WPA2/WPA3 comparatif. Total : 9 minimum.

PROFONDEUR : ACLs (5.6) = 5 PAGES MIN. Standard + extended + named,
wildcard masks (255.255.255.255 - masque), placement, 5 exercices progressifs,
show access-lists + show ip interface complets.
L2 Security (5.7) = attaque AVANT protection (spoofing→snooping, poisoning→DAI, flooding→port-security).
Topic 5.11 ML security = NOUVEAU v1.1."
    ;;
    6) SPECS="
MERMAID : traditionnel vs SDN (2 graphs), SDN architecture (NB/SB APIs),
overlay/underlay/fabric, DNA Center, REST CRUD flowchart,
JSON annoté, Ansible vs Puppet vs Chef. Total : 7 minimum.

PROFONDEUR : REST APIs (6.5) = exemples curl concrets avec payloads JSON, codes HTTP.
JSON (6.7) = données réseau réelles (interfaces, routing table, inventaire), exercice parsing.
Automation impact (6.1) = cas concret 100 switches manuel (3j) vs automatisé (15min)."
    ;;
    esac

    cat << PROMPT
$CONTENT_RULES
$HANDOFF

TÂCHE : Module $N — $NAME ($W%). SEUIL : $MW mots minimum.

Lis : MASTER-OUTLINE.md (module $N), references/exam-topics.md (domain $N),
references/pedagogy-rules.md, references/visual-conventions.md, templates/module-template.md.

Génère : $MODULES_DIR/MODULE-${N}-$(echo "$NAME" | tr ' ' '-' | tr '[:upper:]' '[:lower:]').md

STRUCTURE PAR SECTION :
1. Intro (pourquoi ça compte en entreprise)
2. Théorie détaillée (fonctionnement interne)
3. Diagramme Mermaid
4. CLI complète + output réaliste NON TRONQUÉ
5. Interprétation ligne par ligne
6. Tableau récapitulatif/comparatif
7. Encadré Point exam (piège + astuce mémorisation)
8. Exercice entreprise réaliste + solution cachée
9. Cross-references

Fin de module : quiz 12-15 questions (4 options, explication chaque option, topic ID) + checklist auto-éval.

$SPECS

VÉRIF : Compter les mots. Si < $MW, compléter. Vérifier chaque topic ID du domain $N.

Puis créer $HANDOFFS_DIR/HANDOFF-MODULE-${N}.md (sections, topics, volume, mermaid count, exercices, notes module suivant).
PROMPT
}

PROMPT_LABS="
$CONTENT_RULES

TÂCHE : 16 labs Packet Tracer.

Lis references/lab-templates.md + templates/lab-template.md + les 6 modules (titres seulement).

Génère dans $LABS_DIR/ : LAB-1-1 à LAB-6-2 (16 fichiers, noms dans lab-templates.md).

Chaque lab : topologie Mermaid (pas juste ASCII), tableau d'adressage complet,
config de départ, étapes numérotées avec commandes IOS exactes et outputs attendus,
point exam, questions réflexion + réponses en spoiler, solution complète en spoiler.
"

PROMPT_QUIZZES="
$CONTENT_RULES

TÂCHE : Évaluations transversales + exam blanc.

Lis templates/quiz-template.md + les 6 modules (points clés).

Génère dans $QUIZZES_DIR/ :
1. QUIZ-TRANSVERSAL-1.md : 25 questions modules 1-3, MCQ + scénarios
2. QUIZ-TRANSVERSAL-2.md : 25 questions modules 1-5, interconnexions inter-domains
3. SUBNETTING-DRILL.md : 50 exercices 5 niveaux (basique→VLSM→supernetting→dépannage→examen)
4. EXAM-BLANC.md : 102+ questions format examen (répartition officielle par domain,
   MCQ simple/multiple, drag-and-drop, scénarios, 120 min, explications complètes)
"

# ============================================================================
# PROMPTS — OUTILLAGE (utilisés avec Sonnet)
# ============================================================================

PROMPT_OUTLINE="
Tu travailles dans $PROJECT_DIR. Lis references/exam-topics.md + references/pedagogy-rules.md.

TÂCHE : Générer MASTER-OUTLINE.md — structure complète du guide CCNA 200-301 v1.1.

Contenu : vue d'ensemble, 6 modules (titre, poids, sections avec topic ID, pages estimées,
exercices, labs, quiz prévus), planning 10 semaines, annexes (subnetting 50 exos, exam blanc, glossaire).
Public : étudiant Bac+3 dev/cybersécurité, bases IT, pas expert réseau. Écris en français.
"

PROMPT_GLOSSAIRE="
Tu travailles dans $PROJECT_DIR. Parcours les 6 modules dans $MODULES_DIR/.

TÂCHE : Générer references/glossaire.md — 150+ termes classés A-Z.
Format : **Terme** — Définition concise. _(Module N, Topic N.X)_
Inclure protocoles, commandes, acronymes, concepts. Écris en français.
"

PROMPT_ASSEMBLE="
Tu travailles dans $PROJECT_DIR.

TÂCHE : Assembler et valider.
1. bash scripts/merge-guide.sh $EXPORTS_DIR/CCNA-GUIDE-COMPLET.md
2. python3 scripts/coverage-check.py
3. Si topics manquants → compléter modules → re-merge
4. Créer $EXPORTS_DIR/RESUME-GUIDE.md (stats : mots, pages, exercices, labs, quiz, couverture)
"

QUARTO_CTX="
Répertoire Quarto : $QUARTO_DIR | Sources MD : $MODULES_DIR, $LABS_DIR, $QUIZZES_DIR
Glossaire : $PROJECT_DIR/references/glossaire.md
Docs Quarto : quarto.org/docs/guide/, diagrams, callouts, cross-references, pdf-basics
"

PROMPT_QUARTO_INIT="
$QUARTO_CTX

TÂCHE : Initialiser le projet Quarto book dans $QUARTO_DIR/.

Créer :
1. _quarto.yml (book type, 10 chapitres en 4 parts + appendices, HTML cosmo+scss, PDF A4 report,
   mermaid neutral, code-fold, toc 3 niveaux, number-sections, search, fr)
2. index.qmd (préface, légende callouts, planning 10 sem, tableau poids domains)
3. styles/custom.scss (bleu marine #1a2332, bleu Cisco #049fd9, orange #ff6b35,
   callouts stylisés tip/warning/note/important, code blocks fond sombre bordure bleue,
   tableaux header bleu marine lignes alternées, responsive)
4. styles/preamble.tex (fancyhdr, xcolor, tcolorbox, listings, couleurs Cisco, headers/footers)
5. includes/before-body.tex (page de garde sobre bleu marine)
6. chapters/ stubs vides pour les 10 .qmd

Config book :
  title: 'Guide CCNA 200-301 v1.1'
  author: 'Anthony Faria Dos Santos'
  Parts : Fondamentaux (01,02), Connectivité & Services (03,04),
  Sécurité & Automatisation (05,06), Pratique (07-labs, 08-exercices, 09-exam-blanc)
  Appendices : 10-glossaire

NE PAS convertir les modules — juste structure + config + styles.
"

PROMPT_QUARTO_CONVERT="
$QUARTO_CTX

TÂCHE : Convertir les MD en .qmd dans $QUARTO_DIR/chapters/.

Sources → Destinations :
MODULE-1-*.md → 01-network-fundamentals.qmd ... MODULE-6-*.md → 06-automation.qmd
LAB-*.md (tous) → 07-labs.qmd | QUIZ-*.md + SUBNETTING-*.md → 08-exercices.qmd
EXAM-BLANC.md → 09-exam-blanc.qmd | glossaire.md → 10-glossaire.qmd

Règles conversion :
- Frontmatter YAML (title, description) — h1 module → titre frontmatter
- Headings : h2/h3/h4 sans saut de niveau, pas de h1 dans les chapitres
- Callouts : Point exam → {.callout-tip}, Attention → {.callout-warning},
  Note → {.callout-note}, Lab → {.callout-important}
- Code : \`\`\`cisco → \`\`\`{.cisco filename=\"R1\"}, outputs → \`\`\`{.default title=\"Output\"}
- <details> → ::: {.callout-note collapse=\"true\" title=\"Solution\"}
- Mermaid : <15 lignes inline \`\`\`{mermaid}, ≥15 lignes → assets/diagrams/[module]-[topic]-[desc].mmd
- Topologies ASCII → \`\`\`{.text title=\"Topologie\"}
- Cross-refs : labels {#sec-topic-N-X}, {#fig-xxx}, {#tbl-xxx}, liens @sec-topic-X-Y
- Tableaux : syntaxe pipe valide, labels si référencés
- Blocs ouverts/fermés vérifiés, UTF-8, pas de HTML brut
"

PROMPT_QUARTO_ENRICH="
$QUARTO_CTX
Lis references/visual-conventions.md.

TÂCHE : Enrichir visuellement les .qmd (chapitres 01-06 uniquement).

Pour CHAQUE chapitre :
1. DIAGRAMMES : compter les {mermaid}. Minimum : ch01,03=10 | ch02,04,05=8 | ch06=7.
   Si en dessous → AJOUTER (topologies avec IPs, sequenceDiagram, flowcharts, stateDiagram).
   Vérifier : IPs sur liens, labels messages, branches étiquetées, titre+légende.

2. CONTENU : chaque section {#sec-topic-N-X} doit avoir ≥300 mots + CLI + Point exam + exercice.
   Si manquant → AJOUTER.

3. POLISH : tableaux bien formatés, pas 2 blocs code consécutifs sans texte,
   code cisco avec filename=, icônes callouts (🎯 Point exam, 🔬 Lab, 💡 Astuce, ⚠️ Attention).

4. CROSS-REFS : ajouter @sec-topic-X-Y entre chapitres, @fig-xxx vers diagrammes.

5. LABS (ch07) : topologie Mermaid (pas juste ASCII), tableau adressage propre.

NE PAS modifier la structure ni _quarto.yml ni les styles.
"

PROMPT_QUARTO_QA="
$QUARTO_CTX

TÂCHE : Créer et exécuter $PROJECT_DIR/scripts/qa_quarto.py.

Vérifier : fichiers _quarto.yml ↔ chapters/ (pas d'orphelin), headings sans saut,
callouts ::: ouverts/fermés, mermaid fermés, .mmd référencés, images référencées,
cross-refs @sec/@fig/@tbl avec labels, code blocks fermés, couverture topics 1.1→6.7,
stats (mots/chapitre, exercices, labs, quiz, pages PDF estimées).

Output : $EXPORTS_DIR/QA-REPORT.md. Exit 0=OK, 1=erreurs, 2=warnings.
"

PROMPT_QUARTO_RENDER="
$QUARTO_CTX

TÂCHE : Rendu Quarto HTML + PDF.

1. Vérifier : quarto --version (≥1.4), tinytex installé
2. cd $QUARTO_DIR && quarto render --to html (corriger erreurs, max 5 itérations)
3. cd $QUARTO_DIR && quarto render --to pdf (gérer tableaux larges, images manquantes,
   mermaid chromium, unicode LaTeX — corriger, max 5 itérations)
4. cp -r $QUARTO_DIR/_output/* $EXPORTS_DIR/
5. Vérifier : sidebar HTML, TOC PDF, page de garde, sections numérotées, mermaid rendus
6. Créer $EXPORTS_DIR/BUILD-REPORT.md (date, version quarto, tailles, pages PDF, erreurs, statut)
"

# ============================================================================
# EXÉCUTION
# ============================================================================

main() {
    log "================================================"
    log "  CCNA Guide — Génération Autonome"
    log "  Opus=$MODEL_CONTENT | Sonnet=$MODEL_TOOLING"
    log "  Projet : $PROJECT_DIR"
    log "================================================"

    init_dirs

    if ! command -v claude &> /dev/null; then
        err "Claude Code CLI non trouvé"; exit 1
    fi
    log "Claude CLI : $(claude --version 2>/dev/null || echo 'OK')"

    MIN_SIZE=500

    # ── Phase 1 : Outline (Sonnet) ──
    if [ "$SKIP_TO" -le 0 ]; then
        if [ "$FORCE" = false ] && [ -f "$PROJECT_DIR/MASTER-OUTLINE.md" ] && [ "$(wc -c < "$PROJECT_DIR/MASTER-OUTLINE.md")" -gt $MIN_SIZE ]; then
            ok "Outline existant ($(wc -w < "$PROJECT_DIR/MASTER-OUTLINE.md")w) — skip"
            save_progress 1
        else
            log "━━━ PHASE 1 : Outline (Sonnet) ━━━"
            run_claude "01-outline" "$PROMPT_OUTLINE" "$MODEL_TOOLING"
            check_output "$PROJECT_DIR/MASTER-OUTLINE.md" "Outline"
            save_progress 1
        fi
    fi

    # ── Phase 2 : Modules 1-6 (Opus) ──
    local MINS=("" "6000" "6000" "9000" "4000" "5500" "4000")
    for N in 1 2 3 4 5 6; do
        if [ "$SKIP_TO" -le "$N" ]; then
            EXISTING=$(find "$MODULES_DIR" -name "MODULE-${N}-*.md" -size +${MIN_SIZE}c 2>/dev/null | head -1)
            if [ "$FORCE" = false ] && [ -n "$EXISTING" ]; then
                ok "Module $N existant — quality check..."
                check_quality "$EXISTING" "${MINS[$N]}" "Module $N" || \
                    warn "Module $N sous seuils. --force ou --skip-to $N pour régénérer."
                save_progress $((N + 1))
            else
                log "━━━ PHASE 2.$N : Module $N (Opus) ━━━"
                PROMPT=$(generate_module_prompt $N)
                run_claude "02-module-$N" "$PROMPT" "$MODEL_CONTENT"

                local GEN=$(find "$MODULES_DIR" -name "MODULE-${N}-*.md" -size +100c 2>/dev/null | head -1)
                [ -n "$GEN" ] && check_quality "$GEN" "${MINS[$N]}" "Module $N" || warn "Module $N sous seuils"
                save_progress $((N + 1))
                sleep 10
            fi
        fi
    done

    # ── Phase 3a : Labs (Opus) ──
    if [ "$SKIP_TO" -le 7 ]; then
        local el=$(find "$LABS_DIR" -name "LAB-*.md" -size +${MIN_SIZE}c 2>/dev/null | wc -l)
        if [ "$FORCE" = false ] && [ "$el" -ge 10 ]; then
            ok "$el labs existants — skip"
            save_progress 8
        else
            log "━━━ PHASE 3a : Labs (Opus, $el existants) ━━━"
            run_claude "03-labs" "$PROMPT_LABS" "$MODEL_CONTENT"
            ok "$(find "$LABS_DIR" -name "LAB-*.md" | wc -l) labs"
            save_progress 8
        fi
    fi

    # ── Phase 3b : Quizzes (Opus) ──
    if [ "$SKIP_TO" -le 8 ]; then
        local eq=$(find "$QUIZZES_DIR" -name "*.md" -size +${MIN_SIZE}c 2>/dev/null | wc -l)
        if [ "$FORCE" = false ] && [ "$eq" -ge 3 ]; then
            ok "$eq quizzes existants — skip"
            save_progress 9
        else
            log "━━━ PHASE 3b : Quizzes (Opus, $eq existants) ━━━"
            run_claude "04-quizzes" "$PROMPT_QUIZZES" "$MODEL_CONTENT"
            ok "$(find "$QUIZZES_DIR" -name "*.md" | wc -l) quizzes"
            save_progress 9
        fi
    fi

    # ── Phase 3c : Glossaire (Sonnet) ──
    if [ "$SKIP_TO" -le 9 ]; then
        if [ "$FORCE" = false ] && [ -f "$PROJECT_DIR/references/glossaire.md" ] && [ "$(wc -c < "$PROJECT_DIR/references/glossaire.md")" -gt $MIN_SIZE ]; then
            ok "Glossaire existant — skip"
            save_progress 10
        else
            log "━━━ PHASE 3c : Glossaire (Sonnet) ━━━"
            run_claude "05-glossaire" "$PROMPT_GLOSSAIRE" "$MODEL_TOOLING"
            check_output "$PROJECT_DIR/references/glossaire.md" "Glossaire"
            save_progress 10
        fi
    fi

    # ── Phase 4 : Assemblage (Sonnet) ──
    if [ "$SKIP_TO" -le 10 ]; then
        if [ "$FORCE" = false ] && [ -f "$EXPORTS_DIR/CCNA-GUIDE-COMPLET.md" ] && [ "$(wc -c < "$EXPORTS_DIR/CCNA-GUIDE-COMPLET.md")" -gt 10000 ]; then
            ok "Guide MD assemblé existant — skip"
            save_progress 11
        else
            log "━━━ PHASE 4 : Assemblage (Sonnet) ━━━"
            run_claude "06-assemble" "$PROMPT_ASSEMBLE" "$MODEL_TOOLING"
            check_output "$EXPORTS_DIR/CCNA-GUIDE-COMPLET.md" "Guide complet"
            save_progress 11
        fi
    fi

    # ── Phase 5a : Quarto init (Sonnet) ──
    if [ "$SKIP_TO" -le 11 ]; then
        if [ "$FORCE" = false ] && [ -f "$QUARTO_DIR/_quarto.yml" ] && [ -f "$QUARTO_DIR/styles/custom.scss" ]; then
            ok "Quarto initialisé — skip"
            save_progress 12
        else
            log "━━━ PHASE 5a : Quarto init (Sonnet) ━━━"
            run_claude "07-quarto-init" "$PROMPT_QUARTO_INIT" "$MODEL_TOOLING"
            check_output "$QUARTO_DIR/_quarto.yml" "_quarto.yml"
            save_progress 12
        fi
    fi

    # ── Phase 5b : Conversion MD→QMD (Sonnet) ──
    if [ "$SKIP_TO" -le 12 ]; then
        local eqmd=$(find "$QUARTO_DIR/chapters" -name "*.qmd" -size +${MIN_SIZE}c 2>/dev/null | wc -l)
        if [ "$FORCE" = false ] && [ "$eqmd" -ge 8 ]; then
            ok "$eqmd .qmd existants — skip"
            save_progress 13
        else
            log "━━━ PHASE 5b : MD→QMD (Sonnet, $eqmd existants) ━━━"
            run_claude "08-quarto-convert" "$PROMPT_QUARTO_CONVERT" "$MODEL_TOOLING"
            ok "$(find "$QUARTO_DIR/chapters" -name "*.qmd" | wc -l) .qmd"
            save_progress 13
        fi
    fi

    # ── Phase 5c : Enrichissement (Opus) ──
    if [ "$SKIP_TO" -le 13 ]; then
        log "━━━ PHASE 5c : Enrichissement visuel (Opus) ━━━"
        run_claude "09-quarto-enrich" "$PROMPT_QUARTO_ENRICH" "$MODEL_CONTENT"
        save_progress 14
    fi

    # ── Phase 5d : QA (Sonnet) ──
    if [ "$SKIP_TO" -le 14 ]; then
        log "━━━ PHASE 5d : QA (Sonnet) ━━━"
        run_claude "10-quarto-qa" "$PROMPT_QUARTO_QA" "$MODEL_TOOLING"
        save_progress 15
    fi

    # ── Phase 5e : Render (Sonnet) ──
    if [ "$SKIP_TO" -le 15 ]; then
        log "━━━ PHASE 5e : Render HTML+PDF (Sonnet) ━━━"
        run_claude "11-quarto-render" "$PROMPT_QUARTO_RENDER" "$MODEL_TOOLING"
        save_progress 16
    fi

    rm -f "$PROGRESS_FILE"

    # ── Récapitulatif ──
    log "================================================"
    log "  RÉCAPITULATIF"
    log "================================================"

    [ -f "$EXPORTS_DIR/CCNA-GUIDE-COMPLET.md" ] && {
        local tw=$(wc -w < "$EXPORTS_DIR/CCNA-GUIDE-COMPLET.md")
        ok "Guide MD : ${tw}w (~$((tw / 350)) pages)"
    }

    local tm=$(find "$MODULES_DIR" -name "MODULE-*.md" 2>/dev/null | wc -l)
    local tl=$(find "$LABS_DIR" -name "LAB-*.md" 2>/dev/null | wc -l)
    local tq=$(find "$QUIZZES_DIR" -name "*.md" 2>/dev/null | wc -l)
    local tc=$(find "$QUARTO_DIR/chapters" -name "*.qmd" 2>/dev/null | wc -l)
    local tmm=$(grep -r '```{mermaid}' "$QUARTO_DIR/chapters/" 2>/dev/null | wc -l || echo 0)
    local tmd=$(find "$QUARTO_DIR/assets/diagrams" -name "*.mmd" 2>/dev/null | wc -l)

    echo ""
    echo "  📄 Modules  : $tm / 6"
    echo "  🔬 Labs     : $tl"
    echo "  📝 Quizzes  : $tq"
    echo "  📘 QMD      : $tc .qmd"
    echo "  📊 Mermaid  : $tmm inline + $tmd .mmd"
    echo ""

    if [ -d "$QUARTO_DIR/_output" ]; then
        local hx=$(find "$QUARTO_DIR/_output" -name "index.html" 2>/dev/null | head -1)
        local px=$(find "$QUARTO_DIR/_output" -name "*.pdf" 2>/dev/null | head -1)
        [ -n "$hx" ] && ok "HTML : $hx" || warn "HTML non trouvé"
        [ -n "$px" ] && ok "PDF  : $px" || warn "PDF non trouvé"
    fi

    echo ""
    ok "Terminé !"
    log "Logs : $LOGS_DIR/"
}

main "$@"
