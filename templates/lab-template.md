# Lab {MODULE}.{NUM} — {Titre}

> **Module** : {N} — {Domain Name}
> **Topics couverts** : {N.X, N.Y}
> **Difficulté** : {Débutant | Intermédiaire | Avancé}
> **Durée estimée** : {XX} minutes
> **Outil** : Cisco Packet Tracer / GNS3

## Topologie

```
     [PC1]                          [PC2]
       |                              |
   Fa0/1                          Fa0/1
   [SW1]----Gi0/1------Gi0/1----[SW2]
       \                          /
    Gi0/0                    Gi0/0
        \                      /
         [R1]----Se0/0----[R2]
```

## Tableau d'adressage

| Équipement | Interface | Adresse IP | Masque | Passerelle | VLAN |
|------------|-----------|-----------|--------|------------|------|
| R1 | Gi0/0 | — | — | — | — |
| R1 | Se0/0 | — | — | — | — |
| SW1 | VLAN 1 | — | — | — | — |
| PC1 | NIC | — | — | — | — |

> À compléter par l'étudiant selon les consignes.

## Objectifs

1. {Objectif opérationnel 1 — verbe d'action + résultat attendu}
2. {Objectif opérationnel 2}
3. {Objectif de vérification — commandes show attendues}

## Prérequis

- Module {N}, sections {N.X} à {N.Y} complétées
- Packet Tracer {version minimum} installé

## Configuration de départ

> Copier-coller dans chaque équipement ou charger le fichier .pkt fourni.

```cisco
! === R1 ===
enable
configure terminal
hostname R1
no ip domain-lookup
line console 0
 logging synchronous
 exec-timeout 30 0
exit
banner motd #Lab {MODULE}.{NUM} - R1#
```

## Partie 1 : {Titre section}

### Étape 1 — {Action}

{Explication de ce qu'on fait et pourquoi.}

```cisco
{Commandes exactes}
```

### Étape 2 — {Action}

{Explication.}

```cisco
{Commandes exactes}
```

### Vérification Partie 1

```cisco
{Commande show}
```

**Output attendu :**
```
{Output réaliste}
```

{Interprétation : que confirme cet output ?}

## Partie 2 : {Titre section}

{Même structure...}

## Vérification finale

Exécuter les commandes suivantes et vérifier les résultats :

```cisco
show ip interface brief
show running-config | section interface
show {protocole} {détail}
ping {destination}
traceroute {destination}
```

**Critères de réussite :**
- [ ] {Critère mesurable 1}
- [ ] {Critère mesurable 2}
- [ ] {Critère mesurable 3}

## Questions de réflexion

1. **Pourquoi** : {Question sur le fonctionnement — teste la compréhension}
2. **What-if** : {Que se passe-t-il si on modifie X ?}
3. **Troubleshoot** : {Si le ping échoue vers Y, quelles commandes utilisez-vous ?}

<details>
<summary>Réponses</summary>

1. {Réponse détaillée}
2. {Réponse détaillée}
3. {Réponse détaillée}

</details>

## Solution complète

<details>
<summary>Voir la configuration complète</summary>

```cisco
! === R1 — Configuration finale ===
{Config complète}

! === R2 — Configuration finale ===
{Config complète}

! === SW1 — Configuration finale ===
{Config complète}
```

</details>
