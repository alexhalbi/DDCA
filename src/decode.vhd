library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pack.all;
use work.op_pack.all;
use work.regfile;

entity decode is

    port (
        clk, reset : in  std_logic;
        stall      : in  std_logic;
        flush      : in  std_logic;
        pc_in      : in  std_logic_vector(PC_WIDTH-1 downto 0);
        instr      : in  std_logic_vector(INSTR_WIDTH-1 downto 0);
        wraddr     : in  std_logic_vector(REG_BITS-1 downto 0);
        wrdata     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        regwrite   : in  std_logic;
        pc_out     : out std_logic_vector(PC_WIDTH-1 downto 0);
        exec_op    : out exec_op_type;
        cop0_op    : out cop0_op_type;
        jmp_op     : out jmp_op_type;
        mem_op     : out mem_op_type;
        wb_op      : out wb_op_type;
        exc_dec    : out std_logic);

end decode;

architecture rtl of decode is

    constant INSTR_ZERO : std_logic_vector (INSTR_WIDTH-1 downto 0) := (others => '0');

    -- instruction codes
    constant OP_SPECIAL : std_logic_vector(5 downto 0) := "000000";
    constant OP_REGIMM  : std_logic_vector(5 downto 0) := "000001";
    constant OP_J       : std_logic_vector(5 downto 0) := "000010";
    constant OP_JAL     : std_logic_vector(5 downto 0) := "000011";
    constant OP_BEQ     : std_logic_vector(5 downto 0) := "000100";
    constant OP_BNE     : std_logic_vector(5 downto 0) := "000101";
    constant OP_BLEZ    : std_logic_vector(5 downto 0) := "000110";
    constant OP_BGTZ    : std_logic_vector(5 downto 0) := "000111";
    constant OP_ADDI    : std_logic_vector(5 downto 0) := "001000";
    constant OP_ADDIU   : std_logic_vector(5 downto 0) := "001001";
    constant OP_SLTI    : std_logic_vector(5 downto 0) := "001010";
    constant OP_SLTIU   : std_logic_vector(5 downto 0) := "001011";
    constant OP_ANDI    : std_logic_vector(5 downto 0) := "001100";
    constant OP_ORI     : std_logic_vector(5 downto 0) := "001101";
    constant OP_XORI    : std_logic_vector(5 downto 0) := "001110";
    constant OP_LUI     : std_logic_vector(5 downto 0) := "001111";
    constant OP_COP0    : std_logic_vector(5 downto 0) := "010000";
    constant OP_LB      : std_logic_vector(5 downto 0) := "100000";
    constant OP_LH      : std_logic_vector(5 downto 0) := "100001";
    constant OP_LW      : std_logic_vector(5 downto 0) := "100011";
    constant OP_LBU     : std_logic_vector(5 downto 0) := "100100";
    constant OP_LHU     : std_logic_vector(5 downto 0) := "100101";
    constant OP_SB      : std_logic_vector(5 downto 0) := "101000";
    constant OP_SH      : std_logic_vector(5 downto 0) := "101001";
    constant OP_SW      : std_logic_vector(5 downto 0) := "101011";

    -- instruction func codes
    constant FU_SLL     : std_logic_vector(5 downto 0) := "000000";
    constant FU_SRL     : std_logic_vector(5 downto 0) := "000010";
    constant FU_SRA     : std_logic_vector(5 downto 0) := "000011";
    constant FU_SLLV    : std_logic_vector(5 downto 0) := "000100";
    constant FU_SRLV    : std_logic_vector(5 downto 0) := "000110";
    constant FU_SRAV    : std_logic_vector(5 downto 0) := "000111";
    constant FU_JR      : std_logic_vector(5 downto 0) := "001000";
    constant FU_JALR    : std_logic_vector(5 downto 0) := "001001";
    constant FU_ADD     : std_logic_vector(5 downto 0) := "100000";
    constant FU_ADDU    : std_logic_vector(5 downto 0) := "100001";
    constant FU_SUB     : std_logic_vector(5 downto 0) := "100010";
    constant FU_SUBU    : std_logic_vector(5 downto 0) := "100011";
    constant FU_AND     : std_logic_vector(5 downto 0) := "100100";
    constant FU_OR      : std_logic_vector(5 downto 0) := "100101";
    constant FU_XOR     : std_logic_vector(5 downto 0) := "100110";
    constant FU_NOR     : std_logic_vector(5 downto 0) := "100111";
    constant FU_SLT     : std_logic_vector(5 downto 0) := "101010";
    constant FU_SLTU    : std_logic_vector(5 downto 0) := "101011";

    -- instruction rd codes
    constant RD_BLTZ    : std_logic_vector(4 downto 0) := "00000";
    constant RD_BGEZ    : std_logic_vector(4 downto 0) := "00001";
    constant RD_BLTZAL  : std_logic_vector(4 downto 0) := "10000";
    constant RD_BGEZAL  : std_logic_vector(4 downto 0) := "10001";

    -- instruction rs codes
    constant RS_MFC0    : std_logic_vector(4 downto 0) := "00000";
    constant RS_MTC0    : std_logic_vector(4 downto 0) := "00100";

    -- state machine states
    type DECODER_STATE_TYPE is (RESET_ST, DECODE_ST, READREGISTER, OUTPUT_ST);
    type DECODER_CMD IS (DEC_NOP, DEC_EXEC, DEC_COP0, DEC_JMP, DEC_MEM, DEC_WB);

    -- intern decoder signals
    signal int_pc           : std_logic_vector(PC_WIDTH-1 downto 0);
    signal int_instr        : std_logic_vector(INSTR_WIDTH-1 downto 0);

    -- intern regfile signals
    signal int_rdaddr1      : std_logic_vector(REG_BITS-1 downto 0);
    signal int_rdaddr2      : std_logic_vector(REG_BITS-1 downto 0);
    signal int_rddata1      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal int_rddata2      : std_logic_vector(DATA_WIDTH-1 downto 0);

    alias opcode    : std_logic_vector(5 downto 0)  is int_instr(31 downto 26);
    alias rs        : std_logic_vector(4 downto 0)  is int_instr(25 downto 21);
    alias rt        : std_logic_vector(4 downto 0)  is int_instr(20 downto 16);
    alias rd        : std_logic_vector(4 downto 0)  is int_instr(15 downto 11);
    alias shamt     : std_logic_vector(4 downto 0)  is int_instr(10 downto 6);
    alias func      : std_logic_vector(5 downto 0)  is int_instr(5 downto 0);
    alias adrim     : std_logic_vector(15 downto 0) is int_instr(15 downto 0);
    alias taradr    : std_logic_vector(25 downto 0) is int_instr(25 downto 0);

