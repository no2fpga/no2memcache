CORE := mem_cache

DEPS_mem_cache := misc ice40

RTL_SRCS_mem_cache := $(addprefix rtl/, \
	mc_bus_wb.v \
	mc_core.v \
	mc_tag_match.v \
	mc_tag_ram.v \
)

SIM_SRCS_mem_cache := $(addprefix sim/, \
	mem_sim.v \
)

TESTBENCHES_mem_cache := \
	mc_core_tb \
	mc_wb_tb \
	mem_sim_tb \
	$(NULL)

include $(ROOT)/build/core-magic.mk
