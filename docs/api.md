# API SGE

Índice das rotas HTTP disponíveis no servidor SGE.

## Visão geral

- URL base local: `http://localhost:8085`
- Formato de entrada: JSON nas rotas que recebem corpo
- Autenticação: todas as rotas estão registradas como públicas
- Banco de dados: SQLite, no arquivo `sge.db`
- Servidor: executado sem processamento concorrente (`Threaded = False`)

> O endpoint de login emite um JWT, mas o servidor ainda não valida esse token
> nas demais rotas. Atualmente não é necessário enviar o cabeçalho
> `Authorization`.

## Rotas

| Método | Rota | Descrição |
| --- | --- | --- |
| `GET` | [`/health`](routes/health.md) | Verifica se a API está em execução |
| `POST` | [`/auth/login`](routes/auth-login.md) | Valida credenciais e retorna um JWT |
| `POST` | [`/usuario`](routes/usuario-criar.md) | Cria um usuário |
| `GET` | [`/cargos`](routes/cargos-listar.md) | Lista todos os cargos |
| `POST` | [`/cargo`](routes/cargo-criar.md) | Cria um cargo |
| `GET` | [`/cargo/:id`](routes/cargo-consultar.md) | Consulta um cargo pelo ID |
| `POST` | [`/cargo/:id/`](routes/cargo-atualizar.md) | Atualiza o nome de um cargo |
| `DELETE` | [`/cargo/:id/`](routes/cargo-excluir.md) | Exclui um cargo |

## Observações gerais

- As respostas de erro são texto puro e não seguem um schema JSON comum.
- JSON malformado pode gerar exceções não convertidas em uma resposta HTTP
  padronizada.
- Não existem rotas HTTP para funcionários, clientes, contratos, veículos ou
  movimentações, embora essas entidades apareçam na estrutura do banco.

