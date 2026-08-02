# redbook-post-gen

简体中文

> 面向小红书创作者的 AI 图文帖生成 skill。把选题思路交给 Agent，经过热搜词采集、选题诊断、实证检索、写稿、审稿循环与出图，获得可直接发布的成稿与轮播图。专业依赖按需安装在本机 agent skills 目录，缺失自动拉取、过期自动更新。

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![License](https://img.shields.io/badge/license-CC%20BY--NC%204.0-green)

支持：豆包、WorkBuddy、Claude Code、Codex，以及其他支持 Skills 的 Agent。

## 功能介绍

- 小红书（Rednote）图文帖生成 skill，专业依赖不随仓库打包，安装在本机 agent skills 目录（`~/.workbuddy/skills/`），跨项目共享。
- 主 skill 只负责**流程控制、信息传递与最终结果输出**；热搜词采集、选题与写稿方向诊断、钩子生成、实证检索、写稿、审稿、出图，均由依赖 skill 按其内部规范完成。
- 内置 14 步编排流程：信息收集（选题思路 + 人群画像 + 图文贴目的）→ 热搜词采集（5–10 个）→ 选题 / 写稿方向 / 钩子产出 → 用户三点确认 → 实证数据检索（标注来源）→ 初稿撰写 → 审稿循环（dbs-resonate 审、content-deai-engine 改）→ 用户确认循环 → 图文卡出图（风格可选）→ 落盘。
- 每次任务开始前强制完整环境检测：依赖缺失自动安装到全局 skills 目录、git 类依赖过期自动更新到上游最新、深度依赖（Playwright + Chromium）缺失自修复安装、解析路径记录到 `.deps-cache/deps.json`；主机运行时（Node.js 等）缺失自动安装到本机全局目录并自动更新。检测失败即中止，禁止跳过、禁止降级。
- 所有向用户的提问均为纯文本：每次一个问题、编号选项、无多余输出（不使用交互式弹窗）。

## 依赖（9 个）

| 依赖 | 用途 | 来源 |
|---|---|---|
| xhs-real-keywords | 小红书热搜词采集（浏览器自动化，免费无 API，带来源证据） | `lsuyu899-tech/xhs-real-keywords` |
| dbs-content | 选题梳理与写稿方向诊断 | `dontbesilent2025/dbskill` |
| dbs-hook | 钩子生成 | `dontbesilent2025/dbskill` |
| multi-search-engine | 实证数据检索（16 引擎，无 API） | 本机已装 |
| content-deai-engine | 写稿与修订 | `lanyasheng/content-deai-engine` |
| dbs-resonate | 审稿（共鸣诊断，输出明确修改方向） | `dontbesilent2025/dbskill` |
| guizang-social-card-skill | 图文卡出图（Editorial Magazine × E-ink 图文混排 / Swiss International） | `op7418/guizang-social-card-skill` |

## 用法

1. 克隆仓库：

   ```bash
   git clone https://github.com/Keyway-tech/redbook-post-gen.git
   ```

2. 安装依赖：在本仓库根目录运行 `bash ensure_deps.sh`，自动把 9 个依赖 skill 安装 / 更新到本机全局 skills 目录（`~/.workbuddy/skills/`）并记录路径到 `.deps-cache/deps.json`；首次克隆或拉取更新后建议运行一次。
3. 在支持 skill 的 agent（如 WorkBuddy / Claude Code）中加载本目录作为 skill。
4. 向 agent 描述你的发帖选题思路（可附配图）。主 skill 会先运行完整环境检测（依赖安装 / 更新 / 记录、主机运行时检测），再按 14 步流程驱动各依赖：缺失的关键信息（人群画像、图文贴目的）会每次一个问题向你补齐。
5. 出图前可选择风格（Editorial Magazine × E-ink 电子杂志图文混排 / Swiss International 瑞士国际主义，及各自主题色）；配图可自备，也可由出图 skill 按流程询问后网络取图或 AI 生成。
6. 落盘前会询问存放位置，默认 `output/<最终标题_日期>/`（skill 内部），产物为最终稿 md + 卡片 PNG。

## 引用声明

- `dbs-content` / `dbs-hook` / `dbs-resonate` 源自 dontbesilent 工具箱，版权归其原作者所有。
- `guizang-social-card-skill`（小红书 3:4 轮播卡出图）沿用其自带 `LICENSE`（ISC）与 `COMMERCIAL_LICENSING.md`。
- `xhs-real-keywords`（小红书热搜词采集，带来源证据）源自 lsuyu899-tech/xhs-real-keywords，MIT License。
- `content-deai-engine`（去 AI 味写稿）源自 lanyasheng/content-deai-engine。
- `multi-search-engine`（多引擎检索聚合）MIT License。
- 任何形式引用、借鉴或搬运本项目，均须注明出处 `Keyway-tech/redbook-post-gen`。

## 特殊说明

- 运行期产生的记录与成稿（`.deps-cache/`、`output/`）不随仓库分发，已列入 `.gitignore`，禁止上传。
- 主 skill 不亲自写稿、审稿、出图或做诊断；专业内容一律由本机 agent skills 目录中的依赖产出。
- 出图依赖 Playwright + Chromium，环境检测时自动校验与安装，需联网且可能依赖系统库。
- 依赖失败（含环境 / 依赖未安装且无法安装 / 更新失败）一律中止并报告，不会静默降级或用替代方案。

## 开源协议

本项目采用 [Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/)（CC BY-NC 4.0）发布：

- **开源**：允许非商业性的学习、研究、个人使用。
- **禁止商用**：未经授权不得用于任何商业目的。
- **搬运必须注明出处**：任何形式的复制、转发、二次发布或衍生，均须清晰标注来源 `Keyway-tech/redbook-post-gen`，并保留本声明。
- 各依赖组件保留其各自的原始许可（如 `guizang-social-card-skill` 的 ISC），使用时须一并遵守。

完整协议文本见 [LICENSE](./LICENSE) 文件。
