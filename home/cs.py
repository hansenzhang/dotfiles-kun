"""Search the Claude Code sessions archived in ~/claude-sessions.

cs QUERY...               ranked sessions; opens fzf on a terminal, prints text otherwise
cs show HOST:SESSION      print a session's conversation
"""
import argparse
import json
import os
import shutil
import sqlite3
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ARCHIVE = Path.home() / "claude-sessions"
# A cache derived from the archive: each machine builds its own, and deleting it is safe.
INDEX = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "claude-sessions" / "index.db"

SCHEMA = """
create table if not exists files (path text primary key, mtime_ns integer, size integer);
create virtual table if not exists turns using fts5(
    text, path unindexed, host unindexed, session unindexed, cwd unindexed, role unindexed,
    ts unindexed, tokenize = 'porter unicode61');
"""


def message_text(event):
    """The prose of a user or assistant event. Tool calls, tool output and thinking are left out."""
    if event.get("type") not in ("user", "assistant") or event.get("isMeta"):
        return ""
    content = (event.get("message") or {}).get("content")
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        blocks = [b for b in content if isinstance(b, dict) and b.get("type") == "text"]
        return "\n".join(b.get("text", "") for b in blocks).strip()
    return ""


def file_turns(path):
    """Yield (text, session, cwd, role, ts) for each turn in a transcript or plan file."""
    if path.suffix == ".md":
        ts = datetime.fromtimestamp(path.stat().st_mtime, timezone.utc).isoformat()
        yield path.read_text(errors="replace"), path.stem, "", "plan", ts
        return
    with open(path, errors="replace") as lines:
        for line in lines:
            try:
                event = json.loads(line)
            except ValueError:
                continue  # a line Syncthing has not finished writing
            if not isinstance(event, dict):
                continue
            text = message_text(event)
            if text:
                yield (text, event.get("sessionId") or path.stem, event.get("cwd", ""),
                       event["type"], event.get("timestamp", ""))


def open_index(index):
    index.parent.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(index)
    db.executescript(SCHEMA)
    return db


def update_index(db, archive):
    """Bring the index in line with the archive, reading only files that changed."""
    indexed = {path: stat for path, *stat in db.execute("select path, mtime_ns, size from files")}
    current = {}
    for pattern in ("*/projects/**/*.jsonl", "*/plans/*.md"):
        for path in archive.glob(pattern):
            stat = path.stat()
            current[str(path.relative_to(archive))] = [stat.st_mtime_ns, stat.st_size]
    stale = [path for path in indexed if indexed[path] != current.get(path)]
    changed = [path for path in current if current[path] != indexed.get(path)]
    if len(changed) > 20:
        print(f"indexing {len(changed)} files", file=sys.stderr)
    with db:
        for path in stale:
            db.execute("delete from turns where path = ?", (path,))
            db.execute("delete from files where path = ?", (path,))
        for path in changed:
            host = path.split("/")[0]
            db.executemany(
                "insert into turns values (?, ?, ?, ?, ?, ?, ?)",
                ((text, path, host, session, cwd, role, ts)
                 for text, session, cwd, role, ts in file_turns(archive / path)))
            db.execute("insert into files values (?, ?, ?)", (path, *current[path]))


def search(db, query, limit=20, project="", mark=("", "")):
    """The best-matching turn of each session, best session first."""
    match = " ".join('"%s"' % term.replace('"', '""') for term in query.split())
    rows = db.execute(
        """select host, session, cwd, role, ts, path, snippet(turns, 0, ?, ?, '…', 30)
           from turns where turns match ? and cwd like ? order by bm25(turns) limit 2000""",
        (*mark, match, f"%{project}%"))
    hits = {}
    for host, session, cwd, role, ts, path, snippet in rows:
        hit = hits.setdefault((host, session), {
            "host": host, "session": session, "cwd": cwd, "role": role, "ts": ts, "path": path,
            "snippet": " ".join(snippet.split()), "count": 0})
        hit["count"] += 1
    return list(hits.values())[:limit]


def show(db, key, at=""):
    """A session's turns in order, starting one turn before timestamp `at` when given."""
    host, _, session = key.partition(":")
    turns = db.execute(
        "select role, ts, text from turns where host = ? and session = ? order by ts, rowid",
        (host, session)).fetchall()
    start = next((i for i, turn in enumerate(turns) if turn[1] == at), 0)
    return turns[max(start - 1, 0):]


def resume_hint(hit):
    if hit["role"] == "plan":
        return str(ARCHIVE / hit["path"])
    return f"claude --resume {hit['session']}  # on {hit['host']}, in {hit['cwd']}"


def pick(hits):
    """Let the user choose a hit in fzf, previewing the conversation around it."""
    lines = "\n".join(
        "\t".join([hit["ts"][:10], hit["host"], Path(hit["cwd"]).name, hit["snippet"],
                   f"{hit['host']}:{hit['session']}", hit["ts"], str(n)])
        for n, hit in enumerate(hits))
    fzf = subprocess.run(
        ["fzf", "--ansi", "--delimiter=\t", "--with-nth=1..4", "--no-sort",
         "--preview", f"{sys.argv[0]} show {{5}} --at {{6}}", "--preview-window=down,65%,wrap"],
        input=lines, stdout=subprocess.PIPE, text=True)
    if fzf.returncode == 0:
        print(resume_hint(hits[int(fzf.stdout.rstrip("\n").split("\t")[-1])]))


def main():
    if sys.argv[1:2] == ["show"]:
        parser = argparse.ArgumentParser(prog="cs show")
        parser.add_argument("key", metavar="HOST:SESSION")
        parser.add_argument("--at", default="", help="start one turn before this timestamp")
        args = parser.parse_args(sys.argv[2:])
        turns = show(open_index(INDEX), args.key, args.at)
        if not turns:
            sys.exit(f"no session {args.key}")
        for role, ts, text in turns:
            print(f"━━ {role} {ts}\n{text}\n")
        return

    parser = argparse.ArgumentParser(prog="cs", description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("query", nargs="+")
    parser.add_argument("-n", type=int, default=20, help="sessions to return (default 20)")
    parser.add_argument("-p", "--project", default="", help="only sessions whose cwd contains this")
    args = parser.parse_args()
    interactive = sys.stdout.isatty() and shutil.which("fzf")
    db = open_index(INDEX)
    update_index(db, ARCHIVE)
    try:
        hits = search(db, " ".join(args.query), args.n, args.project,
                      ("\x1b[1;33m", "\x1b[0m") if interactive else ("", ""))
    except sqlite3.OperationalError as error:
        sys.exit(f"bad query: {error}")
    if not hits:
        sys.exit("no matches")
    if interactive:
        pick(hits)
        return
    for hit in hits:
        key = f"{hit['host']}:{hit['session']}"
        print(f"{key}  {hit['ts'][:10]}  {hit['cwd'] or hit['path']}  {hit['count']} matching turns")
        print(f"    {hit['snippet']}")
        print(f"    cs show {key} --at {hit['ts']}")


if __name__ == "__main__":
    main()
