package de.fhdw.haml.codegen.linreg;

import de.fhdw.haml.codegen.DataSetGen;
import de.fhdw.knn.data.CsvReader;
import de.fhdw.knn.data.DataSet;
import de.fhdw.knn.data.MinMaxNormalizer;
import de.fhdw.knn.data.Normalizer;

import java.io.IOException;

public class F3x12 {

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
        DataSet dataSet = CsvReader.readFile("f3x12.csv", 0, 1, 1, 1, 1);
        Normalizer normalizerInputs = new MinMaxNormalizer(-1, 1 - Math.pow(2, -17));
        Normalizer normalizerOutputs = new MinMaxNormalizer(-1, 1 - Math.pow(2, -17));
        dataSet.normalizeInputs(normalizerInputs);
        dataSet.normalizeOutputs(normalizerOutputs);

        double const0 = fixedPointToDouble("000000001010011001", 17);
        double m1 = fixedPointToDouble("011111110111000001", 17);
        normalizerOutputs.denormalize(dataSet.outputs);
        for (int i = 0; i < dataSet.size; i++) {
            double[][] arr = new double[][]{new double[]{const0 + m1 * dataSet.inputs[i][0]}};
            normalizerOutputs.denormalize(arr);
            System.out.println(Math.round(dataSet.outputs[i][0]) + ", but: " + Math.round(arr[0][0]));
        }

        if (true)
            return;


        DataSetGen gen = new DataSetGen();
        gen.fpSize = 18;
        gen.fpFrac = 17;
        gen.dataSet = dataSet;
        gen.name = "f3x12";
        gen.gen("linreg", false);
    }

}