/*
 * mem_sim_data.cpp
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: MIT
 */

#include "sim.h"

using namespace cxxrtl_yosys;

namespace cxxrtl_design {

template<size_t AW>
struct bb_p_memsim__data_impl : public bb_p_memsim__data<AW>
{
	uint32_t *mem;

	uint32_t v_addr;
	uint32_t v_wdata;
	bool v_we;

	bb_p_memsim__data_impl(const std::string &filename);
	virtual ~bb_p_memsim__data_impl();

	void reset();
	bool eval();

	bool negedge_p_clk() const {
		return this->prev_p_clk.template slice<0>().val() && !this->p_clk.template slice<0>().val();
	}
};

template<size_t AW>
bb_p_memsim__data_impl<AW>::bb_p_memsim__data_impl(const std::string &filename)
{
	this->mem = new uint32_t[1<<AW];

	FILE *fh = fopen(filename.c_str(), "r");

	for (int i=0; i<(1<<AW); i++)
		if (fscanf(fh, "%08x\n", &this->mem[i]) != 1)
			break;

	fclose(fh);
}

template<size_t AW>
bb_p_memsim__data_impl<AW>::~bb_p_memsim__data_impl()
{
	delete [] this->mem;
}

template<size_t AW>
void
bb_p_memsim__data_impl<AW>::reset()
{
}

template<size_t AW>
bool
bb_p_memsim__data_impl<AW>::eval()
{
	/* Workaround bug #2887 : Sample on falling edge */
	if (this->negedge_p_clk()) {
		this->v_addr  = this->p_mem__addr.template get<uint32_t>();
		this->v_wdata = this->p_mem__wdata.template get<uint32_t>();
		this->v_we    = bool(this->p_mem__we);
	}

	if (this->posedge_p_clk()) {
		/* Reads */
		this->p_mem__rdata.template set<uint32_t>(this->mem[this->v_addr]);

		/* Writes */
		if (this->v_we)
			this->mem[this->v_addr] = this->v_wdata;
	}

	return false;
}

template<>
std::unique_ptr<bb_p_memsim__data<MEM_SIM_AW>>
bb_p_memsim__data<MEM_SIM_AW>::create(std::string name, metadata_map parameters, metadata_map attributes)
{
	return std::make_unique<bb_p_memsim__data_impl<MEM_SIM_AW>>(parameters.at("INIT_FILE").as_string());
}

} // namespace cxxrtl_design
