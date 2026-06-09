import requests
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

URL = "http://localhost:8085/cargos"
REQUESTS_COUNT = 50
MAX_WORKERS = 5


def make_request():
    response = requests.get(URL)
    return response.status_code


start = time.perf_counter()

with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
    futures = [executor.submit(make_request) for _ in range(REQUESTS_COUNT)]

    success = 0
    errors = 0

    for future in as_completed(futures):
        status = future.result()

        if status == 200:
            success += 1
        else:
            errors += 1

elapsed = time.perf_counter() - start

print(f"Requests: {REQUESTS_COUNT}")
print(f"Success:  {success}")
print(f"Errors:   {errors}")
print(f"Time:     {elapsed:.2f}s")
print(f"RPS:      {REQUESTS_COUNT / elapsed:.2f}")