#!/usr/bin/env bash
# redbook-post-gen 依赖环境检查脚本（增强版）
# 职责：
#   1) 检查并安装本机 agent skills 目录（~/.workbuddy/skills/）下的各依赖 skill；
#   2) 校验每个依赖的【深度依赖】（运行时前置，如浏览器自动化 Playwright+Chromium）；
#   3) 校验每个依赖是否【最新】（git 类依赖对比上游 HEAD，过期则自动快进到最新）；
#   4) 把解析路径、状态、commit、深度依赖结果写入 .deps-cache/deps.json。
# 健壮性：
#   - 所有网络调用均受超时约束（见下方常量），超时即中止该调用并说明原因+修复方案，不无限挂起；
#   - 克隆/拉取等可重试操作受 MAX_RETRY 计次限制，达上限仍失败则报告原因并中止；
#   - 诊断信息走 stderr，不污染命令的标准输出（数据通道）。
# 调用：bash <SKILL_REPO_DIR>/ensure_deps.sh
set -uo pipefail

SKILLS_DIR="$HOME/.workbuddy/skills"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="$SCRIPT_DIR/.deps-cache"
DEPS_JSON="$STATE_DIR/deps.json"
COMMITS_DIR="$STATE_DIR/.dep_commits"
mkdir -p "$SKILLS_DIR" "$STATE_DIR" "$COMMITS_DIR"

# ---- 超时与重试常量（秒 / 次数）----
# 取值基准：本运行环境到 GitHub 的 git 操作实测延迟约 1–2 分钟，故 git 类超时留 3 分钟余量以允许慢连接成功完成，
# 仅用于斩断真正的死挂（无响应），而非惩罚慢网络。PLAYWRIGHT 安装含 Chromium 大体积下载，给 15 分钟。
GIT_TIMEOUT=180         # git ls-remote 探测上游
CLONE_TIMEOUT=300       # git clone --depth 1
FETCH_TIMEOUT=180       # git fetch / reset 更新
NPM_TIMEOUT=60          # npm view 版本探测
PLAYWRIGHT_TIMEOUT=900  # npm install playwright / npx playwright install chromium
MAX_RETRY=2             # 克隆、拉取的最大重试次数（含首次）

# ---- 依赖表：name|git_url|subpath(可选) ----
# 与 SKILL.md「环境检测」、references/dependencies.md 三处一致，改动须同步。
# 格式说明：
#   name|url                       -> 独立仓库，整仓克隆到 ~/.workbuddy/skills/<name>（目标为 git 仓库，可 pull 更新）
#   name|url|subpath               -> monorepo，克隆一次后复制子路径 subpath（目标非 git 仓库，更新靠重新复制）
#   name|                          -> 无来源（本机已装），缺失时仅记 missing-optional，不自动克隆
# dbs 系列（dbs-content 选题与写稿方向 / dbs-hook 钩子 / dbs-xhs-title 标题 / dbs-resonate 共鸣审稿）共享同一 monorepo（dontbesilent2025/dbskill），克隆一次后按名复制子目录。
# guizang 为独立仓库，整仓克隆（目标为 git 仓库，保留 node_modules/playwright）。
# content-deai-engine 为独立仓库（lanyasheng/content-deai-engine），整仓克隆。
# xiaohongshu-keyword-collector 来自 openlark/skills monorepo 子路径 skills/xiaohongshu-keyword-collector。
# multi-search-engine 为本机已装的多引擎网页检索聚合 skill（无自动 clone 来源，可选，缺失不阻塞）。
# no-ai-slop 为独立仓库（petergyang/no-ai-slop），整仓克隆；步骤 11 去 AI 味专责。
DEPS=(
  "dbs-content|https://github.com/dontbesilent2025/dbskill.git"
  "dbs-hook|https://github.com/dontbesilent2025/dbskill.git"
  "dbs-xhs-title|https://github.com/dontbesilent2025/dbskill.git"
  "dbs-resonate|https://github.com/dontbesilent2025/dbskill.git"
  "guizang-social-card-skill|https://github.com/op7418/guizang-social-card-skill.git"
  "content-deai-engine|https://github.com/lanyasheng/content-deai-engine.git"
  "xiaohongshu-keyword-collector|https://github.com/openlark/skills.git|skills/xiaohongshu-keyword-collector"
  "no-ai-slop|https://github.com/petergyang/no-ai-slop.git"
  "multi-search-engine|"
)

