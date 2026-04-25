package de.fhdw.haml.codegen.knnc;

import de.fhdw.haml.codegen.util.Binary;
import de.fhdw.knn.data.CsvReader;
import de.fhdw.knn.data.DataSet;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;

public class BananaQuality {

    private static final int FP_SIZE = 18;
    private static final int FP_FRAC = 12;
    private static final String FILE_TEMPLATE = """
            library ieee;
            use ieee.std_logic_1164.all;
            use ieee.numeric_std.all;
            
            package bq_dataset_tb is
            
                constant FP_SIZE : natural := %d;
                constant FP_FRAC : natural := %d;
                constant ADR_SIZE : natural := 13;
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
                    signal write_adr : out std_logic_vector(ADR_SIZE-1 downto 0);
                    signal write_part : out std_logic_vector(PART_SIZE-1 downto 0);
                    signal write_data : out std_logic_vector(DATA_SIZE-1 downto 0);
                    clk_period : time;
                    i : natural
                );
            
                type t_dataset is array (0 to %d, 0 to %d) of std_logic_vector(DATA_SIZE-1 downto 0);
                signal dataset : t_dataset := (
            %s
                );
            
            end package;
            
            package body bq_dataset_tb is
            
                procedure write_dataset_to_ram (
                    signal we : out std_logic;
                    signal write_adr : out std_logic_vector(ADR_SIZE-1 downto 0);
                    signal write_part : out std_logic_vector(PART_SIZE-1 downto 0);
                    signal write_data : out std_logic_vector(DATA_SIZE-1 downto 0);
                    clk_period : time
                ) is
                begin
                    we <= '1';
                    for adr in t_dataset'range loop
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
                    signal write_adr : out std_logic_vector(ADR_SIZE-1 downto 0);
                    signal write_part : out std_logic_vector(PART_SIZE-1 downto 0);
                    signal write_data : out std_logic_vector(DATA_SIZE-1 downto 0);
                    clk_period : time;
                    i : natural
                ) is
                begin
                    we <= '1';
                    write_adr <= std_logic_vector(unsigned(END_ADR)+1);
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


    public static void main(String[] args) throws IOException {
        StringBuilder entries = new StringBuilder();
        DataSet dataSet = CsvReader.readFile("banana_quality.csv", 0, 7, 7, 1);
        for (int i = 0; i < dataSet.size; i++) {
            entries.append(DATAPOINT_PRE.formatted(i));
            entries.append(DATAVALUE_TEMPLATE.formatted(0, Binary.toBinaryPad((int) dataSet.outputs[i][0], FP_SIZE)));
            entries.append(", ");
            for (int input = 0; input < dataSet.inputSize; input++) {
                entries.append(DATAVALUE_TEMPLATE.formatted(
                        input+1,
                        Binary.toFixedPoint(dataSet.inputs[i][input], FP_SIZE, FP_FRAC)
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
                FP_SIZE,
                FP_FRAC,
                (int) Math.ceil(Math.log(dataSet.inputSize)/Math.log(2)),
                FP_SIZE,
                Binary.toBinaryPad(dataSet.size - 1, 13),
                dataSet.size-1,
                dataSet.inputSize,
                entries
        );
        Files.writeString(Path.of("../test/knnc/bq_dataset_tb.vhd"), file, StandardOpenOption.TRUNCATE_EXISTING, StandardOpenOption.CREATE);
    }

}
