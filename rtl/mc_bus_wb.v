/*
 * mc_bus_wb.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2020-2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module mc_bus_wb #(
	parameter integer ADDR_WIDTH = 24,

	// auto
	parameter integer BL = ADDR_WIDTH - 1
)(
	// Wishbone bus
	input  wire [BL:0] wb_addr,
	input  wire [31:0] wb_wdata,
	input  wire [ 3:0] wb_wmsk,
	output wire [31:0] wb_rdata,
	input  wire        wb_cyc,
	input  wire        wb_we,
	output wire        wb_ack,

	// Request output
	output wire [BL:0] req_addr_pre,	// 1 cycle early

	output wire        req_valid,

	output wire        req_write,
	output wire [31:0] req_wdata,
	output wire [ 3:0] req_wmsk,

	// Response input
	input  wire        resp_ack,
	input  wire        resp_nak,
	input  wire [31:0] resp_rdata,

	// Common
	input  wire clk,
	input  wire rst
);
	// Control path
	reg pending;
	reg new;

	always @(posedge clk or posedge rst)
		if (rst)
			pending <= 1'b0;
		else
			pending <= (pending | wb_cyc) & ~resp_ack;

	always @(posedge clk)
		new <= wb_cyc & ~pending;

	assign req_addr_pre = wb_addr;
	assign req_valid = resp_nak | new;

	assign wb_ack = resp_ack;

	// Write path
	assign req_write = wb_we;
	assign req_wdata = wb_wdata;
	assign req_wmsk  = wb_wmsk;

	// Read path
	assign wb_rdata  = resp_rdata;

endmodule
