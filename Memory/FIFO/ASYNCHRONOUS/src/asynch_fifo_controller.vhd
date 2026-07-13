----------------------------------------------------------------------------------
-- Company      :
-- Engineer     : Shekhar Mishra
--
-- Create Date  : 10.07.2026
-- Module Name  : async_fifo_controller
-- Project Name : FPGA Design Library
-- Target Device: Generic FPGA
--
-- Description:
--
--   Parameterizable Asynchronous FIFO Controller.
--
--   This module implements the control logic required for a dual-clock
--   asynchronous FIFO. Independent write and read pointer logic operate in
--   separate clock domains while safely exchanging pointer information using
--   Gray-code encoding and multi-stage clock-domain synchronizers.
--
--   Features:
--     • Independent write and read clock domains
--     • Binary pointer implementation with additional wrap-around bit
--     • Gray-code conversion for CDC
--     • Multi-stage pointer synchronizers
--     • Configurable FIFO depth
--     • Full / Empty flag generation
--     • Almost Full / Almost Empty flag generation
--     • Memory read/write enable generation
--     • Generic synchronizer depth
--     • FPGA friendly implementation
--
--   Design Methodology:
--
--      Write Domain                  Read Domain
--
--      Binary Pointer               Binary Pointer
--            │                           │
--            ▼                           ▼
--      Gray Conversion             Gray Conversion
--            │                           │
--            │                           │
--            ├──────► CDC ◄──────────────┤
--            │                           │
--            ▼                           ▼
--      Gray → Binary               Gray → Binary
--            │                           │
--            ▼                           ▼
--      Full Logic                 Empty Logic
--
--   Notes:
--     • FIFO depth must be a power of two.
--     • Gray coding ensures only one bit changes between adjacent pointer
--       values, minimizing sampling ambiguity during clock domain crossing.
--     • Occupancy calculations are performed independently in each clock
--       domain using synchronized pointers.
--     • Full and Empty flags are generated entirely within their respective
--       clock domains.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.basic_package.ALL;

entity async_fifo_controller is

    generic(

        ----------------------------------------------------------------------
        -- FIFO storage depth.
        -- Must be a power of two.
        ----------------------------------------------------------------------
        FIFO_DEPTH : natural := 16;

        ----------------------------------------------------------------------
        -- Assert Almost Full when occupancy reaches this value.
        ----------------------------------------------------------------------
        ALMOST_FULL_THRESHOLD : natural := 14;

        ----------------------------------------------------------------------
        -- Assert Almost Empty when occupancy falls below or equals this value.
        ----------------------------------------------------------------------
        ALMOST_EMPTY_THRESHOLD : natural := 2;

        ----------------------------------------------------------------------
        -- Number of synchronization stages used for CDC.
        -- Two stages are recommended for most FPGA applications.
        ----------------------------------------------------------------------
        CDC_STAGES : natural := 2

    );

    port(

        ----------------------------------------------------------------------
        -- Write Clock Domain
        ----------------------------------------------------------------------
        clk_wr       : in std_logic;
        rst_wr       : in std_logic;
        wr_domain_en : in std_logic;
        wr_en        : in std_logic;

        ----------------------------------------------------------------------
        -- Read Clock Domain
        ----------------------------------------------------------------------
        clk_rd       : in std_logic;
        rst_rd       : in std_logic;
        rd_domain_en : in std_logic;
        rd_en        : in std_logic;

        ----------------------------------------------------------------------
        -- FIFO Status Flags
        ----------------------------------------------------------------------
        full         : out std_logic;
        almost_full  : out std_logic;

        empty        : out std_logic;
        almost_empty : out std_logic;

        ----------------------------------------------------------------------
        -- Memory Control Interface
        ----------------------------------------------------------------------
        mem_wr       : out std_logic;
        mem_rd       : out std_logic;

        ----------------------------------------------------------------------
        -- Memory Address Interface
        ----------------------------------------------------------------------
        wr_ptr       : out std_logic_vector(clog2(FIFO_DEPTH)-1 downto 0);
        rd_ptr       : out std_logic_vector(clog2(FIFO_DEPTH)-1 downto 0)

    );

end async_fifo_controller;

