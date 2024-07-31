/*Statistiques proposées par Bert Chan dans son article original de lenia
 Pour les focntions spécifiques à un canal, la variable i indique de quel canal est tirée la statistique*/

//Les fonctions suivantes calculent la somme de tous les états des cellules :

//Par canal
float chanelMass(int i) {
  float mass = 0;
  for (int j = 0; j < world[i].length; j++) {
    mass += world[i][j];
  }
  return mass;
}

//Dans tous les canaux
float totalMass() {
  float mass = 0;
  for (int i = 0; i < world.length; i++) {
    mass += chanelMass(i);
  }
  return mass;
}

//Les focntions suivantes calcules le nombre de cellules ayant un état plus grand de zéro

//Par canal
float chanelVolume(int i) {
  float volume = 0;
  for (int j = 0; j < world[i].length; j++) {
    if (world[i][j] > 0) {
      volume++;
    }
  }
  return volume;
}

//Dans tous les canaux
float totalVolume () {
  float volume = 0;
  for (int i = 0; i < world.length; i++) {
    volume += chanelVolume(i);
  }
  return volume;
}

//Les fonctions suivantes calculent la densitée, soit la masse divisée par son volume

//Par canal
float chanelDensity(int i) {
  return (chanelMass(i)/chanelVolume(i));
}

//Pour tous les canaux
float totalDensity () {
  return (totalMass()/totalVolume());
}

//Les fonctions suivantes calculent la somme de toutes les croissances positives

//Par canal
float chanelGrowth(int i) {
  float growth = 0;
   for (int j = 0; j < world[i].length; j++) {
     if (growthMatrix[i][j] > 0) {
     growth += growthMatrix[i][j];
   }
   }
   return growth;
 }

//Pour tous les canaux
float totalGrowth() {
  float growth = 0;
  for (int i = 0; i < world.length; i++) {
    growth += chanelGrowth(i);
  }
  return growth;
}

//Les fonctions suivantes calculent le "centre de masse" des états

//Par canal et en x
int chanelCentroidX(int i, float[] _world) {
  float centroid = 0;
  for (int x = 0; x < _world.length; x++) {
    centroid += _world[x]*(x%WORLD_DIMENSIONS);
  }
  return int((centroid/chanelMass(i)));
}

//Pour tous les canaux et en x
int totalCentroidX(float [][] _world) {
  float centroid = 0;
  for (int i = 0; i < _world.length; i++) {
    centroid += chanelCentroidX(i, _world[i]);
  }
  return (int(centroid/3));
}

//Par canal et en y
int chanelCentroidY(int i, float[] world_) {
  float centroid = 0;
  for (int x = 0; x < world_.length; x++) {
    centroid += world_[x]*(floor(i/WORLD_DIMENSIONS));
  }
  return int((centroid/chanelMass(i)));
}

//Pour tous les canaux et en y
int totalCentroidY(float[][] _world) {
  float centroid = 0;
  for (int i = 0; i < _world.length; i++) {
    centroid += chanelCentroidY(i, _world[i]);
  }
  return (int(centroid/3));
}

//Par canal et en format  1D
int chanelCentroid1D (int i, float[] _world) {
  return chanelCentroidX(i, _world) + WORLD_DIMENSIONS*chanelCentroidY(i, _world);
}

//Pour tous les canaux et en format 1D
int totalCentroid1D(float[][] _world) {
  return totalCentroidX(_world) + WORLD_DIMENSIONS*totalCentroidY(_world);
}

//Les fonctions suivantes calculent le "centre de croissance" des états

//Par canal et en x
int chanelGrowthCenterX(int i, float[]_growthMatrix) {
  float center = 0;
  for (int x = 0; x < world[i].length; x++) {
    center += _growthMatrix[x]*(x%WORLD_DIMENSIONS);
  }
  return int((center/chanelMass(i)));
}

//Pour tous les canaux et en x
int totalGrowthCenterX(float[][] _growthMatrix) {
  float center = 0;
  for (int i = 0; i < world.length; i++) {
    center += chanelGrowthCenterX(i, _growthMatrix[i]);
  }
  return (int(center/3));
}

//Par canal et en y
int chanelGrowthCenterY(int i, float[]_growthMatrix) {
  float center = 0;
  for (int x = 0; x < world[i].length; x++) {
    center += _growthMatrix[x]*(floor(i/WORLD_DIMENSIONS));
  }
  return int((center/chanelMass(i)));
}

//Pour tous les canaux et en y
int totalGrowthCenterY(float[][] _growthMatrix) {
  float center = 0;
  for (int i = 0; i < world.length; i++) {
    center += chanelGrowthCenterY(i, _growthMatrix[i]);
  }
  return (int(center/3));
}

//Par canal et en format  1D
int chanelGrowthCenter1D (int i, float[] _growthMatrix) {
  return chanelGrowthCenterX(i, _growthMatrix) + WORLD_DIMENSIONS*chanelGrowthCenterY(i, _growthMatrix);
}

//Pour tous les canaux et en format 1D
int totalGrowthCenter1D(float[][]_growthMatrix) {
  return totalGrowthCenterX(_growthMatrix) + WORLD_DIMENSIONS*totalGrowthCenterY(_growthMatrix);
}

//Les fonctions suivantes calculent la distance entre le centre de masse et de croissance

//Par canal
float chanelGrowthCentroid(int i, float[] _world, float[]_growthMatrix) {
  return abs(dist(chanelGrowthCenterX(i, _growthMatrix), chanelGrowthCenterY(i, _growthMatrix), chanelCentroidX(i, _world), chanelCentroidY(i, _world)));
}

//Pour tous les canaux
float totalGrowthCentroid(float[][] _world, float[][] _growthCenter) {
  return abs(dist(totalGrowthCenterX(_growthCenter), totalGrowthCenterY(_growthCenter), totalCentroidX(_world), totalCentroidY(_world)));
}

float chanellinearSpeed(int i) {
  return (chanelGrowthCentroid(i, world[i], growthMatrix[i])-chanelGrowthCentroid(i, buffer[i], growthMatrix[i]))/dt;
}

float totallinearSpeed() {
  return (totalGrowthCentroid(world, growthMatrix)-totalGrowthCentroid(buffer, growthMatrix))/dt;
}
