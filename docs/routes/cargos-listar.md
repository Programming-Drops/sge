# `GET /cargos`

Lista todos os cargos, ordenados pelo ID em ordem crescente.

[Voltar ao índice da API](../api.md)

## Autenticação

Esta rota é protegida. Envie um token JWT válido:

```http
Authorization: Bearer <access_token>
```

## Requisição

Esta rota não recebe parâmetros ou corpo.

```bash
curl http://localhost:8085/cargos \
  -H "Authorization: Bearer <access_token>"
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
