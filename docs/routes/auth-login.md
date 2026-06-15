# `POST /auth/login`

Valida credenciais e retorna um token JWT.

[Voltar ao índice da API](../api.md)

## Comportamento atual

A autenticação é aceita quando os valores de `usr` e `pwd` são iguais. As
credenciais ainda não são consultadas no banco de dados.

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
Content-Type: text/plain

<token-jwt>
```

O token:

- usa o algoritmo configurado pela biblioteca LazJWT;
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
| `401 Unauthorized` | `usr` e `pwd` possuem valores diferentes | `Unauthorized` |

> A mensagem referente à ausência de `usr` menciona `"nome"` por um erro de
> texto na implementação atual.

## Exemplo

```bash
curl -X POST http://localhost:8085/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usr":"admin","pwd":"admin"}'
```

## Limitações

- O token emitido não é validado nas demais rotas.
- O segredo JWT está fixo no código-fonte.
- O login não consulta os usuários cadastrados.

