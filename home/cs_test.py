"""Run with: python3 -m unittest home/cs_test.py"""
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import cs  # noqa: E402


def event(role, content, ts, session="s1", **extra):
    return {"type": role, "sessionId": session, "cwd": "/home/me/repo", "timestamp": ts,
            "message": {"content": content}, **extra}


class CsTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.archive = Path(tmp.name) / "archive"
        self.db = cs.open_index(Path(tmp.name) / "cache" / "index.db")

    def write(self, rel, events):
        path = self.archive / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("".join(json.dumps(e) + "\n" for e in events))
        return path

    def search(self, query, **kwargs):
        cs.update_index(self.db, self.archive)
        return cs.search(self.db, query, **kwargs)

    def test_finds_conversation_text_but_not_tool_output(self):
        self.write("oci/projects/-home-me-repo/s1.jsonl", [
            event("user", "why does the tailnet relay drop packets", "2026-11-01T10:00:00Z"),
            event("assistant", [{"type": "thinking", "thinking": "secretthought"},
                                {"type": "text", "text": "The relay MTU is too high."},
                                {"type": "tool_use", "name": "Bash", "input": {"command": "toolcall"}}],
                  "2026-11-01T10:00:05Z"),
            event("user", [{"type": "tool_result", "content": "tooloutput relay"}], "2026-11-01T10:00:06Z"),
            event("user", "injected relay skill body", "2026-11-01T10:00:07Z", isMeta=True),
        ])
        hits = self.search("relay")
        self.assertEqual([(h["host"], h["session"], h["count"]) for h in hits], [("oci", "s1", 2)])
        self.assertEqual(hits[0]["cwd"], "/home/me/repo")
        for hidden in ("secretthought", "toolcall", "tooloutput", "injected"):
            self.assertEqual(self.search(hidden), [])

    def test_returns_one_hit_per_session_across_hosts_and_stems_words(self):
        self.write("oci/projects/p/a.jsonl", [event("user", "deploying the indexer", "t1", "a")])
        self.write("mac/projects/p/b.jsonl", [event("user", "deploy failed", "t1", "b"),
                                              event("assistant", "deploy fixed", "t2", "b")])
        hits = self.search("deploy")
        self.assertEqual({(h["host"], h["session"]) for h in hits}, {("oci", "a"), ("mac", "b")})
        self.assertEqual(self.search("deploy", project="nowhere"), [])
        self.assertEqual(len(self.search("deploy", limit=1)), 1)

    def test_punctuation_in_query_is_literal(self):
        self.write("oci/projects/p/a.jsonl", [event("user", "run claude-sessions-sync now", "t1", "a")])
        self.assertEqual(len(self.search('claude-sessions-sync "now')), 1)

    def test_reindexes_changed_files_and_drops_deleted_ones(self):
        path = self.write("oci/projects/p/a.jsonl", [event("user", "first draft", "t1", "a")])
        self.assertEqual(len(self.search("draft")), 1)
        self.write("oci/projects/p/a.jsonl", [event("user", "first draft", "t1", "a"),
                                              event("assistant", "second draft", "t2", "a")])
        os.utime(path, ns=(1, 1))  # same-size rewrites still differ by mtime
        self.assertEqual(self.search("draft")[0]["count"], 2)
        path.unlink()
        self.assertEqual(self.search("draft"), [])

    def test_skips_half_written_lines(self):
        path = self.write("oci/projects/p/a.jsonl", [event("user", "complete line", "t1", "a")])
        with open(path, "a") as f:
            f.write('{"type": "user", "message": {"content": "trunc')
        self.assertEqual(len(self.search("complete")), 1)

    def test_indexes_plans(self):
        plan = self.archive / "mac/plans/tidy-otter.md"
        plan.parent.mkdir(parents=True)
        plan.write_text("# Plan\nMigrate the scheduler")
        hit, = self.search("scheduler")
        self.assertEqual((hit["role"], hit["path"]), ("plan", "mac/plans/tidy-otter.md"))

    def test_show_starts_one_turn_before_the_hit(self):
        self.write("oci/projects/p/a.jsonl", [event("user", "one", "t1", "a"),
                                              event("assistant", "two", "t2", "a"),
                                              event("user", "three", "t3", "a"),
                                              event("assistant", "four", "t4", "a")])
        cs.update_index(self.db, self.archive)
        self.assertEqual([t[2] for t in cs.show(self.db, "oci:a")], ["one", "two", "three", "four"])
        self.assertEqual([t[2] for t in cs.show(self.db, "oci:a", at="t3")], ["two", "three", "four"])
        self.assertEqual(cs.show(self.db, "oci:missing"), [])


if __name__ == "__main__":
    unittest.main()
