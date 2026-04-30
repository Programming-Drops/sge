# SGE

Sistema de Gestão de Estacionamentos.

Este é o repositório do projeto desenvolvido nas lives do canal. A ideia é
construir, ao vivo, um SGE: um sistema de gestão de estacionamentos, usando
Lazarus, Free Pascal e SQLite.

O projeto é feito com foco didático, mostrando a evolução do código, a criação
das rotinas de banco de dados, organização das units, testes automatizados e o
fluxo de desenvolvimento de uma aplicação CLI em Pascal.

## Estrutura do Projeto

| Pasta/arquivo | Descrição |
| --- | --- |
| `src/` | Código-fonte principal do projeto |
| `src/units/` | Units Pascal usadas pela aplicação |
| `db/` | Scripts SQL para criação da estrutura do banco |
| `tests/` | Testes unitários com FPCUnit |
| `run-tests.ps1` | Script PowerShell para compilar e executar os testes |
| `tools/` | Ferramentas auxiliares usadas no desenvolvimento e nas lives |

## Requisitos

- Lazarus
- Free Pascal Compiler, FPC
- SQLite
- PowerShell, para rodar o script de testes no Windows

No Windows, é recomendado configurar uma variável de ambiente apontando para a
pasta de instalação do Free Pascal.

Exemplo no PowerShell:

```powershell
$env:FPCDIR = "C:\caminho\para\fpc\3.2.2"
```

Exemplo no `cmd`:

```text
set FPCDIR=C:\caminho\para\fpc\3.2.2
```

Normalmente, quando o FPC vem instalado junto com o Lazarus, essa pasta fica
dentro do diretório do Lazarus, por exemplo:

```text
%LAZARUSDIR%\fpc\3.2.2
```

Se quiser, você também pode configurar `LAZARUSDIR`:

```powershell
$env:LAZARUSDIR = "C:\caminho\para\lazarus"
$env:FPCDIR = "$env:LAZARUSDIR\fpc\3.2.2"
```

O executável do compilador costuma ficar em:

```text
%FPCDIR%\bin\x86_64-win64\fpc.exe
```

## Compilando com Lazarus

1. Abra o Lazarus.
2. Vá em **Project > Open Project...**.
3. Selecione o arquivo:

```text
src\sge.lpi
```

4. Compile o projeto com **Run > Build** ou usando o atalho padrão do Lazarus.
5. Para executar, use **Run > Run**.

O arquivo principal do programa é:

```text
src\sge.lpr
```

## Compilando com Free Pascal pela linha de comando

Na raiz do projeto, execute:

```powershell
& "$env:FPCDIR\bin\x86_64-win64\fpc.exe" -MObjFPC -Fusrc\units -FEbin -FUbin\x86_64-win64 src\sge.lpr
```

No `cmd`, o mesmo comando fica:

```bat
"%FPCDIR%\bin\x86_64-win64\fpc.exe" -MObjFPC -Fusrc\units -FEbin -FUbin\x86_64-win64 src\sge.lpr
```

Depois, execute o programa compilado:

```powershell
.\bin\sge.exe
```

Se o comando `fpc` estiver no seu `PATH`, você também pode usar:

```powershell
fpc -MObjFPC -Fusrc\units -FEbin -FUbin\x86_64-win64 src\sge.lpr
```

Para colocar o FPC no `PATH` apenas na sessão atual do PowerShell:

```powershell
$env:PATH = "$env:FPCDIR\bin\x86_64-win64;$env:PATH"
```

## Rodando os Testes

Os testes unitários usam FPCUnit.

Para compilar e executar os testes:

```powershell
.\run-tests.ps1
```

Esse script compila o runner de testes em:

```text
bin\tests\test_runner.exe
```

E em seguida executa os testes.

## Arquivos Ignorados

Arquivos gerados por compilação, bancos locais e diretórios de backup não devem
ser versionados. Exemplos:

- `bin/x86_64-win64/`
- `database.sqlite3`
- `teste.db`
- `src/backup/`
- `**/backup/`
