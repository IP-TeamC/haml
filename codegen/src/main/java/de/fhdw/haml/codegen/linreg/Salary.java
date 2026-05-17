package de.fhdw.haml.codegen.linreg;

import de.fhdw.haml.codegen.DataSetGen;
import de.fhdw.knn.data.*;

import java.io.IOException;

public class Salary {

    // chatty, mal schauen ob es funktioniert...
    public static double fixedPointToDouble(String bits, int fractionalBits) {
        int totalBits = bits.length();

        // Binärstring zu signed long (Zweierkomplement)
        long value = Long.parseLong(bits, 2);

        // Falls Vorzeichenbit gesetzt ist → negatives Zahlformat
        if (bits.charAt(0) == '1') {
            value -= (1L << totalBits);
        }

        // Durch 2^fractionalBits teilen
        return value / Math.pow(2, fractionalBits);
    }

    public static void main(String[] args) throws IOException {
        DataSet dataSet = CsvReader.readFile("salary.csv", 0, 2, 2, 1, 1);
        Normalizer normalizerInputs = new MinMaxNormalizer(-1, 1);
        Normalizer normalizerOutputs = new MinMaxNormalizer(-1, 1);
        dataSet.normalizeInputs(normalizerInputs);
        dataSet.normalizeOutputs(normalizerOutputs);

        double const0 = fixedPointToDouble("110101011100001000", 16);
        double yoe1 = fixedPointToDouble("001101111111010000", 16);
        double grade2 = fixedPointToDouble("101111011110001101", 16);
        normalizerOutputs.denormalize(dataSet.outputs);
        for (int i = 0; i < dataSet.size; i++) {
            double[][] arr = new double[][]{new double[]{const0 + yoe1 * dataSet.inputs[i][0] + grade2 * dataSet.inputs[i][1]}};
            normalizerOutputs.denormalize(arr);
            System.out.println(Math.round(dataSet.outputs[i][0]) + ", but: " + Math.round(arr[0][0]));
        }

        if (true)
            return;


        DataSetGen gen = new DataSetGen();
        gen.fpSize = 18;
        gen.fpFrac = 16;
        gen.dataSet = dataSet;
        gen.name = "salary";
        gen.gen("linreg", false);
    }

}