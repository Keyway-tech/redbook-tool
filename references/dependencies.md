# 依赖调用规范（显式 · 全部指向本项目内打包副本）

本 skill 为自包含结构：所有依赖 skill 已原样复制于本项目 `skills/` 目录。主 skill 调用任一依赖时，**必须读取本项目内对应文件并完整遵循其规范流程**，不引用宿主机器上任何已安装的同名 skill。主 skill 仅负责流程编排、信息收集、信息传递与最终落盘；本文件规定「传什么、收什么、哪些点主 skill 不得插手」，不替代依赖 skill 的内部逻辑。所有相对路径（如 `assets/`、`references/`、`scripts/`）均以各依赖自身目录 `skills/<name>/` 为基准。

---

## 1. dbs-goal（打包于 skills/dbs-goal/）— 流程第 1 步介入（目标澄清前置）

- **路径**：`skills/dbs-goal/SKILL.md`
- **职责边界**：用维特根斯坦语言哲学把模糊的发帖目标审计成可检查交付物（可指物性/可否证性/完成态/语法健全/嵌在上下文）。**它是审计者，不代定选题。**
- **传入**：用户对本次发帖目标的原话（该 skill Phase 1 要求原封不动的原话——主 skill 收集时禁止先行润色）。
- **完整执行**：读取 `skills/dbs-goal/SKILL.md`，遵循其 Phase 流程（接收原话 → 三个用法测试逐个问 → 审计输出）。其流程要求「逐个问、等回答」——主 skill 必须把追问原样转给用户，禁止代答。
- **主 skill 接收**：审计后的目标结论（下一步做什么 + 什么时候算完）。
- **后续动作（主 skill 职责）**：目标结论列给用户确认；确认后写入信息包全程传递（dbs-content、xhs-copywriter 均消费）。
- **禁止**：主 skill 替用户回答用法测试、跳过审计直接进角度诊断、篡改目标原话。

---

## 2. dbs-content（打包于 skills/dbs-content/）

- **路径**：`skills/dbs-content/SKILL.md`
- **职责边界**：诊断「已确认选题如何做成好内容」——切入角度、内容形式、五维诊断（文字洁癖/封面标题/表达效率/认知落差/AI 辅助）。**它是诊断者，不写稿**（写稿由 `xhs-copywriter` 专职承担）。
- **传入**：已确认的基础选题 + dbs-goal 目标结论 + 目标形式固定为「小红书图文」。
- **完整执行**：读取 `skills/dbs-content/SKILL.md`，遵循其 Phase 1→4（接收内容 → 内容形式匹配 → 五维诊断 → 输出诊断报告）。不得跳过任一 Phase，不得由主 skill 替它下结论。
- **主 skill 接收**：诊断报告中的「推荐形式/平台」「五维判断」「第一步行动」。
- **后续动作（主 skill 职责）**：从诊断中抽取 2-3 个可执行的切入角度，列给用户确认；用户未确认禁止进入 `dbs-deconstruct`。
- **禁止**：主 skill 替用户断定角度、跳过五维诊断、把诊断报告当成文案。

---

## 3. dbs-deconstruct（打包于 skills/dbs-deconstruct/）— 写稿方向介入

- **路径**：`skills/dbs-deconstruct/SKILL.md`
- **职责边界**：用维特根斯坦 + 奥派方法把已确认角度中的核心商业概念拆到原子级（使用场景分析、Question/Problem 区分、严格定义），锁定写稿方向、消灭模糊大词。**它是拆解者，不写稿。**
- **传入**：已确认的切入角度 + 角度中出现的核心概念（如「精准获客」「个人 IP」等；主 skill 从角度表述中识别出待拆概念传入）。
- **完整执行**：读取 `skills/dbs-deconstruct/SKILL.md`，遵循其 Phase 流程（接收概念 → 维特根斯坦式审查 → 拆解输出）。
- **主 skill 接收**：概念拆解结论（核心概念的明确定义与使用边界）。
- **后续动作（主 skill 职责）**：拆解结论写入信息包，传给 `dbs-xhs-title`（标题用词）与 `xhs-copywriter`（正文用词必须与拆解一致）。
- **禁止**：主 skill 自行定义概念、跳过拆解直接进标题、在后续环节改回模糊大词。

---

## 4. dbs-xhs-title（打包于 skills/dbs-xhs-title/）

