# eth-vanity-brev

CUDA Ethereum vanity address generator, ready for **[NVIDIA Brev](https://brev.nvidia.com/environment/)** (Linux VM + GPU).

Based on [manuelinfosec/eth-vanity-cuda](https://github.com/manuelinfosec/eth-vanity-cuda) (AGPL-3.0).

## NVIDIA Brev — quick start

### 1. Create Environment
1. Open https://brev.nvidia.com/environment/
2. Pick a GPU (e.g. **L40S**)
3. Mode: **VM Mode** (Python + CUDA + Docker)
4. Jupyter: **OFF**
5. **Run a Setup Script: ON** — paste [`brev-paste.sh`](brev-paste.sh):

```bash
#!/bin/bash
set -euo pipefail
cd /home/ubuntu/workspace
git clone --depth 1 https://github.com/rheiCEO/eth-vanity-brev.git
cd eth-vanity-brev
bash brev-setup.sh
```

6. Deploy and wait ~2–3 minutes

### 2. Search

SSH / terminal on the instance:

```bash
cd /home/ubuntu/workspace/eth-vanity-brev
./scripts/run.sh dead          # prefix without 0x
./scripts/run.sh cafe beef     # prefix + suffix
WORK_SCALE=17 ./scripts/run.sh aabb
```

Hits (with private keys) go to `results/` — **do not commit or share**.

### 3. Brev CLI (optional)

```bash
brev start https://github.com/rheiCEO/eth-vanity-brev.git \
  --setup-script https://raw.githubusercontent.com/rheiCEO/eth-vanity-brev/main/brev-setup.sh
```

Auto-start search on provision: set env `PREFIX=dead AUTO_RUN=1`.

## Local Linux + CUDA

```bash
./scripts/build.sh
./scripts/run.sh <prefix> [suffix]
```

Env: `DEVICE` (default 0), `WORK_SCALE` (default 16), `CUDA_ARCH` (default `-arch=native`).

## Windows (ethV2.03)

Keep using `SKOMPILUJ.bat` / `SZUKAJ.bat` / `synapse.exe` locally.  
On Brev use **this** repo (Linux binary), not `synapse.exe`.

## Performance (ballpark)

| GPU        | M/s   |
|------------|-------|
| RTX 3070   | ~1000 |
| RTX 3090   | ~1600 |
| RTX 4090   | ~3800 |
| L40S       | tune `WORK_SCALE` 15–17 |

ECC curve init can take a few minutes at high work-scale, then throughput ramps up.

## Security

- Private key = full control of funds. Keep `results/` private.
- Longer prefix = much longer search (each hex char ~×16 harder).

## License

AGPL-3.0 — see [LICENSE](LICENSE). Upstream: manuelinfosec/eth-vanity-cuda.
