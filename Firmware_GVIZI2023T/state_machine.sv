module state_machine

(
input clk,
input spi_cs,
input [7:0]din,
output [7:0]dout



);

//wires
wire reset;

//assignments
assign reset = spi_cs;

//registers
reg [7:0]Din;	//входные данные
reg [3:0]Addr;	//адрес памяти


enum int unsigned { IDLE = 0, READ = 2, INTERP = 4, READM = 8, WRITEM = 16 } state, next_state;
always_comb begin : next_state_logic
next_state = IDLE;
case(state)
IDLE: next_state = READ;
READ: next_state = INTERP;
INTERP: next_state = READM;
READM: next_state = READM;
endcase
end
always_comb begin
case(state)
IDLE: dout = din[3];
READ: dout = din[2];
INTERP: dout = din[1];
READM: dout = din[0];
endcase
end
always_ff@(posedge clk or negedge reset) begin
if(reset)
state <= IDLE;
else
state <= next_state;
end
endmodule


