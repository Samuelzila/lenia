/*Statistiques proposées par Bert Chan dans son article original de lenia
 Pour les focntions spécifiques à un canal, la variable i indique de quel canal est tirée la statistique*/

//Les fonctions suivantes calculent la masse, soit la somme de tous les états des cellules [mg]

//Par canal
float chanelMass(int i) {
  int memoryIndex = getMemoryIndex();
  float mass = 0;
  for (int j = 0; j < world.get(memoryIndex)[i].length; j++) {
    mass += world.get(memoryIndex)[i][j];
  }
  return mass;
}

//Dans tous les canaux
float totalMass() {
  float mass = 0;
  for (int i = 0; i < world.get(getMemoryIndex()).length; i++) {
    mass += chanelMass(i);
  }
  return mass;
}

//Les fonctions suivantes calculent le "centre de masse" des états

//Par canal et en y
int chanelCentroidY(int i, float[] _world) {
  float centroid = 0;
  for (int j = 0; j < _world.length; j++) {
    int x = j/WORLD_DIMENSIONS;
    int y = j%WORLD_DIMENSIONS;
    centroid += _world[x*WORLD_DIMENSIONS + Math.floorMod(y - deplacementY, WORLD_DIMENSIONS)]*(y - deplacementY);
  }
  return int(centroid/chanelMass(i));
}

//Pour tous les canaux et en y
int totalCentroidY(float [][] _world) {
  float centroid = 0;
  for (int i = 0; i < _world.length; i++) {
    centroid += chanelCentroidY(i, _world[i]);
  }
  return (int(centroid/_world.length));
}

//Par canal et en x
int chanelCentroidX(int i, float[] world_) {
  float centroid = 0;
  for (int j = 0; j < world_.length; j++) {
    int x = j/WORLD_DIMENSIONS;
    int y = j%WORLD_DIMENSIONS;
    centroid += world_[Math.floorMod(x - deplacementX, WORLD_DIMENSIONS)*WORLD_DIMENSIONS + y]*(x - deplacementX);
  }
  return int(centroid/chanelMass(i));
}

//Pour tous les canaux et en x
int totalCentroidX(float[][] _world) {
  float centroid = 0;
  for (int i = 0; i < _world.length; i++) {
    centroid += chanelCentroidX(i, _world[i]);
  }
  return (int(centroid/_world.length));
}