architecture Behavioral of async_fifo_controller is

    --------------------------------------------------------------------------
    -- Local Constants
    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    -- Number of address bits required to address FIFO memory.
    -- An additional MSB is used internally to detect pointer wrap-around.
    --------------------------------------------------------------------------
    constant PTR_WIDTH : natural := clog2(FIFO_DEPTH);

   
    -- Pointer Registers
    --
    -- Binary pointers include one additional wrap-around bit used to
    -- distinguish between Full and Empty conditions.
    --------------------------------------------------------------------------
    signal wr_ptr_reg       : unsigned(PTR_WIDTH downto 0);
    signal wr_ptr_next      : unsigned(PTR_WIDTH downto 0);

    signal rd_ptr_reg       : unsigned(PTR_WIDTH downto 0);
    signal rd_ptr_next      : unsigned(PTR_WIDTH downto 0);

    --------------------------------------------------------------------------
    -- Gray-Coded Pointers
    --
    -- Gray pointers are transferred across clock domains because only one
    -- bit changes between adjacent pointer values.
    --------------------------------------------------------------------------
    signal wr_ptr_gray_reg      : unsigned(PTR_WIDTH downto 0);
    signal rd_ptr_gray_reg      : unsigned(PTR_WIDTH downto 0);
    
    --------------------------------------------------------------------------
    -- Synchronized Gray Pointers
    --
    -- These pointers have safely crossed into the opposite clock domain
    -- through the N-stage synchronizer.
    --------------------------------------------------------------------------
    signal rd_ptr_gray_wr_sync : std_logic_vector(PTR_WIDTH downto 0);
    signal wr_ptr_gray_rd_sync : std_logic_vector(PTR_WIDTH downto 0);

    --------------------------------------------------------------------------
    -- Binary Pointers After Synchronization
    --
    -- Gray pointers are converted back into binary for occupancy calculation
    -- and Full / Empty comparisons.
    --------------------------------------------------------------------------
    signal rd_ptr_bin_wr_sync : unsigned(PTR_WIDTH downto 0);
    signal wr_ptr_bin_rd_sync : unsigned(PTR_WIDTH downto 0);

    --------------------------------------------------------------------------
    -- FIFO Occupancy Counters
    --
    -- Occupancy is computed independently in each clock domain using the
    -- local pointer and the synchronized remote pointer.
    --------------------------------------------------------------------------
    signal fifo_count_at_wr : unsigned(PTR_WIDTH downto 0);
    signal fifo_count_at_rd : unsigned(PTR_WIDTH downto 0);

    --------------------------------------------------------------------------
    -- Internal Status Flags
    --------------------------------------------------------------------------
    signal f_full         : std_logic;
    signal f_empty        : std_logic;
    signal wr_allow       : std_logic;
    signal rd_allow       : std_logic;
