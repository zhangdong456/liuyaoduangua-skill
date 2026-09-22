# 案例记录模板

## 预测前记录

- `case_id`：
- `event_id`：同一现实事件的追问、重摇和重复反馈共享一个 ID
- `source_type`：personal / book / imported
- `source_ref`：
- `asked_at`：
- `question`：
- `horizon`：
- `context`：人物、背景、真实所念、已知限制
- `chart`：日月干支、旬空、本卦、变卦、世应、六亲、六神、动爻、变爻
- `prediction.yongshen`：
- `prediction.verdict`：
- `prediction.timing`：
- `prediction.confidence`：0 到 1
- `prediction.evidence_rules`：例如 R-002、R-007
- `prediction.shadow_rules`：预登记的候选规则 ID，仅影子验证
- `prediction.shadow_predictions`：对象数组，每项含 rule_id、verdict、依据；独立于正式断语
- `rule_version`：当前 skill 的 Git commit 或版本号

## 反馈后记录

- `outcome.status`：correct / partial / wrong / unverifiable
- `outcome.occurred_at`：
- `outcome.description`：只写实际发生的结果
- `review.correct_parts`：
- `review.wrong_parts`：
- `review.error_tags`：yongshen / verdict / timing / detail / tracking / missing-rule
- `review.new_rule_candidate`：跨案例可复用的规则；单一事件不要直接升级
- `review.checked_rules` / `supported_rules` / `counter_rules`：已检查、支持和反例规则 ID
- `review.rule_checks`：每条规则的适用性及支持/反例判断理由
- `review.corrections`：录入纠正的旧值、新值、原因与时间；原预测不覆盖
