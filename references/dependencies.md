# 依赖调用规范（显式 · 全部指向本机 agent skills 目录）

本 skill **不自带依赖副本**：所有依赖 skill 安装在本机 agent skills 目录 `~/.workbuddy/skills/<name>/`，由 `.deps-cache/ensure_deps.sh` 检查 / 安装 / 更新并把解析路径写入 `.deps-cache/deps.json`。主 skill 调用任一依赖时，读取 `.deps-cache/deps.json` 记录（缺省 `~/.workbuddy/skills/<name>/SKILL.md`）并完整遵循其规范流程，不裁剪其决策逻辑。主 skill 仅负责流程控制、信息传递与最终结果输出；本文件规定「传什么、收什么、哪些点主 skill 不得插手」。所有相对路径均以各依赖自身目录 `~/.workbuddy/skills/<name>/` 为基准。

依赖总表（9 个，与 SKILL.md「环境检测」、`.deps-cache/ensure_deps.sh` 三处一致）：

| 依赖 | 用途（流程步骤） | 缺失时安装来源 |
|---|---|---|
| xiaohongshu-keyword-collector | 热搜词采集（步骤 3） | `openlark/skills` 子路径 `skills/xiaohongshu-keyword-collector` |
| dbs-content | 选题梳理与写稿方向诊断（步骤 4） | `dontbesilent2025/dbskill` 对应子路径 |
| dbs-hook | 钩子生成（步骤 4） | `dontbesilent2025/dbskill` 对应子路径 |
| dbs-xhs-title | 标题撰写与确认（步骤 9） | `dontbesilent2025/dbskill` 对应子路径 |
| multi-search-engine | 实证数据检索（步骤 8） | 本机已装，无自动安装来源 |
| content-deai-engine | 写稿与逐图文案（步骤 10、12） | `lanyasheng/content-deai-engine` |
| dbs-resonate | 共鸣审稿（步骤 11、12） | `dontbesilent2025/dbskill` 对应子路径 |
| no-ai-slop | 去 AI 味（步骤 11） | `petergyang/no-ai-slop` |
| guizang-social-card-skill | 图文卡出图（步骤 13） | `op7418/guizang-social-card-skill` |

---

## 1. xiaohongshu-keyword-collector（热搜词采集，步骤 3）

- **路径**：`~/.workbuddy/skills/xiaohongshu-keyword-collector/SKILL.md`
- **职责边界**：基于浏览器自动化打开小红书探索页，输入种子词（**不提交搜索**），采集搜索框联想下拉的相关/趋势热词。纯浏览器操作，无 API Key、无调用额度、无付费层；部分词需登录态才完整，遇验证码需人工处理。**它是采集者，不写稿、不评审。**
- **传入**：主 skill 以「选题思路 + 人群画像 + 图文贴目的」提炼的 1–3 个种子词。
- **完整执行**：读取其 SKILL.md，遵循其 Workflow（打开 `https://www.xiaohongshu.com/explore` → 定位搜索框 → 输入种子词不提交 → 等待联想下拉 1–2 秒 → 采集全部联想词 → 去重整理输出）。不得要求它提交搜索或自由发挥；遇验证码按其规范提示用户人工处理，不得绕过。
- **主 skill 接收**：联想词列表（单词/批量，去重后）。
- **后续动作（主 skill 职责）**：按与选题思路的相关度筛选 **5–10 个最贴近的搜索关键词**写入信息包；不足 5 个时调整种子词再采一轮，仍不足如实记录实际数量。
- **禁止**：主 skill 编造热词、用非小红书来源词冒充热搜词、跳过本步直接进选题环节。

---

## 2. dbs-content（选题梳理与写稿方向诊断，步骤 4）

