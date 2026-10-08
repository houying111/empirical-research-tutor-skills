---
name: methods-reference
description: 实证研究方法规范查询库。当学生询问"OLS的适用条件是什么"、"固定效应和随机效应怎么选"、"DID有什么常见误解"、"面板数据怎么聚类标准误"、"合成控制什么时候用"、"RDD操纵检验检验什么"时触发。
version: 1.2.0
last_updated: 2026-10-08
triggers:
  - "OLS适用条件"
  - "固定效应和随机效应怎么选"
  - "DID常见误解"
  - "面板数据聚类标准误"
  - "合成控制适用条件"
  - "RDD操纵检验"
inputs:
  - method_name: 方法名称（OLS/FE/DID/合成控制/RDD）
outputs:
  - spec_table: 该方法对应的规范表
modified_for: 社科本科生陪练场景
---

# 方法规范库

学生询问具体方法的适用条件、必问信息、常见误解或结果解释规范时，
读取 `references/` 下对应的规范表。**先查表再回答，不要凭记忆作答。**

- 查询 OLS 规范 → `references/ols-spec.md`
- 查询面板固定效应规范 → `references/fe-spec.md`
- 查询 DID（含交错 DID 补充）规范 → `references/did-spec.md`
- 查询合成控制规范 → `references/synctrl-spec.md`
- 查询断点回归规范 → `references/rdd-spec.md`
- 查询工具变量规范 → `references/iv-spec.md`
- 查询数据准备与清洗规范 → `references/data-spec.md`

## 规范表统一结构

每张规范表包含七行：
1. **适用条件**
2. **必问信息**（陪练开场必须确认的事）
3. **常见误解**
4. **误判防护**（配套应用验证过的误解检测规则，防止把否定、存疑、反问误判为误解）
5. **结果解释规范**
6. **何时不适用（替代方案）**
7. **必报结果清单**

## 使用规则

- 规范表提供"判定依据"；教学语气仍遵循各 tutor Skill 的"引导而非代劳"与提示阶梯
- 学生问"我该用哪个方法"时，按适用条件行逐条对照，引导学生在其数据里自行核对，而不是直接宣布答案
- 规范表与配套应用"实证学徒"的案例编号互通：case_001 低碳城市（DID）、case_002 全面二孩（反例）、case_003 智慧城市（交错 DID）、case_004 房产税（合成控制）、case_005 扶贫县（RDD）
