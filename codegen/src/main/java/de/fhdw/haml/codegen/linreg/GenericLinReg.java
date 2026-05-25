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

        double[] fF3x12 = f3x12.convertDenormalizeAndPrintFunction("000000000000000000", "011111111111111111");
        double[] fSalary = salary.convertDenormalizeAndPrintFunction("111111101100011011", "011101111111111101", "111100010001100011");
        double[] fLineareRegression1 = lineareRegression1.convertDenormalizeAndPrintFunction("111111111111111110", "100000000000000001");
        double[] fLineareRegression2 = lineareRegression2.convertDenormalizeAndPrintFunction("000000000000010100", "011111111111100100");

        //f3x12.printFromNormalized(fF3x12);
        //salary.printFromNormalized(fSalary);
        //lineareRegression1.printFromNormalized(fLineareRegression1);
        //lineareRegression2.printFromNormalized(fLineareRegression2);
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

    private double[] convertDenormalizeAndPrintFunction(String constant, String... coefs) {
        System.out.println(fileName);

        double[] factors = new double[coefs.length + 1];
        factors[0] = fixedPointToDouble(constant, fpFrac);
        for (int i = 0; i < coefs.length; i++) {
            factors[i + 1] = fixedPointToDouble(coefs[i], fpFrac);
        }

        denormalizeFunction(factors);

        System.out.println("constant 0: " + factors[0]);
        for (int i = 1; i < factors.length; i++) {
            System.out.println("coefficient " + i + ": " + factors[i]);
        }

        System.out.println("------");
        return factors;
    }

    private void denormalizeFunction(double[] normalized) {
        double[][] inputs = new double[][]{ new double[normalized.length-1], new double[normalized.length-1] };
        double[][] output = new double[][]{ new double[]{ -1 }, new double[]{ 1 - Math.pow(2, -fpFrac) } };
        for (int i = 0; i < inputs[0].length; i++) {
            inputs[0][i] = -1;
            inputs[1][i] = 1 - Math.pow(2, -fpFrac);
        }
        normalizerInputs.denormalize(inputs);
        normalizerOutputs.denormalize(output);
        double[] inputsMin = inputs[0];
        double[] inputsMax = inputs[1];
        double outputMin = output[0][0];
        double outputMax = output[1][0];

        for (int i = 1; i < normalized.length; i++) {
            normalized[i] *= (outputMax - outputMin) / (inputsMax[i-1] - inputsMin[i-1]);
        }
        normalized[0] = (outputMax + outputMin) / 2
                + normalized[0] * (outputMax - outputMin) / 2;
        for (int i = 1; i < normalized.length; i++) {
            normalized[0] -= normalized[i] * (inputsMax[i-1] + inputsMin[i-1]) / 2;
        }
    }

    public void printFromNormalized(double[] factors) {
        normalizerInputs.denormalize(dataSet.inputs);
        normalizerOutputs.denormalize(dataSet.outputs);
        for (int i = 0; i < dataSet.size; i++) {
            double predicted = factors[0];
            for (int j = 0; j < factors.length-1; j++) {
                predicted += factors[j + 1] * dataSet.inputs[i][j];
            }
            System.out.println(Math.round(dataSet.outputs[i][0]) + ", but: " + Math.round(predicted));
        }
        dataSet = null;
    }

}
