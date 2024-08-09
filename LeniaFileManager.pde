import java.io.File;
import java.io.FileWriter;
import java.time.*;
import java.time.format.*;
import java.util.Scanner;

class LeniaFileManager {
  private String directoryPath;
  private int stateCounter = 0;

  LeniaFileManager() {
    directoryPath = sketchPath() + "/recordings/" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH-mm-ss.SSS")) + "/";
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
        jsonKernelObject.put("inputChanel", kernels[i].getinputchanel());
        jsonKernelObject.put("outputChanel", kernels[i].getOutputchanel());
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
    directoryPath = sketchPath() + "/recordings/" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH-mm-ss.SSS")) + "/";
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

      int localWorldDimensions = json.getInt("worldDimensions");
      //Si le monde chargé est plus petit que le nôtre, on veut le mettre à l'échelle.
      int scalingFactor = WORLD_DIMENSIONS/localWorldDimensions;
      dt = json.getFloat("dt");

      //Chargement des canaux.
      org.json.JSONArray jsonWorlds = json.getJSONArray("worlds");
      for (int w = 0; w < world.length; w++) {
        org.json.JSONArray jsonWorld = jsonWorlds.getJSONArray(w);
        for (int x = 0; x < localWorldDimensions; x++)
          for (int y =0; y < localWorldDimensions; y++)
            for (int i = x*scalingFactor; i < (x+1)*scalingFactor; i++)
              for (int j = y*scalingFactor; j < (y+1)*scalingFactor; j++) {
                world[w][i*WORLD_DIMENSIONS+j] = jsonWorld.getFloat(x*localWorldDimensions+y);
              }
      }

      //Chargement des noyaux.
      org.json.JSONArray jsonKernels = json.getJSONArray("kernels");

      //On supprime les canaux existants. 
      for (int i = 0; i < kernels.length; i++) {
        kernels[i].finalize();
      }

      kernels = new Kernel[jsonKernels.length()];

      //On crée les nouveaux;
      for (int i = 0; i < kernels.length; i++) {

        org.json.JSONObject jsonKernelObject = jsonKernels.getJSONObject(i);
        int R = jsonKernelObject.getInt("R") * scalingFactor;
        int coreFunction = jsonKernelObject.getInt("coreFunction");
        int growthFunction = jsonKernelObject.getInt("growthFunction");
        float mu = jsonKernelObject.getFloat("mu");
        float sigma = jsonKernelObject.getFloat("sigma");
        int inputchanel = jsonKernelObject.getInt("inputChanel");
        int outputchanel = jsonKernelObject.getInt("outputChanel");
        float kernelWeight = jsonKernelObject.getFloat("kernelWeight");

        //Beta
        float[] beta = new float[jsonKernelObject.getJSONArray("beta").length()];
        for (int j = 0; j < beta.length; j++) {
          beta[j] = jsonKernelObject.getJSONArray("beta").getFloat(j);
        }

        kernels[i] = new Kernel(R, beta, coreFunction, growthFunction, mu, sigma, inputchanel, outputchanel, kernelWeight, true);
      }

      fileReader.close();
    }
    catch(Exception e) {
      println(e);
    }
  }
}
