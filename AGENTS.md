# AGENTS.md — 给 AI 助手的仓库说明

## 这是什么

朱辰彬古筮六爻解卦技能包（蒸馏自朱辰彬 8 部著作，约 130 万字语料）。当用户提供六爻卦象（摇钱卦）要求解卦、断吉凶、看感情/婚姻/财运/事业/疾病等走势时使用。

## 仓库结构

```
├── SKILL.md          # 聚合主 skill（总纲：七步断卦法 + 模块路由）★核心
├── README.md         # 人类阅读的说明文档
├── AGENTS.md         # 本文件（AI 阅读）
├── install.sh        # Linux/macOS 一键安装
├── install.ps1       # Windows 一键安装
├── references/       # 基础规则层（只读，不直接写入个人反馈）
├── personal_cases/   # 个人案例、反馈和低 token 索引
├── personal_rules/   # 经过复盘后形成的个人规则候选
├── rag/              # 本地检索索引构建和查询
├── fine_tuning/      # 自动门槛检查和微调数据准备
├── docs/             # 深度文档（DIGEST/GLOSSARY/INDEX 等）
├── tests/            # 测试（40 条 prompt，通过率 40/40）
├── candidates/       # 提取素材审计
└── rejected/         # 淘汰单元审计
```

## 如何安装（当用户要求安装时）

### 方式一：一键脚本（推荐）
```bash
# Linux/macOS / Git Bash
./install.sh                  # 自动探测 skills 目录
./install.sh ~/.claude/skills # 或手动指定

# Windows PowerShell
.\install.ps1                 # 自动探测
.\install.ps1 -Target "$env:USERPROFILE\.claude\skills"
```

### 方式二：手动复制
把 `SKILL.md` + `references/` 整个目录复制到目标 skills 目录（如 `~/.claude/skills/zhuchenbin-liuyao/`）。

### 常见 skills 目录
| 平台 | 路径 |
|---|---|
| Claude Code / 通用 | `~/.claude/skills/` |
| Cursor | `~/.cursor/skills/` 或项目级 `.cursor/skills/` |
| Hermes | `$HERMES_HOME/profiles/<profile>/skills/`（Windows 默认 `%LOCALAPPDATA%\hermes\profiles\liuyao\skills`） |

## 如何用（当用户发卦时）

1. 加载 `SKILL.md`（聚合总纲），按"七步断卦法"执行：
   读盘 → 定卦种 → 取用神 → 评旺衰 → 定吉凶 → 对轨 → 应期细节
2. 需要模块细节时，读 `references/` 对应文件：
   - `qigua.md` 起卦装卦 / `duangua.md` 吉凶判断（含感情婚姻专项、灾卦四公式）
   - `yingqi.md` 应期 / `jixiang.md` 细节取象 / `jingyan-ku.md` 特殊案例 / `yicuodian.md` 易错点
3. 个人案例闭环：
   - 新卦先在 `personal_cases/` 建立 `pending` 案例，记录预测时可见信息和 `rule_version`
   - 用户反馈后更新同一案例的 `outcome` / `review`，不要直接改写 `references/`
   - 日常解卦只检索 `personal_cases/index.jsonl` 的少量摘要，不加载全部历史案例
   - 只有多个独立案例支持且没有明显反例时，才将经验写入 `personal_rules/rules.jsonl`
   - 经验先入 candidate，预测检索只用 active；升级前运行 personal_rules/test-rule-evidence.ps1。至少 3 个独立 event_id 支持，至少 1 个提出规则后的影子预测验证，所有已复盘案例已检查适用性且无反例
   - 首次保存后预测字段冻结；反馈只补 outcome/review/status。历史检索摘要的验证标签必须保留；错误断语不作为正面范例
   - 每次案例更新后自动检查 `fine_tuning/policy.json`；达到门槛就生成 `fine_tuning/output/dataset.jsonl` 和报告，不需要用户手动统计案例
   - 微调训练样本只取预测时可见的信息，不能把实际结果或复盘泄漏进输入；外部 fine-tuning 提交仍需明确确认

4. 核心铁律：
   - 两层面分离（吉凶层循卦理、细节层取象），不可混用
   - 只适用于摇钱卦，不适用于梅花易数/时间/报数起卦
   - 卦象"只答心念不答口述"——先问清用户真实问题再取用神
   - 重大人生/财务决策须注明"仅供参考、勿迷信、结合现实"

## 依赖

无外部依赖（纯 Markdown skill）。安装后立即可用。

## 维护说明

- 修改规则层时：改 `references/*.md` 和 `SKILL.md`，保持 `docs/`、`tests/` 同步
- 修改个人学习层时：只更新 `personal_cases/`、`personal_rules/`，再运行 `rag/build-index.ps1`
- 修改微调准备层时：同步更新 `fine_tuning/` 和 `tests/verify-fine-tuning.ps1`
- 修改后运行 `tests/` 中的测试 prompt 验证触发
- 源工作区（提取文本、蒸馏流水线）在本地 `C:\Users\26878\liuyao_pdf_txt\` 与 `C:\Users\26878\zhuchenbin-liuyao\`，不随仓库分发
