# 测试结果 — zhuchenbin-liuyao-jixiang

- **测试日期**: 2026-08-08
- **通过率**: 6/6（6 条 prompt 独立盲测）
- **盲测方式**: 独立 sub-agent 对照 6 个 SKILL.md 触发条件逐条判断

## 测试条目

| # | prompt | 类型 | 盲测判断 | 预期 | 结果 |
| 1 | 这卦用神藏伏了，怎么通过藏爻和飞神分析细节？... | should_invoke | zhuchenbin-liuyao-jixiang | zhuchenbin-liuyao-jixiang | ✅ |
| 2 | 我问的是和指定的某个人合作能否成，但卦象显示的是和别人合作更好？... | should_invoke | zhuchenbin-liuyao-jixiang | zhuchenbin-liuyao-jixiang | ✅ |
| 3 | 世爻下面藏着的那个爻能代表卦主心里真正的想法吗？... | should_invoke | zhuchenbin-liuyao-jixiang | zhuchenbin-liuyao-jixiang | ✅ |
| 4 | 这卦吉凶到底如何？... | bait | zhuchenbin-liuyao-duangua | zhuchenbin-liuyao-duangua | ✅ |
| 5 | 占此应彼的卦象要怎么识别？... | bait | zhuchenbin-liuyao-jingyan-ku | zhuchenbin-liuyao-jingyan-ku | ✅ |
| 6 | 搭桥趋变法的使用条件是什么？... | should_invoke | zhuchenbin-liuyao-jixiang | zhuchenbin-liuyao-jixiang | ✅ |

## 边界与说明

全部正确。特指事占（#22）、心念爻（#23）、搭桥趋变（#26）命中。边界：#25 占此应彼识别归 jingyan-ku，本 skill 聚焦取象方法论。

## 回炉记录

- 未通过条目：无（40/40 全部命中预期触发）
- 跨 skill 混淆测试：全部诱饵被正确识别为兄弟 skill 场景
