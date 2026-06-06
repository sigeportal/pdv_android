# Troubleshooting - Impressora Não Está Imprimindo

## 📋 Checklist de Diagnóstico

### 1. **Verificar Configurações da Impressora**
- Arquivo: `lib/Services/PrinterService.dart`
- Linhas 10-11:
  ```dart
  static const String _printerIp = '10.0.0.22';
  static const int _printerPort = 9100;
  ```
- **Ação**: Confirme se o IP e porta estão corretos

### 2. **Verificar Conexão da Impressora**

#### No Terminal (Windows):
```powershell
# Teste o ping para a impressora
ping 10.0.0.22

# Teste a porta 9100
Test-NetConnection -ComputerName 10.0.0.22 -Port 9100
```

#### No Terminal (Linux/Mac):
```bash
# Teste o ping
ping 10.0.0.22

# Teste a conexão na porta 9100
nc -zv 10.0.0.22 9100
```

### 3. **Mensagens de Erro Comuns**

#### ❌ "Conectando à impressora..."
- A impressora nunca responde
- **Causas possíveis**:
  - IP incorreto
  - Impressora offline
  - Sem conexão de rede
  - Firewall bloqueando porta 9100

#### ❌ "Erro de conexão com a impressora: OS Error: WSAECONNREFUSED"
- A conexão foi recusada
- **Causas possíveis**:
  - Impressora ligada mas serviço de impressão offline
  - Porta errada

#### ❌ "Erro de conexão com a impressora: OS Error: WSAEHOSTUNREACH"
- Host não alcançável
- **Causas possíveis**:
  - IP errado
  - Impressora fora da rede

### 4. **Encontrar IP da Impressora**

#### Opção 1: Painel da Impressora
- Pressione o botão de menu na impressora
- Procure por "Network Settings" ou "Configurações de Rede"
- Anote o IP exibido

#### Opção 2: Router WiFi
- Acesse o painel de administração do roteador
- Procure por "Dispositivos Conectados"
- Localize a impressora pela MAC ou nome

#### Opção 3: Print a Network Configuration Page
- Muitas impressoras têm um botão para imprimir configurações
- Procure pelo IP na página impressa

### 5. **Corrigir o IP na Configuração**

1. Abra: `lib/Services/PrinterService.dart`
2. Altere a linha 10:
   ```dart
   static const String _printerIp = 'NOVO_IP_AQUI';
   ```
3. Altere a linha 11 se necessário:
   ```dart
   static const int _printerPort = NOVA_PORTA_AQUI;
   ```
4. Salve o arquivo
5. Recompile e execute: `flutter pub get && flutter run`

### 6. **Aumentar Timeout se Necessário**

Se a impressora é lenta, aumente o timeout na linha 12:
```dart
static const Duration _connectionTimeout = Duration(seconds: 10); // De 5 para 10 segundos
```

## 🔍 Debugging

### Ver Logs de Conexão
1. Rode a aplicação com: `flutter run -v` (modo verbose)
2. Busque por mensagens de impressão no console
3. Procure por:
   - `"Conectando à impressora..."`
   - `"Impressão enviada com sucesso!"`
   - `"Erro de conexão com a impressora"`

### Testar Conexão Manualmente (Dart)
```dart
import 'dart:io';

void testPrinterConnection() async {
  try {
    final socket = await Socket.connect('10.0.0.22', 9100,
        timeout: Duration(seconds: 5));
    print('✅ Conexão estabelecida!');
    socket.close();
  } catch (e) {
    print('❌ Erro: $e');
  }
}
```

## 💡 Modelos de Impressoras Populares

### Portas Padrão
- **Maioria**: Porta 9100 (ESC/POS)
- **Algumas Samsung**: Porta 515
- **Epson**: Porta 9100 ou 5800

### IPs Padrão (geralmente)
- Impressoras não configuram automaticamente
- Você precisa atribuir via WiFi/Ethernet manualmente

## 📞 Suporte

Se persistir o problema:
1. Verifique o manual da impressora
2. Teste com outro dispositivo na mesma rede
3. Reinicie a impressora
4. Verifique se a placa de rede da impressora está funcionando

---

**Última atualização**: 29 de Janeiro de 2026
