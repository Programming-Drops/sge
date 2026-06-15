# API SGE

Índice das rotas HTTP disponíveis no servidor SGE.

## Visão geral

- URL base local: `http://localhost:8085`
- Formato de entrada: JSON nas rotas que recebem corpo
- Autenticação: rotas protegidas exigem `Authorization: Bearer <access_token>`
- Banco de dados: SQLite, no arquivo `sge.db`
- Servidor: executado sem processamento concorrente (`Threaded = False`)

> O endpoint de login retorna um JWT. Use esse token no cabeçalho
> `Authorization` para acessar as rotas protegidas.

## Rotas

| Método | Rota | Acesso | Descrição |
| --- | --- | --- | --- |
| `GET` | [`/health`](routes/health.md) | Público | Verifica se a API está em execução |
| `POST` | [`/auth/login`](routes/auth-login.md) | Público | Valida credenciais e retorna um JWT |
| `POST` | [`/usuario`](routes/usuario-criar.md) | Público | Cria um usuário |
| `GET` | [`/cargos`](routes/cargos-listar.md) | Protegido | Lista todos os cargos |
| `POST` | [`/cargo`](routes/cargo-criar.md) | Protegido | Cria um cargo |
| `GET` | [`/cargo/:id`](routes/cargo-consultar.md) | Protegido | Consulta um cargo pelo ID |
| `POST` | [`/cargo/:id/`](routes/cargo-atualizar.md) | Protegido | Atualiza o nome de um cargo |
| `DELETE` | [`/cargo/:id/`](routes/cargo-excluir.md) | Protegido | Exclui um cargo |

## Observações gerais

- As respostas de erro são texto puro e não seguem um schema JSON comum.
- JSON malformado pode gerar exceções não convertidas em uma resposta HTTP
  padronizada.
- Não existem rotas HTTP para funcionários, clientes, contratos, veículos ou
  movimentações, embora essas entidades apareçam na estrutura do banco.
