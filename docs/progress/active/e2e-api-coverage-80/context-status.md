# E2E API Coverage 80% Context 状态

## 全局目标

- 后端覆盖率口径：`ModernWMS.Core + ModernWMS.WMS` 合并 line coverage。
- 最终门槛：全局合并 line coverage >= 80%。
- 每个业务 context 使用自收敛 loop，不允许单轮未达标后直接跳到下一个 context。
- 每个 context 的 mutation-style 抽样必须在该 context Gate 内完成。

## Context Gate Loop

```text
Context 当前 coverage
        ↓
分析未覆盖文件 / 方法 / 分支
        ↓
分类：API E2E / 单元测试 / 配置限定 / 死代码 / 阻塞
        ↓
设计下一批业务场景
        ↓
编写测试
        ↓
运行目标测试 + coverage
        ↓
mutation-style 抽样
        ↓
覆盖率不足或 survivor → 回到分析
达标且 mutation 通过 → Gate 完成
```

## 当前状态表

| 顺序建议 | Context | Baseline | 状态 | 下一步 |
| ---: | --- | ---: | --- | --- |
| 1 | 基础主数据 | 7.00% → 84.27% | 完成 | 见 `master-data-summary.md`；mutation 2/2 killed |
| 2 | 系统管理 | 14.46% → 83.33% | 完成 | 见 `system-management-summary.md`；mutation 2/2 killed；FlowSet/HelloWorld 有证据化例外 |
| 3 | 入库执行 | 37.70% → 90.16% | 完成 | 见 `inbound-execution-summary.md`；mutation 2/2 killed；AnsSummary/AsnFlowInput 为证据化例外 |
| 4 | 库存可视化 | 51.35% → 100.00% | 完成 | 见 `inventory-visibility-summary.md`；mutation 2/2 killed；安全库存仓库聚合 bug 已修复 |
| 5 | 库内作业 | 15.04% → 100.00% | 完成 | 见 `internal-operations-summary.md`；mutation 2/2 killed |
| 6 | 出库履约 | 23.36% → 100.00% | 完成 | 见 `outbound-fulfillment-summary.md`；mutation 3/3 killed；签收明细匹配 bug 已修复 |
| 7 | Core/shared closure | 49.76% → 93.67% | 完成 | 见 `core-shared-closure-summary.md`；mutation 3/3 killed；剩余 raw ADO / startup host guard / token defensive fallback 已证据化例外 |

## Gate 完成条件

每个 context 必须同时满足：

1. context 有效 line coverage >= 80%；或剩余未覆盖代码均有证据化例外说明。
2. 未覆盖代码已经尝试通过 API E2E 或单元测试覆盖，不能直接记录后跳过。
3. mutation-style 抽样完成，理论上改变行为的 mutation 被测试杀死。
4. 目标测试通过，且全局后端测试无新增失败。
5. 输出该 context 的 summary/status，说明：loop 次数、覆盖率变化、新增场景、单元测试、例外、mutation 结果。

## 子任务执行约束

- 优先 API E2E，使用现有 Reqnroll DSL 风格。
- 不写纯覆盖率用例，测试必须体现业务场景。
- 接口触及但分支复杂、需要大量 API case 时，用单元测试补分支。
- 发现 API 无法触达、配置限定或死代码时，必须在 `exceptions.md` 或 context summary 中说明证据。
- 生产代码只在 failing test 暴露真实 bug 或确认删除死代码时最小修改。

## 执行记录

### Gate 0: Baseline

- 状态：完成
- 覆盖率：35.76%（664 / 1857）
- 详情：`docs/progress/active/e2e-api-coverage-80/coverage-baseline.md`
- 验证日志：`/tmp/modernwms-cov-baseline-run.log`

### Gate 1: 基础主数据

- 状态：完成
- 覆盖率：7.00% → 84.27%（241 / 286）
- 全局覆盖率：35.76% → 47.87%（889 / 1857）
- Mutation：2/2 killed
- 详情：`docs/progress/active/e2e-api-coverage-80/master-data-summary.md`
- 验证日志：
  - `/tmp/modernwms-masterdata-green2.log`
  - `/tmp/modernwms-spu-unit.log`
  - `/tmp/modernwms-masterdata-cov3.log`
  - `/tmp/modernwms-masterdata-mut1.log`
  - `/tmp/modernwms-masterdata-mut2.log`

### Gate 2: 系统管理

