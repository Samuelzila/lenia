/*Statistiques proposées par Bert Chan dans son article original de lenia
 Pour les focntions spécifiques à un canal, la variable i indique de quel canal est tirée la statistique*/

//Les fonctions suivantes calculent la masse, soit la somme de tous les états des cellules [mg]

//Par canal
float channelMass(int i) {
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
    mass += channelMass(i);
  }
  return mass;
}

//Les fonctions suivantes calcules le volume, soit le nombre de cellules ayant un état plus grand de zéro [mm²]

//Par canal
float channelVolume(int i) {
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
    volume += channelVolume(i);
  }
  return volume;
}

//Les fonctions suivantes calculent la densitée, soit la masse divisée par son volume [mg/mm²]

//Par canal
float channelDensity(int i) {
  return (channelMass(i)/channelVolume(i));
}

//Pour tous les canaux
float totalDensity () {
  return (totalMass()/totalVolume());
}

//Les fonctions suivantes calculent la croissance, somme de toutes les sorties de fonctions de croissance positives [mg/s]

//Par canal
float channelGrowth(int i) {
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
    growth += channelGrowth(i);
  }
  return growth;
}

//Les fonctions suivantes calculent le "centre de masse" des états

//Par canal et en y
int channelCentroidY(int i, float[] _world) {
  float centroid = 0;
  for (int j = 0; j < _world.length; j++) {
    int x = j/WORLD_DIMENSIONS;
    int y = j%WORLD_DIMENSIONS;
    centroid += _world[x*WORLD_DIMENSIONS + Math.floorMod(y - pOriginY[i], WORLD_DIMENSIONS)]*(y - pOriginY[i]);
  }
  //Centroïde modulé et normalisé.
  int normalizedCentroid = Math.floorMod(int((centroid/channelMass(i))), WORLD_DIMENSIONS);
  pOriginY[i] = WORLD_DIMENSIONS/2 - normalizedCentroid;
  return normalizedCentroid;
}

//Pour tous les canaux et en y
int totalCentroidY(float [][] _world) {
  float centroid = 0;
  for (int i = 0; i < _world.length; i++) {
    centroid += channelCentroidY(i, _world[i]);
  }
  return (int(centroid/world.length));
}

//Par canal et en x
int channelCentroidX(int i, float[] world_) {
  float centroid = 0;
  for (int j = 0; j < world_.length; j++) {
    int x = j/WORLD_DIMENSIONS;
    int y = j%WORLD_DIMENSIONS;
    centroid += world_[Math.floorMod(x - pOriginX[i], WORLD_DIMENSIONS)*WORLD_DIMENSIONS + y]*(x - pOriginX[i]);
  }
  //Centroïde modulé et normalisé.
  int normalizedCentroid = Math.floorMod(int(centroid/channelMass(i)), WORLD_DIMENSIONS);
  pOriginX[i] = WORLD_DIMENSIONS/2 - normalizedCentroid;
  return normalizedCentroid;
}

//Pour tous les canaux et en x
int totalCentroidX(float[][] _world) {
  float centroid = 0;
  for (int i = 0; i < _world.length; i++) {
    centroid += channelCentroidX(i, _world[i]);
  }
  return (int(centroid/world.length));
}

//Par canal et en format  1D
//int channelCentroid1D (int i, float[] _world) {
//return channelCentroidX(i, _world) + WORLD_DIMENSIONS*channelCentroidY(i, _world);
//}

//Pour tous les canaux et en format 1D
//int totalCentroid1D(float[][] _world) {
//return totalCentroidX(_world) + WORLD_DIMENSIONS*totalCentroidY(_world);
//}

//Les fonctions suivantes calculent le "centre de croissance" des états

//Par canal et en y
int channelGrowthCenterY(int i, float[]_growthMatrix) {
  float center = 0;
  for (int x = 0; x < world[i].length; x++) {
    if (growthMatrix[i][x] > 0) {
      center += _growthMatrix[x]*(x%WORLD_DIMENSIONS);
    }
  }
  return int((center/channelGrowth(i)));
}

//Pour tous les canaux et en y
int totalGrowthCenterY(float[][] _growthMatrix) {
  float center = 0;
  for (int i = 0; i < world.length; i++) {
    center += channelGrowthCenterY(i, _growthMatrix[i]);
  }
  return (int(center/world.length));
}

//Par canal et en x
int channelGrowthCenterX(int i, float[]_growthMatrix) {
  float center = 0;
  for (int x = 0; x < world[i].length; x++) {
    if (growthMatrix[i][x] > 0) {
      center += _growthMatrix[x]*(floor(x/WORLD_DIMENSIONS));
    }
  }
  return int((center/channelGrowth(i)));
}

