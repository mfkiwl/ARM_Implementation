module ARM (input clk,
            rst);
    wire flush, freeze, BranchTaken;
    assign flush       = 1'b0;
    assign freeze      = 1'b0;
    assign BranchTaken = 1'b0;
    wire[31:0] BranchAddress;
    assign BranchAddress = 32'b0;
    
    // ################################# Instruction Fetch Stage: ###################################
    wire[31:0] if_pc_in, if_instruction_in, if_pc_out, if_instruction_out;
    IF_Stage if_stage(
        clk, 
        rst, 
        freeze, 
        BranchTaken,
        BranchAddress,
        if_pc_in,
        if_instruction_in
    );
    IF_Stage_Reg if_stage_reg(
        clk,
        rst, 
        flush, 
        freeze, 
        if_pc_in, 
        if_instruction_in, 
        if_pc_out, 
        if_instruction_out
    );
    
    // ################################## Instruction Decode Stage: #################################
    wire[31:0] id_pc_in, id_pc_out;
    wire id_mem_r_en_in, id_mem_w_en_in, id_wb_en_in, id_status_w_en_in, id_branch_taken_in, id_imm_in;
    wire[3:0] id_exec_cmd_in;
    wire[31:0] id_val_rm_in, id_val_rn_in;
    wire[23:0] id_signed_immed_24_in;
    wire[3:0] id_dest_in; 
    wire[11:0] id_shift_operand_in;
    wire id_mem_r_en_out, id_mem_w_en_out, id_wb_en_out, id_status_w_en_out, id_branch_taken_out, id_imm_out;
    wire[3:0] id_exec_cmd_out;
    wire[31:0] id_val_rm_out, id_val_rn_out;
    wire[23:0] id_signed_immed_24_out;
    wire[3:0] id_dest_out;
    wire[11:0] id_shift_operand_out;

    ID_Stage id_stage(
        clk, rst,
        if_pc_out, 
        if_instruction_out,
        id_pc_in,
        id_mem_r_en_in, id_mem_w_en_in, id_wb_en_in, id_status_w_en_in, id_branch_taken_in, id_imm_in,
        id_exec_cmd_in,
        id_val_rm_in, id_val_rn_in,
        id_signed_immed_24_in,
        id_dest_in,
        id_shift_operand_in
    );

    ID_Stage_Reg id_stage_reg(
        clk, rst, flush, freeze,
        id_pc_in, 
        id_mem_r_en_in, id_mem_w_en_in, id_wb_en_in, id_status_w_en_in, id_branch_taken_in, id_imm_in,
        id_exec_cmd_in,
        id_val_rm_in, id_val_rn_in,
        id_signed_immed_24_in,
        id_dest_in,
        id_shift_operand_in,
        id_pc_out,
        id_mem_r_en_out, id_mem_w_en_out, id_wb_en_out, id_status_w_en_out, id_branch_taken_out, id_imm_out,
        id_exec_cmd_out,
        id_val_rm_out, id_val_rn_out,
        id_signed_immed_24_out,
        id_dest_out,
        id_shift_operand_out
    );

    // ################################### Executaion Stage: ################################
    wire[31:0] exe_pc_in, exe_pc_out;

    wire [31:0] exe_branch_address_in;
    wire [3:0] exe_alu_status_in;

    wire exe_wb_en_in, exe_mem_r_en_in, exe_mem_w_en_in;
    wire [31:0] exe_alu_res_in;
    wire [31:0] exe_val_rm_in;
    wire [3:0] exe_dest_in;

    wire exe_wb_en_out, exe_mem_r_en_out, exe_mem_w_en_out;
    wire [31:0] exe_alu_res_out;
    wire [31:0] exe_val_rm_out;
    wire [3:0] exe_dest_out;

    EXE_Stage exe_stage(
        .clk(clk), .rst(rst),
        .PC_in(id_pc_out),
        .mem_r_en(id_mem_r_en_out), .mem_w_en(id_mem_w_en_out), 
        .wb_en(id_wb_en_out), .imm(id_imm_out),
        input carry_in, //TODO: should be added to ID_Stage_Reg
        .shift_operand(id_shift_operand_out),
        .exec_cmd(id_exec_cmd_out),
        .val_rm(id_val_rm_out), .val_rn(id_val_rn_out),
        .signed_immed_24(id_signed_immed_24_out),
        .dest(id_dest_out),

        .branch_address(exe_branch_address_in),
        .alu_status(exe_alu_status_in),

        .PC(exe_pc_in),
        .wb_en_out(exe_wb_en_in), mem_r_en_out(exe_mem_r_en_in), mem_w_en_out(exe_mem_w_en_in),
        .alu_res(exe_alu_res_in),
        .val_rm_out(exe_val_rm_in),
        .dest_out(exe_dest_in)
    );
    EXE_Stage_Reg exe_stage_reg(
        .clk(clk), .rst(rst), .flush(flush), .freeze(freeze),
        .pc_in(exe_pc_in), 
        .wb_en_in(exe_wb_en_in), .mem_r_en_in(exe_mem_r_en_in), .mem_w_en_in(exe_mem_r_en_in),
        .alu_res_in(exe_alu_res_in),
        .val_rm_in(exe_val_rm_in),
        .dest_in(exe_dest_in),

        .pc(exe_pc_out),
        .wb_en(exe_wb_en_out), .mem_r_en(exe_mem_r_en_out), .mem_w_en(exe_mem_w_en_out),
        .alu_res(exe_alu_res_out),
        .val_rm(exe_val_rm_out),
        .dest(exe_dest_out)
    );

    // ################################# Status Register: ############################################

    // ################################# Memory Stage: ############################################
    wire[31:0] mem_pc_in, mem_pc_out;
    MEM_Stage mem_stage(
        clk, 
        rst, 
        exe_pc_out, 
        mem_pc_in
    );
    MEM_Stage_Reg mem_stage_reg(
        clk, 
        rst, 
        flush, 
        freeze,
        mem_pc_in, 
        mem_pc_out
    );

    // ################################### Write Block Stage: #######################################
    wire[31:0] wb_pc_in, wb_pc_out;
    WB_Stage wb_stage(
        clk, 
        rst, 
        mem_pc_out, 
        wb_pc_in
    );
    WB_Stage_Reg wb_stage_reg(
        clk, 
        rst, 
        flush, 
        freeze,
        wb_pc_in, 
        wb_pc_out
    ); 
    
endmodule
