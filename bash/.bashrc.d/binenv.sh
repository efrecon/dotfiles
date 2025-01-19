#!/usr/bin/bash

if [ -d "${HOME}/.binenv" ]; then
	export PATH="${HOME}/.binenv:$PATH"
	source <(binenv completion bash)
fi
