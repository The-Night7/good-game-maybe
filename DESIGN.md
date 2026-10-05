# Document de conception

> Document vivant : on le complète au fur et à mesure.

## Vision

Un MMORPG **agréable entre amis** (10 à 50 joueurs sur un même serveur), dans l'esprit
d'**Albion Online** (économie entre joueurs, l'équipement définit les compétences, combat en
temps réel) et de **Dofus** (univers 2D isométrique, métiers, ambiance), avec une
**timeline originale**.

## Piliers

1. **Jouer ensemble** : tout est plus fun en groupe, rien n'oblige à jouer seul ou
   à « farmer » des heures.
2. **Ce que tu portes, c'est ce que tu es** : pas de classe fixe, les armes et armures
   donnent les compétences (comme Albion).
3. **Une économie faite par les joueurs** : récolte, métiers, artisanat, échanges.
4. **Un monde qui a une histoire** : la timeline (à définir, voir plus bas).

## Choix techniques

| Sujet | Choix | Pourquoi |
|---|---|---|
| Moteur | Godot 4.3+ (GDScript) | Gratuit, exporte PC + Android + iOS, isométrique natif |
| Rendu | GL Compatibility | Fonctionne sur le plus de téléphones possible |
| Vue | 2D isométrique, tuiles 64×32 | Style Dofus |
| Réseau | Serveur autoritaire (vie, combat, butin, sac) ; position envoyée par le joueur pour rester fluide | Anti-triche raisonnable, confortable sur mobile |
| Contrôles | Clavier, clic/toucher pour se déplacer, D-pad virtuel optionnel | PC et mobile |

## Plateformes

**Priorité : la version mobile** (Android, puis iOS). Tout est pensé d'abord pour le tactile :
D-pad, toucher pour se déplacer, boutons à l'écran.

### Notes pour la version PC (plus tard)

- **Configuration du clavier au premier lancement** : proposer deux presets,
  **QWERTY** (WASD) et **AZERTY** (ZQSD), avec la disposition supposée d'après la langue du
  système mise en avant. Les flèches marchent toujours. Modifiable ensuite dans les Options.
- Clic gauche maintenu pour se déplacer (déjà en place, comme Albion).

## Feuille de route

- [x] **Étape 1** : carte isométrique, déplacement (D-pad, toucher), options
- [x] **Étape 2** : combat temps réel, monstres avec IA, compétences liées à l'arme, mort et réapparition
- [x] **Étape 3** : récolte, artisanat, sac, équipement, potions
- [x] **Étape 4** : multijoueur entre amis (hôte sur téléphone ou serveur dédié), sauvegarde chez l'hôte
- [ ] **Étape 5** : vrais graphismes (sprites, animations), sons et musique
- [ ] **Étape 6** : plusieurs zones et donjons, boss, paliers d'équipement (T1 → T4 comme Albion)
- [ ] **Étape 7** : la timeline (histoire, quêtes, événements du monde), guildes, marché entre joueurs
- [ ] **Étape 8** : serveur en ligne permanent, comptes, version PC

## Contenu actuel

| | |
|---|---|
| Armes | Épée (Taillade, Tourbillon, Fracas), Arc (Tir, Pluie de flèches, Tir perçant), Bâton (Boule de feu, Explosion, Soin de groupe) |
| Monstres | Slime (prairies), Slime de roche (zones de pierre) |
| Ressources | Bois (arbres), Minerai (rochers), Fibre (buissons), Gelée (monstres) |
| Artisanat | Potion de soin, Épée de fer, Arc de chasseur, Bâton de braise, Veste de cuir |

Tout l'équilibrage est dans `scripts/game_data.gd`.

## Timeline (à choisir)

- **A. Les Échos** : le monde évolue par ères ; les actions des joueurs décident de l'ère suivante.
- **B. Fracture** : chaque zone est figée à une époque différente, avec des portails entre elles.
- **C. Les Héritiers** : on joue la génération suivante et on découvre le passé à l'envers.
