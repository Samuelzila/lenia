/*Les fonctions suivantes servent à changer les paramètres des différents noyaux pendant l'exécution du code 
La variable i fait toujours référence à l'indice du noyau sur lequel est effectué les changements

The following functions change the kernels' parameters when the code is runnung
The variable i always refers to the index of the kernel on which the changes are made*/


//Change la focntion coeur du noyau
//Changes the core function of the kernel
void changeCoreFunction(int i) {
  kernels[i].coreFunction = (kernels[i].coreFunction+1)%4;
}

//Change la fonction de croissance associée au noyau
//Change the growth function associated to the kernel
void changeGrowthFunction(int i) {
  kernels[i].growthFunction = (kernels[i].growthFunction+1)%4;
}

//Augmente la valeur de mu de 0,01
//Increases the value of mu by 0.01
void increaseMu (int i) {
  kernels[i].mu += 0.01;
}

//Diminue la valeur de mu de 0,01
//Decrases the value of mu by 0.01
void decreaseMu (int i) {
  kernels[i].mu -= 0.01;
}

//Augmente la valeur de sigma de 0,001 
//Increases the value of sigma by 0.001
void increaseSigma (int i) {
  kernels[i].sigma += 0.001;
}

//Diminue la valeur de sigma de 0,001
//Decreases the value of sigma by 0,001
void decreaseSigma (int i) {
  kernels[i].sigma -= 0.001;
}

//Augmente la valeur du poids du noyau de 0,25
//Increases the kernel weigth by 0.25
void increaseWeigth (int i) {
  kernels[i].kernelWeight += 0.25;
}

//Diminue la valeur du poids du noyau de 0.25
//Decreases the kernel weigth by 0.25
void decreaseWeigth (int i) {
  kernels[i].kernelWeight -= 0.25;
}

//Augmente la valeur du rayon de 1
//Increases the radius by 1
void increaseRadius (int i) {
  kernels[i].R += 1*4;
}

//Diminue la valeur du rayon de 1
//Decreases the value of the radius by 1
void decreaseRadius (int i) {
  kernels[i].R -= 1*4;
}

// Augmente la valeur du canal d'entrée
//Increases the input channel value
void increaseInput (int i) {
  kernels[i].inputchannel ++;
}

//Diminue la valeur du canal d'entrée
//Decreases the input channel value
void decreaseInput (int i) {
  kernels[i].inputchannel --;
}

//Augmente la valeur du canal de sortie
//Increases the output channel value
void increaseOutput (int i) {
  kernels[i].outputchannel ++;
}

//Diminue la valeur du canal de sortie
//Decreases the output channel value
void decreaseOutput (int i) {
  kernels[i].outputchannel --;
}

//Afficher les changements de paramètres
//Displays the parameter changes
void showParameterChanges (int i) {
  try {
 stroke(255);
 strokeWeight(1);
 fill(0);
 rect(1500, 160, 400, 175);
 fill(255);
 textSize(25);
 text("Noyau : <"+i+">", 1500, 185);
 
 //Changement du rayon
 //Radius change
 textSize(20);
 text("Rayon : <" + kernels[i].getR()+ ">", 1505, 205);
 
 //Changement de mu
 //Mu change
 text("Mu : <" + String.format("%.2f", kernels[i].getMu()) + ">", 1505, 225);
 
 //Changement de sigma
 //Sigma change
 text("Sigma : <" +String.format("%.3f", kernels[i].getSigma()) + ">", 1505, 245);
 
 //Changement du canal d'entrée
 //Input channel change
 text("Entrée : <" + kernels[i].getinputchannel() + ">", 1705, 205);
 
 //Changement du canal de sortie
 //Output channel change
 text("Sortie : <" + kernels[i].getOutputchannel() + ">", 1705, 225);
 
 //Changement du poids du noyau
 //Weigth change
 text("Poids : <" + String.format("%.2f", kernels[i].getWeight()) + ">",1705, 245);
 
 //Utilisation de FFT
 //Use of FFT
 text("FFT : ", 1705, 185);
 fill(kernels[i].useFft ? 255 : 0);
 square(1755,169,18);
 fill(255);
 
 //Changement de la fonction core
 //Core function change
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
   //Growth function change
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

    //Noyau asymétrique
    text("Noyau asymétrique : ", 1505, 305);
    fill(kernels[i].asymetricKernel ? 255 : 0);
    square(1506 + textWidth("Noyau asymétrique : "), 290, 18);
    fill(255);

    //Application des changements
    textSize(23);
    text("Appliquer les changements", 1505, 325);
  }
  catch (Exception e) {
    println(e + " en affichant les options de modification de noyaux.");
    println("Ceci peut arriver si les paramètres sont inaccessibles. Par exemple, lors d'un changement de noyau.");
  }
}
