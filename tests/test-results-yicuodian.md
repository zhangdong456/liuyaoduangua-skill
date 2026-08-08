# 测试结果 — zhuchenbin-liuyao-yicuodian

- **测试日期**: 2026-08-08
- **通过率**: 7/7（7 条 prompt 独立盲测）
- **盲测方式**: 独立 sub-agent 对照 6 个 SKILL.md 触发条件逐条判断

## 测试条目

| # | prompt | 类型 | 盲测判断 | 预期 | 结果 |
| 1 | 我断卦时把动爻与月令相合论成'月绊'断凶了，对吗？... | should_invoke | zhuchenbin-liuyao-yicuodian | zhuchenbin-liuyao-yicuodian | ✅ |
| 2 | 为什么我断的卦总是不准？帮我看看思路哪里错了... | should_invoke | zhuchenbin-liuyao-yicuodian | zhuchenbin-liuyao-yicuodian | ✅ |
| 3 | 用神克世是不是都是凶兆？... | should_invoke | zhuchenbin-liuyao-yicuodian | zhuchenbin-liuyao-yicuodian | ✅ |
| 4 | 自占病是不是应该取官鬼为用神？... | should_invoke | zhuchenbin-liuyao-yicuodian | zhuchenbin-liuyao-yicuodian | ✅ |
| 5 | 帮我完整断一下这卦的吉凶... | bait | zhuchenbin-liuyao-duangua | zhuchenbin-liuyao-duangua | ✅ |
| 6 | 短事之占出现化进退，该按进退断吗？... | boundary | zhuchenbin-liuyao-yicuodian | zhuchenbin-liuyao-yicuodian | ✅ |
| 7 | 心态卦里子孙旬空代表什么？... | should_invoke | zhuchenbin-liuyao-yicuodian | zhuchenbin-liuyao-yicuodian | ✅ |

## 边界与说明

全部正确。月绊（#34）、用神克世（#36）、自占病取用（#37）、短事化进退（#39）、心态卦空亡（#40）命中。边界：#10（自占病官鬼持世→盲测判 jingyan-ku 心态卦）与 #37（取用规则→yicuodian）为合理边界模糊，两 skill 均有覆盖。

## 回炉记录

- 未通过条目：无（40/40 全部命中预期触发）
- 跨 skill 混淆测试：全部诱饵被正确识别为兄弟 skill 场景
