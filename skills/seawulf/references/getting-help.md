# Getting help from RCI (support tickets)

**Claude drafts tickets; the user submits them.** A ticket goes to people under the user's name, so never
submit one or log in to the helpdesk. Hand the user a ready-to-paste draft and the link.

- Helpdesk: https://iacs.supportsystem.com/ (web form; RCI lists no support email)
- For faster, informal help: RCI's virtual office hours (times on rci.stonybrook.edu's Events page)

## When a ticket is the right step

Check the references and RCI's docs first, then open a ticket for:
- a block only RCI can lift (e.g. NVwulf's `reducequotablock-qos` staying after the user is back under quota);
- accounts and access ("Request an account for SeaWulf", "Request an Account for NVwulf"; new projects are faculty-only);
- storage requests (project space, more quota);
- jobs that keep failing for no reason the user can find, `NODE_FAIL` on the same node repeatedly, modules that won't load on a node type, transfers that fail or crawl;
- advice on submitting jobs, managing storage or setting up software.

Not for: queue waits explained by load or down nodes (show the user `squeue`/`sinfo`), or anything this skill
already answers.

## What every ticket needs (RCI's list, plus what makes it actionable)

1. **Cluster** (SeaWulf or NVwulf) and **login node**
2. **Queue and node type** used
3. **Job ID(s)** and the **job script path**
4. **Exact commands** run
5. **Error messages or log output**: the relevant lines, not whole logs
6. **What was already tried**
7. For account or storage issues: **NetID, PI, project number** (and the Slurm account and QOS names if relevant)

Gather the facts first with commands, not from memory: `sacct -j <id> --format=JobID,State,ExitCode,Elapsed,NodeList`,
`sacctmgr -n -P show assoc user=$USER format=Account,QOS`, quota (`myquota` on SeaWulf,
`lfs quota -h -u $USER /lustre` on NVwulf).

## Draft format

Show the user the help topic, a subject line and the body, plainly:

```
Help topic: <closest topic in the form>
Subject: NVwulf jobs blocked by reducequotablock-qos after getting under quota

Cluster: NVwulf (login1). NetID: <netid>. Slurm account: <account>.
Problem: every job pends with QOSMaxJobsPerUserLimit. My association is on reducequotablock-qos.
I was over my 20 GB /lustre quota (27.4 GB); I'm now at 1.2 GB (lfs quota -h -u $USER /lustre), since <date/time>.
Example job: <id>, debug-b40x4, 1 GPU, pending with QOSMaxJobsPerUserLimit.
Could you lift the block, or tell me when it clears automatically?
```

Keep it short and factual: one problem per ticket, no guesses stated as facts, no passwords or tokens.
