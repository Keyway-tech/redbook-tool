# redbook-post-gen

自包含的小红书（Rednote / 小红书）图文帖生成 skill。主 skill 只做**流程编排、信息收集、信息传递与最终落盘**；一切专业产出（目标澄清、角度诊断、概念拆解、标题、钩子、写稿、共鸣诊断、AI 特征检测、出图）均由原样打包在本项目 `skills/` 内的专业依赖完成。

## 特性

- **完全自包含**：所有依赖 skill / 模板 / 脚本 / 资源均已打包于 `skills/`，可独立拷贝到其他电脑运行，不引用宿主机器上已安装的版本。
- **主 skill 纯编排**：不亲自写稿、出图或诊断；专业内容一律由打包依赖产出。
- **11 步编排流程**：目标澄清 → 角度诊断 → 概念拆解 → 标题 → 钩子 → 写稿 → 共鸣诊断 → AI 特征检测 → 出图 → 落盘。
- **强制自检**：版本自检（git pull / WebFetch 兜底）、环境自检（Node≥18、Playwright+Chromium、git、网络）、打包完整性校验；任一失败即中止，不回退默认。
- **产物隔离**：运行记忆与成稿写入 `.local/`、`output/`，均列入 `.gitignore`，禁止上传仓库。

## 目录结构

```
redbook-post-gen/
├── SKILL.md                        # 主 skill：职责边界 / 自检 / 11 步命令 / 依赖来源
├── references/
│   └── dependencies.md             # 各依赖的传入/接收/禁干预点、自检与隔离细则
├── .gitignore                      # 隔离运行记忆与产物
└── skills/                         # 全部依赖，原样打包
    ├── dbs-goal/                   # 目标澄清（第 1 步介入）
    ├── dbs-content/                # 切入角度诊断
    ├── dbs-deconstruct/            # 核心概念拆解
    ├── dbs-xhs-title/              # ≤20 字标题公式
    ├── dbs-hook/                   # 开场钩子
    ├── xhs-copywriter/             # 专职写稿（信息包 → 五段结构）
    ├── dbs-resonate/               # 共鸣诊断
    ├── dbs-ai-check/               # AI 写作特征检测
    └── guizang-social-card-skill/  # 3:4 轮播卡出图（含 assets/ references/ scripts/）
```

## 使用方式

1. 克隆仓库到任意机器：

   ```bash
   git clone https://github.com/Keyway-tech/redbook-post-gen.git
   ```

2. 在支持 skill 的 agent（如 CodeBuddy / Claude）中加载本目录作为 skill。
3. 描述你的发帖想法，主 skill 会按 11 步流程驱动各依赖，完成从选题到出图的全过程。
4. 首次运行会自动：交互确认落盘目录、检测并预装 guizang 的 Playwright / Chromium（需网络）。

## 环境要求

- Node.js ≥ 18
- Playwright + Chromium 浏览器二进制（首次运行自动 `npm install` + `playwright install chromium`）
- git（用于版本自检；缺失时走 WebFetch 比对兜底）
- 可访问 `raw.githubusercontent.com`（版本比对、取图）

## 许可

- `skills/guizang-social-card-skill/` 沿用其自带 `LICENSE`（ISC）及 `COMMERCIAL_LICENSING.md`。
- `dbs-*` 系列依赖源自 dontbesilent 工具箱；`xhs-copywriter` 为本项目新增。
- 运行产物与记忆不随仓库分发。
