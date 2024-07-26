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
