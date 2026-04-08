# Module {N} — {Domain Name}

> **Domain** : {N} — {Domain Name} | **Poids examen** : {XX}%
> **Durée estimée** : {X} semaine(s) | **Prérequis** : {Module(s) ou "Aucun"}
> **Topics couverts** : {N.1} à {N.X}

## Objectif du module

À l'issue de ce module, vous serez capable de :
- {Objectif 1 avec verbe d'action}
- {Objectif 2}
- {Objectif 3}

---

## {N.X} — {Topic Title}

> **Exam topic {N.X}** : _{Verbe Cisco}_ — {Description officielle}_
> **Niveau** : {Identify|Describe|Explain|Compare|Configure|Verify|Interpret}

### Contexte

{2-3 lignes : pourquoi ce sujet compte dans un réseau d'entreprise réel}

### Théorie

{Contenu détaillé. Utiliser des analogies pour les concepts abstraits.
Inclure au moins un tableau ou schéma par sous-section majeure.}

#### Schéma : {Titre du diagramme}

```
{Description textuelle ASCII du diagramme}
{Ou placeholder : [DIAGRAMME : description pour insertion ultérieure]}
```

### Mise en pratique CLI

```cisco
! {Contexte : sur quel équipement, quelle situation}
{Commande 1}
{Commande 2}
```

**Output attendu :**
```
{Output réaliste de la commande show correspondante}
```

**Interprétation** : {Explication de chaque champ important de l'output}

### Point exam

> **Piège courant** : {Description du piège fréquent sur ce topic}
>
> **À retenir** : {Fait critique à mémoriser pour l'examen}

### Exercice {N.X.1} — {Titre}

**Contexte** : {Scénario réseau — entreprise fictive, topologie}

**Consigne** : {Ce que l'étudiant doit faire — objectif mesurable}

**Indice** : <details><summary>Voir l'indice</summary>{Aide}</details>

<details>
<summary>Solution</summary>

```cisco
{Configuration/commandes solution}
```

**Explication** : {Pourquoi cette solution fonctionne}

</details>

### Voir aussi

- Topic {X.Y} dans Module {M} (relation : {description})

---

{Répéter la structure pour chaque topic du module}

---

## Labs Module {N}

### Lab {N}.1 — {Titre du lab}

**Topologie :**
```
{Diagramme ASCII de la topologie réseau}
{Exemple :}
{  [PC1]---[SW1]---[R1]---[R2]---[SW2]---[PC2]  }
```

**Tableau d'adressage :**

| Équipement | Interface | Adresse IP | Masque | Passerelle |
|------------|-----------|-----------|--------|------------|
| R1 | Gi0/0 | 192.168.1.1 | 255.255.255.0 | — |
| PC1 | NIC | 192.168.1.10 | 255.255.255.0 | 192.168.1.1 |

**Objectifs :**
1. {Objectif mesurable 1}
2. {Objectif mesurable 2}

**Configuration de départ :**
```cisco
! Router R1
hostname R1
no ip domain-lookup
!
interface GigabitEthernet0/0
 description {description}
 ip address {ip} {mask}
 no shutdown
```

**Étapes :**

1. **{Titre étape 1}**
   - {Instruction détaillée}
   - Commande : `{commande exacte}`
   - Vérification : `{commande show}`

2. **{Titre étape 2}**
   - {Instruction détaillée}

**Vérification finale :**
```cisco
{Commandes de vérification avec output attendu}
```

**Questions de validation :**
1. {Question de compréhension — pourquoi ?}
2. {Question what-if — que se passe-t-il si ?}

---

## Quiz Module {N} — {X} questions

**Q1.** {Énoncé de la question} _(Topic {N.X})_

- A) {Option A}
- B) {Option B}
- C) {Option C}
- D) {Option D}

<details>
<summary>Réponse</summary>

**{Lettre}** — {Explication complète : pourquoi cette réponse est correcte
ET pourquoi chaque autre option est incorrecte.}

</details>

---

## Récapitulatif Module {N}

| Topic | Concept clé | Commande(s) essentielles |
|-------|------------|--------------------------|
| {N.1} | {Résumé 1 ligne} | `{commande}` |
| {N.2} | {Résumé 1 ligne} | `{commande}` |

**Check-list avant de passer au Module {N+1} :**
- [ ] Je sais {compétence 1}
- [ ] Je sais {compétence 2}
- [ ] J'ai complété les {X} exercices
- [ ] J'ai réalisé les {X} labs
- [ ] J'ai obtenu >{70%} au quiz
