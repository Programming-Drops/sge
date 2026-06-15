# `POST /cargo/:id/`

Atualiza o nome de um cargo.

[Voltar ao índice da API](../api.md)

> A rota usa `POST`, e não `PUT` ou `PATCH`. A barra final faz parte do padrão
> registrado: `/cargo/:id/`.

## Parâmetros da rota

| Parâmetro | Tipo | Descrição |
| --- | --- | --- |
| `id` | integer | Identificador do cargo |

## Cabeçalhos

```http
Content-Type: application/json
```

## Corpo da requisição

| Campo | Tipo | Obrigatório | Descrição |
| --- | --- | --- | --- |
| `nome` | string | Sim | Novo nome do cargo |

```json
{
  "nome": "Supervisor"
}
```

## Resposta de sucesso

```http
HTTP/1.1 200 OK
Content-Type: text/plain

Cargo updated
```

## Erros

| Status | Condição | Corpo observado |
| --- | --- | --- |
| `400 Bad Request` | `Content-Type` diferente de `application/json` | `Mime type invalid` |
| `400 Bad Request` | Corpo vazio | `Content cannot be empty` |
| `400 Bad Request` | Campo `nome` ausente | `The "nome" property was not found on payload ` |
| `500 Internal Server Error` | A atualização retorna falha | `Internal Server Error` |

## Exemplo

```bash
curl -X POST http://localhost:8085/cargo/1/ \
  -H "Content-Type: application/json" \
  -d '{"nome":"Supervisor"}'
```

## Limitação

O código atual considera a operação bem-sucedida mesmo quando nenhum registro
corresponde ao ID informado, desde que o comando SQL seja executado sem erro.

