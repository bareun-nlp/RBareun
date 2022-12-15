.onAttach <- function(libname, pkgName) {
    if (interactive()) {
        packageStartupMessage("bareun ", packageVersion("bareun"),
                              " using BareunNLP 1.7")
    }
}