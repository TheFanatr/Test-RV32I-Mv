
module Top #
(
    parameter DATA_WIDTH = 8
)(
	input  wire user_clk,
	input  wire user_rst_n,
	
	input  wire rxd,
	output wire txd,
	output wire en_out
);
		//send
		logic [DATA_WIDTH-1:0]  s_axis_tdata;
		wire                   s_axis_tvalid;
		wire             	    s_axis_tready;


	  //in
     wire [DATA_WIDTH-1:0]  m_axis_tdata;
     wire                   m_axis_tvalid;
     wire                   m_axis_tready;
	 

	 assign s_axis_tvalid = m_axis_tvalid;
		 assign s_axis_tready = m_axis_tready; 
	 
	 always_ff @(posedge clk_sys) begin
			s_axis_tdata <= m_axis_tdata + 1;
	 end
	 

    wire tx_busy;
    wire rx_busy;
    wire rx_overrun_error;
    wire rx_frame_error;

	


	wire clk_sys;
	wire clk_locked;
	wire async_rst;

	pll	pll_inst (
		.areset ( async_rst ),
		.inclk0 ( user_clk ),
		.c0 ( clk_sys ),
		.locked (clk_locked)
	);

	
	button_debouncing bd (    
    .clk(user_clk),
    .button_n_in(user_rst_n),
    .double_pulse_enabled(1'b0),

    .pulse_out(async_rst)
	);

	reg  [3:0] enable_vector_sys_current;
	wire [3:0] enable_vector_sys_next = {enable_vector_sys_current[2:0], clk_locked};
	wire       enable_vector_sys_trigger = clk_locked;
	always_ff @(posedge clk_sys or posedge async_rst) begin
		if (async_rst) begin
			 enable_vector_sys_current <= 4'd0;
		end
		else if (enable_vector_sys_trigger) begin
			 enable_vector_sys_current <= enable_vector_sys_next;
		end
	end
	wire clk_en_sys = enable_vector_sys_current[3]; //enable
	wire   sys_rst_check = ~enable_vector_sys_current[1] && enable_vector_sys_current[0];

	reg  sys_rst_delay_current;
	wire sys_rst_delay_next = sys_rst_check;
	wire sys_rst_delay_trigger = clk_locked;
	always_ff @(posedge clk_sys or posedge async_rst) begin
		if (async_rst) begin
			 sys_rst_delay_current <= 1'b0;
		end
		else if (sys_rst_delay_trigger) begin
			 sys_rst_delay_current <= sys_rst_delay_next;
		end
	end
	wire sync_rst_sys = sys_rst_delay_current; //reset
	
	assign en_out = ~clk_en_sys;

uart
	uart_inst (
		 .clk(clk_sys),
		 .rst(sync_rst_sys),
		 // AXI input
		 .s_axis_tdata(s_axis_tdata),
		 .s_axis_tvalid(s_axis_tvalid),
		 .s_axis_tready(s_axis_tready),
		 // AXI output
		 .m_axis_tdata(m_axis_tdata),
		 .m_axis_tvalid(m_axis_tvalid),
		 .m_axis_tready(m_axis_tready),
		 // uart
		 .rxd(rxd),
		 .txd(txd),
		 // status
		 .tx_busy(tx_busy),
		 .rx_busy(rx_busy),
		 .rx_overrun_error(rx_overrun_error),
		 .rx_frame_error(rx_overrun_error),
		 // configuration
		 .prescale(50000000 / (9600 * 8))
	);

endmodule





/*
module Top11 #
(
    parameter DATA_WIDTH = 8
)(
	input  wire clk,
	input  wire rst,
	
	input  wire rxd,
	output wire txd

);
	wire c0_sig;




     logic [DATA_WIDTH-1:0]  s_axis_tdata;
     wire                   s_axis_tvalid;
     wire             	    s_axis_tready;


     wire [DATA_WIDTH-1:0]  m_axis_tdata;
     wire                   m_axis_tvalid;
     wire                   m_axis_tready;
	 
	
	 assign s_axis_tvalid = m_axis_tvalid;
	 assign s_axis_tready = m_axis_tready;
	 
	 always @(posedge c0_sig) begin
		s_axis_tdata <= m_axis_tdata + 2;
	 end
	 

    wire tx_busy;
    wire rx_busy;
    wire rx_overrun_error;
    wire rx_frame_error;

	uart
	uart_inst (
		 .clk(c0_sig),
		 .rst(rst),
		 // AXI input
		 .s_axis_tdata(s_axis_tdata),
		 .s_axis_tvalid(s_axis_tvalid),
		 .s_axis_tready(s_axis_tready),
		 // AXI output
		 .m_axis_tdata(m_axis_tdata),
		 .m_axis_tvalid(m_axis_tvalid),
		 .m_axis_tready(m_axis_tready),
		 // uart
		 .rxd(rxd),
		 .txd(txd),
		 // status
		 .tx_busy(tx_busy),
		 .rx_busy(rx_busy),
		 .rx_overrun_error(rx_overrun_error),
		 .rx_frame_error(rx_overrun_error),
		 // configuration
		 .prescale(50000000 / (9600 * 8))
	);
  

endmodule
*/


/**
 *  Module: button_debouncing
 *
 *  About: 
 *
 *  Ports:
 *
**/
module button_debouncing (
    //* Assumed Active Low
    // parameter bit Reset_Polarity = 1'b1 // 0: Active High, 1: Active Low
    input  clk,
    input  button_n_in,
    input  double_pulse_enabled,

    output pulse_out
);

// 111111111111111111110000000000000000000000000000000000001111111111111111111111
// Idle                Active                              Idle
//                     Local Reset                         Reset Out

//? User Reset Control
    //                                                                       //
    //* User Reset Clock Synchronization
        reg  user_reset_delay_current;
        always_ff @(posedge clk) begin
            user_reset_delay_current <= button_n_in;
        end

        reg  user_reset_delay_2_current;
        always_ff @(posedge clk) begin
            user_reset_delay_2_current <= user_reset_delay_current;
        end
    //                                                                       //
    //* Reset Edge Detection
        wire user_reset_check = ~user_reset_delay_2_current;
        reg  user_reset_active_current;
        always_ff @(posedge clk) begin
            user_reset_active_current <= user_reset_check;
        end
        wire local_reset_pulse = ~user_reset_check && user_reset_active_current;
    //                                                                       //
//?

//? Reset Detection
    //                                                                       //
    //* If Zero Reset Init - clears on user reset to trigger mock-POR
        reg  [3:0] zero_reset_vector_current;
        wire       zero_vector_check = zero_reset_vector_current != 4'HF;
        wire       zero_reser_lsb = zero_reset_vector_current[0] || zero_vector_check;
        wire [3:0] zero_reset_vector_next = local_reset_pulse ? 4'd0 : {zero_reset_vector_current[2:0], zero_reser_lsb};
        always_ff @(posedge clk) begin
            zero_reset_vector_current <= zero_reset_vector_next;
        end
    //                                                                       //
    //* Reset Check
        wire por_check = &zero_reset_vector_current;
    //                                                                       //
    //* Reset Delay
        reg  [3:0] por_vector_current;
        wire       clk_en_check = |por_vector_current[3:2];
        wire [3:0] por_vector_next = {clk_en_check, por_vector_current[1:0], por_check};
        always_ff @(posedge clk) begin
            por_vector_current <= por_vector_next;
        end
    //                                                                       //
    //* Reset Control
        wire begin_reset = ~por_vector_current[2] && por_vector_current[1];
        wire local_clk_en = por_vector_current[3];
    //                                                                       //
//?

//? Output Reset Control
    //                                                                       //
    //* Reset Active
        reg  reset_active_current;
        wire reset_active_next = begin_reset && ~reset_lockout_elapsed;
        wire reset_lockout_elapsed;
        wire reset_active_trigger = (begin_reset && ~reset_active_current) || (local_clk_en && reset_lockout_elapsed);
        always_ff @(posedge clk) begin
            if (reset_active_trigger) begin
                reset_active_current <= reset_active_next;
            end
        end
    //                                                                       //
    //* Delay Lockout
        reg    [31:0] reset_lockout_count_current;
        // assign        reset_lockout_elapsed = reset_lockout_count_current == 32'd5_000_000; //* 1/10th of a second @ 50Mhz
        // wire          reset_active_check = reset_lockout_count_current >= 32'd4_500_000; //* 1/100th of a second @ 50Mhz
        
        assign        reset_lockout_elapsed = reset_lockout_count_current == 32'd50_000; //* 1/10th of a second @ 50Mhz
        wire          reset_active_check = reset_lockout_count_current >= 32'd15_0; //* 1/100th of a second @ 50Mhz
        wire          double_pulse_check = (reset_lockout_count_current >= 32'd5_0) && (reset_lockout_count_current <= 32'd10_0) && double_pulse_enabled; //* 1/100th of a second @ 50Mhz
        
        // assign        reset_lockout_elapsed = reset_lockout_count_current == 32'd20; //* 1/10th of a second @ 50Mhz
        // wire          reset_active_check = reset_lockout_count_current >= 32'd15; //* 1/100th of a second @ 50Mhz
        // wire          double_pulse_check = (reset_lockout_count_current >= 32'd5) && (reset_lockout_count_current <= 32'd10); //* 1/100th of a second @ 50Mhz
        
        // assign        reset_lockout_elapsed = reset_lockout_count_current == 32'd50; //! 50 cycles for testing
        wire   [31:0] reset_lockout_count_next = ((begin_reset && ~reset_active_current) || reset_lockout_elapsed)
                                               ? 32'd0
                                               : (reset_lockout_count_current + 32'd1);
        wire          reset_lockout_count_trigger = (begin_reset && ~reset_active_current) || (local_clk_en && reset_active_current);
        always_ff @(posedge clk) begin
            if (reset_lockout_count_trigger) begin
                reset_lockout_count_current <= reset_lockout_count_next;
            end
        end
    //                                                                       //
    //* Reset Output Buffer
        reg  [3:0] reset_output_vector_current;
        //wire       reset_pulse_check = ~reset_output_vector_current[1] && reset_output_vector_current[0];
          wire [3:0] reset_output_vector_next = begin_reset ? 4'd0 : {reset_output_vector_current[2:0], (reset_active_check || double_pulse_check)};
        always_ff @(posedge clk) begin
                reset_output_vector_current <= reset_output_vector_next;
        end
        assign pulse_out = reset_output_vector_current[3];
    //                                                                       //
//?

endmodule : button_debouncing
