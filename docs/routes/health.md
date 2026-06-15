# `GET /health`

Verifica se o servidor HTTP está disponível.

[Voltar ao índice da API](../api.md)

## Requisição

Esta rota não recebe parâmetros, corpo ou cabeçalhos obrigatórios.

```bash
curl http://localhost:8085/health
```

## Resposta de sucesso

```http
HTTP/1.1 200 OK
Content-Type: text/plain

Healty
```

> A palavra `Healty` é retornada dessa forma pela implementação atual.

