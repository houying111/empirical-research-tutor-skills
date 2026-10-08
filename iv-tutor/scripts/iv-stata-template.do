* ============================================
* 工具变量（2SLS）Stata 模板 (v1.0)
* 需要预先安装：ssc install ivreg2 ranktest, replace
* 约定：y = 因变量；x = 内生解释变量；
*       z = 工具变量；x1 x2 = 外生控制变量
* ============================================

* ---- Step 1: 先看朴素 OLS（作为对照，不作因果结论）----
reg y x x1 x2, robust

* ---- Step 2: 第一阶段手动回归（务必先单独看一眼）----
reg x z x1 x2, robust
* 检验 z 的系数方向、量级与显著性；手动 F 需用 ivreg2 输出的
* Cragg-Donald/Kleibergen-Paap Wald F，经验标准 F ≥ 10

* ---- Step 3: 2SLS 基准估计 ----
* 圆括号内：x 为内生变量，z 为其工具变量
ivreg2 y (x = z) x1 x2, robust first
* 重点看：
*   First-stage F statistic（弱工具诊断，≥10）
*   x 的 2SLS 系数与稳健标准误

* ---- Step 4: 聚类稳健（处理发生在组层面时）----
* ivreg2 y (x = z) x1 x2, cluster(province_id) first

* ---- Step 5: 过度识别检验（仅当工具数 > 内生变量数）----
* ivreg2 y (x = z1 z2) x1 x2, robust
* 输出 Sargan/Hansen J 统计量：
*   p 很小 → 至少一个工具不外生；
*   p 大    → "没有拒绝"≠"证明外生"，仍需制度论证

* ---- Step 6: 弱工具稳健推断对照 ----
* LIML 对弱工具比 2SLS 更不敏感（同样需要外生工具）：
* ivreg2 y (x = z1 z2) x1 x2, liml

* ---- Step 7: 含高维固定效应的 IV ----
* 需要：ssc install ivreghdfe ftools reghdfe
* ivreghdfe y (x = z) x1 x2, absorb(id year) cluster(province_id) first

* ============================================
* 提醒：报告时必须给出——第一阶段方程与 F 统计量、
* 2SLS 系数与稳健/聚类标准误、识别不足与弱工具检验、
* 工具变量外生性的制度论证（不可由统计检验替代）；
* 异质性效应下系数解释为依从者（compliers）的 LATE。
* ============================================
