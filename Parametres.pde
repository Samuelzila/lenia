/*Les fonctions suivantes servent à changer les paramètres des différents noyaux pendant l'exécution du code 
La variable i fait toujours référence à l'indicedu noyau sur lequel est effectué les changements*/

//Change la focntion coeur du noyau
void changeCoreFunction(int i) {
  kernels[i].coreFunction = (kernels[i].coreFunction+1)%4;
  //kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Change la fonction de croissance associée au noyau
void changeGrowthFunction(int i) {
  kernels[i].growthFunction = (kernels[i].growthFunction+1)%4;
  // kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Augmente la valeur de mu de 0,01
void increaseMu (int i) {
  kernels[i].mu += 0.01;
  // kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Diminue la valeur de mu de 0,01
void decreaseMu (int i) {
  kernels[i].mu -= 0.01;
 //  kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Augmente la valeur de sigma de 0,001 
void increaseSigma (int i) {
  kernels[i].sigma += 0.001;
   kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Diminue la valeur de sigma de 0,001
void decreaseSigma (int i) {
  kernels[i].sigma -= 0.001;
  // kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Augmente la valeur du poids du noyau de 0,25
void increaseWeigth (int i) {
  kernels[i].kernelWeight += 0.25;
  // kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Diminue la valeur du poids du noyau de 0.25
void decreaseWeigth (int i) {
  kernels[i].kernelWeight -= 0.25;
  // kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Augmente la valeur du rayon de 1
void increaseRadius (int i) {
  kernels[i].R += 1*4;
  // kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Diminue la valeur du rayon de 1
void decreaseRadius (int i) {
  kernels[i].R -= 1*4;
 //  kernels[i].kernel = kernels[i].preCalculateKernel();
}

// Augmente la valeur du canal d'entrée
void increaseInput (int i) {
  kernels[i].inputchanel ++;
}

//Diminue la valeur du canal d'entrée
void decreaseInput (int i) {
  kernels[i].inputchanel --;
}

//Augmente la valeur du canal de sortie
void increaseOutput (int i) {
  kernels[i].outputchanel ++;
}

//Diminue la valeur du canal de sortie
void decreaseOutput (int i) {
  kernels[i].outputchanel --;
}




/* Pour les deux prochaines fonctions, la variable j sert à déterminer quel composante de beta est changée*/

//Augmente la valeur d'une composante de beta de 0,25
void increaseBeta (int i, int j) {
  kernels[i].beta[j] += 0.25;
 //  kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Diminue la valeur d'une composante de beta de 0,25
void decreaseBeta (int i, int j) {
  kernels[i].beta[j] -= 0.25;
  // kernels[i].kernel = kernels[i].preCalculateKernel();
}

//Afficher les changements de paramètres
void showParameterChanges (int i) {
 stroke(255);
 strokeWeight(1);
 fill(0);
 rect(1500, 160, 400, 155);
 fill(255);
 textSize(25);
 text("Noyau : <"+i+">", 1500, 185);
 
 //Changement du rayon
 textSize(20);
 text("Rayon : <" + kernels[i].getR()+ ">", 1505, 205);
 
 //Changement de mu
 text("Mu : <" + String.format("%.2f", kernels[i].getMu()) + ">", 1505, 225);
 
 //Changement de sigma
 text("Sigma : <" +String.format("%.3f", kernels[i].getSigma()) + ">", 1505, 245);
 
 //Changement du canal d'entrée
 text("Entrée : <" + kernels[i].getinputchanel() + ">", 1705, 205);
 
 //Changement du canal de sortie
 text("Sortie : <" + kernels[i].getOutputchanel() + ">", 1705, 225);
 
 //Changement du poids du noyau
 text("Poids : <" + String.format("%.2f", kernels[i].getWeight()) + ">",1705, 245);
 
 //Changement de la fonction core
 String function = "Aucune";
 if (kernels[i].getCoreFunction() == 0) {
   function = "Gaussienne";
 } else if (kernels[i].getCoreFunction() == 1) {
   function = "Polynomiale";
 } else if (kernels[i].getCoreFunction() == 2) {
   function = "Rectangulaire";
 } else if (kernels[i].getCoreFunction() == 3) {
   function = "Exponentielle";
 }
   text("Fonction du coeur : " + function + ">", 1505, 265);
   
   //Changement de la fonction de croissance
    String Gfunction = "Aucune";
 if (kernels[i].getGrowthFunction() == 0) {
   Gfunction = "Gaussienne";
 } else if (kernels[i].getGrowthFunction() == 1) {
   Gfunction = "Polynomiale";
 } else if (kernels[i].getGrowthFunction() == 2) {
   Gfunction = "Rectangulaire";
 } else if (kernels[i].getGrowthFunction() == 3) {
   Gfunction = "Exponentielle";
 }
 
 text("Fonction de croissance : " + Gfunction + ">", 1505, 285);
 
 //Application des changements
 textSize(23);
 text("Appliquer les changements", 1505, 305);
}
