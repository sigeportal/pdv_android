---
name: project-memory
description: >-
  Memória consolidada do PDV_NOVO: regras de negócio, tabelas do banco Firebird,
  parâmetros do PortalORM, permissões de supervisor e plano de migração do PDV_android.
---

# Memória do Projeto: PDV_NOVO & Roteiro de Migração

Este documento centraliza as decisões arquiteturais, regras de negócio e o estado atual do ecossistema `PDV_NOVO`.

---

## 🧠 1. Regras de Negócio do PDV_NOVO

1. **Caixa Multi-Contas (`MOV_CON`)**:
   - `MOV_CON = 0`: Movimentação do **Caixa Físico do PDV**.
   - `MOV_CON > 0`: Movimentação de **Contas Financeiras/Bancárias** (relacionadas ao campo `CON_CODIGO` da tabela `CONTAS`).
   - Permite controle isolado de entradas/saídas por conta ou extrato consolidado.

2. **Permissões de Supervisor (Auth Guard)**:
   - **ESC com Carrinho Cheio**: Não permite fechar a tela com produtos lançados sem autorização de supervisor (`AuthPermissionDialog`).
   - **Exclusão ou Decremento de Itens**: Exige confirmação de senha de supervisor com permissão específica.

3. **Produtos com Grade e Variações**:
   - Produtos com variações de grade abrem o `GradeSelectorDialog` para associar o estoque e valor correto ao SKU.

4. **Integração com Centro de Distribuição (CD) e Filiais**:
   - Sincronização e recepção de transferências de estoque com conferência por código de barras (`RecepcaoTransferencias_page.dart`).

---

## 🏛️ 2. Padrões do Backend Delphi (Horse + PortalORM)

- **RTTI Mapeada**: As entidades herdam de `TTabela` (`UnitPortalORM.Model.pas`).
- **Consultas `iQuery`**: É obrigatório usar `Query.AddParam('PARAM', valor)`. O uso de `ParamByName` é proibido.
- **REST First**: Apenas rotas REST dedicadas (`/v1/grupos`, `/v1/grades`, `/v1/usuarios`, etc.) devem ser consumidas pelo frontend.

---

## 🗺️ 3. Roteiro de Migração dos Módulos do `PDV_android`

1. **Módulo de Mesas & Comandas**:
   - Migrar `Mesas_page.dart` e `DetalheComanda_page.dart` para `frontend/lib/Pages/`.
   - Adotar o design system moderno do `PDV_NOVO` e `ConfigController.instance`.
2. **Módulo de Sabores Fracionados (Pizzas 1..4 sabores)**:
   - Migrar assets de `assets/images/X sabores/` para o frontend do `PDV_NOVO`.
   - Implementar cálculo flexível de frações no carrinho de compras.
3. **Módulo de Níveis e Complementos**:
   - Modernizar `adicionais_widget.dart` e `complementos_widget.dart` para os diálogos arredondados do `pdv_portal`.