- **路径**：`~/.workbuddy/skills/dbs-content/SKILL.md`
- **职责边界**：内容创作诊断——把选题方向诊断成可执行的好内容方案（形式匹配 + 五维诊断）。**它是诊断者，不写稿**（写稿由 `content-deai-engine` 专职承担）。
- **传入**：「选题思路 + 人群画像 + 图文贴目的 + 热搜词」信息包；目标形式固定为「小红书图文」。
- **完整执行**：读取其 SKILL.md，遵循其 Phase 1→4（接收内容 → 内容形式匹配 → 五维诊断：文字洁癖 / 封面标题 / 表达效率 / 认知落差 / AI 辅助 → 输出诊断报告）。不得跳过任一 Phase，不得由主 skill 替它下结论；其流程中的追问由主 skill 按提问规范原样转达用户。
- **主 skill 接收**：**3–5 个选题**及各自**写稿方向**（切入角度、推荐形式、五维判断、第一步行动）。
- **后续动作（主 skill 职责）**：一致性自检（选题须源自用户思路与热搜词）后，将候选选题列给用户确认（步骤 5），再将其下的写稿方向列给用户确认（步骤 6）。
- **禁止**：主 skill 替用户断定选题或方向、把诊断报告当成文案、跳过五维诊断。

---

## 3. dbs-hook（钩子生成，步骤 4）

- **路径**：`~/.workbuddy/skills/dbs-hook/SKILL.md`
- **职责边界**：开头/钩子专家——按「话题 + Hook + 可信度」公式生成开场钩子候选。原生面向短视频开头，此处复用其钩子生成能力产出小红书图文的开场钩子（首图首句 / 正文第一句）。**它只产钩子，不定选题。**
- **传入**：步骤 2 信息包 + dbs-content 的选题/写稿方向结论（作为素材）；说明目标载体为「小红书图文开场」。
- **完整执行**：读取其 SKILL.md，遵循其阶段流程（接收文案 → 内容质量诊断 → 生成优化方案：素材提取 / 素材增补 / 悬念制造三方法共 10–15 条 → Top3 推荐）。**若其 Phase 2 判定素材不足而停止优化，主 skill 把停止结论原样转达用户并回步骤 2 补充素材，禁止强迫生成、禁止主 skill 代写钩子。**
- **主 skill 接收**：钩子候选列表（含各自公式结构说明）+ Top3 推荐。
- **后续动作（主 skill 职责）**：筛选与图文载体适配的候选（去除仅适用于视频口播的表述），列给用户选定（步骤 7）；未选定禁止写稿。
- **禁止**：主 skill 跳过该依赖自写钩子、替用户选定钩子、把视频专用表述原样塞进图文。

---

## 3.1 dbs-xhs-title（标题撰写与确认，步骤 9）

- **路径**：`~/.workbuddy/skills/dbs-xhs-title/SKILL.md`
- **职责边界**：小红书标题公式专家——从验证过的爆款标题公式中挑对的、用对的、说明为什么用这个。它只产标题，不定选题、不写正文。
- **传入**：步骤 9 标题输入信息包（已确认选题 / 行文方向 / 已确认钩子 / 热搜词 5–10 / 人群画像 / 图文贴目的 + `config.md` 封面主标题约束 4–14 字）。
- **完整执行**：读取其 SKILL.md，遵循其标题公式流程产出候选（含 Top 推荐）。主 skill 不干预其公式选择与排序。
- **主 skill 接收**：标题候选列表 + 推荐；经用户确认循环（步骤 9）采用固定值，供步骤 10 封面标题槽使用。
- **禁止**：主 skill 自行拟定或改写标题、替用户选定标题。

---

## 4. multi-search-engine（实证数据检索，步骤 8）

- **路径**：`~/.workbuddy/skills/multi-search-engine/SKILL.md`
- **职责边界**：多引擎网页检索聚合器（16 引擎：7 国内 + 9 国际，无需 API Key），采集真实数据、公开观点、权威信息。**它是检索聚合器，不写稿、不臆造来源。**
- **传入**：主 skill 分析已确认信息（选题 + 行文方向 + 钩子 + 人群画像 + 目的）后列出的实证检索清单——关键词 + 可选查询级筛选（`site:` 命中权威域如 gov.cn / edu.cn、`filetype:`、时间过滤 `tbs=qdr:y` 等、排除词 `-`），并说明目标用途（如「某话题近一年的真实数据与公开观点」）。
- **完整执行**：读取其 SKILL.md，遵循其 Workflow（语言评估 → 受控检索（速率限制、分批）→ 结果聚合整理）。不得由主 skill 自行拼搜索结果替代其聚合流程。
- **主 skill 接收**：聚合检索报告（来源链接 + 摘要），其中数据须可溯源。
- **后续动作（主 skill 职责）**：将检索报告并入步骤 9 写稿信息包；真实数据在终稿中须标注来源；检索不到的信息标注「待核实」。
- **禁止**：主 skill 编造检索结果、把未经验证的来源当事实写入终稿、把检索噪声直接塞入正文。

