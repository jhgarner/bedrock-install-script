#!/bin/bash

git clone --branch 1.0beta2 https://github.com/bedrocklinux/bedrocklinux-userland.git
cd bedrocklinux-userland
make
mkdir ../tar
mv bedrock_linux_1.0beta2_nyla.tar ../tar/
