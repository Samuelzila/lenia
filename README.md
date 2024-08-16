# Lenia

Lenia UdeS 2024 !

(English version follows)

## Status du projet
Ce projet ayant été réalisé dans le contexte d'un stage de recherche à l'Université de Sherbrooke, nous n'avons pas l'intention de le maintenir au-delà du temps donné au cours du stage, soit l'été 2024.

## Description
Un programme pour explorer la famille d'automates cellulaires [Lenia](https://chakazul.github.io/lenia.html).

### Fonctionnalités
- Support pour de multiples noyaux de convolution dont il est possible de changer les paramètres en cours de simulation.
- Support pour jusqu'à trois canaux.
- Option pour utiliser l'algorithme FFT pour des noyaux qui en bénéficieraient.
- Option pour avoir des noyaux asymétriques, où les valeurs du haut sont plus importantes que celles du bas.
- Possibilité d'enregistrer des états puis de les charger lors d'une exécution ultérieure.
- Programme pour rendre des vidéos à partir des simulations.
- Des outils pour dessiner dans le monde de Lenia.
- Possibilité d'étamper des "créatures" de type *Orbium*.
- Une interface qui affiche diverses statistiques utiles à l'analyse des mondes. Les unités affichées sont celles proposées dans [l'article original de lenia par Bert Chan](https://arxiv.org/pdf/1812.05433). Les statistiques présentées sont les suivantes :
    - L'option *Canal choisi* détermine à partir de quel canal sont calculées les statistiques. Si l'option *tous* est sélectionnée, les statistiques sont calculées en tenant compte de tous les canaux.
    - La masse correspond à la somme de tous les états. Lorsque tous les canaux sont choisis, la masse affiche la somme des masses de tous les canaux.
    - Le volume correspond au nombre d'états non nuls dans la simulation. Comme pour la masse, le volume, lorsque tous les canaux sont choisis, correspond à la somme des volumes de tous les canaux.
    - La densité correspond à la masse divisée par le volume.
    - Le centroïde, aussi appelé centre de masse, est calculé par une moyenne de tous les emplacements des cellules de la grille, pondérée par leurs états. Ainsi, c'est le centre de tous les états.
    - Le centre de croissance est calculé, un peu comme le centroïde, par une moyenne de tous les emplacements sur la matrice de croissance (appelé *growthMatrix* dans le code), pondérée par leurs valeurs de croissance.
    - La distance centroïde centre de croissance correspond à la distance euclidienne entre le centroïde et le centre de croissance.
    - La vitesse de déplacement du centroïde correspond à la distance euclidienne entre le centroïde au temps t et au temps t-dt.
    - La vitesse angulaire de déplacement du centroïde correspond à la différence d'angle entre le vecteur de déplacement du centroïde au temps t et au temps t-dt.
    - L'asymétrie de masse correspond à la différence de masse entre les deux côtés du vecteur de déplacement du centroïde.
    - Le pourcentage d'asymétrie de la masse correspond au rapport entre l'asymétrie de la masse et de la masse, en pourcentage. (Cette statistique est la seule qui n'était pas proposée dans l'article de Chan)

## Visuels
<img src="/assets/orbium.gif" width="512" height="512" alt="Animated orbium"/><img src="/assets/hydrogenium.gif" width="512" height="512" alt="Animated hydrogenium" />

## Installation
Installez d'abord [l'éditeur de code *Processing*](https://processing.org/download).
Ouvrez le fichier lenia.pde et vous pourrez lancer le programme avec le bouton de lecture en haut à gauche ou CTRL+R.

## Utilisation

Il est recommandé d'utiliser une souris afin de faciliter l'utilisation de ce programme.

Bien que plusieurs paramètres puissent être modifiés pendant l'exécution, d'autres, comme le nombre de canaux, sont écrits directement dans le code. Ceux-ci sont dans les premières lignes de lenia.pde dans la section *Variables de configuration*.

Actuellement, notre programme ne permet pas de rendre des simulations qui ne sont pas dans un monde carré. En fonction de la machine utilisée, il se peut que le programme ne supporte pas non plus des mondes n'ayant pas des côtés qui sont des multiples de 32 ou de 64.

Plusieurs touches permettent d'interagir avec le programme :
- La touche *r* permet de réinitialiser tous les canaux avec du bruit de Perlin.
- La touche *n* permet de réinitialiser tous les canaux aléatoirement.
- La touche *c* permet de réinitialiser tous les canaux.
- La touche *o* active l'étampe de créature de type *Orbium* (aussi accessible directement dans l'interface).
- La touche *espace* met la simulation sur pause (aussi accessible directement dans l'interface).
- La touche *d* permet de réinitialiser le zoom et le déplacement.
- La touche *a* crée des noyaux aléatoires.

La souris permet d'interagir avec la simulation et avec l'interface : 
- En maintenant un clic droit de la souris dans la simulation, il est possible de faire glisser l'écran en déplaçant la souris.
-En utilisant un clic gauche de la souris dans la simulation, il est possible de modifier les états des cellules en fonction des paramètres de l'interface activés. Cette fonctionnalité est appelée *Pinceau*. Le mode standard du pinceau permet de changer l'état des cellules en cercle de rayon de 10 pixels avec une intensité de 0,50.

L'interface est interactive avec le clic gauche de la souris. Toutes les cases peuvent être basculées.
- La case *Pause* permet de basculer entre la simulation et le mode pause.
- La case *Enregistrer* permet de commencer l'enregistrement des états afin de les revisiter ultérieurement.
- La case *Charger un état* permet de charger un état enregistré précédemment ou un état téléchargé.
- La case *Efface* permet de basculer entre le mode *efface* et le mode standard du pinceau. Le mode *efface* permet d'effacer tous les états des cellules dans le rayon du pinceau en les fixant à 0.
- La case *Aléatoire* permet de basculer entre le mode aléatoire et le mode standard du pinceau. Le mode aléatoire permet de modifier les états des cellules dans le rayon du pinceau en utilisant du bruit de Perlin.
- La case *Carré* permet de basculer entre le mode carré et le mode standard du pinceau. Le mode carré permet de changer la forme du pinceau en carré avec des côtés de longueur rayon X 2.
- Le rayon du pinceau peut être modifié en cliquant sur l'icône *<* et *>* en modifiant la valeur par incréments de 1 pixel.
- L'intensité du pinceau peut être modifiée en cliquant sur l'icône *<* et *>* en modifiant la valeur par incréments de 0,05. L'intensité du pinceau correspond à l'état des pixels d'une valeur continue entre 0 et 1.
- Le canal où le pinceau interagit peut être modifié en cliquant sur l'icône *<* et *>* en modifiant la valeur par incréments de 1.
- La case *Canal* permet de basculer entre le mode canal et le mode standard du pinceau. Le mode canal permet de modifier tous les canaux en même temps à l'aide du pinceau.
- Les cases *1*, *2* et *3* permettent d'afficher seulement le canal ou les canaux sélectionnés.
- La case *Étampes* permet de basculer entre le mode étampe et le mode standard. Le mode étampe permet de modifier les cellules en fonction d'une étampe précise. Présentement, il n'y a qu'une seule étampe : un *Orbium*.
- L'angle permet de modifier l'angle de direction de l'orbium implémenté par l'étampe. L'angle des étampes peut être modifié en cliquant sur l'icône *<* et *>* en modifiant la valeur par incréments de 30 degrés.

Dans l'interface, il y a une section spécifique pour les noyaux et leurs paramètres.
Afin d'utiliser cette interface, la simulation est automatiquement mise sur pause.
- Le noyau concerné peut être modifié en cliquant sur l'icône *<* et *>* en modifiant la valeur par incréments de 1.
- Le rayon de convolution du noyau peut être modifié en cliquant sur l'icône *<* et *>* en modifiant la valeur par incréments de 4 cellules.
- Le paramètre μ (mu) peut être modifié en cliquant sur l'icône *<* et *>* en modifiant la valeur par incréments de 0,01. Ce paramètre représente le centre de croissance.
- Le paramètre σ (sigma) peut être modifié en cliquant sur l'icône *<* et *>* en modifiant la valeur par incréments de 0,001. Ce paramètre représente l'étalement de croissance.
- La fonction du cœur du noyau (*Core function*) peut être modifiée en cliquant sur l'icône *>*.
- La fonction de croissance peut être modifiée en cliquant sur l'icône *>*.
- L'entrée peut être modifiée en cliquant sur l'icône *<* et *>* en modifiant la valeur par incrément de 1. Ce paramètre représente le canal dans lequel la convolution est effectuée.
- La sortie peut être modifiée en cliquant sur l'icône *<* et *>* en modifiant la valeur par incrément de 1. Ce paramètre représente le canal dans lequel les valeurs de croissances obtenues suite à la convolution seront utilisées.
- Le poids peut être modifié en cliquant sur l'icône *<* et *>* en modifiant la valeur par incrément de 0,25. Ce paramètre influence le poids que le noyau aura dans son canal de sortie respectif.
- Afin d'appliquer les changements, il faut cliquer sur la case *Appiquer les changements* avant de reprendre la simulation.

Dans l'interface, il y a une section dédiée aux couleurs de la simulation.
Le mode de couleur utilisé est le HSB.
- La première barre représente les couleurs de la simulation actuelle, passant du 0 (cellule morte) à 1 (cellule vivante).
- Les barres de gauche représentent la couleur à 0 et les barres de droite représentent la couleur à 1.
- La première rangée de barres représente le paramètre de la teinte. La flèche entre les deux barres représente le sens dans la teinte que l'étalement de couleur prendra.
- La deuxième rangée de barres représente le paramètre de la saturation.
- La troisième rangée de barres représente le paramètre de luminosité. Il est fortement recommandé de laisser la luminosité du 0 au minimum lorsqu'il y a plus d'un canal dans la simulation.

### Sauvegarder et charger des états
Par défaut, le programme enregistre la première configuration de chaque simulation dans le répertoire *recordings*, dans un dossier nommé selon la date, précise aux millisecondes. Dans l'interface, un bouton permet d'enregistrer continuellement les états de la simulation.


Par la suite, un bouton permet de charger les états précédemment enregistrés au format *JSON*. Ceci chargera les valeurs des cellules ainsi que les paramètre de la simulation, comme les noyaux.

Quelques créatures sont fournies dans le répertoire *creatures*. Celles-ci peuvent être chargées comme les états enregistrés dans *recordings*

### FFT
Le programme offre l'option d'utiliser l'algorithme FFT pour les convolutions. Dans certaines situations, ceci permet de gagner en performance. En général, si le noyau de convolution est gros, il est pertinent d'utiliser FFT. Sinon, une convolution standard sera plus rentable.

### Noyaux asymétriques
Les noyaux asymétriques sont implémentés en générant un noyau normal, puis en le multipliant à un dégradé logarithmique. Si h est la position verticale d'une case dans la matrice du noyau, en partant du haut, la formule du dégradé est log2(h+1).

Les créatures fournies dans *creatures/asymetric/* nécessitent de manuellement configurer leurs noyaux pour être asymétriques dans l'interface.

### Rendre des vidéos
Un programme pour générer des vidéos est aussi fourni dans le répertoire *movieMaker*. Pour s'en servir, il faut d'abord avoir enregistré les états d'une simulation dans le programme principal. Ceci se fait depuis l'interface et enregistre les états dans *recordings*.
Par la suite, on peut lancer *movieMaker.pde* via l'éditeur de code *Processing*. Il n'y a pas d'interface, alors les paramètres de rendu sont à configurer directement dans le code. Comme pour *lenia.pde*, les variables de configuration sont au début du fichier.

Si ce n'est pas la première simulation, il est pertinent de supprimer le dossier *rendu*. Si c'est la première, on peut ignorer cette étape.

Une fois le programme en exécution, il demandera de choisir un dossier de simulation. Le programme convertira les états de la simulation en images au format *.tif* dans le dossier *rendu*.

Lorsque la conversion est terminée, le programme se fermera automatiquement.

On peut ensuite utiliser l'outil *Movie Maker* intégré à l'éditeur *Processing* dans la section *Tools* de la barre de navigation pour convertir ces images en vidéo. L'outil contient des instructions détaillées pour s'en servir.

## Support
Si vous voulez nous contacter, vous pouvez essayer de le faire à l'une des adresses courriel suivantes:

- bers3101@usherbrooke.ca
- samuel.cote13@usherbrooke.ca
- poum6502@usherbrooke.ca
- william.therrien.2003@gmail.com

## Objectifs
Voir [TODO.md](https://depot-rech.fsci.usherbrooke.ca/bisous/stages/lenia/-/blob/main/TODO.md?ref_type=heads)

## Auteurs et remerciements
Cette simulation a été implémentée à partir de l'article [Lenia — Biology of Artificial Life de Bert Chan](https://arxiv.org/pdf/1812.05433) ainsi que [Lenia and Expanded Universe de Bert Chan](https://arxiv.org/pdf/2005.03742).

L'idée du projet est venue de cette [vidéo](https://www.youtube.com/watch?v=PlzV4aJ7iMI) de David Louapre, qui explique très bien l'univers de Lenia.

## Licence
Ce projet est sous une [version modifiée de la licence MIT](https://depot-rech.fsci.usherbrooke.ca/bisous/stages/lenia/-/blob/main/LICENCE?ref_type=heads), qui interdit un usage commercial.

# English README

## Project Status
This project was done for a research internship at the Université de Sherbrooke, so we do not have the intention to maintain it further than the time given for our internship, which was the summer of 2024.

## Description
A program meant to explore the [Lenia](https://chakazul.github.io/lenia.html) family of cellular automata.

### Features
- Support for many convolution kernels which parameters can be changed during a simulation.
- Support for up to three channels without issues.
- Option to use of the FFT algorithm for kernels that can benefit it.
- Option for asymmetrical kernels, where the values of the top are more important than the one of the bottom. 
- Possibility of saving states and to load them during a later execution.
- Program for creating videos from simulations.
- Tools to draw in Lenia's world.
- Possibility of stamping "creatures" of type *Orbium*.
- An interface that shows many statistics useful to the analysis of worlds. The shown units are the ones presented in [the original article on Lenia by Bert Chan](https://arxiv.org/pdf/1812.05433). The presented statistics are the following:
    - The *Canal choisi* option (Selected channel) chooses from which channel are calculated the statistics. If the *tous* (all) option is selected, the statistics are calculated for all the channels.
    - The mass (shown as "Masse") is the sum of all states. When all the channels are selected, the mass shows the sum of the masses of all channels.
    - The volume (shown as "Volume") is the number of non-zero states. As for the mass, the volume shows the sum of the volumes of all channels when all the channels are selected.
    - The density (shown as "Densité") is the mass divided by the volume.
    - The centroid (shown as "Centroïde"), also known as the centre of mass, is calculated by the median of all the placements of the cells on the grid, weighted by the value of their states. In that way, it is the centre of all states.
    - The growth centre (shown as "Centre de croissance") is calculated, just like the centroid, by the median of all the placements on the growth matrix (called *growthMatrix* in the code), weighted by their growth values.
    - The centroid-growth centre distance (shown as "Distance centroïde centre de croissance") is the euclidean distance between the centroid and the growth centre.
    - The linear speed (shown as "Vitesse de déplacement du centroïde") is the euclidean distance between the centroid at the time t and time t-dt.
    - The angular speed (shown as "Vitesse angulaire de déplacement du centroïde") is the difference of angle between the displacement vector of the centroid at the time t and t-dt.
    - The mass asymmetry (shown as "Asymétrie de masse") is the mass difference between the two sides of the displacement vector of the centroid.
    - The percentage of mass asymmetry (show as "Pourcentage d'asymétrie de masse") is the ratio of the mass asymmetry by the mass, in percentage. (This statistic is the only one that was not presented if Chan's article.)

## Visuals
<img src="/assets/orbium.gif" width="512" height="512" alt="Animated orbium"/><img src="/assets/hydrogenium.gif" width="512" height="512" alt="Animated hydrogenium" />

## Installation
Start by installing the [*Processing* code editor](https://processing.org/download).

Then, open the lenia.pde file and you can run the program with the play button in the top left or with CTRL+R.

## Usage
It is recommended to use a mouse to use this program.

Even if many parameters can be modified during the execution, others, like the number of channels, are written directly into the code. These are in the first lines of the lenia.pde file in the *Variables de configuration* (configuration variables) section.

Our program can not create simulations in a non-square world. Depending on the computer, it is possible that the program does not support worlds that do not have sides that are multiples of 32 or 64.

Many keys can be used to interact with the simulation:
- The *r* key resets all the channels with a Perlin noise.
- The *n* key resets all the channels randomly.
- The *c* key clears all the channels.
- The *o* key activates the creature stamp of type *Orbium*.
- The space key pauses the simulation (also accessible in the interface).
- The *d* key resets the zoom and the displacement.
- The *a* key randomizes the kernels.

The mouse can interact with the simulation and the interface : 
- By keeping a right click in the simulation, the screen can be glided by moving the mouse.
- By using a left click in the simulation, the states of the cells can be changed depending on the parameters of the interface. This functionality is called "Pinceau" (brush). The standard mode of the brush can change the cell states in a circle with a 10 pixels radius and an intensity of 0.50.

The interface is interactive with the left click. All the squares can be selected.
- The square *Pause* (pause) pauses the simulation.
- The square *Enregister* (save) saves the states of the simulation so they can be reused later.
- The square *Charger un état* (load state) loads a saved or downloaded state into the simulation.
- The square *Efface* (eraser) switches between the eraser mode and the standard mode of the brush. The eraser mode erases all the states of the cells in the radius of the brush by setting them to zero.
- The square *Carré* (square) switches between the square mode and the standard mode of the brush. The square mode changes the shape of the brush into a square of side radius X 2.
- The radius of the brush can be modified by pressing on *<* and *>* in the *Rayon pinceau* section (brush radius). The value changes by 1 pixel steps.
- The intensity of the brush can be modified by pressing on *<* and *>* in the *Intensité* section (intensity). The value changes by 0.05 steps. The intensity is the state of a pixel, between 0 and 1.
- The channel in which the brush interacts can be modified by pressing on *<* and *>* in the *Canal* section (channel).
- The square *Canal* (channel) switches between the channel mode and the standard mode. The channel mode changes the values of all the channels with the brush.
- The *1*, *2*, and *3* squares offer the possibility to show only the selected channel or channels.
- The square *Étampes* (stamps) switches between stamp and standard mode. The stamp mode can change the cell configuration according to a precise stamp. Now, we only have one stamp: an *Orbium*.
- The  angle of the stamp can be modified below the *stamp* square. Its angle can be modified by pressing on *<* and *>* in the *Angle* section (angle). The value is changed by steps of 30 degrees.

In the interface, there is a specific section for the kernels and their parameters.
When using it, the simulation is automatically paused.
- The selected kernel can be modified by pressing on *<* and *>* in the *Canal* section (channel). 
- The radius of the kernel can be modified by pressing on *<* and *>* in the *Rayon* section (radius). The value is changed by steps of 4 pixels.
- The μ (mu) parameter can be modified by pressing on *<* and *>* in the *mu* section. The value is changed by steps of 0.01. This parameter controls the centre value of growth function.
- The σ (sigma) parameter can be modified by pressing on *<* and *>* in the *sigma* section. The value is changed by steps 0.001. This parameter controls the spread of the growth function.
- The core function of the kernel can be modified by pressing on *>* in the *Fonction du coeur* (core function) section.
- The growth function associated with the kernel can be modified by pressing on *>* in the *Fonction de croissance* (growth function) section.
- The input of the kernel can be modified by pressing on *<* and *>* in the *Entrée* section (input). This parameter controls the channel in which the convolution is made.
- The output of the kernel can be modified by pressing on *<* and *>* in the *Sortie* section (output). This parameter controls the channel in which the growth values calculated with the convolution and the growth function are used.
- The weigth of the kernel can be modified by pressing on *<* and *>* in the *Poids* section (weigth). The value changes by steps of 0.25. This parameter controls the weigth of the kernel in its output channel.
- Changes will be saved and applied when *Appliquer les changement* (Apply changes) is pressed.

In the interface, there is a section dedicated to the colours of the simulation.
The colour mode is HSB.
- The first bar shows the present colours of the simulation, starting with the one associated with a state of zero (dead cell) up to the one associated with a state of one (alive cell).
- The left bars show the colours associated with the state of zero and the right ones the colours associated with the states of one.
- The first row of bars shows the tint parameter. The arrow between the two bars indicates the way used for the colour spread.
- The second row of bars shows the saturation parameters.
- The third row of bars shows the brightness parameter. When there is more than one channel, we strongly recommend to set the brightness of the state 0 at the minimum.

### Saving and loading states
By default, the program saves the first configuration of every the simulation in the *recordings* repository, in a folder named after the date, with a millisecond accuracy. In the interface, a button ("Enregistrer") saves the simulation states continuously.

Later, the "Charger un état" button can load the states that were previously saved in the *JSON* format. It loads the values of the cells and the parameters of the simulation, like the kernels, for example.

A few creatures are provided in the *creatures* repository. They can be loaded like the states saved in *recordings*.

### FFT
The program offers the option to use the FFT algorithm for the convolutions. In certain situations, it can improve the performance. In general, if the convolution kernel is big, it is pertinent to use FFT. Otherwise, a standard convolution is more efficient.

### Asymmetrical kernels
Asymmetrical kernels are implemented by generating a normal kernel, then multiplying it by a logarithmic gradient. If h is the vertical position of a cell in the kernel matrix, starting from the top, the gradient formula is log2(h+1).

Creatures in *creatures/asymetric/* need to have their kernels manually set to asymetric from the interface.

### Creating videos
A program for generating videos is also provided in the *movieMaker* repository. To use it, states of a previous simulation in the main program must be saved already. This can be done by using the interface and the states are saved in *recordings*.

Next, open *movieMaker.pde* via *Procssing*. There is no interface, so the video parameters must be set directly in the code. As in *Lenia.pde*, the configuration variables are at the beginning of the file.

If it is not the first simulation, it is pertinent to delete the *rendu* repository. If it is the first one, this step can be ignored.

Once the program is running, it will ask to choose a simulation repository. The program will convert the states of the simulations into images in the *.tif* format in the *rendu* repository.

Then, *Movie Maker* from the *Tools* section of *Processing*'s navigation bar can be used to convert those images to a video. The tool has its own detailed instructions.

## Support
To contact us, you can try to use one of the following addresses:

- bers3101@usherbrooke.ca
- samuel.cote13@usherbrooke.ca
- poum6502@usherbrooke.ca
- william.therrien.2003@gmail.com


## Goals
See [TODO.md](https://depot-rech.fsci.usherbrooke.ca/bisous/stages/lenia/-/blob/main/TODO.md?ref_type=heads)

## Authors and acknowledgements
This project is based on [Lenia — Biology of Artificial Life by Bert Chan](https://arxiv.org/pdf/1812.05433) and [Lenia and Expanded Universe by Bert Chan](https://arxiv.org/pdf/2005.03742).

The idea of the project came from this french [video](https://www.youtube.com/watch?v=PlzV4aJ7iMI) by David Louapre, that explains the universe of Lenia.

## Licence
This project is under a [modified MIT licence](https://depot-rech.fsci.usherbrooke.ca/bisous/stages/lenia/-/blob/main/LICENCE?ref_type=heads) which prohibits commercial use.
