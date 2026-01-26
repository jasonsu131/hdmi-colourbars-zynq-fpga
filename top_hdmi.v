`timescale 1ns / 1ps
// Display colour bars over HDMI at 640x480
// Pixel clock for 640x480 = 25.175 MHz

module top_hdmi(
    input  clk, // 100 MHz
    input  reset_btn,
    output hdmi_clk_p,
    output hdmi_clk_n,
    output [2:0] hdmi_tx_p,
    output [2:0] hdmi_tx_n,
    output hdmi_out_en,
    output hdmi_hpd
);
// Clock signals
wire pix_clk;    // 25.175 MHz
wire pix_clk_5x; // TMDS serialization
wire clk_wiz_locked;
wire clk_wiz_reset;
wire tmds_reset;

// video signals
reg [7:0] red;
reg [7:0] green;
reg [7:0] blue;
reg hsync;
reg vsync;
reg vde;
reg [9:0] hcount = 0; //0-799
reg [9:0] vcount = 0; //0-524

// VGA 640x480 @ 60Hz timing constants
parameter H_VISIBLE   = 640; // visible horizontal pixels
parameter H_FRONT     = 16;  // front porch
parameter H_SYNC      = 96;  // hsync pulse width
parameter H_BACK      = 48;  // back porch
parameter H_TOTAL     = H_VISIBLE + H_FRONT + H_SYNC + H_BACK; // 800 pixels

parameter V_VISIBLE   = 480; // visible vertical lines
parameter V_FRONT     = 10;  // front porch
parameter V_SYNC      = 2;   // vsync pulse width
parameter V_BACK      = 33;  // back porch
parameter V_TOTAL     = V_VISIBLE + V_FRONT + V_SYNC + V_BACK; // 525 pixels

parameter HS_START    = H_VISIBLE + H_FRONT;
parameter HS_END      = HS_START + H_SYNC;
parameter VS_START    = V_VISIBLE + V_FRONT;
parameter VS_END      = VS_START + V_SYNC;

parameter PIXELS_PER_BAR = H_VISIBLE / 8; // 80 pixels per colout bar

assign hdmi_out_en = 1'b1;
assign hdmi_hpd    = 1'b1;
assign clk_wiz_reset = reset_btn;
assign tmds_reset = reset_btn | ~clk_wiz_locked;

// Clock Wizard
clk_wiz_0 clkgen (
    .clk_in1(clk),
    .clk_out1(pix_clk),    // 25.175 MHz
    .clk_out2(pix_clk_5x), // 125.875 MHz
    .locked(clk_wiz_locked),
    .reset(clk_wiz_reset)
);

// Updating pixel count
always @(posedge pix_clk) begin : pix_cnt
    if (hcount == H_TOTAL-1) begin
        hcount <= 0;
        if (vcount == V_TOTAL-1) begin
            vcount <= 0;
        end else begin
            vcount <= vcount + 1;
        end
    end else begin
        hcount <= hcount + 1;
    end
    // Sync Pulse: Line/Frame is finished
    hsync <= (hcount >= HS_START && hcount < HS_END);
    vsync <= (vcount >= VS_START && vcount < VS_END);
    vde   <= (hcount < H_VISIBLE) && (vcount < V_VISIBLE);
 end

// Colour Bars
always @(posedge pix_clk) begin : colour_bars
    if (vde) begin
        case (hcount / PIXELS_PER_BAR) // 8 colour bars, 80 pixels each
            0: {red, green, blue} = 24'hFF_00_00; // Red
            1: {red, green, blue} = 24'h00_FF_00; // Green
            2: {red, green, blue} = 24'h00_00_FF; // Blue
            3: {red, green, blue} = 24'hFF_FF_00; // Yellow
            4: {red, green, blue} = 24'h00_FF_FF; // Cyan
            5: {red, green, blue} = 24'hFF_00_FF; // Magenta
            6: {red, green, blue} = 24'hFF_FF_FF; // White
            7: {red, green, blue} = 24'h00_00_00; // Black
            default: {red, green, blue} = 24'h00_00_00; // Black
        endcase
    end
end

// TMDS
rgb2dvi #(
    .kGenerateSerialClk(0) // disable internal pll in rgb2dvi
) hdmi_out (
    .PixelClk(pix_clk),     // pixel-clock recovered from the DVI interface
    .SerialClk(pix_clk_5x), // 5x PixelClk
    .aRst(tmds_reset),   
    // Video in
    .vid_pData({red, green, blue}),
    .vid_pVDE(vde),
    .vid_pHSync(hsync),
    .vid_pVSync(vsync),
    // DVI 1.0 TMDS video interface
    .TMDS_Clk_p(hdmi_clk_p),
    .TMDS_Clk_n(hdmi_clk_n),
    .TMDS_Data_p(hdmi_tx_p),
    .TMDS_Data_n(hdmi_tx_n)
);
endmodule
