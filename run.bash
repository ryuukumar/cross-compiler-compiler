#!/bin/bash


# COLORS

BLACK='\e[30m'
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
WHITE='\e[37m'
NOCOLOR='\e[0m'


# INSTALL REQUIRED PACKAGES

echo -e "\n${CYAN}0. [PREREQUISITE] Installing required packages...${NOCOLOR}"

packages=(
	build-essential bison flex
	libgmp3-dev libmpc-dev libmpfr-dev
	texinfo libisl-dev
)

sudo apt install -y "${packages[@]}"

installed_gpp_version=$(g++ --version | head -n1 | grep -o -E '[0-9]+(\.[0-9]+)+' | tail -n1)
installed_ld_version=$(ld --version | head -n1 | grep -o -E '[0-9]+(\.[0-9]+)+' | tail -n1)


# CONFIGURATION

echo -e "\n${CYAN}1. Gathering configuration.${NOCOLOR}"

echo -e -n "Build directory [default $HOME/tmp/cross-build] "
read -r build_dir
if [ -z "$build_dir" ]; then
    build_dir="$HOME/tmp/cross-build"
else
    build_dir=$(realpath "$build_dir")
fi

echo -e -n "Compiler target [default x86_64-elf] "
read -r compiler_target
if [ -z "$compiler_target" ]; then
    compiler_target="x86_64-elf"
fi

echo -e -n "Compiler install location [default $HOME/opt/cross]"
read -r compiler_location
if [ -z "$compiler_location" ]; then
    compiler_location="$HOME/opt/cross"
fi

echo -e -n "Which version of GCC do you want to build? [default ${installed_gpp_version}] " 
read -r gcc_version
if [ -z "$gcc_version" ]; then
    gcc_version="${installed_gpp_version}"
fi

echo -e -n "Which version of binutils do you want to build? [default ${installed_ld_version}] "
read -r binuntils_version
if [ -z "$binuntils_version" ]; then
    binuntils_version="${installed_ld_version}"
fi

echo -e -n "Whether to build C++? [Y/n] "
read -r build_cpp
if [[ -z "$build_cpp" || "$build_cpp" =~ ^[Yy]$ ]]; then
	build_cpp=true
else
	build_cpp=false
fi

echo -e -n "Whether to add compiler location to .bashrc? [Y/n] "
read -r compiler_saveto_bashrc
if [[ -z "$compiler_saveto_bashrc" || "$compiler_saveto_bashrc" =~ ^[Yy]$ ]]; then
	compiler_saveto_bashrc=true
else
	compiler_saveto_bashrc=false
fi

echo -e "\n\n${CYAN}Configuration summary:${NOCOLOR}"

echo -e "${CYAN}Compiler target: ${YELLOW}${compiler_target}${NOCOLOR}"
echo -e "${CYAN}Compiler build location: ${YELLOW}${build_dir}${NOCOLOR}"
echo -e "${CYAN}Compiler install location: ${YELLOW}${compiler_location}${NOCOLOR}"
echo -e "${CYAN}GCC version to build: ${YELLOW}${gcc_version}${NOCOLOR}"
echo -e "${CYAN}binutils version to build: ${YELLOW}${binuntils_version}${NOCOLOR}"
if [ "$build_cpp" = true ]; then
    echo -e "${CYAN}Build C++: ${GREEN}Yes${NOCOLOR}"
else
    echo -e "${CYAN}Build C++: ${RED}No${NOCOLOR}"
fi
if [ "$compiler_saveto_bashrc" = true ]; then
    echo -e "${CYAN}Add compiler location to .bashrc: ${GREEN}Yes${NOCOLOR}"
else
    echo -e "${CYAN}Add compiler location to .bashrc: ${RED}No${NOCOLOR}"
fi

echo -e -n "\n${YELLOW}Do you want to proceed with this configuration? [y/N] ${NOCOLOR}"
read -r proceed
if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborted by user.${NOCOLOR}"
    exit 1
fi


# DOWNLOAD SOURCE FILES

echo -e "\n${CYAN}2. Downloading source files...${NOCOLOR}"

if [ -d "${build_dir}" ]; then
    echo -e "${YELLOW}The folder '${build_dir}' already exists. It is recommended you delete this folder as continuing from a partial build may not work perfectly.${NOCOLOR}"
else
    mkdir -p "${build_dir}"
fi

gcc_url="https://github.com/gcc-mirror/gcc/archive/refs/tags/releases/gcc-${gcc_version}.tar.gz"
binutils_url="https://github.com/bminor/binutils-gdb/archive/refs/tags/binutils-${binuntils_version//./_}.tar.gz"

echo -e "${CYAN}2.1. Downloading GCC source files...${NOCOLOR}"
# if wget -q --show-progress -c -O "${build_dir}/gcc-${gcc_version}.tar.gz" "${gcc_url}"; then
#     echo -e "${GREEN}GCC source file downloaded successfully.${NOCOLOR}"
# else
#     echo -e "${RED}Failed to download GCC source file from ${gcc_url}. Aborting.${NOCOLOR}"
#     exit 1
# fi

echo -e "${CYAN}2.2. Downloading Binutils source files...${NOCOLOR}"
# if wget -q --show-progress -c -O "${build_dir}/binuntils-${binuntils_version}.tar.gz" "${binutils_url}"; then
#     echo -e "${GREEN}Binutils source file downloaded successfully.${NOCOLOR}"
# else
#     echo -e "${RED}Failed to download GCC source file from ${binutils_url}. Aborting.${NOCOLOR}"
#     exit 1
# fi

