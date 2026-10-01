---
name: pdv-architecture
description: >-
  Arquitetura canônica do PDV_NOVO: Frontend Flutter (pdv_portal) cross-platform
  (Windows Desktop e Android) e Backend Delphi Horse com PortalORM.
---

# Arquitetura Canônica do PDV_NOVO (`G:\PROJETOS\PDV_NOVO`)

Este documento serve como referência de arquitetura para o desenvolvimento e recepção de módulos migrados.

---

## 🏗️ 1. Estrutura do Frontend Flutter (`pdv_portal`)

Localizado em `G:\PROJETOS\PDV_NOVO\frontend/lib/`:

```
frontend/lib/
├── Components/       # Diálogos modais modernos, seletores de grade, banners e atalhos
│   ├── AuthPermissionDialog.dart          # Diálogo de autorização de supervisor
│   ├── GradeSelectorDialog.dart           # Seletor visual de variações/tamanhos/SKUs
│   ├── PixQrCodeDialog.dart               # Exibição de QRCode PIX dinâmico
│   ├── ImpressaoEtiquetasZebraDialog.dart  # Modal de impressão de etiquetas ZPL
│   ├── TransferenciaCdNotificationBanner.dart # Notificação de transferências pendentes
│   └── shortcut_widgets.dart              # Atalhos de teclado (F1..F12, ESC, ENTER)
├── Constants.dart    # Paleta de cores reativa e dinâmica vinculada ao ConfigController
├── Controller/       # Controllers de estado e configurações
│   ├── Config.Controller.dart   # Personalização visual (cores, logo, título) e endpoints CD/Filial
│   ├── Comanda.Controller.dart  # Gerenciador de itens, totais, comanda/carrinho
│   ├── Tef/                     # Módulo completo TEF PayGo (GetX)
│   └── usuario_controller.dart  # Sessão do usuário e permissões
├── Models/           # Modelos de dados fortemente tipados
├── Pages/            # Telas modernas e responsivas
│   ├── Principal_page.dart      # Shell principal com Drawer e roteamento de abas
│   ├── Carrinho_page.dart       # Lançamento rápido de itens, teclado numérico e atalhos
│   ├── AberturaCaixa_page.dart / FechamentoCaixa_page.dart # Caixa multi-contas
│   ├── Dashboard_page.dart      # Gráficos de vendas, indicadores e ticket médio
│   ├── Nfce_page.dart / DavsPendentesNfce_page.dart # Emissão e contingência NFC-e
│   ├── Estoque_page.dart / RecepcaoTransferencias_page.dart # Gestão de estoque e CD
│   └── GrupoSubGrupo_page.dart / Tamanhos_page.dart # Cadastros de apoio
├── Services/         # Camada de serviços e comunicação REST
│   ├── GrupoSubGrupoService.dart, ModeloService.dart, TamanhoService.dart, GradeService.dart
│   ├── CaixaService.dart, PixService.dart, NfceService.dart, EstoqueService.dart
│   └── PrinterService.dart, ZebraPrinterService.dart
└── main.dart         # Inicialização MultiProvider + GetMaterialApp com temas dinâmicos
```

---

## 🎨 2. Design System & Tematização Dinâmica

O `PDV_NOVO` adota personalização White-Label através do `ConfigController.instance`:
- `primaryColorHex`, `secondaryColorHex`, `pdvBackgroundHex`.
- `Constants.primaryColor` e `Constants.secondaryColor` são getters reativos que convertem as cores hexadecimais em tempo de execução.
- Interface limpa com cards brancos arredondados, sombras suaves e suporte completo a modo escuro/claro (`ThemeController`).

---

## ⚙️ 3. Backend Delphi (Horse + PortalORM)

Localizado em `G:\PROJETOS\PDV_NOVO\backend/`:
1. **Rotas REST Dedicadas**: Cada entidade possui seu próprio controller REST (`Unit{Entidade}.Controller.pas`) e classe ORM (`Unit{Entidade}.Model.pas` herdando de `TTabela`).
2. **Proibição de `/v1/dataset` Genérico**: Endpoints dedicados (`/v1/grupos`, `/v1/subgrupos`, `/v1/grades`, etc.) substituem queries SQL dinâmicas abertas enviadas pelo cliente.
3. **Regra de Parâmetros SQL (`iQuery`)**:
   - Empregar estritamente `Query.AddParam('PARAM', valor)`.
   - **Nunca** utilizar `ParamByName(...)`.
