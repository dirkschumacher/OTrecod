#' merge_dbs()
#'
#' Overlay of two databases with specific outcome variables and shared covariates
#'
#' Assuming that A and B are 2 databases (2 separate data.frames in R) to merge vertically, the function \code{merge_dbs} performs this overlay by checking the compatibility of the shared variables between the bases.
#' The 2 databases must be made up of a target variable (By example, \code{Y} in A and \code{Z} in B respectively, so that \code{Y} is missing in B and \code{Z} is missing in A), a subset of shared covariates (By example, the best predictors of Y in A, and Z in B),
#' and another possible subset of variables specific to each database.
#' A rule decided for the overlay is that the first base declared (\code{DB1}) will be placed above the second one (\code{DB2}).
#' This function proposes a helpul tool for any user who wants to prepare their databases to solve matching problems using Optimal Transportation theory.
#' This function can so corresponds to the 2nd preliminary step for data fusion using Optimal Transportation theory, where the sets of best predictors, specific to each base, would be selected using the function \code{select_pred}.
#' Neverhteless, it is not compulsory to have used the function \code{select_pred} beforehand, to use the function \code{merge_dbs}.
#'
#'
#' A. The function \code{merge_dbs} handles incomplete information, by respecting the following rules:
#' \itemize{
#' \item If \code{Y} or \code{Z} have missing values in A or B, corresponding raws are excluded from the database before merging.
#' \item Before overlay, the function deals with incomplete covariates according to the argument \code{impute}.
#' Users can decide to work with complete case only ("CC"), to keep ("NO") or impute missing data ("MICE","FAMD").
#' \item the function \code{imput_cov}, integrated in the syntax of \code{merge_dbs} deals with imputations. Two approaches are actually available:
#' The multivariate imputation by chained equation approach (MICE, see Van Buuren 2011 for more details about the approach or the corresponding package \pkg{mice}),
#' and an imputation approach from the package \pkg{missMDA} that uses a dimensionality reduction method (Here a factor analysis for mixed data called FAMD, see Audigier 2013), to provide single imputations.
#' If multiple imputation is required (\code{impute} = "MICE"), the average of the plausible values will be retained for a continuous variable, while the most frequent candidate will be remained for a categorical variable or factor (ordinal or not).
#' }
#'
#' B. The function \code{merge_dbs} studies the compatiblities between A and B, of each shared covariate, by respecting the following rules:
#' \itemize{
#' \item The formats of \code{Y} and \code{Z} must be suitable. Categorical (ordered or not) factors are allowed. Numeric outcomes with infinite values are not allowed and discrete outcomes with finite values will be automatically converted as ordered factors
#' using the function \code{transfo_target} integrated in the function \code{merge_dbs}.
#' \item Shared covariate with incompatible format between the 2 database will be removed from the merging and the related label saved in output (\code{REMOVE1}).
#' \item Shared factor with incompatible levels (or number of levels) will be removed from the merging and the related label saved in output (\code{REMOVE2}).
#' \item Covariates whose names are specific to each database will be also deleted from the merging.
#' }
#' Notice that if certain important predictors have been improperly excluded from the merging, users can make the necessary transformations on these variables, and re-run the function.
#' As a finally step, the function checks that all values related to Y in B are missing and inversely for Z in A.
#'
#' @param DB1 A data.frame corresponding to the 1st database to merge (Top database)
#' @param DB2 A data.frame corresponding to the 2nd database to merge (Bottom database)
#' @param NAME_Y Name of the outcome (with quotes) in its specific scale/encoding gathered from the 1st database
#' @param NAME_Z Name of the outcome (with quotes) in its specific scale/encoding gathered from the 2nd database
#' @param order_levels_Y To complete only if Y is considered as an ordinal factor (scale). A vector of labels of levels (with quotes) sorted in ascending order in DB1
#' @param order_levels_Z To complete only if Y is considered as an ordinal factor.A vector of labels of levels sorted in ascending order in DB2 with different scale from DB1
#' @param ordinal_DB1 Vector of index of columns corresponding to ordinal variables in DB1 (No ordinal variable by default)
#' @param ordinal_DB2 Vector of index of columns corresponding to ordinal variables in DB2 (No ordinal variable by default)
#' @param impute A character (with quotes) equals to "NO" when missing data on covariates are kept (By default), "CC" for Complete Case by keeping only covariates with no missing information , "MICE" for MICE multiple imputation approach, "FAMD" for single imputation approach using Factorial Analysis for Mixed Data
#' @param R_MICE Number of multiple imputations require for te  MICE approach (5 by default)
#' @param NCP_FAMD Integer corresponding to the number of components used to predict missing values in FAMD imputation (3 by default)
#' @param seed_func Integer used as argument by the set.seed() for offsetting the random number generator (Random integer by default, only useful with MICE)
#'
#' @return A list containing 10 elements (11 if the argument \code{impute} equals "MICE"):
#' \item{DB_READY}{The database matched from the 2 initial BDDs with common covariates and imputed or not according to the impute option}
#' \item{Y_LEVELS}{Levels retained for the target variable in the DB1}
#' \item{Z_LEVELS}{Levels retained for the target variable in the DB2}
#' \item{REMOVE1}{Labels of deleted covariates because of their different types observed from DB1 to DB2}
#' \item{REMOVE2}{Removed factor(s) because of their different levels observed from DB1 to DB2}
#' \item{REMAINING_VAR}{Labels of the covariates remained for the data integration using OT algorithm}
#' \item{IMPUTE_TYPE}{A character with quotes that specify the method eventually chosen to handle missing data in covariates}
#' \item{MICE_DETAILS}{A list containing the details of the imputed datasets using \code{MICE} when this option is enabled. Databases imputed for DB1 and DB2 according to the number of mutliple imputation selected (Only if impute = "MICE")}
#' \item{DB1_RAW}{A data.frame corresponding to the 1st raw database}
#' \item{DB2_RAW}{A data.frame corresponding to the 2nd raw database}
#' \item{SEED}{An integer used as argument by the \code{set.seed} function for offsetting the random number generator (random selection by default)}
#'
#' @export
#'
#' @seealso \code{\link{imput_cov}},\code{\link{transfo_target}},\code{\link{select_pred}}
#'
#' @aliases merge_dbs
#'
#' @author Gregory Guernec
#' \email{gregory.guernec@@inserm.fr}
#'
#' @references
#' ### For the Optimal Transportation algorithm:
#' Gares V, Dimeglio C, Guernec G, Fantin F, Lepage B, Korosok MR, savy N (2019). On the use of optimal transportation theory to recode variables and application to database merging. The International Journal of Biostatistics.
#' 0, 20180106 (2019),\url{https://doi.org/10.1515/ijb-2018-0106}
#'
#' ### For the imputation of missing values using factor analysis for mixed data, see documents related to the (\code{\link[missMDA]{missMDA-package}}) package like:
#' Audigier, V., Husson, F. & Josse, J. (2013). A principal components method to impute mixed data. Advances in Data Analysis and Classification, 10(1), 5-26.
#'
#' ### For multiple imputation using MICE, see documents related to the (\code{\link[mice]{mice}}) package like:
#' van Buuren, S., Groothuis-Oudshoorn, K. (2011). mice: Multivariate Imputation by Chained Equations in R. Journal of Statistical Software, 45(3), 1–67.
#'
#'
#' @importFrom stats na.omit
#'
#' @examples
#'
#' ### Suppose that we have 2 distinct databases (from simu_data): data_A and data_B
#' data(simu_data)
#' data_A = simu_data[simu_data$DB == "A",c(2,4:8)]; head(data_A)
#' data_B = simu_data[simu_data$DB == "B",c(3,4:8)]; head(data_B)
#'
#' # For the example, we add a coavariate (Weight) only in data_A
#' data_A$Weight = rnorm(300,70,5)
#'
#' # Be careful: your target variables must be in factor (or ordered) in your 2 databases
#' # Because it is not the case for Yb2 in data_B, we convert it.
#' data_B$Yb2    = as.factor(data_B$Yb2)
#'
#' # Moreover, we store the Dosage covariate in 3 classes in data_B (instead of 4 classes in data_B)
#' data_B$Dosage = as.character(data_B$Dosage)
#' data_B$Dosage = as.factor(ifelse(data_B$Dosage %in% c("Dos 1","Dos 2"),"D1",
#'                           ifelse(data_B$Dosage == "Dos 3","D3","D4")))
#'
#' # For more diversity, we put this covariate at the last column of the data_B
#' data_B        = data_B[,c(1:3,5,6,4)]
#'
#' # Ex 1: We merged the 2 databases and impute covariates using MICE
#' soluc1  = merge_dbs(data_A,data_B,
#' NAME_Y = "Yb1",NAME_Z = "Yb2",
#' ordinal_DB1 = c(1,4), ordinal_DB2 = c(1,6),
#' impute = "MICE",R_MICE = 2, seed_func = 3011)
#' summary(soluc1$DB_READY)
#'
#'
#' # Ex 2: We merged the 2 databases and kept all missing data
#' soluc2  = merge_dbs(data_A,data_B,
#' NAME_Y = "Yb1",NAME_Z = "Yb2",
#' ordinal_DB1 = c(1,4), ordinal_DB2 = c(1,6),
#' impute = "NO",seed_func = 3011)
#'
#' # Ex 3: We merged the 2 databases by only keeping the complete cases
#' soluc3  = merge_dbs(data_A,data_B,
#' NAME_Y = "Yb1",NAME_Z = "Yb2",
#' ordinal_DB1 = c(1,4), ordinal_DB2 = c(1,6),
#' impute = "CC",seed_func = 3011)
#'
#' # Ex 4: We merged the 2 databases and impute covariates using FAMD
#' soluc4  = merge_dbs(data_A,data_B,
#' NAME_Y = "Yb1",NAME_Z = "Yb2",
#' ordinal_DB1 = c(1,4), ordinal_DB2 = c(1,6),
#' impute = "FAMD",NCP_FAMD = 4,seed_func = 2096)
#'
#' # Conclusion:
#' # The data fusion is successful in each situation.
#' # The Dosage and Weight covariates have been normally excluded from the fusion.
#' # The covariates have been imputed when required.
#'
merge_dbs = function(DB1,
                     DB2,
                     NAME_Y,
                     NAME_Z,
                     order_levels_Y = levels(DB1[, NAME_Y]),
                     order_levels_Z = levels(DB2[, NAME_Z]),
                     ordinal_DB1 = NULL,
                     ordinal_DB2 = NULL,
                     impute = "NO",
                     R_MICE = 5,
                     NCP_FAMD = 3,
                     seed_func = sample(1:1000000, 1)) {
  cat("DBS MERGING in progress. Please wait ...", "\n")

  DB1_raw = DB1
  DB2_raw = DB2


  # Constraints on the 2 databases
  #--------------------------------

  if ((!is.data.frame(DB1)) | (!is.data.frame(DB2))) {
    stop("At least one of your two objects is not a data.frame!")

  } else {
  }


  if ((is.character(NAME_Y) != TRUE) |
      (is.character(NAME_Z) != TRUE)) {
    stop ("NAME_Y and NAME_Z must be declared as strings of characters with quotes")

  } else {
  }


  if ((length(NAME_Y) != 1) | (length(NAME_Z) != 1)) {
    stop ("No or more than one target declared by DB !")

  } else {
  }

  if ((is.null(levels(DB1[, NAME_Y])))|(is.null(levels(DB2[, NAME_Z])))){

    stop ("Your target variable must be a factor in the 2 databases")

  } else{
  }


  if ((!(is.numeric(R_MICE)))|(!(is.numeric(NCP_FAMD)))){

    stop ("The options R_MICE and NCP_FAMD must contain numeric values")

  } else {

  }

  if (!(impute %in% c("CC","FAMD","MICE","NO"))){

    stop("Invalid character in the impute option: You must choose between NO, FAMD, CC and MICE")

  } else {

  }

  if ((length(ordinal_DB1)>ncol(DB1))|(length(ordinal_DB2)>ncol(DB2))){

    stop("The number of column indexes exceeds the number of columns of your DB")

  } else {

  }


  # Remove subjects in DB1 (resp. DB2) with Y (resp.Z) missing
  #-------------------------------------------------------------

  NB1_1 = nrow(DB1)
  NB2_1 = nrow(DB2)


  DB1   = DB1[!is.na(DB1[, NAME_Y]), ]
  DB2   = DB2[!is.na(DB2[, NAME_Z]), ]

  NB1_2 = nrow(DB1)
  NB2_2 = nrow(DB2)



  REMOVE_SUBJECT1 = NB1_1 - NB1_2
  REMOVE_SUBJECT2 = NB2_1 - NB2_2




  # Covariates selection
  #----------------------

  # Impute NA in covariates from DB1 and DB2 if necessary


  count_lev1  = apply(DB1, 2, function(x) {
    length(names(table(x)))
  })
  num_lev1    = sapply(DB1, is.numeric)

  typ_cov_DB1 = ifelse (((1:ncol(DB1)) %in% ordinal_DB1) &
                          (count_lev1 > 2),
                        "polr",
                        ifelse ((count_lev1 == 2) &
                                  (num_lev1 == FALSE),
                                "logreg",
                                ifelse (num_lev1 == TRUE, "pmm", "polyreg")
                        ))


  count_lev2  = apply(DB2, 2, function(x) {
    length(names(table(x)))
  })
  num_lev2    = sapply(DB2, is.numeric)

  typ_cov_DB2 = ifelse (((1:ncol(DB2)) %in% ordinal_DB2) &
                          (count_lev2 > 2),
                        "polr",
                        ifelse ((count_lev2 == 2) &
                                  (num_lev2 == FALSE),
                                "logreg",
                                ifelse (num_lev2 == TRUE, "pmm", "polyreg")
                        ))

  typ_cov_DB1b = typ_cov_DB1[setdiff(names(DB1), NAME_Y)]
  typ_cov_DB2b = typ_cov_DB2[setdiff(names(DB2), NAME_Z)]


  if ((setequal(DB1, stats::na.omit(DB1))) &
      (setequal(DB2, stats::na.omit(DB2))) & (impute != "NO")) {
    cat("No missing values in covariates: No imputation methods required",
        "\n")
    impute = "NO"

  } else {
  }


  if (impute == "CC") {
    DB1 = stats::na.omit(DB1)
    DB2 = stats::na.omit(DB2)

    DB1_new = stats::na.omit(DB1[, setdiff(names(DB1), NAME_Y)])
    DB2_new = stats::na.omit(DB2[, setdiff(names(DB2), NAME_Z)])

  } else if (impute == "MICE") {
    DB1bis       = imput_cov(
      DB1[, setdiff(names(DB1), NAME_Y)],
      R_mice = R_MICE,
      meth = typ_cov_DB1b,
      missMDA = FALSE,
      seed_choice = seed_func
    )
    DB2bis       = imput_cov(
      DB2[, setdiff(names(DB2), NAME_Z)],
      R_mice = R_MICE,
      meth = typ_cov_DB2b,
      missMDA = FALSE,
      seed_choice = seed_func
    )


  } else if (impute == "FAMD") {
    DB1bis       = imput_cov(
      DB1[, setdiff(names(DB1), NAME_Y)],
      meth = typ_cov_DB1b,
      missMDA = TRUE,
      NB_COMP = NCP_FAMD,
      seed_choice = seed_func
    )
    DB2bis       = imput_cov(
      DB2[, setdiff(names(DB2), NAME_Z)],
      meth = typ_cov_DB2b,
      missMDA = TRUE,
      NB_COMP = NCP_FAMD,
      seed_choice = seed_func
    )


  } else if (impute == "NO") {
    DB1_new = DB1[, setdiff(names(DB1), NAME_Y)]
    DB2_new = DB2[, setdiff(names(DB2), NAME_Z)]

  } else {
    stop("The specification of the impute option is false: NO, CC, MICE, MDA only")
  }


  # Transform Y
  #-------------

  cat("Y", "\n")
  Y            = transfo_target(DB1[, NAME_Y], levels_order = order_levels_Y)$NEW
  cat("Z", "\n")
  Z            = transfo_target(DB2[, NAME_Z], levels_order = order_levels_Z)$NEW

  if (setequal(levels(Y), levels(Z))) {
    stop("Your target has identical labels in the 2 databases !")

  } else {
  }




  # Y and Z extracted from DB1 and DB2

  if (impute %in% c("MICE", "FAMD")) {
    DB1_new = DB1bis$DATA_IMPUTE
    DB2_new = DB2bis$DATA_IMPUTE

  } else {
  }


  # Covariates re-ordered by their names in each DB

  DB1_new          = DB1_new[, order(names(DB1_new))]
  DB2_new          = DB2_new[, order(names(DB2_new))]


  # Names of the common covariates between the two DB

  same_cov      = intersect(names(DB1_new), names(DB2_new))
  n_col         = length(same_cov)


  # Remaining common covariates in each DB

  DB1_4FUS     = DB1_new[, same_cov]
  DB2_4FUS     = DB2_new[, same_cov]


  # Removed covariate(s) because of their different types from DB1 to DB2

  list1   = as.list(lapply(DB1_4FUS, class))
  list1   = lapply(list1, paste, collapse = " ")
  l1      = unlist(list1)

  list2   = as.list(lapply(DB2_4FUS, class))
  list2   = lapply(list2, paste, collapse = " ")
  l2      = unlist(list2)


  ind_typ       = (l1 != l2)

  if (sum(ind_typ) != 0) {
    remove_var1 = same_cov[ind_typ]

  } else {
    remove_var1 = NULL
  }



  # Removed factor(s) because of their different levels from DB1 to DB2

  modif_factor = (1:n_col)[l1 %in% c("factor", "ordered factor")]

  same_cov2 = same_cov[modif_factor]

  levels_DB1 = sapply(DB1_4FUS[, modif_factor], levels)
  levels_DB2 = sapply(DB2_4FUS[, modif_factor], levels)


  ind_fac = compare_lists(levels_DB1, levels_DB2)

  if (sum(ind_fac) != 0) {
    remove_var2 = same_cov2[ind_fac]

  } else {
    remove_var2 = NULL
  }


  # Names of variables removed before merging

  remove_var = c(remove_var1, remove_var2)


  # Names of variables remained before merging

  remain_var = setdiff(same_cov, remove_var)

  if (length(remain_var) == 0) {
    stop("no common variable selected in the 2 DBS except the target !")

  } else {
  }


  DB1_4FUS = DB1_4FUS[, remain_var]
  DB2_4FUS = DB2_4FUS[, remain_var]

  Zb = sample(Z, length(Y), replace = T)

  DB_COV = rbind(
    data.frame(DB = rep(1, nrow(DB1_4FUS)), Y, Z = Zb, DB1_4FUS),
    data.frame(
      DB = rep(2, nrow(DB2_4FUS)),
      Y = rep(NA, nrow(DB2_4FUS)),
      Z,
      DB2_4FUS
    )

  )

  DB_COV$Z[1:nrow(DB1_4FUS)] = rep(NA, nrow(DB1_4FUS))

  cat("DBS MERGING OK", "\n")
  cat(rep("-", 23), sep = "")
  cat("\n")
  cat("SUMMARY OF DBS MERGING:", "\n")
  cat(
    "Nb of removed subjects because of NA on Y:",
    REMOVE_SUBJECT1 + REMOVE_SUBJECT2,
    "(",
    round((REMOVE_SUBJECT1 + REMOVE_SUBJECT2) * 100 / (NB1_1 + NB2_1)),
    "%)",
    "\n"
  )
  cat("Nb of removed covariates because of their different types:",
      length(remove_var),
      "\n")
  cat("Nb of remained covariates:", ncol(DB_COV) - 3, "\n")
  cat("More details in output ...", "\n")

  if (impute %in% c("NO", "CC", "FAMD")) {
    return(
      list(
        DB_READY = DB_COV,
        Y_LEVELS = levels(DB_COV$Y),
        Z_LEVELS = levels(DB_COV$Z),
        REMOVE1 = remove_var1,
        REMOVE2 = remove_var2,
        REMAINING_VAR = colnames(DB_COV)[4:ncol(DB_COV)],
        IMPUTE_TYPE = impute,
        DB1_RAW = DB1_raw,
        DB2_RAW = DB2_raw,
        SEED = seed_func
      )
    )

  } else if (impute == "MICE") {
    return(
      list(
        DB_READY = DB_COV,
        Y_LEVELS = levels(DB_COV$Y),
        Z_LEVELS = levels(DB_COV$Z),
        REMOVE1 = remove_var1,
        REMOVE2 = remove_var2,
        REMAINING_VAR = colnames(DB_COV)[4:ncol(DB_COV)],
        IMPUTE_TYPE = impute,
        MICE_DETAILS = list(
          DB1 = list(RAW = DB1bis[[1]], LIST_IMPS = DB1bis[[4]]),
          DB2 = list(RAW = DB2bis[[1]], LIST_IMPS = DB2bis[[4]])
        ),
        DB1_RAW = DB1_raw,
        DB2_RAW = DB2_raw,
        SEED = seed_func
      )
    )

  }

}
