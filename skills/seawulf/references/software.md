# Software: modules, Python and conda, containers, interactive apps

## Contents
1. Modules
2. Python, conda and pip
3. GPU Python (PyTorch, vLLM, ...)
4. Containers
5. Notebooks and IDEs
6. Building from source

## 1. Modules

SeaWulf uses Environment Modules 4.5 (`module`). There's no `module spider`.

```
module avail                 # everything (long)
module -t avail 2>&1 | grep -i cuda      # search; -t prints one per line, to stderr
module load gcc/13.2.0       # always give a version in scripts
module list
module purge                 # start clean (do this at the top of job scripts)
```

- **The list depends on the login node**, because MODULEPATH includes architecture folders (`milan`, `skylake`, `xeonMax`). Build and run on the node type you load for.
- Seen on milan on 2026-11-20 (not exhaustive):
  - **Compilers and MPI:** `gcc` 11.2, 12.3, 13.2; `openmpi` 4.1.x and 5.0.2; `mvapich2`; `intel`; `nvhpc`.
  - **Python and envs:** `python` 3.9.7, 3.11.2, 3.12.0 and 3.14.6; `anaconda/3` (default `3-new`); `miniforge/3`; `mamba`.
  - **GPU and ML:** CUDA from `cuda80` to `cuda130`/`cuda133`; `cudnn`; `nccl`; `jax`; `ollama`.
  - **Tools:** `jupyter`; `code-server`; `git`, `git-lfs`; `globus`.
  - **Domain packages:** hundreds, from chemistry and bioinformatics to MATLAB and Mathematica.
- There's even a `claude-code` module.
- System tools on the login node: `git` 2.52, system `python3` 3.9, `tmux`, `screen`. Don't build envs on the system Python.

## 2. Python, conda and pip

```
module load anaconda/3
conda create --prefix /gpfs/home/$USER/envs/myproject python=3.11 -y      # small envs: home
conda create --prefix /gpfs/projects/<Group>/envs/myproject python=3.11 -y   # big envs: group project space
conda activate /gpfs/home/$USER/envs/myproject
```

RCI's rules:
- **Never build environments or install software in scratch.** Scratch deletes files untouched for 45 days, even ones in use, which breaks the env mid-project.
- Never install into `base`, and pin the Python version.

Home is only 20 GB with about 200k files, which a CUDA env can fill. Put big envs in project space if the group has some (`/gpfs/projects/<Group>`, requested by the PI). Keep **caches** (safe to lose) out of home:

```
conda config --add pkgs_dirs /gpfs/scratch/$USER/conda-pkgs
export PIP_CACHE_DIR=/gpfs/scratch/$USER/pip-cache
export HF_HOME=/gpfs/scratch/$USER/hf                 # model downloads re-download if purged
conda clean --all                                      # when home fills up
```

The cache locations are this skill's suggestion, not RCI's: caches can be lost safely, while envs can't.

In job scripts, load and activate inside the script:

```
module load anaconda/3
conda activate /gpfs/home/$USER/envs/myproject
```

Some setups need `source "$(conda info --base)/etc/profile.d/conda.sh"` before `conda activate` in a non-interactive shell; batch login shells usually work without it. A plain `python -m venv` on a module Python (`module load python/3.12.0`) works too, with the same placement rules.

## 3. GPU Python (PyTorch, vLLM, ...)

- Install the pip wheels in the env, for example `pip install torch` or `pip install vllm`. They bring their own CUDA runtime and only need the node's driver. Loading a `cuda*` module isn't needed unless you compile CUDA code.
- Keep heavyweight stacks in **separate envs**. vLLM pins its own torch, so installing it into a working torch env replaces that torch.
- Installs run on the login node; it has internet. **Test on a GPU node**, since the login node has no GPU. `python -c "import torch; print(torch.cuda.is_available())"` belongs inside a GPU job.
- Compute nodes reached huggingface.co and pypi.org when tested on 2026-11-20. Still, downloading weights in a separate CPU job (or on the login node) keeps GPU time for GPU work; run GPU jobs with `HF_HUB_OFFLINE=1`.

## 4. Containers

- `singularity` (SingularityCE 4.5.1) is installed. There's no `apptainer` command.
- `singularity exec --nv image.sif python ...` passes GPUs through.
- Reported: `singularity pull docker://...` was killed (SIGKILL) while extracting large images. Build or pull inside a CPU job with more memory, or export the image with a tool like `crane` and build from that.
- Keep `.sif` files and the Singularity cache (`SINGULARITY_CACHEDIR`) out of home.

## 5. Notebooks and IDEs

Open OnDemand ([sn-ood.seawulf.stonybrook.edu](https://sn-ood.seawulf.stonybrook.edu)) runs **Jupyter** and JupyterLab (on CPU nodes), **RStudio**, **MATLAB**, **code-server** (VS Code in the browser), a desktop, and LLM apps (vLLM or Ollama with Open WebUI). Jupyter opens in home; to reach scratch or project data, make a symlink first: `ln -s /gpfs/scratch/$USER ~/scratch`. For a GPU notebook, use a batch job, or NVwulf's OnDemand.

## 6. Building from source

Build on the login node of the architecture you'll run on, or in a job. Use `module purge`, then load one toolchain (e.g. `gcc/13.2.0` with `openmpi/gcc13.2/4.1.6`), and install into home or project space with `--prefix`. Mixing toolchains is a common cause of segfaults. Anything built on the retired `login1`/`login2` (Haswell) should be rebuilt on milan.
