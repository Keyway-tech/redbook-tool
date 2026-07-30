---
name: redbook-post-gen
description: 自包含小红书图文帖生成器。全部依赖 skill/模板/脚本已原样打包于本项目 skills/ 内，可独立拷贝到其他电脑运行，不引用宿主机器已安装版本。主 skill 仅负责流程编排、信息收集、信息传递与最终落盘，一切专业产出（目标澄清/角度诊断/概念拆解/标题/钩子/写稿/共鸣诊断/AI检测/出图）均由打包依赖完成。强制版本自检与环境自检；依赖失败即中止、不回退默认；依赖自带默认方案时交互式征求用户。仅编排外层流程，不干预依赖内层逻辑。
---

# 职责边界（总纲，强制）

主 skill 只做四件事：**流程编排、信息收集、信息传递、最终落盘**。禁止主 skill 亲自产出任何专业内容（写稿、标题、钩子、诊断、拆解、排版、出图一律由打包依赖完成）。

# 版本自检（首步，强制）

- 记录仓库：`https://github.com/Keyway-tech/redbook-post-gen.git`
- `<SKILL_REPO_DIR>` = 本 SKILL.md 所在目录（运行时解析，禁止硬编码绝对路径）
- 更新命令：`git -C <SKILL_REPO_DIR> pull --ff-only`
- Git 不可用或无远端时：用 WebFetch 拉取 `https://raw.githubusercontent.com/Keyway-tech/redbook-post-gen/main/SKILL.md` 与本地逐行比对；不一致即过期
- 自检同时校验打包完整性：确认 `skills/` 下九个依赖目录及其 SKILL.md 均存在（dbs-goal、dbs-content、dbs-deconstruct、dbs-xhs-title、dbs-hook、xhs-copywriter、dbs-resonate、dbs-ai-check、guizang-social-card-skill）；任一缺失即依赖损坏，中止
- 更新失败 / 本地有未提交改动 / 无法连接远程 / 打包不完整 → 立即中止，报告原因。**禁止用过期或残缺版本继续**
- 远程存在更新 → 合并到最新后再继续（更新会同步刷新 skills/ 内打包的依赖）
- **两级更新检测（强制，优先执行）**：若存在 `<SKILL_REPO_DIR>/.local/check_updates.py`，用受管 Python 运行之（`python .local/check_updates.py`），替代上述手工比对：
  - 第一级：检测本 skill 自身是否有更新（git fetch 比对，git 不可用时自动回退 GitHub API 比对）。
  - 第二级：逐个检测 `.local/deps.json` 中各依赖 skill 的上游是否有更新（dbs 系列 → `dontbesilent2025/dbskill` 对应子路径；guizang → `op7418/guizang-social-card-skill`；xhs-copywriter → 本仓库子路径）。
  - 退出码 0 → 继续执行；退出码 10 → 向用户**明确提示**哪些模块有更新并停下等待确认：自身更新经确认后执行 `--apply-self`；某依赖更新经确认后执行 `--apply --only <依赖名>`，仅替换该依赖的 `skills/<名>` 目录（保留 node_modules），不影响其他模块。
  - 仓库地址与版本基线持久化于 `.local/deps.json`（脚本自动回写）；检测日志追加于 `.local/update_check.log`。二者均在 `.local/` 内，不污染仓库树。
  - `.local/` 缺失（如新机器首次运行）→ 回退上述手工 git/WebFetch 比对，并提示可从维护者处获取检测脚本。

# 环境自检（次步，强制，任一失败即中止）

skill 无法以文件形式打包运行时环境，执行前必须逐项检测，全部通过方可进入命令流程：

| 项目 | 检测命令 | 通过标准 | 用途 |
|---|---|---|---|
| Node.js | `node --version` | ≥ v18，命令可执行 | guizang 渲染与 `validate-social-deck.mjs` 校验 |
| guizang 渲染依赖 | `node -e "require.resolve('playwright')"` 于 `skills/guizang-social-card-skill/` 目录；且 `npx playwright install chromium` 已就绪（Chromium 二进制存在） | 模块可解析 **且** 浏览器二进制存在 | guizang 出图与 `validate-social-deck.mjs` 校验（该脚本 `import { chromium } from "playwright"`） |
| git | `git --version` | 可执行 | 版本自检；缺失则必须走 WebFetch 比对兜底 |
| 网络 | WebFetch 可达 `raw.githubusercontent.com` | 可达 | 版本比对、Pexels 取图、Playwright/Chromium 首次安装 |

