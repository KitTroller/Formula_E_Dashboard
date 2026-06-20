/*
  ARISTURTLE INNOVATION FORUM DEMO -- Dashboard Input Bridge
  Arduino Uno R3 -> Formula Student Dashboard via USB serial @ 115200

  WIRING (Uno R3)
    A0  Throttle pot wiper   (outer pins of pot to 5V and GND)
    A1  Brake pot wiper      (outer pins of pot to 5V and GND)
    A2  Joystick VRx
    A3  Joystick VRy
    D2  Button: Regen        (other side to GND; external pull-up optional)
    D3  Button: Traction Control
    D4  Button: Torque Vectoring
    D5  Button: Cooling
    D6  Button: Radio
    D7  Button: Sideslip (SS)
    5V / GND -> breadboard rails

  PROTOCOL (matches vehicledataprovider.cpp UART parser)
    [0xAA sync] [CAN_ID LE 4 bytes] [DLC 1 byte] [payload DLC bytes] [XOR checksum]

  CAN frames emitted at 50 Hz:
    798  - throttle (DLC 2, u16 * 0.001)
    101  - brake    (DLC 2, u16 * 0.01 / 200)
    1799 - g-meter  (DLC 4, two int16 * 0.02 / 9.81)
    801  - hero gauge: power (i8), speed (i16 * 0.01), SoC (i8), TV/Regen/TC bools

  If the throttle/brake direction feels reversed (idle position = full bar),
  swap the outer 5V and GND wires on that pot, or invert the value in code.
*/

// ---------- pin map ----------
const uint8_t PIN_THROTTLE    = A0;
const uint8_t PIN_BRAKE       = A1;
const uint8_t PIN_JOY_X       = A2;
const uint8_t PIN_JOY_Y       = A3;
const uint8_t PIN_BTN_REGEN   = 2;
const uint8_t PIN_BTN_TC      = 3;
const uint8_t PIN_BTN_TV      = 4;
const uint8_t PIN_BTN_COOLING = 5;
const uint8_t PIN_BTN_RADIO   = 6;
const uint8_t PIN_BTN_SS      = 7;

// ---------- demo tuning ----------
const float    MAX_SPEED_KMH   = 120.0;  // throttle pot fully open -> this many km/h
const float    MAX_POWER_KW    = 60.0; //95.0;   // arc goes red above 80 kW, dramatic at full
const float    MAX_G_FORCE     = 1.5;    // joystick full deflection -> +/- this many G
const float    G_DEADZONE      = 0.05;   // ignore tiny wobble at idle
const uint16_t LOOP_PERIOD_MS  = 20;     // 50 Hz
const uint16_t BUTTON_DEBOUNCE_MS = 80;

// ---------- battery model (visible drain + sag) ----------
const float SOC_IDLE_DRAIN_PER_S     = 0.05; // %/s baseline so SoC ticks down even at rest
const float SOC_THROTTLE_DRAIN_PER_S = 1.0;  // up to %/s extra at full throttle
const float SOC_REGEN_RECHARGE_PER_S = 0.5;  // %/s when regen is on AND brake is pressed
const float V_FULL_PACK    = 600.0;          // pack voltage at 100% SoC, no load
const float V_EMPTY_PACK   = 470.0;          // pack voltage at 0% SoC, no load
const float V_SAG_FULL     = 30.0;           // extra droop under full throttle (volts)
const float V_SAG_TAU_S    = 1.5;            // low-pass time constant: voltage sag/recovery takes ~this many seconds

// ---------- runtime state ----------
int  joyZeroX = 512;
int  joyZeroY = 512;
bool regenOn   = false;
bool tcOn      = false;
bool tvOn      = false;
bool coolingOn = false;
bool radioOn   = false;
bool ssOn      = false;
bool btnRegenLast   = HIGH, btnTcLast    = HIGH, btnTvLast = HIGH;
bool btnCoolingLast = HIGH, btnRadioLast = HIGH, btnSsLast = HIGH;
unsigned long btnRegenAt   = 0, btnTcAt    = 0, btnTvAt = 0;
unsigned long btnCoolingAt = 0, btnRadioAt = 0, btnSsAt = 0;
float socFloat = 100.0;
float voltagePack = V_FULL_PACK;
float voltageSagFiltered = 0.0; // smoothed instantaneous sag under load

// ====================================================================
// CAN-over-UART transmitter (matches dashboard FSM exactly)
// ====================================================================
void sendCan(uint32_t canId, uint8_t dlc, const uint8_t *payload) {
  Serial.write((uint8_t)0xAA);                      // sync
  uint8_t header[5];
  header[0] = canId & 0xFF;
  header[1] = (canId >> 8) & 0xFF;
  header[2] = (canId >> 16) & 0xFF;
  header[3] = (canId >> 24) & 0xFF;
  header[4] = dlc;
  Serial.write(header, 5);
  Serial.write(payload, dlc);

  uint8_t cksum = dlc;
  for (uint8_t i = 0; i < dlc; ++i) cksum ^= payload[i];
  Serial.write(cksum);
}

