# Diretrizes do Projeto: Migração e Arquitetura PDV_NOVO

Este ambiente orienta a evolução e migração de módulos entre o **PDV Lanchonete (`PDV_android`)** e a base canônica **`PDV_NOVO` (`G:\PROJETOS\PDV_NOVO`)**.

Consulte as habilidades em `.agents/skills/`:
- `pdv-architecture`: Arquitetura do `PDV_NOVO` (Frontend Flutter `pdv_portal` + Backend Delphi Horse / PortalORM).
- `migration-guide`: Guia passo a passo para migrar módulos do `PDV_android` (Mesas, Comandas, Sabores Fracionados/Níveis) para o `PDV_NOVO`.
- `tef-paygo`: Integração de pagamentos TEF PayGo no padrão `pdv_portal`.
- `thermal-printing`: Impressão térmica ESC/POS, etiquetas Zebra ZPL e relatórios PDF.
- `project-memory`: Memória consolidada das regras de negócio, tabelas do banco Firebird, parâmetros do `PortalORM` e histórico de decisões.
