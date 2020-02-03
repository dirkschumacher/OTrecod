
#' indiv_grp_optimal()
#'
#' Assuming that Y and Z summarize a same information encoded in two distinct forms stored in two distinct databases A and B.
#' This function is an alternative to the \code{\link{indiv_grp_closest}} approach for the individual predictions of Y en B and Z in A.
#' It solves an optimization problem to get the individual transport that minimizes total distance while satisfying the joint probability computed by the model.
#' See section 5.3 (p24) of the reference article 2 for more details about this method.
#'
#' As for \code{\link{indiv_grp_closest}}, the \code{indiv_grp_optimal} function is directly implemented in the \code{OT} and requires the prior use of code{\link{proxim_dist}} and \code{\link{avg_dist_closest}} for running.
#'
#'
#' @param proxim An object corresponding to the output of the \code{\link{proxim_dist}} function
#' @param jointprobaA A matrix which number of columns equals the number of modalities of the target variable Y in database A, and which number of rows equals the number of modalities of Z in database B. It gives an estimation of the joint probability (Y,Z) in DB A.
#' The sum of cells of this matrix must be equal to 1
#' @param jointprobaB A matrix which number of columns equals the number of modalities of the target variable Y in database A, and which number of rows equals the number of modalities of Z in database B. It gives an estimation of the joint probability (Y,Z) in DB B.
#' The sum of cells of this matrix must be equal to 1
#' @param percent_closest A value between 0 and 1 (by default) corresponding to the desired \code{percent closest} indivisuals taken in the computation of the distances
#'
#' @return A list of two vectors of numeric values:
#' \describe{
#' \item{YAtrans}{A vector corresponding to the predicted values of Y in database B using the Optimal Transportation theory}
#' \item{YBtrans}{A vector corresponding to the predicted values of Z in database A using the Optimal Transportation theory}
#' }
#'
#' @author Gregory Guernec, Valerie Gares, Jeremy Omer
#' \email{gregory.guernec@@inserm.fr}
#'
#' @seealso \code{\link{proxim_dist}}, \code{\link{avg_dist_closest}}, \code{\link{indiv_grp_closest}}
#'
#' @import ompr ROI ROI.plugin.glpk
#' @importFrom ompr.roi with_ROI
#'
#' @references
#' # Article 1:
#' Gares V, Dimeglio C, Guernec G, Fantin F, Lepage B, Korosok MR, savy N (2019). On the use of optimal transportation theory to recode variables and application to database merging. The International Journal of Biostatistics.
#' 0, 20180106 (2019) | \url{https://doi.org/10.1515/ijb-2018-0106}
#'
#' # Article 2:
#' Gares V, Omer J. Regularized optimal transport of covariates and outcomes in datarecoding(2019).hal-02123109 \url{https://hal.archives-ouvertes.fr/hal-02123109/document}
#'
#' @aliases indiv_grp_optimal
#'
#' @example
#'
#' ### Example using The Euclidean distance on a complete database
#' # For this example we keep only 200 rows:
#'
#' data(tab_test)
#' tab_test2 = tab_test[c(1:100,5001:5100),]; dim(tab_test2)
#'
#' # Adding NAs in Y1 and Y2
#' tab_test2[tab_test2$ident == 2,2] = NA
#' tab_test2[tab_test2$ident == 1,3] = NA
#'
#' # Because all covariates are ordered in numeric form,
#' # the transfo_dist function is not required here
#'
#' res3      = proxim_dist(tab_test2,norme = 2)
#'
#' #' ### Y1 and Y2 are a same variable encoded in 2 different forms:
#' ### 4 levels for Y1 and 3 levels for Y2
#' ### ... Stored in two distinct databases, A and B, respectively
#' ### The marginal distribution of Y1 in B is unknown,
#' ### as the marginal distribution of Z2 in A ...
#'
#' # By supposing that the following matrix called transport symbolizes
#' # an estimation of the joint distribution L(Y,Z) ...
#' # Note that, in reality this distribution is UNKNOWN and is
#' # estimated in the OT function by resolving an optimisation problem.
#'
#' # By supposing:
#'
#' val_trans  = c(0.275,0.115,0,0,0,0.085,0.165,0,0,0,0.095,0.265)
#' transport2 = matrix(val_trans,ncol = 3,byrow = FALSE)
#'
#' res4      = indiv_grp_optimal(res3,jointprobaA = transport2,
#'             jointprobaB = transport2, percent_closest= 0.90)
#'
#' \dontrun{
#' ### Example 2 using The Manhattan distance with incomplete covariates
#' data(simu_data)
#'
#' try1 = transfo_dist(simu_data,quanti = c(3,8), nominal = c(1,4:5,7),
#'                     ordinal = c(2,6), logic = NULL, prep_choice = "M")
#' res1 = proxim_dist(try1,norme = 1)
#'
#'
#' ### Y and Z are a same variable encoded in 2 different forms:
#' ### (3 levels for Y and 5 levels for Z)
#' ### ... Stored in two distinct databases, A and B, respectively
#' ### The marginal distribution of Y in B is unknown,
#' ### as the marginal distribution of Z in A ...
#'
#' # By supposing that the following matrix called transport symbolizes
#' # an estimation of the joint distribution L(Y,Z) ...
#' # Note that, in reality this distribution is UNKNOWN and is
#' # estimated in the OT function by resolving an optimisation problem.
#'
#' transport1 = matrix(c(0,0.35285714,0,0.09142857,0,0.03571429,
#'                       0,0,0.08285714,0,0.07857143,0.03142857,
#'                       0.32714286,0,0),ncol = 5,byrow = FALSE)
#'
#'
#' # The affectation of the predicted values of Y in database B and Z in database A
#' # are stored in the following object:
#'
#' res2      = indiv_grp_optimal(res1,jointprobaA = transport1,
#'                               jointprobaB = transport1, percent_closest= 0.90)
#' summary(res2)
#' }
#'

