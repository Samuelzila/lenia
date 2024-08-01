/*Les fonctions suivantes servent à changer les paramètres des différents noyaux pendant l'exécution du code 
La variable i fait toujours référence à l'indicedu noyau sur lequel est effectué les changements*/

//Change la focntion coeur du noyau
void changeCoreFunction(int i) {
  kernels[i].coreFunction = (kernels[i].coreFunction+1)%3;
  kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Change la fonction de croissance associée au noyau
void changeGrowthFunction(int i) {
  kernels[i].growthFunction = (kernels[i].growthFunction+1)%3;
   kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Augmente la valeur de mu de 0,01
void increaseMu (int i) {
  kernels[i].mu += 0.01;
   kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Diminue la valeur de mu de 0,01
void decreaseMu (int i) {
  kernels[i].mu -= 0.01;
   kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Augmente la valeur de sigma de 0,001 
void increaseSigma (int i) {
  kernels[i].sigma += 0.001;
   kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Diminue la valeur de sigma de 0,001
void decreaseSigma (int i) {
  kernels[i].sigma -= 0.001;
   kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Augmente la valeur du poids du noyau de 0,25
void increaseWeigth (int i) {
  kernels[i].kernelWeight += 0.25;
   kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Diminue la valeur du poids du noyau de 0.25
void decreaseWeigth (int i) {
  kernels[i].kernelWeight -= 0.25;
   kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Augmente la valeur du rayon de 1
void increaseRadius (int i) {
  kernels[i].R += 1*8;
   kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Diminue la valeur du rayon de 1
void decreaseRadius (int i) {
  kernels[i].R -= 1*8;
   kernels[i].kernel = kernels[i].preCalculateKernel();
}

/* Pour les deux prochaines fonctions, la variable j sert à déterminer quel composante de beta est changée*/

//Augmente la valeur d'une composante de beta de 0,25
void increaseBeta (int i, int j) {
  kernels[i].beta[j] += 0.25;
   kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Diminue la valeur d'une composante de beta de 0,25
void decreaseBeta (int i, int j) {
  kernels[i].beta[j] -= 0.25;
   kernels[i].kernel = kernels[i].preCalculateKernel();
}
