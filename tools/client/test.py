from __future__ import annotations

import argparse
import os
import time
import uuid
from dataclasses import dataclass
from typing import Callable

import requests
from rich import box
from rich.console import Console
from rich.panel import Panel
from rich.prompt import Prompt
from rich.table import Table


DEFAULT_BASE_URL = "http://localhost:8085"
DEFAULT_PASSWORD = "123456"
REQUEST_TIMEOUT = 5


console = Console()


@dataclass
class TestResult:
    name: str
    method: str
    route: str
    ok: bool
    status_code: int | None
    elapsed_ms: float
    detail: str


class ApiClient:
    def __init__(self, base_url: str) -> None:
        self.base_url = base_url.rstrip("/")
        self.session = requests.Session()
        self.access_token: str | None = None
        self.auth_detail: str | None = None

    def url(self, route: str) -> str:
        return f"{self.base_url}{route}"

    def get(self, route: str) -> requests.Response:
        return self.session.get(self.url(route), timeout=REQUEST_TIMEOUT)

    def get_auth(self, route: str, token: str) -> requests.Response:
        return self.session.get(
            self.url(route),
            headers=auth_headers(token),
            timeout=REQUEST_TIMEOUT,
        )

    def post_json(
        self,
        route: str,
        payload: dict[str, str],
        token: str | None = None,
    ) -> requests.Response:
        return self.session.post(
            self.url(route),
            json=payload,
            headers=auth_headers(token) if token else None,
            timeout=REQUEST_TIMEOUT,
        )

    def delete_auth(self, route: str, token: str) -> requests.Response:
        return self.session.delete(
            self.url(route),
            headers=auth_headers(token),
            timeout=REQUEST_TIMEOUT,
        )


def unique_username(prefix: str = "tester") -> str:
    return f"{prefix}_{uuid.uuid4().hex[:12]}"


def unique_cargo_name(prefix: str = "Cargo teste") -> str:
    return f"{prefix} {uuid.uuid4().hex[:8]}"


def auth_headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def make_result(
    name: str,
    method: str,
    route: str,
    ok: bool,
    response: requests.Response | None,
    elapsed_ms: float,
    detail: str,
) -> TestResult:
    return TestResult(
        name=name,
        method=method,
        route=route,
        ok=ok,
        status_code=response.status_code if response is not None else None,
        elapsed_ms=elapsed_ms,
        detail=detail,
    )


def failure_result(
    name: str,
    method: str,
    route: str,
    detail: str,
    response: requests.Response | None = None,
    elapsed_ms: float = 0,
) -> TestResult:
    return make_result(name, method, route, False, response, elapsed_ms, detail)


def format_request_error(exc: requests.RequestException) -> str:
    return f"{exc.__class__.__name__}: {exc}"


def run_request(
    name: str,
    method: str,
    route: str,
    request: Callable[[], requests.Response],
    validate: Callable[[requests.Response], tuple[bool, str]],
) -> TestResult:
    start = time.perf_counter()
    response: requests.Response | None = None

    try:
        response = request()
        ok, detail = validate(response)
    except requests.RequestException as exc:
        ok = False
        detail = f"Falha de conexão: {format_request_error(exc)}"

    elapsed_ms = (time.perf_counter() - start) * 1000
    return make_result(name, method, route, ok, response, elapsed_ms, detail)


def ensure_login(client: ApiClient) -> tuple[str | None, str]:
    if client.access_token:
        return client.access_token, client.auth_detail or "Token reaproveitado"

    username = os.getenv("SGE_TEST_USER") or unique_username("login_user")
    password = os.getenv("SGE_TEST_PASSWORD") or DEFAULT_PASSWORD

    try:
        if "SGE_TEST_USER" not in os.environ:
            create_response = client.post_json("/usuario", {"user": username, "pwd": password})
            if create_response.status_code not in (201, 409):
                detail = (
                    "Não foi possível criar usuário temporário para login. "
                    f"Resposta: {create_response.text.strip() or '<vazia>'}"
                )
                return None, detail

        login_response = client.post_json("/auth/login", {"usr": username, "pwd": password})
    except requests.RequestException as exc:
        return None, f"Falha de conexão durante autenticação: {format_request_error(exc)}"

    if login_response.status_code != 200:
        detail = (
            f"Não foi possível autenticar usuário {username}. "
            f"Resposta: {login_response.text.strip() or '<vazia>'}"
        )
        return None, detail

    try:
        data = login_response.json()
    except ValueError:
        return None, "Login retornou 200, mas não veio JSON válido"

    token = data.get("access_token")
    if not token:
        return None, "Login retornou 200, mas access_token veio ausente"

    client.access_token = token
    client.auth_detail = f"Usuário autenticado: {username}"
    return token, f"Usuário autenticado: {username}"


