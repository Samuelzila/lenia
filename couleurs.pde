color getColorPalette(float value, int canalC) {
  color colorPixel;
  float hue1 = colpalHue1[canalC];
  float hue2 = colpalHue2[canalC];
  float hueOri = colpalHueOri[canalC];
  float sat1 = colpalSat1[canalC];
  float sat2 = colpalSat2[canalC];
  float light1 = colpalLight1[canalC];
  float light2 = colpalLight2[canalC];

  if (hueOri==1 && hue1>hue2) {
    hue2 += 360;
  }
  if (hueOri==0 && hue1<hue2) {
    hue1 += 360;
  }
  int hue = int(lerp(hue1, hue2, floor(100*value)/float(100))) % 360;
  int sat = int(lerp(sat1, sat2, value));
  int light = int(lerp(light1, light2, value));
  colorPixel = color(hue, sat, light);
  return colorPixel;
}

// Obtenir la couleur d'un pixel selon sa position
// Gives the color of a pixel according to its position
color getColorPixel(int positionPixel) {
  // Les axes de processing et les nôtres sont inversés.
  // Processig axis and ours are inverted
  color pixelColor = color(0, 0, 0);
  float valueChannel0;
  float valueChannel1;
  float valueChannel2;
  if (NB_CHANNELS == 1) {
    valueChannel0 = world[0][positionPixel];
    pixelColor = getColorPalette(valueChannel0, 0);
  } else if (NB_CHANNELS == 2) {
    
    valueChannel0 = (showChannel0) ? world[0][positionPixel] : 0;
    valueChannel1 = (showChannel1) ? world[1][positionPixel] : 0;
    if (valueChannel0==0 && valueChannel1==0) {
      pixelColor = color(0, 0, 0);
    } else if (valueChannel0==0) {
      pixelColor = getColorPalette(valueChannel1, 1);
    } else if (valueChannel1==0) {
      pixelColor = getColorPalette(valueChannel0, 0);
    } else {
      color pixelColor0 = getColorPalette(valueChannel0, 0);
      color pixelColor1 = getColorPalette(valueChannel1, 1);
      pixelColor = mix2colors(pixelColor0, pixelColor1);
    }
  } else if (NB_CHANNELS == 3) {
    valueChannel0 = (showChannel0) ? world[0][positionPixel] : 0;
    valueChannel1 = (showChannel1) ? world[1][positionPixel] : 0;
    valueChannel2 = (showChannel2) ? world[2][positionPixel] : 0;
    if (valueChannel0==0 && valueChannel1==0 && valueChannel2==0) {
      pixelColor = color(0, 0, 0);
    } else if (valueChannel0==0 && valueChannel1==0) {
      pixelColor = getColorPalette(valueChannel2, 2);
    } else if (valueChannel0==0 && valueChannel2==0) {
      pixelColor = getColorPalette(valueChannel1, 1);
    } else if (valueChannel1==0 && valueChannel2==0) {
      pixelColor = getColorPalette(valueChannel0, 0);
    } else if (valueChannel0==0) {
      color pixelColor0 = getColorPalette(valueChannel1, 1);
      color pixelColor1 = getColorPalette(valueChannel2, 2);
      pixelColor = mix2colors(pixelColor0, pixelColor1);
    } else if (valueChannel1==0) {
      color pixelColor0 = getColorPalette(valueChannel0, 0);
      color pixelColor1 = getColorPalette(valueChannel2, 2);
      pixelColor = mix2colors(pixelColor0, pixelColor1);
    } else if (valueChannel2==0) {
      color pixelColor0 = getColorPalette(valueChannel0, 0);
      color pixelColor1 = getColorPalette(valueChannel1, 1);
      pixelColor = mix2colors(pixelColor0, pixelColor1);
    } else {
      color pixelColor0 = getColorPalette(valueChannel0, 0);
      color pixelColor1 = getColorPalette(valueChannel1, 1);
      color pixelColor2 = getColorPalette(valueChannel2, 2);
      pixelColor = mix3colors(pixelColor0, pixelColor1, pixelColor2);
    }
  }
  return pixelColor;
}

color mix2colors(color pixelColor0, color pixelColor1) {
  // Hue
  float hue0 = hue(pixelColor0);
  float hue1 = hue(pixelColor1);
  float hue = (hue0 + hue1) / 2.;
  if (abs(hue - hue0) > 90) {
    hue = (hue + 180) % 360;
  }

  // Saturation
  float posX = (cos(radians(hue0)) + cos(radians(hue1)))/2.;
  float posY = (sin(radians(hue0)) + sin(radians(hue1)))/2.;
  float sat = 100*dist(0, 0, posX, posY);

  // Lightness
  float light0 = brightness(pixelColor0);
  float light1 = brightness(pixelColor1);
  float light = (light0 + light1)/2.;

  color pixelColor = color(hue, sat, light);
  return pixelColor;
}

color mix3colors(color pixelColor0, color pixelColor1, color pixelColor2) {
  // Hue
  float hue0 = hue(pixelColor0);
  float hue1 = hue(pixelColor1);
  float hue2 = hue(pixelColor2);
  float posX = (cos(radians(hue0)) + cos(radians(hue1)) + cos(radians(hue2)))/3.;
  float posY = (sin(radians(hue0)) + sin(radians(hue1)) + sin(radians(hue2)))/3.;
  float hue = degrees(atan2(posY, posX));

  // Saturation
  float sat = 100*dist(0, 0, posX, posY);
  
  // Lightness
  float light0 = brightness(pixelColor0);
  float light1 = brightness(pixelColor1);
  float light2 = brightness(pixelColor2);
  float light = (light0 + light1 + light2)/3.;
  
  color pixelColor = color(hue, sat, light);
  return pixelColor;
}
