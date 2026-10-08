* ============================================
* DID 分析 Stata 模板 (v1.1)
* 使用前请确认：
*   1. 已 xtset id year 声明面板
*   2. treat（处理组）、post（政策后）变量已定义
*   3. 聚类层级 = 政策分配发生的层级（通常省份或城市）
* ============================================

* ---- Step 0: 数据准备检查 ----
xtset id year
xtdescribe
* 经典 DID 要求处理组身份不随时间变化：
bysort id: egen treat_max = max(treat)
* assert treat_max == treat   // 自检用，取消注释运行

* ---- Step 1: 基准回归 ----
* treat##post 等价于手动生成交互项 treat_post
reghdfe y treat##post, absorb(id year) cluster(province_id)
* 常见错误：聚类层级过高或过低都会影响标准误
* 政策在省级分配 → cluster(province_id)；市级分配 → cluster(city_id)

* ---- Step 2: 平行趋势检验（事件研究法）----
gen rel_time = year - policy_year
* 尾部归并：政策前后期数太多会使各期系数不稳定（示例保留 [-4, 5]）
gen evt = rel_time
replace evt = -4 if rel_time <= -4
replace evt = 5  if rel_time >=  5
* 关键点：以政策前一期（-1）为基准组（omitted），看其余各期系数
reghdfe y ib(-1).evt##i.treat, absorb(id year) cluster(province_id)
* 动态效应图（需 ssc install coefplot）：
* coefplot, keep(1.treat#*.evt) vertical yline(0) ciopts(recast(rcap))

* ---- Step 3: 安慰剂检验（完整可运行版：随机处理组 × 500 次）----
* 思路：随机抽取与真实处理组同等规模的"伪处理组"，重新回归并保存系数，
* 观察真实系数是否落在安慰剂分布的尾部。

* 3.1 先取出真实系数，画图时作参考线
reghdfe y treat##post, absorb(id year) cluster(province_id)
scalar true_b = _b[1.treat#1.post]

* 3.2 安慰剂循环（N_TREAT 替换为真实处理组个体数）
tempfile master
save `master'
tempname sim
postfile `sim' beta using "placebo_results.dta", replace
set seed 20261006
forvalues i = 1/500 {
    quietly {
        use `master', clear
        preserve
        keep id
        duplicates drop
        gen double u = runiform()
        sort u
        gen pseudo = (_n <= 30)          // ← 30 改为真实处理组个体数
        keep id pseudo
        tempfile pm
        save `pm'
        restore
        merge m:1 id using `pm', nogen
        gen pseudo_post = pseudo * post
        capture reghdfe y pseudo_post, absorb(id year) cluster(province_id)
        if _rc == 0 post `sim' (_b[pseudo_post])
    }
}
postclose `sim'

* 3.3 查看安慰剂分布
use "placebo_results.dta", clear
kdensity beta, xline(`=true_b') ///
    title("安慰剂系数分布与真实系数") note("随机分配伪处理组500次")

* ---- Step 4: 交错 DID（政策分批实施时改用，见 did-primer）----
* 4.1 Callaway & Sant'Anna（需 ssc install csdid drdid）
*     gvar = 各个体首次接受处理的年份，从未处理组设为 0
* gen gvar = ...
* csdid y, ivar(id) time(year) gvar(gvar) method(drimp) notyet
* estat event      // 动态（事件研究）效应
* estat simple     // 加总平均效应
* 4.2 备选：de Chaisemartin & D'Haultfœuille（需 ssc install did_multiplegt）
* did_multiplegt y id year treat_var

* ============================================
* 提醒：报告时必须给出——基准系数与聚类标准误（注明层级）、
* 事件研究图（政策前系数不显著）、安慰剂检验结果。
* ============================================
