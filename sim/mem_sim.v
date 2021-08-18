/*
 * mem_sim.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2020-2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module mem_sim #(
	parameter INIT_FILE = "",
	parameter integer AW = 20,

	// auto
	parameter integer AL = AW - 1
)(
	// Memory controller interface
	input  wire [AL:0] mi_addr,
	input  wire [ 6:0] mi_len,
	input  wire        mi_rw,
	input  wire        mi_valid,
	output wire        mi_ready,

	input  wire [31:0] mi_wdata,
	output wire        mi_wack,
	output wire        mi_wlast,

	output wire [31:0] mi_rdata,
	output wire        mi_rstb,
	output wire        mi_rlast,

	// Common
	input  wire clk,
	input  wire rst
);

	localparam [1:0]
		ST_IDLE		= 0,
		ST_WRITE	= 2,
		ST_READ		= 3;


	// Signals
	// -------

	// Memory array
	reg [31:0] mem[0:(1<<AW)-1];

	wire [19:0] mem_addr;
	wire [31:0] mem_wdata;
	reg  [31:0] mem_rdata;
	wire        mem_we;

	// FSM
	reg  [1:0] state_cur;
	reg  [1:0] state_nxt;

	// Command counters
	reg  [19:0] cmd_addr;
	reg  [ 7:0] cmd_len;
	wire        cmd_last;


	// Memory
	// ------

	initial
	begin : mem_init
		integer a;

		if (INIT_FILE == "") begin
			for (a=0; a<(1<<20)-1; a=a+1)
				mem[a] = a;
		end else begin
			$readmemh(INIT_FILE, mem);
		end
	end

	always @(posedge clk)
	begin
		if (mem_we)
			mem[mem_addr] <= mem_wdata;

		mem_rdata <= mem[mem_addr];
	end


	// Main FSM
	// --------

	always @(posedge clk)
		if (rst)
			state_cur <= ST_IDLE;
		else
			state_cur <= state_nxt;

	always @(*)
	begin
		// Default is to stay put
		state_nxt = state_cur;

		// ... or not
		case (state_cur)
			ST_IDLE:
				if (mi_valid)
					state_nxt = mi_rw ? ST_READ : ST_WRITE;

			ST_READ:
				if (cmd_last)
					state_nxt = ST_IDLE;

			ST_WRITE:
				if (cmd_last)
					state_nxt = ST_IDLE;
		endcase
	end


	// Command channel
	// ---------------

	// Register command
	always @(posedge clk)
	begin
		if (state_cur == ST_IDLE) begin
			cmd_addr <= mi_addr;
			cmd_len  <= { 1'b0, mi_len } - 1;
		end else begin
			cmd_addr <= cmd_addr + 1;
			cmd_len  <= cmd_len - 1;
		end
	end

	assign cmd_last = cmd_len[7];

	// Ready ?
	assign mi_ready = (state_cur == ST_IDLE);

	// Mem access
	assign mem_addr = cmd_addr;


	// Write data channel
	// ------------------

	assign mem_wdata = mi_wdata;
	delay_bit #(2) dly_we( (state_cur == ST_WRITE), mem_we, clk );

	assign mi_wack  = mem_we;
	delay_bit #(2) dly_wlast( cmd_last, mi_wlast, clk );


	// Read data channel
	// -----------------

	wire [31:0] mi_rdata_i;

	delay_bus #(5, 32) dly_rdata (mem_rdata, mi_rdata_i, clk);
	delay_bit #(6)     dly_rstb  ((state_cur == ST_READ), mi_rstb, clk);
	delay_bit #(6)     dly_rlast ((state_cur == ST_READ) ? cmd_last : 1'bx, mi_rlast, clk);

	assign mi_rdata = mi_rstb ? mi_rdata_i : 32'hxxxxxxxx;

endmodule
