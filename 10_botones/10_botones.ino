// --- Arduino: 10 botones (5 alfombra + 4 mesa + 1 botón "0") ---
const int numBotones = 10;
int pines[numBotones] = {2, 3, 4, 5, 6, 7, 8, 9, 10, 11}; // 10 botones
int estadoActual[numBotones];
int estadoPrevio[numBotones];

void setup() {
  Serial.begin(115200);
  for (int i = 0; i < numBotones; i++) {
    pinMode(pines[i], INPUT_PULLUP); // usa pull-up interno (botón a GND)
    estadoPrevio[i] = digitalRead(pines[i]);
  }
}

void loop() {
  for (int i = 0; i < numBotones; i++) {
    estadoActual[i] = digitalRead(pines[i]);

    if (estadoActual[i] != estadoPrevio[i]) { // cambio detectado
      int estado = (estadoActual[i] == LOW) ? 1 : 0; // invertido por pull-up
      Serial.print("B");
      Serial.print(i);
      Serial.print(":");
      Serial.println(estado);
      estadoPrevio[i] = estadoActual[i];
      delay(10);
    }
  }
}