def create_temp_cargo(client: ApiClient, token: str) -> tuple[int | None, str, str]:
    cargo_name = unique_cargo_name()
    try:
        response = client.post_json("/cargo", {"nome": cargo_name}, token=token)
    except requests.RequestException as exc:
        return None, cargo_name, f"Falha de conexão ao criar cargo temporário: {format_request_error(exc)}"

    if response.status_code != 201:
        detail = f"Não foi possível criar cargo temporário. Resposta: {response.text.strip() or '<vazia>'}"
        return None, cargo_name, detail

    location = response.text.strip()
    try:
        cargo_id = int(location.rstrip("/").split("/")[-1])
    except (IndexError, ValueError):
        return None, cargo_name, f"Cargo criado, mas Location inválido: {location or '<vazio>'}"

    return cargo_id, cargo_name, f"Cargo temporário: {cargo_id}"


def cleanup_cargo(client: ApiClient, token: str, cargo_id: int | None) -> None:
    if cargo_id is not None:
        try:
            client.delete_auth(f"/cargo/{cargo_id}/", token)
        except requests.RequestException:
            pass


def test_health(client: ApiClient) -> TestResult:
    return run_request(
        "Healthcheck",
        "GET",
        "/health",
        lambda: client.get("/health"),
        lambda response: (
            response.status_code == 200 and response.text.strip() == "Healty",
            f"Resposta: {response.text.strip() or '<vazia>'}",
        ),
    )


def test_create_user(client: ApiClient) -> TestResult:
    username = unique_username("public_user")
    payload = {"user": username, "pwd": DEFAULT_PASSWORD}

    return run_request(
        "Criar usuário",
        "POST",
        "/usuario",
        lambda: client.post_json("/usuario", payload),
        lambda response: (
            response.status_code == 201 and response.text.strip().startswith("/usuario/"),
            f"Usuário: {username} | Resposta: {response.text.strip() or '<vazia>'}",
        ),
    )


def test_login(client: ApiClient) -> TestResult:
    username = os.getenv("SGE_TEST_USER") or unique_username("login_user")
    password = os.getenv("SGE_TEST_PASSWORD") or DEFAULT_PASSWORD

    try:
        if "SGE_TEST_USER" not in os.environ:
            create_response = client.post_json("/usuario", {"user": username, "pwd": password})
            if create_response.status_code not in (201, 409):
                return TestResult(
                    name="Login",
                    method="POST",
                    route="/auth/login",
                    ok=False,
                    status_code=create_response.status_code,
                    elapsed_ms=0,
                    detail=(
                        "Não foi possível criar usuário temporário para login. "
                        f"Resposta: {create_response.text.strip() or '<vazia>'}"
                    ),
                )
    except requests.RequestException as exc:
        return failure_result(
            "Login",
            "POST",
            "/auth/login",
            f"Falha de conexão durante preparação: {format_request_error(exc)}",
        )

    return run_request(
        "Login",
        "POST",
        "/auth/login",
        lambda: client.post_json("/auth/login", {"usr": username, "pwd": password}),
        lambda response: validate_login_response(response, username),
    )


def test_list_cargos(client: ApiClient) -> TestResult:
    token, auth_detail = ensure_login(client)
    if not token:
        return failure_result("Listar cargos", "GET", "/cargos", auth_detail)

    return run_request(
        "Listar cargos",
        "GET",
        "/cargos",
        lambda: client.get_auth("/cargos", token),
        lambda response: validate_list_cargos_response(response),
    )


def validate_list_cargos_response(response: requests.Response) -> tuple[bool, str]:
    if response.status_code != 200:
        return False, f"Resposta: {response.text.strip() or '<vazia>'}"

    try:
        data = response.json()
    except ValueError:
        return False, "Resposta 200, mas não veio JSON válido"

    ok = isinstance(data, list)
    return ok, f"Itens retornados: {len(data) if isinstance(data, list) else 'N/A'}"


