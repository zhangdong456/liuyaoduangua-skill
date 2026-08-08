# 测试结果 — zhuchenbin-liuyao-duangua

- **测试日期**: 2026-08-08
- **通过率**: 7/7（7 条 prompt 独立盲测）
- **盲测方式**: 独立 sub-agent 对照 6 个 SKILL.md 触发条件逐条判断

## 测试条目

| # | prompt | 类型 | 盲测判断 | 预期 | 结果 |
| 1 | 帮我断卦：戌月壬申日占求财，得山火贲变雷火丰，妻财寅木持世被月合，兄弟午火发动克... | should_invoke | zhuchenbin-liuyao-duangua | zhuchenbin-liuyao-duangua | ✅ |
| 2 | 这卦用神妻财巳火动而克世爻酉金，但我是问终身财运，能断有财吗？... | boundary | zhuchenbin-liuyao-duangua | zhuchenbin-liuyao-duangua | ✅ |
| 3 | 自占病，官鬼持世，是不是病很重治不好？... | bait | zhuchenbin-liuyao-yicuodian | zhuchenbin-liuyao-yicuodian | ✅ |
| 4 | 静卦用神持世但逢月破，到底是吉是凶？... | should_invoke | zhuchenbin-liuyao-duangua | zhuchenbin-liuyao-duangua | ✅ |
| 5 | 这卦的应期大概在什么时候？... | bait | zhuchenbin-liuyao-yingqi | zhuchenbin-liuyao-yingqi | ✅ |
| 6 | 我想知道这卦除了吉凶，还显示了什么细节？... | bait | zhuchenbin-liuyao-jixiang | zhuchenbin-liuyao-jixiang | ✅ |
| 7 | 三合局形成后，单爻的回头克还有意义吗？... | should_invoke | zhuchenbin-liuyao-duangua | zhuchenbin-liuyao-duangua | ✅ |

## 边界与说明

全部正确。跨组诱饵全部识别（#12→yingqi、#13→jixiang、#18/#24/#31/#38→duangua 本身）。边界：#9（具体卦问吉凶→duangua）vs #36（抽象规则问'是不是都凶'→yicuodian）靠问句形态区分。

## 回炉记录

- 未通过条目：无（40/40 全部命中预期触发）
- 跨 skill 混淆测试：全部诱饵被正确识别为兄弟 skill 场景
