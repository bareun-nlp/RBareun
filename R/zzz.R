.onAttach <- function(libname, pkgName) {
    if (interactive()) {
        packageStartupMessage("bareun ", packageVersion("bareun"),
                              " using Bareun/1.7")
    }
}