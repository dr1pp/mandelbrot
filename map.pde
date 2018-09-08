double doubleMap(double value, double istart, double istop, double ostart, double ostop) {
    return ostart + (ostop - ostart) * ((value - istart) / (istop - istart));
}
