module testGVI
(
input clk_internal,
input clk_external,
input reg start,
input SPI_CS,
input SPI_CLK,
input SPI_MOSI,
input [3:0]GziOutCpldIn,
output SPI_MISO,
output logic [3:0]Ch_discharge,
output [1:0]DAC_CS,
output DAC_MOSI,
output DAC_CLK,
output logic [3:0]Ch_charge,
output [3:0]GVIZIout,
output [3:0]GVIZIoutLed,
output GZIMod,
output GVIMod,

//RC мультивибраторы
output logic [3:0]OChExp,
input [3:0]IChExp,
output logic [3:0]OChExpLed,
input logic[3:0]IChExpLed

);


logic [3:0]GVIZIoutq;
wire [15:0]ChCount0,ChCount1, ChCount2,ChCount3;	//данные для каждого канала
wire [23:0]RawD;	//сырые необработанные данные
wire mod,clk2,clk3;	//mod - режим работы 0/1 - GZI/GVI
wire [7:0]presc, OnCh;
wire first_charge,discharge,startGZI;
wire [7:0] ChDAC0,ChDAC1,ChDAC2,ChDAC3;
wire spi_done;
logic startGZI_GVI, clk_channels;
wire [3:0]outCh;
wire Clk_mod;

reg [15:0]Drc=16'hffff;	//регистр счетчика рабочего цикла
reg Drcz=0;		//защелка счетчика рабочего цикла
wire wDrc = ~(|Drc[15:0]);	//reset сигнал сброса от счетчика рабочего цикла

reg [3:0]clk_internal_dev = 0;
reg clk_internalDiv = 0;
wire clk_int_devw = ~(|clk_internal_dev[3:0]);

//assign OChExp[3:0]= GVIZIoutq[3:0];
//assign OChExpLed[3:0] = GVIZIoutq[3:0];
assign GVIZIoutLed[3:0] = IChExpLed[3:0];

assign GZIMod = ~mod;
assign GVIMod = mod;

integer i;


assign GVIZIout[0] = GVIZIoutq[0]|IChExp[0],GVIZIout[1] = GVIZIoutq[1]|IChExp[1],
		GVIZIout[2] = GVIZIoutq[2]|IChExp[2],GVIZIout[3] = GVIZIoutq[3]|IChExp[3];
always_comb
	begin
	for(i=0; i<4; i=i+1)
		if(GVIZIoutq[i]==1)
			begin
			OChExpLed[i] = GVIZIoutq[i];
			OChExp[i] = GVIZIoutq[i];
			end
			else begin
			OChExpLed[i] = 1'bZ;
			OChExp[i] = 1'bZ; end
	
	for(i=0; i<4; i=i+1) 
		Ch_discharge[i] = discharge; 
	end

//Увеличение длительности сигналов

//
always_comb
	begin
	if(mod)
	begin
		startGZI_GVI = start;
		Ch_charge = 0;
		GVIZIoutq  = outCh;
	end
	else
	begin
		startGZI_GVI = startGZI;
		Ch_charge = outCh;
		GVIZIoutq = ~GziOutCpldIn;
	end
	if(Clk_mod)
	clk_channels = clk_external;
	else
	clk_channels = clk_internal;
	end

//registers
reg [7:0]identificator = 8'hb0; //идентификатор устройства, в версии GVIZI2023T всегда отсылается ведущему
fchd fchd(.clk(clk2),.start(start),.reset(wDrc),.first_charge(first_charge),.discharge(discharge),.startcounter(startGZI)); //блок первого заряда и разряда

ChCounter Ch0(.clk(clk_channels),.ChEnable(OnCh[0]),.enable(clk2),.start(startGZI_GVI),.first_charge(first_charge),.HighDel(wDrc),.DATA(ChCount0),.out(outCh[0]));
ChCounter Ch1(.clk(clk_channels),.ChEnable(OnCh[1]),.enable(clk2),.start(startGZI_GVI),.first_charge(first_charge),.HighDel(wDrc),.DATA(ChCount1),.out(outCh[1]));
ChCounter Ch2(.clk(clk_channels),.ChEnable(OnCh[2]),.enable(clk2),.start(startGZI_GVI),.first_charge(first_charge),.HighDel(wDrc),.DATA(ChCount2),.out(outCh[2]));
ChCounter Ch3(.clk(clk_channels),.ChEnable(OnCh[3]),.enable(clk2),.start(startGZI_GVI),.first_charge(first_charge),.HighDel(wDrc),.DATA(ChCount3),.out(outCh[3]));
Memmory Memmory(.data(RawD),.Omod(mod),.Clk_mod(Clk_mod),.presc(presc),.Onoff(OnCh[3:0]),
					.ChCount0(ChCount0),.ChCount1(ChCount1),.ChCount2(ChCount2),.ChCount3(ChCount3),
					.ChDAC0(ChDAC0),.ChDAC1(ChDAC1),.ChDAC2(ChDAC2),.ChDAC3(ChDAC3),.enable(spi_done),.clk(clk_internal)); 

spi_slave spi_slave(.clk(clk_internal), .ss(SPI_CS),.mosi(SPI_MOSI),.miso(SPI_MISO),.sck(SPI_CLK),.done(spi_done),.din(identificator[7:0]),.dout(RawD));
DAC2X2 DAC2X2(.clk(clk_internalDiv),.CS(SPI_CS),.data({ChDAC0[7:0],ChDAC1[7:0],ChDAC2[7:0],ChDAC3[7:0]}),.CsDac(DAC_CS),.dataDac(DAC_MOSI),.ClkDac(DAC_CLK));

prescallerV3 prescallerV3(.clk(clk_channels),.prescData(presc),.out_clkP1(clk2),.out_clkP2(clk3)); //out_clkP1 - короткий out_clkP2 - длинный



always@(posedge (start||wDrc))
begin
Drcz<=~Drcz;
end
always@(posedge (clk2&Drcz))
begin
if(Drcz == 1)
	Drc <= Drc - 1;
else
	Drc <= 16'hffff;
end


always@(posedge clk_internal)
begin
if(clk_int_devw == 0)
	begin
	clk_internalDiv<=0;
	clk_internal_dev <= clk_internal_dev - 1;
	end
else
	begin
	clk_internalDiv<=1;
	clk_internal_dev <= 4'hf;
	end
end

endmodule 

