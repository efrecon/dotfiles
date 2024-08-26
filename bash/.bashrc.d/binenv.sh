if [ -d "~/.binenv" ]; then
	export PATH="~/.binenv:$PATH"
	source <(binenv completion bash)
fi