echo -e "${CYAN}2.3. Unpacking source files...${NOCOLOR}"
#tar -xf "${build_dir}/gcc-${gcc_version}.tar.gz" -C "${build_dir}"
#tar -xf "${build_dir}/binuntils-${binuntils_version}.tar.gz" -C "${build_dir}"

gcc_src_path=$(realpath "${build_dir}/gcc-releases-gcc-${gcc_version}")
binutils_src_path=$(realpath "${build_dir}/binutils-gdb-binutils-${binuntils_version//./_}")

echo -e "${GREEN}Unpacked GCC at ${gcc_src_path}${NOCOLOR}"
echo -e "${GREEN}Unpacked Binutils at ${binutils_src_path}${NOCOLOR}"



# BUILD Binutils

echo -e "\n${CYAN}3. Building Binutils...${NOCOLOR}"

export PATH="${PATH}:${compiler_location}/bin"

cd "${build_dir}"
mkdir build_binutils
cd build_binutils

binutils_src_path=$(realpath -s --relative-to="$(pwd)" "${binutils_src_path}")

binutils_config_cmd="./${binutils_src_path}/configure --target=${compiler_target} --prefix=${compiler_location} --with-sysroot --disable-nls --disable-werror"
binutils_build_cmd="make -j$(nproc)"
binutils_install_cmd="make install"

echo -e "${MAGENTA}Configuring Binutils with ${binutils_config_cmd}${NOCOLOR}"
if $binutils_config_cmd; then
    echo -e "${GREEN}Binutils configured successfully.${NOCOLOR}"
else
    echo -e "${RED}Failed to configure Binutils. Aborting.${NOCOLOR}"
    exit 1
fi

echo -e "${MAGENTA}Building Binutils with ${binutils_build_install_cmd}${NOCOLOR}"
if $binutils_build_cmd; then
    echo -e "${GREEN}Binutils built successfully.${NOCOLOR}"
else
    echo -e "${RED}Failed to build Binutils. Aborting.${NOCOLOR}"
    exit 1
fi

echo -e "${MAGENTA}Installing Binutils with ${binutils_install_cmd}${NOCOLOR}"
if $binutils_install_cmd; then
    echo -e "${GREEN}Binutils installed successfully.${NOCOLOR}"
else
    echo -e "${RED}Failed to install Binutils. Aborting.${NOCOLOR}"
    exit 1
fi


# BUILD GCC

echo -e "\n${CYAN}3. Building GCC...${NOCOLOR}"

cd "${build_dir}"
mkdir build_gcc
cd build_gcc

gcc_src_path=$(realpath -s --relative-to="$(pwd)" "${gcc_src_path}")

if [ "$build_cpp" = true ]; then
    gcc_config_cmd="./${gcc_src_path}/configure --target=${compiler_target} --prefix=${compiler_location} --disable-nls --enable-languages=c,c++ --without-headers --disable-hosted-libstdcxx"
else
    gcc_config_cmd="./${gcc_src_path}/configure --target=${compiler_target} --prefix=${compiler_location} --disable-nls --enable-languages=c --without-headers --disable-hosted-libstdcxx"
fi
gcc_build_cmds=(
    "make all-gcc -j$(nproc)"
    "make all-target-libgcc -j$(nproc)"
)
gpp_build_cmds=("make all-target-libstdc++-v3 -j$(nproc)")
gcc_install_cmds=(
    "make install-gcc"
    "make install-target-libgcc"
)
gpp_install_cmds=("make install-target-libstdc++-v3")

echo -e "${MAGENTA}Configuring GCC with ${gcc_config_cmd}${NOCOLOR}"
if $gcc_config_cmd; then
    echo -e "${GREEN}GCC configured successfully.${NOCOLOR}"
else
    echo -e "${RED}Failed to configure GCC. Aborting.${NOCOLOR}"
    exit 1
fi

for cmd in "${gcc_build_cmds[@]}"; do
    echo -e "${MAGENTA}Building GCC with ${cmd}${NOCOLOR}"
    if $cmd; then
        echo -e "${GREEN}${cmd} completed successfully.${NOCOLOR}"
    else
        echo -e "${RED}Failed to build GCC (${cmd}). Aborting.${NOCOLOR}"
        exit 1
    fi
done

if [ "$build_cpp" = true ]; then
    for cmd in "${gpp_build_cmds[@]}"; do
        echo -e "${MAGENTA}Building G++ with ${cmd}${NOCOLOR}"
        if $cmd; then
            echo -e "${GREEN}${cmd} completed successfully.${NOCOLOR}"
        else
            echo -e "${RED}Failed to build G++ (${cmd}). Aborting.${NOCOLOR}"
            exit 1
        fi
    done
fi

for cmd in "${gcc_install_cmds[@]}"; do
    echo -e "${MAGENTA}Installing GCC with ${cmd}${NOCOLOR}"
    if $cmd; then
        echo -e "${GREEN}${cmd} completed successfully.${NOCOLOR}"
    else
        echo -e "${RED}Failed to install GCC (${cmd}). Aborting.${NOCOLOR}"
        exit 1
    fi
done

if [ "$build_cpp" = true ]; then
    for cmd in "${gpp_install_cmds[@]}"; do
        echo -e "${MAGENTA}Installing G++ with ${cmd}${NOCOLOR}"
        if $cmd; then
            echo -e "${GREEN}${cmd} completed successfully.${NOCOLOR}"
        else
            echo -e "${RED}Failed to install G++ (${cmd}). Aborting.${NOCOLOR}"
            exit 1
        fi
    done
fi