---

## 5. content-deai-engine（写稿与逐图文案，步骤 10、12）

- **路径**：`~/.workbuddy/skills/content-deai-engine/SKILL.md`（含 `references/anti-ai-patterns.md`、`platform-templates.md`、`preflight-checklist.md`）
- **职责边界**：「去 AI 味」初稿生成与修订引擎，自带 AI 味诊断、四步重写、平台适配、质量门禁与三角色自检。**它是生成者，不替代 dbs-resonate 的独立审稿与 no-ai-slop 的去 AI 味。** 其内置 AI 味诊断仍运行，但循环内的去 AI 味专责由 no-ai-slop 承担。
- **传入（初稿，步骤 10）**：完整信息包——选题思路 + 人群画像 + 图文贴目的 + 热搜词（5–10 个）+ 已确认选题 + 已确认行文方向 + 已确认钩子 + 步骤 9 确认标题（固定值，封面标题槽）+ 实证检索报告（带来源）+ 用户配图（如有）+ 目标平台「小红书」+ 素材来源标注。明确要求：按小红书平台模板（痛点场景 → 亲历细节 → 3 步做法 → 互动提问）产出；热搜词自然融入正文 ≥2–3 个；数据对应检索报告来源；无法验证的信息标注「待核实」。
- **完整执行**：读取其 SKILL.md，遵循其 0) 先决条件 → 1) AI 味诊断 → 2) 四步重写 → 3) 平台适配 → 4) 标准输出 → 5) 质量门禁 → 6) 三角色自检 全流程。不得裁剪其重写与自检逻辑。
- **主 skill 接收**：标准输出——正文 / 评论区首评 / 标签建议 / 发布前风险提示 + 「逐图文案」块。封面标题由步骤 9 确认值固定提供（本步骤封面标题槽须等于该值），随步骤 12 由用户确认。
- **传入（修订，步骤 11、12）**：dbs-resonate 报告中的【具体改法】与 no-ai-slop 的去 AI 味稿，原样作为修改方向（或并入用户修改方向），按其修订模式（四步重写 / 快速调用模式）落实一轮并吸收去味修改。
- **后续动作（主 skill 职责）**：初稿进入步骤 11 审稿循环（dbs-resonate 共鸣 + no-ai-slop 去 AI 味）；修订稿回 dbs-resonate 复审 + no-ai-slop 去味；用户确认（步骤 12）后进入出图。
- **禁止**：主 skill 自行写稿 / 改稿、写稿 skill 不按修改方向修改、臆造细节或来源、终稿不含与选题强相关的热搜词。

---

## 5.1 no-ai-slop（去 AI 味，步骤 11）

- **路径**：`~/.workbuddy/skills/no-ai-slop/SKILL.md`
- **职责边界**：去 AI 味重写专家——按其行为准则重写文本，去除 AI 生成痕迹，保留作者原意与口语感。**它是去 AI 味专责者，不替代 dbs-resonate 的共鸣诊断，也不替代 content-deai-engine 的写稿。**
- **传入**：步骤 11 审稿循环中 content-deai-engine 修订后的当前稿。
- **完整执行**：读取其 SKILL.md，遵循其去 AI 味重写流程（诊断 AI 味 → 按准则重写 → 自检）。主 skill 不干预其去味判断。
- **主 skill 接收**：去 AI 味稿（或「无 AI 味」通过结论）；判定仍有 AI 味时其重写稿即修改方向，主 skill 原样转交 content-deai-engine 吸收融合。
- **禁止**：主 skill 自行去味、把去 AI 味职责推给 dbs-resonate。

