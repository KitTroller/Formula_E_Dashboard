# 🛰️ The Spacedot Qt/QML Masterclass: Aerospace Ground Segment Engineering
## A Comprehensive Reference for Telecommunications & Satellite Operations

---

## 📖 Preface: The Aerospace Context
At **Spacedot** (specifically for missions like **AcubeSAT**), the software is the primary interface between the vacuum of space and the human researcher. As a Telecommunications Engineer, your responsibility is the **Ground Segment**. You are building the tools that decode radio waves, visualize link budgets, and control high-gain antennas.

Standard software (Python, Web-based) is often too slow or too resource-heavy for real-time mission control. **Qt 6** is the industry standard for aerospace (used by NASA, SpaceX, and the ESA) because it provides the **deterministic performance of C++** with the **fluidity of GPU-accelerated graphics**.

This guide is a university-level reference designed to take you from a "hello world" beginner to an "architect-level" professional.

---

# 📚 Table of Contents
1.  **Foundations: The C++ Meta-System**
2.  **Binary Mechanics: The Meta-Object Compiler (MOC)**
3.  **The Heartbeat: Event-Driven Architecture**
4.  **The Nervous System: Signals, Slots & Queued Connections**
5.  **Memory Engineering: Implicit Sharing & Reference Counting**
6.  **The Bridge: Q_PROPERTY & Reactive UI**
7.  **The Visual Engine: QML, V4, and the Scene Graph**
8.  **Data Structures for Telecom: QByteArray & Bitmasking**
9.  **High-Frequency Telemetry: The Model/View/Delegate Architecture**
10. **Concurrency: Thread Affinity & The Worker Object Pattern**
11. **Aerospace I/O: SerialPort, QCanBus, and Network Sockets**
12. **DSP Visualization: GLSL Shaders & Waterfall Plots**
13. **System Modularity: Qt Remote Objects (QtRO)**
14. **Mission-Critical Reliability: Unit Testing & Profiling**
15. **Conclusion: Your CV as an Aerospace Systems Engineer**

---

<br>

# ⚙️ CHAPTER 1: Foundations - The C++ Meta-System

Standard C++ is a **static** language. Once compiled, the binary has no idea what its own classes or functions are named. For a dynamic UI or a flexible telemetry system, we need **Introspection** (the ability for an object to look at its own structure at runtime).

Qt achieves this through the `QObject` base class.

### 1.1 The `QObject` Paradigm
Every class in your ground station (the Serial Parser, the Link Budget Calculator, the Map View) must inherit from `QObject`.
```cpp
class TelemetryParser : public QObject {
    Q_OBJECT // This macro is MANDATORY
    // ...
};
```
**Why?** Because `QObject` provides:
*   **Identity:** Every object has a unique name and location in a hierarchy.
*   **Ownership:** Parent-child trees prevent memory leaks in long-running mission control apps.
*   **Metadata:** Information about methods and properties that can be accessed by the QML engine.

---

<br>

# 🛠️ CHAPTER 2: Binary Mechanics - The Meta-Object Compiler (MOC)

When you see the `Q_OBJECT` macro, you are triggering a code-generation phase. 

### 2.1 The Code Generation Lifecycle
1.  **Scan:** Qt's `moc` tool reads your header file.
2.  **Introspect:** It finds every `signal` and `slot` you've defined.
3.  **Generate:** It creates a file called `moc_telemetryparser.cpp`.
4.  **Binary String Table:** Inside this file is a massive table of strings and function pointers.

**Professional Insight:** When QML asks for the `snrValue`, it doesn't just "access memory." It queries the **Meta-Object Table** for the index of the property "snrValue" and then calls the associated C++ getter function. This is why Qt is so flexible—it adds a layer of dynamic behavior to static C++.

---

<br>

# 🔄 CHAPTER 3: The Heartbeat - Event-Driven Architecture

In aerospace, "polling" (a loop that checks for data) is forbidden because it wastes CPU and creates jitter. Ground stations use **Event-Driven Architecture**.

