# 测试结果 — zhuchenbin-liuyao-jingyan-ku

- **测试日期**: 2026-08-08
- **通过率**: 7/7（7 条 prompt 独立盲测）
- **盲测方式**: 独立 sub-agent 对照 6 个 SKILL.md 触发条件逐条判断

## 测试条目

| # | prompt | 类型 | 盲测判断 | 预期 | 结果 |
| 1 | 我明明问的是小厮的病，卦象却显示我秋天功名有碍，这正常吗？... | should_invoke | zhuchenbin-liuyao-jingyan-ku | zhuchenbin-liuyao-jingyan-ku | ✅ |
| 2 | 起卦时我不小心把卦排错了，这卦还能断吗？... | should_invoke | zhuchenbin-liuyao-jingyan-ku | zhuchenbin-liuyao-jingyan-ku | ✅ |
| 3 | 我上次测女篮比赛没测准，是不是我技术不行？... | should_invoke | zhuchenbin-liuyao-jingyan-ku | zhuchenbin-liuyao-jingyan-ku | ✅ |
| 4 | 用周易炒期货有什么特别注意的？... | should_invoke | zhuchenbin-liuyao-jingyan-ku | zhuchenbin-liuyao-jingyan-ku | ✅ |
| 5 | 这卦用神旺相，能断吉吗？... | bait | zhuchenbin-liuyao-duangua | zhuchenbin-liuyao-duangua | ✅ |
| 6 | 为什么我的卦总是显示别的事情而不是我问的？... | should_invoke | zhuchenbin-liuyao-jingyan-ku | zhuchenbin-liuyao-jingyan-ku | ✅ |
| 7 | 遇到占此应彼，所问之事还要不要照断？... | boundary | zhuchenbin-liuyao-jingyan-ku | zhuchenbin-liuyao-jingyan-ku | ✅ |

## 边界与说明

全部正确。占此应彼（#27/#32/#33）、错卦正显（#28）、测不准（#29）、金融（#30）全部命中。边界：#29（测不准）vs #35（思路哪里错了→yicuodian）镜像对，靠'特殊卦种场景' vs '自查误区'区分。

## 回炉记录

- 未通过条目：无（40/40 全部命中预期触发）
- 跨 skill 混淆测试：全部诱饵被正确识别为兄弟 skill 场景
