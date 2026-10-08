* ============================================
* 断点回归 Stata 模板 (v1.0)
* 需要预先安装：ssc install rdrobust rddensity, replace
* 约定：x = 驱动变量（已中心化，门槛 c = 0）
*       y = 结果变量；treat = 是否受处理（fuzzy 时使用）
* ============================================

* ---- Step 0: RD 图（先看散点在门槛处的整体跳变）----
rdplot y x, c(0) p(1) binselect(esmv)
* esmv 最优分箱；p(1) 局部线性

* ---- Step 1: 操纵检验（驱动变量密度在门槛处是否连续）----
rddensity x, c(0)
* 注意：驱动变量为取值稀少的离散变量时，密度检验不可靠，
* 必须结合生成机制讨论（分数可否重考、认定材料是否可控）

* ---- Step 2: 协变量平衡（前定特征在门槛处不应跳变）----
* 对每个协变量逐一执行：
rdrobust cov1 x, c(0)
rdrobust cov2 x, c(0)

* ---- Step 3: 基准估计（稳健偏差修正置信区间）----
rdrobust y x, c(0) p(1) kernel(triangular)
* 表格需同时报告 Conventional / Bias-Corrected / Robust 三行与 h、b 两个带宽

* ---- Step 4: 带宽与设定敏感性 ----
rdrobust y x, c(0) p(1) h(20)
rdrobust y x, c(0) p(1) h(40)
rdrobust y x, c(0) p(2)
* 结论不应依赖单一带宽或单一阶数

* ---- Step 5: fuzzy RDD（过线只提高受处理概率时）----
rdrobust y x, c(0) fuzzy(treat)
* 解读类似 IV：门槛附近"依从者"（compliers）的局部平均处理效应

* ============================================
* 提醒：报告时必须给出——RD 图、操纵检验、协变量平衡、
* 多带宽敏感性，并把结论表述为"门槛附近的局部效应（RLATE）"。
* ============================================
