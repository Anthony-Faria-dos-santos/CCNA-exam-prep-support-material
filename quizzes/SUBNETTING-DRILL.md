# Subnetting Drill — 50 exercices progressifs

> **Topics** : 1.6, 1.7, 3.2, 5.6 | **Exercices** : 50
> **Objectif** : Maîtriser le subnetting IPv4 de la base au VLSM avancé
> **Temps cible** : Résoudre chaque exercice en moins de 60 secondes à l'examen

---

## Conseils méthodologiques

### La méthode rapide du "magic number"

Pour tout exercice de subnetting, la technique la plus rapide repose sur le **nombre magique** (magic number) :

1. **Identifier l'octet intéressant** : celui où le masque n'est ni 255 ni 0.
2. **Calculer le magic number** : `256 - valeur du masque dans cet octet`.
3. **L'adresse réseau** est le plus grand multiple du magic number inférieur ou égal à la valeur de l'octet intéressant de l'IP.
4. **L'adresse broadcast** = adresse réseau + magic number - 1.

**Exemple** : 172.16.45.200 /20

- Masque /20 = 255.255.**240**.0 -- l'octet intéressant est le 3e
- Magic number = 256 - 240 = **16**
- Octet intéressant de l'IP = 45
- Plus grand multiple de 16 <= 45 : 16 x 2 = 32 -- adresse réseau = 172.16.**32**.0
- Broadcast = 172.16.32+16-1.255 = 172.16.**47**.255

### Puissances de 2 a connaitre par coeur

