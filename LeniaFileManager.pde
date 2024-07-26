import java.io.File;
import java.io.FileWriter;
import java.time.*;
import java.time.format.*;

class LeniaFileManager {
  private String directoryPath;
  private int stateCounter = 0;

  LeniaFileManager() {
    directoryPath = sketchPath() + "/recordings/" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS")) + "/";
  }

  void saveState() {
    try {
      //Conversion des données de la simulation en objet JSON.
      org.json.JSONObject json = new org.json.JSONObject();
      json.put("world", world);
      json.put("R", R);
      json.put("dt", dt);
      json.put("mu", MU);
      json.put("sigma", SIGMA);
      json.put("beta", BETA);

      /*
       static final int WORLD_DIMENSIONS = 512; // Les dimensions des côtés de la grille.
       static final int R = 13*8; // Le rayon du noyeau de convolution.
       static final float dt = 0.1; // Le pas dans le temps à chaque itération.
       static final float MU = 0.14; // Centre de la fonction de noyeau.
       static final float SIGMA = 0.014; // Étendue de la fonction de noyeau. Plus la valeur est petite, plus les pics sont importants.
       static final float[] BETA = {1}; // Les hauteurs relatives des pics du noyeau de convolution.
       */

      //Données du fichier.
      String fileName = stateCounter++ + ".txt";
      String filePath = directoryPath + fileName;

      //Création du répertoire parent au besoin.
      File file = new File(filePath);
      file.getParentFile().mkdirs();

      //Écrire dans le fichier.
      file.createNewFile();
      FileWriter writer = new FileWriter(filePath);
      writer.write(json.toString());
      writer.close();
    }
    catch(Exception e) {
      println(e);
    }
  }
}
