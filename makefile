
# DICAS: http://www.ifp.illinois.edu/~nakazato/tips/xgcc.html
# http://sourceware.org/ml/crossgcc/2005-08/msg00114/l-cross-ltr.pdf
# http://wiki.osdev.org/GCC_Cross-Compiler
# Toolchain para o microblaze da xilinx http://www.xilinx.com/guest_resources/gnu/

# CROSS-COMPILER GENERATION STEPS
# 1. Download sources: 
#    binutils ---------  ~30M binutils-2.24.tar.gz
#    gcc -------------- ~106M gcc-4.8.2.tar.gz (requires mpc, mpfr, gmp)
#    newlib -----------  ~31M gdb-7.7.tar.gz
#    gdb (optional) ---  ~16M newlib-2.1.0.tar.gz
#    qemu (optional) --  ~12M qemu-1.7.0.tar.bz2
# 2. Set environment variables
# 3. Build binutils
# 4. Build bootstrap gcc
# 5. Build newlib
# 6. Build gcc (again) with newlib
# 7. Build gdb with PSIM
# 8. Build qemu
# 8. Test

# Target platforms
# TARGET: MIPS
# ARCH: 32 BITS
# Big-Endian

# Target list: http://gcc.gnu.org/install/specific.html
#ls -lR gcc-tree/gcc/config
# TARGET=microblaze-xilinx-elf
# export TARGET := mips-elf
export TARGET := microblaze-xilinx-elf
export PREFIX := $(shell pwd)/$(TARGET)
export PATH := $(PREFIX)/bin:$(PATH)

# Packages
BINUTILS_PKG = binutils-2.24.tar.bz2
GMP_PKG = gmp-5.1.3.tar.bz2
MPFR_PKG = mpfr-3.1.2.tar.bz2
MPC_PKG = mpc-1.0.1.tar.gz
GCC_PKG = gcc-4.8.2.tar.bz2
NEWLIB_PKG = newlib-2.1.0.tar.gz
GDB_PKG = gdb-7.7.tar.bz2
QEMU_PKG = qemu-1.7.0.tar.bz2

ALL_PKGS = \
	$(BINUTILS_PKG) \
	$(GMP_PKG) \
	$(MPFR_PKG) \
	$(MPC_PKG) \
	$(GCC_PKG) \
	$(NEWLIB_PKG) \
	$(GDB_PKG) \
	$(QEMU_PKG)


all: donwload-pkgs extract-pkgs 


# DONWLOAD PACKAGES
#==============================================================================

donwload-pkgs: pkgs $(addprefix pkgs/, $(ALL_PKGS))

pkgs:
	@ mkdir -p pkgs

pkgs/$(BINUTILS_PKG):
	@ cd pkgs; \
		wget http://ftp.gnu.org/gnu/binutils/$(BINUTILS_PKG)

pkgs/$(GCC_PKG):
	@ cd pkgs; \
		wget ftp://ftp.unicamp.br/pub/gnu/gcc/$(GCC_PKG:.tar.bz2=)/$(GCC_PKG)

pkgs/$(NEWLIB_PKG):
	@ cd pkgs; \
		wget ftp://sourceware.org/pub/newlib/$(NEWLIB_PKG)

pkgs/$(GDB_PKG):
	@ cd pkgs; \
		wget http://ftp.gnu.org/gnu/gdb/$(GDB_PKG)

pkgs/$(QEMU_PKG):
	@ cd pkgs; \
		wget http://wiki.qemu-project.org/download/$(QEMU_PKG)

pkgs/$(GMP_PKG):
	@ cd pkgs; \
		wget https://ftp.gnu.org/gnu/gmp/$(GMP_PKG)

pkgs/$(MPFR_PKG):
	@ cd pkgs; \
		wget http://www.mpfr.org/mpfr-current/$(MPFR_PKG)

pkgs/$(MPC_PKG):
	@ cd pkgs; \
		wget ftp://ftp.gnu.org/gnu/mpc/$(MPC_PKG)


# EXTRACT PAKAGES
#==============================================================================

extract-pkgs: donwload-pkgs $(addprefix pkgs/, $(basename $(basename $(ALL_PKGS))))

pkgs/%:
	@ if [ -f $(@).tar.bz2 ]; then \
			cd pkgs; \
			tar -xvjf $(notdir $(@)).tar.bz2; \
		fi
	@ if [ -f $(@).tar.gz ]; then \
			cd pkgs; \
			tar -xvxf $(notdir $(@)).tar.gz; \
		fi


