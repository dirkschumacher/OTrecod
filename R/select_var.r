
#' select_var()
#'
#' This function preselects interesting covariates for data integration according
#' to their associations with a target variable. It also detects problem of colinearities between covariates and suggests covariates to remove and interesting candidates to keep
#' When applying Optimal Transportation theory for data interation is the objective of the study, we suggest to apply this function beforehand to the OT function, on each of the two databases to be merged
#'
#' @param databa A data.frame containing variable of any type
#' @param Y A character string (with quotes) corresponding to the name of the target variable
#' @param type_Y A character string (with quotes) corresponding to the type of the target variable. "ORD" (Default) for ordinal type, "MUL" for multinomial type,
#'               and "BIN" for binary type
#' @param threshX A double (=0.90 by default) that corresponds to a threshold taken between 0 and 1. Beyond this threshold two variables are considered too highly correlated
#' @param threshY A double (=0.95 by default) that corresponds to a threshold taken between 0 and 1. Beyond this threshold, a variable is considered too highly correlated with the target Y
#' @param thresh_vif A double that corresponds to a threshold (10 by default) of the Variance Important Factor beyond which a multicolinearity situation is highlighted
#' @param index_var A vector of integers that specifies the column indices associated with the covariates
#'
#' @return A list of 6 elements is returned:
#' \item{Y}{A simple reminder of the label of the target of interest}
#' \item{cor_Y}{A list of covariates that are considered too highly correlated (Spearman coefficient) to the target variable}
#' \item{VIF_PB}{A list of covariates which inclusion in regressions could lead to severity problem of multicollinearities}
#' \item{cor_X}{A list of covariates that are considered too highly correlated (Spearman coefficient) with other covariates}
#' @export
#'
#' @author Gregory Guernec
#' \email{gregory.guernec@@inserm.fr}
#'
#' @importFrom stats lm cor na.omit anova glm binomial pchisq p.adjust
#' @importFrom dplyr %>%
#' @import nnet ordinal car
#'
#' @aliases select_var
#'
#' @examples
#'
#' # Ex 1:
#' data(tab_test)
#' tab1 = tab_test[tab_test$ident == 2,]
#'
#' # By taking the ordinal variable Y2 as target:
#' select1 = select_var(tab1,Y = "Y2",index_var = 4:6)
#'
#' # Ex 2:
#' # Using the simu_data table, firstly, we separate the 2 bases A and B ...
#' data(simu_data)
#' simu_A = simu_data[simu_data$DB == "A",]    # Base A
#' simu_B = simu_data[simu_data$DB == "B",]    # Base B
#'
#' # In DB A, the target variable is Yb1.
#' # The indexes of the column covariates go from 4 to 8.
#' # By keeping the other default parameters:
#'
#' select_A = select_var(simu_A,Y = "Yb1",index_var = 4:8)
#'
#' # We conclude here that all covariates seems to be good candidates for OT
#'
#' # Following the same reasoning for the database B:
#' select_B = select_var(simu_B,Y = "Yb2",index_var = 4:8)
#'
#' # We conclude here that all covariates seems to be good candidates for OT
#'
#'
#' # By supposing that the Treatment variable (not ordered) is the target in the DB A:
#' select_A = select_var(simu_A,Y = "Treatment",type_Y = "MUL",index_var = c(2,4,6:8))
#'
#' # By supposing that the Gender variable (binary) is the target in the DB A:
#' select_A = select_var(simu_A,Y = "Gender",type_Y = "BIN",index_var = c(2,5:8))
#'
select_var = function(databa,
                      Y,
                      type_Y     = "ORD",
                      threshX    = 0.90 ,
                      threshY    = 0.95 ,
                      thresh_vif = 10   ,
                      index_var  = 2:ncol(databa)){


  stopifnot(is.data.frame(databa))
  # stopifnot(is.character(Y))
  stopifnot(type_Y %in% c("BIN","ORD","MUL"))
  stopifnot(threshX <=1); stopifnot(threshX >0)
  stopifnot(threshY <=1); stopifnot(threshY >0)
  stopifnot(thresh_vif >0)
  stopifnot(is.vector(index_var))
  stopifnot(class(index_var) %in% c("integer","numeric"))
  stopifnot(length(index_var) < ncol(databa))


  cat("select_var function in progress. Please wait ...","\n")

  indY = which(colnames(databa)==Y)
  dat1 = databa[,c(indY,index_var)]

  ind.char = which(unlist(lapply(dat1,is.character)))

  if (length(ind.char)!=0){

    for (j in 1:length(ind.char)){

      dat1[,ind.char[j]] = as.factor(dat1[,ind.char[j]])

    }

  } else {}

  for (j in 1:ncol(dat1)){

    dat1[,j] = as.numeric(dat1[,j])

  }


  datababis = dat1[,-1]
  model1    = stats::lm(dat1[,Y] ~.,data = datababis)
  vifmod    = sort(car::vif(model1),decreasing = TRUE)
  vif_pb    = vifmod[vifmod > thresh_vif]


  cor_mat = stats::cor(stats::na.omit(dat1),method = "spearman")
  diag(cor_mat) = 0

  cor_Y     = sort(round(cor_mat[,Y],3),decreasing = TRUE)
  cor_Y     = cor_Y[abs(cor_Y)>threshY]

  indi      = (1:ncol(cor_mat))[colnames(cor_mat) == Y]
  cor_mat2  = cor_mat[-indi,-indi]


  name1     = rep(row.names(cor_mat2),each = nrow(cor_mat2))
  name2     = rep(row.names(cor_mat2),nrow(cor_mat2))
  correl    = round(as.numeric(cor_mat2),3)

  tab_cor   = data.frame(name1,name2,correl)
  tab_cor   = tab_cor[abs(tab_cor$correl)>threshX,]
  cor_X     = tab_cor[duplicated(tab_cor$correl)==FALSE,]


  indouble        = which(sapply(dat1,is.double))
  indfactor       = which(sapply(dat1,is.factor))
  dat3            = dat1
  dat3[,indouble] = apply(dat3[,indouble],2,scale)
  dat3[,indfactor]= apply(dat3[,indfactor],2,as.character)
  dat3            = stats::na.omit(dat3)
  dat1            = stats::na.omit(dat1)

  ind_new   = (1:ncol(dat3))[colnames(dat3) %in% setdiff(names(dat3),c(names(cor_Y),Y))]
  names_new = names(dat3)[colnames(dat3) %in% setdiff(names(dat3),c(names(cor_Y),Y))]

  pval = vector(length = length(ind_new))


  if (type_Y == "ORD"){

    for (j in 1:length(ind_new)){

      # print(j)

      ordi_mod  = ordinal::clm(as.ordered(dat1[,Y]) ~ dat3[,ind_new[j]],data=dat3,link="logit")
      ordi_NULL = ordinal::clm(as.ordered(dat1[,Y]) ~ 1,data=dat3,link="logit")
      pval[j]   = stats::anova(ordi_mod,ordi_NULL)[[6]][2]

    }

  } else if (type_Y == "MUL"){

    for (j in 1:length(ind_new)){

      nomi_mod  = nnet::multinom(dat1[,Y] ~ dat3[,ind_new[j]],data=dat3,trace=F)
      nomi_NULL = nnet::multinom(dat1[,Y] ~ 1,data=dat3,trace=F)
      pval[j]   = stats::anova(nomi_mod,nomi_NULL)[[7]][2]

    }

  } else if (type_Y == "BIN"){

    if (length(names(table(dat1[,Y]))) > 2){

      stop("Your outcome counts more than 2 modalities")

    } else {}

    dat1[,Y]  = dat1[,Y] - 1

    for (j in 1:length(ind_new)){

      bin_mod   = stats::glm(dat1[,Y] ~ dat3[,ind_new[j]],data=dat3,family = stats::binomial(link="logit"))
      pval[j]   = 1-stats::pchisq(bin_mod$null.deviance-bin_mod$deviance, bin_mod$df.null-bin_mod$df.residual)

    }

  } else {stop("Mispecified value for the type_Y option: Please consult the help function for more details")}

  select_X        = data.frame(NAME = names_new,pval)
  select_X        = select_X[sort.list(select_X$pval,decreasing = FALSE),]
  select_X$CORREC = stats::p.adjust(select_X$pval,method = "bonferroni")

  select_X        = select_X [select_X$CORREC < 0.05,]

  name_cov = as.character(select_X$NAME)

  keep_cov  = NA
  suppr_cov = NA

  if (nrow(cor_X)!=0){

  for (k in 1:nrow(cor_X)){

    names_corX =c(as.character(cor_X[k,1]),as.character(cor_X[k,2]))

    if (length(intersect(name_cov,names_corX))!=0){

      ind_names  = which(name_cov %in% names_corX)
      keep_cv    = name_cov[min(ind_names)]
      suppr_cv   = setdiff(names_corX,keep_cv)

    } else {

      keep_cv = suppr_cv = NULL

    }

    keep_cov  = c(keep_cov,keep_cv)
    suppr_cov = c(suppr_cov,suppr_cv)

  }
  } else {suppr_cov = NULL}

  keep_cov_fin = setdiff(name_cov,unique(c(names(cor_Y),suppr_cov[-1])))
  del_cov_fin  = unique(c(names(cor_Y),suppr_cov[-1]))

  return(list(Y = Y, cor_Y = cor_Y, VIF_PB = vif_pb, KEEP_COV = keep_cov_fin,
              DEL_COV = del_cov_fin,
              PVAL_Y = select_X[!(select_X$NAME %in% del_cov_fin),]))

}
