# `GET /cargos`

Lista todos os cargos, ordenados pelo ID em ordem crescente.

[Voltar ao índice da API](../api.md)

## Requisição

Esta rota não recebe parâmetros, corpo ou cabeçalhos obrigatórios.

```bash
curl http://localhost:8085/cargos
```

## Resposta de sucesso

```http
HTTP/1.1 200 OK
Content-Type: application/json
```

```json
[
  {
    "id": 1,
    "nome": "Recepcionista"
  },
  {
    "id": 2,
    "nome": "Gerente"
  }
]
```

Quando não existem cargos, a resposta é um array vazio:

```json
[]
```