| Exposant | Valeur | Masque CIDR associé (dans l'octet) |
|----------|--------|------------------------------------|
| 2^1 = 2 | /31 (128) | 2 adresses |
| 2^2 = 4 | /30 (192) | 4 adresses, 2 hotes |
| 2^3 = 8 | /29 (224) | 8 adresses, 6 hotes |
| 2^4 = 16 | /28 (240) | 16 adresses, 14 hotes |
| 2^5 = 32 | /27 (224) | 32 adresses, 30 hotes |
| 2^6 = 64 | /26 (192) | 64 adresses, 62 hotes |
| 2^7 = 128 | /25 (128) | 128 adresses, 126 hotes |
| 2^8 = 256 | /24 (0) | 256 adresses, 254 hotes |

### Formules essentielles

- **Nombre d'hotes utilisables** = 2^(32 - préfixe) - 2
- **Nombre de sous-réseaux** = 2^(bits empruntés)
- **Wildcard mask** = 255.255.255.255 - masque de sous-réseau

### Astuce examen

A l'examen, **ne convertissez pas tout en binaire**. Utilisez le magic number pour aller vite. Ne passez en binaire que quand vous devez vérifier un résultat douteux ou quand l'exercice porte sur des conversions explicites.

---

## Niveau 1 — Basique (exercices 1-10)

### Exercice 1 — Conversion décimale vers binaire

**Énoncé** : Vous configurez un routeur et devez vérifier un masque de sous-réseau.

**Question** : Convertissez le nombre décimal 192 en binaire (8 bits).

<details>
<summary>Solution</summary>

**Réponse** : `11000000`

**Méthode de résolution** :

Diviser par 2 successivement et noter les restes :
```
192 / 2 = 96  reste 0
 96 / 2 = 48  reste 0
 48 / 2 = 24  reste 0
 24 / 2 = 12  reste 0
 12 / 2 =  6  reste 0
  6 / 2 =  3  reste 0
  3 / 2 =  1  reste 1
  1 / 2 =  0  reste 1
```
Lire les restes de bas en haut : **11000000**

Ou plus rapide, utiliser les puissances de 2 :
```
128  64  32  16   8   4   2   1
  1   1   0   0   0   0   0   0   = 128 + 64 = 192 ✓
```

**Vérification** : 128 + 64 = 192 ✓

</details>

---

### Exercice 2 — Conversion binaire vers décimale

**Énoncé** : Dans un dump réseau, vous lisez un octet en binaire.

**Question** : Convertissez `10101100` en décimal.

<details>
<summary>Solution</summary>

**Réponse** : `172`

**Méthode de résolution** :

```
Position :  128  64  32  16   8   4   2   1
Bits :        1   0   1   0   1   1   0   0
```

Additionner les positions où le bit vaut 1 :
128 + 32 + 8 + 4 = **172**

**Vérification** : 172 correspond au premier octet de la plage 172.16.0.0 -- 172.31.255.255 (classe B privée), ce qui est cohérent.

</details>

---

### Exercice 3 — Masque CIDR vers décimale pointée

**Énoncé** : Un collègue vous donne un réseau en notation CIDR : 10.0.0.0/18.

**Question** : Quel est le masque de sous-réseau en notation décimale pointée ?

<details>
<summary>Solution</summary>

**Réponse** : `255.255.192.0`

**Méthode de résolution** :

/18 signifie 18 bits à 1 suivis de 14 bits à 0 :
```
11111111.11111111.11000000.00000000
```

Conversion octet par octet :
- Octet 1 : 11111111 = 255
- Octet 2 : 11111111 = 255
- Octet 3 : 11000000 = 128 + 64 = 192
- Octet 4 : 00000000 = 0

Masque : **255.255.192.0**

**Vérification** : /16 = 255.255.0.0, /24 = 255.255.255.0, /18 est entre les deux avec 2 bits de plus que /16, donc le 3e octet = 192, ce qui est cohérent.

</details>

---

### Exercice 4 — Masque décimal vers CIDR

**Énoncé** : Sur un switch, vous relevez le masque 255.255.240.0.

**Question** : Quelle est la notation CIDR correspondante ?

<details>
<summary>Solution</summary>

**Réponse** : `/20`

**Méthode de résolution** :

Convertir chaque octet en binaire :
```
255 = 11111111  (8 bits à 1)
255 = 11111111  (8 bits à 1)
240 = 11110000  (4 bits à 1)
  0 = 00000000  (0 bits à 1)
```

Total de bits à 1 : 8 + 8 + 4 + 0 = **20**

Notation CIDR : **/20**

**Vérification** : /20 correspond à un bloc de 2^12 = 4096 adresses, soit 16 sous-réseaux de /24. 256/16 = 16, et 256 - 240 = 16. Cohérent.

</details>

---

### Exercice 5 — Classe d'adresse et type

**Énoncé** : Vous analysez le trafic réseau et observez les adresses suivantes.

**Question** : Pour chaque adresse, identifiez la classe (A, B, C, D ou E) et si elle est publique, privée ou spéciale :

1. 10.200.15.1
2. 191.255.0.1
3. 172.20.0.1
4. 224.0.0.5
5. 192.168.1.1

<details>
<summary>Solution</summary>

**Réponse** :

| Adresse | Classe | Type |
|---------|--------|------|
| 10.200.15.1 | A | Privée (10.0.0.0/8) |
| 191.255.0.1 | B | Publique |
| 172.20.0.1 | B | Privée (172.16.0.0/12) |
| 224.0.0.5 | D | Multicast (OSPF All Routers) |
| 192.168.1.1 | C | Privée (192.168.0.0/16) |

**Méthode de résolution** :

Regarder le premier octet en binaire :
```
  10 = 0_0001010  → commence par 0     → Classe A (1-126)
 191 = 1_0111111  → commence par 10    → Classe B (128-191)
 172 = 1_0101100  → commence par 10    → Classe B (128-191)
 224 = 1_1100000  → commence par 1110  → Classe D (224-239)
 192 = 1_1000000  → commence par 110   → Classe C (192-223)
```

Plages privées (RFC 1918) :
- Classe A : 10.0.0.0 -- 10.255.255.255
- Classe B : 172.16.0.0 -- 172.31.255.255
- Classe C : 192.168.0.0 -- 192.168.255.255

**Vérification** : 172.20 est bien dans la plage 172.16-31, donc privée. 191.255 n'est pas dans 172.16-31, donc publique.

</details>

---

### Exercice 6 — Adresse réseau

**Énoncé** : Un poste a l'adresse IP 172.16.45.200 avec un masque /20.

**Question** : Quelle est l'adresse réseau de ce sous-réseau ?

<details>
<summary>Solution</summary>

**Réponse** : `172.16.32.0`

**Méthode de résolution** :

1. Masque /20 = 255.255.240.0 -- l'octet intéressant est le 3e (240)
2. Magic number = 256 - 240 = **16**
3. Octet intéressant de l'IP = 45
4. Plus grand multiple de 16 inférieur ou égal à 45 : 16 x 2 = 32 (16 x 3 = 48 > 45)

Adresse réseau : **172.16.32.0**

Vérification en binaire :
```
IP :     10101100.00010000.00101101.11001000  (172.16.45.200)
Masque : 11111111.11111111.11110000.00000000  (/20)
AND :    10101100.00010000.00100000.00000000  = 172.16.32.0 ✓
```

**Vérification** : Le prochain sous-réseau serait 172.16.48.0. L'IP 172.16.45.200 est bien entre 172.16.32.0 et 172.16.47.255.

</details>

---

### Exercice 7 — Adresse de broadcast

**Énoncé** : Le réseau 192.168.10.64/26 est utilisé dans un VLAN.

**Question** : Quelle est l'adresse de broadcast de ce sous-réseau ?

<details>
<summary>Solution</summary>

**Réponse** : `192.168.10.127`

**Méthode de résolution** :

1. Masque /26 = 255.255.255.192 -- l'octet intéressant est le 4e (192)
2. Magic number = 256 - 192 = **64**
3. L'adresse réseau est 192.168.10.64 (déjà donnée, multiple de 64)
4. Broadcast = adresse réseau + magic number - 1 = 64 + 64 - 1 = **127**

Broadcast : **192.168.10.127**

Vérification en binaire :
```
Réseau :    11000000.10101000.00001010.01000000  (192.168.10.64)
Broadcast : 11000000.10101000.00001010.01111111  (192.168.10.127)
```
On met tous les bits hôte à 1 → les 6 derniers bits passent à 111111 = 63, donc 64 + 63 = 127. ✓

**Vérification** : Le sous-réseau suivant commence à 192.168.10.128. Le broadcast doit être l'adresse juste avant : 192.168.10.127. ✓

</details>

---

### Exercice 8 — Nombre d'hotes utilisables

**Énoncé** : Vous devez dimensionner un VLAN pour un département.

**Question** : Combien d'hotes utilisables peut-on placer dans un sous-réseau /27 ? Et dans un /21 ?

<details>
<summary>Solution</summary>

**Réponse** :
- /27 : **30 hotes**
- /21 : **2046 hotes**

**Méthode de résolution** :

Formule : Hotes utilisables = 2^(32 - préfixe) - 2

Pour /27 :
- Bits hôte = 32 - 27 = 5
- 2^5 = 32 adresses totales
- 32 - 2 = **30 hotes utilisables** (on retire réseau et broadcast)

Pour /21 :
- Bits hôte = 32 - 21 = 11
- 2^11 = 2048 adresses totales
- 2048 - 2 = **2046 hotes utilisables**

**Vérification** : Un /27 a un magic number de 32 (256-224), ce qui donne bien 32 adresses dans le bloc. Un /21 a 8 fois plus d'adresses qu'un /24 (2048 vs 256). ✓

</details>

---

### Exercice 9 — Premiere et derniere adresse hote

**Énoncé** : Le réseau 10.50.128.0/17 est attribué à une filiale.

**Question** : Donnez la premiere et la derniere adresse hote utilisable de ce réseau.

<details>
<summary>Solution</summary>

**Réponse** :
- Premiere adresse hote : **10.50.128.1**
- Derniere adresse hote : **10.50.255.254**

**Méthode de résolution** :

1. Masque /17 = 255.255.128.0 -- l'octet intéressant est le 3e (128)
2. Magic number = 256 - 128 = **128**
3. L'adresse réseau est 10.50.128.0 (donnée, et 128 est bien un multiple de 128)
4. Broadcast = 10.50.(128 + 128 - 1).255 = 10.50.**255**.255

En binaire :
```
Réseau :    00001010.00110010.10000000.00000000  (10.50.128.0)
Broadcast : 00001010.00110010.11111111.11111111  (10.50.255.255)
```

- Premiere hote = adresse réseau + 1 = **10.50.128.1**
- Derniere hote = broadcast - 1 = **10.50.255.254**

**Vérification** : Ce sous-réseau contient 2^15 = 32768 adresses (de .128.0 à .255.255). Premier hote = .128.1, dernier hote = .255.254. ✓

</details>

---

### Exercice 10 — Synthese niveau 1

**Énoncé** : Un serveur a l'adresse 172.30.96.14/21.

**Question** : Determinez :
1. L'adresse réseau
2. L'adresse de broadcast
3. La premiere adresse hote
4. La derniere adresse hote
5. Le nombre d'hotes utilisables
6. Le masque en notation décimale pointée

<details>
<summary>Solution</summary>

**Réponse** :

| Élément | Valeur |
|---------|--------|
| Adresse réseau | 172.30.96.0 |
| Broadcast | 172.30.103.255 |
| Premiere hote | 172.30.96.1 |
| Derniere hote | 172.30.103.254 |
| Hotes utilisables | 2046 |
| Masque décimal | 255.255.248.0 |

**Méthode de résolution** :

1. /21 → masque = 255.255.248.0 (octet intéressant = 3e, valeur 248)
2. Magic number = 256 - 248 = **8**
3. Octet intéressant de l'IP = 96
4. Plus grand multiple de 8 <= 96 : 8 x 12 = **96** (c'est exactement un multiple !)
5. Adresse réseau = 172.30.**96**.0
6. Broadcast = 172.30.(96 + 8 - 1).255 = 172.30.**103**.255
7. Premiere hote = 172.30.96.**1**
8. Derniere hote = 172.30.103.**254**
9. Hotes = 2^(32-21) - 2 = 2^11 - 2 = 2048 - 2 = **2046**

Vérification binaire :
```
IP :        10101100.00011110.01100000.00001110  (172.30.96.14)
Masque :    11111111.11111111.11111000.00000000  (/21)
AND :       10101100.00011110.01100000.00000000  = 172.30.96.0 ✓
Broadcast : 10101100.00011110.01100111.11111111  = 172.30.103.255 ✓
```

**Vérification** : Le prochain sous-réseau serait 172.30.104.0. L'IP 172.30.96.14 est bien dans [96.0 -- 103.255]. ✓

</details>

---

## Niveau 2 — Subnetting standard (exercices 11-20)

### Exercice 11 — Nombre de sous-réseaux

**Énoncé** : Vous découpez le réseau de classe B 172.16.0.0/16 avec le masque 255.255.240.0.

**Question** : Combien de sous-réseaux sont créés ? Combien d'hotes par sous-réseau ?

<details>
<summary>Solution</summary>

**Réponse** :
- **16 sous-réseaux**
- **4094 hotes par sous-réseau**

**Méthode de résolution** :

Le masque par défaut de classe B est /16. Le nouveau masque est /20.

Bits empruntés = 20 - 16 = **4 bits**

```
Masque classful :  11111111.11111111.00000000.00000000  (/16)
Nouveau masque :   11111111.11111111.11110000.00000000  (/20)
                                      ^^^^
                                  4 bits empruntés
```

- Nombre de sous-réseaux = 2^4 = **16**
- Bits hôte restants = 32 - 20 = 12
- Hotes par sous-réseau = 2^12 - 2 = **4094**

**Vérification** : 16 sous-réseaux x 4096 adresses = 65536 = 2^16 adresses au total, ce qui correspond à un /16. ✓

</details>

---

### Exercice 12 — Trouver le sous-réseau d'appartenance

**Énoncé** : Dans un réseau d'entreprise, un poste a l'adresse 10.72.155.30/21.

**Question** : A quel sous-réseau appartient cette adresse ? Quel est le broadcast de ce sous-réseau ?

<details>
<summary>Solution</summary>

**Réponse** :
- Sous-réseau : **10.72.152.0/21**
- Broadcast : **10.72.159.255**

**Méthode de résolution** :

1. /21 → masque 255.255.248.0 → octet intéressant = 3e (248)
2. Magic number = 256 - 248 = **8**
3. Octet intéressant de l'IP = 155
4. Plus grand multiple de 8 <= 155 : 8 x 19 = **152** (8 x 20 = 160 > 155)

Sous-réseau = 10.72.**152**.0
Broadcast = 10.72.(152 + 8 - 1).255 = 10.72.**159**.255

Vérification binaire :
```
IP :     00001010.01001000.10011011.00011110  (10.72.155.30)
Masque : 11111111.11111111.11111000.00000000  (/21)
AND :    00001010.01001000.10011000.00000000  = 10.72.152.0 ✓
```

**Vérification** : 155 est bien entre 152 et 159. ✓

</details>

---

### Exercice 13 — Lister les sous-réseaux

**Énoncé** : Le réseau 192.168.5.0/24 est découpé en sous-réseaux de taille /28.

**Question** : Listez les 4 premiers et les 4 derniers sous-réseaux avec leur plage d'hotes.

<details>
<summary>Solution</summary>

**Réponse** :

Nombre total de sous-réseaux = 2^(28-24) = 2^4 = **16 sous-réseaux**

| # | Sous-réseau | Premiere hote | Derniere hote | Broadcast |
|---|-------------|---------------|---------------|-----------|
| 1 | 192.168.5.0/28 | 192.168.5.1 | 192.168.5.14 | 192.168.5.15 |
| 2 | 192.168.5.16/28 | 192.168.5.17 | 192.168.5.30 | 192.168.5.31 |
| 3 | 192.168.5.32/28 | 192.168.5.33 | 192.168.5.46 | 192.168.5.47 |
| 4 | 192.168.5.48/28 | 192.168.5.49 | 192.168.5.62 | 192.168.5.63 |
| ... | ... | ... | ... | ... |
| 13 | 192.168.5.192/28 | 192.168.5.193 | 192.168.5.206 | 192.168.5.207 |
| 14 | 192.168.5.208/28 | 192.168.5.209 | 192.168.5.222 | 192.168.5.223 |
| 15 | 192.168.5.224/28 | 192.168.5.225 | 192.168.5.238 | 192.168.5.239 |
| 16 | 192.168.5.240/28 | 192.168.5.241 | 192.168.5.254 | 192.168.5.255 |

**Méthode de résolution** :

1. /28 → masque 255.255.255.240 → magic number = 256 - 240 = **16**
2. Les sous-réseaux démarrent tous les 16 adresses dans le 4e octet
3. Premier sous-réseau : .0, puis .16, .32, .48 ... .224, .240
4. Chaque sous-réseau contient 2^4 - 2 = **14 hotes**

**Vérification** : 16 sous-réseaux x 16 adresses = 256 adresses = un /24 complet. ✓

</details>

---

### Exercice 14 — Meme sous-réseau ?

**Énoncé** : Deux postes doivent communiquer directement (sans routeur) :
- Poste A : 10.10.33.120/26
- Poste B : 10.10.33.200/26

**Question** : Ces deux postes sont-ils dans le même sous-réseau ? Justifiez.

<details>
<summary>Solution</summary>

**Réponse** : **Non**, ils ne sont pas dans le même sous-réseau.

**Méthode de résolution** :

1. /26 → masque 255.255.255.192 → magic number = 256 - 192 = **64**
2. Sous-réseaux possibles dans le 4e octet : .0, .64, .128, .192

Pour le poste A (120) :
- Plus grand multiple de 64 <= 120 : 64 x 1 = **64**
- Sous-réseau A = 10.10.33.**64**/26 (plage : 64--127)

Pour le poste B (200) :
- Plus grand multiple de 64 <= 200 : 64 x 3 = **192**
- Sous-réseau B = 10.10.33.**192**/26 (plage : 192--255)

Les deux adresses sont dans des sous-réseaux **différents**. La communication directe est impossible sans un routeur entre les deux sous-réseaux.

Vérification binaire :
```
Poste A : 00001010.00001010.00100001.01|111000  → réseau : ...01|000000 = .64
Poste B : 00001010.00001010.00100001.11|001000  → réseau : ...11|000000 = .192
                                       ^^ bits réseau différents
```

**Vérification** : 120 est dans [64--127] et 200 est dans [192--255]. Sous-réseaux différents. ✓

</details>

---

### Exercice 15 — Masque pour un nombre d'hotes donné

**Énoncé** : Vous devez créer un sous-réseau pouvant accueillir exactement 50 postes (avec de la marge minimale).

**Question** : Quel est le masque le plus petit (le plus restrictif) qui peut contenir 50 hotes ? Combien d'adresses sont gaspillées ?

<details>
<summary>Solution</summary>

**Réponse** :
- Masque : **/26** (255.255.255.192)
- Adresses gaspillées : **12**

**Méthode de résolution** :

On cherche le plus petit n tel que 2^n - 2 >= 50 :
- 2^5 - 2 = 30 → insuffisant
- 2^6 - 2 = **62** → suffisant !

Donc il faut 6 bits hôte → masque = /26 (32 - 6 = 26)

Adresses gaspillées = hotes possibles - hotes nécessaires = 62 - 50 = **12**

**Vérification** : Un /27 ne donnerait que 30 hotes (insuffisant pour 50). Un /26 donne 62 hotes (suffisant). C'est bien le masque optimal. ✓

</details>

---

### Exercice 16 — Découpage en sous-réseaux égaux

**Énoncé** : Le réseau 172.20.0.0/16 doit être divisé en au moins 100 sous-réseaux de taille égale.

**Question** : Quel masque utilisez-vous ? Combien de sous-réseaux obtenez-vous réellement ? Combien d'hotes par sous-réseau ?

<details>
<summary>Solution</summary>

**Réponse** :
- Masque : **/23** (255.255.254.0)
- Sous-réseaux : **128**
- Hotes par sous-réseau : **510**

**Méthode de résolution** :

On part du /16 et on cherche combien de bits emprunter pour obtenir au moins 100 sous-réseaux :

- 2^6 = 64 → insuffisant
- 2^7 = **128** → suffisant !

Bits empruntés = 7 → nouveau masque = /16 + 7 = **/23**

- Nombre de sous-réseaux = 2^7 = **128**
- Bits hôte = 32 - 23 = 9
- Hotes par sous-réseau = 2^9 - 2 = **510**

Les sous-réseaux :
```
172.20.0.0/23   (172.20.0.0 -- 172.20.1.255)
172.20.2.0/23   (172.20.2.0 -- 172.20.3.255)
172.20.4.0/23   (172.20.4.0 -- 172.20.5.255)
...
172.20.254.0/23 (172.20.254.0 -- 172.20.255.255)
```

**Vérification** : 128 sous-réseaux x 512 adresses = 65536 = 2^16 → couvre bien tout le /16. ✓

</details>

---

### Exercice 17 — Sous-réseau spécifique

**Énoncé** : Le réseau 10.0.0.0/8 est découpé avec le masque 255.255.0.0 (/16).

**Question** : Quel est le 45e sous-réseau (en partant de 0) ? Donnez son adresse réseau et sa plage d'hotes.

<details>
<summary>Solution</summary>

**Réponse** :
- 45e sous-réseau (index 44) : **10.44.0.0/16**
- Plage : 10.44.0.1 -- 10.44.255.254

**Méthode de résolution** :

1. Le masque passe de /8 à /16 → 8 bits empruntés dans le 2e octet
2. Les sous-réseaux s'incrémentent dans le 2e octet : 10.0.0.0, 10.1.0.0, 10.2.0.0, ...
3. Le 45e sous-réseau (index 44, car on commence à 0) = 10.**44**.0.0/16

Plage :
- Adresse réseau : 10.44.0.0
- Premiere hote : 10.44.0.1
- Derniere hote : 10.44.255.254
- Broadcast : 10.44.255.255

**Vérification** : Le 1er sous-réseau est 10.0.0.0 (index 0), le 2e est 10.1.0.0 (index 1), donc l'index 44 est bien 10.44.0.0. ✓

</details>

---

### Exercice 18 — Adresse valide ou non ?

**Énoncé** : Un technicien a configuré les adresses suivantes sur des interfaces. Le sous-réseau est 172.16.64.0/18.

**Question** : Lesquelles sont des adresses hote valides dans ce sous-réseau ?

1. 172.16.64.0
2. 172.16.100.1
3. 172.16.127.255
4. 172.16.128.1
5. 172.16.65.254

<details>
<summary>Solution</summary>

**Réponse** :

| Adresse | Valide ? | Raison |
|---------|----------|--------|
| 172.16.64.0 | Non | Adresse réseau |
| 172.16.100.1 | **Oui** | Hote valide |
| 172.16.127.255 | Non | Adresse de broadcast |
| 172.16.128.1 | Non | Hors du sous-réseau (sous-réseau suivant) |
| 172.16.65.254 | **Oui** | Hote valide |

**Méthode de résolution** :

1. /18 → masque 255.255.192.0 → magic number = 256 - 192 = **64**
2. Réseau = 172.16.64.0 (donné)
3. Broadcast = 172.16.(64 + 64 - 1).255 = 172.16.**127**.255
4. Plage hote : 172.16.64.1 -- 172.16.127.254

Vérification de chaque adresse :
- 172.16.64.0 = adresse réseau elle-meme → **non valide**
- 172.16.100.1 : 100 est entre 64 et 127 → **valide**
- 172.16.127.255 = broadcast → **non valide**
- 172.16.128.1 : 128 >= 128 → hors plage → **non valide**
- 172.16.65.254 : 65 est entre 64 et 127 → **valide**

**Vérification** : Le sous-réseau suivant est 172.16.128.0/18. L'adresse 172.16.128.1 en fait partie. ✓

</details>

---

### Exercice 19 — Nombre de sous-réseaux nécessaires

**Énoncé** : Une entreprise possède le réseau 192.168.50.0/24 et a besoin de 6 sous-réseaux distincts (au minimum).

**Question** : Combien de bits devez-vous emprunter ? Quel sera le nouveau masque ? Combien d'hotes par sous-réseau ?

<details>
<summary>Solution</summary>

**Réponse** :
- Bits empruntés : **3**
- Nouveau masque : **/27** (255.255.255.224)
- Hotes par sous-réseau : **30**

**Méthode de résolution** :

On cherche le plus petit n tel que 2^n >= 6 :
- 2^2 = 4 → insuffisant
- 2^3 = **8** → suffisant (8 >= 6)

Bits empruntés = 3 → nouveau masque = /24 + 3 = **/27**

- Nombre de sous-réseaux créés = 2^3 = **8** (6 utilisés, 2 en réserve)
- Bits hôte restants = 32 - 27 = 5
- Hotes = 2^5 - 2 = **30 par sous-réseau**

Les 8 sous-réseaux :
```
192.168.50.0/27     (hotes: .1 -- .30)
192.168.50.32/27    (hotes: .33 -- .62)
192.168.50.64/27    (hotes: .65 -- .94)
192.168.50.96/27    (hotes: .97 -- .126)
192.168.50.128/27   (hotes: .129 -- .158)
192.168.50.160/27   (hotes: .161 -- .190)
192.168.50.192/27   (hotes: .193 -- .222)
192.168.50.224/27   (hotes: .225 -- .254)
```

**Vérification** : 8 sous-réseaux x 32 adresses = 256 = un /24 complet. ✓

</details>

---

### Exercice 20 — Synthese niveau 2

**Énoncé** : Le réseau 10.100.0.0/22 est attribué à un site. On souhaite le découper en sous-réseaux de /26.

**Question** :
1. Combien de sous-réseaux /26 sont créés ?
2. Quel est le 10e sous-réseau (index 9) ?
3. L'adresse 10.100.2.200 appartient à quel sous-réseau ?
4. Les adresses 10.100.1.65 et 10.100.1.100 sont-elles dans le même sous-réseau ?

<details>
<summary>Solution</summary>

**Réponse** :

1. **64 sous-réseaux** /26
2. 10e sous-réseau (index 9) : **10.100.2.64/26**
3. 10.100.2.200 appartient à **10.100.2.192/26**
4. **Oui**, les deux sont dans 10.100.1.64/26

**Méthode de résolution** :

**Question 1** : Nombre de sous-réseaux
- Bits empruntés = 26 - 22 = 4... Non ! Il faut compter correctement.
- Un /22 contient 2^(26-22) = 2^4 = 16 sous-réseaux ? Non.
- Un /22 = 2^(32-22) = 1024 adresses. Un /26 = 2^(32-26) = 64 adresses.
- Nombre de /26 dans un /22 = 1024 / 64 = **16**... 

Reprenons : bits empruntés = 26 - 22 = 4. Sous-réseaux = 2^4 = **16**.

Correction -- vérifions : le réseau 10.100.0.0/22 couvre 10.100.0.0 à 10.100.3.255 (4 x 256 = 1024 adresses). Chaque /26 = 64 adresses. 1024/64 = **16 sous-réseaux**.

Mais attendons : re-calcul. 2^(26-22) = 2^4 = 16. Cela donne 16 sous-réseaux, pas 64. Corrigeons la réponse.

Sous-réseaux = **16**

**Question 2** : 10e sous-réseau (index 9)
Magic number du /26 dans le 4e octet = 64. Les sous-réseaux :
```
Index 0 : 10.100.0.0/26
Index 1 : 10.100.0.64/26
Index 2 : 10.100.0.128/26
Index 3 : 10.100.0.192/26
Index 4 : 10.100.1.0/26
Index 5 : 10.100.1.64/26
Index 6 : 10.100.1.128/26
Index 7 : 10.100.1.192/26
Index 8 : 10.100.2.0/26
Index 9 : 10.100.2.64/26
```
10e sous-réseau = **10.100.2.64/26**

**Question 3** : Sous-réseau de 10.100.2.200
- Octet intéressant (4e) = 200
- Plus grand multiple de 64 <= 200 : 64 x 3 = **192**
- Sous-réseau = **10.100.2.192/26** (plage : .192 à .255)

**Question 4** : 10.100.1.65 et 10.100.1.100
- Les deux ont le même 3e octet (1)
- Pour .65 : multiple de 64 <= 65 → **64** → sous-réseau 10.100.1.64/26
- Pour .100 : multiple de 64 <= 100 → **64** → sous-réseau 10.100.1.64/26
- **Oui**, même sous-réseau.

**Vérification** : 16 sous-réseaux x 64 adresses = 1024 adresses = 2^(32-22) = un /22 complet. ✓

</details>

---

## Niveau 3 — VLSM (exercices 21-30)

### Exercice 21 — VLSM basique : 3 sous-réseaux

**Énoncé** : Vous disposez du réseau **10.1.0.0/24** et devez créer un plan d'adressage pour 3 sous-réseaux :

| Sous-réseau | Hotes nécessaires |
|-------------|-------------------|
| LAN Ventes | 100 |
| LAN Admin | 50 |
| Lien WAN R1-R2 | 2 |

**Question** : Proposez un plan VLSM complet en commencant par le plus gros sous-réseau.

<details>
<summary>Solution</summary>

**Réponse** :

| Sous-réseau | Préfixe | Adresse réseau | Premiere hote | Derniere hote | Broadcast | Hotes dispo |
|-------------|---------|---------------|---------------|---------------|-----------|-------------|
| LAN Ventes | /25 | 10.1.0.0/25 | 10.1.0.1 | 10.1.0.126 | 10.1.0.127 | 126 |
| LAN Admin | /26 | 10.1.0.128/26 | 10.1.0.129 | 10.1.0.190 | 10.1.0.191 | 62 |
| Lien WAN | /30 | 10.1.0.192/30 | 10.1.0.193 | 10.1.0.194 | 10.1.0.195 | 2 |

Espace restant libre : 10.1.0.196/30 -- 10.1.0.255 (60 adresses)

**Méthode de résolution** :

**Etape 1** : Trier par taille décroissante et déterminer les masques

| Besoin | Masque nécessaire | Hotes fournis |
|--------|-------------------|---------------|
| 100 hotes | /25 (2^7 - 2 = 126) | 126 |
| 50 hotes | /26 (2^6 - 2 = 62) | 62 |
| 2 hotes | /30 (2^2 - 2 = 2) | 2 |

**Etape 2** : Assigner en partant du début du bloc

1. **LAN Ventes** (/25, bloc de 128 adresses) :
   - Début : 10.1.0.0, Fin : 10.1.0.127
   - Prochaine adresse disponible : 10.1.0.128

2. **LAN Admin** (/26, bloc de 64 adresses) :
   - 10.1.0.128 est-il aligné sur un /26 ? 128/64 = 2 → oui
   - Début : 10.1.0.128, Fin : 10.1.0.191
   - Prochaine adresse disponible : 10.1.0.192

3. **Lien WAN** (/30, bloc de 4 adresses) :
   - 10.1.0.192 est-il aligné sur un /30 ? 192/4 = 48 → oui
   - Début : 10.1.0.192, Fin : 10.1.0.195

**Vérification** : Aucun overlap. Total utilisé = 128 + 64 + 4 = 196 adresses sur 256 disponibles. ✓

</details>

---

### Exercice 22 — VLSM intermédiaire : 5 sous-réseaux

**Énoncé** : Réseau source : **172.16.8.0/22** (1024 adresses disponibles).

| Sous-réseau | Hotes nécessaires |
|-------------|-------------------|
| LAN Production | 400 |
| LAN Bureaux | 200 |
| LAN Serveurs | 60 |
| LAN Wi-Fi invités | 25 |
| Lien WAN | 2 |

**Question** : Concevez le plan VLSM complet.

<details>
<summary>Solution</summary>

**Réponse** :

| Sous-réseau | Préfixe | Adresse réseau | Premiere hote | Derniere hote | Broadcast | Hotes dispo |
|-------------|---------|---------------|---------------|---------------|-----------|-------------|
| LAN Production | /23 | 172.16.8.0/23 | 172.16.8.1 | 172.16.9.254 | 172.16.9.255 | 510 |
| LAN Bureaux | /24 | 172.16.10.0/24 | 172.16.10.1 | 172.16.10.254 | 172.16.10.255 | 254 |
| LAN Serveurs | /26 | 172.16.11.0/26 | 172.16.11.1 | 172.16.11.62 | 172.16.11.63 | 62 |
| LAN Wi-Fi invités | /27 | 172.16.11.64/27 | 172.16.11.65 | 172.16.11.94 | 172.16.11.95 | 30 |
| Lien WAN | /30 | 172.16.11.96/30 | 172.16.11.97 | 172.16.11.98 | 172.16.11.99 | 2 |

Espace restant libre : 172.16.11.100 -- 172.16.11.255 (156 adresses)

**Méthode de résolution** :

**Etape 1** : Trier et choisir les masques

| Besoin | Masque | Taille bloc | Hotes |
|--------|--------|-------------|-------|
| 400 | /23 | 512 | 510 |
| 200 | /24 | 256 | 254 |
| 60 | /26 | 64 | 62 |
| 25 | /27 | 32 | 30 |
| 2 | /30 | 4 | 2 |

Total blocs = 512 + 256 + 64 + 32 + 4 = **868** adresses (sur 1024 dispo)

**Etape 2** : Assigner séquentiellement

1. **Production** (/23) : 172.16.8.0 → 172.16.9.255 (512 adresses)
   - Alignement : 8 est pair → ok pour /23
2. **Bureaux** (/24) : 172.16.10.0 → 172.16.10.255 (256 adresses)
   - Alignement : ok
3. **Serveurs** (/26) : 172.16.11.0 → 172.16.11.63 (64 adresses)
   - Alignement : 0 est multiple de 64 → ok
4. **Wi-Fi** (/27) : 172.16.11.64 → 172.16.11.95 (32 adresses)
   - Alignement : 64 est multiple de 32 → ok
5. **WAN** (/30) : 172.16.11.96 → 172.16.11.99 (4 adresses)
   - Alignement : 96 est multiple de 4 → ok

**Vérification** : Pas d'overlap, tout est dans le bloc 172.16.8.0/22 (8.0 à 11.255). Total utilisé : 868/1024 = 84,8%. ✓

</details>

---

### Exercice 23 — VLSM avec liens point-à-point multiples

**Énoncé** : Réseau source : **192.168.100.0/24**. Topologie :

```
[LAN1: 60 hotes]---R1---WAN1---R2---[LAN2: 28 hotes]
                                |
                               WAN2
                                |
                               R3---[LAN3: 12 hotes]
```

| Sous-réseau | Hotes nécessaires |
|-------------|-------------------|
| LAN1 | 60 |
| LAN2 | 28 |
| LAN3 | 12 |
| WAN1 (R1-R2) | 2 |
| WAN2 (R2-R3) | 2 |

**Question** : Plan VLSM complet.

<details>
<summary>Solution</summary>

**Réponse** :

| Sous-réseau | Préfixe | Adresse réseau | Premiere hote | Derniere hote | Broadcast | Hotes |
|-------------|---------|---------------|---------------|---------------|-----------|-------|
| LAN1 | /26 | 192.168.100.0/26 | 192.168.100.1 | 192.168.100.62 | 192.168.100.63 | 62 |
| LAN2 | /27 | 192.168.100.64/27 | 192.168.100.65 | 192.168.100.94 | 192.168.100.95 | 30 |
| LAN3 | /28 | 192.168.100.96/28 | 192.168.100.97 | 192.168.100.110 | 192.168.100.111 | 14 |
| WAN1 | /30 | 192.168.100.112/30 | 192.168.100.113 | 192.168.100.114 | 192.168.100.115 | 2 |
| WAN2 | /30 | 192.168.100.116/30 | 192.168.100.117 | 192.168.100.118 | 192.168.100.119 | 2 |

Espace restant : 192.168.100.120 -- 192.168.100.255 (136 adresses)

**Méthode de résolution** :

1. Tri décroissant : 60, 28, 12, 2, 2
2. Masques : /26 (62), /27 (30), /28 (14), /30 (2), /30 (2)
3. Tailles : 64 + 32 + 16 + 4 + 4 = **120 adresses** sur 256

Assignation :
- LAN1 /26 : commence à .0 (0 mod 64 = 0 ✓) → .0 à .63
- LAN2 /27 : commence à .64 (64 mod 32 = 0 ✓) → .64 à .95
- LAN3 /28 : commence à .96 (96 mod 16 = 0 ✓) → .96 à .111
- WAN1 /30 : commence à .112 (112 mod 4 = 0 ✓) → .112 à .115
- WAN2 /30 : commence à .116 (116 mod 4 = 0 ✓) → .116 à .119

**Vérification** : Aucun chevauchement. Tous les alignements sont corrects. 120/256 = 46,9% d'utilisation. ✓

</details>

---

### Exercice 24 — VLSM avec gaspillage à analyser

**Énoncé** : Un administrateur junior a proposé le plan d'adressage suivant pour le réseau **10.0.0.0/24** :

| Sous-réseau | Besoin | Attribution |
|-------------|--------|------------|
| LAN A | 5 hotes | 10.0.0.0/24 |
| LAN B | 10 hotes | 10.0.1.0/24 |
| LAN C | 3 hotes | 10.0.2.0/24 |

**Question** :
1. Quel est le problème principal de ce plan ?
2. Combien d'adresses sont gaspillées ?
3. Proposez un plan VLSM optimisé utilisant le réseau 10.0.0.0/24 uniquement.

<details>
<summary>Solution</summary>

**Réponse** :

**1. Probleme principal** : L'administrateur utilise 3 réseaux /24 distincts (10.0.0.0, 10.0.1.0, 10.0.2.0) pour des besoins minuscules. De plus, 10.0.1.0/24 et 10.0.2.0/24 ne font pas partie du réseau 10.0.0.0/24 attribué ! Il confond les sous-réseaux avec des réseaux séparés.

**2. Gaspillage** (s'il disposait réellement de ces 3 blocs /24) : 3 x 254 = 762 hotes possibles pour seulement 18 utilisés → **744 adresses gaspillées** (97,6% de gaspillage).

**3. Plan VLSM optimisé** sur 10.0.0.0/24 :

| Sous-réseau | Préfixe | Adresse réseau | Premiere hote | Derniere hote | Broadcast | Hotes |
|-------------|---------|---------------|---------------|---------------|-----------|-------|
| LAN B (10 hotes) | /28 | 10.0.0.0/28 | 10.0.0.1 | 10.0.0.14 | 10.0.0.15 | 14 |
| LAN A (5 hotes) | /29 | 10.0.0.16/29 | 10.0.0.17 | 10.0.0.22 | 10.0.0.23 | 6 |
| LAN C (3 hotes) | /29 | 10.0.0.24/29 | 10.0.0.25 | 10.0.0.30 | 10.0.0.31 | 6 |

Total utilisé : 16 + 8 + 8 = **32 adresses** sur 256 (12,5%)
Espace libre restant : 10.0.0.32 -- 10.0.0.255 pour la croissance future.

**Méthode de résolution** :

- LAN B (10 hotes) : 2^4 - 2 = 14 >= 10 → **/28**
- LAN A (5 hotes) : 2^3 - 2 = 6 >= 5 → **/29**
- LAN C (3 hotes) : 2^3 - 2 = 6 >= 3 → **/29**

Assignation par taille décroissante : LAN B d'abord, puis A, puis C.

**Vérification** : Un seul réseau /24 suffit largement. L'ancien plan gaspillait 97,6% de l'espace. Le nouveau plan n'utilise que 12,5%. ✓

</details>

---

### Exercice 25 — VLSM avec 6 sous-réseaux

**Énoncé** : Réseau source : **10.1.0.0/22** (1024 adresses).

| Sous-réseau | Hotes nécessaires |
|-------------|-------------------|
| Datacenter | 200 |
| Développement | 100 |
| Comptabilité | 50 |
| Direction | 25 |
| DMZ | 10 |
| Lien WAN | 2 |

**Question** : Plan VLSM complet. Indiquez l'espace restant disponible.

<details>
<summary>Solution</summary>

**Réponse** :

| Sous-réseau | Préfixe | Adresse réseau | Premiere hote | Derniere hote | Broadcast | Hotes |
|-------------|---------|---------------|---------------|---------------|-----------|-------|
| Datacenter | /24 | 10.1.0.0/24 | 10.1.0.1 | 10.1.0.254 | 10.1.0.255 | 254 |
| Développement | /25 | 10.1.1.0/25 | 10.1.1.1 | 10.1.1.126 | 10.1.1.127 | 126 |
| Comptabilité | /26 | 10.1.1.128/26 | 10.1.1.129 | 10.1.1.190 | 10.1.1.191 | 62 |
| Direction | /27 | 10.1.1.192/27 | 10.1.1.193 | 10.1.1.222 | 10.1.1.223 | 30 |
| DMZ | /28 | 10.1.1.224/28 | 10.1.1.225 | 10.1.1.238 | 10.1.1.239 | 14 |
| Lien WAN | /30 | 10.1.1.240/30 | 10.1.1.241 | 10.1.1.242 | 10.1.1.243 | 2 |

**Espace restant** :
- 10.1.1.244/30 à 10.1.1.255 → 12 adresses (3 blocs /30)
- 10.1.2.0/23 → 512 adresses (tout le bloc 10.1.2.0 -- 10.1.3.255)
- **Total libre : 524 adresses** sur 1024 (51,2%)

**Méthode de résolution** :

Tri et choix des masques :

| Besoin | Plus petit 2^n - 2 >= besoin | Masque | Bloc |
|--------|------------------------------|--------|------|
| 200 | 2^8 - 2 = 254 | /24 | 256 |
| 100 | 2^7 - 2 = 126 | /25 | 128 |
| 50 | 2^6 - 2 = 62 | /26 | 64 |
| 25 | 2^5 - 2 = 30 | /27 | 32 |
| 10 | 2^4 - 2 = 14 | /28 | 16 |
| 2 | 2^2 - 2 = 2 | /30 | 4 |

Total = 256 + 128 + 64 + 32 + 16 + 4 = **500 adresses**

Alignements :
- /24 à .0.0 → 0 mod 256 = 0 ✓
- /25 à .1.0 → 0 mod 128 = 0 ✓
- /26 à .1.128 → 128 mod 64 = 0 ✓
- /27 à .1.192 → 192 mod 32 = 0 ✓
- /28 à .1.224 → 224 mod 16 = 0 ✓
- /30 à .1.240 → 240 mod 4 = 0 ✓

**Vérification** : Tout reste dans le bloc 10.1.0.0/22 (10.1.0.0 -- 10.1.3.255). Pas d'overlap. ✓

</details>

---

### Exercice 26 — Détecter un overlap VLSM

**Énoncé** : Un collègue vous soumet le plan d'adressage suivant sur le réseau **192.168.1.0/24** :

| Sous-réseau | Attribution |
|-------------|------------|
| LAN A | 192.168.1.0/26 |
| LAN B | 192.168.1.32/27 |
| LAN C | 192.168.1.64/26 |
| LAN D | 192.168.1.128/25 |

**Question** : Y a-t-il un problème ? Si oui, identifiez-le et proposez une correction.

<details>
<summary>Solution</summary>

**Réponse** : **Oui**, il y a un overlap entre LAN A et LAN B.

**Détail du problème** :

| Sous-réseau | Plage couverte |
|-------------|----------------|
| LAN A : 192.168.1.0/26 | 192.168.1.0 -- 192.168.1.63 |
| LAN B : 192.168.1.32/27 | 192.168.1.32 -- 192.168.1.63 |
| LAN C : 192.168.1.64/26 | 192.168.1.64 -- 192.168.1.127 |
| LAN D : 192.168.1.128/25 | 192.168.1.128 -- 192.168.1.255 |

Le LAN B (192.168.1.32 -- .63) est **entièrement inclus** dans le LAN A (192.168.1.0 -- .63). C'est un overlap qui provoquera des conflits de routage.

**Plan corrigé** (en conservant les tailles demandées) :

| Sous-réseau | Préfixe | Plage |
|-------------|---------|-------|
| LAN D | /25 | 192.168.1.0 -- .127 |
| LAN A | /26 | 192.168.1.128 -- .191 |
| LAN C | /26 | Ce plan ne rentre pas ! |

En fait, vérifions la capacité : /26 (64) + /27 (32) + /26 (64) + /25 (128) = 288 > 256. **Le plan est impossible en /24 !**

**Correction possible** : remplacer le /25 par un /26 si le besoin le permet, ou utiliser un réseau plus grand (/23).

Plan alternatif si LAN D peut être /26 :

| Sous-réseau | Préfixe | Adresse réseau | Plage |
|-------------|---------|---------------|-------|
| LAN A | /26 | 192.168.1.0/26 | .0 -- .63 |
| LAN B | /27 | 192.168.1.64/27 | .64 -- .95 |
| LAN C | /26 | 192.168.1.128/26 | .128 -- .191 |
| LAN D | /26 | 192.168.1.192/26 | .192 -- .255 |

Total = 64 + 32 + 64 + 64 = 224 <= 256 ✓

**Vérification** : Dans le plan corrigé, aucune plage ne se chevauche. ✓

</details>

---

### Exercice 27 — VLSM avec contrainte d'alignement

**Énoncé** : Réseau source : **172.30.0.0/21** (2048 adresses, couvre 172.30.0.0 -- 172.30.7.255).

Besoins :
| Sous-réseau | Hotes nécessaires |
|-------------|-------------------|
| Campus principal | 500 |
| Campus secondaire | 250 |
| Labo réseau | 120 |
| Administration | 30 |
| Liens WAN (x3) | 2 chacun |

**Question** : Plan VLSM complet avec vérification des alignements.

<details>
<summary>Solution</summary>

**Réponse** :

| Sous-réseau | Préfixe | Adresse réseau | Premiere hote | Derniere hote | Broadcast | Hotes |
|-------------|---------|---------------|---------------|---------------|-----------|-------|
| Campus principal | /22 | 172.30.0.0/22 | 172.30.0.1 | 172.30.3.254 | 172.30.3.255 | 1022 |
| Campus secondaire | /23 | 172.30.4.0/23 | 172.30.4.1 | 172.30.5.254 | 172.30.5.255 | 510 |
| Labo réseau | /24 | 172.30.6.0/24 | 172.30.6.1 | 172.30.6.254 | 172.30.6.255 | 254 |
| Administration | /27 | 172.30.7.0/27 | 172.30.7.1 | 172.30.7.30 | 172.30.7.31 | 30 |
| WAN 1 | /30 | 172.30.7.32/30 | 172.30.7.33 | 172.30.7.34 | 172.30.7.35 | 2 |
| WAN 2 | /30 | 172.30.7.36/30 | 172.30.7.37 | 172.30.7.38 | 172.30.7.39 | 2 |
| WAN 3 | /30 | 172.30.7.40/30 | 172.30.7.41 | 172.30.7.42 | 172.30.7.43 | 2 |

**Espace restant** : 172.30.7.44 -- 172.30.7.255 = 212 adresses

**Méthode de résolution** :

| Besoin | Masque | Bloc |
|--------|--------|------|
| 500 | /22 (2^10 - 2 = 1022) | 1024 |
| 250 | /23 (2^9 - 2 = 510) | 512 |
| 120 | /24 (2^8 - 2 = 254) | 256 |
| 30 | /27 (2^5 - 2 = 30) | 32 |
| 2 (x3) | /30 (2^2 - 2 = 2) | 4 x 3 = 12 |

Total = 1024 + 512 + 256 + 32 + 12 = **1836 adresses** sur 2048

Vérification des alignements (critère fondamental du VLSM) :
- /22 à .0.0 : adresse en binaire pour les octets 3-4 = 00000000.00000000, les 10 bits hôte sont bien à 0 ✓
- /23 à .4.0 : 00000100.00000000 → les 9 bits hôte (bit 8 à 0) sont à 0 ✓
- /24 à .6.0 : 00000110.00000000 → les 8 bits hôte sont à 0 ✓
- /27 à .7.0 : 00000111.00000000 → les 5 bits hôte sont à 0 ✓
- /30 à .7.32 : 00100000 → les 2 bits hôte sont à 0 ✓

**Vérification** : Tout est dans 172.30.0.0 -- 172.30.7.255. Pas d'overlap. ✓

</details>

---

### Exercice 28 — VLSM : allocation inverse

**Énoncé** : Le plan VLSM suivant est déjà en place sur le réseau **10.10.0.0/22** :

| Sous-réseau | Attribution |
|-------------|------------|
| VLAN 10 | 10.10.0.0/25 |
| VLAN 20 | 10.10.0.128/26 |
| VLAN 30 | 10.10.0.192/27 |
| WAN 1 | 10.10.0.224/30 |
| WAN 2 | 10.10.0.228/30 |

**Question** : On doit ajouter un nouveau VLAN de 200 hotes. Où le placer dans l'espace disponible ?

<details>
<summary>Solution</summary>

**Réponse** : Le nouveau VLAN de 200 hotes nécessite un /24 (254 hotes). Il peut être placé à **10.10.1.0/24**.

**Méthode de résolution** :

1. D'abord, identifier l'espace utilisé et libre :

Espace total du /22 : 10.10.0.0 -- 10.10.3.255 (1024 adresses)

Espace utilisé :
```
10.10.0.0   -- 10.10.0.127   (VLAN 10, /25, 128 adresses)
10.10.0.128 -- 10.10.0.191   (VLAN 20, /26, 64 adresses)
10.10.0.192 -- 10.10.0.223   (VLAN 30, /27, 32 adresses)
10.10.0.224 -- 10.10.0.227   (WAN 1, /30, 4 adresses)
10.10.0.228 -- 10.10.0.231   (WAN 2, /30, 4 adresses)
```

Espace libre :
```
10.10.0.232 -- 10.10.0.255   (24 adresses)
10.10.1.0   -- 10.10.3.255   (768 adresses)
```

2. Pour 200 hotes → /24 (bloc de 256, besoin d'alignement sur un multiple de 256).

3. L'adresse 10.10.1.0 est-elle alignée pour un /24 ? Le 3e octet = 1, et pour un /24, l'alignement porte sur le 4e octet qui doit etre 0 → **oui**.

**Attribution** : 10.10.1.0/24 (10.10.1.0 -- 10.10.1.255)

Espace libre restant après ajout :
```
10.10.0.232 -- 10.10.0.255  (24 adresses)
10.10.2.0   -- 10.10.3.255  (512 adresses)
```

**Vérification** : Le nouveau /24 ne chevauche aucune allocation existante. Il reste 536 adresses de libre. ✓

</details>

---

### Exercice 29 — VLSM complet d'entreprise

**Énoncé** : Réseau source : **10.20.0.0/21** (10.20.0.0 -- 10.20.7.255, 2048 adresses).

Topologie d'entreprise avec 3 sites :

```
Site A (siège) :
  - VLAN Employés : 400 hotes
  - VLAN Serveurs : 50 hotes
  - VLAN VoIP : 200 hotes

Site B (filiale) :
  - VLAN Employés : 100 hotes
  - VLAN Imprimantes : 15 hotes

Site C (agence) :
  - VLAN Unique : 25 hotes

Liens WAN :
  - A-B : 2 hotes
  - A-C : 2 hotes
  - B-C : 2 hotes
```

**Question** : Plan VLSM complet pour les 9 sous-réseaux.

<details>
<summary>Solution</summary>

**Réponse** :

| # | Sous-réseau | Préfixe | Adresse réseau | Premiere hote | Derniere hote | Broadcast | Hotes |
|---|-------------|---------|---------------|---------------|---------------|-----------|-------|
| 1 | Site A - Employés | /23 | 10.20.0.0/23 | 10.20.0.1 | 10.20.1.254 | 10.20.1.255 | 510 |
| 2 | Site A - VoIP | /24 | 10.20.2.0/24 | 10.20.2.1 | 10.20.2.254 | 10.20.2.255 | 254 |
| 3 | Site B - Employés | /25 | 10.20.3.0/25 | 10.20.3.1 | 10.20.3.126 | 10.20.3.127 | 126 |
| 4 | Site A - Serveurs | /26 | 10.20.3.128/26 | 10.20.3.129 | 10.20.3.190 | 10.20.3.191 | 62 |
| 5 | Site C - Unique | /27 | 10.20.3.192/27 | 10.20.3.193 | 10.20.3.222 | 10.20.3.223 | 30 |
| 6 | Site B - Imprimantes | /28 | 10.20.3.224/28 | 10.20.3.225 | 10.20.3.238 | 10.20.3.239 | 14 |
| 7 | WAN A-B | /30 | 10.20.3.240/30 | 10.20.3.241 | 10.20.3.242 | 10.20.3.243 | 2 |
| 8 | WAN A-C | /30 | 10.20.3.244/30 | 10.20.3.245 | 10.20.3.246 | 10.20.3.247 | 2 |
| 9 | WAN B-C | /30 | 10.20.3.248/30 | 10.20.3.249 | 10.20.3.250 | 10.20.3.251 | 2 |

**Espace restant** : 10.20.3.252/30 + 10.20.4.0/22 = 4 + 1024 = **1028 adresses** libres

**Méthode de résolution** :

Tri par taille décroissante :

| Besoin | Masque | Bloc |
|--------|--------|------|
| 400 | /23 | 512 |
| 200 | /24 | 256 |
| 100 | /25 | 128 |
| 50 | /26 | 64 |
| 25 | /27 | 32 |
| 15 | /28 | 16 |
| 2 (x3) | /30 | 4 x 3 = 12 |

Total = 512 + 256 + 128 + 64 + 32 + 16 + 12 = **1020 adresses** sur 2048 (49,8%)

Toutes les assignations sont alignées :
- .0.0 pour /23 : ✓ (0 mod 512 = 0)
- .2.0 pour /24 : ✓ (512 mod 256 = 0)
- .3.0 pour /25 : ✓ (768 mod 128 = 0)
- .3.128 pour /26 : ✓ (128 mod 64 = 0)
- .3.192 pour /27 : ✓ (192 mod 32 = 0)
- .3.224 pour /28 : ✓ (224 mod 16 = 0)
- .3.240 pour /30 : ✓ (240 mod 4 = 0)

**Vérification** : Tout est dans 10.20.0.0 -- 10.20.7.255. Aucun overlap. ✓

</details>

---

### Exercice 30 — VLSM : identifier les erreurs

**Énoncé** : Le plan VLSM suivant a été soumis pour validation sur le réseau **172.20.0.0/22** :

| Sous-réseau | Attribution | Besoin |
|-------------|------------|--------|
| LAN 1 | 172.20.0.0/25 | 100 hotes |
| LAN 2 | 172.20.0.128/26 | 50 hotes |
| LAN 3 | 172.20.0.192/27 | 30 hotes |
| LAN 4 | 172.20.0.200/28 | 10 hotes |
| WAN 1 | 172.20.1.0/30 | 2 hotes |

**Question** : Identifiez toutes les erreurs dans ce plan.

<details>
<summary>Solution</summary>

**Réponse** : Il y a **3 erreurs** dans ce plan :

**Erreur 1 : LAN 1 (/25) ne peut pas contenir 100 hotes**
- Un /25 donne 2^7 - 2 = **126 hotes** → en fait c'est suffisant pour 100. Pas d'erreur ici.

Reprenons l'analyse systématique :

**Erreur 1 : Overlap entre LAN 3 et LAN 4**
- LAN 3 : 172.20.0.192/27 → plage : .192 -- .223
- LAN 4 : 172.20.0.200/28 → plage : .200 -- .215 (si on suppose que c'est intentionnel, mais...)
- LAN 4 commence à .200, qui est **a l'intérieur** du LAN 3 (.192 -- .223). Overlap !

**Erreur 2 : LAN 4 n'est pas aligné**
- 172.20.0.200/28 : un /28 a un bloc de 16 adresses. L'adresse doit être un multiple de 16.
- 200 / 16 = 12,5 → **200 n'est pas un multiple de 16** !
- Le /28 le plus proche serait .192 (pris par LAN 3) ou .208.

**Erreur 3 : LAN 3 est trop petit pour 30 hotes**
- Un /27 donne 2^5 - 2 = **30 hotes**, ce qui est exactement le besoin. Techniquement suffisant, mais sans aucune marge. En pratique, il faut aussi une adresse pour la passerelle (qui est comptée dans les 30 hotes), donc c'est juste mais correct.

**Plan corrigé** :

| Sous-réseau | Attribution | Plage | Hotes |
|-------------|------------|-------|-------|
| LAN 1 | 172.20.0.0/25 | .0 -- .127 | 126 |
| LAN 2 | 172.20.0.128/26 | .128 -- .191 | 62 |
| LAN 3 | 172.20.0.192/27 | .192 -- .223 | 30 |
| LAN 4 | 172.20.0.224/28 | .224 -- .239 | 14 |
| WAN 1 | 172.20.0.240/30 | .240 -- .243 | 2 |

**Vérification** : Dans le plan corrigé, aucun overlap, tous les alignements sont corrects, et tous les besoins sont satisfaits. ✓

</details>

---

## Niveau 4 — Supernetting/Summarization (exercices 31-40)

### Exercice 31 — Résumé de 2 réseaux contigus

**Énoncé** : Votre table de routage contient ces deux entrées :
- 192.168.10.0/24
- 192.168.11.0/24

**Question** : Quelle route résumée (summary route) pouvez-vous configurer pour remplacer ces deux entrées ?

<details>
<summary>Solution</summary>

**Réponse** : **192.168.10.0/23**

**Méthode de résolution** :

Écrire les adresses en binaire et trouver les bits communs :
```
192.168.10.0 = 11000000.10101000.00001010.00000000
192.168.11.0 = 11000000.10101000.00001011.00000000
                                        ^
                        Les 23 premiers bits sont identiques
```

Le bit 24 diffère (0 vs 1). Donc le préfixe commun est de 23 bits → **/23**

L'adresse réseau du résumé : mettre tous les bits hôte à 0 à partir du bit 24 :
11000000.10101000.0000101**0**.00000000 = **192.168.10.0**

Route résumée : **192.168.10.0/23**

**Vérification** : 192.168.10.0/23 couvre 192.168.10.0 -- 192.168.11.255, ce qui inclut les deux /24 et rien de plus. ✓

</details>

---

### Exercice 32 — Résumé de 4 réseaux

**Énoncé** : Un routeur a ces routes vers un site distant :
- 10.1.32.0/24
- 10.1.33.0/24
- 10.1.34.0/24
- 10.1.35.0/24

**Question** : Quelle est la summary route la plus précise possible ?

<details>
<summary>Solution</summary>

**Réponse** : **10.1.32.0/22**

**Méthode de résolution** :

Écrire le 3e octet en binaire :
```
32 = 00100000
33 = 00100001
34 = 00100010
35 = 00100011
       ^^^^^^ ces 6 bits sont communs
```

Bits communs dans le 3e octet : les 6 premiers (001000) → 6 bits
Total bits communs : 8 + 8 + 6 = **22**

L'adresse réseau du résumé : le 3e octet avec les bits hôte à 0 = 001000**00** = 32

Route résumée : **10.1.32.0/22**

Vérifions la couverture :
- 10.1.32.0/22 couvre 10.1.32.0 -- 10.1.35.255
- Cela inclut exactement nos 4 réseaux /24 (32, 33, 34, 35)

**Vérification** : Un /22 = 4 x /24, et nos 4 réseaux commencent à .32 (multiple de 4 dans le 3e octet). C'est le résumé le plus précis. ✓

</details>

---

### Exercice 33 — Résumé non trivial

**Énoncé** : Votre routeur a ces 8 routes :
- 172.16.16.0/24
- 172.16.17.0/24
- 172.16.18.0/24
- 172.16.19.0/24
- 172.16.20.0/24
- 172.16.21.0/24
- 172.16.22.0/24
- 172.16.23.0/24

**Question** : Donnez la summary route la plus précise.

<details>
<summary>Solution</summary>

**Réponse** : **172.16.16.0/21**

**Méthode de résolution** :

Écrire le 3e octet en binaire :
```
16 = 00010000
17 = 00010001
18 = 00010010
19 = 00010011
20 = 00010100
21 = 00010101
22 = 00010110
23 = 00010111
      ^^^^^  ces 5 bits sont communs (00010)
```

Bits communs dans le 3e octet : 5 → total = 8 + 8 + 5 = **21**

L'adresse résumée : 172.16.000**10000**.0 = 172.16.16.0

Route résumée : **172.16.16.0/21**

Couverture : 172.16.16.0 -- 172.16.23.255 → exactement nos 8 réseaux.

**Vérification** : Un /21 = 8 x /24. 16 est bien un multiple de 8. Le résumé couvre 16 à 23 inclus. ✓

</details>

---

### Exercice 34 — Résumé avec réseau parasite

**Énoncé** : Vous devez résumer ces réseaux :
- 10.0.4.0/24
- 10.0.5.0/24
- 10.0.6.0/24
- 10.0.7.0/24

Un résumé naif en /21 est proposé : 10.0.0.0/21.

**Question** :
1. Le /21 est-il correct ?
2. Y a-t-il un résumé plus précis ?
3. Quels réseaux "parasites" sont inclus dans le /21 ?

<details>
<summary>Solution</summary>

**Réponse** :

1. Le /21 **fonctionne** mais n'est pas optimal.
2. Oui : **10.0.4.0/22** est plus précis.
3. Le /21 inclut les réseaux parasites : 10.0.0.0/24, 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24.

**Méthode de résolution** :

Analyse du 3e octet en binaire :
```
4 = 00000100
5 = 00000101
6 = 00000110
7 = 00000111
     ^^^^^^ 6 bits communs (000001)
```

Bits communs : 8 + 8 + 6 = **22** → le résumé optimal est **/22**, pas /21.

Couverture de 10.0.4.0/22 : 10.0.4.0 -- 10.0.7.255 → exactement nos 4 réseaux.

Couverture de 10.0.0.0/21 : 10.0.0.0 -- 10.0.7.255 → inclut 8 réseaux /24, dont 4 "parasites" :
- 10.0.0.0/24 (parasite)
- 10.0.1.0/24 (parasite)
- 10.0.2.0/24 (parasite)
- 10.0.3.0/24 (parasite)
- 10.0.4.0/24 ✓
- 10.0.5.0/24 ✓
- 10.0.6.0/24 ✓
- 10.0.7.0/24 ✓

Le résumé trop large pourrait router du trafic vers des réseaux inexistants (black hole) ou vers des destinations non souhaitées.

**Vérification** : 4 est un multiple de 4 (pour un /22 = 4 x /24). 4 n'est pas un multiple de 8 (pour un /21 = 8 x /24), ce qui confirme que le /21 devrait commencer à .0, pas à .4. ✓

</details>

---

### Exercice 35 — Réseaux non contigus

**Énoncé** : On vous demande de résumer ces 3 réseaux :
- 192.168.4.0/24
- 192.168.5.0/24
- 192.168.7.0/24

**Question** : Peut-on les résumer en un seul préfixe sans inclure de réseau parasite ? Si non, quelle est la meilleure approche ?

<details>
<summary>Solution</summary>

**Réponse** : **Non**, on ne peut pas les résumer parfaitement en un seul préfixe.

**Méthode de résolution** :

Le 3e octet en binaire :
```
4 = 00000100
5 = 00000101
7 = 00000111
     ^^^^^   5 bits communs (00000) seulement
```

Le résumé le plus court couvrant les 3 serait 192.168.4.0/21 (couvre .0 à .7), mais il inclurait :
- 192.168.0.0/24 (parasite)
- 192.168.1.0/24 (parasite)
- 192.168.2.0/24 (parasite)
- 192.168.3.0/24 (parasite)
- 192.168.4.0/24 ✓
- 192.168.5.0/24 ✓
- 192.168.6.0/24 (parasite)
- 192.168.7.0/24 ✓

5 réseaux parasites pour 3 réseaux utiles — inacceptable.

**Meilleure approche : deux summary routes**

| Résumé | Couvre | Parasites |
|--------|-------|-----------|
| 192.168.4.0/23 | 192.168.4.0 et .5.0 | Aucun |
| 192.168.7.0/24 | 192.168.7.0 | Aucun |

On ne peut pas inclure .7 sans inclure .6 (car 6 et 7 forment un /23 naturel). Donc le réseau .7 reste en route séparée.

Alternative si on accepte un parasite : 192.168.4.0/22 couvre .4, .5, .6, .7 → un seul parasite (.6), ce qui est souvent acceptable.

**Vérification** : Les réseaux .4 et .5 sont contigus (résumé en /23 possible). Le réseau .7 est séparé de .5 par un "trou" (.6 manque). ✓

</details>

---

### Exercice 36 — Summary route pour routage OSPF

**Énoncé** : Le routeur R1 est ABR (Area Border Router) entre l'area 0 et l'area 1. L'area 1 contient ces sous-réseaux :

- 10.10.64.0/26
- 10.10.64.64/26
- 10.10.64.128/26
- 10.10.64.192/26
- 10.10.65.0/26
- 10.10.65.64/26
- 10.10.65.128/26
- 10.10.65.192/26

**Question** : Quelle commande OSPF de summarization configurez-vous sur R1 pour annoncer un seul préfixe dans l'area 0 ?

<details>
<summary>Solution</summary>

**Réponse** :
```
router ospf 1
 area 1 range 10.10.64.0 255.255.254.0
```

Soit le résumé : **10.10.64.0/23**

**Méthode de résolution** :

1. Les 8 sous-réseaux /26 couvrent :
   - 10.10.64.0 -- 10.10.64.255 (4 x /26 = un /24)
   - 10.10.65.0 -- 10.10.65.255 (4 x /26 = un /24)

2. Ces deux /24 sont contigus (64 et 65) :
```
64 = 01000000
65 = 01000001
      ^^^^^^^ 7 bits communs
```
Résumé : /23 (8 + 8 + 7 = 23)

3. En OSPF, la summarization inter-area se fait avec `area X range` sur l'ABR.

4. La commande utilise le masque en notation décimale (pas CIDR) :
   /23 = 255.255.254.0

**Vérification** : 10.10.64.0/23 couvre 10.10.64.0 -- 10.10.65.255, soit exactement les 8 sous-réseaux /26 listés. 8 x 64 = 512 = 2^9 = un /23. ✓

</details>

---

### Exercice 37 — Supernetting inverse : éclater un résumé

**Énoncé** : Un routeur possède la route résumée 172.16.128.0/19.

**Question** :
1. Combien de sous-réseaux /24 cette route couvre-t-elle ?
2. Listez le premier et le dernier /24 couverts.
3. L'adresse 172.16.170.50 est-elle couverte par cette route ?

<details>
<summary>Solution</summary>

**Réponse** :

1. **32 sous-réseaux** /24
2. Premier : 172.16.128.0/24, Dernier : 172.16.159.0/24
3. **Non**, 172.16.170.50 n'est pas couverte

**Méthode de résolution** :

**Question 1** :
- Un /19 contient 2^(24-19) = 2^5 = **32 sous-réseaux /24**

**Question 2** :
- /19, masque 255.255.224.0, magic number = 256 - 224 = **32**
- Adresse réseau : 172.16.128.0
- Broadcast : 172.16.(128 + 32 - 1).255 = 172.16.159.255
- Premier /24 : **172.16.128.0/24**
- Dernier /24 : **172.16.159.0/24**

**Question 3** :
- 172.16.170.50 : le 3e octet est 170
- La plage du /19 va de 128 à 159
- 170 > 159 → **hors de la route résumée**

**Vérification** : 32 sous-réseaux /24 de .128 à .159, chaque octet incrémente de 1 : 128, 129, ..., 159. C'est bien 32 réseaux (159 - 128 + 1 = 32). ✓

</details>

---

### Exercice 38 — Trouver le supernet minimal

**Énoncé** : Votre table de routage contient :
- 10.100.48.0/24
- 10.100.49.0/24
- 10.100.50.0/24
- 10.100.51.0/24
- 10.100.52.0/24
- 10.100.53.0/24

**Question** : Quel est le supernet le plus précis couvrant tous ces réseaux ? Y a-t-il des réseaux parasites ?

<details>
<summary>Solution</summary>

**Réponse** :
- Supernet : **10.100.48.0/21**
- Réseaux parasites : **oui, 2 réseaux** (10.100.54.0/24 et 10.100.55.0/24)

**Méthode de résolution** :

Le 3e octet en binaire :
```
48 = 00110000
49 = 00110001
50 = 00110010
51 = 00110011
52 = 00110100
53 = 00110101
      ^^^^     seuls 4 bits sont communs à TOUS (mais vérifions)
```

Vérifions bit par bit :
```
48 = 0011|0000
49 = 0011|0001
50 = 0011|0010
51 = 0011|0011
52 = 0011|0100
53 = 0011|0101
```

Les 4 premiers bits (0011) sont communs. Le 5e bit varie (0 pour 48-51, 1 pour 52-53).

Bits communs : 8 + 8 + 4 = 20 → le résumé serait **/20**, soit 10.100.48.0/20.

Mais vérifions : /20 couvre 10.100.48.0 -- 10.100.63.255 → cela inclut .48 à .63, soit **16 réseaux /24** dont seulement 6 sont les notres. Beaucoup trop de parasites (10 parasites).

Essayons /21 : 10.100.48.0/21 couvre .48 à .55 (magic number = 8), soit 8 sous-réseaux /24.
- 48, 49, 50, 51, 52, 53 : les notres ✓
- 54, 55 : parasites

/22 ne fonctionne pas car 10.100.48.0/22 couvre .48 à .51 (4 réseaux), et .52 à .55 serait un autre /22. On devrait utiliser deux résumés.

Le supernet **le plus précis en un seul préfixe** est donc **10.100.48.0/21** avec 2 réseaux parasites (.54 et .55).

Alternative sans parasite : deux routes
- 10.100.48.0/22 (couvre .48 à .51)
- 10.100.52.0/23 (couvre .52 et .53)

**Vérification** : 48 est bien un multiple de 8 (48/8 = 6) pour un /21. Le /21 couvre .48 à .55. ✓

</details>

---

### Exercice 39 — Summary route sur routeur de bordure

**Énoncé** : Votre routeur BGP annonce ces préfixes vers un ISP :
- 203.0.113.0/26
- 203.0.113.64/26
- 203.0.113.128/26
- 203.0.113.192/26

**Question** :
1. Quel préfixe agrégé annonceriez-vous à la place ?
2. Quelle commande Cisco configureriez-vous ?
3. Pourquoi est-il recommandé d'ajouter une route vers Null0 ?

<details>
<summary>Solution</summary>

**Réponse** :

1. **203.0.113.0/24**
2. ```
   router bgp 65001
    network 203.0.113.0 mask 255.255.255.0
    aggregate-address 203.0.113.0 255.255.255.0 summary-only
   ```
3. Pour éviter les boucles de routage (routing loops).

**Méthode de résolution** :

**Question 1** :
Les 4 sous-réseaux /26 couvrent un /24 complet :
- .0 à .63 + .64 à .127 + .128 à .191 + .192 à .255 = .0 à .255
- 4 x /26 = 1 x /24

Résumé parfait : **203.0.113.0/24** (aucun parasite).

**Question 2** :
- `aggregate-address` crée le résumé
- `summary-only` supprime les routes spécifiques de l'annonce BGP (n'annonce que le résumé)

**Question 3** :
La route statique vers Null0 :
```
ip route 203.0.113.0 255.255.255.0 Null0
```
Si un des sous-réseaux /26 tombe (par exemple .128/26), le routeur continuerait d'annoncer le /24. Sans la route Null0, le trafic destiné au sous-réseau tombé suivrait la route par défaut et créerait une boucle. Avec Null0, le trafic est simplement supprimé (black hole controlé).

**Vérification** : 4 x 64 = 256 adresses = un /24 complet. Résumé parfait. ✓

</details>

---

### Exercice 40 — Synthese summarization

**Énoncé** : Un réseau d'entreprise multi-sites utilise ces sous-réseaux :

Site Paris :
- 10.1.0.0/24, 10.1.1.0/24, 10.1.2.0/24, 10.1.3.0/24

Site Lyon :
- 10.1.4.0/24, 10.1.5.0/24, 10.1.6.0/24, 10.1.7.0/24

Site Marseille :
- 10.1.8.0/24, 10.1.9.0/24

**Question** :
1. Donnez la summary route pour Paris.
2. Donnez la summary route pour Lyon.
3. Donnez la summary route pour Marseille.
4. Peut-on résumer les 3 sites en une seule route ? Si oui, laquelle ? Combien de parasites ?

<details>
<summary>Solution</summary>

**Réponse** :

1. Paris : **10.1.0.0/22**
2. Lyon : **10.1.4.0/22**
3. Marseille : **10.1.8.0/23**
4. Oui : **10.1.0.0/20** avec **6 réseaux parasites**

**Méthode de résolution** :

**Paris** (0, 1, 2, 3) :
```
0 = 00000000
3 = 00000011
     ^^^^^^  6 bits communs → /22
```
10.1.0.0/22 couvre .0 à .3 → parfait, aucun parasite.

**Lyon** (4, 5, 6, 7) :
```
4 = 00000100
7 = 00000111
     ^^^^^^  6 bits communs → /22
```
10.1.4.0/22 couvre .4 à .7 → parfait, aucun parasite.

**Marseille** (8, 9) :
```
8 = 00001000
9 = 00001001
     ^^^^^^^ 7 bits communs → /23
```
10.1.8.0/23 couvre .8 et .9 → parfait, aucun parasite.

**Résumé global** (0 à 9) :
```
 0 = 0000|0000
 9 = 0000|1001
      ^^^^  4 bits communs → /20
```
10.1.0.0/20 couvre .0 à .15 (3e octet)
- Réseaux utilisés : .0 à .9 (10 réseaux)
- Réseaux parasites : .10, .11, .12, .13, .14, .15 → **6 parasites**

En pratique, si ces adresses parasites ne sont utilisées nulle part, c'est acceptable. Sinon, annoncer les 3 summary routes séparées.

**Vérification** :
- Paris : 4 x /24 = 1 x /22 ✓
- Lyon : 4 x /24 = 1 x /22 ✓
- Marseille : 2 x /24 = 1 x /23 ✓
- Global : /20 = 16 x /24, dont 10 utilisés et 6 parasites ✓

</details>

---

## Niveau 5 — Dépannage et examen (exercices 41-50)

### Exercice 41 — Analyse de table de routage

**Énoncé** : Vous consultez la table de routage de R1 :

```
R1# show ip route
[...]
Gateway of last resort is 10.0.0.1 to network 0.0.0.0

     10.0.0.0/8 is variably subnetted, 5 subnets, 3 masks
C       10.0.0.0/30 is directly connected, GigabitEthernet0/0
L       10.0.0.2/32 is directly connected, GigabitEthernet0/0
O       10.1.0.0/22 [110/20] via 10.0.0.1, 00:15:32, GigabitEthernet0/0
O       10.1.4.0/23 [110/30] via 10.0.0.1, 00:15:32, GigabitEthernet0/0
S*      0.0.0.0/0 [1/0] via 10.0.0.1

     192.168.1.0/24 is variably subnetted, 2 subnets, 2 masks
C       192.168.1.0/26 is directly connected, GigabitEthernet0/1
L       192.168.1.1/32 is directly connected, GigabitEthernet0/1
```

**Question** :
1. Vers quelle interface sera routé un paquet destiné à 10.1.2.50 ?
2. Vers quelle interface sera routé un paquet destiné à 10.1.5.100 ?
3. Vers quelle interface sera routé un paquet destiné à 192.168.1.70 ?
4. Un hote 192.168.1.30 peut-il communiquer avec 10.1.3.200 ?

<details>
<summary>Solution</summary>

**Réponse** :

1. **GigabitEthernet0/0** via 10.0.0.1 (route OSPF 10.1.0.0/22)
2. **GigabitEthernet0/0** via 10.0.0.1 (route OSPF 10.1.4.0/23)
3. **GigabitEthernet0/0** via 10.0.0.1 (route par défaut, car .70 hors du /26 local)
4. **Oui**, R1 a une route vers 10.1.0.0/22 qui couvre 10.1.3.200

**Méthode de résolution** :

**Question 1** : 10.1.2.50
- Vérifier 10.1.0.0/22 : couvre 10.1.0.0 -- 10.1.3.255. L'adresse 10.1.2.50 est dans cette plage.
- Route OSPF via Gi0/0 → **GigabitEthernet0/0**

**Question 2** : 10.1.5.100
- 10.1.0.0/22 couvre .0.0 à .3.255 → .5.100 n'est PAS dans cette plage
- 10.1.4.0/23 couvre 10.1.4.0 -- 10.1.5.255 → .5.100 **est** dans cette plage
- Route OSPF via Gi0/0 → **GigabitEthernet0/0**

**Question 3** : 192.168.1.70
- 192.168.1.0/26 couvre .0 à .63. L'adresse .70 > .63 → PAS dans le sous-réseau local
- Aucune autre route spécifique ne correspond
- Route par défaut 0.0.0.0/0 via 10.0.0.1, Gi0/0 → **GigabitEthernet0/0**

**Question 4** : Communication 192.168.1.30 → 10.1.3.200
- 192.168.1.30 est dans le sous-réseau local Gi0/1 (192.168.1.0/26, plage .1-.62) ✓
- 10.1.3.200 est couvert par la route 10.1.0.0/22 ✓
- R1 peut router le trafic. La communication est possible (sous réserve que le retour soit aussi routé cote distant).

**Vérification** : Le longest prefix match est toujours appliqué : la route la plus spécifique gagne. ✓

</details>

---

### Exercice 42 — Diagnostic de communication impossible

**Énoncé** : Deux hotes ne peuvent pas communiquer :

```
Host A : 10.10.10.50/26     Gateway : 10.10.10.1
Host B : 10.10.10.100/26    Gateway : 10.10.10.65
```

Un ping de A vers B échoue. Le routeur est correctement configuré.

**Question** : Pourquoi les hotes ne peuvent-ils pas communiquer directement (sans routeur) ? Expliquez le problème.

<details>
<summary>Solution</summary>

**Réponse** : Les deux hotes sont dans des **sous-réseaux différents** et doivent passer par un routeur pour communiquer.

**Méthode de résolution** :

Analysons chaque hote :

**Host A** : 10.10.10.50/26
- Magic number = 256 - 192 = 64
- Plus grand multiple de 64 <= 50 : **0**
- Sous-réseau : 10.10.10.**0**/26 (plage : .0 -- .63)
- Gateway : 10.10.10.1 → dans le même sous-réseau ✓

**Host B** : 10.10.10.100/26
- Plus grand multiple de 64 <= 100 : **64**
- Sous-réseau : 10.10.10.**64**/26 (plage : .64 -- .127)
- Gateway : 10.10.10.65 → dans le même sous-réseau ✓

**Diagnostic** : Host A est dans 10.10.10.0/26, Host B est dans 10.10.10.64/26. Ce sont deux sous-réseaux distincts.

Quand Host A veut envoyer un paquet à Host B (.100), il fait un AND entre l'IP destination et son propre masque :
```
10.10.10.100 AND 255.255.255.192 = 10.10.10.64 ≠ 10.10.10.0 (son propre réseau)
```
Host A sait donc que la destination est hors de son sous-réseau et envoie le paquet à sa **gateway** (10.10.10.1). Si le routeur a les deux sous-réseaux configurés sur des sous-interfaces, la communication fonctionnera via le routeur.

Si le ping échoue malgré un routeur correctement configuré, vérifier :
- Le routage inter-VLAN est-il activé ?
- Les deux sous-réseaux sont-ils sur des interfaces différentes du routeur ?
- Les routes retour existent-elles ?

**Vérification** : .50 est dans [0--63] et .100 est dans [64--127]. Sous-réseaux différents. ✓

</details>

---

### Exercice 43 — Wildcard mask pour ACL

**Énoncé** : Vous devez créer une ACL qui autorise tout le trafic provenant du sous-réseau 172.16.32.0/21.

**Question** :
1. Quel est le wildcard mask correspondant ?
2. Écrivez la commande ACL Cisco complète.

<details>
<summary>Solution</summary>

**Réponse** :

1. Wildcard mask : **0.0.7.255**
2. ```
   access-list 10 permit 172.16.32.0 0.0.7.255
   ```

**Méthode de résolution** :

**Calcul du wildcard mask** :

Wildcard = 255.255.255.255 - masque de sous-réseau

Masque /21 = 255.255.248.0

```
  255.255.255.255
- 255.255.248.  0
= 0  .  0.  7.255
```

Wildcard : **0.0.7.255**

**Interprétation** : Les bits à 0 dans le wildcard doivent correspondre exactement. Les bits à 1 sont "don't care" (ignorés).

```
Masque :   11111111.11111111.11111000.00000000
Wildcard : 00000000.00000000.00000111.11111111
```

L'ACL matchera toute adresse de 172.16.32.0 à 172.16.39.255, soit le sous-réseau /21 complet.

**Vérification** : 172.16.32.0 avec wildcard 0.0.7.255 couvre 172.16.32.0 -- 172.16.39.255. Le /21 a pour broadcast 172.16.(32+8-1).255 = 172.16.39.255. ✓

</details>

---

### Exercice 44 — Wildcard mask avancé

**Énoncé** : Vous devez écrire une ACL qui bloque uniquement le sous-réseau 10.0.0.128/29.

**Question** :
1. Quel est le wildcard mask ?
2. Donnez la commande ACL étendue bloquant le trafic TCP port 80 depuis ce sous-réseau vers toute destination.

<details>
<summary>Solution</summary>

**Réponse** :

1. Wildcard mask : **0.0.0.7**
2. ```
   access-list 100 deny tcp 10.0.0.128 0.0.0.7 any eq 80
   access-list 100 permit ip any any
   ```

**Méthode de résolution** :

**Wildcard** :
Masque /29 = 255.255.255.248
Wildcard = 255.255.255.255 - 255.255.255.248 = **0.0.0.7**

Vérification : le /29 couvre 10.0.0.128 -- 10.0.0.135 (8 adresses, 6 hotes).
Le wildcard 0.0.0.7 signifie que les 3 derniers bits sont "don't care" :
```
128 = 10000|000
135 = 10000|111
             ^^^ ces 3 bits varient → wildcard
```

**L'ACL étendue** :
- `100` : numéro d'ACL étendue (100-199)
- `deny tcp` : refuse le trafic TCP
- `10.0.0.128 0.0.0.7` : source = le /29
- `any` : toute destination
- `eq 80` : port HTTP
- La deuxieme ligne `permit ip any any` est indispensable car il y a un `deny all` implicite en fin d'ACL.

**Vérification** : 10.0.0.128 OR 0.0.0.7 = 10.0.0.135. La plage couverte est bien .128 à .135 (un /29). ✓

</details>

---

### Exercice 45 — Longest prefix match

**Énoncé** : Un routeur a ces routes dans sa table :

```
O    10.0.0.0/8 [110/100] via 192.168.1.1
O    10.10.0.0/16 [110/50] via 192.168.1.2
O    10.10.10.0/24 [110/20] via 192.168.1.3
O    10.10.10.128/25 [110/10] via 192.168.1.4
S    10.10.10.0/25 [1/0] via 192.168.1.5
```

**Question** : Pour chaque destination, indiquez le next-hop choisi et justifiez :
1. 10.10.10.200
2. 10.10.10.50
3. 10.10.20.1
4. 10.20.0.1

<details>
<summary>Solution</summary>

**Réponse** :

| Destination | Next-hop | Route utilisée | Justification |
|-------------|----------|---------------|---------------|
| 10.10.10.200 | 192.168.1.4 | 10.10.10.128/25 | /25 est le plus long préfixe qui matche |
| 10.10.10.50 | 192.168.1.5 | 10.10.10.0/25 (statique) | /25 est le plus long préfixe qui matche |
| 10.10.20.1 | 192.168.1.2 | 10.10.0.0/16 | /16 est le plus long préfixe qui matche |
| 10.20.0.1 | 192.168.1.1 | 10.0.0.0/8 | /8 est le seul préfixe qui matche |

**Méthode de résolution** :

Le routeur applique toujours le **longest prefix match** : la route avec le masque le plus long (le plus spécifique) qui correspond à l'adresse destination.

**10.10.10.200** :
- 10.0.0.0/8 → match (200 est dans 10.x.x.x) ✓
- 10.10.0.0/16 → match (dans 10.10.x.x) ✓
- 10.10.10.0/24 → match (dans 10.10.10.x) ✓
- 10.10.10.128/25 → couvre .128 à .255, .200 est dedans → match ✓ **← /25 = plus long**
- 10.10.10.0/25 → couvre .0 à .127, .200 n'est PAS dedans ✗

**10.10.10.50** :
- 10.10.10.128/25 → couvre .128 à .255, .50 n'est PAS dedans ✗
- 10.10.10.0/25 → couvre .0 à .127, .50 est dedans → match ✓ **← /25 = plus long**
- 10.10.10.0/24 → match aussi mais /24 < /25

**10.10.20.1** :
- 10.0.0.0/8 → match ✓
- 10.10.0.0/16 → match ✓ **← /16 = plus long**
- 10.10.10.0/24 → 20 ≠ 10 → pas de match ✗

**10.20.0.1** :
- 10.0.0.0/8 → match ✓ **← /8 = seul match**
- 10.10.0.0/16 → 20 ≠ 10 dans le 2e octet → pas de match ✗

**Vérification** : La distance administrative et la métrique ne sont utilisées que pour départager des routes de **meme longueur de préfixe**. Le longest prefix match a toujours la priorité. ✓

</details>

---

### Exercice 46 — Diagnostic avec show ip interface brief

**Énoncé** : Vous dépannez un problème de connectivité. Voici la sortie de commande :

```
R1# show ip interface brief
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0     10.10.10.1      YES manual up                    up
GigabitEthernet0/1     10.10.10.65     YES manual up                    up
GigabitEthernet0/2     10.10.10.129    YES manual up                    up
Serial0/0/0            172.16.0.1      YES manual up                    up
Loopback0              1.1.1.1         YES manual up                    up
```

Un utilisateur sur le réseau Gi0/0 (avec l'IP 10.10.10.30/26) n'arrive pas à joindre le serveur 10.10.10.140 sur le réseau Gi0/2.

**Question** :
1. Vérifiez que les adresses IP des interfaces sont cohérentes avec un schéma /26.
2. Dans quel sous-réseau se trouve le serveur 10.10.10.140 ?
3. Le masque /26 est-il configuré sur le poste utilisateur ? Quel sous-réseau voit-il ?
4. Identifiez la cause probable du problème si le ping échoue.

<details>
<summary>Solution</summary>

**Réponse** :

1. **Oui**, les adresses sont cohérentes :
   - Gi0/0 (.1) → 10.10.10.0/26 (plage .0-.63)
   - Gi0/1 (.65) → 10.10.10.64/26 (plage .64-.127)
   - Gi0/2 (.129) → 10.10.10.128/26 (plage .128-.191)

2. Le serveur 10.10.10.140 est dans le sous-réseau **10.10.10.128/26** (Gi0/2)

3. L'utilisateur 10.10.10.30/26 est dans le sous-réseau **10.10.10.0/26** avec pour gateway 10.10.10.1

4. Causes probables :
   - Le masque du poste utilisateur n'est peut-être pas /26 (si /24, il croirait que .140 est local et n'enverrait pas à la gateway)
   - La route retour depuis le réseau Gi0/2 vers Gi0/0 pourrait manquer
   - Le serveur .140 pourrait avoir un mauvais masque ou une mauvaise gateway

**Méthode de résolution** :

**Vérification des sous-réseaux /26** (magic number = 64) :
```
Sous-réseau 1 : 10.10.10.0/26   (.0 -- .63)   → Gi0/0 : .1 ✓
Sous-réseau 2 : 10.10.10.64/26  (.64 -- .127)  → Gi0/1 : .65 ✓
Sous-réseau 3 : 10.10.10.128/26 (.128 -- .191) → Gi0/2 : .129 ✓
```

Le serveur .140 est dans le sous-réseau 3 (.128 -- .191, Gi0/2).

**Piège classique** : si l'utilisateur a un masque /24 au lieu de /26, il pense que .140 est dans son réseau local (10.10.10.0/24 = .0 à .255). Il envoie alors des ARP en broadcast sur son LAN au lieu d'envoyer à sa gateway. Le paquet ne quitte jamais le segment local → echec du ping.

**Vérification** : Trois sous-réseaux /26 dans le dernier octet : .0, .64, .128. Chaque interface est la premiere adresse hote de son sous-réseau. ✓

</details>

---

### Exercice 47 — Examen chrono : choix multiple

**Énoncé** : Un hote a l'adresse 10.172.64.25/19. Quel est le broadcast de son sous-réseau ?

**Options** :
- A) 10.172.64.255
- B) 10.172.79.255
- C) 10.172.95.255
- D) 10.172.127.255

