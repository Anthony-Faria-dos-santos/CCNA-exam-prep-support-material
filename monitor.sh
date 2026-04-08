#!/bin/bash
# ============================================================================
# monitor.sh — Dashboard live pour orchestrate.sh (compatible Git Bash)
# Usage : ouvrir un 2eme Git Bash :
#   cd ccna-guide && bash monitor.sh
# ============================================================================

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROGRESS_FILE="$PROJECT_DIR/.progress"
LOGS_DIR="$PROJECT_DIR/logs"
MODULES_DIR="$PROJECT_DIR/modules"
LABS_DIR="$PROJECT_DIR/labs"
QUIZZES_DIR="$PROJECT_DIR/quizzes"
QUARTO_DIR="$PROJECT_DIR/book"
EXPORTS_DIR="$PROJECT_DIR/exports"

STEP_NAMES=(
    "Outline"
    "Module 1 - Network Fundamentals"
    "Module 2 - Network Access"
    "Module 3 - IP Connectivity"
    "Module 4 - IP Services"
    "Module 5 - Security Fundamentals"
    "Module 6 - Automation"
    "Labs (16 fichiers)"
    "Quizzes + Exam blanc"
    "Glossaire"
    "Assemblage MD"
    "Quarto init"
    "MD -> QMD"
    "Enrichissement visuel"
    "QA Quarto"
    "Render HTML+PDF"
)

STEP_LOGS=(
    "01-outline"
    "02-module-1" "02-module-2" "02-module-3"
    "02-module-4" "02-module-5" "02-module-6"
    "03-labs" "04-quizzes" "05-glossaire" "06-assemble"
    "07-quarto-init" "08-quarto-convert" "09-quarto-enrich"
    "10-quarto-qa" "11-quarto-render"
)

STEP_MODELS=(
    "Sonnet" "Opus" "Opus" "Opus" "Opus" "Opus" "Opus"
    "Opus" "Opus" "Sonnet" "Sonnet" "Sonnet" "Sonnet"
    "Opus" "Sonnet" "Sonnet"
)

get_file_age() {
    local f="$1"
    [ ! -f "$f" ] && echo "9999" && return
    local now fmod
    now=$(date +%s)
    fmod=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null || echo "0")
    echo $(( now - fmod ))
}

show_dashboard() {
    clear
    local current now total pct filled empty bar
    current=$(cat "$PROGRESS_FILE" 2>/dev/null || echo "0")
    now=$(date '+%H:%M:%S')
    total=${#STEP_NAMES[@]}

    printf "\n"
    printf "  ========================================================\n"
    printf "    CCNA Guide - Pipeline Monitor              %s\n" "$now"
    printf "  ========================================================\n\n"

    local i
    for i in $(seq 0 $((total - 1))); do
        local name="${STEP_NAMES[$i]}"
        local logname="${STEP_LOGS[$i]}"
        local model="${STEP_MODELS[$i]}"
        local log_file="$LOGS_DIR/${logname}.log"
        local icon status

        if [ "$i" -lt "$current" ]; then
            icon="[OK]"
            status="done"
        elif [ "$i" -eq "$current" ]; then
            if [ -f "$log_file" ]; then
                local age
                age=$(get_file_age "$log_file")
                if grep -qi "rate.limit\|out of.*usage\|resets" "$log_file" 2>/dev/null; then
                    icon="[ZZ]"
                    status="rate-limit"
                elif [ "$age" -lt 180 ]; then
                    icon="[>>]"
                    status="running"
                else
                    icon="[..]"
                    status="stale"
                fi
            else
                icon="[>>]"
                status="starting"
            fi
        else
            icon="[  ]"
            status="pending"
        fi

        case "$status" in
            done)
                printf "  \033[32m%-5s %2d  %-38s  %s\033[0m\n" "$icon" "$i" "$name" "$model"
                ;;
            running|starting)
                printf "  \033[1;36m%-5s %2d  %-38s  %s  << ACTIF\033[0m\n" "$icon" "$i" "$name" "$model"
                ;;
            rate-limit)
                printf "  \033[1;33m%-5s %2d  %-38s  %s  ** RATE LIMIT **\033[0m\n" "$icon" "$i" "$name" "$model"
                ;;
            stale)
                printf "  \033[33m%-5s %2d  %-38s  %s  (pause?)\033[0m\n" "$icon" "$i" "$name" "$model"
                ;;
            pending)
                printf "  \033[2m%-5s %2d  %-38s  %s\033[0m\n" "$icon" "$i" "$name" "$model"
                ;;
        esac
    done

    # Barre de progression
    pct=0
    [ "$total" -gt 0 ] && pct=$(( current * 100 / total ))
    filled=$(( pct / 5 ))
    empty=$(( 20 - filled ))
    bar=""
    for i in $(seq 1 $filled); do bar="${bar}#"; done
    for i in $(seq 1 $empty); do bar="${bar}-"; done

    printf "\n  Progression : [%s] %d%%  (%d/%d)\n" "$bar" "$pct" "$current" "$total"

    # Stats
    printf "\n  --------------------------------------------------------\n"
    local nm nl nq nc
    nm=$(find "$MODULES_DIR" -name "MODULE-*.md" -size +500c 2>/dev/null | wc -l | tr -d ' ')
    nl=$(find "$LABS_DIR" -name "LAB-*.md" -size +500c 2>/dev/null | wc -l | tr -d ' ')
    nq=$(find "$QUIZZES_DIR" -name "*.md" -size +500c 2>/dev/null | wc -l | tr -d ' ')
    nc=$(find "$QUARTO_DIR/chapters" -name "*.qmd" -size +500c 2>/dev/null | wc -l | tr -d ' ')
    printf "  Modules: %s/6  |  Labs: %s  |  Quiz: %s  |  QMD: %s\n" "$nm" "$nl" "$nq" "$nc"

    local html pdf
    html=$(find "$QUARTO_DIR/_output" -name "index.html" 2>/dev/null | head -1)
    pdf=$(find "$QUARTO_DIR/_output" -name "*.pdf" 2>/dev/null | head -1)
    [ -n "$html" ] && printf "  \033[32mHTML book : OK\033[0m\n"
    [ -n "$pdf" ]  && printf "  \033[32mPDF : OK (%s)\033[0m\n" "$(du -h "$pdf" 2>/dev/null | cut -f1)"

    # Log actif
    printf "\n  --------------------------------------------------------\n"
    if [ "$current" -lt "$total" ]; then
        local current_log="$LOGS_DIR/${STEP_LOGS[$current]}.log"
        printf "  Log [%s] :\n" "${STEP_LOGS[$current]}"
        if [ -f "$current_log" ]; then
            tail -3 "$current_log" 2>/dev/null | while IFS= read -r line; do
                printf "  \033[2m  %.62s\033[0m\n" "$line"
            done
        else
            printf "  \033[2m  (en attente)\033[0m\n"
        fi
    else
        printf "  \033[32m  Pipeline termine !\033[0m\n"
    fi

    printf "\n  --------------------------------------------------------\n"
    printf "  Refresh 15s | Ctrl+C = quitter (pipeline continue)\n"
    printf "  ========================================================\n"
}

printf "Monitor demarre. Ctrl+C pour quitter.\n"
while true; do
    show_dashboard
    sleep 15
done