//Pour tous les canaux et en x
int totalGrowthCenterX(float[][] _growthMatrix) {
  float center = 0;
  for (int i = 0; i < world.length; i++) {
    center += channelGrowthCenterX(i, _growthMatrix[i]);
  }
  return (int(center/world.length));
}

//Les prochaines fonctions calculent le centre de croissance de manière périodique
int channelPeriodicGrowthCenterX (int c) {
  float center = 0;
  for (int i = -WORLD_DIMENSIONS/2; i < WORLD_DIMENSIONS/2; i++) {
    for (int j = -WORLD_DIMENSIONS/2; j < WORLD_DIMENSIONS/2; j++) {
      int x  = Math.floorMod(channelGrowthCenterX(c, growthMatrixBuffer[c]) + i, WORLD_DIMENSIONS);
      int y =Math.floorMod(channelGrowthCenterY(c, growthMatrixBuffer[c]) + j, WORLD_DIMENSIONS);
      center += growthMatrix[c][WORLD_DIMENSIONS*x+y] * i;
    }
  }


  return int(center/channelGrowth(c)+ channelGrowthCenterX(c, growthMatrixBuffer[c]));
}

int periodicGrowthCenterX () {
  float growth = 0;
  for (int i = 0; i < world.length; i++) {
    growth += channelPeriodicGrowthCenterX(i);
  }
  return int(growth / world.length);
}

int periodicGrowthCenterY () {
  float center = 0;
  for (int i = 0; i < world.length; i++) {
    center += channelGrowthCenterY(i, growthMatrix[i]);
  }
  return (int(center/ world.length));
}


//Par canal et en format  1D
//int channelGrowthCenter1D (int i, float[] _growthMatrix) {
//return channelGrowthCenterX(i, _growthMatrix) + WORLD_DIMENSIONS*channelGrowthCenterY(i, _growthMatrix);
//}

//Pour tous les canaux et en format 1D
//int totalGrowthCenter1D(float[][]_growthMatrix) {
//return totalGrowthCenterX(_growthMatrix) + WORLD_DIMENSIONS*totalGrowthCenterY(_growthMatrix);
//}

//Les fonctions suivantes calculent la distance entre le centre de masse et de croissance [mm]

//Par canal
float channelGrowthCentroid(int i, float[] _world, float[]_growthMatrix) {
  return abs(dist(channelGrowthCenterX(i, _growthMatrix), channelGrowthCenterY(i, _growthMatrix), channelCentroidX(i, _world), channelCentroidY(i, _world)));
}

//Pour tous les canaux
float totalGrowthCentroid(float[][] _world, float[][] _growthMatrix) {
  return abs(dist(totalGrowthCenterX(_growthMatrix), totalGrowthCenterY(_growthMatrix), totalCentroidX(_world), totalCentroidY(_world)));
}

//Les fonctions suivantes calculent la vitesse de déplacement du centroïde [mm/s]

//Par canal
float channelLinearSpeed(int i) {
  float channelLinearSpeedX = (channelCentroidX(i, world[i]) - channelCentroidX(i, buffer[i]))/dt;
  float channelLinearSpeedY = (channelCentroidY(i, world[i]) - channelCentroidY(i, buffer[i]))/dt;
  return sqrt(pow(channelLinearSpeedX, 2) + pow(channelLinearSpeedY, 2));
}

//Pour tous les canaux
float totalLinearSpeed() {
  float totalLinearSpeedX = 0;
  float totalLinearSpeedY = 0;
  for (int i = 0; i < world.length; i++) {
    totalLinearSpeedX += (channelCentroidX(i, world[i]) - channelCentroidX(i, buffer[i]))/dt;
    totalLinearSpeedY += (channelCentroidY(i, world[i]) - channelCentroidY(i, buffer[i]))/dt;
  }
  return sqrt(pow(totalLinearSpeedX, 2) + pow(totalLinearSpeedY, 2));
}

//Les fonctions suivantes calculent la vitesse angulaire du centroïde [rad/s]

//Pour un canal
float channelAngularSpeed(int i) {
  float worldAngle = PI/2;
  float bufferAngle = PI/2;
  if (channelCentroidX(i, world[i]) - channelCentroidX(i, buffer[i]) != 0) {
    worldAngle = atan((channelCentroidY(i, world[i]) - channelCentroidY(i, buffer[i]))/(float)(channelCentroidX(i, world[i]) - channelCentroidX(i, buffer[i])));
  }
  if ((channelCentroidX(i, buffer[i]) - channelCentroidX(i, buffer2[i])) != 0) {
    bufferAngle = atan((channelCentroidY(i, buffer[i]) - channelCentroidY(i, buffer2[i]))/(float)(channelCentroidX(i, buffer[i]) - channelCentroidX(i, buffer2[i])));
  }
  return (worldAngle-bufferAngle)/2;
}