# 可选依赖（缺失不阻塞主流程）：
OPTIONAL="multi-search-engine"

# 深度依赖映射：name -> 空格分隔的深度依赖键（见下方 check_<key> 函数）
deep_deps_of() {
  case "$1" in
    guizang-social-card-skill|xiaohongshu-keyword-collector) echo "playwright" ;;
    *) echo "" ;;
  esac
}

is_optional() { [[ " $OPTIONAL " == *" $1 "* ]]; }

# 存储每依赖安装 commit（仅 copied 类需要；gitrepo 类直接读 .git）
store_commit() { echo "$2" > "$COMMITS_DIR/$1"; }
get_stored_commit() { [ -f "$COMMITS_DIR/$1" ] && cat "$COMMITS_DIR/$1" || echo ""; }

# ---- 超时执行：run_timeout <secs> <cmdstring>
#   返回 0=成功(标准输出到 stdout) / 2=超时 / 1=其他失败
#   优先用 GNU `timeout`；不可用时降级为「后台进程 + kill」兜底（仍受 secs 约束）。
run_timeout() {
  local secs="$1" cmd="$2" tmp rc=0
  tmp="$(mktemp)"
  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs" bash -c "$cmd" >"$tmp" 2>&1
    rc=$?
  else
    bash -c "$cmd" >"$tmp" 2>&1 &
    local pid=$! waited=0
    while kill -0 "$pid" 2>/dev/null; do
      sleep 1; waited=$((waited+1))
      if [ "$waited" -ge "$secs" ]; then
        kill "$pid" 2>/dev/null; sleep 1; kill -9 "$pid" 2>/dev/null
        rc=124; break
      fi
    done
    if [ "$rc" -ne 124 ]; then wait "$pid"; rc=$?; fi
  fi
  if [ "$rc" -eq 124 ]; then rm -f "$tmp"; return 2; fi
  if [ "$rc" -ne 0 ]; then rm -f "$tmp"; return 1; fi
  cat "$tmp"; rm -f "$tmp"; return 0
}

# ---- 网络操作封装：net_op <secs> <label> <cause> <fix> <cmdstring>
#   成功则返回命令标准输出、rc=0；超时则 rc=2 并向 stderr 打印「原因 + 修复」；
#   其他失败 rc=1（不打印，交由调用方按场景处理，必要时自行补充提示）。
net_op() {
  local secs="$1" label="$2" cause="$3" fix="$4" cmd="$5"
  local out rc
  out="$(run_timeout "$secs" "$cmd")"; rc=$?
  if [ "$rc" -eq 2 ]; then
    echo "   ⏱️ [$label] 超时(${secs}s)：$cause" >&2
    echo "      🔧 修复：$fix" >&2
  fi
  printf '%s' "$out"
  return "$rc"
}

# ---- 上游最新 commit 缓存（按 url） ----
declare -A UPSTREAM_CACHE
upstream_commit() {
  local url="$1"
  if [ -n "${UPSTREAM_CACHE[$url]+x}" ]; then echo "${UPSTREAM_CACHE[$url]}"; return; fi
  local branch
  branch="$(net_op "$GIT_TIMEOUT" "ls-remote:${url##*/}" \
    "无法在 ${GIT_TIMEOUT}s 内连接 $url 获取默认分支（网络慢 / 代理拦截 / 离线）" \
    "检查网络与代理连通性；或先手动 git clone 该仓库，再运行 ensure_deps.sh" \
    "git ls-remote --symref '$url' HEAD 2>/dev/null | sed -n 's#^ref: refs/heads/\([^[:space:]]*\).*#\1#p' | head -1")"
  [ -z "$branch" ] && branch="main"
  local commit
  commit="$(net_op "$GIT_TIMEOUT" "ls-remote-commit:${url##*/}" \
    "无法在 ${GIT_TIMEOUT}s 内连接 $url 获取最新 commit" \
    "检查网络；或稍后重试 ensure_deps.sh" \
    "git ls-remote '$url' 'refs/heads/$branch' 2>/dev/null | sed -n '1s#^\([0-9a-f]*\).*#\1#p'")"
  UPSTREAM_CACHE[$url]="$commit"
  echo "$commit"
}