*Temps cible : 45 secondes*

<details>
<summary>Solution</summary>

**Réponse** : **C) 10.172.95.255**

**Méthode rapide** (moins de 30 secondes) :

1. /19 → masque dans le 3e octet = 224 (car 19 = 16 + 3, donc 3 bits dans le 3e octet : 111|00000 = 224)
2. Magic number = 256 - 224 = **32**
3. Octet intéressant = 64
4. Multiple de 32 <= 64 : 32 x 2 = **64** (exact !)
5. Adresse réseau = 10.172.**64**.0
6. Broadcast = 10.172.(64 + 32 - 1).255 = 10.172.**95**.255

Élimination rapide :
- A) .64.255 → c'est un broadcast de /24, pas de /19
- B) .79.255 → magic number = 80-64 = 16 → /20, pas /19
- C) .95.255 → 95-64+1 = 32 → magic number 32 → **/19** ✓
- D) .127.255 → magic number = 64 → /18, pas /19

**Vérification** : Le prochain sous-réseau est 10.172.96.0. Le broadcast est l'adresse juste avant : 10.172.95.255. ✓

</details>

---

### Exercice 48 — Examen chrono : wildcard et ACL

**Énoncé** : Quelle ACL autorise uniquement les hotes du réseau 192.168.16.0/22 ?

