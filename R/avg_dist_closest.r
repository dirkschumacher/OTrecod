
#' avg_dist_closest()
#'
#' This function computes average distances between levels of 2 categorical outcomes located in two distinct databases
#'
#'
#' The function \code{avg_dist_closest} is an intermediate function used in the implementation of an original algorithm dedicated to the solving of recoding problems in data fusion using Optimal Transportation theory (see the algorithms of the models called
#' \code{OUTCOME},\code{R_OUTCOME},\code{JOINT} and \code{R_JOINT}, in the two following references of Gares and Al.). \code{avg_dist_closest} is so directly implemented in the \code{OT_outcome} and \code{OT_JOINT} functions but can also be used separately.
#' The function \code{avg_dist_closest} uses, in particular, the D distance matrix (that stores distances between rows of A and B) from \code{\link{proxim_dist}} to produce 3 distinct matrices saved in a list object.
#' Therefore, the function required in input, this specific output of the function \code{\link{proxim_dist}} which is available in the package and so usable beforehand.
#' In consequence, do not use this function directly on your database, and do not hesitate to consult the examples provided for a better understanding.
#'
#'
#' DEFINITION OF THE COST MATRIX
#'
#' Assuming that A and B are 2 databases with a set of shared variables and a same latent target factor (called Y in A and Z in B, such that Y is unknown in B and Z is unknown in A) whose encoding depends on the database (nY levels in A and nZ levels in B).
#' A distance between one level of Y and one level of Z is estimated by averaging the distances between individuals from the 2 databases that are classed in the two levels of Y and Z, in A and B respectively.
#' The distance between 2 individuals depends on variations between the shared covariates, and also depends on the distance function chosen by user.
#' For the computation, all the individuals concerned by these 2 classes can be taken into a count, or only parts of them, depending on the argument \code{percent_closest}.
#' When \code{percent_closest} < 1, only the corresponding percent of individuals, considered as closest neighbors of the considered levels, are used in the compution of average distances.
#'
#' The average distance between each individual of Y (Z) and each levels of Z (Y) are returned in output, in the object \code{DindivA} (\code{DindivB} respectively).
#' The average distance between each levels of Y and each levels of Z are returned in a matrix saved in output (the object \code{Davg}).
#' \code{Davg} returns the computation of the cost matrix D, whose dimensions (nA*nB) correspond to the number of levels of Y (rows) and Z (columns).
#' This matrix can be seen as the ability for an individual (row) to move from a given level of the target variable (Y) in A to given level of Z in the database B.
#'
#'
#' @param proxim An object corresponding to the output of the \code{proxim_dist} function
#' @param percent_closest A value between 0 and 1 (by default, all individuals) corresponding to the desired percent of rows (or individuals) that will be taken into acccount for the computation of the average distances between levels or
#' between individuals and levels of factors.
#'
#' @return A list of 3 matrix is returned:
#' \item{Davg}{The cost matrix whose number of rows corresponds to nY, the number of levels of the target variable Y in the database A, and whose number of columns corresponds to nB: the number of levels of the target variable in B.
#' In this case, the related cost matrix can be interpreted as the ability to move from one level of Y in A to one level of Z in B.
#' Davg[P,Q] so refers to the average distance between the modality P in Y (only known in A) and modality Q of Z (only known in B).}
#' \item{DindivA}{A matrix whose number of rows corresponds to the number of rows of the 1st database A and number of columns corresponds to nB, the number of levels of the target variable in the 2nd database B.
#' DindivA[i,Q] refers to the average distance between the i_th individual (or row) of the 1st database and a chosen proportion of individuals (\code{percent_closest} set by the user) of the 2nd database having the modality Q of Z.}
#' \item{DindivB}{A matrix whose number of rows corresponds to the number of rows of the 2nd database B and number of columns corresponds to nA, the number of levels of the target variable in the 1st database A.
#' DindivB[k,P] refers to the average distance between the k_th individual (or row) of the 2nd database and a chosen proportion of individuals (depending on \code{percent_closest}) of the 1st database having the modality P of Y.}
#'
#' @author Gregory Guernec, Valerie Gares, Jeremy Omer
#'
#' \email{gregory.guernec@@inserm.fr}
#'
#' @references
#' ### About OT algorithms for data integration:
#' Gares V, Dimeglio C, Guernec G, Fantin F, Lepage B, Korosok MR, savy N (2019). On the use of optimal transportation theory to recode variables and application to database merging. The International Journal of Biostatistics.
#' Volume 16, Issue 1, 20180106, eISSN 1557-4679 | \url{https://doi.org/10.1515/ijb-2018-0106}
#'
#' Gares V, Omer J. Regularized optimal transport of covariates and outcomes in datarecoding(2019).hal-02123109 \url{https://hal.archives-ouvertes.fr/hal-02123109/document}
#'
#'
#' @seealso \code{\link{proxim_dist}}
#'
#' @aliases avg_dist_closest
#'
#' @export
#'
#' @examples
#' data(simu_data)
#' ### The covariates of the data are prepared according to the distance chosen
#' ### using the transfo_dist function
#'
#' ### Example with The Manhattan distance
#'
#' try1 = transfo_dist(simu_data,quanti = c(3,8), nominal = c(1,4:5,7),
#'                     ordinal = c(2,6), logic = NULL, prep_choice = "M")
#' res1 = proxim_dist(try1,norm = "M")
#'
#' # proxim_dist() fixes the distance measurement chosen,
#' # and defines neighborhoods between profiles and individuals
#'
#' # If you want that only 80 percents of the indiduals (the closest to each levels)
#' # participate to the computation of the average distances:
#' res_new  = avg_dist_closest(res1,percent_closest = 0.80)
#'
#'
avg_dist_closest = function(proxim, percent_closest = 1){

  if (!is.list(proxim)){

    stop("This object must be a list returned by the proxim_dist function")

  } else {}

  if ((percent_closest>1)|(percent_closest <= 0)){

    stop("Incorrect value for the percent_closest option")

  } else {}


  # Redefine A and B for the model
  A = (1:proxim$nA)
  B = (1:proxim$nB)
  Y = proxim$Y
  Z = proxim$Z
  indY = proxim$indY
  indZ = proxim$indZ

  # Compute average distances
  Davg     = matrix(0,length(Y),length(Z));
  DindivA  = matrix(0,proxim$nA,length(Z));
  DindivB  = matrix(0,proxim$nB,length(Y));

  for (y in Y){
    for (i in indY[[y]]){
      for (z in Z){
        nbclose = max(round(percent_closest*length(indZ[[z]])),1);

        distance     = sort(proxim$D[i,indZ[[z]]])
        DindivA[i,z] = sum(distance[1:nbclose])/nbclose;
        Davg[y,z]    = Davg[y,z] + sum(distance[1:nbclose])/nbclose/length(indY[[y]])/2.0;
      }
    }
  }
  for (z in Z){
    for (j in indZ[[z]]){
      for (y in Y){
        nbclose      = max(round(percent_closest*length(indY[[y]])),1);

        distance     = sort(proxim$D[indY[[y]],j])
        DindivB[j,y] = sum(distance[1:nbclose])/nbclose;
        Davg[y,z]    = Davg[y,z] + sum(distance[1:nbclose])/nbclose/length(indZ[[z]])/2.0;
      }
    }
  }

  return(list(Davg=Davg, DindivA=DindivA, DindivB=DindivB))
}