- **guizang 渲染依赖预装（强制，任一缺失即中止）**：进入命令流程前，确认 `skills/guizang-social-card-skill/node_modules/playwright` 存在；不存在则在该目录依次执行：
  1. `npm install --no-audit --no-fund`（安装 playwright 模块）
  2. `npx playwright install chromium`（安装 Chromium 浏览器二进制，需网络与操作系统依赖）
  - 安装失败（无网络 / 无权限 / 系统依赖缺失）→ 立即中止，按「依赖失败处理」规则报告具体原因。
  - ⚠️ 仅 `npx playwright --version` 可用**不足以**满足 `validate-social-deck.mjs` 的本地 `import` 解析，必须确认 `node_modules/playwright` 已落于 guizang 目录内。
  - `node_modules/` 已被 `.gitignore` 忽略，不随仓库提交；换到其他电脑首次运行须重新执行上述预装。
- 任一项不满足 → 立即中止，逐项报告缺失内容与安装建议（如「请安装 Node.js ≥18」「请执行 guizang 目录下的 npm install 与 playwright install chromium」），**禁止跳过检测直接执行，禁止用降级方案替代**。
- 用户补齐环境后从版本自检重新开始。

# 命令

1. 调用 `dbs-goal`（读取本项目 `skills/dbs-goal/SKILL.md` 并按其完整规范执行）接收用户关于本次发帖的原始想法原话，把发帖目标审计为可检查交付物（下一步做什么、什么时候算完）；目标结论经用户确认后随信息包全程传递；未确认禁止后续步骤。
2. 确认基础选题（基于已确认的目标结论推导；缺失则询问，禁止臆造）。
3. 调用 `dbs-content`（读取本项目 `skills/dbs-content/SKILL.md` 并按其完整规范执行）诊断切入角度；产出 2-3 候选角度列给用户确认；未确认禁止后续步骤。
4. 调用 `dbs-deconstruct`（读取本项目 `skills/dbs-deconstruct/SKILL.md` 并按其完整规范执行）拆解已确认角度中的核心概念，锁定写稿方向；拆解结论随信息包传给写稿与标题环节。
5. 调用 `dbs-xhs-title`（读取本项目 `skills/dbs-xhs-title/SKILL.md` 并按其完整规范执行）生成 ≤20 字候选标题；列举供用户选定；未选定禁止后续步骤。
6. 调用 `dbs-hook`（读取本项目 `skills/dbs-hook/SKILL.md` 并按其完整规范执行）基于选题+角度+标题生成开场钩子候选；列举供用户选定；未选定禁止写稿。
7. 调用 `xhs-copywriter`（读取本项目 `skills/xhs-copywriter/SKILL.md` 并按其完整规范执行）写稿：主 skill 组装信息包（选题/目标结论/角度/概念拆解/标题/钩子/痛点关键词/获客意图）传入，接收五段结构定稿；**禁止主 skill 亲自写稿**。
8. 调用 `dbs-resonate`（读取本项目 `skills/dbs-resonate/SKILL.md` 并按其完整规范执行）对定稿做共鸣诊断；诊断建议交回 `xhs-copywriter` 修订模式落实；主 skill 向用户展示诊断结论与修订说明。
9. 调用 `dbs-ai-check`（读取本项目 `skills/dbs-ai-check/SKILL.md` 并按其完整规范执行）检测修订稿 AI 写作特征；命中 AI 指纹 → 展示检测报告并弹交互式问题框询问用户「进入其改写引导 / 保持原稿」，改写结论交 `xhs-copywriter` 修订模式落实，禁止自动改写；未命中 → 放行。
10. 调用 `guizang-social-card-skill`（读取本项目 `skills/guizang-social-card-skill/SKILL.md` 并按其完整规范执行；其模板/脚本/参考均在该目录内，使用相对路径调用）：≥3 张 3:4（1080×1440）轮播卡，完整承载终稿同一份文案；图内文字严格对齐、字号层级遵循文案层级；最小字号 ≥28px；轮播用「左滑」+页码。**主 skill 须将本次落盘子目录 `<SKILL_REPO_DIR>/output/<选题名_日期>` 作为 guizang 的 task folder 显式传入（覆盖其默认 `local-tests/<slug>/`），使渲染产物直接落入已隔离的输出目录，避免仓库内残留未隔离的临时目录。**
11. 本地落盘：
    - 读取 `<SKILL_REPO_DIR>/.local/output-dir.txt` 中已记住的落盘目录；
    - 不存在 → 弹交互式问题框询问落盘目录，**默认选项为 skill 同目录**（`<SKILL_REPO_DIR>/output/`），用户选定后写入 `.local/output-dir.txt` 记住，后续执行直接沿用；
    - 子目录 `选题名_日期`；同选题修改复用原目录覆盖更新；
    - 终态输出文字区纯文本 + 图片 + 落盘子目录路径。

