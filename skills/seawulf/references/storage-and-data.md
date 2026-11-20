# Storage and moving data

## Where things go

| Path | Quota | Files | Backed up | Purge | For |
| --- | --- | --- | --- | --- | --- |
| `/gpfs/home/<netid>` (`~`) | 20 GB | ~200,000 | Yes | Kept | Scripts, settings, small envs and software |
| `/gpfs/scratch/<netid>` | 20 TB | 10 million | **No** | **Files older than 45 days deleted** (by modification time) | Job input and output, caches, while working |
| `/gpfs/projects/<Group>` | up to 10 TB (PI requests) | ~10 million | No | Until the project ends | Shared group data, big envs |
| `/gpfs/software` | — | — | — | — | System software (read-only) |

- Run jobs from scratch, then **copy results you need to keep** to home, project space, or off the cluster.
- Never put envs or software in scratch; the purge breaks them.
- Older SBU pages say scratch purges after 30 days; the current RCI storage page says 45. Treat anything in scratch as temporary either way.
- Check usage with `myquota`. It prints GB and file counts against quota for home, scratch and project. Run it on "disk quota exceeded" or "no space left on device".

Quotas checked with `myquota` on 2026-11-20 (home 20 GB / 200,000 files, scratch 20,480 GB / 10,000,000 files). Policy from [storage layout & policies](https://rci.stonybrook.edu/docs/storage-layout-policies).

## Moving data

| Need | How |
| --- | --- |
| Code | Push to git (GitHub etc.), then `git clone`/`git pull` on the cluster. The login node reaches GitHub. This is the best way for Claude to ship code |
| Small text files from Claude | Write them on the cluster with a heredoc inside one remote command (`cat > file <<'X' ... X`) |
| Files to and from a laptop | `scp file seawulf:/gpfs/scratch/<netid>/` or `rsync -av dir/ seawulf:/gpfs/scratch/<netid>/dir/`. Each is a new ssh connection, so a Duo push unless on the VPN or reusing a connection. With `DUO_PASSCODE=push` (see [connecting.md](connecting.md)) they don't need the Duo menu. In one test (Windows/WSL client), scp/sftp over a reused connection failed while plain ssh streaming worked: `tar cf - dir | ssh seawulf 'tar xf - -C /gpfs/scratch/<netid>'` |
| Uploads without a terminal | Open OnDemand's file manager. Good for small files |
| Large datasets | Globus. SeaWulf has no permanent endpoint: on milan1/milan2, run `module load globus/3.15.0`, then `globus login`, then `globus endpoint create --personal`, then `globusconnectpersonal` ([RCI Globus](https://rci.stonybrook.edu/docs/globus-file-transfer)) |
| Downloads from the internet | `wget`/`curl`/`git`/`huggingface-cli` on the login node for modest sizes; a CPU job for big ones |
| Backups | RCI documents rclone ([backing up](https://rci.stonybrook.edu/docs/backing-rclone)) |
| SeaWulf to NVwulf | Separate storage: run `rsync` **on NVwulf**, pulling from SeaWulf |
