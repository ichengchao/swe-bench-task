# swe-bench-task

SWE-bench 评估任务定义和工具集。配合 mock 项目 [swe-bench-test](https://github.com/ichengchao/swe-bench-test) 使用。

## 项目结构

```
.
├── swe_task.json                          # SWE-bench 格式的 task 定义
├── swe_task_spec.md                       # swe_task.json 字段说明文档
├── mini_swe_agent.py                      # 自定义 mini SWE agent (DashScope)
├── dashscope_config.yaml                  # 官方 mini-swe-agent 的 DashScope 配置
└── tasks/                                 # Harbor 格式的 task
    └── ichengchao__swe-bench-test-1/
        ├── task.toml                      # 任务元数据
        ├── instruction.md                 # 问题描述 (agent 输入)
        ├── environment/
        │   └── Dockerfile                 # 构建 buggy 环境
        ├── solution/
        │   └── solve.sh                   # gold patch 修复脚本
        └── tests/
            └── test.sh                    # 验证脚本 (FAIL_TO_PASS + PASS_TO_PASS)
```

## Task 说明

目标仓库：[ichengchao/swe-bench-test](https://github.com/ichengchao/swe-bench-test)

Bug：`fibonacci(0)` 返回 `1` 而不是 `0`（Issue [#1](https://github.com/ichengchao/swe-bench-test/issues/1)）

详细的字段说明见 [swe_task_spec.md](swe_task_spec.md)。

## 使用方式

### 方式一：官方 mini-swe-agent (推荐)

[mini-swe-agent](https://github.com/SWE-agent/mini-swe-agent) 是 SWE-agent 团队的官方极简 agent，约 100 行代码，SWE-bench verified 得分超 74%。

#### 1. 安装

```bash
pip install uv   # 如果还没有 uv
```

#### 2. 克隆目标仓库

```bash
git clone https://github.com/ichengchao/swe-bench-test.git
cd swe-bench-test
```

#### 3. 配置 DashScope

编辑 `dashscope_config.yaml`，填入你的 API key：

```yaml
model:
  model_name: "openai/qwen-plus"
  model_class: "litellm"
  model_kwargs:
    api_base: "https://dashscope.aliyuncs.com/compatible-mode/v1"
    api_key: "sk-your-dashscope-key"
  cost_tracking: "ignore_errors"

agent:
  step_limit: 30
```

#### 4. Checkout 到 buggy commit

```bash
git checkout 932468602d3778403ec173ca7a1151d329c9e027
```

#### 5. 运行 agent

```bash
export MSWEA_CONFIGURED=1

uvx mini-swe-agent \
  -m "openai/qwen-plus" \
  -c mini.yaml \
  -c /path/to/dashscope_config.yaml \
  -t "fibonacci(0) returns 1 instead of 0. The bug is in mathutils/core.py. Fix it so that tests/test_core.py::TestFibonacci::test_zero passes." \
  -y \
  --exit-immediately \
  --agent-class default \
  -o agent_output.json
```

参数说明：
- `-m`: 模型名称 (需要带 `openai/` 前缀)
- `-c mini.yaml`: 加载默认配置
- `-c dashscope_config.yaml`: 覆盖模型配置为 DashScope
- `-t`: 问题描述 (即 problem_statement)
- `-y`: 跳过确认提示
- `--agent-class default`: 使用非交互 agent (适合脚本/CI 环境)
- `--exit-immediately`: agent 完成后自动退出
- `-o`: 输出 trajectory 文件路径

#### 6. 验证修复

```bash
python3 -m pytest tests/test_core.py -v
```

#### 7. 恢复仓库

```bash
git checkout . && git checkout master
```

### 方式二：自定义 mini SWE agent

`mini_swe_agent.py` 是一个自定义的简易 agent，直接读取 `swe_task.json` 并自动完成整个流程。

#### 1. 安装依赖

```bash
pip3 install openai pytest
```

#### 2. 将 swe_task.json 复制到目标仓库并运行

```bash
cp swe_task.json /path/to/swe-bench-test/
cp mini_swe_agent.py /path/to/swe-bench-test/
cd /path/to/swe-bench-test

export DASHSCOPE_API_KEY="sk-your-dashscope-key"
python3 mini_swe_agent.py swe_task.json
```

执行流程：
1. 读取 task JSON
2. Checkout 到 buggy commit
3. 验证 FAIL_TO_PASS 测试确实失败
4. 将代码和问题描述发给 LLM，生成修复 patch
5. Apply patch (支持多种 fallback 策略)
6. 运行 FAIL_TO_PASS 测试 (应通过)
7. 运行 PASS_TO_PASS 测试 (无回归)
8. 输出结果：RESOLVED 或 FAILED

### 方式三：手动验证 (用 gold patch)

不依赖任何 agent，直接用 `swe_task.json` 中的 gold patch 验证整个评估流程。

```bash
cd /path/to/swe-bench-test

# 1. Checkout 到 buggy commit
git checkout 932468602d3778403ec173ca7a1151d329c9e027

# 2. 确认 FAIL_TO_PASS 测试失败
python3 -m pytest tests/test_core.py::TestFibonacci::test_zero -v
# 预期输出: FAILED - assert 1 == 0

# 3. 从 swe_task.json 中提取 patch 并保存为文件
python3 -c "
import json
with open('swe_task.json') as f:
    task = json.load(f)[0]
with open('gold_patch.diff', 'w') as f:
    f.write(task['patch'])
"

# 4. 应用 gold patch (只修改文件，不产生 commit)
git apply gold_patch.diff

# 5. 验证 FAIL_TO_PASS 测试通过
python3 -m pytest tests/test_core.py::TestFibonacci::test_zero -v
# 预期输出: PASSED

# 6. 验证 PASS_TO_PASS 无回归
python3 -m pytest tests/test_core.py -v
# 预期输出: 19 passed

# 7. 恢复仓库
rm -f gold_patch.diff
git checkout . && git checkout master
```

## SWE-bench vs Harbor 格式对比

| SWE-bench (JSON) | Harbor (目录) | 说明 |
|---|---|---|
| `instance_id` | 目录名 + `task.toml` | 任务标识 |
| `problem_statement` | `instruction.md` | agent 看到的输入 |
| `base_commit` | `Dockerfile` 中 git checkout | 构建 buggy 环境 |
| `patch` | `solution/solve.sh` | gold patch 修复脚本 |
| `FAIL_TO_PASS` + `PASS_TO_PASS` | `tests/test.sh` | 验证修复 + 无回归 |
| `test_patch` | `tests/test.patch` | 额外测试补丁（本例为空） |

## 如何创建新的 task

1. 在 [swe-bench-test](https://github.com/ichengchao/swe-bench-test) 中引入新 bug 并 commit
2. 记录 buggy commit SHA
3. 创建 GitHub Issue 描述问题
4. 修复 bug 并 commit，记录 patch diff
5. 在 `swe_task.json` 中添加新的 task 实例
6. 在 `tasks/` 下创建对应的 Harbor 格式目录
7. 用 agent 跑一遍验证