def test_create_cargo(client: ApiClient) -> TestResult:
    token, auth_detail = ensure_login(client)
    if not token:
        return failure_result("Criar cargo", "POST", "/cargo", auth_detail)

    cargo_name = unique_cargo_name()
    cargo_id: int | None = None

    def validate(response: requests.Response) -> tuple[bool, str]:
        nonlocal cargo_id
        location = response.text.strip()
        ok = response.status_code == 201 and location.startswith("/cargo/")
        if ok:
            try:
                cargo_id = int(location.rstrip("/").split("/")[-1])
            except (IndexError, ValueError):
                ok = False
        return ok, f"Cargo: {cargo_name} | Resposta: {location or '<vazia>'}"

    result = run_request(
        "Criar cargo",
        "POST",
        "/cargo",
        lambda: client.post_json("/cargo", {"nome": cargo_name}, token=token),
        validate,
    )
    cleanup_cargo(client, token, cargo_id)
    return result


def test_get_cargo(client: ApiClient) -> TestResult:
    token, auth_detail = ensure_login(client)
    if not token:
        return failure_result("Consultar cargo", "GET", "/cargo/:id", auth_detail)

    cargo_id, cargo_name, setup_detail = create_temp_cargo(client, token)
    if cargo_id is None:
        return failure_result("Consultar cargo", "GET", "/cargo/:id", setup_detail)

    result = run_request(
        "Consultar cargo",
        "GET",
        f"/cargo/{cargo_id}",
        lambda: client.get_auth(f"/cargo/{cargo_id}", token),
        lambda response: validate_get_cargo_response(response, cargo_id, cargo_name),
    )
    cleanup_cargo(client, token, cargo_id)
    return result


def validate_get_cargo_response(
    response: requests.Response,
    cargo_id: int,
    cargo_name: str,
) -> tuple[bool, str]:
    if response.status_code != 200:
        return False, f"Resposta: {response.text.strip() or '<vazia>'}"

    try:
        data = response.json()
    except ValueError:
        return False, "Resposta 200, mas não veio JSON válido"

    ok = data.get("id") == cargo_id and data.get("nome") == cargo_name
    return ok, f"Cargo esperado: {cargo_id} - {cargo_name}"


def test_update_cargo(client: ApiClient) -> TestResult:
    token, auth_detail = ensure_login(client)
    if not token:
        return failure_result("Atualizar cargo", "POST", "/cargo/:id/", auth_detail)

    cargo_id, _, setup_detail = create_temp_cargo(client, token)
    if cargo_id is None:
        return failure_result("Atualizar cargo", "POST", "/cargo/:id/", setup_detail)

    new_name = unique_cargo_name("Cargo atualizado")
    result = run_request(
        "Atualizar cargo",
        "POST",
        f"/cargo/{cargo_id}/",
        lambda: client.post_json(f"/cargo/{cargo_id}/", {"nome": new_name}, token=token),
        lambda response: (
            response.status_code == 200 and response.text.strip() == "Cargo updated",
            f"Novo nome: {new_name} | Resposta: {response.text.strip() or '<vazia>'}",
        ),
    )
    cleanup_cargo(client, token, cargo_id)
    return result


def test_delete_cargo(client: ApiClient) -> TestResult:
    token, auth_detail = ensure_login(client)
    if not token:
        return failure_result("Excluir cargo", "DELETE", "/cargo/:id/", auth_detail)

    cargo_id, cargo_name, setup_detail = create_temp_cargo(client, token)
    if cargo_id is None:
        return failure_result("Excluir cargo", "DELETE", "/cargo/:id/", setup_detail)

    return run_request(
        "Excluir cargo",
        "DELETE",
        f"/cargo/{cargo_id}/",
        lambda: client.delete_auth(f"/cargo/{cargo_id}/", token),
        lambda response: (
            response.status_code == 200,
            f"Cargo excluído: {cargo_id} - {cargo_name} | Resposta: {response.text.strip() or '<vazia>'}",
        ),
    )


def validate_login_response(response: requests.Response, username: str) -> tuple[bool, str]:
    if response.status_code != 200:
        return False, f"Usuário: {username} | Resposta: {response.text.strip() or '<vazia>'}"

    try:
        data = response.json()
    except ValueError:
        return False, "Resposta 200, mas não veio JSON válido"

    token = data.get("access_token")
    token_type = data.get("token_type")
    expires_in = data.get("expires_in")
    ok = bool(token) and token_type == "Bearer" and expires_in == 3600
    detail = f"Usuário: {username} | Token: {'recebido' if token else 'ausente'}"
    return ok, detail


