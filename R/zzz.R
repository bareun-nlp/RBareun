.onAttach <- function(libname, pkgName) {
    if (interactive()) {
        packageStartupMessage("RBareun ", packageVersion("bareun"),
                              " using Bareun/1.8")
    }
}
