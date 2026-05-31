on:
  push:
    branches: [ "main" ]

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  pipeline:
    name: Build, Segurança e Deploy
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}

    steps:
      # PASSO 1 — Baixar o código do repositório para o runner
      - name: 📥 Checkout do Código
        uses: actions/checkout@v4

      # PASSO 2 — Build (verificação simples dos arquivos)
      - name: ⚙️ Build
        run: |
          echo "Verificando arquivos..."
          ls src/
          echo "Build OK!"

      # PASSO 3 — Secrets Scanning (Gitleaks) — quebra se achar credencial
      - name: 🔑 Secrets Scanning - Gitleaks
        run: |
          docker run --rm -v "${{ github.workspace }}:/repo" zricethezav/gitleaks:latest \
            detect \
            --source="/repo" \
            --no-git \
            --config="/repo/.gitleaks.toml" \
            --report-format=sarif \
            --report-path="/repo/gitleaks-report.sarif" \
            --redact \
            --verbose

      # Publica o relatório do Gitleaks como artefato (mesmo se quebrar)
      - name: 📄 Upload do relatório do Gitleaks
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: gitleaks-report
          path: gitleaks-report.sarif
          if-no-files-found: ignore
