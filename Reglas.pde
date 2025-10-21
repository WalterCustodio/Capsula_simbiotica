import processing.serial.*;
import oscP5.*;
import netP5.*;

// --- Comunicación ---
Serial myPort;
OscP5 oscP5;
NetAddress resolume;
boolean modoSimulacion = false;

// --- Botones ---
int numBotones = 10;
boolean[] presionado = new boolean[numBotones];
long[] tiempoInicio = new long[numBotones];

// --- Parámetros visuales ---
int cols = 3;
int rows = 4;
float w = 100;
float h = 100;

// --- Alfombra y mesa ---
int[] alfombra = {4, 6, 1, 2, 3};
int[] mesa = {7, 8, 9, 5, 0};

// --- Brillo ---
float brillo = 0.7; // 70% por defecto

void setup() {
  size(400, 500);
  println("Puertos disponibles:");
  println(Serial.list());

  if (Serial.list().length > 0) {
    println("Conectando al primer puerto serie...");
    myPort = new Serial(this, Serial.list()[0], 115200);
    myPort.bufferUntil('\n');
  } else {
    modoSimulacion = true;
    println("⚠️ No se detectó Arduino. Modo simulación (teclado numérico).");
  }

  oscP5 = new OscP5(this, 12000);
  resolume = new NetAddress("127.0.0.1", 7000);
  println("Sistema listo.");
}

void draw() {
  background(20);
  dibujarBotones();
  actualizarBrillo();
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(16);
  text("Brillo actual: " + int(brillo * 100) + "%", width/2, height - 20);
}

void dibujarBotones() {
  int index = 0;
  
  // Distribución tipo teclado numérico
  int[][] layout = {
    {7, 8, 9},
    {4, 5, 6},
    {1, 2, 3},
    {-1, 0, -1} // fila inferior con el 0 centrado y doble ancho
  };
  
  for (int row = 0; row < layout.length; row++) {
    for (int col = 0; col < layout[row].length; col++) {
      int b = layout[row][col];
      if (b == -1) continue; // hueco
      float x = 50 + col * (w + 10);
      float y = 50 + row * (h + 10);
      float ww = (b == 0) ? w * 2 + 10 : w;

      boolean esAlfombra = esDeAlfombra(b);
      int cBase = esAlfombra ? color(50, 180, 50) : color(50, 150, 200);
      int cActivo = esAlfombra ? color(0, 255, 0) : color(0, 200, 255);
      fill(presionado[b] ? cActivo : cBase);
      stroke(255);
      strokeWeight(2);
      rect(x, y, ww, h, 15);
      fill(0);
      textSize(24);
      textAlign(CENTER, CENTER);
      text(b, x + ww/2, y + h/2);
    }
  }
}

boolean esDeAlfombra(int b) {
  for (int a : alfombra) if (a == b) return true;
  return false;
}

// --- Serial ---
void serialEvent(Serial p) {
  if (p == null) return;
  String msg = p.readStringUntil('\n');
  if (msg == null) return;
  msg = trim(msg);
  if (msg.startsWith("B")) {
    int sep = msg.indexOf(':');
    int boton = int(msg.substring(1, sep));
    int estado = int(msg.substring(sep + 1));
    if (boton >= 0 && boton < numBotones) {
      if (estado == 1) onPress(boton);
      else onRelease(boton);
    }
  }
}

// --- Lógica de botones ---
void onPress(int b) {
  if (!presionado[b]) {
    presionado[b] = true;
    tiempoInicio[b] = millis();
    println("Botón " + b + " PRESIONADO");
    evaluarReglas();
    enviarOSC(b, 1);
  }
}

void onRelease(int b) {
  if (presionado[b]) {
    presionado[b] = false;
    println("Botón " + b + " LIBERADO. Duración: " + (millis() - tiempoInicio[b]) + " ms");
    enviarOSC(b, 0);
  }
}

// --- OSC ---
void enviarOSC(int boton, int valor) {
  OscMessage m = new OscMessage("/clip/" + boton);
  m.add(valor);
  oscP5.send(m, resolume);
}

// --- Reglas de interacción ---
void evaluarReglas() {
  // Contar cuántos botones de alfombra están presionados
  int count = 0;
  for (int b : alfombra) if (presionado[b]) count++;
  println("Botones de alfombra presionados: " + count);
}

// --- Brillo dinámico ---
void actualizarBrillo() {
  int count = 0;
  for (int b : alfombra) if (presionado[b]) count++;
  float nuevoBrillo = (count > 2) ? 1.0 : 0.7;
  if (abs(nuevoBrillo - brillo) > 0.01) {
    brillo = nuevoBrillo;
    println("Brillo cambiado a " + int(brillo * 100) + "%");
    OscMessage m = new OscMessage("/composition/brightness");
    m.add(brillo);
    oscP5.send(m, resolume);
  }
}

// --- Teclado numérico para simular botones ---
void keyPressed() {
  if (key >= '0' && key <= '9') {
    int b = key - '0';
    onPress(b);
  }
}

void keyReleased() {
  if (key >= '0' && key <= '9') {
    int b = key - '0';
    onRelease(b);
  }
}