# ---- monorepo 临时克隆（按 url 缓存，整个脚本生命周期只克隆一次） ----
declare -A MONO_TMP
TMP_DIRS=()
ensure_mono_tmp() {
  local url="$1" key="${url//[^A-Za-z0-9]/_}"
  if [ -n "${MONO_TMP[$key]+x}" ]; then echo "${MONO_TMP[$key]}"; return 0; fi
  local tmp rc i
  tmp="$(mktemp -d)"
  for ((i=1; i<=MAX_RETRY; i++)); do
    net_op "$CLONE_TIMEOUT" "clone:${url##*/}" \
      "克隆 $url 超时(${CLONE_TIMEOUT}s)，可能因网络慢 / 代理拦截" \
      "检查网络与代理；或手动执行：git clone --depth 1 $url $tmp" \
      "git clone --depth 1 '$url' '$tmp' >/dev/null 2>&1" >/dev/null
    rc=$?
    if [ "$rc" -eq 0 ] && [ -d "$tmp/.git" ]; then
      MONO_TMP[$key]="$tmp"; TMP_DIRS+=("$tmp"); echo "$tmp"; return 0
    fi
    if [ "$i" -lt "$MAX_RETRY" ]; then
      echo "   ↻ [clone:${url##*/}] 第 $i/$MAX_RETRY 次未成功（超时或失败），重试..."
    fi
  done
  echo "   ❌ [clone:${url##*/}] 已重试 $MAX_RETRY 次仍失败，请按上方修复建议处理" >&2
  rm -rf "$tmp" 2>/dev/null
  echo ""; return 1
}

cleanup() { for d in "${TMP_DIRS[@]:-}"; do [ -n "$d" ] && rm -rf "$d" 2>/dev/null; done; }
trap cleanup EXIT

# ---- 安装（缺失时） ----
ensure_present() {
  local name="$1" url="$2" subpath="$3" target="$SKILLS_DIR/$name"
  if [ -f "$target/SKILL.md" ]; then echo "present"; return; fi
  if [ -z "$url" ]; then echo "missing-no-source"; return; fi
  if [[ "$url" == *dbskill.git ]]; then
    local tmp; tmp="$(ensure_mono_tmp "$url")" || { echo "clone-fail"; return; }
    local src; src="$(find "$tmp" -maxdepth 6 -type d -name "$name" | head -1)"
    [ -z "$src" ] && { echo "subdir-notfound"; return; }
    cp -r "$src" "$target"
    store_commit "$name" "$(git -C "$tmp" rev-parse HEAD)"
  elif [ -n "$subpath" ]; then
    local tmp; tmp="$(ensure_mono_tmp "$url")" || { echo "clone-fail"; return; }
    local src="$tmp/$subpath"
    [ ! -d "$src" ] && { echo "subdir-notfound"; return; }
    cp -r "$src" "$target"
    store_commit "$name" "$(git -C "$tmp" rev-parse HEAD)"
  else
    local ok=0 rc i
    for ((i=1; i<=MAX_RETRY; i++)); do
      net_op "$CLONE_TIMEOUT" "clone:$name" \
        "克隆 $url 超时(${CLONE_TIMEOUT}s)" \
        "检查网络 / 代理；或手动 git clone --depth 1 $url $target" \
        "git clone --depth 1 '$url' '$target' >/dev/null 2>&1" >/dev/null
      rc=$?
      if [ "$rc" -eq 0 ] && [ -d "$target/.git" ]; then ok=1; break; fi
      if [ "$i" -lt "$MAX_RETRY" ]; then echo "   ↻ [clone:$name] 第 $i/$MAX_RETRY 次未成功，重试..."; fi
    done
    [ "$ok" -eq 1 ] || { echo "clone-fail"; return; }
  fi
  [ -f "$target/SKILL.md" ] && echo "installed" || echo "install-fail"
}

