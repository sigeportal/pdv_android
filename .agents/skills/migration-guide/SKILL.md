---
name: migration-guide
description: >-
  Guia passo a passo para migrar módulos do PDV_android (Mesas, Comandas, Sabores
  Fracionados, Níveis e Complementos) para o ecossistema PDV_NOVO.
---

# Guia de Migração: `PDV_android` ➡️ `PDV_NOVO`

Este runbook define a metodologia e o checklist técnico para migrar módulos da base legada de lanchonete para a arquitetura moderna do `PDV_NOVO`.

---

## 🎯 Módulos Candidatos à Migração

### 1. Módulo de Mesas & Comandas
- **Origem (`PDV_android`)**: `Pages/Mesas_page.dart`, `Pages/DetalheComanda_page.dart`, `Services/MesaService.dart`, `Services/ComandaService.dart`, `Models/mesa_model.dart`.
- **Alvo (`PDV_NOVO\frontend`)**:
  - Ajustar visual para o design system do `PDV_NOVO` (Cards arredondados com cores reativas `Constants.mesaAberta`, `Constants.mesaOcupada`, `Constants.mesaFechamento`).
  - Integrar com o menu lateral/Drawer de `Principal_page.dart` através do enum `Paginas.mesas`.
  - Integrar com `AuthPermissionDialog` para transferências de mesa e cancelamento de itens enviados à cozinha.

### 2. Módulo de Fracionamento de Sabores (Pizzas 1..4 Sabores)
- **Origem (`PDV_android`)**: `assets/images/1 sabor/`, `2 sabores/`, `3 sabores/`, `4 sabores/`, `Models/produtos_model.dart` (lógica de frações).
- **Alvo (`PDV_NOVO\frontend`)**:
  - Copiar assets para `frontend/assets/images/` e registrar no `pubspec.yaml`.
  - Criar componente moderno de seleção de pizza/sabores que calcula o valor proporcional ou pelo maior valor.

### 3. Módulo de Níveis, Adicionais e Complementos
- **Origem (`PDV_android`)**: `Components/adicionais_widget.dart`, `Components/complementos_widget.dart`, `Models/niveis_model.dart`, `Models/complementos_model.dart`, `Services/ComplementoService.dart`.
- **Alvo (`PDV_NOVO\frontend`)**:
  - Reutilizar a estrutura desacoplada em `frontend/lib/Components/` convertendo os diálogos para o padrão visual moderno.
  - Integrar a listagem de adicionais ao carrinho unificado (`Carrinho_page.dart`).

---

## 📋 Checklist de Migração de um Módulo

1. **Análise de Dependências**:
   - Verificar imports e substituir `package:lanchonete/...` por `package:pdv_portal/...`.
2. **Adaptação Visual & Cores**:
   - Substituir referências hardcoded de cores por `Constants.primaryColor`, `Constants.secondaryColor` ou `Theme.of(context)`.
3. **Comunicação REST**:
   - Substituir chamadas SQL cruas (`/v1/dataset`) por Services que consomem endpoints REST dedicados (`/v1/mesas`, `/v1/comandas`, `/v1/complementos`).
4. **Proteção de Permissões**:
   - Para qualquer operação sensível (descontos, estornos, cancelamento de itens lançados), acionar `AuthPermissionDialog` solicitando validação de supervisor.
5. **Roteamento**:
   - Adicionar a rota em `main.dart` no `getPages` e, se aplicável, no enum `Paginas` de `Principal_page.dart`.