indiv_grp_optimal=function(proxim, jointprobaA, jointprobaB, percent_closest = 1.0){


  if (!is.list(proxim)){

    stop("This object must be a list returned by the proxim_dist function")

  } else {}

  if ((!is.matrix(jointprobaA))|(!is.matrix(jointprobaA))){

    stop("The joint distributions must be store in matrix objects")

  } else {}

  if ((ncol(jointprobaA) != ncol(jointprobaB))|(nrow(jointprobaA) != nrow(jointprobaB))){

    stop("The joint distributions must be store in matrix of same size")

  } else {}


  if ((format(sum(jointprobaA)) != "1")| (format(sum(jointprobaB)) != "1")){

    stop("The sum of the jointprobaA matrix or the sum of the jointprobaB matrix differs from 1 !")

  } else {}


  if ((percent_closest>1)|(percent_closest <= 0)){

    stop("Incorrect value for the percent_closest option")

  } else {}

  # Redefine A and B for the model
  A      = 1:proxim$nA
  B      = 1:proxim$nB
  Y      = proxim$Y
  Z      = proxim$Z
  indY   = proxim$indY
  indZ   = proxim$indZ
  nbindY = numeric(0)

  for (y in Y){

    nbindY = c(nbindY,length(proxim$indY[[y]]))}
    nbindZ= numeric(0)

  for (z in Z){

    nbindZ = c(nbindZ,length(proxim$indZ[[z]]))}

  # Create a model for the optimal transport of individuals
  # indiv = Model(solver=IpoptSolver(print_level=4))
  # indiv = Model(with_optimizer(Clp.Optimizer,LogLevel=0))
  # indiv = Model(solver=GurobiSolver(Method=2,LogToConsole=0)); #Presolve=0,Method=2,Crossover=0))


  # Variables
  # - assignA[i][z] : fraction of individual i assigned to modality z
  # @variable(indiv, assignA[i in A, z in Z] >= 0, base_name="assignA")
  # - assignB[j][y] : fraction of individual j assigned to modality y
  # @variable(indiv, assignB[j in B, y in Y] >= 0, base_name="assignB")

  # compute the average distance between the individuals and the modalities of
  # the other base
  CA = matrix(rep(0,proxim$nA * length(Z)), nrow = proxim$nA,ncol = length(Z))
  CB = matrix(rep(0,proxim$nB * length(Y)), nrow = proxim$nB,ncol = length(Y))

  for (i in A){

    for (z in Z){

      nbclose      = round(percent_closest*nbindZ[z])
      distance     = sort(proxim$D[i,indZ[[z]]])
      CA[i,z]      = sum(distance[1:nbclose])/nbclose

      }
  }

  for (j in B){

    for (y in Y){

      nbclose      = round(percent_closest*nbindY[y])
      distance     = sort(proxim$D[indY[[y]],j])
      CB[j,y]      = CB[j,y] + sum(distance[1:nbclose])/nbclose

      }
  }

  # Objective: minimize the distance between individuals of A and B
  #@objective(indiv, Min, sum(CA[i,z]*assignA[i,z] for i in A, z in Z)
  #                        + sum(CB[j,y]*assignB[j,y] for j in B, y in Y))

  CAf <- function(i,z){

    CA[i,z]

  }

  CBf <- function(j,y){

    CB[j,y]

    }

  result <-  MIPModel() %>%
    add_variable(assignA[i,z],  i = A, z = Z,type = "continuous",lb=0) %>%
    add_variable(assignB[j,y],  j = B, y = Y,type = "continuous",lb=0) %>%
    set_objective(sum_expr(CAf(i,z)*assignA[i,z], i = A,z=Z) + sum_expr(CBf(j,y)*assignB[j,y],j = B,y=Y), "min") %>%
    add_constraint(sum_expr(assignA[i,z], i=indY[[y]])   == jointprobaA[y,z], z = Z, y = Y) %>%
    add_constraint(sum_expr(assignB[j,y], j = indZ[[z]]) == jointprobaB[y,z], z = Z, y = Y) %>%
    add_constraint(sum_expr(assignA[i,z], z = Z) == 1/(length(A)),i = A) %>%
    add_constraint(sum_expr(assignB[j,y], y = Y) == 1/(length(B)),j = B) %>%
    solve_model(with_ROI(solver = "glpk"))

  solution = get_solution(result, assignA[i,z])
  assignA = matrix(solution$value, length(A),length(Z))
  solution = get_solution(result, assignB[j,y])
  assignB=  matrix(solution$value, length(B),length(Y))


  # Extract the values of the solution
  # assignA_val = [value(assignA[i,z]) for i in A, z in Z]
  # assignB_val = [value(assignB[j,y]) for j in B, y in Y]



  # Transport the modality that maximizes frequency
  # YBtrans = [findmax([assignA_val[i,z]  for z in Z])[2] for i in A]
  # YAtrans = [findmax([assignB_val[j,y]  for y in Y])[2] for j in B]
  YBtrans = apply(assignA,1,which.max)
  YAtrans = apply(assignB,1,which.max)

  return(list(YAtrans = YAtrans, ZBtrans = YBtrans))
}