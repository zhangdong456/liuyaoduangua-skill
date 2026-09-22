# 个人规则注册表

个人规则不能直接覆盖 `references/` 的朱辰彬原规则。每条经验先进入 `candidate`，经过多个独立案例和反例检查后，才可以变成 `active`。

## 字段

- `rule_id`：例如 `P-R-001`
- `statement`：可执行的规则
- `scope`：适用问事类型、卦种和时间范围
- `trigger`：触发条件
- `exceptions`：不适用条件
- `priority`：与其他规则冲突时的优先级
- `source_refs`：原始资料或规则文件
- `supporting_cases`：支持案例 ID
- `counter_cases`：反例 ID
- `confidence`：当前置信度
- `status`：candidate / active / retired
- `introduced_at`：首次提出规则的时间，不得为了通过门槛向前改写
- 支持案例至少来自 3 个不同 `event_id`；至少 1 个事件在提出规则后预登记 `prediction.shadow_rules`，候选影子判断记录于 `prediction.shadow_predictions`，不能改变正式预测
- 每个已复盘案例须记录 `review.checked_rules`（包括判定不适用）、`supported_rules`、`counter_rules` 和 `rule_checks`（适用性、理由）。存在反例或未检查案例时不升级
- 升级前运行 `test-rule-evidence.ps1`；它只给资格结果，不自动改状态。新反馈构成反例时 active 立即退为 candidate 或 retired，缩小范围须新建规则版本并重新验证

## 注册原则

先记录“机制”，再记录“事件”。例如“求对方答应之事优先看应爻动态”可以成为规则；“某公司这次没有录用”只能先成为案例。