def public_route_tests() -> list[tuple[str, Callable[[ApiClient], TestResult]]]:
    return [
        ("Healthcheck - GET /health", test_health),
        ("Login - POST /auth/login", test_login),
        ("Criar usuário - POST /usuario", test_create_user),
    ]


def cargo_route_tests() -> list[tuple[str, Callable[[ApiClient], TestResult]]]:
    return [
        ("Listar cargos - GET /cargos", test_list_cargos),
        ("Criar cargo - POST /cargo", test_create_cargo),
        ("Consultar cargo - GET /cargo/:id", test_get_cargo),
        ("Atualizar cargo - POST /cargo/:id/", test_update_cargo),
        ("Excluir cargo - DELETE /cargo/:id/", test_delete_cargo),
    ]


def all_tests() -> list[tuple[str, Callable[[ApiClient], TestResult]]]:
    return public_route_tests() + cargo_route_tests()


def print_header(base_url: str) -> None:
    console.print(
        Panel(
            f"[bold]SGE API Tester[/bold]\n[dim]Base URL:[/dim] {base_url}",
            border_style="cyan",
            box=box.ROUNDED,
        )
    )


def print_menu(base_url: str) -> None:
    table = Table(title="Menu de testes", box=box.SIMPLE_HEAVY)
    table.add_column("Opção", justify="center", style="cyan", no_wrap=True)
    table.add_column("Ação")

    table.add_row("1", "Rodar todos os testes")
    table.add_row("2", "Rodar todos os testes públicos")
    table.add_row("3", "Rodar todos os testes de cargos")
    for index, (label, _) in enumerate(all_tests(), start=4):
        table.add_row(str(index), label)
    table.add_row("B", f"Alterar URL base (atual: {base_url})")
    table.add_row("Q", "Sair")
    console.print(table)


def print_results(results: list[TestResult]) -> None:
    table = Table(title="Resultado", box=box.SIMPLE_HEAVY)
    table.add_column("Status", justify="center", no_wrap=True)
    table.add_column("Teste")
    table.add_column("Método", no_wrap=True)
    table.add_column("Rota")
    table.add_column("HTTP", justify="right", no_wrap=True)
    table.add_column("Tempo", justify="right", no_wrap=True)
    table.add_column("Detalhe")

    for result in results:
        table.add_row(
            "[green]OK[/green]" if result.ok else "[red]ERRO[/red]",
            result.name,
            result.method,
            result.route,
            str(result.status_code) if result.status_code is not None else "-",
            f"{result.elapsed_ms:.0f} ms",
            result.detail,
        )

    console.print(table)


def run_selected_tests(client: ApiClient, selected: list[Callable[[ApiClient], TestResult]]) -> None:
    results: list[TestResult] = []
    for test in selected:
        with console.status(f"Rodando {test.__name__}...", spinner="dots"):
            results.append(test(client))
    print_results(results)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Cliente Rich para testar a API SGE local.")
    parser.add_argument(
        "--base-url",
        default=os.getenv("SGE_API_URL", DEFAULT_BASE_URL),
        help=f"URL base da API. Padrão: {DEFAULT_BASE_URL}",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Roda todos os testes sem abrir o menu.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    base_url = args.base_url
    client = ApiClient(base_url)

    print_header(base_url)

    if args.all:
        run_selected_tests(client, [test for _, test in all_tests()])
        return

    while True:
        print_menu(client.base_url)
        choice = Prompt.ask("Escolha um teste").strip().lower()
        tests = all_tests()

        if choice == "1":
            run_selected_tests(client, [test for _, test in tests])
        elif choice == "2":
            run_selected_tests(client, [test for _, test in public_route_tests()])
        elif choice == "3":
            run_selected_tests(client, [test for _, test in cargo_route_tests()])
        elif choice in {"q", "quit", "sair"}:
            console.print("[cyan]Até mais.[/cyan]")
            return
        elif choice == "b":
            base_url = Prompt.ask("Nova URL base", default=client.base_url)
            client = ApiClient(base_url)
            print_header(client.base_url)
        elif choice.isdigit() and 4 <= int(choice) < len(tests) + 4:
            _, test = tests[int(choice) - 4]
            run_selected_tests(client, [test])
        else:
            console.print("[yellow]Opção inválida.[/yellow]")


if __name__ == "__main__":
    main()
