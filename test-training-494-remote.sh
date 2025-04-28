#!/bin/bash
set -exu

# This script copies the steps at https://github.com/instructlab/training/blob/main/.github/workflows/e2e-nvidia-l40s-x4.yml
# In order to reproduce the e2e failures we saw at https://github.com/instructlab/training/issues/494
#
# Requires tokens:
#   https://huggingface.co/settings/tokens
#   https://platform.openai.com/settings/organization/api-keys
# This sanity-checks that you've set these variables before starting:
echo $HF_TOKEN > /dev/null
echo $OPENAI_API_KEY > /dev/null

export TMPDIR=/home/tmp

setup() {
    sudo dnf install -y gcc gcc-c++ make git python3.11 python3.11-devel

    git clone https://github.com/instructlab/instructlab
    git clone https://github.com/instructlab/training

    sudo dnf install 'dnf-command(config-manager)' -y
    sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
    sudo dnf install gh --repo gh-cli -y

    gh --version

    # This part requires GITHUB_TOKEN, and it's only necessary for checking out
    # PRs and adding comments to them. Skip this step for now.
    # pushd training
    #   gh repo set-default https://github.com/instructlab/training
    # popd
}

setup

install_ilab() {
    pushd $HOME/instructlab
    export CUDA_HOME="/usr/local/cuda"
    export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"
    export PATH="$PATH:$CUDA_HOME/bin"
    python3.11 -m venv --upgrade-deps venv
    . venv/bin/activate
    nvidia-smi
    python3.11 -m pip cache remove llama_cpp_python

    CMAKE_ARGS="-DLLAMA_CUDA=on" python3.11 -m pip install . -c constraints-dev.txt

    # https://github.com/instructlab/instructlab/issues/1821
    # install with Torch and build dependencies installed
    python3.11 -m pip install packaging wheel setuptools-scm
    python3.11 -m pip install .[cuda] -r requirements-vllm-cuda.txt
    popd
}

install_ilab

update_training() {
    pushd $HOME/training
    . ../instructlab/venv/bin/activate
    pip install .
    pip install .[cuda]
    popd
}

update_training

# Check disks before
df -h

# Run e2e test
e2e_test() {
    pushd $HOME/instructlab
    . venv/bin/activate
    popd
    ./scripts/e2e-ci.sh -lp | tee e2e.log
    log_files=$(find /tmp/ -name "training_params_and_metrics_global0.jsonl")
    phase_num=1;
    for log_file in $log_files; do
        mv "${log_file}" phase-${phase_num}-training-log.jsonl
        ((phase_num++))
    done
}

e2e_test

# Check disks after test
df -h