begin  -- rtl

    -- component deklarations
    regfile_inst : entity regfile
    port map (
        clk         => clk,
        reset       => reset,
        stall       => stall,           -- in
        rdaddr1     => int_rdaddr1,     -- in
        rdaddr2     => int_rdaddr2,     -- in
        rddata1     => int_rddata1,     -- out
        rddata2     => int_rddata2,     -- out
        wraddr      => wraddr,          -- in
        wrdata      => wrdata,          -- in
        regwrite    => regwrite         -- in
    );

    -- ##################### --
    -- process: decode_input --
    -- ##################### --
    decode_input : process (clk, reset)
    begin
        if reset = '0' then
            -- reset intern signals
            int_pc      <= (others => '0');
            int_instr   <= (others => '0');
            int_rdaddr1 <= (others => '0');
            int_rdaddr2 <= (others => '0');
        elsif rising_edge(clk) then
            if flush = '1' then
                -- flush intern signals
                int_pc      <= (others => '0');
                int_instr   <= (others => '0');
                int_rdaddr1 <= (others => '0');
                int_rdaddr2 <= (others => '0');
            elsif stall = '0' then
                -- latch intern signals
                int_pc      <= pc_in;
                int_instr   <= instr;
                int_rdaddr1 <= instr(25 downto 21); -- rs
                int_rdaddr2 <= instr(20 downto 16); -- rt / rd
            end if;
        end if;
    end process decode_input;

    -- ###################### --
    -- process: decode_output --
    -- ###################### --
    decode_output : process (int_pc, int_instr, int_rddata1, int_rddata2)
    begin

        -- set default output signals
        pc_out  <= int_pc;
        exec_op <= EXEC_NOP;
        cop0_op <= COP0_NOP;
        jmp_op  <= JMP_NOP;
        mem_op  <= MEM_NOP;
        wb_op   <= WB_NOP;
        exc_dec <= '0';

        if not (int_instr = INSTR_ZERO) then
            -- ############## start case opcode ############## --
            case opcode is
                when OP_SPECIAL =>
                    -- Format: R    Syntax: --  Semantics:  Table 21
                    --TODO: move wb_op here, isntead of inside case
                    --wb_op.memtoreg  <= '0'; --TODO: do not need
                    --wb_op.regwrite  <= '1';

                    -- ############## start case func ############## --
                    case func is
                        when FU_SLL =>
                            -- Syntax: SLL rd, rt, shamt    Semantics: rd = rt << shamt
                            -- read value from register
                            exec_op.readdata2 <= int_rddata2;

                            -- set output values
                            exec_op.aluop   <= ALU_SLL;
                            exec_op.imm(REG_BITS-1 downto 0) <= shamt;
                            exec_op.rd      <= rd;
                            exec_op.useamt  <= '1';

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when FU_SRL =>
                            -- Syntax: SRL rd, rt, shamt    Semantics: rd = rt0/ >> shamt
                            -- read value from register
                            exec_op.readdata2 <= int_rddata2;

                            -- set output values
                            exec_op.aluop   <= ALU_SRL;
                            exec_op.imm(REG_BITS-1 downto 0) <= shamt;
                            exec_op.rd      <= rd;
                            exec_op.useamt  <= '1';

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when FU_SRA =>
                            -- Syntax: SRA rd, rt, shamt    Semantics: rd = rt± >> shamt
                            -- read value from register
                            exec_op.readdata2 <= int_rddata2;

                            -- set output values
                            exec_op.aluop <= ALU_SRA;
                            exec_op.imm(REG_BITS-1 downto 0) <= shamt;
                            exec_op.rd      <= rd;
                            exec_op.useamt  <= '1';

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when FU_SLLV =>
                            -- Syntax: SLLV rd, rt, rs  Semantics: rd = rt << rs4:0
                            -- read value from register
                            exec_op.readdata1(4 downto 0) <= int_rddata1(4 downto 0);
                            exec_op.readdata2 <= int_rddata2;

                            -- set output values
                            exec_op.aluop   <= ALU_SLL;
                            exec_op.rd      <= rd;

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when FU_SRLV =>
                            -- Syntax: SRLV rd, rt, rs  Semantics: rd = rt0/ >> rs4:0
                            -- read value from register
                            exec_op.readdata1(4 downto 0) <= int_rddata1(4 downto 0);
                            exec_op.readdata2 <= int_rddata2;

                            -- set output values
                            exec_op.aluop   <= ALU_SRL;
                            exec_op.rd      <= rd;

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when FU_SRAV =>
                            -- Syntax: SRAV rd, rt, rs  Semantics: rd = rt±>> rs4:0
                            -- read value from register
                            exec_op.readdata1(4 downto 0) <= int_rddata1(4 downto 0);
                            exec_op.readdata2 <= int_rddata2;

                            -- set output values
                            exec_op.aluop   <= ALU_SRA;
                            exec_op.rd      <= rd;

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when FU_JR =>
                            -- Syntax: JR rs            Semantics: pc = rs
                            -- read value from register
                            exec_op.readdata1 <= int_rddata1;

                            -- set output values
                            exec_op.aluop   <= ALU_NOP;  --TODO: do not need
                            jmp_op          <= JMP_JMP;

                        when FU_JALR =>
                            -- Syntax: JALR rd, rs      Semantics: rd = pc+4; pc = rs
                            -- read value from register
                            exec_op.readdata1 <= int_rddata1;

                            -- set output values
                            exec_op.aluop   <= ALU_NOP;  --TODO: do not need
                            exec_op.rd      <= rd;
                            exec_op.link    <= '1';

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when FU_ADD =>
                            -- Syntax: ADD rd, rs, rt   Semantics: rd = rs + rt, overflow trap
                            -- read value from register
                            exec_op.readdata1 <= int_rddata1;
                            exec_op.readdata2 <= int_rddata2;

                            -- set output values
                            exec_op.aluop   <= ALU_ADD;
                            exec_op.rd      <= rd;
                            exec_op.ovf     <= '1';

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when FU_ADDU =>
                            -- Syntax: ADDU rd, rs, rt  Semantics: rd = rs + rt
                            -- read value from register
                            exec_op.readdata1 <= int_rddata1;
                            exec_op.readdata2 <= int_rddata2;

                            -- set output values
                            exec_op.aluop   <= ALU_ADD;
                            exec_op.rd      <= rd;

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when FU_SUB =>
                            -- Syntax: SUB rd, rs, rt   Semantics: rd = rs - rt, overflow trap
                            -- read value from register
                            exec_op.readdata1 <= int_rddata1;
                            exec_op.readdata2 <= int_rddata2;

                            -- set output values
                            exec_op.aluop   <= ALU_SUB;
                            exec_op.rd      <= rd;
                            exec_op.ovf     <= '1';

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when FU_SUBU =>
                            -- Syntax: SUBU rd, rs, rt  Semantics: rd = rs - rt
                            -- read value from register
                            exec_op.readdata1 <= int_rddata1;
                            exec_op.readdata2 <= int_rddata2;

                            -- set output values
                            exec_op.aluop   <= ALU_SUB;
                            exec_op.rd      <= rd;

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when FU_AND =>
                            -- Syntax: AND rd, rs, rt   Semantics: rd = rs & rt
                            -- read value from register
                            exec_op.readdata1 <= int_rddata1;
                            exec_op.readdata2 <= int_rddata2;

                            -- set output values
                            exec_op.aluop   <= ALU_AND;
                            exec_op.rd      <= rd;

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when FU_OR =>
                            -- Syntax: AND rd, rs, rt   Semantics: rd = rs & rt
                            -- read value from register
                            exec_op.readdata1 <= int_rddata1;
                            exec_op.readdata2 <= int_rddata2;

                            -- set output values
                            exec_op.aluop   <= ALU_OR;
                            exec_op.rd      <= rd;

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when FU_XOR =>
                            -- Syntax: XOR rd, rs, rt   Semantics: rd = rs ^ rt
                            -- read value from register
                            exec_op.readdata1 <= int_rddata1;
                            exec_op.readdata2 <= int_rddata2;

                            -- set output values
                            exec_op.aluop   <= ALU_XOR;
                            exec_op.rd      <= rd;

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when FU_NOR =>
                            -- Syntax: NOR rd, rs, rt   Semantics: rd = ~(rs | rt)
                            -- read value from register
                            exec_op.readdata1 <= int_rddata1;
                            exec_op.readdata2 <= int_rddata2;

                            -- set output values
                            exec_op.aluop   <= ALU_NOR;
                            exec_op.rd      <= rd;

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when FU_SLT =>
                            -- Syntax: SLT rd, rs, rt   Semantics: rd = (rs± < rt±) ? 1 : 0
                            -- read value from register
                            exec_op.readdata1 <= int_rddata1;
                            exec_op.readdata2 <= int_rddata2;

                            -- set output values
                            exec_op.aluop   <= ALU_SLT;
                            exec_op.rd      <= rd;

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when FU_SLTU =>
                            -- Syntax: SLTU rd, rs, rt  Semantics: rd = (rs0/ < rt0/ ) ? 1 : 0
                            -- read value from register
                            exec_op.readdata1 <= int_rddata1;
                            exec_op.readdata2 <= int_rddata2;

                            -- set output values
                            exec_op.aluop   <= ALU_SLTU;
                            exec_op.rd      <= rd;

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                        when others =>
                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '0';
                    end case;
                    -- ############## end case func ############## --
                when OP_REGIMM =>
                    -- Format: I    Syntax: --  Semantics: Table 22

                    -- ############## start case rd ############## --
                    case rd is
                        when RD_BLTZ =>
                            -- Syntax: BLTZ rs, imm18   Semantics: if (rs±< 0) pc += imm±<< 2
                            -- read value from register
                            exec_op.readdata1 <= int_rddata1;

                            -- set output values
                            exec_op.aluop   <= ALU_NOP;
                            -- sign extend and shift imm
                            exec_op.imm     <= (others => adrim(15));
                            exec_op.imm(1 downto 0)  <= "00";
                            exec_op.imm(17 downto 2) <= adrim(15 downto 0);
                            --exec_op.useimm  <= '1';
                            exec_op.branch  <= '1';

                            jmp_op  <= JMP_BLTZ;

                        when RD_BGEZ =>
                            -- Syntax: BGEZ rs, imm18   Semantics: if (rs±>= 0) pc += imm±<< 2
                            -- read value from register
                            exec_op.readdata1 <= int_rddata1;

                            -- set output values
                            exec_op.aluop   <= ALU_NOP;
                            -- sign extend and shift imm
                            exec_op.imm     <= (others => adrim(15));
                            exec_op.imm(1 downto 0)  <= "00";
                            exec_op.imm(17 downto 2) <= adrim(15 downto 0);
                            --exec_op.useimm  <= '1';
                            exec_op.branch  <= '1';

                            jmp_op  <= JMP_BGEZ;

                        when RD_BLTZAL =>
                            -- Syntax: BLTZAL rs, imm18 Semantics: r31 = pc+4; if (rs±< 0) pc += imm±<< 2
                            -- read value from register
                            exec_op.readdata1 <= int_rddata1;

                            -- set output values
                            exec_op.aluop   <= ALU_NOP;
                            exec_op.rd      <= std_logic_vector(to_unsigned(31, REG_BITS));
                            -- sign extend and shift imm
                            exec_op.imm     <= (others => adrim(15));
                            exec_op.imm(1 downto 0)  <= "00";
                            exec_op.imm(17 downto 2) <= adrim(15 downto 0);

                            exec_op.link    <= '1';
                            exec_op.branch  <= '1';

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                            jmp_op  <= JMP_BLTZ;

                        when RD_BGEZAL =>
                            -- Syntax: BGEZAL rs, imm18 Semantics: r31 = pc+4; if (rs±>= 0) pc += imm±<< 2
                            -- read value from register
                            exec_op.readdata1 <= int_rddata1;

                            -- set output values
                            exec_op.aluop   <= ALU_NOP;
                            exec_op.rd      <= std_logic_vector(to_unsigned(31, REG_BITS));
                            -- sign extend and shift imm
                            exec_op.imm     <= (others => adrim(15));
                            exec_op.imm(1 downto 0)  <= "00";
                            exec_op.imm(17 downto 2) <= adrim(15 downto 0);

                            exec_op.link    <= '1';
                            exec_op.branch  <= '1';

                            wb_op.memtoreg  <= '0'; --TODO: do not need
                            wb_op.regwrite  <= '1';

                            jmp_op  <= JMP_BGEZ;

                        when others =>
                            -- do nothing
                            null;
                    end case;
                    -- ############## end case rd ############## --
                when OP_J =>
                    -- Format: J    Syntax: J address   Semantics: pc = address0/ << 2
                    -- set output values
                    exec_op.aluop   <= ALU_NOP;
                    exec_op.readdata1(PC_WIDTH+1 downto 2) <= taradr(PC_WIDTH-1 downto 0);

                    jmp_op  <= JMP_JMP;

                when OP_JAL =>
                    -- Format: J    Syntax: JAL address   Semantics: r31 = pc+4; pc = address0/ << 2
                    -- set output values
                    exec_op.aluop   <= ALU_NOP;
                    exec_op.readdata1(PC_WIDTH+1 downto 2) <= taradr(PC_WIDTH-1 downto 0);
                    exec_op.rd      <= std_logic_vector(to_unsigned(31, REG_BITS));
                    exec_op.link    <= '1';

                    wb_op.memtoreg  <= '0'; --TODO: do not need
                    wb_op.regwrite  <= '1';

                    jmp_op  <= JMP_JMP;

                when OP_BEQ =>
                    -- Format: I    Syntax: BEQ rd, rs, imm18   Semantics: if (rs == rd) pc += imm± << 2
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;
                    exec_op.readdata2 <= int_rddata2;

                    -- set output values
                    exec_op.aluop   <= ALU_SUB;
                    -- sign extend and shift imm
                    exec_op.imm     <= (others => adrim(15));
                    exec_op.imm(1 downto 0)  <= "00";
                    exec_op.imm(17 downto 2) <= adrim(15 downto 0);

                    exec_op.branch  <= '1';

                    jmp_op  <= JMP_BEQ;

                when OP_BNE =>
                    -- Format: I    Syntax: BNE rd, rs, imm18   Semantics: if (rs != rd) pc += imm± << 2
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;
                    exec_op.readdata2 <= int_rddata2;

                    -- set output values
                    exec_op.aluop   <= ALU_SUB;
                    -- sign extend and shift imm
                    exec_op.imm     <= (others => adrim(15));
                    exec_op.imm(1 downto 0)  <= "00";
                    exec_op.imm(17 downto 2) <= adrim(15 downto 0);

                    exec_op.branch  <= '1';

                    jmp_op  <= JMP_BNE;

                when OP_BLEZ =>
                    -- Format: I    Syntax:  BLEZ rs, imm18   Semantics: if (rs±<= 0) pc += imm± << 2
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;

                    -- set output values
                    exec_op.aluop   <= ALU_NOP;
                    -- sign extend and shift imm
                    exec_op.imm     <= (others => adrim(15));
                    exec_op.imm(1 downto 0)  <= "00";
                    exec_op.imm(17 downto 2) <= adrim(15 downto 0);

                    exec_op.branch  <= '1';

                    jmp_op  <= JMP_BLTZ;

                when OP_BGTZ =>
                    -- Format: I    Syntax:  BGTZ rs, imm18   Semantics: if (rs±> 0) pc += imm± << 2
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;

                    -- set output values
                    exec_op.aluop   <= ALU_NOP;
                    -- sign extend and shift imm
                    exec_op.imm     <= (others => adrim(15));
                    exec_op.imm(1 downto 0)  <= "00";
                    exec_op.imm(17 downto 2) <= adrim(15 downto 0);

                    exec_op.branch  <= '1';

                    jmp_op  <= JMP_BGTZ;

                when OP_ADDI =>
                    -- Format: I    Syntax:  ADDI rd, rs, imm16   Semantics: rd = rs + imm±, overflow trap
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;

                    -- set output values
                    exec_op.aluop   <= ALU_ADD;
                    exec_op.rd      <= rd;
                    -- sign extend imm
                    exec_op.imm     <= (others => adrim(15));
                    exec_op.imm(15 downto 0) <= adrim(15 downto 0);
                    exec_op.useimm  <= '1';
                    exec_op.ovf     <= '1';

                    wb_op.memtoreg  <= '0'; --TODO: do not need
                    wb_op.regwrite  <= '1';

                when OP_ADDIU =>
                    -- Format: I    Syntax: ADDIU rd, rs, imm16    Semantics: rd = rs + imm±
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;

                    -- set output values
                    exec_op.aluop   <= ALU_ADD;
                    exec_op.rd      <= rd;
                    -- sign extend imm
                    exec_op.imm     <= (others => adrim(15));
                    exec_op.imm(15 downto 0) <= adrim(15 downto 0);
                    exec_op.useimm  <= '1';

                    wb_op.memtoreg  <= '0'; --TODO: do not need
                    wb_op.regwrite  <= '1';

                when OP_SLTI =>
                    -- Format: I    Syntax: SLTI rd, rs, imm16   Semantics: rd = (rs± < imm±) ? 1 : 0
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;

                    -- set output values
                    exec_op.aluop   <= ALU_SLT;
                    exec_op.rd      <= rd;
                    -- sign extend imm
                    exec_op.imm     <= (others => adrim(15));
                    exec_op.imm(15 downto 0) <= adrim(15 downto 0);
                    exec_op.useimm  <= '1';

                    wb_op.memtoreg  <= '0'; --TODO: do not need
                    wb_op.regwrite  <= '1';

                when OP_SLTIU =>
                    -- Format: I    Syntax: SLTIU rd, rs, imm16    Semantics: rd = (rs0/ < imm0/) ? 1 : 0
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;

                    -- set output values
                    exec_op.aluop   <= ALU_SLTU;
                    exec_op.rd      <= rd;
                    -- zero extend imm
                    exec_op.imm     <= (others => '0'); --TODO not really needed
                    exec_op.imm(15 downto 0) <= adrim(15 downto 0);
                    exec_op.useimm  <= '1';

                    wb_op.memtoreg  <= '0'; --TODO: do not need
                    wb_op.regwrite  <= '1';

                when OP_ANDI =>
                    -- Format: I    Syntax: ANDI rd, rs, imm16   Semantics: rd = rs & imm0
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;

                    -- set output values
                    exec_op.aluop   <= ALU_AND;
                    exec_op.rd      <= rd;
                    -- zero extend imm
                    exec_op.imm     <= (others => '0'); --TODO not really needed
                    exec_op.imm(15 downto 0) <= adrim(15 downto 0);
                    exec_op.useimm  <= '1';

                    wb_op.memtoreg  <= '0'; --TODO: do not need
                    wb_op.regwrite  <= '1';

                when OP_ORI =>
                    -- Format: I    Syntax:  ORI rd, rs, imm16   Semantics: rd = rs | imm0
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;

                    -- set output values
                    exec_op.aluop   <= ALU_OR;
                    exec_op.rd      <= rd;
                    -- zero extend imm
                    exec_op.imm     <= (others => '0'); --TODO not really needed
                    exec_op.imm(15 downto 0) <= adrim(15 downto 0);
                    exec_op.useimm  <= '1';

                    wb_op.memtoreg  <= '0'; --TODO: do not need
                    wb_op.regwrite  <= '1';

                when OP_XORI =>
                    -- Format: I    Syntax:  XORI rd, rs, imm16   Semantics: rd = rs ^ imm0
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;

                    -- set output values
                    exec_op.aluop   <= ALU_XOR;
                    exec_op.rd      <= rd;
                    -- zero extend imm
                    exec_op.imm     <= (others => '0'); --TODO not really needed
                    exec_op.imm(15 downto 0) <= adrim(15 downto 0);
                    exec_op.useimm  <= '1';

                    wb_op.memtoreg  <= '0'; --TODO: do not need
                    wb_op.regwrite  <= '1';

                when OP_LUI =>
                    -- Format: I    Syntax:  LUI rd, imm16   Semantics: rd = imm0/ << 16
                    -- set output values
                    exec_op.aluop   <= ALU_LUI;
                    exec_op.rd      <= rd;
                    -- zero extend imm
                    exec_op.imm     <= (others => '0'); --TODO not really needed
                    exec_op.imm(15 downto 0) <= adrim(15 downto 0);
                    exec_op.useimm  <= '1';

                    wb_op.memtoreg  <= '0'; --TODO: do not need
                    wb_op.regwrite  <= '1';

                when OP_COP0 =>
                    -- Format: R    Syntax: --   Semantics: Table 23
                    -- ############## start case rs ############## --
                    case rs is
                        when RS_MFC0 =>
                            -- Syntax: MFC0 rt, rd Semantics: rt = rd, rd register in coprocessor 0
                            --TODO
                            null;
                        when RS_MTC0 =>
                            -- Syntax: MTC0 rt, rd Semantics: rd = rt, rd register in coprocessor 0
                            --TODO: set cop0=1
                            null;
                        when others =>
                            -- do nothing
                            null;
                    end case;
                    -- ############## end case rs ############## --
                when OP_LB =>
                    -- Format: I    Syntax:  LB rd, imm16(rs)    Semantics: rd = (int8_t)[rs+imm±]
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;

                    -- set output values
                    exec_op.aluop   <= ALU_ADD;
                    exec_op.rd      <= rd;
                    -- sign extend imm
                    exec_op.imm     <= (others => adrim(15));
                    exec_op.imm(15 downto 0) <= adrim(15 downto 0);
                    exec_op.useimm  <= '1';

                    mem_op.memtype  <= MEM_B;
                    mem_op.memread  <= '1';
                    mem_op.memwrite <= '0'; --TODO: do not need

                    wb_op.memtoreg  <= '1';
                    wb_op.regwrite  <= '1';

                when OP_LH =>
                    -- Format: I    Syntax: LH rd, imm16(rs)   Semantics: rd = (int16_t)[rs+imm±]
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;

                    -- set output values
                    exec_op.aluop   <= ALU_ADD;
                    exec_op.rd      <= rd;
                    -- sign extend imm
                    exec_op.imm     <= (others => adrim(15));
                    exec_op.imm(15 downto 0) <= adrim(15 downto 0);
                    exec_op.useimm  <= '1';

                    mem_op.memtype  <= MEM_H;
                    mem_op.memread  <= '1';
                    mem_op.memwrite <= '0'; --TODO: do not need

                    wb_op.memtoreg  <= '1';
                    wb_op.regwrite  <= '1';

                when OP_LW =>
                    -- Format: I    Syntax: LW rd, imm16(rs)   Semantics: rd = (int32_t)[rs+imm±]
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;

                    -- set output values
                    exec_op.aluop   <= ALU_ADD;
                    exec_op.rd      <= rd;
                    -- sign extend imm
                    exec_op.imm     <= (others => adrim(15));
                    exec_op.imm(15 downto 0) <= adrim(15 downto 0);
                    exec_op.useimm  <= '1';

                    mem_op.memtype  <= MEM_W;
                    mem_op.memread  <= '1';
                    mem_op.memwrite <= '0'; --TODO: do not need

                    wb_op.memtoreg  <= '1';
                    wb_op.regwrite  <= '1';

                when OP_LBU =>
                    -- Format: I    Syntax: LBU rd, imm16(rs)   Semantics: rd = (uint8_t)[rs+imm±]
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;

                    -- set output values
                    exec_op.aluop   <= ALU_ADD;
                    exec_op.rd      <= rd;
                    -- sign extend imm
                    exec_op.imm     <= (others => adrim(15));
                    exec_op.imm(15 downto 0) <= adrim(15 downto 0);
                    exec_op.useimm  <= '1';

                    mem_op.memtype  <= MEM_BU;
                    mem_op.memread  <= '1';
                    mem_op.memwrite <= '0'; --TODO: do not need

                    wb_op.memtoreg  <= '1';
                    wb_op.regwrite  <= '1';

                when OP_LHU =>
                    -- Format: I    Syntax:  LHU rd, imm16(rs)   Semantics: rd = (uint16_t)[rs+imm±]
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;

                    -- set output values
                    exec_op.aluop   <= ALU_ADD;
                    exec_op.rd      <= rd;
                    -- sign extend imm
                    exec_op.imm     <= (others => adrim(15));
                    exec_op.imm(15 downto 0) <= adrim(15 downto 0);
                    exec_op.useimm  <= '1';

                    mem_op.memtype  <= MEM_HU;
                    mem_op.memread  <= '1';
                    mem_op.memwrite <= '0'; --TODO: do not need

                    wb_op.memtoreg  <= '1';
                    wb_op.regwrite  <= '1';

                when OP_SB =>
                    -- Format: I    Syntax:  SB rd, imm16(rs)   Semantics: (int8_t)[rs+imm±] = rd7:0
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;
                    exec_op.readdata2 <= (others => '0'); --TODO: do not need
                    exec_op.readdata2(7 downto 0) <= int_rddata2(7 downto 0);

                    -- set output values
                    exec_op.aluop   <= ALU_ADD;
                    exec_op.rd      <= rd;
                    -- sign extend imm
                    exec_op.imm     <= (others => adrim(15));
                    exec_op.imm(15 downto 0) <= adrim(15 downto 0);
                    exec_op.useimm  <= '1';

                    mem_op.memtype  <= MEM_B;
                    mem_op.memread  <= '0'; --TODO: do not need
                    mem_op.memwrite <= '1';

                when OP_SH =>
                    -- Format: I    Syntax: SH rd, imm16(rs)   Semantics: (int16_t)[rs+imm±] = rd15:0
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;
                    exec_op.readdata2 <= (others => '0'); --TODO: do not need
                    exec_op.readdata2(15 downto 0) <= int_rddata2(15 downto 0);

                    -- set output values
                    exec_op.aluop   <= ALU_ADD;
                    exec_op.rd      <= rd;
                    -- sign extend imm
                    exec_op.imm     <= (others => adrim(15));
                    exec_op.imm(15 downto 0) <= adrim(15 downto 0);
                    exec_op.useimm  <= '1';

                    mem_op.memtype  <= MEM_H;
                    mem_op.memread  <= '0'; --TODO: do not need
                    mem_op.memwrite <= '1';

                when OP_SW =>
                    -- Format: I    Syntax:  SW rd, imm16(rs)   Semantics: (int32_t)[rs+imm±] = rd
                    -- read value from register
                    exec_op.readdata1 <= int_rddata1;
                    exec_op.readdata2 <= int_rddata2;

                    -- set output values
                    exec_op.aluop   <= ALU_ADD;
                    exec_op.rd      <= rd;
                    -- sign extend imm
                    exec_op.imm     <= (others => adrim(15));
                    exec_op.imm(15 downto 0) <= adrim(15 downto 0);
                    exec_op.useimm  <= '1';

                    mem_op.memtype  <= MEM_W;
                    mem_op.memread  <= '0'; --TODO: do not need
                    mem_op.memwrite <= '1';

                when others =>
                    -- do nothing
                    null;
            end case;
            -- ############## end case opcode ############## --

        end if;

    end process decode_output;

end rtl;