- **路径**：`skills/dbs-xhs-title/SKILL.md`
- **职责边界**：从 75 个验证过的爆款公式中匹配并生成 ≤20 字标题，每个标题须可溯源到具体公式编号。它是「公式匹配器」，不是自由标题生成器；公式库已内联于该 SKILL.md 内，无需外部文件。
- **传入**：确认后的选题 + 已选定的切入角度 + 概念拆解结论 → 提炼为「话题 + 行业/领域」两个字段传入。
- **完整执行**：读取 `skills/dbs-xhs-title/SKILL.md`，遵循其 Step 1→4（理解输入 → 匹配 5-8 个公式 → 生成定制标题并标注公式来源与原始爆款 → 输出含 Top3 推荐）。不得要求它跳过公式匹配或自由发挥。
- **主 skill 接收**：候选标题列表（含公式编号）+ Top3 推荐。
- **后续动作（主 skill 职责）**：列举候选标题供用户选定一个 ≤20 字标题；用户未选定禁止进入 `dbs-hook`。
- **禁止**：主 skill 自行拼标题、绕过公式匹配、生成 >20 字标题、擅自修改公式核心结构。

---

## 5. dbs-hook（打包于 skills/dbs-hook/）

- **路径**：`skills/dbs-hook/SKILL.md`
- **职责边界**：开头/钩子专家——诊断开头问题并按「话题 + Hook + 可信度」公式生成开场钩子候选。原生面向短视频开头，此处复用其钩子生成能力产出小红书图文的开场钩子（首图首句/正文第一句）。
- **传入**：确认后的选题 + 选定的切入角度 + 选定的标题；说明目标载体为「小红书图文开场」。
- **完整执行**：读取 `skills/dbs-hook/SKILL.md`，遵循其阶段流程完成钩子生成（10-15 个候选）。不得由主 skill 直接自由发挥写钩子替代其公式化生成。
- **主 skill 接收**：开场钩子候选列表（含各自的公式结构说明）。
- **后续动作（主 skill 职责）**：筛选与图文载体适配的候选（去除仅适用于视频口播的表述），列给用户选定；用户未选定禁止进入 `xhs-copywriter`。
- **禁止**：主 skill 跳过该依赖自写钩子、替用户选定钩子、把视频专用表述原样塞进图文。

---

## 6. xhs-copywriter（打包于 skills/xhs-copywriter/）— 专职写稿

- **路径**：`skills/xhs-copywriter/SKILL.md`
- **职责边界**：小红书图文帖专业写稿器——接收结构化信息包，产出五段结构定稿（标题+开场钩子+正文+互动提问+获客钩子）；另有修订模式逐条落实诊断建议。**全流程唯一的写稿者；主 skill 禁止亲自写稿。**
- **传入（信息包）**：选题、切入角度、选定标题、选定钩子（必填）；目标结论（dbs-goal）、概念拆解（dbs-deconstruct）、痛点/关键词、获客意图（可选）。
- **完整执行**：读取 `skills/xhs-copywriter/SKILL.md`，遵循其 Phase 1→4（消化信息包 → 五段结构成稿 → 格式规范自检 → 交付含分卡建议）。信息包被退回 → 主 skill 补全后重传；无法补全按依赖失败中止。
- **主 skill 接收**：五段结构定稿全文 + 分卡建议。
- **修订链路**：dbs-resonate 诊断建议、dbs-ai-check 改写结论均由主 skill 转交其「修订模式」落实；主 skill 只传递，不动稿面。
- **禁止**：主 skill 亲自写稿/改稿、绕过信息包口头转述需求、把分卡建议强加给 guizang（排版决定权归出图方）。

---

## 7. dbs-resonate（打包于 skills/dbs-resonate/）

- **路径**：`skills/dbs-resonate/SKILL.md`
- **职责边界**：文稿共鸣诊断——用 5 个心理维度（沉默解除/满足动机/立场框架/传播入口/信念结构）诊断文稿能否打中受众，输出删除/强化建议。**它是诊断者，不重写文稿。**
- **传入**：`xhs-copywriter` 的完整定稿。
- **完整执行**：读取 `skills/dbs-resonate/SKILL.md`，遵循其完整诊断流程输出五维报告与修改建议。不得要求它直接改稿。
- **主 skill 接收**：五维诊断结论 + 逐条删除/强化建议。
- **后续动作（主 skill 职责）**：将建议原样转交 `xhs-copywriter` 修订模式落实；向用户展示「诊断结论 + 修订说明」。
- **禁止**：主 skill 自行按建议改稿、跳过诊断直接出图、把诊断报告当作终稿。

