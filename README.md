
# 🛒 Stride Shopping: Smart Family Hub

**Stride Shopping** is a high-performance platform developed to solve the chaos of household shopping. The system uses a real-time synchronization engine and data intelligence to ensure savings, organization, and, above all, marital peace.

> *"Your problems are over! If you are married, this app will save your life with your spouse. Never forget an item or buy the wrong brand again."*

---

## 🛠 1. Architecture and Tech Stack

The project is structured to ensure near-zero latency and high availability through four pillars:

1. **Frontend Core (`Flutter 3.22+`):** Reactive interface built with Material 3, focused on accessibility and fast shopping flow.
2. **Realtime Engine (`Firebase Firestore`):** Data orchestration via Streams, allowing multiple devices to instantly view changes.
3. **Identity Layer (`Firebase Auth`):** Family data isolation system with secure authentication.
4. **Voice Logic:** Audio conversion layer for hands-free input processing.

---

## 🚀 2. How to Run the Project

### Prerequisites
* **Flutter SDK** (Stable version)
* **Dart 3.0+**
* **Firebase CLI** configured
* **Android Studio / VS Code** with Flutter plugins

### Installation and Execution

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/toshiye/stride-shopping.git
   cd stride-shopping
   ```

2. **Sync Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Start the Environment:**
   ```bash
   flutter run
   ```

---

## 🧠 3. Business Logic and Decision Making

### Fair Price Algorithm (Smart Check)
The system stores the historical average of each item to provide immediate visual feedback and market intelligence to the user:

* **🟢 Green:** Price below or at the average (Purchase opportunity detected).
* **🔴 Red:** Price above the historical average (Local inflation or cost alert).


### Zero-Friction Synchronization (QR Code)
We implemented a pairing system via Deep Linking to eliminate the friction of manual configurations and complex ID exchanges:

1. **Token Generation:** The "Family Master" generates a secure and dynamic Token.
2. **Scan & Bind:** The partner scans the QR Code, and the synchronization engine automatically links the `UIDs` in Firebase, creating an instant bidirectional communication channel.


---

## 📊 4. System Glossary

| Module | Technology | Main Function |
| :--- | :--- | :--- |
| **Scanner Engine** | `mobile_scanner` | Instant reading of family invitations via QR Code. |
| **Voice Input** | `speech_to_text` | Hands-free item addition during the shopping flow. |
| **Data Stream** | `Cloud Firestore` | Real-time global state synchronization between devices. |
| **Local Cache** | `Shared Preferences` | Persistence of UI preferences and local session states. |

---