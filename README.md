# 🛒 Stride Shopping: Smart Family Hub

A **Stride Shopping** é uma plataforma de alta performance desenvolvida para solucionar o caos das compras domésticas. O sistema utiliza um motor de sincronização em tempo real e inteligência de dados para garantir economia, organização e, acima de tudo, a paz conjugal. 

> *"Seus problemas acabaram! Se você é casado, este app vai salvar a sua vida com a patroa. Nunca mais esqueça um item ou compre a marca errada."*

---

## 🛠 1. Arquitetura e Stack Técnica

O projeto foi estruturado para garantir latência próxima de zero e alta disponibilidade através de quatro pilares:

1. **Frontend Core (`Flutter 3.22+`):** Interface reativa construída com Material 3, focada em acessibilidade e rapidez no fluxo de compra.
2. **Realtime Engine (`Firebase Firestore`):** Orquestração de dados via Streams, permitindo que múltiplos dispositivos visualizem alterações instantaneamente.
3. **Identity Layer (`Firebase Auth`):** Sistema de isolamento de dados familiares com autenticação segura.
4. **Voice Logic:** Camada de conversão de áudio para processamento de entradas mãos-livres.

---

## 🚀 2. Como Rodar o Projeto

### Pré-requisitos
* **Flutter SDK** (Versão estável)
* **Dart 3.0+**
* **Firebase CLI** configurado
* **Android Studio / VS Code** com plugins Flutter

### Instalação e Execução

1. **Clone o Repositório:**
   ```bash
   git clone [https://github.com/toshiye/stride-shopping.git](https://github.com/toshiye/stride-shopping.git)
   cd stride-shopping
   ```

2. **Sincronize as Dependências::**
   ```bash
   flutter pub get
    ```

3. **Inicie o Ambiente::**
  ```bash
   flutter run
   ```

---

## 🧠 3. Lógica de Negócio e Tomada de Decisões

### Algoritmo de Preço Justo (Smart Check)
O sistema armazena a média histórica de cada item para fornecer feedback visual imediato e inteligência de mercado ao usuário:

* **🟢 Verde:** Preço abaixo ou na média (Oportunidade de compra detectada).
* **🔴 Vermelho:** Preço acima da média histórica (Inflação local ou alerta de custo).



### Sincronização Zero-Friction (QR Code)
Implementamos um sistema de pareamento via Deep Linking para eliminar a fricção de configurações manuais e troca de IDs complexos:

1. **Geração de Token:** O "Mestre da Família" gera um Token seguro e dinâmico.
2. **Scan & Bind:** O parceiro escaneia o QR Code, e o motor de sincronização vincula os `UIDs` no Firebase automaticamente, criando um canal de comunicação bidirecional instantâneo.



---

## 📊 4. Glossário do Sistema

| Módulo | Tecnologia | Função Principal |
| :--- | :--- | :--- |
| **Scanner Engine** | `mobile_scanner` | Leitura instantânea de convites familiares via QR Code. |
| **Voice Input** | `speech_to_text` | Adição de itens mãos-livres durante o fluxo de compras. |
| **Data Stream** | `Cloud Firestore` | Sincronização de estado global em tempo real entre dispositivos. |
| **Local Cache** | `Shared Preferences` | Persistência de preferências de UI e estados de sessão local. |

---