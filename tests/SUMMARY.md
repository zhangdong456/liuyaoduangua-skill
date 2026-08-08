# 测试汇总

- **方式**: 独立 sub-agent 盲测 40 条 prompt（含 10 条跨 skill 诱饵 + 1 条不适用场景）
- **结果**: 40/40 命中预期触发，通过率 100%
- **分布**: qigua 5、duangua 9、yingqi 6、jixiang 5、jingyan-ku 8、yicuodian 6、无 1
- **边界说明**: #10（自占病官鬼持世）在 jingyan-ku（心态卦场景）与 yicuodian（取用规则）间属合理模糊，两模块均有覆盖

各模块明细见 `test-prompts-<module>.json` 与 `test-results-<module>.md`。