**Options** :
- A) `permit 192.168.16.0 0.0.0.255`
- B) `permit 192.168.16.0 0.0.3.255`
- C) `permit 192.168.16.0 0.0.7.255`
- D) `permit 192.168.0.0 0.0.31.255`

*Temps cible : 30 secondes*

<details>
<summary>Solution</summary>

**Réponse** : **B) `permit 192.168.16.0 0.0.3.255`**

**Méthode rapide** :

Masque /22 = 255.255.252.0
Wildcard = 255.255.255.255 - 255.255.252.0 = **0.0.3.255**

Vérification de chaque option :
- A) 0.0.0.255 → wildcard d'un /24 → trop restrictif (ne couvre que .16.x)
- B) 0.0.3.255 → wildcard d'un /22 → **correct** (couvre .16.x à .19.x)
- C) 0.0.7.255 → wildcard d'un /21 → trop large (couvrirait .16.x à .23.x)
- D) 0.0.31.255 → wildcard d'un /19 et mauvaise adresse réseau

**Vérification** :
192.168.16.0 avec wildcard 0.0.3.255 couvre :
- De 192.168.16.0 à 192.168.19.255
- C'est exactement un /22 (4 x /24).
- 16 + 3 = 19, donc la plage .16 à .19 ✓

</details>

