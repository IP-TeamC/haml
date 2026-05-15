package de.fhdw.haml.codegen.knnc;

import de.fhdw.haml.codegen.DataSetGen;
import de.fhdw.knn.data.CsvReader;
import de.fhdw.knn.data.DataSet;
import de.fhdw.knn.data.TrainTestSplit;

import java.io.IOException;

public class BananaQuality {

    public static void main(String[] args) throws IOException {
        DataSet dataSet = CsvReader.readFile("banana_quality.csv", 0, 7, 7, 1);
        TrainTestSplit split = dataSet.shuffleAndSplit(42, 0.745);

        DataSetGen train = new DataSetGen();
        train.dataSet = split.train;
        train.name = "bq_train";
        train.gen("knnc", true);

        DataSetGen test = new DataSetGen();
        test.dataSet = split.test;
        test.name = "bq_test";
        test.gen("knnc", true);
    }

}
