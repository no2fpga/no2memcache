/*
 * mc_tag_ram.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2020-2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module mc_tag_ram #(
	parameter integer IDX_WIDTH =  8,
	parameter integer TAG_WIDTH = 12,
	parameter integer AGE_WIDTH =  2,

	// auto
	parameter integer IL = IDX_WIDTH-1,
	parameter integer TL = TAG_WIDTH-1,
	parameter integer AL = AGE_WIDTH-1
)(
	// Write
	input  wire [IL:0] w_idx,
	input  wire        w_ena,

	input  wire        w_valid_we,
	input  wire        w_valid,

	input  wire        w_dirty_we,
	input  wire        w_dirty,

	input  wire        w_age_we,
	input  wire [AL:0] w_age,

	input  wire        w_tag_we,
	input  wire [TL:0] w_tag,

	// Read
	input  wire [IL:0] r_idx,
	input  wire        r_ena,

	output wire        r_valid,
	output wire        r_dirty,
	output wire [AL:0] r_age,
	output wire [TL:0] r_tag,

	// Common
	input  wire        clk
);

	// Configuration
	// -------------

	initial
		if (IDX_WIDTH > 11) begin
			$display("Maximum supported number of cache lines is 2048");
			$finish;
		end


	localparam integer REQ_DWIDTH = TAG_WIDTH + AGE_WIDTH + 2;

	localparam integer RAM_MODE   = (IDX_WIDTH <= 8) ? 0 : (IDX_WIDTH - 8);
	localparam integer RAM_DWIDTH = 16 >> RAM_MODE;
	localparam integer RAM_AWIDTH = 8 + RAM_MODE;
	localparam integer RAM_COUNT  = (REQ_DWIDTH + RAM_DWIDTH - 1) / RAM_DWIDTH;

	localparam integer MEM_DWIDTH = RAM_COUNT * RAM_DWIDTH;
	localparam integer FILL = MEM_DWIDTH - REQ_DWIDTH;

	initial
		$display("Cache tag memory config, %d x %d x %d", RAM_COUNT, 1 << RAM_AWIDTH, RAM_DWIDTH);


	// Signals
	// -------

	wire [RAM_AWIDTH-1:0] w_addr;
	reg  [RAM_AWIDTH-1:0] w_addr_r;
	wire [RAM_AWIDTH-1:0] r_addr;

	wire [MEM_DWIDTH-1:0] r_val;
	wire [MEM_DWIDTH-1:0] w_val;
	reg  [MEM_DWIDTH-1:0] w_val_r;
	wire [MEM_DWIDTH-1:0] w_msk;
	reg  [MEM_DWIDTH-1:0] w_msk_r;

	reg  w_ena_r;


	// Mapping
	// -------

	assign w_addr = { {(RAM_AWIDTH-IDX_WIDTH){1'b0}}, w_idx };
	assign r_addr = { {(RAM_AWIDTH-IDX_WIDTH){1'b0}}, r_idx };

	assign { r_valid, r_dirty, r_age, r_tag } = r_val[REQ_DWIDTH-1:0];
	assign w_val = { {FILL{1'b0}},  w_valid,     w_dirty,                w_age,                  w_tag };
	assign w_msk = { {FILL{1'b1}}, ~w_valid_we, ~w_dirty_we, {AGE_WIDTH{~w_age_we}}, {TAG_WIDTH{~w_tag_we}} };


	// Write side reg
	// --------------

`ifdef CXXRTL
	always @(*)
	begin
		w_addr_r = w_addr;
		w_val_r  = w_val;
		w_msk_r  = w_msk;
		w_ena_r  = w_ena;
	end
`else
	always @(posedge clk)
	begin
		w_addr_r <= w_addr;
		w_val_r  <= w_val;
		w_msk_r  <= w_msk;
		w_ena_r  <= w_ena;
	end
`endif


	// Storage elements
	// ----------------

	genvar i;

	generate

		for (i=0; i<RAM_COUNT; i=i+1)
			ice40_ebr #(
				.READ_MODE(RAM_MODE),
				.WRITE_MODE(RAM_MODE),
				.MASK_WORKAROUND(1),
`ifdef CXXRTL
				.NEG_WR_CLK(0)
`else
				.NEG_WR_CLK(1)
`endif
			) ram_I (
				.wr_addr(w_addr_r),
				.wr_data(w_val_r[i*RAM_DWIDTH+:RAM_DWIDTH]),
				.wr_mask(w_msk_r[i*RAM_DWIDTH+:RAM_DWIDTH]),
				.wr_ena(w_ena_r),
				.wr_clk(clk),
				.rd_addr(r_addr),
				.rd_data(r_val[i*RAM_DWIDTH+:RAM_DWIDTH]),
				.rd_ena(r_ena),
				.rd_clk(clk)
			);

	endgenerate

endmodule