---

### Exercice 49 — Dépannage complet avec outputs CLI

**Énoncé** : Un utilisateur sur le VLAN 10 (PC1 : 10.10.10.50/24) ne peut pas accéder au serveur web dans le VLAN 20.

Voici les outputs du routeur inter-VLAN (router-on-a-stick) :

```
R1# show ip interface brief
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0     unassigned      YES unset  up                    up
GigabitEthernet0/0.10  10.10.10.1      YES manual up                    up
GigabitEthernet0/0.20  10.10.20.1      YES manual up                    up

R1# show ip route
[...]
     10.0.0.0/8 is variably subnetted, 4 subnets, 2 masks
C       10.10.10.0/24 is directly connected, GigabitEthernet0/0.10
L       10.10.10.1/32 is directly connected, GigabitEthernet0/0.10
C       10.10.20.0/24 is directly connected, GigabitEthernet0/0.20
L       10.10.20.1/32 is directly connected, GigabitEthernet0/0.20

R1# show running-config | section interface
interface GigabitEthernet0/0
 no ip address
 no shutdown
!
interface GigabitEthernet0/0.10
 encapsulation dot1Q 10
 ip address 10.10.10.1 255.255.255.0
!
interface GigabitEthernet0/0.20
 encapsulation dot1Q 20
 ip address 10.10.20.1 255.255.255.0
!

R1# show access-lists
Extended IP access list VLAN10-OUT
    10 deny ip 10.10.10.0 0.0.0.255 10.10.20.0 0.0.0.255
    20 permit ip any any
```

