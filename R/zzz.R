#' @importFrom utils packageVersion
.onAttach <- function(libname, pkgName) {
    if (interactive()) {
        packageStartupMessage("RBareun ", packageVersion("bareun"),
                              " using Bareun/3.0")
    }
}