# ---- 更新（过期时）：gitrepo -> fetch+reset；copied -> 重新复制子路径 ----
update_dep() {
  local name="$1" url="$2" subpath="$3" target="$4"
  if [ -d "$target/.git" ]; then
    local branch; branch="$(git -C "$target" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    [ -z "$branch" ] && branch="main"
    net_op "$FETCH_TIMEOUT" "fetch:$name" \
      "拉取 $name 更新超时(${FETCH_TIMEOUT}s)" \
      "检查网络；或手动 cd $target && git fetch origin $branch" \
      "git -C '$target' fetch --depth 1 origin '$branch' >/dev/null 2>&1" >/dev/null
    [ "$?" -ne 0 ] && return 1
    net_op "$FETCH_TIMEOUT" "reset:$name" \
      "重置 $name 到最新超时(${FETCH_TIMEOUT}s)" \
      "手动 cd $target && git reset --hard origin/$branch" \
      "git -C '$target' reset --hard 'origin/$branch' >/dev/null 2>&1" >/dev/null
    [ "$?" -ne 0 ] && return 1
  elif [ -z "$subpath" ] && [[ "$url" != *dbskill.git ]]; then
    # 独立仓库但目标缺失 .git（非克隆方式安装，无法 fetch）：
    # 新鲜克隆上游后移植 .git 到目标，再 reset --hard 对齐到上游 HEAD
    # （node_modules 等未跟踪文件保留；目标中多出的文件变为未跟踪，不被删除）。
    local tmp2 rc2 i2
    tmp2="$(mktemp -d)"; TMP_DIRS+=("$tmp2")
    rc2=1
    for ((i2=1; i2<=MAX_RETRY; i2++)); do
      net_op "$CLONE_TIMEOUT" "clone:$name(git修复)" \
        "克隆 $url 超时(${CLONE_TIMEOUT}s)" \
        "检查网络 / 代理；或手动 git clone --depth 1 $url \"$tmp2/repo\" 后将其 .git 移入 $target 并 git reset --hard" \
        "git clone --depth 1 '$url' '$tmp2/repo' >/dev/null 2>&1" >/dev/null
      rc2=$?
      [ "$rc2" -eq 0 ] && [ -d "$tmp2/repo/.git" ] && break
      if [ "$i2" -lt "$MAX_RETRY" ]; then echo "   ↻ [clone:$name(git修复)] 第 $i2/$MAX_RETRY 次未成功，重试..."; fi
    done
    { [ "$rc2" -eq 0 ] && [ -d "$tmp2/repo/.git" ]; } || return 1
    mv "$tmp2/repo/.git" "$target/.git" || return 1
    rm -rf "$tmp2/repo"
    git -C "$target" reset --hard HEAD >/dev/null 2>&1 || return 1
  else
    local tmp; tmp="$(ensure_mono_tmp "$url")" || return 1
    local src
    if [ -n "$subpath" ]; then src="$tmp/$subpath"; else src="$(find "$tmp" -maxdepth 6 -type d -name "$name" | head -1)"; fi
    [ -z "$src" ] && return 1
    rm -rf "$target"
    cp -r "$src" "$target"
    store_commit "$name" "$(git -C "$tmp" rev-parse HEAD)"
  fi
}

local_commit() {
  local name="$1" target="$2"
  if [ -d "$target/.git" ]; then git -C "$target" rev-parse HEAD 2>/dev/null; else get_stored_commit "$name"; fi
}

