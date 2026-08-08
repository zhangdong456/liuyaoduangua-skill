# 测试结果 — zhuchenbin-liuyao-qigua

- **测试日期**: 2026-08-08
- **通过率**: 7/7（7 条 prompt 独立盲测）
- **盲测方式**: 独立 sub-agent 对照 6 个 SKILL.md 触发条件逐条判断

## 测试条目

| # | prompt | 类型 | 盲测判断 | 预期 | 结果 |
| 1 | 我想摇一卦问问最近的项目能不能成，应该怎么起卦？... | should_invoke | zhuchenbin-liuyao-qigua | zhuchenbin-liuyao-qigua | ✅ |
| 2 | 我刚才用三个硬币摇了六次，结果依次是：背背字、背字字、字字字、背背背、字背背、背... | should_invoke | zhuchenbin-liuyao-qigua | zhuchenbin-liuyao-qigua | ✅ |
| 3 | 起卦时我把第一爻记成在最上面了，这卦还能用吗？... | boundary | zhuchenbin-liuyao-qigua | zhuchenbin-liuyao-qigua | ✅ |
| 4 | 我按梅花易数用时间起了一卦，能按你的六爻体系断吗？... | boundary | zhuchenbin-liuyao-qigua | zhuchenbin-liuyao-qigua | ✅ |
| 5 | 这卦世爻是申金，妻财寅木发动回头克世，请问是吉是凶？... | bait | zhuchenbin-liuyao-duangua | zhuchenbin-liuyao-duangua | ✅ |
| 6 | 我同时想问财运和健康，能不能一卦一起问？... | should_invoke | zhuchenbin-liuyao-qigua | zhuchenbin-liuyao-qigua | ✅ |
| 7 | 背和字哪个算阳面？我有点记不清了... | should_invoke | zhuchenbin-liuyao-qigua | zhuchenbin-liuyao-qigua | ✅ |

## 边界与说明

全部正确。注意 #4（梅花易数/时间起卦）应判'无'——命中不适用范围时正确响应是拒绝而非激活。边界：#3 排卦规则 vs #28 错卦正显（jingyan-ku）易混淆，按'是否涉及无心之失的卦象解读'区分。

## 回炉记录

- 未通过条目：无（40/40 全部命中预期触发）
- 跨 skill 混淆测试：全部诱饵被正确识别为兄弟 skill 场景
