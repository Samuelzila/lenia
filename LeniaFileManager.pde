import java.io.File;
import java.io.FileWriter;
import java.time.*;
import java.time.format.*;
import java.util.Scanner;

class LeniaFileManager {
  private String directoryPath;
  private int stateCounter = 0;

  LeniaFileManager() {
    directoryPath = sketchPath() + "/recordings/" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS")) + "/";
  }

  /**
   Enregistre l'état actuel de la simulation ainsi que ses paramètres dans ./recordings/<moment au lancement de la simulation>/<numéro du fichier>.json
   */
  public void saveState() {
    try {
      //Conversion des données de la simulation en objet JSON.
      org.json.JSONObject json = new org.json.JSONObject();
      json.put("world", world);
      json.put("worldDimensions", WORLD_DIMENSIONS);
      json.put("R", R);
      json.put("dt", dt);
      json.put("mu", MU);
      json.put("sigma", SIGMA);
      json.put("beta", BETA);

      //Données du fichier.
      String fileName = stateCounter++ + ".json";
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

  /**
   Charge l'état d'une simulation ainsi que ses paramètres à partir du chemin du fichier fourni.
   */
  public void loadState(String path) {
    File file = new File(path);
    loadState(file);
  }

  /**
   Charge l'état d'une simulation ainsi que ses paramètres à partir d'un objet java.io.File, comme retourné par la fonction selectInput() de processing.
   */
  public void loadState(File file) {
    try {
      //Lecture du fichier.
      Scanner fileReader = new Scanner(file);
      String data = "";
      while (fileReader.hasNextLine()) {
        data += fileReader.nextLine();
      }
      
      //Conversion en JSON.
      org.json.JSONObject json = new org.json.JSONObject(data);
      
      WORLD_DIMENSIONS = json.getInt("worldDimensions");
      R = json.getInt("R");
      dt = json.getInt("dt");
      MU = json.getInt("mu");
      SIGMA = json.getInt("sigma");
      
      //Chargement de world en tableau.
      org.json.JSONArray jsonWorld = json.getJSONArray("world");      
      for (int i = 0; i < WORLD_DIMENSIONS * WORLD_DIMENSIONS; i++) {
        world[i] = jsonWorld.getFloat(i);
      }
      
      //Chargement de beta en tableau.
      org.json.JSONArray jsonBeta = json.getJSONArray("beta");      
      int i = 0;
      for (Object value : jsonBeta) {
        BETA[i++] = int(value.toString());
      }
      
      println(BETA);
      
      fileReader.close();
    }
    catch(Exception e) {
      println(e);
    }
  }
}
