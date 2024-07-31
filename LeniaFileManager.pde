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
      json.put("worldDimensions", WORLD_DIMENSIONS);
      json.put("dt", dt);

      //Enregistrement des noyaux
      org.json.JSONArray jsonKernels = new org.json.JSONArray();
      for (int i = 0; i < kernels.length; i++) {
        org.json.JSONObject jsonKernelObject = new org.json.JSONObject();
        jsonKernelObject.put("R", kernels[i].getR());
        jsonKernelObject.put("beta", kernels[i].getBeta());
        jsonKernelObject.put("coreFunction", kernels[i].getCoreFunction());
        jsonKernelObject.put("growthFunction", kernels[i].getGrowthFunction());
        jsonKernelObject.put("mu", kernels[i].getMu());
        jsonKernelObject.put("sigma", kernels[i].getSigma());
        jsonKernelObject.put("inputChannel", kernels[i].getinputChannel());
        jsonKernelObject.put("outputChannel", kernels[i].getOutputChannel());
        jsonKernelObject.put("kernelWeight", kernels[i].getWeight());

        jsonKernels.put(jsonKernelObject);
      }
      json.put("kernels", jsonKernels);

      //Enregistrement des canaux.
      org.json.JSONArray jsonWorlds = new org.json.JSONArray();
      for (int i = 0; i < world.length; i++) {
        jsonWorlds.put(world[i]);
      }
      json.put("worlds", jsonWorlds);

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
    directoryPath = sketchPath() + "/recordings/" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS")) + "/";
    stateCounter = 0;
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
      dt = json.getFloat("dt");

      //Chargement des canaux.
      org.json.JSONArray jsonWorlds = json.getJSONArray("worlds");
      for (int w = 0; w < world.length; w++) {
        org.json.JSONArray jsonWorld = jsonWorlds.getJSONArray(w);
        for (int i = 0; i < WORLD_DIMENSIONS * WORLD_DIMENSIONS; i++) {
          world[w][i] = jsonWorld.getFloat(i);
        }
      }

      //Chargement des noyaux.
      org.json.JSONArray jsonKernels = json.getJSONArray("kernels");
      for (int i = 0; i < kernels.length; i++) {
        kernels[i].finalize();

        org.json.JSONObject jsonKernelObject = jsonKernels.getJSONObject(i);
        int R = jsonKernelObject.getInt("R");
        int coreFunction = jsonKernelObject.getInt("coreFunction");
        int growthFunction = jsonKernelObject.getInt("growthFunction");
        float mu = jsonKernelObject.getFloat("mu");
        float sigma = jsonKernelObject.getFloat("sigma");
        int inputChannel = jsonKernelObject.getInt("inputChannel");
        int outputChannel = jsonKernelObject.getInt("outputChannel");
        float kernelWeight = jsonKernelObject.getFloat("kernelWeight");

        //Beta
        float[] beta = new float[jsonKernelObject.getJSONArray("beta").length()];
        for (int j = 0; j < beta.length; j++) {
          beta[j] = jsonKernelObject.getJSONArray("beta").getFloat(j);
        }

        float[] beta = {1};
        kernels[i] = new Kernel(R, beta, coreFunction, growthFunction, mu, sigma, inputChannel, outputChannel, kernelWeight, true);
      }

      fileReader.close();
    }
    catch(Exception e) {
      println(e);
    }
  }
}
