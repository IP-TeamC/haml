package de.fhdw.haml.codegen.util;

public class Binary {

    public static String toFixedPoint(double value, int fpSize, int fpFrac) {
        if (value >= Math.pow(2, fpSize - fpFrac)) {
            throw new IllegalArgumentException("value too big");
        }

        value *= Math.pow(2, fpFrac);
        String fpBinary = Integer.toBinaryString((int) Math.round(value));
        while (fpBinary.length() < fpSize) {
            fpBinary = "0" + fpBinary;
        }

        return fpBinary.substring(fpBinary.length() - fpSize);
    }

}
