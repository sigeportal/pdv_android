---
name: thermal-printing
description: >-
  Guia completo de impressão no PDV_NOVO: ESC/POS (Rede e USB), Etiquetas Zebra (ZPL II)
  e relatórios em PDF.
---

# Sistema de Impressão do PDV_NOVO

O `PDV_NOVO` possui uma camada completa de serviços de impressão para automação comercial, localizada em `frontend/lib/Services/`.

---

## 🖨️ Módulos de Impressão

1. **`PrinterService.dart` (ESC/POS)**:
   - Impressão térmica para cupons de venda, comprovantes de fechamento de caixa e conferência de mesa.
   - Suporte a conexão de **Rede TCP** (porta 9100 com timeout defensivo) e **USB nativo**.
   - **Regra de Caracteres**: Execução mandatória de `_semAcentos(texto)` para compatibilidade total com Code Pages de diversas marcas (Epson, Daruma, Bematech, Elgin, Sunmi).

2. **`ZebraPrinterService.dart` (Etiquetas ZPL II)**:
   - Geração de código ZPL II para impressoras Zebra (GC420t, ZD220, ZD230, etc.).
   - Suporte a impressão direta via TCP Raw (9100) ou via Spooler do Windows.
   - Layout customizável: Código de barras (EAN-13 / Code 128), Descrição, Preço e Destaque de Grade/Tamanho.

3. **`PrinterServicePDF.dart`**:
   - Geração de relatórios gerenciais e comprovantes fiscais em PDF integrado ao spooler do sistema operacional via biblioteca `printing`.