# BUILD PAKAGES
#==============================================================================

#build-all: build-prepare $(addprefix $(TARGET)-/, $(basename $(basename $(ALL_PKGS))))
build: build-binutils build-gcc-bootstrap build-newlib build-gcc

build-binutils: build-prepare $(addprefix $(TARGET)-build/, $(basename $(basename $(BINUTILS_PKG))))
build-gcc-bootstrap: $(addsuffix .bootstrap, $(addprefix $(TARGET)-build/, $(basename $(basename $(GCC_PKG)))))
build-newlib: build-prepare $(addprefix $(TARGET)-build/, $(basename $(basename $(NEWLIB_PKG))))
build-gcc: build-prepare $(addsuffix .final, $(addprefix $(TARGET)-build/, $(basename $(basename $(GCC_PKG)))))

# build-gdb: build-prepare $(addprefix $(TARGET)-build/, $(basename $(basename $(GDB_PKG))))
# build-qemu: build-prepare $(addprefix $(TARGET)-build/, $(basename $(basename $(QEMU_PKG))))

build-prepare:
	@ mkdir -p $(TARGET)
	@ mkdir -p $(TARGET)-build
		@ echo -e " \n \
		Toolchain tools version \n\n \
		$(basename $(basename $(BINUTILS_PKG))) \n \
		$(basename $(basename $(GMP_PKG))) \n \
		$(basename $(basename $(MPFR_PKG))) \n \
		$(basename $(basename $(MPC_PKG))) \n \
		$(basename $(basename $(GCC_PKG))) \n \
		$(basename $(basename $(NEWLIB_PKG))) \n \
	" > $(TARGET)/VERSION

$(TARGET)-build/binutils-%:
	@ mkdir -p $(@)
	@ cd $(@); \
		../../pkgs/$(notdir $(@))/configure \
			--target=$(TARGET) \
			--prefix=$(PREFIX); \
		make && make install

$(TARGET)-build/gcc-%.bootstrap: donwload-gcc-requirements
	@ mkdir -p $(@:.bootstrap=)
	@ cd $(@:.bootstrap=); \
			../../pkgs/$(notdir $(@:.bootstrap=))/configure \
				--target=$(TARGET) \
				--prefix=$(PREFIX) \
				--without-headers \
				--enable-languages=c,c++ \
				--with-newlib \
				--with-gnu-as \
				--with-gnu-ld; \
			make all-gcc && make install-gcc

# Building GCC requires GMP 4.2+, MPFR 2.4.0+ and MPC 0.8.0+.
donwload-gcc-requirements:
	cd pkgs/$(basename $(basename $(GCC_PKG))); \
		./contrib/download_prerequisites

$(TARGET)-build/newlib-%:
	@ mkdir -p $(@)
	@ cd $(@); \
		../../pkgs/$(notdir $(@))/configure \
			--target=$(TARGET) \
			--prefix=$(PREFIX); \
		make && make install

$(TARGET)-build/gcc-%.final:
	@ cd $(@:.final=); \
			../../pkgs/$(notdir $(@:.final=))/configure \
				--target=$(TARGET) \
				--prefix=$(PREFIX) \
				--without-headers \
				--enable-languages=c,c++ \
				--with-newlib \
				--with-gnu-as \
				--with-gnu-ld; \
			make && make install

# Nao funcionou
# $(TARGET)-build/gdb-%:
	# @ mkdir -p $(@)
	# @ cd $(@); \
	# 	../../pkgs/$(notdir $(@))/configure \
	# 		--target=$(TARGET) \
	# 		--prefix=$(PREFIX) \
	# 	  --with-mpc=/home/leco/Desktop/cross-compiler/mips-elf-build/gcc-4.8.2/mpc \
	# 	  --with-mpfr=/home/leco/Desktop/cross-compiler/mips-elf-build/gcc-4.8.2/mpfr \
	# 	  --with-gmp=/home/leco/Desktop/cross-compiler/mips-elf-build/gcc-4.8.2/gmp; \
	# 	make && make install

# Nao funcionou
# $(TARGET)-build/qemu-%:
# 	@ mkdir -p $(@)
# 	@ cd $(@); \
# 		../../pkgs/$(notdir $(@))/configure \
# 			--prefix=$(PREFIX); \
# 		make && make install


clean:
	@ rm -rf $(PREFIX)-build

cleanall: cleanall
	@ rm -rf $(PREFIX)