#!/bin/bash

echo "Simple install for bedrock linux. The following is based on commands found in the guide. "
echo "This assumes you are using a hijack and has only been tested on arch."
echo "Downloading the source..."
git clone --branch 1.0beta2 https://github.com/bedrocklinux/bedrocklinux-userland.git
echo "Compiling tarball now..."
cd bedrocklinux-userland
make
echo "This script is compete. The rest of the install requires root. If there were not problems, run installBedrock now"
