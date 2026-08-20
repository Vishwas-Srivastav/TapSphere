# <PROJECT_NAME>

> <PROJECT_DESCRIPTION>

---

## Getting Started

### 1. Local Configuration
```bash
cp .env.example .env
```

### 2. Initialize Engineering Guardrails
```bash
./scripts/setup-guardrails.sh
```

### 3. Install Dependencies
```bash
# <INSTALL_COMMAND> (e.g. npm install / pip install -r requirements.txt / go mod download)
```

### 4. Run Development Server
```bash
# <START_COMMAND> (e.g. npm run dev / python main.py / go run main.go)
```

---

## Development Workflow

- **Default Branch:** `development` (All Pull Requests must target `development`).
- **Production Sync:** Merging into `development` automatically syncs changes to `main`.
- **Branch Naming:** `<PROJECT_INITIALS>-<NUMBER>` (e.g., `WSAI-01`, `UC-01`, `ML-01`).
- **Commit Format:** [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `chore:`).

---

## Documentation & Standards

- **Contributor Guide:** [CONTRIBUTING.md](CONTRIBUTING.md)
- **Engineering Guardrails:** [docs/GUARDRAILS.md](docs/GUARDRAILS.md)
- **UI & Icon Standards:** [docs/UI_GUIDELINES.md](docs/UI_GUIDELINES.md)
- **Security Policy:** [SECURITY.md](SECURITY.md)
- **Template Reference:** [docs/TEMPLATE_GUIDE.md](docs/TEMPLATE_GUIDE.md)