- 状态：完成
- 覆盖率：14.46% → 83.33%（145 / 174）
- 全局覆盖率：47.87% → 54.28%（1008 / 1857）
- Mutation：2/2 killed
- 详情：`docs/progress/active/e2e-api-coverage-80/system-management-summary.md`
- 验证日志：
  - `/tmp/pi-modernwms-system-management-target-final.log`
  - `/tmp/pi-modernwms-system-management-full-final.log`
  - `/tmp/pi-modernwms-system-management-mut1.log`
  - `/tmp/pi-modernwms-system-management-mut2.log`

### Gate 3: 入库执行

- 状态：完成
- 覆盖率：37.70% → 90.16%（55 / 61）
- 全局覆盖率：54.28% → 58.05%（1078 / 1857）
- Mutation：2/2 killed
- 详情：`docs/progress/active/e2e-api-coverage-80/inbound-execution-summary.md`
- 验证日志：
  - `/tmp/pi-modernwms-inbound-execution-target-final.log`
  - `/tmp/pi-modernwms-inbound-execution-unit-final.log`
  - `/tmp/pi-modernwms-inbound-execution-full-final.log`
  - `/tmp/pi-modernwms-inbound-execution-mut1.log`
  - `/tmp/pi-modernwms-inbound-execution-mut2.log`

### Gate 4: 库存可视化

- 状态：完成
- 覆盖率：51.35% → 100.00%（37 / 37）
- 全局覆盖率：58.05% → 58.91%（1094 / 1857）
- Mutation：2/2 killed
- 详情：`docs/progress/active/e2e-api-coverage-80/inventory-visibility-summary.md`
- 验证日志：
  - `/tmp/pi-modernwms-inventory-visibility-unit-postmut.log`
  - `/tmp/pi-modernwms-inventory-visibility-e2e-postmut.log`
  - `/tmp/pi-modernwms-inventory-visibility-full-postmut.log`
  - `/tmp/pi-modernwms-inventory-visibility-mut1.log`
  - `/tmp/pi-modernwms-inventory-visibility-mut2.log`

### Gate 5: 库内作业

- 状态：完成
- 覆盖率：15.04% → 100.00%（133 / 133）
- 全局覆盖率：58.91% → 65.11%（1209 / 1857）
- Mutation：2/2 killed
- 详情：`docs/progress/active/e2e-api-coverage-80/internal-operations-summary.md`
- 验证日志：
  - `/tmp/pi-modernwms-internal-operations-unit-final.log`
  - `/tmp/pi-modernwms-internal-operations-e2e-final.log`
  - `/tmp/pi-modernwms-internal-operations-full-final.log`
  - `/tmp/pi-modernwms-internal-operations-mut1.log`
  - `/tmp/pi-modernwms-internal-operations-mut2.log`

### Gate 6: 出库履约

- 状态：完成
- 覆盖率：23.36% → 100.00%（107 / 107）
- 全局覆盖率：65.11% → 69.95%（1299 / 1857）
- Mutation：3/3 killed
- 详情：`docs/progress/active/e2e-api-coverage-80/outbound-fulfillment-summary.md`
- 验证日志：
  - `/tmp/pi-modernwms-outbound-fulfillment-unit-final.log`
  - `/tmp/pi-modernwms-outbound-fulfillment-e2e-final.log`
  - `/tmp/pi-modernwms-outbound-fulfillment-full-final.log`
  - `/tmp/pi-modernwms-outbound-fulfillment-mut1.log`
  - `/tmp/pi-modernwms-outbound-fulfillment-mut2.log`
  - `/tmp/pi-modernwms-outbound-fulfillment-mut3.log`

### Gate 7: Core/shared closure

- 状态：完成
- 覆盖率：54.75% → 93.67%（582 / 1063 → 1007 / 1075）
- 全局覆盖率：69.95% → 92.24%（1299 / 1857 → 1724 / 1869）
- Mutation：3/3 killed
- 详情：`docs/progress/active/e2e-api-coverage-80/core-shared-closure-summary.md`
- 验证日志：
  - `/tmp/pi-modernwms-core-shared-loop2c-green.log`
  - `/tmp/pi-modernwms-core-shared-full-final3.log`
  - `/tmp/pi-modernwms-core-shared-mut1.log`
  - `/tmp/pi-modernwms-core-shared-mut2.log`
  - `/tmp/pi-modernwms-core-shared-mut3.log`
