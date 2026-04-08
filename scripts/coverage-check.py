#!/usr/bin/env python3
"""
coverage-check.py — Vérifie la couverture des exam topics CCNA dans le guide.

Usage : python3 scripts/coverage-check.py [--verbose]
"""
import re, os, sys, json

TOPICS_FILE = "references/exam-topics.md"
MODULES_DIR = "modules"

def extract_topic_ids(filepath):
    """Extrait les topic IDs (format N.N ou N.N.x) depuis un fichier."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    # Capturer les IDs principaux (1.1, 2.3, etc.) et sous-topics (1.1.a, 2.2.b)
    main_ids = set(re.findall(r'(?:^|\s)(\d+\.\d+)(?:\s|$|\.)', content, re.MULTILINE))
    sub_ids = set(re.findall(r'(\d+\.\d+\.[a-z])', content))
    return main_ids, sub_ids

def scan_modules(modules_dir):
    """Scanne tous les modules et collecte les topic IDs couverts."""
    covered_main = set()
    covered_sub = set()
    module_coverage = {}
    
    for fname in sorted(os.listdir(modules_dir)):
        if not fname.endswith('.md'):
            continue
        filepath = os.path.join(modules_dir, fname)
        main_ids, sub_ids = extract_topic_ids(filepath)
        covered_main.update(main_ids)
        covered_sub.update(sub_ids)
        module_coverage[fname] = {'main': main_ids, 'sub': sub_ids}
    
    return covered_main, covered_sub, module_coverage

def main():
    verbose = '--verbose' in sys.argv
    
    if not os.path.exists(TOPICS_FILE):
        print(f"ERREUR : {TOPICS_FILE} introuvable. Exécuter depuis la racine du projet.")
        sys.exit(2)
    
    if not os.path.exists(MODULES_DIR):
        print(f"ERREUR : {MODULES_DIR}/ introuvable.")
        sys.exit(2)
    
    # Extraire les topics attendus
    expected_main, expected_sub = extract_topic_ids(TOPICS_FILE)
    
    # Scanner les modules
    covered_main, covered_sub, module_coverage = scan_modules(MODULES_DIR)
    
    # Calcul couverture
    missing_main = expected_main - covered_main
    missing_sub = expected_sub - covered_sub
    extra_main = covered_main - expected_main
    
    total_expected = len(expected_main)
    total_covered = len(expected_main - missing_main)
    pct = (total_covered / total_expected * 100) if total_expected > 0 else 0
    
    # Rapport
    print("=" * 60)
    print(f"CCNA Guide — Rapport de couverture")
    print("=" * 60)
    print(f"\nTopics principaux : {total_covered}/{total_expected} couverts ({pct:.1f}%)")
    
    if missing_main:
        print(f"\n⚠️  Topics MANQUANTS ({len(missing_main)}) :")
        for tid in sorted(missing_main, key=lambda x: [int(n) for n in x.split('.')]):
            print(f"   ❌ {tid}")
    
    if verbose and module_coverage:
        print(f"\n--- Couverture par module ---")
        for fname, data in module_coverage.items():
            print(f"\n📄 {fname}")
            print(f"   Topics : {', '.join(sorted(data['main']))}")
    
    if extra_main:
        print(f"\nℹ️  Topics hors-syllabus trouvés : {', '.join(sorted(extra_main))}")
    
    print("\n" + "=" * 60)
    
    if missing_main:
        print(f"❌ INCOMPLET — {len(missing_main)} topic(s) manquant(s)")
        sys.exit(1)
    else:
        print("✅ COUVERTURE COMPLÈTE — Tous les exam topics sont couverts")
        sys.exit(0)

if __name__ == '__main__':
    main()
