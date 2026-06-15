# `POST /cargo`

Cria um cargo.

[Voltar ao índice da API](../api.md)

## Cabeçalhos

```http
Content-Type: application/json
```

## Corpo da requisição

| Campo | Tipo | Obrigatório | Descrição |
| --- | --- | --- | --- |
| `nome` | string | Sim | Nome do cargo |

```json
{
  "nome": "Caixa"
}
```

## Resposta de sucesso

```http
HTTP/1.1 201 Created
Location: /cargo/3
Content-Type: text/plain

/cargo/3
```

## Erros

| Status | Condição | Corpo observado |
| --- | --- | --- |
| `400 Bad Request` | `Content-Type` diferente de `application/json` | `Mime type invalid` |
| `400 Bad Request` | Corpo vazio | `Content cannot be empty` |
| `400 Bad Request` | Campo `nome` ausente | `The "nome" property was not found on payload ` |
| `400 Bad Request` | Não foi possível criar o cargo | `Could not create the new "cargo"` |

## Exemplo

```bash
curl -X POST http://localhost:8085/cargo \
  -H "Content-Type: application/json" \
  -d '{"nome":"Caixa"}'
```

