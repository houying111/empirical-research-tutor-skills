# 实证研究陪练 Skill 包

面向社科本科生的实证研究教学技能集，配套"实证学徒"AI 陪练应用。
覆盖实证研究全链路：**数据准备 → OLS/LPM、面板固定效应、DID（含交错）、
合成控制、断点回归、工具变量** 七大陪练技能 + 方法规范查询库。

## 技能地图

```
research-tutor（入口调度：判断研究阶段，按数据结构与识别条件路由）
├── data-tutor       —— 数据准备：体检/筛选/缺失异常值/合并/可复现 do-file
├── ols-tutor       —— 横截面 · OLS 与线性概率模型（CHDES 正规就业本土案例）
├── fe-tutor        —— 面板固定效应（FE/RE 选择、吸收问题诊断）
├── did-tutor       —— 双重差分（经典 + 交错；平行趋势失败诊断与路由）
├── synctrl-tutor   —— 合成控制（无对照组 / 单一处理单元）
├── rdd-tutor       —— 断点回归（sharp/fuzzy、操纵检验、RLATE）
├── iv-tutor        —— 工具变量（两条件论证、弱工具诊断、LATE）
└── methods-reference —— 方法规范查询库（七张统一结构规范表）
```

**与配套应用"实证学徒"的关系**：应用承担 12 阶段课程与 5 个案例演练
（case_001 低碳城市 DID / case_002 全面二孩反例 / case_003 智慧城市交错 DID /
case_004 房产税合成控制 / case_005 扶贫县 RDD）；本技能包承担课后开放式陪练、
诊断与规范查询，案例编号、误解判定规则与应用互通。

## 安装

- **Agent 环境（Trae / Claude Code 等）**：将本目录复制到 agents 的 skills 目录，
  按 `manifest.json` 批量加载，或由各 SKILL.md 的 description 自动触发
- **独立使用**：把对应 SKILL.md 作为 system prompt 注入；references/ 按需读取

## 目录结构

```
skills/
├── README.md  LICENSE  manifest.json
├── _shared/                              全技能共享守则
│   ├── misconception-guards.md           误解判定规则（句内匹配/否定豁免/质问处理）
│   ├── academic-integrity.md             学术诚信边界（拒代写/伪造/p-hacking）
│   └── mastery-rubrics.md                八份掌握度行为清单（教学效果证据）
├── research-tutor/SKILL.md
├── data-tutor/    SKILL.md + scripts/data-cleaning-template.do
├── ols-tutor/
│   ├── SKILL.md
│   ├── references/ols-primer.md
│   ├── references/ols-case-china.md       CHDES 正规就业案例（可核验文献）
│   ├── references/source-and-usage-conditions.md  来源/申请/合规/核对状态
│   ├── references/variable-dictionary.xlsx
│   └── scripts/ols-stata-template.do
├── fe-tutor/      SKILL.md + references/fe-primer.md
├── did-tutor/     SKILL.md + references/did-primer.md + scripts/did-stata-template.do
├── synctrl-tutor/ SKILL.md + scripts/synctrl-stata-template.do
├── rdd-tutor/     SKILL.md + scripts/rdd-stata-template.do
├── iv-tutor/      SKILL.md + scripts/iv-stata-template.do
├── methods-reference/SKILL.md + references/{ols,fe,did,synctrl,rdd,iv,data}-spec.md
└── evals/                                可执行评测集
    ├── routing.jsonl        10 条路由用例（含歧义触发消歧）
    ├── misconception.jsonl  16 条误解判定用例（正反各半，含否定/质问反例）
    ├── behavior.jsonl       7 条教学行为用例（提示阶梯/诚信/语气/RLATE）
    └── run_evals.py         无依赖评测脚本（离线/在线双模式）
```

## 评测（可现场演示的教学质量证据）

```bash
# 离线模式：用例格式校验 + 全包引用断链检查 + 规则覆盖检查（无需任何依赖与密钥）
python evals/run_evals.py

# 在线模式：把 SKILL.md 作为 system prompt 实跑对话用例
#   环境变量与主应用一致：LLM_API_KEY / LLM_BASE_URL / LLM_MODEL
python evals/run_evals.py --llm
```

33 条用例覆盖三类能力：路由正确性（含"双向固定效应"歧义消歧）、
误解判定的正反例（否定语气、质问澄清、邻接约束）、
教学行为（提示阶梯不跳级、拒绝代写与伪造数据、禁止不耐烦语气、RLATE 外推拦截）。

## 设计原则（评审要点）

1. **陪练而非代劳**：一次只问一个问题；"提示阶梯"四级逐级放出
   （提问 → 思考方向 → 半成品 → 完整代码）；每技能附反模式清单
2. **误判防护工程化**：误解检测只做句内匹配、否定语境豁免、百分比须有主张形式、
   质问式回复不当答题——全部规则来自配套应用真实迭代（曾修复"相当于放弃 RDD"
   被反向误判、置信水平被误判为百分比等问题），并沉淀为共享守则与正反评测用例
3. **学术诚信成体系**：拒绝代写/伪造数据/p-hacking/违规分发数据库的话术与合规替代；
   CHDES 案例建立"来源核对状态 + 模拟数据强制标注 + 禁止分发原始库"制度
4. **可核验教学内容**：本土案例基于可查证的 CSSCI 文献（黄阳华等，
   《数量经济技术经济研究》2025 年第 7 期）；规范表含"何时不适用（替代方案）"
   与"必报结果清单"；Stata 模板可运行（DID 安慰剂含完整 500 次循环）
5. **结构化输出契约 + 掌握度 rubric**：每技能定义 JSON 输出
   （stage / misconception_flag / hint_level / next_question / route_to），
   配行为式掌握清单，教学效果可观测、可答辩演示

## 版本

- **v1.2.0**（2026-10-08）：新增 data-tutor、iv-tutor 与 iv/data 规范表；
  _shared 三共享模块（误判守则/诚信边界/掌握度 rubric）；evals 评测集与脚本；
  CHDES 案例重排并升级 LPM 教学点；FE/DID 触发消歧；manifest 与 LICENSE
- v1.1.0（2026-10-06）：新增 synctrl-tutor、rdd-tutor；提示阶梯/反模式/输出契约/黄金示例全覆盖
- v1.0.0：初始五技能

## 许可与来源

代码 MIT，教学内容 CC BY-NC-SA 4.0，详见 [LICENSE](LICENSE)。
did-tutor 改编自 `ptreezh/sscisubagent-skills` 与
`scdenney/open-science-skills`，再分发前请核对上游许可；
CHDES/CFPS 原始数据库不得随包分发。