begin
     --------------------------------------------------------------------------
    -- Generic Validation
    --------------------------------------------------------------------------
    --------------------------------------------------------------------------
    -- Ensure FIFO depth is valid.
    --------------------------------------------------------------------------
    assert FIFO_DEPTH > 1
    report "FIFO_DEPTH must be greater than one."
    severity failure;

    --------------------------------------------------------------------------
    -- Ensure FIFO depth is power of 2.
    --------------------------------------------------------------------------
    assert (2**PTR_WIDTH = FIFO_DEPTH)
    report "FIFO_DEPTH must be a power of two."
    severity failure;
    --------------------------------------------------------------------------
    -- Validate Almost Full threshold.
    --------------------------------------------------------------------------
    assert ALMOST_FULL_THRESHOLD <= FIFO_DEPTH
    report "ALMOST_FULL_THRESHOLD exceeds FIFO depth."
    severity failure;

    --------------------------------------------------------------------------
    -- Validate Almost Empty threshold.
    --------------------------------------------------------------------------
    assert ALMOST_EMPTY_THRESHOLD <= FIFO_DEPTH
    report "ALMOST_EMPTY_THRESHOLD exceeds FIFO depth."
    severity failure;


        --------------------------------------------------------------------------
    -- Write Clock Domain
    --
    -- Maintains the binary write pointer.
    --
    -- The pointer is incremented only when:
    --   • Write domain is enabled.
    --   • A write request is present.
    --   • FIFO is not Full.
    --------------------------------------------------------------------------
    wr_pointer_pr : process(clk_wr)
    begin

        if rising_edge(clk_wr) then

            if rst_wr = '1' then

                wr_ptr_reg <= (others => '0');

            elsif wr_domain_en = '1' then

                wr_ptr_reg <= wr_ptr_next;

            end if;

        end if;

    end process wr_pointer_pr;

    --------------------------------------------------------------------------
    -- Read Clock Domain
    --
    -- Maintains the binary read pointer.
    --
    -- The pointer is incremented only when:
    --   • Read domain is enabled.
    --   • A read request is present.
    --   • FIFO is not Empty.
    --------------------------------------------------------------------------
    rd_pointer_pr : process(clk_rd)
    begin

        if rising_edge(clk_rd) then

            if rst_rd = '1' then

                rd_ptr_reg <= (others => '0');

            elsif rd_domain_en = '1' then

                rd_ptr_reg <= rd_ptr_next;

            end if;

        end if;

    end process rd_pointer_pr;

    --------------------------------------------------------------------------
    -- Binary-to-Gray Conversion Registered Process Write
    --
    -- Binary pointers are converted to Gray code before crossing clock
    -- domains. Since only a single bit changes between adjacent Gray-code
    -- values, the probability of sampling an invalid intermediate value
    -- during synchronization is minimized.
    --------------------------------------------------------------------------

    register_gray_ptr_wr:process(clk_wr)
    begin
        if rising_edge(clk_wr) then
    
            if rst_wr='1' then
    
                wr_ptr_gray_reg <= (others=>'0');
    
            elsif wr_domain_en='1' then
    
                wr_ptr_gray_reg <=unsigned(binary_to_gray(std_logic_vector(wr_ptr_reg)));
    
            end if;
    
        end if;
    end process register_gray_ptr_wr;

    --------------------------------------------------------------------------
    -- Binary-to-Gray Conversion Registered Process Read
    --
    -- Binary pointers are converted to Gray code before crossing clock
    -- domains. Since only a single bit changes between adjacent Gray-code
    -- values, the probability of sampling an invalid intermediate value
    -- during synchronization is minimized.
    --------------------------------------------------------------------------

    register_gray_ptr_rd:process(clk_rd)
        begin
            if rising_edge(clk_rd) then
        
                if rst_rd='1' then
        
                    rd_ptr_gray_reg <= (others=>'0');
        
                elsif wr_domain_en='1' then
        
                    rd_ptr_gray_reg <= unsigned(binary_to_gray(std_logic_vector(rd_ptr_reg)));
        
                end if;
        
            end if;
        end process register_gray_ptr_rd;


    --------------------------------------------------------------------------
    -- Write Allow Logic
    --
    -- Prevents writes whenever the FIFO is Full.
    --------------------------------------------------------------------------
    wr_allow <= wr_en and (not f_full) and wr_domain_en;

    --------------------------------------------------------------------------
    -- Read Allow Logic
    --
    -- Prevents reads whenever the FIFO is Empty.
    --------------------------------------------------------------------------
    rd_allow <= rd_en and (not f_empty) and rd_domain_en;

    --------------------------------------------------------------------------
    -- Write Pointer Next-State Logic
    --------------------------------------------------------------------------
    wr_ptr_next <= wr_ptr_reg + 1
                   when wr_allow = '1'
                   else wr_ptr_reg;

    --------------------------------------------------------------------------
    -- Read Pointer Next-State Logic
    --------------------------------------------------------------------------
    rd_ptr_next <= rd_ptr_reg + 1
                   when rd_allow = '1'
                   else rd_ptr_reg;

    --------------------------------------------------------------------------
    -- Memory Address Outputs
    --
    -- The external memory uses only the address bits.
    -- The additional MSB is used internally for Full/Empty detection.
    --------------------------------------------------------------------------
    wr_ptr <= std_logic_vector(
                  wr_ptr_reg(wr_ptr_reg'left-1 downto 0)
              );

    rd_ptr <= std_logic_vector(
                  rd_ptr_reg(rd_ptr_reg'left-1 downto 0)
              );
    
    
    --------------------------------------------------------------------------
    -- Clock Domain Crossing (CDC)
    --
    -- The Gray-coded pointers are synchronized into the opposite clock domain
    -- using a configurable multi-stage flip-flop synchronizer.
    --
    -- Gray coding ensures that only one bit changes between successive pointer
    -- values, significantly reducing the probability of sampling invalid
    -- intermediate values during synchronization.
    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    -- Synchronize Read Pointer into Write Clock Domain
    --------------------------------------------------------------------------
    rd_ptr_sync_inst : entity work.n_stage_ff_synch
        generic map
        (
            STAGES    => CDC_STAGES,
            MSB_INDEX => PTR_WIDTH
        )
        port map
        (
            clk     => clk_wr,
            sig_in  => std_logic_vector(rd_ptr_gray_reg),
            sig_out => rd_ptr_gray_wr_sync
        );

    --------------------------------------------------------------------------
    -- Synchronize Write Pointer into Read Clock Domain
    --------------------------------------------------------------------------
    wr_ptr_sync_inst : entity work.n_stage_ff_synch
        generic map
        (
            STAGES    => CDC_STAGES,
            MSB_INDEX => PTR_WIDTH
        )
        port map
        (
            clk     => clk_rd,
            sig_in  => std_logic_vector(wr_ptr_gray_reg),
            sig_out => wr_ptr_gray_rd_sync
        );

    --------------------------------------------------------------------------
    -- Gray-to-Binary Conversion
    --
    -- After synchronization, Gray-coded pointers are converted back into
    -- binary representation for pointer comparison and FIFO occupancy
    -- calculation.
    --------------------------------------------------------------------------
    rd_ptr_bin_wr_sync <= unsigned(gray_to_binary(rd_ptr_gray_wr_sync));

    wr_ptr_bin_rd_sync <= unsigned(gray_to_binary(wr_ptr_gray_rd_sync));

    --------------------------------------------------------------------------
    -- FIFO Occupancy Calculation
    --
    -- Occupancy is calculated independently within each clock domain using
    -- the local binary pointer and the synchronized binary pointer from the
    -- opposite clock domain.
    --
    -- Due to synchronization latency, these values may lag the true FIFO
    -- occupancy by several clock cycles, which is acceptable for generation
    -- of Almost Full and Almost Empty status flags.
    --------------------------------------------------------------------------
    fifo_count_at_wr <= wr_ptr_reg - rd_ptr_bin_wr_sync;

    fifo_count_at_rd <= wr_ptr_bin_rd_sync - rd_ptr_reg;

    --------------------------------------------------------------------------
    -- Full Flag Generation
    --
    -- The FIFO is Full when:
    --   • The lower address bits of both pointers are identical.
    --   • The additional wrap-around bit differs.
    --
    -- This comparison is performed entirely within the write clock domain.
    --------------------------------------------------------------------------
    f_full <= '1'
              when
              (
                  wr_ptr_reg(wr_ptr_reg'left) /=
                  rd_ptr_bin_wr_sync(rd_ptr_bin_wr_sync'left)
              )
              and
              (
                  wr_ptr_reg(wr_ptr_reg'left-1 downto 0) =
                  rd_ptr_bin_wr_sync(rd_ptr_bin_wr_sync'left-1 downto 0)
              )
              else '0';

    --------------------------------------------------------------------------
    -- Empty Flag Generation
    --
    -- The FIFO is Empty when the synchronized write pointer equals the
    -- current read pointer.
    --
    -- This comparison is performed entirely within the read clock domain.
    --------------------------------------------------------------------------
    f_empty <= '1'
               when wr_ptr_bin_rd_sync = rd_ptr_reg
               else '0';

    --------------------------------------------------------------------------
    -- Almost Full Flag
    --
    -- Asserted whenever FIFO occupancy reaches or exceeds the configured
    -- threshold.
    --------------------------------------------------------------------------
    almost_full <= '1'
                   when fifo_count_at_wr >= ALMOST_FULL_THRESHOLD
                   else '0';

    --------------------------------------------------------------------------
    -- Almost Empty Flag
    --
    -- Asserted whenever FIFO occupancy falls below or equals the configured
    -- threshold.
    --------------------------------------------------------------------------
    almost_empty <= '1'
                    when fifo_count_at_rd <= ALMOST_EMPTY_THRESHOLD
                    else '0';

    --------------------------------------------------------------------------
    -- Memory Interface
    --
    -- Memory write and read enables are generated only when the requested
    -- operation is permitted.
    --------------------------------------------------------------------------
    mem_wr <= wr_allow;

    mem_rd <= rd_allow;

    --------------------------------------------------------------------------
    -- Status Flag Outputs
    --------------------------------------------------------------------------
    full  <= f_full;

    empty <= f_empty;

end Behavioral;
