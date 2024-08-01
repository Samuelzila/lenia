import java.io.File;
import java.io.FileWriter;
import java.time.*;
import java.time.format.*;
import java.util.Scanner;

class LeniaFileReader {
  private File directory;
  private int fileCounter;
  private File[] files;
  private int nbChannels = -1;

  LeniaFileReader(File _directory) {
    directory = _directory;
    files = directory.listFiles();
  }

  /**
   Charge l'état d'une simulation ainsi que ses paramètres à partir d'un objet java.io.File, comme retourné par la fonction selectInput() de processing.
   Retourne si une frame à pu être lue.
   */
  public boolean loadState() {
    if (fileCounter >= files.length - 1) return false;
    try {
      //Lecture du fichier.
      Scanner fileReader = new Scanner(files[fileCounter]);
      String data = "";
      while (fileReader.hasNextLine()) {
        data += fileReader.nextLine();
      }

      //Conversion en JSON.
      org.json.JSONObject json = new org.json.JSONObject(data);

      WORLD_DIMENSIONS = json.getInt("worldDimensions");

      //Chargement des canaux.
      org.json.JSONArray jsonWorlds = json.getJSONArray("worlds");
      if (nbChannels == -1) {
        nbChannels = jsonWorlds.length();
      }
      world.add(new float[nbChannels][WORLD_DIMENSIONS*WORLD_DIMENSIONS]);
      for (int w = 0; w < world.get(fileCounter).length; w++) {
        org.json.JSONArray jsonWorld = jsonWorlds.getJSONArray(w);
        for (int i = 0; i < WORLD_DIMENSIONS * WORLD_DIMENSIONS; i++) {
          world.get(fileCounter)[w][i] = jsonWorld.getFloat(i);
        }
      }
      
      println("Loaded file " + fileCounter);
      
      fileCounter++;

      fileReader.close();
    }
    catch(Exception e) {
      println(e);
    }
    return true;
  }
}
