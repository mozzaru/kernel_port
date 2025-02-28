#!/bin/bash
#
# Copyright (C) 2020 Fox kernel project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Setup colour for the script
yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
green='\e[0;32m'

# Deleting out "kernel complied" and zip "anykernel" from an old compilation
echo -e "$green << cleanup >> \n $white"

rm -rf out
rm -rf zip
rm -rf error.log

echo -e "$green << setup dirs >> \n $white"

# With that setup , the script will set dirs and few important thinks

MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

# Now u can chose which things need to be modified
# CHATID = chatid of a telegram group/channel
# API_BOT = api bot of a telegram bot
#
# DEVICE = your device codename
# KERNEL_NAME = the name of ur kranul
#
# DEFCONFIG = defconfig that will be used to compile the kernel
#
# AnyKernel = the url of your modified anykernel script
# AnyKernelbranch = the branch of your modified anykernel script
#
# HOSST = build host
# USEER = build user
#
# TOOLCHAIN = the toolchain u want to use "gcc/clang"

CHATID="7047525313"
API_BOT="7883309393:AAH8dj7eCYIV8JUn1JlLUQ3hvozHVlU1hAI"


DEVICE="Redmi 4 Prime"
CODENAME="markw"
KERNEL_NAME="Prototype-v2-normal"

DEFCONFIG="markw_defconfig"

AnyKernel="https://github.com/mozzaru/anykernel"
AnyKernelbranch="master"

HOSST="Show Buildbot"
USEER="mozzaru"

TOOLCHAIN="clang"

# setup telegram env
export BOT_MSG_URL="https://api.telegram.org/bot$API_BOT/sendMessage"
export BOT_BUILD_URL="https://api.telegram.org/bot$API_BOT/sendDocument"

tg_post_msg() {
        curl -s -X POST "$BOT_MSG_URL" -d chat_id="$2" \
        -d "parse_mode=html" \
        -d text="$1"
}

tg_post_build() {
        #Post MD5Checksum alongwith for easeness
        MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

        #Show the Checksum alongwith caption
        curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
        -F chat_id="$2" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="$3 build finished in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
}

tg_error() {
        curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
        -F chat_id="$2" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="$3Failed to build , check <code>error.log</code>"
}

# Now let's clone gcc/clang on HOME dir
# And after that , the script start the compilation of the kernel it self
# For regen the defconfig . use the regen.sh script

if [ "$TOOLCHAIN" == gcc ]; then
	if [ ! -d "$HOME/gcc64" ] && [ ! -d "$HOME/gcc32" ]
	then
		echo -e "$green << cloning gcc from arter >> \n $white"
		git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 "$HOME"/gcc64
		git clone --depth=1 https://github.com/mvaisakh/gcc-arm "$HOME"/gcc32
	fi
	export PATH="$HOME/gcc64/bin:$HOME/gcc32/bin:$PATH"
	export STRIP="$HOME/gcc64/aarch64-elf/bin/strip"
	export KBUILD_COMPILER_STRING=$("$HOME"/gcc64/bin/aarch64-elf-gcc --version | head -n 1)
