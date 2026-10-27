# Contributing to Abhi Ludo 🎲

Thank you for your interest in contributing to **Abhi Ludo**! We welcome contributions, bug fixes, enhancements, and suggestions to make this the best open-source Ludo game experience.

---

## 📜 Code of Conduct

By participating in this project, you agree to maintain a respectful, welcoming, and harassment-free environment for everyone. Please treat all contributors with kindness and constructive feedback.

---

## 🚀 How to Contribute

### 1. Reporting Bugs
- Search existing [GitHub Issues](https://github.com/Abhishekchoudhary9622/Abhi-Ludo/issues) to avoid duplicates.
- If not reported, open a new issue detailing:
  - Exact steps to reproduce.
  - Expected vs actual behavior.
  - Device/OS version and Flutter/Node version.
  - Relevant logs, screenshots, or stack traces.

### 2. Suggesting Features & Enhancements
- Open a feature request issue explaining the motivation, use case, and envisioned user interface or logic.

### 3. Submitting Pull Requests (PRs)
1. **Fork** the repository and clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Abhi-Ludo.git
   cd Abhi-Ludo
   ```
2. **Create a topic branch**:
   ```bash
   git checkout -b feature/amazing-feature
   # or
   git checkout -b fix/bug-description
   ```
3. **Make your changes** adhering to the project's coding standards:
   - Keep the Pure Dart game engine in `mobile/lib/game/` completely decoupled from Flutter UI imports (`package:flutter`).
   - Use Riverpod state management patterns for UI-to-engine state updates.
   - Maintain vector-rendered aesthetic consistency.
4. **Run tests and linters**:
   ```bash
   # Flutter tests & analysis
   cd mobile
   flutter pub get
   flutter analyze
   flutter test

   # Server tests
   cd ../server
   npm install
   node --test
   ```
5. **Commit your changes**:
   ```bash
   git commit -m "feat(rules): add custom timer rule variation"
   ```
6. **Push to your fork** and open a Pull Request against the `main` branch of `Abhishekchoudhary9622/Abhi-Ludo`.

---

## 📐 Coding Conventions

- **Dart/Flutter**: Follow the official [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide. Enforced via `flutter_lints`.
- **Node.js**: Clean ES6+ standard conventions.
- **Git Commit Messages**: Follow the [Conventional Commits](https://www.conventionalcommits.org/) format (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`).

---

## 📄 License

By contributing to **Abhi Ludo**, you agree that your contributions will be licensed under the [MIT License](LICENSE).
