boolean stamps = false;
// Valeurs d'un orbium
boolean orbiumStamp = false;
float[][] orbium = {{0, 0, 0, 0, 0, 0, 0.1, 0.14, 0.1, 0, 0, 0.03, 0.03, 0, 0, 0.3, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0.08, 0.24, 0.3, 0.3, 0.18, 0.14, 0.15, 0.16, 0.15, 0.09, 0.2, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0.15, 0.34, 0.44, 0.46, 0.38, 0.18, 0.14, 0.11, 0.13, 0.19, 0.18, 0.45, 0, 0, 0, 0}, {0, 0, 0, 0, 0.06, 0.13, 0.39, 0.5, 0.5, 0.37, 0.06, 0, 0, 0, 0.02, 0.16, 0.68, 0, 0, 0, 0}, {0, 0, 0, 0.11, 0.17, 0.17, 0.33, 0.4, 0.38, 0.28, 0.14, 0, 0, 0, 0, 0, 0.18, 0.42, 0, 0, 0}, {0, 0, 0.09, 0.18, 0.13, 0.06, 0.08, 0.26, 0.32, 0.32, 0.27, 0, 0, 0, 0, 0, 0, 0.82, 0, 0, 0}, {0.27, 0, 0.16, 0.12, 0, 0, 0, 0.25, 0.38, 0.44, 0.45, 0.34, 0, 0, 0, 0, 0, 0.22, 0.17, 0, 0}, {0, 0.07, 0.2, 0.02, 0, 0, 0, 0.31, 0.48, 0.57, 0.6, 0.57, 0, 0, 0, 0, 0, 0, 0.49, 0, 0}, {0, 0.59, 0.19, 0, 0, 0, 0, 0.2, 0.57, 0.69, 0.76, 0.76, 0.49, 0, 0, 0, 0, 0, 0.36, 0, 0}, {0, 0.58, 0.19, 0, 0, 0, 0, 0, 0.67, 0.83, 0.9, 0.92, 0.87, 0.12, 0, 0, 0, 0, 0.22, 0.07, 0}, {0, 0, 0.46, 0, 0, 0, 0, 0, 0.7, 0.93, 1, 1, 1, 0.61, 0, 0, 0, 0, 0.18, 0.11, 0}, {0, 0, 0.82, 0, 0, 0, 0, 0, 0.47, 1, 1, 0.98, 1, 0.96, 0.27, 0, 0, 0, 0.19, 0.1, 0}, {0, 0, 0.46, 0, 0, 0, 0, 0, 0.25, 1, 1, 0.84, 0.92, 0.97, 0.54, 0.14, 0.04, 0.1, 0.21, 0.05, 0}, {0, 0, 0, 0.4, 0, 0, 0, 0, 0.09, 0.8, 1, 0.82, 0.8, 0.85, 0.63, 0.31, 0.18, 0.19, 0.2, 0.01, 0}, {0, 0, 0, 0.36, 0.1, 0, 0, 0, 0.05, 0.54, 0.86, 0.79, 0.74, 0.72, 0.6, 0.39, 0.28, 0.24, 0.13, 0, 0}, {0, 0, 0, 0.01, 0.3, 0.07, 0, 0, 0.08, 0.36, 0.64, 0.7, 0.64, 0.6, 0.51, 0.39, 0.29, 0.19, 0.04, 0, 0}, {0, 0, 0, 0, 0.1, 0.24, 0.14, 0.1, 0.15, 0.29, 0.45, 0.53, 0.52, 0.46, 0.4, 0.31, 0.21, 0.08, 0, 0, 0}, {0, 0, 0, 0, 0, 0.08, 0.21, 0.21, 0.22, 0.29, 0.36, 0.39, 0.37, 0.33, 0.26, 0.18, 0.09, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0.03, 0.13, 0.19, 0.22, 0.24, 0.24, 0.23, 0.18, 0.13, 0.05, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0.02, 0.06, 0.08, 0.09, 0.07, 0.05, 0.01, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}};
float[][] test = {{1, 2, 3, 4, 5}, {6, 7, 8, 9, 10}, {11, 12, 13, 14, 15}, {16, 17, 18, 19, 20}, {21, 22, 23, 24, 25}};
//float[][] test = {{1,1,1},{1,1,1},{1,1,1}};
int angleOrbium = 0;