Le serveur web est 10.10.20.100 avec la gateway 10.10.20.1.

**Question** :
1. La configuration des sous-interfaces est-elle correcte ?
2. Le routage entre VLAN est-il en place ?
3. Identifiez la cause du problème.
4. Proposez la correction.

<details>
<summary>Solution</summary>

**Réponse** :

1. **Oui**, les sous-interfaces sont correctement configurées (encapsulation dot1Q + IP dans le bon sous-réseau).
2. **Oui**, le routeur a les deux réseaux en routes directement connectées.
3. **L'ACL "VLAN10-OUT" bloque le trafic** : la ligne 10 interdit explicitement tout trafic de 10.10.10.0/24 vers 10.10.20.0/24.
4. Correction :

```
R1(config)# no access-list VLAN10-OUT
```

Ou si l'ACL doit rester avec d'autres regles, modifier pour autoriser le trafic web :

```
R1(config)# ip access-list extended VLAN10-OUT
R1(config-ext-nacl)# no 10
R1(config-ext-nacl)# 10 permit tcp 10.10.10.0 0.0.0.255 10.10.20.0 0.0.0.255 eq 80
R1(config-ext-nacl)# 15 permit tcp 10.10.10.0 0.0.0.255 10.10.20.0 0.0.0.255 eq 443
R1(config-ext-nacl)# 20 deny ip 10.10.10.0 0.0.0.255 10.10.20.0 0.0.0.255
R1(config-ext-nacl)# 30 permit ip any any
```