// ====================================================================
// Per-frame senders (scales to match the dashboard's decode math)
// ====================================================================
void sendThrottle(float t01) {
  t01 = constrain(t01, 0.0f, 1.0f);
  uint16_t raw = (uint16_t)(t01 * 1000.0f);          // dash: u16 * 0.001 -> [0,1]
  uint8_t p[2] = { (uint8_t)(raw & 0xFF), (uint8_t)(raw >> 8) };
  sendCan(798, 2, p);
}

void sendBrake(float b01) {
  b01 = constrain(b01, 0.0f, 1.0f);
  uint16_t raw = (uint16_t)(b01 * 20000.0f);         // dash: u16 * 0.01 / 200 -> [0,1]
  uint8_t p[2] = { (uint8_t)(raw & 0xFF), (uint8_t)(raw >> 8) };
  sendCan(101, 2, p);
}

void sendGMeter(float gx, float gy) {
  // Dashboard decode: g = raw_int16 * 0.02 / 9.81  =>  raw = g * 490.5
  long rawXl = (long)(gx * 9.81f / 0.02f);
  long rawYl = (long)(gy * 9.81f / 0.02f);
  rawXl = constrain(rawXl, -32768L, 32767L);
  rawYl = constrain(rawYl, -32768L, 32767L);
  int16_t rawX = (int16_t)rawXl;
  int16_t rawY = (int16_t)rawYl;
  uint8_t p[4] = {
    (uint8_t)(rawX & 0xFF), (uint8_t)((rawX >> 8) & 0xFF),
    (uint8_t)(rawY & 0xFF), (uint8_t)((rawY >> 8) & 0xFF)
  };
  sendCan(1799, 4, p);
}

void sendHero(float speedKmh, float powerKw, int socPct,
              bool tv, bool regen, bool tc,
              bool cooling, bool radio, bool ss) {
  int rawSpeedI = constrain((int)(speedKmh * 100.0f), -32768, 32767);
  int rawPowerI = constrain((int)powerKw, -128, 127);
  int rawSocI   = constrain(socPct, -128, 127);
  int16_t rawSpeed = (int16_t)rawSpeedI;

  // byte 7 bits: 0=TV, 1=Regen, 2=TC, 3=Cooling, 4=Radio, 5=Sideslip
  uint8_t bools = (tv ? 0x01 : 0) | (regen ? 0x02 : 0) | (tc ? 0x04 : 0)
                | (cooling ? 0x08 : 0) | (radio ? 0x10 : 0) | (ss ? 0x20 : 0);

  uint8_t p[8] = {
    (uint8_t)rawPowerI,                              // [0]  power kW (i8)
    0,                                               // [1]  unused
    0,                                               // [2]  unused
    (uint8_t)(rawSpeed & 0xFF),                      // [3]  speed lo
    (uint8_t)((rawSpeed >> 8) & 0xFF),               // [4]  speed hi
    0,                                               // [5]  unused
    (uint8_t)rawSocI,                                // [6]  SoC (i8)
    bools                                            // [7]  status bits
  };
  sendCan(801, 8, p);
}

void sendVoltageCurrent(float voltageV, float currentA) {
  // dashboard decode: V = int16 * 0.1,  I = int16 * 0.01
  int rawVI = constrain((int)(voltageV * 10.0f), -32768, 32767);
  int rawII = constrain((int)(currentA * 100.0f), -32768, 32767);
  int16_t rawV = (int16_t)rawVI;
  int16_t rawI = (int16_t)rawII;
  uint8_t p[6] = {
    (uint8_t)(rawV & 0xFF), (uint8_t)((rawV >> 8) & 0xFF),
    0, 0,                                            // bytes 2-3 unused by parser
    (uint8_t)(rawI & 0xFF), (uint8_t)((rawI >> 8) & 0xFF)
  };
  sendCan(1315, 6, p);
}

// ====================================================================
// Button: debounced falling-edge detector (HIGH -> LOW = press)
// ====================================================================
bool pressed(uint8_t pin, bool &lastState, unsigned long &lastEdgeMs) {
  bool cur = digitalRead(pin);
  unsigned long now = millis();
  bool fired = false;
  if (lastState == HIGH && cur == LOW && (now - lastEdgeMs) > BUTTON_DEBOUNCE_MS) {
    fired = true;
    lastEdgeMs = now;
  }
  lastState = cur;
  return fired;
}

