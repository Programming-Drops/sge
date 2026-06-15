# `GET /cargo/:id`

Consulta um cargo pelo ID.

[Voltar ao índice da API](../api.md)

## Autenticação

Esta rota é protegida. Envie um token JWT válido:

```http
Authorization: Bearer <access_token>
```

## Parâmetros da rota

| Parâmetro | Tipo | Descrição |
| --- | --- | --- |
| `id` | integer | Identificador do cargo |

## Resposta de sucesso

```http
HTTP/1.1 200 OK
Content-Type: application/json
```

```json
{
  "id": 1,
  "nome": "Recepcionista"
}
```

## Erros

| Status | Condição |
| --- | --- |
| `404 Not Found` | ID ausente, não numérico ou não encontrado |

## Exemplo

```bash
curl http://localhost:8085/cargo/1 \
  -H "Authorization: Bearer <access_token>"
```
