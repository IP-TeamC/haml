package de.fhdw.haml.codegen.knnc;

import de.fhdw.haml.codegen.util.Binary;
import de.fhdw.knn.data.CsvReader;
import de.fhdw.knn.data.DataSet;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;

public class BananaQuality {

    private static final int FP_SIZE = 32;
    private static final int FP_FRAC = 20;
    private static final String FILE_TEMPLATE = """
            library ieee;
            use ieee.std_logic_1164.all;
            use ieee.numeric_std.all;
            
            package bq_dataset is
            
                constant ADR_SIZE : natural := 13;
                constant DATA_SIZE : natural := %d;
                constant START_ADR : std_logic_vector(ADR_SIZE-1 downto 0) := (others => '0');
                constant END_ADR : std_logic_vector(ADR_SIZE-1 downto 0) := "%s";
            
                procedure write_dataset_to_ram (
                    signal we : out std_logic;
                    signal write_adr : out std_logic_vector(ADR_SIZE-1 downto 0);
                    signal write_data : out std_logic_vector(DATA_SIZE-1 downto 0);
                    clk_period : time
                );
            
            end package;
            
            package body bq_dataset is
            
                procedure write_dataset_to_ram (
                    signal we : out std_logic;
                    signal write_adr : out std_logic_vector(ADR_SIZE-1 downto 0);
                    signal write_data : out std_logic_vector(DATA_SIZE-1 downto 0);
                    clk_period : time
                ) is
                begin
                    we <= '1';
            %s
                    we <= '0';
                end procedure;
            
            end package body;
            """;
    private static final String WRITE_TEMPLATE = """
                        write_adr <= "%s";
                        write_data <= "%s" & "%s" & "%s" & "%s" & "%s" & "%s" & "%s" & "%s";
                        wait for clk_period;
                """;


    public static void main(String[] args) throws IOException {
        StringBuilder entries = new StringBuilder();
        DataSet dataSet = CsvReader.readFile("banana_quality.csv", 0, 7, 7, 1);
        for (int i = 0; i < dataSet.size; i++) {
            entries.append(WRITE_TEMPLATE.formatted(
                    "%13s".formatted(Integer.toBinaryString(i)).replace(' ', '0'),
                    Binary.toFixedPoint(dataSet.inputs[i][0], FP_SIZE, FP_FRAC),
                    Binary.toFixedPoint(dataSet.inputs[i][1], FP_SIZE, FP_FRAC),
                    Binary.toFixedPoint(dataSet.inputs[i][2], FP_SIZE, FP_FRAC),
                    Binary.toFixedPoint(dataSet.inputs[i][3], FP_SIZE, FP_FRAC),
                    Binary.toFixedPoint(dataSet.inputs[i][4], FP_SIZE, FP_FRAC),
                    Binary.toFixedPoint(dataSet.inputs[i][5], FP_SIZE, FP_FRAC),
                    Binary.toFixedPoint(dataSet.inputs[i][6], FP_SIZE, FP_FRAC),
                    dataSet.outputs[i][0] > 0 ? "1" : "0"
            ));
        }
        String file = FILE_TEMPLATE.formatted(
                dataSet.inputSize*FP_SIZE+1,
                "%13s".formatted(Integer.toBinaryString(dataSet.size - 1)).replace(' ', '0'),
                entries
        );
        Files.writeString(Path.of("../test/bq_dataset.vhd"), file, StandardOpenOption.TRUNCATE_EXISTING, StandardOpenOption.CREATE);
    }

}