//Pour tous les canaux
float totalAngularSpeed() {
  float totalAngularSpeed = 0;
  for (int i = 0; i < world.length; i++) {
    totalAngularSpeed += channelAngularSpeed(i)/world.length;
  }
  return totalAngularSpeed;
}

//Les prochaines fonctions caclculent l'assymétrie de masse, soit la différence de masse entre les deux cotés du vecteur de vitesse [mg]

//Par canal
float channelMassAsymetry() {
  if (channelCentroidX(selectedchannelStat-1, world[selectedchannelStat-1])-channelCentroidX(selectedchannelStat-1, buffer[selectedchannelStat-1]) != 0) {
    float upMass = 0;
    float downMass = 0;

    float m = 0;
    float b = 0;
    if (totalCentroidX(world) - totalCentroidX(buffer) != 0) {
      m = (totalCentroidY(world) - totalCentroidY(buffer))/(float)(totalCentroidX(world) - totalCentroidX(buffer));
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

    return(upMass-downMass);
  } else {
    return 0;
  }
}

float totalMassAsymetry() {
  if (totalCentroidX(world)-totalCentroidX(buffer) != 0) {
    float upMass = 0;
    float downMass = 0;
    float m = float((totalCentroidY(world) - totalCentroidY(buffer))/(totalCentroidX(world)-totalCentroidX(buffer)));
    float b = totalCentroidY(world) - totalCentroidX(world)*m;
    for (int i = 0; i < world.length; i++) {
      for (int x = 0; x < WORLD_DIMENSIONS; x++) {
        for (int y = 0; y < WORLD_DIMENSIONS; y++) {
          if (y > m*x+b) {
            upMass += world[i][y+WORLD_DIMENSIONS*x];
          } else if (y < m*x+b) {
            downMass += world[i][y+WORLD_DIMENSIONS*x];
          }
        }
      }
    }
    return(upMass-downMass);
  } else {
    return 0;
  }
}




//Fonctions pour afficher les statistiques
void showStatistics() {
  textAlign(LEFT);
  textSize(30);
  indiceStat = 0;

  fill(0);
  noStroke();
  rect(coordonneeXStat, 600, 750, 450);

  //Affichage pour les changements de canaux
  fill(255);
  if (selectedchannelStat != 0) {
    text("Canal choisi : <  " + (int(selectedchannelStat)-1) + "  >", coordonneeXStat, initialYStat + ecartStat*indiceStat);
  } else {
    text("Canal choisi : <tous>", coordonneeXStat, initialYStat + ecartStat*indiceStat);
  }

  stroke(255);
  strokeWeight(2);
  if (showCentroid) {
    fill(192);
  } else {
    fill(0);
  }
  square(1100, ecartStat*10 + initialYStat - 20, 20);
  fill(255);
  text("Afficher le centroïde", coordonneeXStat, initialYStat + ecartStat*10);

  stroke(255);
  strokeWeight(2);
  if (showGrowthCenter) {
    fill(192);
  } else {
    fill(0);
  }
  square(1100, ecartStat*11 + initialYStat - 20, 20);
  fill(255);
  text("Afficher le centre de croissance", coordonneeXStat, initialYStat + ecartStat*11);

  stroke(255);
  strokeWeight(2);
  fill(255);
  text("Afficher le vecteur de déplacement", coordonneeXStat, initialYStat + ecartStat*12);
  if (showVector) {
    fill(192);
  } else {
    fill(0);
  }
  square(1100, ecartStat*12 + initialYStat - 20, 20) ;


  if (selectedchannelStat == 0 ) {
    //Affichage de la masse
    fill(255);
    indiceStat ++;
    text("Masse totale : " + String.format("%.1f", totalMass()) + "mg", coordonneeXStat, initialYStat + ecartStat*indiceStat);

    //Affichage du volume
    indiceStat++;
    text("Volume total : " + String.format("%.2f", totalVolume()) +"mm²", coordonneeXStat, initialYStat + ecartStat*indiceStat);

    //Affichage de la densité
    indiceStat++;
    text("Densité totale : " + String.format("%.4f", totalDensity()) + "mg/mm²", coordonneeXStat, initialYStat + ecartStat*indiceStat);

    //Affichage du centre de masse
    if (showCentroid) {
      fill(150);
      noStroke();
      int positionX = totalCentroidX(world) + deplacementX;
      int positionY = totalCentroidY(world) + deplacementY;
      int positionPixelX = positionX*(zoom*1024/WORLD_DIMENSIONS);
      int positionPixelY = positionY*(zoom*1024/WORLD_DIMENSIONS) + 55;
      if (positionPixelX > 1 && positionPixelX < 1009 && positionPixelY > 75 && positionPixelY < 1064) {
        circle(positionPixelX, positionPixelY, 15);
      }
    }

    if (showVector) {
      stroke(255);

      int positionX = totalCentroidX(world) + deplacementX;
      int positionY = totalCentroidY(world) + deplacementY;
      int positionPixelX = positionX*(zoom*1024/WORLD_DIMENSIONS);
      int positionPixelY = positionY*(zoom*1024/WORLD_DIMENSIONS) + 55;
      int positionXBuffer = totalCentroidX(buffer) + deplacementX;
      int positionYBuffer = totalCentroidY(buffer) + deplacementY;
      int positionPixelXBuffer = positionXBuffer*(zoom*1024/WORLD_DIMENSIONS);
      int positionPixelYBuffer = positionYBuffer*(zoom*1024/WORLD_DIMENSIONS) + 55;
      if (positionPixelX > 1 && positionPixelX < 1009 && positionPixelY > 75 && positionPixelY < 1064 && positionPixelXBuffer > 1 && positionPixelXBuffer < 1009 && positionPixelXBuffer > 1 && positionPixelXBuffer < 1009 && positionPixelYBuffer > 75 && positionPixelYBuffer < 1064) {
        line(positionPixelX + (positionPixelX-positionPixelXBuffer)*5, positionPixelY + (positionPixelY-positionPixelYBuffer)*5, positionPixelXBuffer, positionPixelYBuffer);
      }
    }

    //Affichage du centre de croissance
    if (showGrowthCenter) {
      fill(255);
      int positionX = totalGrowthCenterX(growthMatrix) + deplacementX;
      int positionY = totalGrowthCenterY(growthMatrix) + deplacementY;
      int positionPixelX = positionX*(zoom*1024/WORLD_DIMENSIONS);
      int positionPixelY = positionY*(zoom*1024/WORLD_DIMENSIONS) + 55;
      if (positionPixelY > 1 && positionPixelY < 1009 && positionPixelX > 75 && positionPixelX < 1064) {
        circle(positionPixelX, positionPixelY, 15);
      }
    }
    fill(255);

    //Affichage distance du centroïde et du centre de croissance
    indiceStat++;
    text("Distance centroïde centre de croissance: " + String.format("%.2f", abs(totalGrowthCentroid(world, growthMatrix))) + "mm", coordonneeXStat, initialYStat + ecartStat*indiceStat);

    //Affichage de la vitesse (scalaire)
    indiceStat++;
    text("Vitesse de déplacement du centroïde: " + String.format("%.2f", abs(totalLinearSpeed())) + "mm/s", coordonneeXStat, initialYStat + ecartStat*indiceStat);

    //Affichage de la vitesse angulaire
    indiceStat++;
    text("Vitesse angulaire de déplacement du centroïde: " + String.format("%.3f", abs(totalAngularSpeed())) + "rad/s", coordonneeXStat, initialYStat + ecartStat*indiceStat);

    //Affichage de l'asymétrie de masse
    fill(255);
    indiceStat++;
    text("Asymétrie de la masse: " + String.format("%.2f", abs(totalMassAsymetry())) + "mg", coordonneeXStat, initialYStat + ecartStat*indiceStat);

    //Affichage de l'asymétrie de masse en pourcentage
    indiceStat++;
    text("Pourcentage d'asymétrie de la masse: " + String.format("%.3f", (totalMassAsymetry()/totalMass())*100) + "%", coordonneeXStat, initialYStat + ecartStat*indiceStat);
  } else {



    //Affichage de la masse
    fill(255);
    indiceStat ++;
    text("Masse totale : " + String.format("%.1f", channelMass(selectedchannelStat-1)) + "mg", coordonneeXStat, initialYStat + ecartStat*indiceStat);

    //Affichage du volume
    indiceStat++;
    text("Volume total : " + String.format("%.2f", channelVolume(selectedchannelStat-1)) +"mm²", coordonneeXStat, initialYStat + ecartStat*indiceStat);

    //Affichage de la densité
    indiceStat++;
    text("Densité totale : " + String.format("%.4f", channelDensity(selectedchannelStat-1)) + "mg/mm²", coordonneeXStat, initialYStat + ecartStat*indiceStat);

    //Affichage du centre de masse
    if (showCentroid) {
      fill(150);
      noStroke();
      int positionX = channelCentroidX(selectedchannelStat-1, world[selectedchannelStat-1]) + deplacementX;
      int positionY = channelCentroidY(selectedchannelStat-1, world[selectedchannelStat-1]) + deplacementY;
      int positionPixelX = positionX*(zoom*1024/WORLD_DIMENSIONS);
      int positionPixelY = positionY*(zoom*1024/WORLD_DIMENSIONS) + 55;
      if (positionPixelX > 1 && positionPixelX < 975 && positionPixelY > 75 && positionPixelY < 1064) {
        circle(positionPixelX, positionPixelY, 15);
      }
    }
    if (showVector) {
      stroke(255);

      int positionX = channelCentroidY(selectedchannelStat-1, world[selectedchannelStat-1]) + deplacementX;
      int positionY = channelCentroidX(selectedchannelStat-1, world[selectedchannelStat-1]) + deplacementY;
      int positionPixelX = positionX*(zoom*1024/WORLD_DIMENSIONS);
      int positionPixelY = positionY*(zoom*1024/WORLD_DIMENSIONS) + 55;
      int positionXBuffer = channelCentroidY(selectedchannelStat-1, buffer[selectedchannelStat-1]) + deplacementX;
      int positionYBuffer = channelCentroidX(selectedchannelStat-1, buffer[selectedchannelStat-1]) + deplacementY;
      int positionPixelXBuffer = positionXBuffer*(zoom*1024/WORLD_DIMENSIONS)+ 55;
      int positionPixelYBuffer = positionYBuffer*(zoom*1024/WORLD_DIMENSIONS);
      if (positionPixelX > 1 && positionPixelX < 1009 && positionPixelY > 75 && positionPixelY < 1064 && positionPixelXBuffer > 1 && positionPixelXBuffer < 1009 && positionPixelYBuffer > 75 && positionPixelYBuffer < 1064) {
        line(positionPixelY + abs(positionPixelY-positionPixelYBuffer), positionPixelX + abs(positionPixelX-positionPixelXBuffer), positionPixelYBuffer, positionPixelXBuffer);
      }
    }


    //Affichage du centre de croissance
    if (showGrowthCenter) {
      fill(255);
      int positionX = channelGrowthCenterX(selectedchannelStat-1, growthMatrix[selectedchannelStat-1]) + deplacementX;
      int positionY = channelGrowthCenterY(selectedchannelStat-1, growthMatrix[selectedchannelStat-1]) + deplacementY;
      int positionPixelX = positionX*(zoom*1024/WORLD_DIMENSIONS);
      int positionPixelY = positionY*(zoom*1024/WORLD_DIMENSIONS) + 55;
      if (positionPixelX > 1 && positionPixelX < 1009 && positionPixelY > 75 && positionPixelY < 1064) {
        circle(positionPixelX, positionPixelY, 15);
      }
    }
    fill(255);

    //Affichage distance du centroïde et du centre de croissance
    indiceStat++;
    text("Distance centroïde centre de croissance: " + String.format("%.2f", abs(channelGrowthCentroid(selectedchannelStat-1, world[selectedchannelStat-1], growthMatrix[selectedchannelStat-1]))) + "mm", coordonneeXStat, initialYStat + ecartStat*indiceStat);

    //Affichage de la vitesse (scalaire)
    indiceStat++;
    text("Vitesse de déplacement du centroïde: " + String.format("%.2f", abs(channelLinearSpeed(selectedchannelStat-1))) + "mm/s", coordonneeXStat, initialYStat + ecartStat*indiceStat);

    //Affichage de la vitesse angulaire
    indiceStat++;
    text("Vitesse angulaire de déplacement du centroïde: " + String.format("%.3f", abs(channelAngularSpeed(selectedchannelStat-1))) + "rad/s", coordonneeXStat, initialYStat + ecartStat*indiceStat);

    //Affichage de l'asymétrie de masse
    fill(255);
    indiceStat++;

    text("Asymétrie de la masse: " + String.format("%.2f", abs(channelMassAsymetry())) + "mg", coordonneeXStat, initialYStat + ecartStat*indiceStat);

    //Affichage de l'asymétrie de masse en pourcentage
    indiceStat++;

    text("Pourcentage d'asymétrie de la masse: " + String.format("%.3f", (channelMassAsymetry()/channelMass(selectedchannelStat-1))*100) + "%", coordonneeXStat, initialYStat + ecartStat*indiceStat);
  }
}
