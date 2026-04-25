package de.fhdw.haml.codegen;

import de.fhdw.haml.codegen.util.Binary;
import de.fhdw.knn.data.DataSet;
import lombok.SneakyThrows;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;

public class DataSetGen {

    private static final String FILE_TEMPLATE = """
            library ieee;
            use ieee.std_logic_1164.all;
            use ieee.numeric_std.all;
            
            package %s_dataset_tb is
            
                constant FP_SIZE : natural := %d;
                constant FP_FRAC : natural := %d;
                constant ADR_SIZE : natural := %d;
                constant PART_SIZE : natural := %d;
                constant DATA_SIZE : natural := %d;
            
            
                constant START_ADR : std_logic_vector(ADR_SIZE-1 downto 0) := (others => '0');
                constant END_ADR : std_logic_vector(ADR_SIZE-1 downto 0) := "%s";
            
                procedure write_dataset_to_ram (
                    signal we : out std_logic;
                    signal write_adr : out std_logic_vector(ADR_SIZE-1 downto 0);
                    signal write_part : out std_logic_vector(PART_SIZE-1 downto 0);
                    signal write_data : out std_logic_vector(DATA_SIZE-1 downto 0);
                    clk_period : time
                );
            
                procedure write_datapoint_to_ram (
                    signal we : out std_logic;
                    signal write_adr : out std_logic_vector;
                    signal write_part : out std_logic_vector(PART_SIZE-1 downto 0);
                    signal write_data : out std_logic_vector(DATA_SIZE-1 downto 0);
                    external_end_adr : std_logic_vector;
                    clk_period : time;
                    i : natural
                );
            
                type t_dataset is array (0 to %d, 0 to %d) of std_logic_vector(DATA_SIZE-1 downto 0);
                signal dataset : t_dataset := (
            %s
                );
            
            end package;
            
            package body %s_dataset_tb is
            
                procedure write_dataset_to_ram (
                    signal we : out std_logic;
                    signal write_adr : out std_logic_vector(ADR_SIZE-1 downto 0);
                    signal write_part : out std_logic_vector(PART_SIZE-1 downto 0);
                    signal write_data : out std_logic_vector(DATA_SIZE-1 downto 0);
                    clk_period : time
                ) is
                begin
                    we <= '1';
                    for adr in 0 to to_integer(unsigned(END_ADR)) loop
                        write_adr <= std_logic_vector(to_unsigned(adr, ADR_SIZE));
                        for part in t_dataset'range(2) loop
                            write_part <= std_logic_vector(to_unsigned(part, PART_SIZE));
                            write_data <= dataset(adr, part);
                            wait for clk_period;
                        end loop;
                    end loop;
                    we <= '0';
                end procedure;
            
                procedure write_datapoint_to_ram (
                    signal we : out std_logic;
                    signal write_adr : out std_logic_vector;
                    signal write_part : out std_logic_vector(PART_SIZE-1 downto 0);
                    signal write_data : out std_logic_vector(DATA_SIZE-1 downto 0);
                    external_end_adr : std_logic_vector;
                    clk_period : time;
                    i : natural
                ) is
                begin
                    we <= '1';
                    write_adr <= std_logic_vector(unsigned(external_end_adr)+1);
                    for part in t_dataset'range(2) loop
                        if part /= 0 then
                            write_part <= std_logic_vector(to_unsigned(part, PART_SIZE));
                            write_data <= dataset(i, part);
                            wait for clk_period;
                        end if;
                    end loop;
                    we <= '0';
                end procedure;
            
            end package body;
            """;
    private static final String DATAPOINT_PRE = """
                    %d => (\
            """;
    private static final String DATAVALUE_TEMPLATE = "%d => \"%s\"";

    public String name;
    public DataSet dataSet;
    public int fpSize = 18;
    public int fpFrac = 12;

    @SneakyThrows
    public void gen() {
        int adrSize = (int) Math.ceil(Math.log(dataSet.size)/Math.log(2));
        int partSize = (int) Math.ceil(Math.log(dataSet.inputSize)/Math.log(2));

        StringBuilder entries = new StringBuilder();
        for (int i = 0; i < dataSet.size; i++) {
            entries.append(DATAPOINT_PRE.formatted(i));
            entries.append(DATAVALUE_TEMPLATE.formatted(0, Binary.toBinaryPad((int) dataSet.outputs[i][0], fpSize)));
            entries.append(", ");
            for (int input = 0; input < dataSet.inputSize; input++) {
                entries.append(DATAVALUE_TEMPLATE.formatted(
                        input+1,
                        Binary.toFixedPoint(dataSet.inputs[i][input], fpSize, fpFrac)
                ));
                if (input != dataSet.inputSize-1) {
                    entries.append(", ");
                }
            }
            entries.append(')');
            if (i != dataSet.size-1) {
                entries.append(",\n");
            }
        }
        String file = FILE_TEMPLATE.formatted(
                name,
                fpSize,
                fpFrac,
                adrSize,
                partSize,
                fpSize,
                Binary.toBinaryPad(dataSet.size - 1, adrSize),
                dataSet.size-1,
                dataSet.inputSize,
                entries,
                name
        );
        Files.writeString(Path.of("../test/knnc/" + name + "_dataset_tb.vhd"), file, StandardOpenOption.TRUNCATE_EXISTING, StandardOpenOption.CREATE);
    }

}
