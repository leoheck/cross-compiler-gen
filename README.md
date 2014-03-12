Makefile para geração de crosscompilers
=======================================

Main steps:

1. Download sources: 
2. Set environment variables
3. Build binutils
4. Build bootstrap gcc
5. Build newlib
6. Build gcc (again) with newlib
7. Tests

Required tools:

* binutils ---------  ~30M binutils-2.24.tar.gz
* gcc -------------- ~106M gcc-4.8.2.tar.gz (requires mpc, mpfr, gmp)
* newlib -----------  ~31M gdb-7.7.tar.gz
* gdb (optional) ---  ~16M newlib-2.1.0.tar.gz
* qemu (optional) --  ~12M qemu-1.7.0.tar.bz2
