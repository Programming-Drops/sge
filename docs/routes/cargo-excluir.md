# `DELETE /cargo/:id/`

Exclui um cargo.

[Voltar ao índice da API](../api.md)

> A barra final faz parte do padrão registrado: `/cargo/:id/`.

## Parâmetros da rota

| Parâmetro | Tipo | Descrição |
| --- | --- | --- |
| `id` | integer | Identificador do cargo |

## Resposta de sucesso

```http
HTTP/1.1 200 OK
```

O corpo da resposta é vazio.

## Erros

| Status | Condição | Corpo observado |
| --- | --- | --- |
| `409 Conflict` | O cargo está associado a outro registro por chave estrangeira | `Conflict` |
| `500 Internal Server Error` | Erro ao executar a exclusão | `Internal Server Error` |

## Exemplo

```bash
curl -X DELETE http://localhost:8085/cargo/3/
```

## Limitação

A exclusão de um ID inexistente pode retornar sucesso se o comando SQL for
executado sem erro.

