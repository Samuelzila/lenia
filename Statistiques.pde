/*Statistiques proposées par Bert Chan dans son article original de lenia
 Pour les focntions spécifiques à un canal, la variable i indique de quel canal est tirée la statistique*/

//Les fonctions suivantes calculent la masse, soit la somme de tous les états des cellules [mg]

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

//Les fonctions suivantes calcules le volume, soit le nombre de cellules ayant un état plus grand de zéro [mm²]

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

//Les fonctions suivantes calculent la densitée, soit la masse divisée par son volume [mg/mm²]

//Par canal
float chanelDensity(int i) {
  return (chanelMass(i)/chanelVolume(i));
}

//Pour tous les canaux
float totalDensity () {
  return (totalMass()/totalVolume());
}

//Les fonctions suivantes calculent la croissance, somme de toutes les sorties de fonctions de croissance positives [mg/s]

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

//Par canal et en y
int chanelCentroidY(int i, float[] _world) {
  float centroid = 0;
  for (int x = 0; x < _world.length; x++) {
    centroid += (_world[x])*(x%WORLD_DIMENSIONS);
  }
  return int((centroid/chanelMass(i)));
}

//Pour tous les canaux et en y
int totalCentroidY(float [][] _world) {
  float centroid = 0;
  for (int i = 0; i < _world.length; i++) {
    centroid += chanelCentroidX(i, _world[i]);
  }
  return (int(centroid/world.length));
}

//Par canal et en x
int chanelCentroidX(int i, float[] world_) {
  float centroid = 0;
  for (int x = 0; x < world_.length; x++) {
    centroid += world_[x]*(floor(x/WORLD_DIMENSIONS));
  }
  return int((centroid/chanelMass(i)));
}

//Pour tous les canaux et en x
int totalCentroidX(float[][] _world) {
  float centroid = 0;
  for (int i = 0; i < _world.length; i++) {
    centroid += chanelCentroidY(i, _world[i]);
  }
  return (int(centroid/world.length));
}

//Par canal et en format  1D
//int chanelCentroid1D (int i, float[] _world) {
//return chanelCentroidX(i, _world) + WORLD_DIMENSIONS*chanelCentroidY(i, _world);
//}

//Pour tous les canaux et en format 1D
//int totalCentroid1D(float[][] _world) {
//return totalCentroidX(_world) + WORLD_DIMENSIONS*totalCentroidY(_world);
//}

//Les fonctions suivantes calculent le "centre de croissance" des états

//Par canal et en y
int chanelGrowthCenterY(int i, float[]_growthMatrix) {
  float center = 0;
  for (int x = 0; x < world[i].length; x++) {
    if (growthMatrix[i][x] > 0) {
      center += _growthMatrix[x]*(x%WORLD_DIMENSIONS);
    }
  }
  return int((center/chanelGrowth(i)));
}

//Pour tous les canaux et en y
int totalGrowthCenterY(float[][] _growthMatrix) {
  float center = 0;
  for (int i = 0; i < world.length; i++) {
    center += chanelGrowthCenterY(i, _growthMatrix[i]);
  }
  return (int(center/world.length));
}

//Par canal et en x
int chanelGrowthCenterX(int i, float[]_growthMatrix) {
  float center = 0;
  for (int x = 0; x < world[i].length; x++) {
    if (growthMatrix[i][x] > 0) {
      center += _growthMatrix[x]*(floor(x/WORLD_DIMENSIONS));
    }
  }
  return int((center/chanelGrowth(i)));
}

//Pour tous les canaux et en x
int totalGrowthCenterX(float[][] _growthMatrix) {
  float center = 0;
  for (int i = 0; i < world.length; i++) {
    center += chanelGrowthCenterX(i, _growthMatrix[i]);
  }
  return (int(center/world.length));
}

//Les prochaines fonctions calculent le centre de croissance de manière périodique
int chanelPeriodicGrowthCenterX (int c) {
 float center = 0;
for (int i = -WORLD_DIMENSIONS/2; i < WORLD_DIMENSIONS/2; i++) {
  for (int j = -WORLD_DIMENSIONS/2; j < WORLD_DIMENSIONS/2; j++) {
    int x  = Math.floorMod(chanelGrowthCenterX(c, growthMatrixBuffer[c]) + i, WORLD_DIMENSIONS);
    int y =Math.floorMod(chanelGrowthCenterY(c, growthMatrixBuffer[c]) + j, WORLD_DIMENSIONS);
    center += growthMatrix[c][WORLD_DIMENSIONS*x+y] * i;
  }
}

return int(center/chanelGrowth(c)+ chanelGrowthCenterX(c, growthMatrixBuffer[c]));
}