// ====================================================================
// Setup
// ====================================================================
void setup() {
  Serial.begin(115200);

  pinMode(PIN_BTN_REGEN,   INPUT_PULLUP);
  pinMode(PIN_BTN_TC,      INPUT_PULLUP);
  pinMode(PIN_BTN_TV,      INPUT_PULLUP);
  pinMode(PIN_BTN_COOLING, INPUT_PULLUP);
  pinMode(PIN_BTN_RADIO,   INPUT_PULLUP);
  pinMode(PIN_BTN_SS,      INPUT_PULLUP);

  // Auto-zero the joystick. DO NOT TOUCH IT for ~500 ms after power-on.
  long sumX = 0, sumY = 0;
  const int N = 50;
  for (int i = 0; i < N; ++i) {
    sumX += analogRead(PIN_JOY_X);
    sumY += analogRead(PIN_JOY_Y);
    delay(10);
  }
  joyZeroX = sumX / N;
  joyZeroY = sumY / N;
}

// ====================================================================
// Main loop @ 50 Hz
// ====================================================================
void loop() {
  static unsigned long nextTick = 0;
  unsigned long now = millis();
  if ((long)(now - nextTick) < 0) return;
  nextTick = now + LOOP_PERIOD_MS;

  // ---- buttons toggle latched state ----
  if (pressed(PIN_BTN_REGEN,   btnRegenLast,   btnRegenAt))   regenOn   = !regenOn;
  if (pressed(PIN_BTN_TC,      btnTcLast,      btnTcAt))      tcOn      = !tcOn;
  if (pressed(PIN_BTN_TV,      btnTvLast,      btnTvAt))      tvOn      = !tvOn;
  if (pressed(PIN_BTN_COOLING, btnCoolingLast, btnCoolingAt)) coolingOn = !coolingOn;
  if (pressed(PIN_BTN_RADIO,   btnRadioLast,   btnRadioAt))   radioOn   = !radioOn;
  if (pressed(PIN_BTN_SS,      btnSsLast,      btnSsAt))      ssOn      = !ssOn;

  // ---- analog inputs ----
  float throttle01 = analogRead(PIN_THROTTLE) / 1023.0f;
  float brake01    = analogRead(PIN_BRAKE)    / 1023.0f;

  int rawJX = analogRead(PIN_JOY_X) - joyZeroX;
  int rawJY = analogRead(PIN_JOY_Y) - joyZeroY;

  // Map joystick deflection to G's. Typical Arduino joystick: pushing UP
  // (forward) decreases VRy, so we invert Y so the G-dot rises during
  // forward push = "acceleration". If your joystick reads the opposite way,
  // flip the sign of gx or gy below.
  float gx =  (rawJX / 512.0f) * MAX_G_FORCE;
  float gy = -(rawJY / 512.0f) * MAX_G_FORCE;
  if (fabs(gx) < G_DEADZONE) gx = 0;
  if (fabs(gy) < G_DEADZONE) gy = 0;

  // ---- derive hero gauge from throttle ----
  float speedKmh = throttle01 * MAX_SPEED_KMH;
  float powerKw  = throttle01 * MAX_POWER_KW;

  // ---- battery model: drain SoC, sag voltage, optional regen recharge ----
  float dt = LOOP_PERIOD_MS / 1000.0f;
  float drain = (SOC_IDLE_DRAIN_PER_S + SOC_THROTTLE_DRAIN_PER_S * throttle01) * dt;
  socFloat -= drain;
  if (regenOn && brake01 > 0.3f) {
    socFloat += SOC_REGEN_RECHARGE_PER_S * dt;
  }
  if (socFloat > 100.0f) socFloat = 100.0f;

  // Demo auto-reset: pack drained to zero -> snap back to a full charge so
  // the booth never gets stuck at 0% during the day. Reset filter too so the
  // sag doesn't carry a residual offset into the next "fresh battery".
  if (socFloat <= 0.0f) {
    socFloat = 100.0f;
    voltageSagFiltered = 0.0f;
  }

  // Low-pass filter the instantaneous voltage sag so the number drifts down
  // smoothly under throttle instead of snapping the moment the pot moves.
  // tau = V_SAG_TAU_S seconds; bigger value = slower change.
  float targetSag = throttle01 * V_SAG_FULL;
  voltageSagFiltered += (targetSag - voltageSagFiltered) * (dt / V_SAG_TAU_S);

  float baseV = V_EMPTY_PACK + (socFloat / 100.0f) * (V_FULL_PACK - V_EMPTY_PACK);
  voltagePack = baseV - 0.3*voltageSagFiltered;
  // dashboard current sign: positive = discharge
  float currentA = (powerKw * 1000.0f) / (voltagePack > 1.0f ? voltagePack : 1.0f);

  // ---- emit frames this tick ----
  sendThrottle(throttle01);
  sendBrake(brake01);
  sendGMeter(gx, gy);
  sendHero(speedKmh, powerKw, (int)(socFloat + 0.5f),
           tvOn, regenOn, tcOn, coolingOn, radioOn, ssOn);
  sendVoltageCurrent(voltagePack, currentA);
}
