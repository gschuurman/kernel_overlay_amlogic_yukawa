CONFIG_AIC_LOADFW_SUPPORT := m
CONFIG_AIC8800_WLAN_SUPPORT := m

obj-$(CONFIG_AIC_LOADFW_SUPPORT)    += aic_load_fw/
obj-$(CONFIG_AIC8800_WLAN_SUPPORT) += aic8800_fdrv/

########## config option ##########
# Upstream default is CONFIG_USE_FW_REQUEST=n, which loads firmware via a
# raw filp_open() on a hardcoded path. filp_open isn't on the GKI KMI
# symbol allowlist (same restriction that blocked CONFIG_PSTORE_BLK on this
# board), so it won't link against this kernel. Force it on to use the
# standard request_firmware() API instead, resolved against
# firmware_class.path=/vendor/firmware (already set on this device's
# kernel cmdline) -- the same mechanism brcmfmac's firmware load already
# uses successfully here.
export CONFIG_USE_FW_REQUEST = y
export CONFIG_PREALLOC_RX_SKB = y
export CONFIG_PREALLOC_TXQ = y
export CONFIG_WOWLAN = n
###################################

########## platform support list ##########
# Only CONFIG_PLATFORM_AMLOGIC matters here -- it's what the aic8800_fdrv
# and aic_load_fw sub-Makefiles key their own -DANDROID_PLATFORM /
# -DCONFIG_PLATFORM_AMLOGIC ccflags off of. KDIR/ARCH/CROSS_COMPILE/O come
# from the real kernel build below, not from a per-platform hardcoded path
# the way upstream's Makefile picks them (those all assumed a specific
# developer's desktop layout).
export CONFIG_PLATFORM_ROCKCHIP = n
export CONFIG_PLATFORM_ALLWINNER = n
export CONFIG_PLATFORM_AMLOGIC = y
export CONFIG_PLATFORM_HI = n
export CONFIG_PLATFORM_UBUNTU = n
############################################

# KERNEL_SRC/ARCH/CROSS_COMPILE/O arrive as command-line overrides from
# vendor/lineage's TARGET_KERNEL_EXT_MODULES build
# (kernel.mk:make-external-module-target). GNU Make propagates
# command-line-set variables to recursive $(MAKE) invocations
# automatically, so the modules target below doesn't need to forward them
# explicitly. Falls back to a plain host build (desktop testing) if
# invoked standalone.
KERNEL_SRC ?= /lib/modules/$(shell uname -r)/build
KDIR ?= $(KERNEL_SRC)
PWD := $(shell pwd)

all: modules

modules:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

modules_install:
	$(MAKE) -C $(KDIR) M=$(PWD) modules_install

clean:
	rm -rf *.o *.ko *.mod.c *.mod *.symvers modules.order .tmp_versions
	$(MAKE) -C aic8800_fdrv clean
	$(MAKE) -C aic_load_fw clean
