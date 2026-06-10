module cache_line(
    input clk,
    input rst,

    // Write port (when loading from memory)
    input        write_en,
    input [19:0] write_tag,
    input [31:0] write_data,

    // Read port (when accessing cache)
    input [19:0]  read_tag,
    output        hit,           // Tag matches?
    output [31:0] read_data,     // Cached data
    output        valid          // Is this line valid?
);

    // Cache line storage
    reg        valid_bit;
    reg [19:0] tag;
    reg [31:0] data;

    // Initialize
    initial begin
        valid_bit = 1'b0;
        tag       = 20'h00000;
        data      = 32'h00000000;
    end

    // Reset
    always @(posedge clk) begin
        if (rst) begin
            valid_bit <= 1'b0;
            tag       <= 20'h00000;
            data      <= 32'h00000000;
        end
        else if (write_en) begin
            valid_bit <= 1'b1;  // Mark as valid when written
            tag       <= write_tag;
            data      <= write_data;
        end
    end

    // Read combinational (asynchronous)
    assign valid = valid_bit;
    assign hit = valid_bit && (tag == read_tag);  // Hit if valid AND tag matches
    assign read_data = data;

endmodule