`timescale 1ns / 1ps

module PWM_tb();
    parameter RESOLUTION=10;
    reg clk,rst;
    wire PWM_out;
    //wire [RESOLUTION-1:0]counter;
    
    PWM uut(
        .clk(clk),
        .rst(rst),
        //.counter(counter),
        .PWM_out(PWM_out)
      );
    
    initial
      begin
        clk=0;
        rst=0;
        end
        
    always
        #5 clk=~clk;
        
    initial 
        begin
            #100
            rst=1;
            #10
            rst=0;
            
            #500 $finish;
        end
        
endmodule