void rotateMatrixI(int angle, float matrice[][]) {
  //rotation = angle/30
  //angleOrbium = Math.floorMod(angleOrbium + angle, 360);
  int rayon = (matrice.length-1)/2;
  int grandRayon = ceil(dist(0, 0, rayon, rayon));
  int vide = grandRayon - rayon;
  float[][] grandeMatrice = new float [2 * grandRayon + 1][2 * grandRayon + 1];
  for (int i = 0; i < vide; i++) {
    for (int j = 0; j < vide; j++) {
      for (int k = grandeMatrice.length - vide; k < grandeMatrice.length; k++) {
        for (int l = grandeMatrice.length - vide; l < grandeMatrice.length; l ++) {
          grandeMatrice[i][j] = 1;
          grandeMatrice[k][l] = 1;
        }
      }
    }
  }
  for (int i = vide; i < grandeMatrice.length - vide; i++) {
    for (int j = vide; j < grandeMatrice.length - vide; j++) {
      grandeMatrice[i][j] = matrice[i - vide][j - vide];
    }
  }
  float[][] tampon = new float[grandeMatrice.length][grandeMatrice.length];
  for (int i = 0; i < matrice.length; i++) {
    for (int j = 0; j < matrice.length; j++) {
      //println(matrice[i][j], matrice[round((i - rayon) * cos(radians(angle)) + (j - rayon) * sin(radians(angle))) + rayon][(round((i - rayon) * -sin(radians(angle)) + (j - rayon) * cos(radians(angle))) + rayon)]);
      tampon[i][j] = grandeMatrice[round((i - rayon) * cos(radians(angle)) + (j - rayon) * sin(radians(angle))) + rayon + vide][(round((i - rayon) * -sin(radians(angle)) + (j - rayon) * cos(radians(angle))) + rayon + vide)];
    }
  }
  for (int i = 0; i < matrice.length; i++) {
    for (int j = 0; j < matrice.length; j++) {
      orbium[i][j] = tampon[i][j];
    }
  }
}

void rotateMatrix(int angle, float matrice[][]) {
  if (angle != angleOrbium) {
    if (angle == 0) {
      angle = 360;
    }
    angleOrbium = Math.floorMod(angleOrbium + angle, 360);
    if (angleOrbium == 0) {
      angleOrbium = 360;
    }
    int rotation = angleOrbium/30;
    int rayon = (matrice.length-1)/2;
    int grandRayon = ceil(dist(0, 0, rayon, rayon));
    int vide = grandRayon - rayon;
    float[][] grandeMatrice = new float [2 * grandRayon + 1][2 * grandRayon + 1];
    for (int i = 0; i < vide; i++) {
      for (int j = 0; j < vide; j++) {
        for (int k = grandeMatrice.length - vide; k < grandeMatrice.length; k++) {
          for (int l = grandeMatrice.length - vide; l < grandeMatrice.length; l ++) {
            grandeMatrice[i][j] = 1;
            grandeMatrice[k][l] = 1;
          }
        }
      }
    }
    for (int i = vide; i < grandeMatrice.length - vide; i++) {
      for (int j = vide; j < grandeMatrice.length - vide; j++) {
        grandeMatrice[i][j] = matrice[i - vide][j - vide];
      }
    }
    float[][] tampon = new float[grandeMatrice.length][grandeMatrice.length];
    for (int i = 0; i < matrice.length; i++) {
      for (int j = 0; j < matrice.length; j++) {
        //println(matrice[i][j], matrice[round((i - rayon) * cos(radians(angle)) + (j - rayon) * sin(radians(angle))) + rayon][(round((i - rayon) * -sin(radians(angle)) + (j - rayon) * cos(radians(angle))) + rayon)]);
        tampon[i][j] = grandeMatrice[round((i - rayon) * cos(radians(rotation * 30)) + (j - rayon) * sin(radians(rotation * 30))) + rayon + vide][(round((i - rayon) * -sin(radians(rotation * 30)) + (j - rayon) * cos(radians(rotation * 30))) + rayon + vide)];
      }
    }
    for (int i = 0; i < matrice.length; i++) {
      for (int j = 0; j < matrice.length; j++) {
        orbium[i][j] = tampon[i][j];
      }
    }
  }
}