---

## 6. dbs-resonate（共鸣审稿，步骤 11、12）

- **路径**：`~/.workbuddy/skills/dbs-resonate/SKILL.md`
- **职责边界**：文稿共鸣诊断——用 5 个传播心理学维度（沉默解除 / 满足动机 / 立场框架 / 传播入口 / 信念结构）诊断文稿能否打中受众，输出具体到文字的改法。**它是诊断者，不重写文稿，不负责去 AI 味（去 AI 味由 no-ai-slop 专责）。**
- **传入**：content-deai-engine 产出的当前稿（初稿或修订稿全文）。
- **完整执行**：读取其 SKILL.md，遵循其 Step 1→4（提取所有主张 → 核心机制审查（不可跳过）→ 五维度诊断 → 输出诊断报告）。每条诊断必须关联文稿具体文字，不允许泛泛而谈。不得要求它直接改稿。
- **主 skill 接收**：诊断报告——核心问题一句话、核心机制审查、五维有效/弱/无效、【具体改法】（删掉 / 缩短为支撑细节 / 强化 / 保持不动 + 改完后的骨架）。
- **放行标准（主 skill 控制，与 no-ai-slop 并联）**：五维全部有效、无删除/强化建议（共鸣达标）**且** no-ai-slop 判定无 AI 味（去味达标）→ 放行，进入步骤 12；否则【具体改法】即为修改方向，原样转交 content-deai-engine 修订（并交 no-ai-slop 去味）后复审。同一修改方向连续两轮未获放行 → 停止循环，报告用户裁决。
- **后续动作（主 skill 职责）**：向用户展示诊断结论与修订说明（步骤 11 确认时）。
- **禁止**：主 skill 自行按建议改稿、跳过审稿直接请用户确认、把诊断报告当作终稿。

---

## 7. guizang-social-card-skill（图文卡出图，步骤 13）

- **路径**：`~/.workbuddy/skills/guizang-social-card-skill/SKILL.md`
- **目录内容**：`assets/`（template-editorial-card.html、template-swiss-card.html、背景系统）、`references/`（platform-specs、style-system、theme-presets、layout-recipes、components、category-cookbook 等 16 个）、`scripts/`、`validate-social-deck.mjs`。
- **职责边界**：由终稿文案与标题生成小红书 3:4（1080×1440）轮播卡 PNG，含图内排版、字号层级、图片来源处理、渲染与自检。**两种风格模式**：Editorial Magazine × E-ink（电子杂志 · 图文混排，6 个杂志主题色）与 Swiss International（瑞士国际主义，4 个强调色），同一套图不混用。
- **传入**：用户确认的最终稿全文 + 最终标题 + 用户选定的风格模式与主题色 + 用户配图（如有）；**落盘子目录 `<落盘根目录>/output/<最终标题_YYYYMMDD>` 作为 task folder 显式传入**（覆盖其默认 `local-tests/<slug>/`）。
- **完整执行**：读取其 SKILL.md，遵循其 Intake → Extract Story → Choose Style Mode → Plan Pages → Build & Render → Image/Screenshot Handling → Deliver 全链路。所有模板/资源/参考用相对于其自身目录的路径调用。不得裁剪其 intake 或 render 步骤。
- **关键交互（主 skill 不得代用户决定）**：
  - 用户无配图时，该 skill 会向用户一问（自备照片 / 网络取图 / AI 生成）——主 skill 把该问原样转达为编号选项，禁止代答、禁止预设网络取图。
  - 网络取图时其会披露来源并询问是否标注——原样转达。
  - 类目落在其能力边界外（如美食大片摆盘、日常 OOTD 全身、梦核氛围装饰等）时它会**拒单**——此即「依赖在能力边界外拒绝」，主 skill 按依赖失败处理中止，禁止回退默认。
  - 其 Deliver 环节会先给用户看图、再问是否自动校验——该问原样转达。
