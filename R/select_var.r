
#' select_var
#' 
#' This function preselect variables according to their associations with each other and according to their associations with a target variable
#'
#' @param databa A data.frame containing variable of any type
#' @param Y A character string (with quotes) corresponding to the name of the target variable
#' @param type_Y A character string (with quotes) corresponding to the type of the target variable. "ORD" (Default) for ordinal type, "MUL" for multinomial type,
#'               and "BIN" for binary type  
#' @param threshX A double that corresponds to a threshold taken between 0 and 1.Beyond this threshold two variables are considered too highly correlated
#' @param threshY A double that corresponds to a threshold taken between 0 and 1.Beyond this threshold, a variable is considered too highly correlated with the target Y
#' @param thresh_vif A double that corresponds to a threshold (10 by default) of the Variance Important Factor beyond which a multicolinearity situation is highlighted
#'
#' @return A list of 6 elements:
#'         Y A simple reminder of the name of the selected target
#'         cor_Y A table of variables which are considered too highly correlated (Spearson coefficient) with the target
#'         VIF_PB 
#'         cor_X A table of variables which are considered too highly correlated (Spearson coefficient) with other covariates
#' @export
#'
#' @examples
#' data(samp.A)   # Require Statmatch package
#' dat1 = samp.A[,-1]
#' sel_cov = select_var(dat1,Y = "c.neti")

select_var = function(databa,Y,type_Y = "ORD",threshX = 0.90,threshY = 0.95,thresh_vif = 10){

    
  stopifnot(is.data.frame(databa))
  stopifnot(is.character(Y))
  stopifnot(type_Y %in% c("BIN","ORD","MUL"))
  stopifnot(threshX <=1); stopifnot(threshX >0)
  stopifnot(threshY <=1); stopifnot(threshY >0)
  stopifnot(thresh_vif >0)
  
  cat("select_var function in progress. Please wait ...","\n")
  
  for (j in 1:ncol(databa)){
    
    databa[,j] = as.numeric(databa[,j])
    
  }
  
  indY = (1:ncol(databa))[colnames(databa) == Y]
  
  datababis = databa[,-indY]
  model1  = lm(databa[,Y] ~.,data = datababis)
  vifmod  = sort(vif(model1),decreasing = TRUE)
  vif_pb  = vifmod[vifmod > 10]
  
  
  cor_mat = cor(databa,method = "spearman")
  diag(cor_mat) = 0
  Y        = "c.neti"
  cor_Y    = sort(round(cor_mat[,Y],3),decreasing = TRUE)
  cor_Y    = cor_Y[abs(cor_Y)>threshY]
  
  indi     =(1:ncol(cor_mat))[colnames(cor_mat) == Y]
  cor_mat2 = cor_mat[-indi,-indi]
  
  
  name1  = rep(row.names(cor_mat2),each = nrow(cor_mat2))
  name2  = rep(row.names(cor_mat2),nrow(cor_mat2))
  correl = round(as.numeric(cor_mat2),3)
  
  tab_cor  = data.frame(name1,name2,correl)
  tab_cor  = tab_cor[abs(tab_cor$correl)>threshX,]
  cor_X    = tab_cor[duplicated(tab_cor$correl)==FALSE,]
  
  
  indouble        = which(sapply(dat1,is.double))
  dat3            = dat1
  dat3[,indouble] = apply(dat3[,indouble],2,scale)
  
  
  ind_new   = (1:ncol(dat3))[colnames(dat3) %in% setdiff(names(dat3),Y)] 
  names_new = names(dat3)[colnames(dat3) %in% setdiff(names(dat3),Y)] 
  
  pval = vector(length = length(ind_new))
  
  
  if (type_Y == "ORD"){
    
    for (j in 1:length(ind_new)){
      
      # print(j)
      
      ordi_mod  = clm(as.ordered(dat1[,Y]) ~ dat3[,ind_new[j]],data=dat3,link="logit")
      ordi_NULL = clm(as.ordered(dat1[,Y]) ~ 1,data=dat3,link="logit")
      pval[j]   = anova(ordi_mod,ordi_NULL)[[6]][2]
      
    }
    
  } else if (type_Y == "MUL"){
    
    for (j in 1:length(ind_new)){
      
      nomi_mod  = multinom(dat1[,Y] ~ dat3[,ind_new[j]],data=dat3,trace=F)
      nomi_NULL = multinom(dat1[,Y] ~ 1,data=dat3,trace=F)
      pval[j]   = anova(nomi_mod,nomi_NULL)[[7]][2] 
      
    }
    
  } else if (type_Y == "BIN"){
    
    if (length(names(table(dat1[,Y]))) > 2){
      
      stop("Your outcome counts more than 2 modalities")
      
    } else {}
    
    
    for (j in 1:length(ind_new)){
      
      bin_mod   = glm(dat1[,Y] ~ dat3[,ind_new[j]],data=dat3,family = binomial(link="logit"))
      pval[j]   = 1-pchisq(bin_mod$null.deviance-bin_mod$deviance, bin_mod$df.null-bin_mod$df.residual) 
      
    }
    
  } else {stop("Mispecified value for the type_Y option: Please consult the help function for more details")}
  
  select_X        = data.frame(NAME = names_new,pval)
  select_X        = select_X[sort.list(select_X$pval,decreasing = FALSE),]
  select_X$CORREC = p.adjust(select_X$pval,method = "bonferroni")
  
  select_X        = select_X [select_X$CORREC < 0.05,]
  
  name_cov = as.character(select_X$NAME)
  
  keep_cov  = NA
  suppr_cov = NA
  
  
  for (k in 1:nrow(cor_X)){
    
    names_corX =c(as.character(cor_X[k,1]),as.character(cor_X[k,2]))
    ind_names  = which(name_cov %in% names_corX)
    keep_cv  = name_cov[min(ind_names)]
    suppr_cv = setdiff(names_corX,keep_cv)
    
    keep_cov  = c(keep_cov,keep_cv)
    suppr_cov = c(suppr_cov,suppr_cv)
    
  }
  
  keep_cov_fin = setdiff(name_cov,unique(c(names(cor_Y),suppr_cov[-1])))
  del_cov_fin  = unique(c(names(cor_Y),suppr_cov[-1]))
  
  return(list(Y = Y, cor_Y = cor_Y, VIF_PB = vif_pb, KEEP_COV = keep_cov_fin, 
              DEL_COV = del_cov_fin,
              PVAL_Y = select_X[!(select_X$NAME %in% del_cov_fin),]))
  
}
