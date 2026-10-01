---
name: tef-paygo
description: >-
  Guia de integração do TEF PayGo no PDV_NOVO: fluxo de transações, intents,
  callbacks, reconciliação e resolução de pendências.
---

# Integração TEF PayGo (`PDV_NOVO`)

Este documento orienta o fluxo de pagamentos eletrônicos com cartão (Débito, Crédito, Voucher) integrado via PayGo no `PDV_NOVO`.

---

## 💳 Arquitetura do TEF no Frontend

Localizado em `frontend/lib/Controller/Tef/`:
- **`paygo_tefcontroller.dart`**: Controlador `GetxController` registrado permanentemente na inicialização do aplicativo (`main.dart`).
- **`paygo_request_handler.dart`**: Monta os payloads e dispara as chamadas via URI/Intent para o integrador PayGo Android/Desktop.
- **`paygo_response_handler.dart`**: Captura retornos de transação assíncrona.
- **`types/pending_transaction_actions.dart`**: Confirmação ou cancelamento de transações que ficaram em estado pendente após queda de energia ou fechamento inesperado.

---

## 🔄 Fluxo de Pagamento na Venda

1. Na tela de pagamento (`Payment_mode_page.dart`):
   ```dart
   final tefController = Get.find<TefController>();
   final requisicao = TransacaoRequisicaoVenda(...);
   final resposta = await tefController.vender(requisicao);
   ```
2. O `TefController` gerencia um `Completer<TransacaoRequisicaoResposta>`, garantindo que:
   - Não ocorram duas transações simultâneas.
   - O aplicativo aguarde o processamento completo na maquininha.
3. Se aprovado, os comprovantes (via do cliente e via do estabelecimento) são impressos automaticamente pelo `PrinterService.dart` e o fechamento da venda é concluído no backend.