# ============ 深度依赖检查函数 ============
# 返回值格式： ok(0|1)|detail|version
check_playwright() {
  local gdir="$SKILLS_DIR/guizang-social-card-skill"
  local ok=1 detail="" ver=""
  # 1) 模块解析
  if [ -d "$gdir/node_modules/playwright" ]; then
    detail="playwright 模块存在($gdir/node_modules)"
  elif node -e "require.resolve('playwright')" >/dev/null 2>&1; then
    detail="playwright 模块可全局解析"
  else
    detail="playwright 模块缺失，尝试安装"; ok=0
    net_op "$PLAYWRIGHT_TIMEOUT" "npm-install:playwright" \
      "安装 playwright 模块超时(${PLAYWRIGHT_TIMEOUT}s)" \
      "检查网络 / 代理与 npm 配置；或手动 cd $gdir && npm install playwright" \
      "cd '$gdir' && npm install --no-audit --no-fund playwright >/dev/null 2>&1" >/dev/null
    if [ "$?" -eq 0 ] && [ -d "$gdir/node_modules/playwright" ]; then
      detail="playwright 已安装($gdir/node_modules)"; ok=1
    else
      detail="playwright 安装失败(网络 / 权限 / 超时，见上方提示)"; ok=0
    fi
  fi
  # 2) 版本
  ver="$(cd "$gdir" 2>/dev/null && node -e "try{console.log(require('playwright/package.json').version)}catch(e){}" 2>/dev/null)"
  # 3) Chromium 二进制
  local chrome=""
  if [ -d "$gdir/node_modules/playwright" ] || node -e "require.resolve('playwright')" >/dev/null 2>&1; then
    chrome="$(cd "$gdir" 2>/dev/null && node -e "try{const{chromium}=require('playwright');console.log(chromium.executablePath())}catch(e){}" 2>/dev/null)"
  fi
  if [ -n "$chrome" ] && [ -f "$chrome" ]; then
    detail="$detail；Chromium 二进制存在"
  else
    detail="$detail；Chromium 缺失，尝试安装"; ok=0
    net_op "$PLAYWRIGHT_TIMEOUT" "playwright-install-chromium" \
      "安装 Chromium 超时(${PLAYWRIGHT_TIMEOUT}s)" \
      "检查网络与系统依赖(libusb 等)；或手动 cd $gdir && npx playwright install chromium" \
      "cd '$gdir' && npx playwright install chromium >/dev/null 2>&1" >/dev/null
    if [ "$?" -eq 0 ]; then
      chrome="$(cd "$gdir" 2>/dev/null && node -e "try{const{chromium}=require('playwright');console.log(chromium.executablePath())}catch(e){}" 2>/dev/null)"
      if [ -n "$chrome" ] && [ -f "$chrome" ]; then detail="$detail；Chromium 已安装"; ok=1; else detail="$detail；Chromium 安装后仍缺失(可能系统依赖缺失)"; ok=0; fi
    else
      detail="$detail；Chromium 安装失败(网络 / 系统依赖 / 超时)"; ok=0
    fi
  fi
  # 4) 最新性（软校验，仅提示，不阻塞）：对比 npm 上游版本
  if [ -n "$ver" ]; then
    local latest=""
    latest="$(net_op "$NPM_TIMEOUT" "npm-view:playwright" \
      "查询 playwright 上游版本超时(${NPM_TIMEOUT}s)" \
      "检查 npm 网络；或忽略此软提示" \
      "npm view playwright version 2>/dev/null")"
    if [ "$?" -eq 0 ] && [ -n "$latest" ] && [ "$latest" != "$ver" ]; then
      detail="$detail；注意 Playwright 上游最新为 $latest（当前 $ver，浏览器二进制未自动升级，如需升级请手动 npx playwright install chromium）"
    fi
  fi
  echo "$ok|$detail|$ver"
}

check_deepkey() {
  case "$1" in
    playwright) check_playwright ;;
    *) echo "0|未知深度依赖键: $1|" ;;
  esac
}

# ---- JSON 记录 ----
members=()
record() {
  local name="$1" path="$2" status="$3" ic="$4" lc="$5" stale="$6" deep="$7"
  local pjson; [ -n "$path" ] && pjson="\"$path\"" || pjson="null"
  local icj; [ -n "$ic" ] && icj="\"$ic\"" || icj="null"
  local lcj; [ -n "$lc" ] && lcj="\"$lc\"" || lcj="null"
  members+=("  \"$name\": {\"path\": $pjson, \"status\": \"$status\", \"installed_commit\": $icj, \"latest_commit\": $lcj, \"stale\": $stale, \"deep_deps\": $deep}")
}