---

## 8. dbs-ai-check（打包于 skills/dbs-ai-check/）

- **路径**：`skills/dbs-ai-check/SKILL.md`
- **职责边界**：AI 写作特征识别——逐条扫描 22 个 AI 指纹特征，输出检测报告。**默认只诊断不改**；其改写引导模式须由用户明确说「我想改」才触发。
- **传入**：经 dbs-resonate 修订后的文稿 + 体裁声明「小红书图文/社交媒体」（影响其误伤判定，如 #13/#14 不适用项）。
- **完整执行**：读取 `skills/dbs-ai-check/SKILL.md`，遵循其识别模式输出逐处检测报告（引用原文 + 特征编号 + 严重度）。
- **主 skill 接收**：检测报告（命中处数、逐处引用与严重度）。
- **后续动作（主 skill 职责）**：
  - 命中 AI 指纹 → 展示报告并弹交互式问题框（AskUserQuestion）询问用户「进入 dbs-ai-check 改写引导 / 保持原稿」；用户选改写 → 按其改写引导模式逐条追问（追问原样转给用户），结论转交 `xhs-copywriter` 修订模式落实；用户选保持 → 放行。
  - 未命中 → 直接放行进入出图。
- **禁止**：主 skill 未经用户选择即自动改写（该 skill 明确反对机械「去 AI 味」）、跳过检测、替用户回答其追问。

---

## 9. guizang-social-card-skill（打包于 skills/guizang-social-card-skill/）

- **路径**：`skills/guizang-social-card-skill/SKILL.md`
- **目录内容（已打包）**：`assets/`（template-editorial-card.html、template-swiss-card.html、magazine-bg-webgl.js、screenshot-backgrounds/）、`references/`（platform-specs、style-system、theme-presets、layout-recipes、components、category-cookbook 等 16 个）、`scripts/`（validate-social-deck.mjs 等）、`validate-social-deck.mjs`、`package.json`。
- **职责边界**：由文案与标题生成小红书 3:4 轮播卡 PNG（≥3 张），含图内排版、字号层级、图片来源处理、渲染与自检。
- **传入**：终稿文案（图文卡与文字区同一份）+ 选定的 ≤20 字标题 + 风格意图（如 Swiss / Editorial / 「你来定」）+（可参考）xhs-copywriter 的分卡建议。
- **完整执行**：读取 `skills/guizang-social-card-skill/SKILL.md`，遵循其 Intake → Extract Story → Choose Style Mode → Plan Pages → Build & Render → Image/Screenshot Handling → Deliver 全链路，含其 `scripts/validate-social-deck.mjs`（或根目录 `validate-social-deck.mjs`）验收环节。所有模板/资源/参考均用相对于 `skills/guizang-social-card-skill/` 的路径调用。不得裁剪其 intake 或 render 步骤。
- **关键交互（主 skill 不得代用户决定）**：
  - 无图时该 skill 会向用户 **A/B/C 三选一**（自备照片 / Pexels 等网络取图 / AI 生成）。**禁止主 skill 预先替用户选 B（Pexels）**——让它按自身流程提问。
  - 若用户已在主流程明确选定图片来源，将该选择作为输入传入，避免重复提问。
  - 类目落在能力边界外（如美食大片摆盘、日常 OOTD 全身、梦核氛围装饰等）时它会**拒单**——此即「依赖在能力边界外拒绝」，主 skill 须按 SKILL.md「依赖失败处理」规则中止，**禁止回退默认**。
- **主 skill 接收**：渲染后的 3:4 卡片 PNG 路径集合 + 输出目录 + 来源/版权说明（若含网络取图）。
- **接收后核对（仅核对，不干预其内层）**：卡片 ≥3 张、比例 3:4、承载同一份文案、图内文字对齐、最小字号 ≥28px、轮播引导「左滑」+页码。
- **禁止**：主 skill 自行指定排版细节覆盖其风格系统、自行出图、忽略其 QA/验证步骤、把「默认 Pexels」强加给它。

---

## 环境自检实施细则