- **主 skill 接收**：渲染后的 3:4 卡片 PNG 路径集合 + 输出目录 + 来源/版权说明（若含网络取图）。
- **禁止**：主 skill 自行指定排版细节覆盖其风格系统、自行出图、忽略其 QA 环节、混用两种风格系统。

---

## 深度依赖与最新性校验模型

> 本模型确保：每个依赖 skill 不仅自身存在，其**运行时深度依赖**也齐备；且 git 类依赖**始终与上游保持最新**。全部在任务开始前的环境检测中由 `.deps-cache/ensure_deps.sh` 强制完成，每次运行都做。

### 1. 深度依赖映射（在 `ensure_deps.sh` 的 `deep_deps_of()` 维护）

| 依赖 skill | 深度依赖键 | 含义 | 校验点 |
|---|---|---|---|
| `guizang-social-card-skill` | `playwright` | Playwright 模块 + Chromium 二进制 | `~/.workbuddy/skills/guizang-social-card-skill/node_modules/playwright` + `chromium.executablePath()` |
| `xiaohongshu-keyword-collector` | `playwright` | 同上（浏览器自动化采集小红书联想热词） | 同上（与 guizang 共用同一套 Playwright/Chromium） |
| 其余依赖（dbs-content / dbs-hook / dbs-xhs-title / dbs-resonate / content-deai-engine / no-ai-slop / multi-search-engine） | （无） | 纯文档/检索类，无额外运行时 | — |

- **新增带深度依赖的 skill 时**：必须在 `ensure_deps.sh` 的 `deep_deps_of()` 中登记其深度依赖键，并提供对应的 `check_<key>` 检查函数（含自修复安装逻辑），否则不被校验。
- **自修复安装**：`check_playwright` 在模块或 Chromium 缺失时，于 guizang 目录执行 `npm install --no-audit --no-fund playwright` 与 `npx playwright install chromium`；任一失败 → 环境检测中止。
- **浏览器二进制最新性**：仅软提示（对比 `npm view playwright version`），不自动升级 Chromium（避免大体积下载）；如需升级手动执行 `npx playwright install chromium`。

### 2. 最新性强制校验（git 类依赖）

- 对每个有来源（git url）的依赖，脚本用 `git ls-remote <url> HEAD` 取得上游默认分支最新 commit。
- 本地 commit 取值：目标为 git 仓库时直接读 `.git` HEAD；否则读 `.deps-cache/.dep_commits/<name>` 中记录的 commit。
- **本地版本未知（无 `.git` 且无 commit 记录）且上游可达** → 记录上游 HEAD 为基线 commit（**不改动任何文件**），后续上游 HEAD 变更即据此触发自动更新；避免对可能含本机定制的副本做盲目覆盖。
- 不一致（过期）→ **自动快进到最新**：目标带 `.git` 时 `git fetch --depth 1 + reset --hard origin/<branch>`（保留 `node_modules` 等未跟踪文件）；独立仓库但缺 `.git` 时新鲜克隆上游并移植 `.git` 后 `reset --hard` 对齐（未跟踪文件保留）；monorepo 复制类重新克隆并复制子路径覆盖。更新后刷新记录。
- 无法连接上游 → 跳过更新仅告警，**不阻塞**主流程（以本地现有版本继续）。
- 无来源的 `multi-search-engine` 无法自动校验最新性，由用户自行维护。

### 3. 超时与重试约束（防止网络调用无限挂起）

- 所有网络调用均被 `.deps-cache/ensure_deps.sh` 包裹在超时内（GNU `timeout`，不可用时降级为「后台进程 + 超时 kill」兜底），**超时即中止该单次调用并继续，不会让整个脚本卡死**：

  | 操作 | 超时 | 触发后的行为 |
  |---|---|---|
  | `git ls-remote` 探测上游 | 180s | 视为无法连接上游，跳过最新性更新并告警（不阻塞） |
  | `git clone --depth 1` | 300s | 计入重试；达 `MAX_RETRY=2` 仍失败 → 该依赖安装失败 → 中止 |
  | `git fetch`/`reset` 更新 | 180s | 计入重试；失败 → 该依赖更新失败 → 中止 |
  | `npm view playwright version` | 60s | 视为查询失败，跳过软提示（不阻塞） |
  | `npm install playwright` / `npx playwright install chromium` | 900s | 自修复失败 → 深度依赖校验失败 → 中止 |

