# `POST /usuario`

Cria um usuário no banco de dados.

[Voltar ao índice da API](../api.md)

## Cabeçalhos

```http
Content-Type: application/json
```

## Corpo da requisição

| Campo | Tipo | Obrigatório | Regras |
| --- | --- | --- | --- |
| `user` | string | Sim | Deve ser único |
| `pwd` | string | Sim | Mínimo de 6 caracteres |

```json
{
  "user": "operador",
  "pwd": "123456"
}
```

## Resposta de sucesso

```http
HTTP/1.1 201 Created
Location: /usuario/1
Content-Type: text/plain

/usuario/1
```

## Erros

| Status | Condição | Corpo observado |
| --- | --- | --- |
| `400 Bad Request` | `Content-Type` diferente de `application/json` | vazio |
| `400 Bad Request` | Corpo vazio | `Content cannot be empty` |
| `400 Bad Request` | Campo `user` ausente | `The "user" property was not found on payload` |
| `400 Bad Request` | Campo `pwd` ausente | `The "pwd" property was not found on payload ` |
| `400 Bad Request` | Senha com menos de 6 caracteres | `The password must have at least 6 characters` |
| `400 Bad Request` | Não foi possível criar o usuário | `Could not create the new "user` |
| `409 Conflict` | Nome de usuário já cadastrado | `This username is already taken` |

## Exemplo

```bash
curl -X POST http://localhost:8085/usuario \
  -H "Content-Type: application/json" \
  -d '{"user":"operador","pwd":"123456"}'
```

## Limitações

- A senha é armazenada sem hash ou criptografia.
- Não existem rotas para consultar, atualizar ou excluir usuários.

