"""Does the seawulf skill activate when it should, and stay quiet when it shouldn't?

Runs each query in queries.json through `claude -p` with this plugin loaded and ONLY the Skill tool
available, so Claude can choose to activate a skill but can't run commands (no ssh, so no Duo pushes).
A query counts as triggered if Claude calls the Skill tool for seawulf.

    python evals/triggering/check_triggering.py [--claude PATH] [--model MODEL] [--runs N]

These are real, billed model runs (one short run per query per --runs).
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
PLUGIN = os.path.dirname(os.path.dirname(HERE))


def triggered(claude, query, model, timeout=180):
    cmd = [claude, "-p", query, "--plugin-dir", PLUGIN, "--tools", "Skill",
           "--output-format", "stream-json", "--verbose", "--no-session-persistence"]
    if model:
        cmd += ["--model", model]
    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", timeout=timeout, env=env,
                             stdin=subprocess.DEVNULL).stdout
    except subprocess.TimeoutExpired:
        return None
    for line in out.splitlines():
        try:
            event = json.loads(line)
        except ValueError:
            continue
        for block in (event.get("message") or {}).get("content") or []:
            if block.get("type") == "tool_use" and block.get("name") == "Skill" and \
                    "seawulf" in json.dumps(block.get("input", {})):
                return True
    return False


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--claude", default=shutil.which("claude") or "claude")
    ap.add_argument("--model")
    ap.add_argument("--runs", type=int, default=1)
    ap.add_argument("--workers", type=int, default=4)
    args = ap.parse_args()
    queries = json.load(open(os.path.join(HERE, "queries.json"), encoding="utf-8"))
    jobs = [(q, r) for q in queries for r in range(args.runs)]
    with ThreadPoolExecutor(args.workers) as pool:
        results = list(pool.map(lambda j: triggered(args.claude, j[0]["query"], args.model), jobs))
    by_query = {}
    for (q, _), t in zip(jobs, results):
        by_query.setdefault(q["query"], (q["should_trigger"], []))[1].append(t)
    correct = 0
    for query, (want, got) in by_query.items():
        rate = sum(bool(g) for g in got) / len(got)
        ok = (rate >= 0.5) == want
        correct += ok
        print(f"{'ok  ' if ok else 'MISS'} want={'yes' if want else 'no '} triggered={rate:.0%}  {query[:90]}")
    print(f"\n{correct}/{len(by_query)} correct")
    return 0 if correct == len(by_query) else 1


if __name__ == "__main__":
    sys.exit(main())
