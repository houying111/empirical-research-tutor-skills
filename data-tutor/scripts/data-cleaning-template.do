* ============================================
* 数据准备与清洗 Stata 模板 (v1.0)
* 原则：原始数据只读；每一步留痕；记录 N 变化
* 可选安装：ssc install winsor2, replace
* ============================================

clear all
set more off

* ---- Step 0: 路径与日志 ----
* global raw  "D:/project/data/raw"       // 原始数据目录（只读，勿写入）
* global work "D:/project/data/work"
* log using "$work/cleaning_log.log", replace text

* ---- Step 1: 数据体检（先看，不改）----
* use "$raw/individual.dta", clear
* describe
* codebook, compact
* misstable summarize                       // 缺失模式
* duplicates report id year                // 面板唯一性
* foreach v of varlist x1 x2 x3 {
*     summarize `v', detail
* }

* ---- Step 2: 样本筛选（每步记录 N）----
* count
* keep if inrange(age, 16, 59)              // 法定工作年龄（口径需写明依据）
* count                                     // 记录删后 N
* keep if emp_status == 1                   // 受雇样本；删前先 tab emp_status
* count

* ---- Step 3: 缺失值处理 ----
* misstable summarize x y controls
* 删除仅限"关键变量缺失"，并先判断缺失机制（MCAR/MAR/MNAR）：
* foreach v of varlist y x1 x2 x3 {
*     drop if missing(`v')
* }
* count

* ---- Step 4: 异常值：先诊断，再决定 ----
* summarize income, detail
* 录入错误（如年龄=999）→ 核对原始问卷后修正或置缺
* 真实极端值 → 缩尾（记录阈值，并保留不缩尾的对照样本）：
* winsor2 income, cuts(1 99) suffix(_w)

* ---- Step 5: 变量构造 ----
* gen age2 = age^2
* gen digital_index = (device + cognition + skill) / 3   // 口径须参考问卷/文献
* label var digital_index "数字化水平（三维等权，教学模拟口径）"

* ---- Step 6: 多表合并（查 _merge 三类分布）----
* merge m:1 province year using "$raw/province_panel.dta"
* tab _merge
* list id province year if _merge == 1 in 1/20   // 未匹配样本先查明原因
* * 确认无误后才 keep _merge == 3；禁止不查就 drop

* ---- Step 7: 终检与归档 ----
* isid id year                              // 再次确认唯一性
* compress
* save "$work/analysis_sample.dta", replace
* log close

* 交付物：analysis_sample.dta + cleaning_log.log + 更新后的数据字典
* 任何数字若来自模拟数据，图表与正文必须标注"模拟数据"
