# redbook-post-gen

简体中文

> 面向小红书创作者的自包含 AI 图文帖生成 skill。把选题、文案与轮播图交给 Agent，获得可直接发布的下一步。

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-CC%20BY--NC%204.0-green)

支持：豆包、WorkBuddy、Claude Code、Codex，以及其他支持 Skills 的 Agent。

## 功能介绍

- 自包含的小红书（Rednote）图文帖生成 skill。
- 主 skill 只负责**流程编排、信息收集、信息传递与最终落盘**；目标澄清、切入角度诊断、概念拆解、标题、开场钩子、写稿、共鸣诊断、AI 写作特征检测、出图等全部专业产出，均由原样打包在 `skills/` 内的依赖完成。
- 内置 11 步编排流程：目标澄清 → 切入角度诊断 → 核心概念拆解 → 标题生成 → 开场钩子 → 写稿 → 共鸣诊断 → AI 写作特征检测 → 出图 → 落盘。
- 完全自包含，可独立拷贝到其他电脑运行，不引用宿主机器已安装的 skill。
- 强制版本自检、环境自检与打包完整性校验；任一依赖失败即中止，不回退默认方案。

## 用法

1. 克隆仓库：

   ```bash
   git clone https://github.com/Keyway-tech/redbook-post-gen.git
   ```

2. 在支持 skill 的 agent（如 CodeBuddy / Claude）中加载本目录作为 skill。
3. 向 agent 描述你的发帖想法，主 skill 会按 11 步流程驱动各依赖，完成从选题到出图的全过程。
4. 首次运行会自动交互确认落盘目录，并检测 / 预装出图所需的 Playwright 与 Chromium（需联网）。

## 引用声明

- `dbs-*` 系列依赖（dbs-goal / dbs-content / dbs-deconstruct / dbs-xhs-title / dbs-hook / dbs-resonate / dbs-ai-check）源自 dontbesilent 工具箱，版权归其原作者所有。
- `guizang-social-card-skill`（小红书 3:4 轮播卡出图）沿用其自带 `LICENSE`（ISC）与 `COMMERCIAL_LICENSING.md`。
- `xhs-copywriter`（专职写稿）为本项目新增组件。
- 任何形式引用、借鉴或搬运本项目，均须注明出处 `Keyway-tech/redbook-post-gen`。

## 特殊说明

- 运行期产生的记忆与成稿（`.local/`、`output/`）不随仓库分发，已列入 `.gitignore`，禁止上传。
- 主 skill 不亲自写稿、出图或做诊断；专业内容一律由打包依赖产出。
- 出图依赖 Playwright + Chromium，首次运行自动安装，需联网且可能依赖系统库。
- 依赖失败（含环境 / 版本 / 打包不完整）一律中止并报告，不会静默降级或用替代方案。

## 开源协议

本项目采用 [Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/)（CC BY-NC 4.0）发布：

- **开源**：允许非商业性的学习、研究、个人使用。
- **禁止商用**：未经授权不得用于任何商业目的。
- **搬运必须注明出处**：任何形式的复制、转发、二次发布或衍生，均须清晰标注来源 `Keyway-tech/redbook-post-gen`，并保留本声明。
- 各依赖组件保留其各自的原始许可（如 `guizang-social-card-skill` 的 ISC），使用时须一并遵守。

完整协议文本见 [LICENSE](./LICENSE) 文件。