int periodicGrowthCenterX () {
  float growth = 0;
  for (int i = 0; i < world.length; i++) {
    growth += chanelPeriodicGrowthCenterX(i);
  }
  return int(growth / world.length);
}

int periodicGrowthCenterY () {
   float center = 0;
  for (int i = 0; i < world.length; i++) {
    center += chanelGrowthCenterY(i, growthMatrix[i]);
  }
  return (int(center/ world.length));
}


//Par canal et en format  1D
//int chanelGrowthCenter1D (int i, float[] _growthMatrix) {
//return chanelGrowthCenterX(i, _growthMatrix) + WORLD_DIMENSIONS*chanelGrowthCenterY(i, _growthMatrix);
//}

//Pour tous les canaux et en format 1D
//int totalGrowthCenter1D(float[][]_growthMatrix) {
//return totalGrowthCenterX(_growthMatrix) + WORLD_DIMENSIONS*totalGrowthCenterY(_growthMatrix);
//}

//Les fonctions suivantes calculent la distance entre le centre de masse et de croissance [mm]

//Par canal
float chanelGrowthCentroid(int i, float[] _world, float[]_growthMatrix) {
  return abs(dist(chanelGrowthCenterX(i, _growthMatrix), chanelGrowthCenterY(i, _growthMatrix), chanelCentroidX(i, _world), chanelCentroidY(i, _world)));
}

//Pour tous les canaux
float totalGrowthCentroid(float[][] _world, float[][] _growthMatrix) {
  return abs(dist(totalGrowthCenterX(_growthMatrix), totalGrowthCenterY(_growthMatrix), totalCentroidX(_world), totalCentroidY(_world)));
}

//Les fonctions suivantes calculent la vitesse de déplacement du centroïde [mm/s]

//Par canal
float chanelLinearSpeed(int i) {
  float chanelLinearSpeedX = (chanelCentroidX(i, world[i]) - chanelCentroidX(i, buffer[i]))/dt;
  float chanelLinearSpeedY = (chanelCentroidY(i, world[i]) - chanelCentroidY(i, buffer[i]))/dt;
  println(chanelCentroidX(i, world[i]));
  return sqrt(pow(chanelLinearSpeedX, 2) + pow(chanelLinearSpeedY, 2));
}

//Pour tous les canaux
float totalLinearSpeed() {
  float totalLinearSpeedX = 0;
  float totalLinearSpeedY = 0;
  for (int i = 0; i < world.length; i++) {
    totalLinearSpeedX += (chanelCentroidX(i, world[i]) - chanelCentroidX(i, buffer[i]))/dt;
    totalLinearSpeedY += (chanelCentroidY(i, world[i]) - chanelCentroidY(i, buffer[i]))/dt;
  }
  return sqrt(pow(totalLinearSpeedX, 2) + pow(totalLinearSpeedY, 2));
}

//Les fonctions suivantes calculent la vitesse angulaire du centroïde [rad/s]

//Pour un canal
float chanelAngularSpeed(int i) {
  float worldAngle = PI/2;
  float bufferAngle = PI/2;
  if (chanelCentroidX(i, world[i]) - chanelCentroidX(i, buffer[i]) != 0) {
  worldAngle = atan((chanelCentroidY(i, world[i]) - chanelCentroidY(i, buffer[i]))/(chanelCentroidX(i, world[i]) - chanelCentroidX(i, buffer[i])));
  }
  if ((chanelCentroidX(i, buffer[i]) - chanelCentroidX(i, buffer2[i])) != 0) {
  bufferAngle = atan((chanelCentroidY(i, buffer[i]) - chanelCentroidY(i, buffer2[i]))/(chanelCentroidX(i, buffer[i]) - chanelCentroidX(i, buffer2[i])));
  }
  return (worldAngle-bufferAngle)/2;
}

