/*
# EXEMPLO DE USO: SelecaoOpcoesProdutoWidget com Niveis

## Estrutura do Modelo

### Nivel
- codigo: int (identificador único do nível)
- titulo: String (Ex: "ESCOLHA O TAMANHO")
- descricao: String (Ex: "Selecione o peso do prato")
- selecaoMin: int (mínimo de seleções)
- selecaoMax: int (máximo de seleções)
  - Se selecaoMax == 1: Escolha ÚNICA (Radio buttons)
  - Se selecaoMax > 1: Múltipla escolha (Contadores)
- opcoes: List<OpcaoNivel>
- codProduto: int (código do produto)

### OpcaoNivel
- codigo: int (identificador único)
- nome: String (Ex: "PP - 400GR")
- valorAdicional: double (valor extra dessa opção)
- ativo: bool (se está ativa)
- ativoStr: String ("S" ou "N")
- codNivel: int (referência ao nível)
- selecionado: bool (se está selecionada - preenchido dinamicamente)
- quantidade: int (quantidade se múltipla escolha - preenchido dinamicamente)

## Passo 1: Receber JSON da API

```dart
final List<dynamic> nivelJsonList = apiResponse['niveis'];
```

## Passo 2: Converter para modelo Nivel

```dart
import 'package:lanchonete/Models/niveis_model.dart';

List<Nivel> niveis = (nivelJsonList as List)
    .map((json) => Nivel.fromJson(json as Map<String, dynamic>))
    .toList();
```

## Passo 3: Abrir widget com diálogo

```dart
import 'package:lanchonete/Components/complementos_widget.dart';

showDialog(
  context: context,
  builder: (context) => Dialog(
    child: SelecaoOpcoesProdutoWidget(
      item: itemSelecionado, // Itens que será preenchido
      niveis: niveis, // Passar os niveis aqui
    ),
  ),
);
```

## Passo 4: Recuperar seleções

Após o usuário clicar em "Salvar", os complementos são salvos automaticamente em:
- `itemSelecionado.complementos` - Lista de Complementos com as opções selecionadas

## Exemplo Completo de JSON

```json
{
  "niveis": [
    {
      "codigo": 1,
      "titulo": "ESCOLHA O TAMANHO",
      "descricao": "Selecione o peso do prato",
      "selecaoMin": 1,
      "selecaoMax": 1,
      "opcoes": [
        {
          "codigo": 1,
          "nome": "PP - 400GR",
          "valorAdicional": 28,
          "ativo": true,
          "ativoStr": "S",
          "codNivel": 1
        }
      ],
      "codProduto": 1
    }
  ]
}
```

## Características

✅ Suporte para níveis de customização com múltiplas opções
✅ Escolha única (radio buttons) ou múltipla (contadores)
✅ Exibe título, descrição e informações de seleção
✅ Calcula total de adicionais automaticamente
✅ Scroll automático entre níveis após seleção
✅ Apresentação visual elegante com Material Design
✅ Compatível com dados mockados se não houver niveis
*/
