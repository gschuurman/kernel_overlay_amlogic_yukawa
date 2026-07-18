CONFIG_AIC_LOADFW_SUPPORT := m
CONFIG_AIC8800_WLAN_SUPPORT := m

obj-$(CONFIG_AIC_LOADFW_SUPPORT)    += aic_load_fw/
obj-$(CONFIG_AIC8800_WLAN_SUPPORT) += aic8800_fdrv/

# Upstream default (CONFIG_USE_FW_REQUEST=n) loads firmware via a raw
# filp_open(), which isn't on the GKI KMI symbol allowlist and won't link.
# Force request_firmware() instead, resolved against the kernel cmdline's
# firmware_class.path=/vendor/firmware.
export CONFIG_USE_FW_REQUEST = y
export CONFIG_PREALLOC_RX_SKB = y
export CONFIG_PREALLOC_TXQ = y
export CONFIG_WOWLAN = n

# Only CONFIG_PLATFORM_AMLOGIC matters -- the aic8800_fdrv/aic_load_fw
# sub-Makefiles key their -DANDROID_PLATFORM/-DCONFIG_PLATFORM_AMLOGIC
# ccflags off it. KDIR/ARCH/CROSS_COMPILE/O below come from the real
# build, not the hardcoded desktop paths upstream's other platform
# branches use.
export CONFIG_PLATFORM_ROCKCHIP = n
export CONFIG_PLATFORM_ALLWINNER = n
export CONFIG_PLATFORM_AMLOGIC = y
export CONFIG_PLATFORM_HI = n
export CONFIG_PLATFORM_UBUNTU = n

# KERNEL_SRC/ARCH/CROSS_COMPILE/O arrive as command-line overrides from
# vendor/lineage's TARGET_KERNEL_EXT_MODULES build; GNU Make propagates
# those to the recursive $(MAKE) below automatically. Falls back to a
# plain host build if invoked standalone.
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
