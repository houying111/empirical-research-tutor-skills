#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
实证研究陪练 Skill 包评测脚本（仅依赖 Python 标准库）

用法：
  python run_evals.py          离线模式：用例格式校验 + 引用断链检查 + 规则覆盖检查
  python run_evals.py --llm    在线模式：调用 OpenAI 兼容接口跑对话用例

在线模式环境变量：
  LLM_API_KEY    密钥
  LLM_BASE_URL   如 https://open.bigmodel.cn/api/paas/v4
  LLM_MODEL      如 glm-4-flash
"""

import glob
import json
import os
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent          # skills/
EVALS_DIR = Path(__file__).resolve().parent

TUTORS = ["ols-tutor", "fe-tutor", "did-tutor", "synctrl-tutor",
          "rdd-tutor", "iv-tutor", "data-tutor"]
ALL_SKILLS = ["research-tutor"] + TUTORS + ["methods-reference"]
KNOWN_EXPECT_KEYS = {"route", "flag", "contains", "contains_any", "not_contains"}

results = []  # (ok, label, detail)


def record(ok, label, detail=""):
    results.append((bool(ok), label, detail))


# ---------------------------------------------------------------- 用例加载
def load_cases():
    cases = []
    for path in sorted(EVALS_DIR.glob("*.jsonl")):
        for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            line = line.strip()
            if not line:
                continue
            try:
                case = json.loads(line)
            except json.JSONDecodeError as e:
                record(False, f"{path.name}:{lineno}", f"JSON 解析失败：{e}")
                continue
            case["_file"] = path.name
            cases.append(case)
    return cases


def validate_cases(cases):
    seen = set()
    for c in cases:
        cid = c.get("id", "<无 id>")
        prefix = f"用例 {cid}（{c.get('_file')}）"
        if cid in seen:
            record(False, prefix, "id 重复")
        seen.add(cid)
        for key in ("skill", "user", "expect"):
            if key not in c:
                record(False, prefix, f"缺少字段 {key}")
        skill_md = ROOT / c.get("skill", "") / "SKILL.md"
        if not skill_md.exists():
            record(False, prefix, f"技能文件不存在：{skill_md}")
        expect = c.get("expect", {})
        unknown = set(expect) - KNOWN_EXPECT_KEYS
        if unknown:
            record(False, prefix, f"未知断言类型：{unknown}")
    record(True, "用例格式校验", f"共 {len(cases)} 条")


# ---------------------------------------------------------------- 断链检查
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
BACKTICK_PATH_RE = re.compile(
    r"`((?:\.\./)?(?:references|scripts|_shared)/[^`\s]+|[\w.-]+\.(?:md|do|xlsx))`")


def check_links():
    checked = 0
    for md in ROOT.rglob("*.md"):
        text = md.read_text(encoding="utf-8")
        candidates = set(LINK_RE.findall(text))
        candidates |= set(BACKTICK_PATH_RE.findall(text))
        for target in candidates:
            target = target.split("#")[0].strip()
            if not target or target.startswith(("http://", "https://", "mailto:")):
                continue
            resolved = (md.parent / target).resolve()
            checked += 1
            if not resolved.exists():
                record(False, f"断链：{md.relative_to(ROOT)}", f"→ {target}")
    record(True, "引用链接检查", f"共核对 {checked} 个引用")


# ---------------------------------------------------------------- 规则覆盖
def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def coverage_checks():
    for skill in TUTORS:
        text = read(f"{skill}/SKILL.md")
        if "提示阶梯" in text and "反模式" in text:
            record(True, f"覆盖：{skill} 含提示阶梯+反模式")
        else:
            record(False, f"覆盖：{skill}", "缺少提示阶梯或反模式")
        if "../_shared/misconception-guards.md" in text:
            record(True, f"覆盖：{skill} 引用共享误判守则")
        else:
            record(False, f"覆盖：{skill}", "未引用 _shared/misconception-guards.md")

    guards = read("_shared/misconception-guards.md")
    for word in ["并没", "有待", "并不是", "不等于", "句内匹配", "质问"]:
        record(word in guards, f"覆盖：守则含关键规则「{word}」")

    integrity = read("_shared/academic-integrity.md")
    for word in ["代写", "伪造", "p-hacking", "模拟数据"]:
        record(word in integrity, f"覆盖：诚信边界含「{word}」")

    manifest = ROOT / "manifest.json"
    if manifest.exists():
        data = json.loads(manifest.read_text(encoding="utf-8"))
        listed = {s["name"] for s in data.get("skills", [])}
        for s in ALL_SKILLS:
            record(s in listed, f"manifest 收录 {s}")
    else:
        record(False, "manifest.json", "不存在")

    readme = read("README.md")
    record("evals/run_evals.py" in readme or "run_evals.py" in readme,
           "README 说明评测方式")


# ---------------------------------------------------------------- 在线评测
def extract_json(text):
    for i, ch in enumerate(text):
        if ch != "{":
            continue
        try:
            obj, _ = json.JSONDecoder().raw_decode(text[i:])
            return obj
        except json.JSONDecodeError:
            continue
    return None


def call_llm(system_prompt, user_prompt):
    base = os.environ.get("LLM_BASE_URL", "").rstrip("/")
    key = os.environ.get("LLM_API_KEY", "")
    model = os.environ.get("LLM_MODEL", "")
    if not (base and key and model):
        sys.exit("在线模式需要环境变量 LLM_API_KEY / LLM_BASE_URL / LLM_MODEL")
    url = base + "/chat/completions"
    payload = {
        "model": model,
        "temperature": 0,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
    }
    req = urllib.request.Request(
        url, data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json",
                 "Authorization": f"Bearer {key}"}, method="POST")
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    return data["choices"][0]["message"]["content"]


def evaluate(case, answer):
    expect = case["expect"]
    ok_all, details = True, []

    if "route" in expect:
        obj = extract_json(answer) or {}
        got = obj.get("next_skill") or obj.get("route_to")
        ok = got == expect["route"]
        ok_all &= ok
        details.append(f"route 期望 {expect['route']}，实际 {got}")

    if "flag" in expect:
        obj = extract_json(answer) or {}
        got = obj.get("misconception_flag")
        ok = got == expect["flag"]
        ok_all &= ok
        details.append(f"flag 期望 {expect['flag']}，实际 {got}")

    for word in expect.get("contains", []):
        ok = word in answer
        ok_all &= ok
        details.append(f"包含「{word}」: {ok}")

    if "contains_any" in expect:
        ok = any(w in answer for w in expect["contains_any"])
        ok_all &= ok
        details.append(f"包含任一 {expect['contains_any']}: {ok}")

    for word in expect.get("not_contains", []):
        ok = word not in answer
        ok_all &= ok
        details.append(f"不包含「{word}」: {ok}")

    return ok_all, "；".join(details)


DIRECTIVES = {
    "routing": "\n\n请严格按你的输出契约，只输出一个 JSON 对象，不要输出多余文字。",
    "misconception": ('\n\n请判断该学生回复是否构成方法误解。只输出 JSON：'
                      '{"misconception_flag": true 或 false, "note": "简短依据"}'),
    "behavior": "",
}


def run_llm_cases(cases):
    for c in cases:
        system_prompt = read(f"{c['skill']}/SKILL.md")
        user_prompt = c["user"] + DIRECTIVES.get(c.get("category", ""), "")
        try:
            answer = call_llm(system_prompt, user_prompt)
        except Exception as e:  # noqa: BLE001
            record(False, f"用例 {c['id']}", f"接口调用失败：{e}")
            continue
        ok, detail = evaluate(c, answer)
        record(ok, f"用例 {c['id']}", detail)


# ---------------------------------------------------------------- main
def report(title):
    passed = sum(1 for ok, _, _ in results if ok)
    failed = [(label, detail) for ok, label, detail in results if not ok]
    print(f"\n===== {title} =====")
    for ok, label, detail in results:
        print(f"[{'PASS' if ok else 'FAIL'}] {label}" + (f" —— {detail}" if detail and not ok else ""))
    print(f"\n合计 {passed} 通过 / {len(failed)} 失败 / 共 {len(results)} 项")
    return 1 if failed else 0


def main():
    cases = load_cases()
    if "--llm" in sys.argv:
        validate_cases(cases)
        run_llm_cases(cases)
        return report("在线对话评测（LLM）")
    validate_cases(cases)
    check_links()
    coverage_checks()
    return report("离线评测：用例格式 + 断链 + 规则覆盖")


if __name__ == "__main__":
    sys.exit(main())
