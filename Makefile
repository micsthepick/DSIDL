#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------
ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

ifneq (,$(shell which python3))
PYTHON	:= python3
else ifneq (,$(shell which python2))
PYTHON	:= python2
else ifneq (,$(shell which python))
PYTHON	:= python
else
$(error "Python not found in PATH, please install it.")
endif

export TARGET	:=	dsidl
export TOPDIR	:=	$(CURDIR)

# specify a directory which contains the nitro filesystem
# this is relative to the Makefile
NITRO_FILES	:=

# These set the information text in the nds file
GAME_CODE	:=	KDLA
GAME_BANNER	:=	banner.bin

include $(DEVKITARM)/ds_rules

.PHONY: checkarm7 checkarm9 clean

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
all: checkarm7 checkarm9 $(TARGET).dsi $(TARGET).sym

#---------------------------------------------------------------------------------
checkarm7:
	$(MAKE) -C arm7

#---------------------------------------------------------------------------------
checkarm9:
	$(MAKE) -C arm9

#---------------------------------------------------------------------------------
$(TARGET).dsi	:	$(NITRO_FILES) arm7/$(TARGET).elf arm9/$(TARGET).elf
	$(SILENTCMD)ndstool -c $@ -7 arm7/$(TARGET).elf -9 arm9/$(TARGET).elf $(_ADDFILES) \
		-g $(GAME_CODE) 00 "DSIDL" -z 80040000 -u 00030004
	$(SILENTCMD)$(PYTHON) animatedbannerpatch.py $@ $(GAME_BANNER)
	@echo built ... $(notdir $@)

#---------------------------------------------------------------------------------
$(TARGET).sym: $(TARGET).arm7.sym $(TARGET).arm9.sym
	$(SILENTCMD)cat $(TARGET).arm9.sym $(TARGET).arm7.sym | uniq | grep -E '.+ .+' > $(TARGET).sym

#---------------------------------------------------------------------------------
arm7/$(TARGET).elf:
	$(MAKE) -C arm7

#---------------------------------------------------------------------------------
arm9/$(TARGET).elf:
	$(MAKE) -C arm9

#---------------------------------------------------------------------------------
$(TARGET).arm7.sym: arm7/$(TARGET).elf
	$(SILENTCMD)$(DEVKITARM)/bin/arm-none-eabi-nm -n arm7/$(TARGET).elf > $(TARGET).arm7.raw.sym
	$(SILENTCMD)sed -r 's/([0-9a-fA-F]{8}) [a-zA-Z] (.*)/\1 \2/g' $(TARGET).arm7.raw.sym > $(TARGET).arm7.sym
	$(SILENTCMD)rm $(TARGET).arm7.raw.sym

#---------------------------------------------------------------------------------
$(TARGET).arm9.sym: arm9/$(TARGET).elf
	$(SILENTCMD)$(DEVKITARM)/bin/arm-none-eabi-nm -n arm9/$(TARGET).elf > $(TARGET).arm9.raw.sym
	$(SILENTCMD)sed -r 's/([0-9a-fA-F]{8}) [a-zA-Z] (.*)/\1 \2/g' $(TARGET).arm9.raw.sym > $(TARGET).arm9.sym
	$(SILENTCMD)rm $(TARGET).arm9.raw.sym

#---------------------------------------------------------------------------------
clean:
	$(MAKE) -C arm9 clean
	$(MAKE) -C arm7 clean
	rm -f $(TARGET).nds

cppcheck:
	$(MAKE) -C arm7 cppcheck
	$(MAKE) -C arm9 cppcheck
