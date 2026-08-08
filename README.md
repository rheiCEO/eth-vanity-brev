# eth-vanity-brev

CUDA Ethereum vanity address generator, ready for **[NVIDIA Brev](https://brev.nvidia.com/environment/)** (Linux VM + GPU).

Based on [manuelinfosec/eth-vanity-cuda](https://github.com/manuelinfosec/eth-vanity-cuda) (AGPL-3.0).

## NVIDIA Brev — szybki start

### 1. Create Environment
1. Wejdź na https://brev.nvidia.com/environment/
2. Wybierz GPU (np. **L40S**)
3. **VM Mode** (Python + CUDA + Docker)
4. Jupyter: **OFF** (niepotrzebny)
5. **Run a Setup Script: ON** → wklej zawartość pliku [`brev-setup.sh`](brev-setup.sh)  
   albo krócej:

```bash
#!/bin/bash
set -euo pipefail
cd /home/ubuntu/workspace
git clone --depth 1 https://github.com/rheiCEO/eth-vanity-brev.git
cd eth-vanity-brev
bash brev-setup.sh
```

6. Deploy → poczekaj aż VM wstanie (~2–3 min)

### 2. Szukaj adresu

Po SSH / terminalu w Brev:

```bash
cd /home/ubuntu/workspace/eth-vanity-brev
./scripts/run.sh dead          # prefix bez 0x
./scripts/run.sh cafe beef     # prefix + suffix
WORK_SCALE=17 ./scripts/run.sh aabb
```

Wyniki (z kluczami prywatnymi) lecą do `results/` — **nie commituj, nie wrzucaj na Discord**.

### 3. CLI Brev (opcjonalnie)

```bash
brev start https://github.com/rheiCEO/eth-vanity-brev.git \
  --setup-script https://raw.githubusercontent.com/rheiCEO/eth-vanity-brev/main/brev-setup.sh
```

Auto-start szukania przy provision:

```bash
# Launch Parameter / env: PREFIX=dead AUTO_RUN=1
```

## Lokalnie (Linux + CUDA)

```bash
./scripts/build.sh
./scripts/run.sh <prefix> [suffix]
```

Zmienne: `DEVICE` (domyślnie 0), `WORK_SCALE` (domyślnie 16), `CUDA_ARCH` (domyślnie `-arch=native`).

## Windows (Twój ethV2.03)

Lokalny stack Synapse zostaje jak był (`SKOMPILUJ.bat` / `SZUKAJ.bat`).  
Na Brev używasz **tego** repo (binarka Linux), nie `synapse.exe`.

## Wydajność

| GPU (orientacyjnie) | M/s |
|---------------------|-----|
| RTX 3070            | ~1000 |
| RTX 3090            | ~1600 |
| RTX 4090            | ~3800 |
| L40S (Brev)         | zwykle bardzo wysoko — stroj `WORK_SCALE` 15–17 |

Init krzywej ECC może zająć kilka minut przy wysokim `work-scale`, potem leci throughput.

## Bezpieczeństwo

- Klucz prywatny = pełna kontrola nad ETH. Trzymaj `results/` lokalnie / szyfruj.
- Nie wrzucaj logów z kluczami do Gita.
- Prefiks dłuższy = znacznie dłuższy czas (każdy hex znak ×16 trudności).

## Licencja

AGPL-3.0 — zobacz [LICENSE](LICENSE). Upstream: manuelinfosec/eth-vanity-cuda.
