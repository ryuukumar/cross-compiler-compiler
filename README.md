# cross-compiler-compiler

Simple script to build a cross compiler (binutils and GCC with optional C++ support). Implemented following the guide on [the OSdev wiki](https://wiki.osdev.org/GCC_Cross-Compiler). Allows you to set some typical parameters like target, versions and install location (prefix), and you can dig into the script for more complex changes.

*NOTE: Script utilises the GitHub mirrors to download GCC and Binutils. Please keep that in mind while deciding on a version.*