# 依赖来源（自包含，禁止引用宿主机器已安装版本）

- 全部依赖 skill 已原样打包于本项目 `skills/` 目录，与宿主环境无关。
- `dbs-goal` → `skills/dbs-goal/SKILL.md`
- `dbs-content` → `skills/dbs-content/SKILL.md`
- `dbs-deconstruct` → `skills/dbs-deconstruct/SKILL.md`
- `dbs-xhs-title` → `skills/dbs-xhs-title/SKILL.md`
- `dbs-hook` → `skills/dbs-hook/SKILL.md`
- `xhs-copywriter` → `skills/xhs-copywriter/SKILL.md`
- `dbs-resonate` → `skills/dbs-resonate/SKILL.md`
- `dbs-ai-check` → `skills/dbs-ai-check/SKILL.md`
- `guizang-social-card-skill` → `skills/guizang-social-card-skill/`（含 assets/ 模板、references/、scripts/）
- 调用任一依赖时，必须读取本项目内的对应文件并遵循其流程；禁止改用宿主机器上同名已安装 skill。
- 各依赖的传入/接收/禁止干预点详见 `references/dependencies.md`。

# 运行产物隔离（强制）

- 运行期记忆与产物一律写入 `.local/`（目录记忆等私有配置）与落盘目录（成稿/图片）；两者均已列入 `.gitignore`。
- ❌ 禁止把运行记忆、成稿、图片、渲染中间产物提交或推送到 GitHub 仓库。
- ❌ 禁止把中间产物（渲染脚本副本/html/temp）留在落盘子目录。

# 依赖失败处理（强制）

- 任一打包依赖出问题（目录缺失 / SKILL.md 缺失 / 报错 / 返回不可用 / 超时 / 拒绝 / 能力边界外拒单 / 信息包被退回且无法补全）→ 立即中止全部执行。
- 禁止回退到任何默认方案或替代路径。
- 依赖 skill 自身给出默认/兜底方案时 → 必须弹出交互式问题框（AskUserQuestion）询问用户是否采纳；未经用户明确选择，禁止自动采纳或拒绝。
- 版本自检、环境自检或打包完整性校验失败 → 同此规则，中止并报告。

# 内层自治（强制）

- 调用任一依赖时，完整遵循其 SKILL.md 规范流程，不裁剪、不改写其决策逻辑。
- 主 skill 仅负责外层编排、信息收集与传递、接收依赖返回；禁止在主 skill 内重写依赖职责（自行写稿、自行出图、自行套标题公式、自行诊断、自行判定 AI 味）。

# 禁令

- ❌ 禁止版本自检、环境自检或打包完整性校验失败后继续执行。
- ❌ 禁止依赖失败时回退默认/替代方案。
- ❌ 禁止未经用户交互确认即采纳依赖的默认方案。
- ❌ 禁止引用宿主机器上已安装的同名 skill（必须用本项目 skills/ 内打包副本）。
- ❌ 禁止干预依赖 skill 内层执行逻辑。
- ❌ 禁止主 skill 亲自写稿、改稿（一律经 `xhs-copywriter`）。
- ❌ 禁止未确认发帖目标、切入角度即进入后续步骤。
- ❌ 禁止未选定标题或开场钩子即写稿/出图。
- ❌ 禁止跳过共鸣诊断与 AI 特征检测直接出图。
- ❌ 禁止 dbs-ai-check 命中后未经用户选择即自动改写文案。
- ❌ 禁止图文卡少于 3 张。
- ❌ 禁止图内文字未严格对齐或最小字号 <28px。
- ❌ 禁止图文卡文案与文字区文案不一致。
- ❌ 禁止文案含 `#话题` 标签。
- ❌ 禁止硬编码落盘目录或跳过落盘目录交互确认（首次）。
- ❌ 禁止将运行记忆与产物上传 GitHub。