# ---- 主流程 ----
fails=0
echo "== 依赖环境检查 (redbook-post-gen) · 含深度依赖与最新性强制校验 =="
echo "   （超时约束：git 探测 ${GIT_TIMEOUT}s / 克隆 ${CLONE_TIMEOUT}s / 拉取 ${FETCH_TIMEOUT}s / npm ${NPM_TIMEOUT}s / playwright ${PLAYWRIGHT_TIMEOUT}s；克隆与拉取重试 ≤${MAX_RETRY} 次）"
for entry in "${DEPS[@]}"; do
  IFS='|' read -r name url subpath <<< "$entry"
  target="$SKILLS_DIR/$name"

  # 1) 存在性
  status="$(ensure_present "$name" "$url" "$subpath")"
  if [ "$status" = "present" ] || [ "$status" = "installed" ]; then
    echo "✅ 已就绪: $name ($( [ "$status" = installed ] && echo 本次安装 || echo 已存在))"
  elif [ "$status" = "missing-no-source" ]; then
    if is_optional "$name"; then echo "⚠️ 可选依赖缺失(无来源，跳过): $name"; record "$name" "" "missing-optional" "" "" "false" "{}"; continue; fi
    echo "❌ 依赖缺失且无来源: $name"; fails=$((fails+1)); record "$name" "" "missing-no-source" "" "" "false" "{}"; continue
  else
    echo "❌ 依赖安装失败($status): $name"; fails=$((fails+1)); record "$name" "" "install-fail" "" "" "false" "{}"; continue
  fi

  # 2) 最新性（git 类依赖）
  local_commit_val="$(local_commit "$name" "$target")"
  upstream=""
  [ -n "$url" ] && upstream="$(upstream_commit "$url")"
  stale="false"
  if [ -n "$url" ] && [ -n "$upstream" ] && [ -z "$local_commit_val" ]; then
    # 本地无版本记录（非克隆方式安装 / 记录丢失）且上游可达：
    # 记录上游 HEAD 为基线 commit（不改动任何文件），后续上游 HEAD 变更将据此触发自动更新。
    store_commit "$name" "$upstream"
    local_commit_val="$upstream"
    echo "   ℹ️ $name 本地版本未知，已记录基线 commit ${upstream:0:8}（不改动文件；后续上游变更将触发自动更新）"
  elif [ -n "$upstream" ] && [ -n "$local_commit_val" ] && [ "$upstream" != "$local_commit_val" ]; then
    stale="true"
    echo "   ↻ $name 非最新(本地 ${local_commit_val:0:8} / 上游 ${upstream:0:8})，自动更新到最新..."
    if update_dep "$name" "$url" "$subpath" "$target"; then
      local_commit_val="$(local_commit "$name" "$target")"
      echo "   ✅ $name 已更新至 ${local_commit_val:0:8}"
    else
      echo "   ❌ $name 更新失败"; fails=$((fails+1))
    fi
  elif [ -z "$upstream" ]; then
    echo "   ⚠️ $name 无法连接上游校验最新性（超时/离线，跳过更新，不阻塞）"
  else
    echo "   ✅ $name 已是最新(${local_commit_val:0:8})"
  fi

  # 3) 深度依赖
  deepkeys="$(deep_deps_of "$name")"
  deep_frags=()
  if [ -n "$deepkeys" ]; then
    for dk in $deepkeys; do
      res="$(check_deepkey "$dk")"
      IFS='|' read -r dok ddetail dver <<< "$res"
      ddetail_esc="${ddetail//\"/\\\"}"
      okb="false"; [ "$dok" = "1" ] && okb="true"
      verj=""; [ -n "$dver" ] && verj="\"$dver\"" || verj="null"
      if [ "$dok" = "0" ]; then echo "   ❌ 深度依赖缺失: $name -> $dk ($ddetail)"; fails=$((fails+1)); fi
      deep_frags+=("\"$dk\": {\"ok\": $okb, \"detail\": \"$ddetail_esc\", \"version\": $verj}")
    done
  fi
  if [ ${#deep_frags[@]} -gt 0 ]; then deepjson="{$(IFS=,; echo "${deep_frags[*]}")}"; else deepjson="{}"; fi

  record "$name" "$target" "$status" "$local_commit_val" "$upstream" "$stale" "$deepjson"
done

# ---- 写出 deps.json ----
{
  echo "{"
  echo "  \"_generated\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
  echo "  \"skills_dir\": \"$SKILLS_DIR\","
  echo "  \"timeout_model\": \"git 探测 ${GIT_TIMEOUT}s / 克隆 ${CLONE_TIMEOUT}s / 拉取 ${FETCH_TIMEOUT}s / npm ${NPM_TIMEOUT}s / playwright ${PLAYWRIGHT_TIMEOUT}s；克隆与拉取重试 ≤${MAX_RETRY} 次。超时即中止该调用并打印原因+修复，不无限挂起。\","
  echo "  \"deep_dep_model\": \"每个依赖的深度依赖(如 playwright 覆盖 guizang 与 xiaohongshu-keyword-collector)在首步强制校验存在性(缺失则尝试自修复安装，失败即中止)；git 类依赖对比上游 HEAD，过期自动快进到最新；浏览器二进制最新性仅软提示。\","
  printf '%s' "${members[0]}"
  for ((i=1;i<${#members[@]};i++)); do printf ',\n%s' "${members[$i]}"; done
  echo ""
  echo "}"
} > "$DEPS_JSON"

echo "== 依赖路径与状态已记录到 $DEPS_JSON =="
if [ "$fails" -gt 0 ]; then
  echo "❌ 存在 $fails 项校验失败，已中止后续流程（见上方 ❌ 项）"
  exit 1
fi
echo "✅ 全部依赖（含深度依赖）校验通过"