- 时机：版本自检通过后、命令步骤 1 之前，每次执行都做。
- 检测项与命令见 SKILL.md「环境自检」表；Node.js 版本取 `node --version` 输出主版本号 ≥18。
- **guizang 渲染依赖（必做，缺失即中止）**：确认 `skills/guizang-social-card-skill/node_modules/playwright` 存在；不存在则于该目录执行 `npm install --no-audit --no-fund` 与 `npx playwright install chromium`。注意：`npx playwright --version` 仅验证瞬态获取，**不能**替代 `node_modules/playwright` 的本地解析（`validate-social-deck.mjs` 用 `import { chromium } from "playwright"`）。安装失败按依赖失败处理。
- 报告格式：逐项列出「项目 / 状态（✅/❌）/ 缺失时的安装建议」；存在 ❌ 即中止。
- 禁止：跳过检测、用「大概率装了」推断替代实际执行检测命令、缺失时静默降级。

## 编排上下文说明（本文件专有）

- 本仓库所有 `dbs-*` 子 skill 末尾的「输入 /dbs」「路由到 /dbs-action 等」导航**在本编排中无效**：那些导航 skill 未打包进本项目。主 skill 已按 11 步流程接管全部路由，子 skill 内部的 `/dbs*` 指引仅作原始形态保留，不得执行。
- guizang 默认 task folder 为 `local-tests/<slug>/`（位于仓库内）；主 skill 在步骤 10 **必须显式传入** `output/<选题名_日期>` 作为 task folder，使产物落入已隔离的输出目录；`local-tests/` 与 `social-card-*/` 等已在 `.gitignore` 忽略，但显式传入可避免任何仓库内临时残留。

## 落盘目录记忆与产物隔离实施细则

- 记忆文件：`<SKILL_REPO_DIR>/.local/output-dir.txt`（单行，绝对路径；`.local/` 与 `output/` 均已列入 `.gitignore`，属本机私有，**禁止上传 GitHub**）。
- 首次执行（或记忆文件缺失/路径已失效）→ 弹交互式问题框（AskUserQuestion）询问落盘目录，**默认推荐选项 = `<SKILL_REPO_DIR>/output/`（skill 同目录）**，同时允许用户自定义输入；选定后创建目录并写入记忆文件。
- 之后执行直接读取沿用，不再重复询问；用户明确要求更换时重新询问并覆盖记忆文件。
- 子目录规则：`选题名_日期`（日期格式 YYYYMMDD，不含时分秒）；同选题再次修改在原子目录内覆盖更新，禁止另建新时间戳子目录。
- 禁止：硬编码落盘目录、首次未经交互确认即落盘、把中间产物（渲染脚本/html/temp）留在落盘子目录、把运行记忆或任何产物提交/推送到仓库。

## 版本自检与打包完整性实施细则

- **仓库**：`https://github.com/Keyway-tech/redbook-post-gen.git`（分支 main）。`<SKILL_REPO_DIR>` = 本项目 SKILL.md 所在目录，运行时解析。
- **执行**：`git -C <SKILL_REPO_DIR> pull --ff-only`。仅快进合并，不重写历史；合并会同步刷新 `skills/` 内打包的依赖。
- **无 Git / 无远端兜底**：WebFetch `https://raw.githubusercontent.com/Keyway-tech/redbook-post-gen/main/SKILL.md`，与本地逐行比对；发现差异即判定过期并中止。
- **打包完整性校验**（每次执行首步一并完成）：确认以下九处均存在，否则按依赖失败中止：
  - `skills/dbs-goal/SKILL.md`
  - `skills/dbs-content/SKILL.md`
  - `skills/dbs-deconstruct/SKILL.md`
  - `skills/dbs-xhs-title/SKILL.md`
  - `skills/dbs-hook/SKILL.md`
  - `skills/xhs-copywriter/SKILL.md`
  - `skills/dbs-resonate/SKILL.md`
  - `skills/dbs-ai-check/SKILL.md`
  - `skills/guizang-social-card-skill/SKILL.md` 及其 `assets/`、`references/`、`scripts/`
- **中止条件（任一即触发）**：pull 报错、本地有未提交改动（fast-forward 受阻）、网络不可达、远程 HEAD 与本地不一致、打包目录/文件缺失。
- **中止动作**：停止后续所有命令与依赖调用，向用户报告具体原因；待用户解决（提交改动 / 连通网络 / 合并更新 / 补全 skills/）后再启动。