elif [ "$TOOLCHAIN" == clang ]; then
	if [ ! -d "$HOME/proton_clang" ]
	then
		echo -e "$green << cloning proton clang >> \n $white"
		git clone --depth=1 https://github.com/kdrag0n/proton-clang.git "$HOME"/proton_clang
	fi
	export PATH="$HOME/proton_clang/bin:$PATH"
	export STRIP="$HOME/proton_clang/aarch64-linux-gnu/bin/strip"
	export KBUILD_COMPILER_STRING=$("$HOME"/proton_clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
fi

# Setup build process

build_kernel() {
Start=$(date +"%s")

if [ "$TOOLCHAIN" == clang  ]; then
	echo clang
	make -j$(nproc --all) O=out \
                              ARCH=arm64 \
	                      CC="ccache clang" \
	                      AR=llvm-ar \
	                      NM=llvm-nm \
	                      STRIP=llvm-strip \
	                      OBJCOPY=llvm-objcopy \
	                      OBJDUMP=llvm-objdump \
	                      OBJSIZE=llvm-size \
	                      READELF=llvm-readelf \
	                      HOSTCC=clang \
	                      HOSTCXX=clang++ \
	                      HOSTAR=llvm-ar \
	                      CROSS_COMPILE=aarch64-linux-gnu- \
	                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
	                      CONFIG_DEBUG_SECTION_MISMATCH=y \
	                      CONFIG_NO_ERROR_ON_MISMATCH=y   2>&1 | tee error.log
elif [ "$TOOLCHAIN" == gcc  ]; then
	echo gcc
	make -j$(nproc --all) O=out \
			      ARCH=arm64 \
			      CROSS_COMPILE=aarch64-elf- \
			      CROSS_COMPILE_ARM32=arm-eabi- 2>&1 | tee error.log
fi

End=$(date +"%s")
Diff=$(($End - $Start))
}

export IMG="$MY_DIR"/out/arch/arm64/boot/Image.gz-dtb

# Let's start

echo -e "$green << doing pre-compilation process >> \n $white"
export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64

export KBUILD_BUILD_HOST="$HOSST"
export KBUILD_BUILD_USER="$USEER"

mkdir -p out

make O=out clean && make O=out mrproper
make "$DEFCONFIG" O=out

echo -e "$yellow << compiling the kernel >> \n $white"
tg_post_msg "<code>Building Image.gz-dtb</code>" "$CHATID"

build_kernel || error=true

DATE=$(date +"%Y%m%d-%H%M%S")
KERVER=$(make kernelversion)

        if [ -f "$IMG" ]; then
                echo -e "$green << Build completed in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds >> \n $white"
        else
                echo -e "$red << Failed to compile the kernel , Check up to find the error >>$white"
                tg_error "error.log" "$CHATID"
                rm -rf out
                rm -rf testing.log
                rm -rf error.log
                exit 1
        fi
 # KernelSU
# Check if AK3 is KSU version to build KernelSU
        if [[ "$ANYK_VERSION" == *"KSU"* ]]; then
    sed -i 's/# CONFIG_KSU is not set/CONFIG_KSU=y/' arch/arm64/configs/markw_defconfig
    echo -e "$cyan KernelSU option selected and enabled to be built! $white"
        fi

        if [ -f "$IMG" ]; then
                echo -e "$green << cloning AnyKernel from your repo >> \n $white"
                git clone "$AnyKernel" --single-branch -b "$AnyKernelbranch" zip
                echo -e "$yellow << making kernel zip >> \n $white"
                cp -r "$IMG" zip/
                cd zip
                mv Image.gz-dtb zImage
                export ZIP="$KERNEL_NAME"-"$CODENAME"-"$DATE"
                zip -r "$ZIP" *
                curl -sLo zipsigner-3.0.jar https://raw.githubusercontent.com/Hunter-commits/AnyKernel/master/zipsigner-3.0.jar
                java -jar zipsigner-3.0.jar "$ZIP".zip "$ZIP"-signed.zip
                tg_post_msg "<b>=============================</b> %0A <b>× Prototype For Redmi 4 Prime ×</b> %0A <b>=============================</b> %0A%0A <b>Date : </b> <code>$(TZ=Indonesia/Jakarta date)</code> %0A%0A <b>Device Code Name:</b> <code>$CODENAME</code> %0A%0A <b>Kernel Version :</b> <code>$KERVER</code> %0A%0A <b>Developer:</b> @mozzaru86 %0A%0A <b>Channel:</b> t.me/Cooking_kernel_bot %0A%0A <b>Changelog:</b> %0A https://github.com/mozzaru/kernel_port/commits/normal-test #prototype #markw" "$CHATID"
                tg_post_build "$ZIP"-signed.zip "$CHATID"
                cd ..
                rm -rf error.log
                rm -rf out
                rm -rf zip
                rm -rf testing.log
                exit
        fi

