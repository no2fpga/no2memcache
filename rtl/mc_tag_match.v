/*
 * mc_tag_match.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2020-2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module mc_tag_match #(
	parameter integer TAG_WIDTH = 12
)(
	input  wire [TAG_WIDTH-1:0] ref,
	input  wire [TAG_WIDTH-1:0] tag,
	input  wire valid,
	output wire match
);

	genvar i;

	// Constants
	// ---------

	localparam integer CW = (TAG_WIDTH + 1) / 2;
	localparam integer AW = ((CW + 1)  + 3) / 4;


	// Signals
	// -------

	wire [(2*CW)-1:0] cmp_in0;
	wire [(2*CW)-1:0] cmp_in1;
	wire [   CW -1:0] cmp_out;

	wire [(4*AW)-1:0] agg_in;
	wire [   AW -1:0] agg_out;


	// Comparator stage
	// ----------------

	// Map input to even number, pad with 0
	assign cmp_in0 = { {(TAG_WIDTH & 1){1'b0}}, ref };
	assign cmp_in1 = { {(TAG_WIDTH & 1){1'b0}}, tag };

	// Comparator, 2 bits at a time
	generate
		for (i=0; i<CW; i=i+1)
			SB_LUT4 #(
				.LUT_INIT(16'h9009)
			) lut_cmp_I (
				.I0(cmp_in0[2*i+0]),
				.I1(cmp_in1[2*i+0]),
				.I2(cmp_in0[2*i+1]),
				.I3(cmp_in1[2*i+1]),
				.O(cmp_out[i])
			);
	endgenerate


	// Aggregation stage
	// -----------------

	// Map aggregator input
	assign agg_in = { {((4*AW)-CW-1){1'b1}}, valid, cmp_out };

	// Aggregate 4 bits at a time
	generate
		for (i=0; i<AW; i=i+1)
			SB_LUT4 #(
				.LUT_INIT(16'h8000)
			) lut_cmp_I (
				.I0(agg_in[4*i+3]),
				.I1(agg_in[4*i+2]),
				.I2(agg_in[4*i+1]),
				.I3(agg_in[4*i+0]),
				.O(agg_out[i])
			);
	endgenerate

	// Final OR
		// This is not manually done because we want the optimizer to merge it
		// with other logic
	assign match = &agg_out;

endmodule
