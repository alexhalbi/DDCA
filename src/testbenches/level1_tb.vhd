
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.txt_util.all;
use work.op_pack.all;
use work.core_pack.all;
use work.mimi;
use work.pipeline;
use work.ocram_altera;


entity level1_tb is
end level1_tb;

architecture arch of level1_tb is
    constant CLK_PERIOD : time := 2 ps;
    signal clk            : std_logic;

    signal s_test_clk_cnt : integer range 0 to 300;

    signal s_reset         : std_logic := '0';
    signal s_mem_in      : mem_in_type := ('0', (others => '0'));
    signal s_intr         : std_logic_vector(INTR_COUNT-1 downto 0) := (others => '0');
    signal r_mem_out     : mem_out_type := ((others => '0'),'0','0', (others => '0'),(others => '0'));
    signal a_mem_out     : mem_out_type := ((others => '0'),'0','0', (others => '0'),(others => '0'));

    signal int_s_reset     : std_logic;
    signal int_s_mem_in : mem_in_type := ('0', (others => '0'));
    signal int_s_intr     : std_logic_vector(INTR_COUNT-1 downto 0);
    signal int_r_mem_out : mem_out_type := ((others => '0'),'0','0', (others => '0'),(others => '0'));
    signal int_a_mem_out : mem_out_type := ((others => '0'),'0','0', (others => '0'),(others => '0'));


    signal clk_cnt     : integer := 0;
    signal testfile : string(8 downto 1);
    signal break_on_error : boolean := false;

    type TEST_TYPE is (NO_TEST, TEST);
    signal has_data     : TEST_TYPE;

    signal fail_count : integer := 0;
    signal total_count : integer := 0;

    procedure check(
        test_nr : in integer;
        signal_name : in string;
        result : in std_logic_vector;
        expected : in std_logic_vector;
                success : inout boolean;
        boe : in boolean) is -- break on error
    begin
        if not std_match(result, expected) then
            if boe = true then
                  assert std_match(result, expected) report str(test_nr) & ": " & signal_name & " result: " & str(result) & " expected: " & str(expected) severity FAILURE;
            else
                assert std_match(result, expected) report str(test_nr) & ": " & signal_name & " result: " & str(result) & " expected: " & str(expected);
                        end if;
            success := false;
        end if;
    end check;

    procedure check(
        test_nr : in integer;
        signal_name : in string;
        result : in std_logic;
        expected : in std_logic;
                success : inout boolean;
        boe : in boolean) is -- break on error
    begin
        if not std_match(result, expected) then
            if boe = true then
                  assert std_match(result, expected) report str(test_nr) & ": " & signal_name & " result: " & chr(result) & " expected: " & chr(expected) severity FAILURE;
            else
                assert std_match(result, expected) report str(test_nr) & ": " & signal_name & " result: " & chr(result) & " expected: " & chr(expected);
                        end if;
            success := false;
        end if;
    end check;

begin

    pipeline_inst : entity pipeline
    port map (
        clk => clk,
        reset => s_reset,
        mem_in => s_mem_in,
        mem_out => r_mem_out,
        intr => s_intr
    );
    
    memory_inst : entity ocram_altera
    port map (
        clock => clk,
        address => r_mem_out.address(11 downto 2),
        byteena => r_mem_out.byteena,
        data => r_mem_out.wrdata,
        wren => r_mem_out.wr,
        q => s_mem_in.rddata
    );

    sync_proc : process
    begin
        clk <= '0';
        wait for CLK_PERIOD;
        clk <= '1';
        wait for CLK_PERIOD;
    end process sync_proc;

    assert_proc : process(clk)
        variable rdline : line;
        file vector_file : text open read_mode is "../src/test.tc";
        variable bin : string(93 downto 1);
        variable vec : std_logic_vector(92 downto 0);
        variable tmp_clk_cnt : integer := -1;
    begin
        if rising_edge(clk) then
            tmp_clk_cnt := tmp_clk_cnt + 1;
            clk_cnt <= tmp_clk_cnt;
            if not endfile(vector_file) then
                --wait for 2 ps;
                readline(vector_file, rdline);
                read(rdline, bin);
                vec := to_std_logic_vector(bin);

                print(output, "############ LINE: " & integer'IMAGE(tmp_clk_cnt) & " ##############");

                s_reset <= vec(92);
                a_mem_out.address <= vec(58 downto 38);
                a_mem_out.rd <= vec(37);
                a_mem_out.wr <= vec(36);
                a_mem_out.byteena <= vec(35 downto 32);
                a_mem_out.wrdata <= vec(31 downto 0);

                has_data <= TEST;

            else
                if has_data = TEST then
                    has_data <= NO_TEST;
                    print(output, "######### EOF of testfile ########");
                                        print(output, str(fail_count) & "/" & str(total_count) & " tests failed.");
                end if;
            end if;
        end if;
    end process assert_proc;

    test_proc : process
        variable success : boolean;
    begin
            wait for 3 ps;
            if has_data = TEST then
                success := true;
                check(clk_cnt, "mem_out.address", r_mem_out.address, a_mem_out.address, success, break_on_error);
                check(clk_cnt, "mem_out.rd", r_mem_out.rd, a_mem_out.rd, success, break_on_error);
                check(clk_cnt, "mem_out.wr", r_mem_out.wr, a_mem_out.wr, success, break_on_error);
                                check(clk_cnt, "mem_out.byteena", r_mem_out.byteena, a_mem_out.byteena, success, break_on_error);
                check(clk_cnt, "mem_out.wrdata", r_mem_out.wrdata, a_mem_out.wrdata, success, break_on_error);

                total_count <= total_count + 1;
                if success = false then
                    fail_count <= fail_count + 1;
                end if;
            else
                assert false report "EOF" severity FAILURE;
            end if;
            wait for 1 ps;
    end process test_proc;
end arch;
