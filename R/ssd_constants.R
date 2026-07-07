# SSD generator package constants
# Exported so users can inspect the discretisation grid and supply the same
# boundaries to their own analyses. All SSD generators accept arguments that
# default to these constants, so users can override them without changing defaults.

#' Default DBH class break points for deepReveal SSD generators
#'
#' @description Lower and upper boundaries for the 10 DBH classes used by the
#'   [generate_ssd_weibull()], [generate_ssd_reverse_j()], and
#'   [generate_ssd_bimodal()] generators. The grid spans 8 cm to \eqn{\infty}
#'   in steps of 1.5–10 cm, widening toward larger classes to reflect typical
#'   forest inventory protocols with DBH \eqn{\geq} 8 cm.
#'
#'   The final element is `Inf` so that the last class captures all stems above
#'   the last measurable break, regardless of actual maximum DBH.
#'
#' @format Numeric vector of length 11 (10 class lower bounds + final `Inf`),
#'   in cm.
#' @seealso [SG_DBH_MIDPOINTS] for the class representative diameters;
#'   [SG_DBH_THETA] for the minimum measured DBH threshold.
#' @examples
#' SG_DBH_BREAKS
#' @export
SG_DBH_BREAKS <- c(8, 11.5, 15, 20, 25, 30, 35, 40, 45, 50, Inf)


#' Default DBH class midpoints for deepReveal SSD generators
#'
#' @description Class representative diameters (cm) corresponding to
#'   [SG_DBH_BREAKS]. Each midpoint is the arithmetic centre of its class,
#'   except the open final class (> 50 cm) which uses 55 cm as a conventional
#'   representative value consistent with European inventory practice.
#'
#'   Used as weights when computing basal area from a discretised SSD
#'   (see [stand_basal_area()]) and as the midpoints argument in
#'   [cao_baldwin_solver_()].
#'
#' @format Numeric vector of length 10, in cm.
#' @seealso [SG_DBH_BREAKS], [stand_basal_area()], [stand_qmd()].
#' @examples
#' SG_DBH_MIDPOINTS
#' @export
SG_DBH_MIDPOINTS <- c(9.75, 13.25, 17.5, 22.5, 27.5, 32.5, 37.5, 42.5, 47.5, 55.0)


#' Default minimum measured DBH for deepReveal Weibull generators
#'
#' @description Location parameter (theta, cm) for the shifted Weibull
#'   distribution used by [weibull_class_probs_()]: the distribution is
#'   shifted so that the left tail starts at the minimum measurable DBH rather
#'   than at 0, consistent with standard forest inventory thresholds
#'   (Siipilehto 1999).
#'
#'   Also used by [generate_ssd_bimodal()] as the fallback threshold: when the
#'   understory mode falls within `theta_cm + sigma` of the measurement limit,
#'   the function switches to a unimodal Weibull.
#'
#' @format Integer scalar, in cm.
#' @seealso [SG_DBH_BREAKS], [generate_ssd_bimodal()].
#' @examples
#' SG_DBH_THETA
#' @export
SG_DBH_THETA <- 8L