- 每次超时向 stderr 打印 `⏱️ [<label>] 超时(<秒>s)：<原因>` 与 `🔧 修复：<具体方案>`；诊断信息走 stderr，不污染 deps.json 数据通道。
- 常量集中在脚本顶部（`GIT_TIMEOUT` / `CLONE_TIMEOUT` / `FETCH_TIMEOUT` / `NPM_TIMEOUT` / `PLAYWRIGHT_TIMEOUT` / `MAX_RETRY`），调参只改一处。

### 4. deps.json 记录字段

每条依赖记录含：`path`、`status`（present / installed / missing-optional / install-fail / missing-no-source）、`installed_commit`、`latest_commit`、`stale`（bool）、`deep_deps`（对象：键为深度依赖名，值含 `ok` / `detail` / `version`）。主 skill 仅把 `status` 为 `present` / `installed` 且 `deep_deps` 全部 `ok` 的依赖视为可用。

---

## 环境检测实施细则

- **时机**：每次任务开始前，先于流程 14 步；禁止跳过。
- **依赖 skill 检测**：运行 `<SKILL_REPO_DIR>/.deps-cache/ensure_deps.sh`（机制见上节）；退出码非 0 即中止。
- **主机运行时检测**（依赖检测通过后执行）：

  | 项目 | 检测命令 | 通过标准 | 缺失 / 不足时策略 |
  |---|---|---|---|
  | Node.js | `node --version` | ≥ v18（guizang 渲染与校验脚本要求） | 自动安装到本机全局受管目录并更新到满足要求的版本（install_binary / managed runtime，跨项目共享，不污染系统环境） |
  | Python | `python --version` | 当前无任何依赖要求 Python；仅在未来某依赖声明需要时启用 | 同 Node.js 策略：安装到本机全局受管目录并自动更新 |
  | git | `git --version` | 可执行 | 报告缺失与安装建议，中止 |
  | 网络 | 可达 `github.com` / `raw.githubusercontent.com` | 可达 | 报告并中止 |

- 报告格式：逐项列出「项目 / 状态（✅/❌）/ 缺失时的处理方式」；存在 ❌ 即中止。
- 禁止：跳过检测、用「大概率装了」推断替代实际执行检测命令、缺失时静默降级。

## 编排上下文说明（本文件专有）

- 各 dbs 子 skill 内部可能带有 `/dbs*` 路由导航（指向 dbs 家族其他 skill）。这些导航仅作原始形态保留——**本流程已由主 skill 按 14 步接管全部路由**，子 skill 内部的 `/dbs*` 指引是否执行由主 skill 决定，不得令流程脱离主编排。
- guizang 默认 task folder 为 `local-tests/<slug>/`；主 skill 在步骤 13 **必须显式传入** `<落盘根目录>/output/<最终标题_YYYYMMDD>` 作为 task folder，使产物落入已隔离的输出目录，避免仓库内临时残留。

## 落盘与产物隔离实施细则

- 每次落盘前按提问规范问一次目录（一次一题、编号选项）：默认 = `<SKILL_REPO_DIR>/output/`；用户可指定其他根目录，子目录规则不变：`<根目录>/output/<最终标题_YYYYMMDD>/`。
- 同选题再次修改在原子目录内覆盖更新，禁止另建新时间戳子目录。
- 产物：最终稿文案 md（标题 / 正文 / 评论区首评 / 标签 / 来源标注）+ 全部卡片 PNG + 网络取图来源记录（如有，如 `assets/SOURCES.md`）。
- 禁止：硬编码落盘目录、未经询问即落盘、把中间产物（渲染脚本副本 / html / temp）留在落盘目录、把运行记忆（`.deps-cache/`）与产物（`output/`）提交或推送到仓库（两者均已列入 `.gitignore`）。
