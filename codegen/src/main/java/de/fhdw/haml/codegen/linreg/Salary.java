package de.fhdw.haml.codegen.linreg;

import de.fhdw.haml.codegen.DataSetGen;
import de.fhdw.knn.data.*;
import de.fhdw.knn.trainer.loss.LossFunction;
import de.fhdw.knn.trainer.loss.MeanSquaredError;

import java.io.IOException;

public class Salary {

    public static void main(String[] args) throws IOException {
        DataSet dataSet = CsvReader.readFile("salary.csv", 0, 2, 2, 1, 1);
        Normalizer normalizerInputs = new MinMaxNormalizer(-1, 1);
        Normalizer normalizerOutputs = new MinMaxNormalizer(-1, 1);
        dataSet.normalizeInputs(normalizerInputs);
        dataSet.normalizeOutputs(normalizerOutputs);

        DataSetGen gen = new DataSetGen();
        gen.fpSize = 18;
        gen.fpFrac = 16;
        gen.dataSet = dataSet;
        gen.name = "salary";
        gen.gen("linreg", false);
    }

}
