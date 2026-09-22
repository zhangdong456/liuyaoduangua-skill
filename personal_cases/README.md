# 个人案例库

这里保存个人六爻案例，不修改 `references/` 中的朱辰彬规则。

## 三类文件

- `cases.jsonl`：每行一个完整案例。预测前只能读取问题、卦面和 `prediction`；反馈后才补充 `outcome`、`review`。
- `../rag/index.jsonl`：由 `rag/build-index.ps1` 自动生成的检索索引，包含摘要、主题、关键词、规则 ID 和历史验证标签；本目录旧 index.jsonl 不作为检索入口。
- `active-case.json`：最近一次自动写入的案例指针，供 agent 在用户追加反馈时定位案例。
- `raw/`、`reviews/`：如需保存较长的原始记录和复盘，可放在这里；日常解卦不自动加载。

## 状态

- `pending`：尚未得到现实反馈。
- `reviewed`：已完成一次反馈复盘。
- `promoted`：复盘经验已升级为个人规则。
- `rejected`：反馈不足、信息污染或存在明显反例，不进入个人规则。

案例必须保留 `rule_version`，这样规则改变后可以回看当时使用的版本。
首次记录后预测字段冻结；反馈更新只改 outcome/review/status。纠错追加 review.corrections，不覆盖预测。同一现实事件共享 event_id。

正常使用时用户不需要手工整理文件。agent 应在每次完成预测后自动调用 `upsert-case.ps1` 保存 `pending` 案例；用户反馈后自动更新同一 `case_id`。`upsert-case.ps1` 会同时更新 `active-case.json` 和 RAG 索引。

如果需要手工重建索引，运行：

```powershell
.\rag\build-index.ps1
```

也可以使用 `upsert-case.ps1` 按 `case_id` 新增或更新案例：

```powershell
.\personal_cases\upsert-case.ps1 -CaseJsonPath .\work\P-2026-0001.json
```