//Pour tous les canaux
float totalAngularSpeed() {
  float totalAngularSpeed = 0;
  for (int i = 0; i < world.length; i++) {
    totalAngularSpeed += chanelAngularSpeed(i)/world.length;
  }
  return totalAngularSpeed;
}

//Les prochaines fonctions caclculent l'assymétrie de masse, soit la différence de masse entre les deux cotés du vecteur de vitesse [mg]

//Par canal
float chanelMassAsymetry( int i) {
  float m = (chanelCentroidY(i, world[i]) - chanelCentroidY(i, buffer[i]))/(chanelCentroidX(i, world[i]) - chanelCentroidX(i, buffer[i]));
  float b = chanelCentroidY(i, world[i]) - m*chanelCentroidX(i, world[i]);
  float upMass = 0;
  float downMass = 0;
  for (int j = 0; j < world[i].length; j++) {
    if (floor(j/WORLD_DIMENSIONS) > m*(j%WORLD_DIMENSIONS)+b) {
      upMass += world[i][j];
    } else if (floor(j/WORLD_DIMENSIONS) < m*(j%WORLD_DIMENSIONS)+b) {
      downMass += world[i][j];
    }
  }
  return upMass-downMass;
}

//Pour tous les canaux
float totalMassAsymetry() {
    float upMass = 0;
  float downMass = 0;
  float m = 0;
  float b = 0;
  if (totalCentroidX(world) - totalCentroidX(buffer) != 0) {
  m = (totalCentroidY(world) - totalCentroidY(buffer))/(totalCentroidX(world) - totalCentroidX(buffer));
  b = totalCentroidY(world) - m*totalCentroidX(world);
  }
  upMass = 0;
  downMass = 0;
  for (int i = 0; i < world.length; i++) {
    for (int j = 0; j < world[i].length; j++) {
      if (floor(j/WORLD_DIMENSIONS) > m *(j%WORLD_DIMENSIONS)+b) {
        upMass += world[i][j];
      } else if (floor(j/WORLD_DIMENSIONS) < m*(j%WORLD_DIMENSIONS)+b) {
        downMass += world[i][j];
    } 
    }
    }
  return upMass-downMass;
}

//Fonctions pour afficher les statistiques
void showStatistics() {
  //Affichage de la masse
  fill(0);
  noStroke();
  rect(1140, 600, 750, 450);
  
  //Affichage de la masse
  fill(255);
  text("Masse totale : " + String.format("%.1f",totalMass()) + "mg", 1140, 625);

  //Affichage du volume
  text("Volume total : " + String.format("%.2f", totalVolume()) +"mm²" , 1140, 655);

  //Affichage de la densité
  text("Densité totale : " + String.format("%.4f", totalDensity()) + "mg/mm²", 1140, 685);

  //Affichage du centre de masse
  fill(150);
  circle(2*totalCentroidY(world), 2*totalCentroidX(world)+55, 20);

  //Affichage du centre de croissance
  fill(255);
  circle(2*totalGrowthCenterX(growthMatrix), 2*totalGrowthCenterY(growthMatrix)+55, 15);

  //Affichage distance du centroïde et du centre de croissance
  text("Distance centroïde centre de croissance: " + String.format("%.2f", chanelGrowthCentroid(0, world[0], growthMatrix[0])) + "mm", 1140, 715);
  
  //Affichage de la vitesse (scalaire)
  text("Vitesse de déplacement du centroïde: " + String.format("%.2f", totalLinearSpeed()) + "mm/s", 1140, 745);
  
  //Affichage de la vitesse angulaire
  text("Vitesse angulaire de déplacement du centroïde: " + String.format("%.3f", totalAngularSpeed()) + "rad/s", 1140, 775); 
 
 //Affichage de l'asymétrie de masse
    fill(255);
    if(totalCentroidX(world) - totalCentroidX(buffer) != 0) {
  text("Asymétrie de la masse: " + String.format("%.2f", totalMassAsymetry()) + "mg", 1140, 805);
    }
    
    //Affichage de l'asymétrie de masse en pourcentage
    if(totalCentroidX(world) - totalCentroidX(buffer) != 0) {
      text("Pourcentage d'asymétrie de la masse: " + String.format("%.3f",(totalMassAsymetry()/totalMass())*100) + "%", 1140, 835);
    }
}