**Méthode de résolution** :

**Etape 1 : Vérifier la couche 3**
- PC1 (10.10.10.50/24) → gateway 10.10.10.1 → sous-interface Gi0/0.10 → OK
- Serveur (10.10.20.100/24) → gateway 10.10.20.1 → sous-interface Gi0/0.20 → OK
- Encapsulation dot1Q sur les bons VLANs → OK
- Routes directement connectées pour les deux /24 → OK

**Etape 2 : Chercher un filtrage**
- L'ACL "VLAN10-OUT" a une regle `deny ip 10.10.10.0 0.0.0.255 10.10.20.0 0.0.0.255`
- Le wildcard 0.0.0.255 correspond bien à un /24 → l'ACL bloque TOUT le trafic IP du VLAN 10 vers le VLAN 20
- C'est la cause directe du problème !

**Etape 3 : Vérifier où l'ACL est appliquée**
L'output ne montre pas l'application (`ip access-group`), mais si l'ACL est appliquée en sortie sur Gi0/0.20 ou en entrée sur Gi0/0.10, elle bloque le trafic.

**Vérification** : Sans l'ACL (ou avec la correction), le routeur a les routes nécessaires pour router entre les deux VLANs. ✓

</details>

---

### Exercice 50 — Synthese finale : scénario complet

