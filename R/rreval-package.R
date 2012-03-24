#' Remote R Evaluation (rreval)
#'
#' \tabular{ll}{
#' Package: \tab rreval\cr
#' Type: \tab Package\cr
#' Version: \tab 1.0--\cr
#' Date: \tab 2012-01-24\cr
#' License: \tab GPL (>= 3)\cr
#' }
#'
#' rreval is a means for using R on a remote system from within a 
#' local R session.  Any R expression can be evaluated on the 
#' remote server. All non-graphical results are returned to the
#' local R session: this includes the results of remote evaluations
#' and all textual output, including errors and warnings.  rreval uses 
#' socket level communication via ssh port forwarding. It 
#' supports uploading and downloading R objects and scp file tranfers.
#'
#' @name rreval
#' @docType package
#' @title Remote R Evaluation (rreval)
#' @author Barnet Wagman \email{bw@@norbl.com}
#' @depends digest
#' @keywords package
NULL
           
