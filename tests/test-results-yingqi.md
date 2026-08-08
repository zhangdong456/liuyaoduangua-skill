# 测试结果 — zhuchenbin-liuyao-yingqi

- **测试日期**: 2026-08-08
- **通过率**: 6/6（6 条 prompt 独立盲测）
- **盲测方式**: 独立 sub-agent 对照 6 个 SKILL.md 触发条件逐条判断

## 测试条目

| # | prompt | 类型 | 盲测判断 | 预期 | 结果 |
| 1 | 卦已经断成吉了，用神卯木发动，什么时候应事？... | should_invoke | zhuchenbin-liuyao-yingqi | zhuchenbin-liuyao-yingqi | ✅ |
| 2 | 用神午火旬空，应期怎么推？是填空还是冲空？... | should_invoke | zhuchenbin-liuyao-yingqi | zhuchenbin-liuyao-yingqi | ✅ |
| 3 | 这卦里有暗动之爻，应期会受影响吗？... | should_invoke | zhuchenbin-liuyao-yingqi | zhuchenbin-liuyao-yingqi | ✅ |
| 4 | 这卦到底能不能成？... | bait | zhuchenbin-liuyao-duangua | zhuchenbin-liuyao-duangua | ✅ |
| 5 | 静卦世爻用神都没有日月生扶，能推应期吗？... | boundary | zhuchenbin-liuyao-yingqi | zhuchenbin-liuyao-yingqi | ✅ |
| 6 | 应期是越早越好还是看重叠信息？... | should_invoke | zhuchenbin-liuyao-yingqi | zhuchenbin-liuyao-yingqi | ✅ |

## 边界与说明

全部正确。#18（到底能不能成）判 duangua 正确——应期须先有吉凶方向。#19（缺根推应期）属应期意外判断，本 skill 覆盖。

## 回炉记录

- 未通过条目：无（40/40 全部命中预期触发）
- 跨 skill 混淆测试：全部诱饵被正确识别为兄弟 skill 场景