**Énoncé** : Vous êtes chargé de concevoir et dépanner le réseau d'une PME. Voici le contexte :

**Réseau attribué** : 10.50.0.0/21

**Besoins** :
| Sous-réseau | Hotes | VLAN |
|-------------|-------|------|
| Employés | 300 | 10 |
| Serveurs | 50 | 20 |
| Wi-Fi public | 100 | 30 |
| Management | 10 | 99 |
| WAN vers ISP | 2 | - |

Après votre conception, un technicien configure le réseau mais un probleme survient. Voici l'output :

```
SW1# show vlan brief
VLAN Name                             Status    Ports
---- -------------------------------- --------- ------------------
10   Employes                         active    Fa0/1-10
20   Serveurs                         active    Fa0/11-15
30   WiFi-Public                      active    Fa0/16-20
99   Management                       active    Fa0/24

R1# show ip interface brief
Interface              IP-Address      OK? Method Status                Protocol
Gi0/0                  unassigned      YES unset  up                    up
Gi0/0.10               10.50.0.1       YES manual up                    up
Gi0/0.20               10.50.2.1       YES manual up                    up
Gi0/0.30               10.50.2.129     YES manual up                    up
Gi0/0.99               10.50.3.1       YES manual up                    up
Gi0/1                  10.50.3.17      YES manual up                    up
```

Un employé (PC dans VLAN 10, IP 10.50.1.200/23) ne peut pas joindre un serveur (VLAN 20, IP 10.50.2.60/26).

**Questions** :
1. Proposez le plan VLSM complet.
2. Vérifiez si les IPs des interfaces du routeur sont cohérentes avec votre plan.
3. Identifiez pourquoi l'employé ne peut pas joindre le serveur.
4. Quel wildcard mask utiliseriez-vous dans une ACL pour cibler le sous-réseau Employés ?
5. Écrivez une ACL qui permet au VLAN Employés d'accéder au VLAN Serveurs en HTTP/HTTPS uniquement.

<details>
<summary>Solution</summary>

**Réponse** :

**1. Plan VLSM**

Réseau source : 10.50.0.0/21 (10.50.0.0 -- 10.50.7.255, 2048 adresses)

| Sous-réseau | Préfixe | Adresse réseau | Premiere hote | Derniere hote | Broadcast | Hotes |
|-------------|---------|---------------|---------------|---------------|-----------|-------|
| Employés (300) | /23 | 10.50.0.0/23 | 10.50.0.1 | 10.50.1.254 | 10.50.1.255 | 510 |
| Wi-Fi public (100) | /25 | 10.50.2.0/25 | 10.50.2.1 | 10.50.2.126 | 10.50.2.127 | 126 |
| Serveurs (50) | /26 | 10.50.2.128/26 | 10.50.2.129 | 10.50.2.190 | 10.50.2.191 | 62 |
| Management (10) | /28 | 10.50.2.192/28 | 10.50.2.193 | 10.50.2.206 | 10.50.2.207 | 14 |
| WAN ISP (2) | /30 | 10.50.2.208/30 | 10.50.2.209 | 10.50.2.210 | 10.50.2.211 | 2 |

Espace restant : 10.50.2.212 -- 10.50.7.255 (1324 adresses)

**2. Vérification des IPs du routeur**

| Interface | IP configurée | IP attendue (plan) | Cohérent ? |
|-----------|--------------|---------------------|------------|
| Gi0/0.10 | 10.50.0.1 | 10.50.0.1 (/23) | ✓ |
| Gi0/0.20 | 10.50.2.1 | 10.50.2.129 (/26) | **ERREUR !** |
| Gi0/0.30 | 10.50.2.129 | 10.50.2.1 (/25) | **ERREUR !** |
| Gi0/0.99 | 10.50.3.1 | 10.50.2.193 (/28) | **ERREUR !** |
| Gi0/1 | 10.50.3.17 | 10.50.2.209 (/30) | **ERREUR !** |

Problème identifié : **les IPs du VLAN 20 et VLAN 30 sont inversées !**
- Gi0/0.20 (Serveurs) a l'IP 10.50.2.1 → c'est la premiere hote du sous-réseau Wi-Fi (/25)
- Gi0/0.30 (Wi-Fi) a l'IP 10.50.2.129 → c'est la premiere hote du sous-réseau Serveurs (/26)

De plus, les IPs de Gi0/0.99 et Gi0/1 ne correspondent pas au plan VLSM proposé (le technicien a peut-être utilisé un plan différent).

**3. Pourquoi l'employé ne peut pas joindre le serveur**

L'employé (10.50.1.200/23) est dans le bon sous-réseau (10.50.0.0/23, plage .0.0 à .1.255). Sa gateway est 10.50.0.1 (Gi0/0.10) → OK.

Le serveur (10.50.2.60/26) :
- Avec un masque /26, son sous-réseau est 10.50.2.0/26 (plage .0 à .63)
- Sa gateway devrait être la premiere adresse de ce sous-réseau, soit 10.50.2.1
- Or 10.50.2.1 est l'IP de Gi0/0.**20** (Serveurs), qui est dans le bon VLAN

Mais attendons : dans notre plan VLSM, le sous-réseau Serveurs est 10.50.2.128/26, pas 10.50.2.0/26.

**Le problème principal** : les IPs des interfaces Gi0/0.20 et Gi0/0.30 sont **interverties**. Le VLAN 20 (Serveurs) a l'IP du sous-réseau Wi-Fi, et inversement.

Si le serveur est 10.50.2.60 avec masque /26, sa gateway est 10.50.2.1 → cette IP est sur Gi0/0.20 (VLAN 20). Le routage pourrait fonctionner localement, mais le plan d'adressage est incohérent avec la conception.

Correction : inverser les IPs des sous-interfaces 20 et 30.

**4. Wildcard mask pour le sous-réseau Employés (10.50.0.0/23)**

Masque /23 = 255.255.254.0
Wildcard = 255.255.255.255 - 255.255.254.0 = **0.0.1.255**

**5. ACL HTTP/HTTPS du VLAN Employés vers Serveurs**

En utilisant le plan corrigé (Serveurs = 10.50.2.128/26) :

```
ip access-list extended EMPLOYES-TO-SERVEURS
 permit tcp 10.50.0.0 0.0.1.255 10.50.2.128 0.0.0.63 eq 80
 permit tcp 10.50.0.0 0.0.1.255 10.50.2.128 0.0.0.63 eq 443
 deny ip 10.50.0.0 0.0.1.255 10.50.2.128 0.0.0.63
 permit ip any any
!
interface GigabitEthernet0/0.10
 ip access-group EMPLOYES-TO-SERVEURS in
```

Détail des wildcards :
- Employés (10.50.0.0/23) → wildcard **0.0.1.255**
- Serveurs (10.50.2.128/26) → wildcard **0.0.0.63**

**Vérification** : L'ACL autorise HTTP (80) et HTTPS (443) depuis le VLAN 10 vers le VLAN 20, refuse tout autre trafic vers les serveurs, et autorise le reste du trafic. ✓

</details>

---

## Recapitulatif des compétences

| Niveau | Compétences testées | Exercices |
|--------|---------------------|-----------|
| 1 - Basique | Conversions, calculs fondamentaux, classes | 1-10 |
| 2 - Subnetting standard | Découpage fixe, sous-réseaux, même réseau | 11-20 |
| 3 - VLSM | Plans d'adressage variables, overlap, alignement | 21-30 |
| 4 - Supernetting | Agrégation de routes, parasites, OSPF/BGP | 31-40 |
| 5 - Dépannage | ACL, wildcard, longest match, outputs CLI | 41-50 |

---

*Astuce finale : A l'examen CCNA, le subnetting revient dans presque tous les thèmes (routage, ACL, OSPF, NAT). Entrainez-vous jusqu'a pouvoir résoudre chaque exercice en moins de 60 secondes. La vitesse vient avec la pratique du magic number.*
