CORE := no2memcache

DEPS_no2memcache := no2misc no2ice40

RTL_SRCS_no2memcache := $(addprefix rtl/, \
	mc_bus_vex.v \
	mc_bus_wb.v \
	mc_core.v \
	mc_tag_match.v \
	mc_tag_ram.v \
)

SIM_SRCS_no2memcache := $(addprefix sim/, \
	mem_sim.v \
)

TESTBENCHES_no2memcache := \
	mc_core_tb \
	mc_wb_tb \
	mem_sim_tb \
	$(NULL)

include $(NO2BUILD_DIR)/core-magic.mk
