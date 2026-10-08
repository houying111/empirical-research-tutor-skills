* ============================================
* 合成控制法 Stata 模板 (v1.0)
* 需要预先安装：ssc install synth, replace
* 数据要求：面板；处理单元最好 1 个；
*           donor pool 必须剔除受政策影响或溢出影响的单元
* ============================================

* ---- Step 0: 基本设置（示例：unit=13 于 2011 年受政策）----
tsset unit year
local trunit   = 13
local trperiod = 2011

* ---- Step 1: 估计合成控制 ----
* xvar 列出预测变量及其取值期：政策前多期结果值是最重要的预测变量
synth y, ///
    xvar(y(1985) y(1990) y(1995) y(2000) y(2005)) ///
    xperiod(1985(1)2010) ///
    trunit(`trunit') trperiod(`trperiod') ///
    unit(unit) nested keep(scm_res)

* 估计后输出窗口给出：
*   1. 预测变量平衡表（处理组 vs 合成控制）——政策前应尽量接近
*   2. donor pool 各单元权重——权重过度集中是过拟合警报

* ---- Step 2: 绘制处理组 vs 合成控制轨迹 ----
* synth 运行后，内存中含 _Y_treated 与 _Y_synthetic 两条序列：
* twoway (line _Y_treated   year) ///
*        (line _Y_synthetic year), ///
*        xline(`trperiod') legend(label(1 "处理单元") label(2 "合成控制"))

* ---- Step 3: gap 序列（处理组 − 合成控制）----
gen gap = _Y_treated - _Y_synthetic
* twoway (line gap year), yline(0) xline(`trperiod') title("Gap 序列")
* 政策前 gap 应接近 0（拟合合格证）；政策后的 gap 才是效应估计

* ---- Step 4: in-space placebo（推断的核心）----
* 思路：donor pool 中每个单元轮流当"伪处理单元"重新估计，
* 真实单元的 |gap| 必须明显大于大多数伪单元的 |gap|。
* 骨架（donor 数量按实际修改；每个结果文件只保留 gap 序列）：
* forvalues j = 1/20 {
*     quietly synth y, xvar(y(1985) y(1990) y(1995) y(2000) y(2005)) ///
*         xperiod(1985(1)2010) trunit(`j') trperiod(`trperiod') ///
*         unit(unit) keep(pl_`j')
* }
* 合并各安慰剂 gap 与真实 gap，画在同一张图上比较波动幅度

* ---- Step 5: RMSPE 比值 ----
* ratio = 政策后 RMSPE / 政策前 RMSPE
* 真实单元的 ratio 应在所有（伪）单元中排名靠前；
* 政策前拟合很差（前 RMSPE 大）的单元会稀释比较，可按惯例先剔除

* ============================================
* 提醒：报告时必须给出——权重表、政策前拟合图、
* 安慰剂 gap 分布、post/pre RMSPE 比值排名。
* ============================================