### 3.1 The Event Loop (`app.exec()`)
The event loop is a sophisticated `select()` or `poll()` wrapper in the Linux kernel.
```cpp
int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    // Code here setup the app
    return app.exec(); // The CPU "sleeps" here until an event occurs
}
```
### 3.2 Types of Events in a Ground Station:
1.  **Timer Events:** Triggered every X milliseconds for watchdog timers.
2.  **I/O Events:** Triggered when the SDR (Software Defined Radio) has 1024 bytes of data ready.
3.  **User Events:** Clicking the "Arm Antenna" button.

By using an Event Loop, your application consumes **0% CPU** while waiting for a satellite pass, but reacts with **microsecond latency** the moment the first bit hits the antenna.

---

<br>

# 🔗 CHAPTER 4: The Nervous System - Signals & Slots

Signals and Slots are the type-safe, thread-safe communication mechanism of Qt.

### 4.1 Theory: Decoupling
*   **Signal:** "I have received a packet." (The parser doesn't know who is listening).
*   **Slot:** "I update the satellite position." (The UI doesn't know who sent the data).

### 4.2 Queued Connections (The Secret to Smooth UI)
When connecting objects across different threads:
```cpp
connect(parser, &TelemetryParser::newPacket, ui, &Dashboard::update, Qt::QueuedConnection);
```
**Why this is crucial:** In a `QueuedConnection`, the signal is converted into an event and placed in the UI thread's queue. This allows your **Telecom Parser** to run at 1000Hz on a background core without ever crashing the UI.

---

<br>

# 💾 CHAPTER 5: Memory Engineering - Implicit Sharing

As a Telecom Engineer, you handle massive arrays of IQ samples. Copying these in memory is slow. Qt uses **Implicit Sharing (Copy-on-Write)**.

### 5.1 How it works
If you have a 10MB `QByteArray` of raw satellite data:
```cpp
QByteArray dataA = sdr->read();
QByteArray dataB = dataA; // refCount = 2. NO MEMORY COPIED.
```
Only if you modify `dataB` does Qt perform the expensive memory allocation and copy. This allows you to pass high-frequency telemetry across your entire ground station with **near-zero CPU overhead**.

---

<br>

# 🌉 CHAPTER 6: The Bridge - Q_PROPERTY & Reactive UI

`Q_PROPERTY` is how we expose C++ aerospace logic to the QML dashboard.

```cpp
Q_PROPERTY(double linkBudget READ linkBudget NOTIFY linkBudgetChanged)
```

### The Professional Workflow:
1.  **C++:** Calculates the loss based on distance and atmosphere.
2.  **C++:** Updates the `m_linkBudget` variable.
3.  **C++:** Calls `emit linkBudgetChanged();`.
4.  **QML:** The UI sees the signal and automatically redraws the link budget graph.

This is **Reactive Programming**. You never "tell" the UI to update; the UI "observes" the C++ logic.

---

<br>

# 🚀 CHAPTER 7: The Visual Engine - QML & The Scene Graph

QML is a declarative language that describes **state**. Under the hood, it is powered by the **V4 JavaScript Engine** and the **Qt Scene Graph (QSG)**.

### 7.1 V4 Engine
QML files are pre-compiled into bytecode. This is why a complex dashboard can start up on a Raspberry Pi in less than a second.

### 7.2 The Scene Graph
QML does not use the CPU to draw pixels. It creates a tree of polygons (the Scene Graph) and hands them to the **GPU** via OpenGL, Vulkan, or Metal.
*   **Result:** You can animate a 3D satellite model with 60 FPS while the CPU is 100% focused on decoding radio packets.

---

<br>

# 🔢 CHAPTER 8: Data Structures - QByteArray & Bitmasking

Satellite packets (like those in AcubeSAT) are packed tight to save bandwidth. You will spend much of your time bitmasking.

### 8.1 Example: Decoding a CSP Header
The CubeSat Space Protocol (CSP) header is 32 bits.
```cpp
// Payload[0-3] contains the 32-bit header
uint32_t header = (payload[0] << 24) | (payload[1] << 16) | (payload[2] << 8) | payload[3];

// Extract Priority (Bits 30-31)
int priority = (header >> 30) & 0x03;

// Extract Destination Address (Bits 20-24)
int dest = (header >> 20) & 0x1F;
```
Qt's `QByteArray` and `QDataStream` make this binary manipulation incredibly safe and fast compared to standard C `char*` arrays.

---

<br>

# 📊 CHAPTER 9: High-Frequency Telemetry - Model/View

If you have a list of 5,000 historical satellite pings, **do not** create 5,000 QML objects. This will crash the app. Use a **Model/View** architecture.

### 9.1 `QAbstractListModel`
The C++ Model holds the data. The QML `ListView` only asks for the data of the items **currently visible on the screen**.
*   **Efficiency:** Memory usage is constant O(1) regardless of whether you have 10 pings or 10,000,000 pings in the history.

---

<br>

# 🧵 CHAPTER 10: Concurrency - The Worker Object Pattern

**Rule #1 of Ground Stations:** NEVER block the GUI thread.
If your Reed-Solomon error correction takes 50ms, the UI will freeze, and the operator will lose control of the antenna.

### 10.1 The Professional Threading Pattern
```cpp
QThread* thread = new QThread();
TelecomWorker* worker = new TelecomWorker(); // No parent!
worker->moveToThread(thread);

// Start the thread
thread->start();
```
Now, all `readyRead` signals from the SDR are handled on **Thread B**, while the UI stays perfectly responsive on **Thread A**.

---

<br>

# 📡 CHAPTER 11: Aerospace I/O - Serial, CAN & Sockets

Qt handles all physical layers with the same Signal/Slot logic.
*   **`QSerialPort`:** For talking to Antenna Rotators (GS-232/EasyComm).
*   **`QCanBus`:** For talking to satellite PC104 stacks during flat-sat testing.
*   **`QUdpSocket`:** For receiving IQ streams from GnuRadio or SDR# over a network.

---

<br>

# 🎇 CHAPTER 12: DSP Visualization - GLSL Shaders

As a Telecom Engineer, you need **Waterfall Plots**. A waterfall plot at 60 FPS is too heavy for the CPU.

### 12.1 The Shader Solution
You pass the raw FFT data to a **Fragment Shader (GLSL)**. The shader runs on the GPU and maps the signal strength to a color (Blue for cold, Red for hot). 
*   **Performance:** This moves 99% of the visualization load away from the main CPU, leaving it free for the complex SGP4 orbital math.

---

<br>

# 🔌 CHAPTER 13: System Modularity - Qt Remote Objects (QtRO)

In a Spacedot mission, you might have:
1.  A server in the Ground Station hut (C++).
2.  A dashboard in the university lab (QML).
3.  A mobile app for the mission manager (QML/Android).

**Qt Remote Objects** allow you to share your telemetry `QObject` across the network. The mobile app can "subscribe" to the satellite's SNR value as if it were a local variable. If the network drops, QtRO handles the reconnection automatically.

---

<br>

# 🛠️ CHAPTER 14: Reliability - Unit Testing & Profiling

Satellites don't give you second chances. Your ground software must be "Flight Grade."

### 14.1 `QtTest`
You must write unit tests for your binary parsers.
```cpp
void testCspParsing() {
    QByteArray mockData = QByteArray::fromHex("...");
    QCOMPARE(parser.decodePriority(mockData), 3);
}
```
### 14.2 The QML Profiler
Use this to find "Jank." If your waterfall plot drops below 60 FPS, the profiler will show you exactly which JavaScript function or shader is the bottleneck.

---

<br>

# 🏁 CHAPTER 15: Your CV as an Aerospace Systems Engineer

By mastering this guide, you can confidently list these high-level skills on your CV for employers like SpaceX, OHB, or Spacedot:

*   **Real-Time System Architecture:** Expert in Event-Driven designs using Qt 6.
*   **Asynchronous I/O:** Proficient in non-blocking hardware interfacing (Serial, CAN, UDP).
*   **GPU-Accelerated Visualization:** Advanced usage of QML Scene Graph and GLSL Shaders for RF analysis.
*   **Concurrency Mastery:** Implementing high-throughput data pipelines using the Worker Object Pattern.
*   **Binary Protocol Engineering:** Designing and decoding aerospace-grade frames (CSP/AX.25).

---

**Masterclass Conclusion:**
A ground station is a living organism. The C++ is the muscle, the Signals are the nerves, and the QML is the skin. Your job as a Telecom Engineer is to ensure they all move in perfect harmony.

**The satellite is passing. Are you ready?** 🛰️📻
