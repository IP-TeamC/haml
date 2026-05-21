package de.fhdw.haml.codegen.linreg;

import de.fhdw.haml.codegen.DataSetGen;
import de.fhdw.knn.data.CsvReader;
import de.fhdw.knn.data.DataSet;
import de.fhdw.knn.data.MinMaxNormalizer;
import de.fhdw.knn.data.Normalizer;
import lombok.SneakyThrows;

import static de.fhdw.haml.codegen.util.Binary.fixedPointToDouble;

public class GenericLinReg {

    public String fileName;
    public int inputSize = 1;

    public int fpSize = 18;
    public int fpFrac = 17;

    public DataSet dataSet;
    public Normalizer normalizerInputs;
    public Normalizer normalizerOutputs;

    public static void main(String[] args) {
        GenericLinReg f3x12 = new GenericLinReg("f3x12.csv");
        GenericLinReg salary = new GenericLinReg("salary.csv", 2);
        GenericLinReg lineareRegression1 = new GenericLinReg("lineare_regression1.csv");
        GenericLinReg lineareRegression2 = new GenericLinReg("lineare_regression2.csv");
        lineareRegression1.printFromNormalized("011111111100011001", "100000000110000111");
    }

    public GenericLinReg(String fileName) {
        this(fileName, 1);
    }

    public GenericLinReg(String fileName, int inputSize) {
        this.fileName = fileName;
        this.inputSize = inputSize;
        generate();
    }

    @SneakyThrows
    public void loadAndNormalizeDataSet() {
        dataSet = CsvReader.readFile(fileName, 0, inputSize, inputSize, 1, 1);
        normalizerInputs = new MinMaxNormalizer(-1, 1 - Math.pow(2, -fpFrac));
        normalizerOutputs = new MinMaxNormalizer(-1, 1 - Math.pow(2, -fpFrac));
        dataSet.normalizeInputs(normalizerInputs);
        dataSet.normalizeOutputs(normalizerOutputs);
    }

    public void generate() {
        loadAndNormalizeDataSet();
        DataSetGen gen = new DataSetGen();
        gen.fpSize = fpSize;
        gen.fpFrac = fpFrac;
        gen.dataSet = dataSet;
        gen.name = fileName.split("\\.")[0];
        gen.gen("linreg", false);
    }

    public void printFromNormalized(String constant, String... coefs) {
        double[] factors = new double[coefs.length + 1];
        factors[0] = fixedPointToDouble(constant, fpFrac);
        for (int i = 0; i < coefs.length; i++) {
            factors[i + 1] = fixedPointToDouble(coefs[i], fpFrac);
        }
        normalizerOutputs.denormalize(dataSet.outputs);
        for (int i = 0; i < dataSet.size; i++) {
            double[][] arr = new double[][]{new double[]{ factors[0] }};
            for (int j = 0; j < coefs.length; j++) {
                arr[0][0] += factors[j + 1] * dataSet.inputs[i][j];
            }
            normalizerOutputs.denormalize(arr);
            System.out.println(Math.round(dataSet.outputs[i][0]) + ", but: " + Math.round(arr[0][0]));
        }
        dataSet = null;
    }

}
