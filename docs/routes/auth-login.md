# `POST /auth/login`

Valida credenciais e retorna um token JWT.

[Voltar ao índice da API](../api.md)

## Comportamento atual

A autenticação consulta a tabela `usuarios`. O login é aceito somente quando o
usuário existe, está ativo e a senha confere.

Senhas novas são armazenadas com Argon2id. Usuários antigos com senha em texto
puro são migrados automaticamente para Argon2id após o primeiro login válido.

## Cabeçalhos

```http
Content-Type: application/json
```

## Corpo da requisição

| Campo | Tipo | Obrigatório | Descrição |
| --- | --- | --- | --- |
| `usr` | string | Sim | Nome do usuário |
| `pwd` | string | Sim | Senha |

```json
{
  "usr": "admin",
  "pwd": "admin"
}
```

## Resposta de sucesso

```http
HTTP/1.1 200 OK
Content-Type: application/json
```

```json
{
  "access_token": "<token-jwt>",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

O token:

- usa o algoritmo `HS256`;
- possui emissor `sge.server`;
- possui audiência `sge server api`;
- usa o usuário como subject;
- expira uma hora após a emissão.

## Erros

| Status | Condição | Corpo observado |
| --- | --- | --- |
| `400 Bad Request` | `Content-Type` diferente de `application/json` | vazio |
| `400 Bad Request` | Corpo vazio | `Content cannot be empty` |
| `400 Bad Request` | Campo `usr` ausente | `The "nome" property was not found on payload ` |
| `400 Bad Request` | Campo `pwd` ausente | `The "pwd" property was not found on payload ` |
| `401 Unauthorized` | Usuário inexistente, inativo ou senha inválida | `Unauthorized` |

> A mensagem referente à ausência de `usr` menciona `"nome"` por um erro de
> texto na implementação atual.

## Exemplo

```bash
curl -X POST http://localhost:8085/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usr":"admin","pwd":"admin"}'
```

## Uso do token

Envie o token retornado nas rotas protegidas:

```http
Authorization: Bearer <access_token>
```

## Limitação

- O segredo JWT ainda está fixo no código-fonte para uso didático/local.
