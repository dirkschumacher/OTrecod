library(OTrecod)
#----------------------------- THE OTrecod PACKAGE --------------------------------------------------------------------------------
# An application of the functions of the package on a real dataset      (07/2019)
#----------------------------------------------------------------------------------------------------------------------------------



# EXEMPLE: From the "samp.A" database of the StatMatch package. 
#--------------------------------------------------------------

# Description (see ?samp.A for more details) ------------------
# This data set provides a limited number of variables observed at persons levels among those usually collected in the European Union
# Statistics on Income and Living Conditions Survey (EU–SILC). 
#
# It has been artificially generated as follows to show an application of the OTrecod package.
#
# --> 2 databases: data3 and data4
# --> c.neti (only in data3) and c.neti.bis (only in data4) coded voluntarily in 2 distinct encodings but represent the same information
# --> c.neti is a factor variable corresponding to the person's net income initially categorized in 7 classes of thousand of Euros
# --> data3 and data4 are composed of Subsets of specific and common covariates of different types, with incomplete information



# I. Preparing the dataset
#--------------------------

library(StatMatch)

data(samp.A)
samp.A = samp.A[,c(1:11,13,12)]
dim(samp.A); names(samp.A)
# [1] 3009   14
# [1] "HH.P.id"    "area5"      "urb"        "hsize"      "hsize5"     "age"        "c.age"      "sex"        "marital"   
# [10] "edu7"       "n.income"   "ww"         "c.neti"     "c.neti.bis"


c.neti            = as.numeric(samp.A$c.neti)

samp.A$c.neti.bis = as.factor(ifelse(c.neti %in% c(1,2),1,
                                    ifelse(c.neti %in% c(3,4),2,
                                           ifelse(c.neti %in% c(5,6),3,4))))
data1 = samp.A[1:600,c(2:9,13)]
data2 = samp.A[601:1000,c(5:11,12,14)]
#--> 600 rows for data1 and 400 rows for data2


# Insert the common covariate "marital" in 2 different types int the 2 database
data1$marital = as.numeric(data1$marital)

# Insert eventually different levels in a common factor variable called "c.age"
# data2$c.age = as.character(data2$c.age)
# data2$c.age[data2$c.age %in% c("[16,34]","(34,44]")] = "[16,44]"
# data2$c.age = as.factor(data2$c.age)

# Add random NA in covariates (10% by covariates):
add_NA = function(DB,tx){
  DB_NA = DB
  for (j in 1:ncol(DB)){
     NA_indic = sample(1:nrow(DB),round(nrow(DB)*tx/100),replace=FALSE)
     DB_NA[NA_indic,j] = rep(NA,length(NA_indic))
  }
return(DB_NA)
}

set.seed(4036); data3 = add_NA(data1,10); data4 = add_NA(data2,10)

#----- OUTCOME: c.neti in 7 modalities in data3
table(data3$c.neti)
# (-Inf,0]    (0,10]   (10,15]   (15,20]   (20,25]   (25,35] (35, Inf] 
#       93       106       101       112        58        45        25 

#----- OUTCOME: c.neti.bis in 4 modalities in data4
table(data4$c.neti.bis)
#   1   2   3   4 
# 149 119  75  17 


summary(data3)
# area5       urb          hsize        hsize5         age             c.age       sex         marital           c.neti   
# NE  :124   1   :180   Min.   :1.000   1   : 86   Min.   :17.00   [16,34] :107   1   :274   Min.   :1.000   (15,20] :112  
# NO  :114   2   :230   1st Qu.:2.000   2   :234   1st Qu.:37.75   (34,44] : 92   2   :266   1st Qu.:1.000   (0,10]  :106  
# C   :127   3   :130   Median :2.000   3   :127   Median :52.00   (44,54] :108   NA's: 60   Median :2.000   (10,15] :101  
# S   :117   NA's: 60   Mean   :2.522   4   : 73   Mean   :51.96   (54,64] : 84              Mean   :1.874   (-Inf,0]: 93  
# I   : 58              3rd Qu.:3.000   >=5 : 20   3rd Qu.:67.00   (64,104]:149              3rd Qu.:2.000   (20,25] : 58  
# NA's: 60              Max.   :9.000   NA's: 60   Max.   :89.00   NA's    : 60              Max.   :3.000   (Other) : 70  
#                       NA's   :60                 NA's   :60                                NA's   :60      NA's    : 60   


summary(data4)
#   hsize5         age             c.age      sex      marital         edu7        n.income           ww         c.neti.bis
# 1   : 45   Min.   :17.00   [16,34] :87   1   :156   1   :109   2      :123   Min.   :-9000   Min.   : 147.1   1   :149  
# 2   :159   1st Qu.:34.75   (34,44] :67   2   :204   2   :211   3      :122   1st Qu.: 2413   1st Qu.: 700.2   2   :119  
# 3   : 85   Median :46.00   (44,54] :70   NA's: 40   3   : 40   1      : 60   Median :11575   Median :1379.2   3   : 75  
# 4   : 53   Mean   :48.68   (54,64] :48              NA's: 40   5      : 37   Mean   :13258   Mean   :1685.3   4   : 17  
# >=5 : 18   3rd Qu.:63.00   (64,104]:88                         4      :  9   3rd Qu.:20168   3rd Qu.:2360.4   NA's: 40  
# NA's: 40   Max.   :96.00   NA's    :40                         (Other):  9   Max.   :80000   Max.   :6789.7             
#            NA's   :40                                          NA's   : 40   NA's   :40      NA's   :40               



# II. Detect possible problems between covariates in each databases
#-------------------------------------------------------------------

# Ability to detect risks of colinearity between variables
library(car)
library(nnet)
library(ordinal)
sel_cov3 = select_var(data3,Y = "c.neti",type_Y = "ORD",threshX = 0.90,threshY = 0.90,thresh_vif = 10); sel_cov3
# $Y
#[1] "c.neti"
#
# $cor_Y
# named numeric(0)
#
# $VIF_PB
#   hsize5    hsize      age    c.age 
# 45.14604 44.76794 15.99125 15.34881 
#
# $KEEP_COV
# [1] "sex"   "c.age" "hsize"
# 
# $DEL_COV
# [1] "hsize5" "age"   
#
# $PVAL_Y
#    NAME         pval       CORREC
# 7   sex 1.067533e-17 8.540261e-17
# 6 c.age 8.584784e-09 6.867827e-08
# 3 hsize 5.452895e-05 4.362316e-04

sel_cov4 = select_var(data4,Y = "c.neti.bis",type_Y = "ORD",threshX = 0.90,threshY = 0.90,thresh_vif = 10); sel_cov4
# select_var function in progress. Please wait ... 
# $Y
# [1] "c.neti.bis"
#
# $cor_Y
# n.income 
# 0.946 
# 
# $VIF_PB
# named numeric(0)
#
# $KEEP_COV
# [1] "sex"   "c.age"
#
# $DEL_COV
# [1] "n.income"

# $PVAL_Y
#    NAME        pval      CORREC
# 4   sex 0.001008028 0.007056193
# 3 c.age 0.001901266 0.013308862

#--> The ouputs of the select_var() function for data3 and data4 suggests that the variables "sex" and "c.age" are good candidates
#    for the data fusion
#--> In data4, the variable "n.income" should be exclude of the analysis because of its too strong association with the outcome.
#--> In data3, there is a risk of multicolinearity between the covariates "hsize5" and "hsize" and between "age" and "c.age".
#    The function suggests to keep first the variables "c.age" and "sex" for the data fusion.
#--> In data4, the variable n.income seems too close to the outcome of interest. The question about its maintenance for the rest of the study should be worth asked.
#--> We notice that the covariates "c.age" and "sex" explain the outcomes similarly in the two databases.


# Based on the previous results, we decide  to remove the covariate "age" from data3:
data3 = data3[,setdiff(colnames(data3),"age")]; names(data3)
#[1] "area5"   "urb"     "hsize"   "hsize5"  "c.age"   "sex"     "marital" "c.neti" 


# ... We also remove the covariate "n.income" and "age" from data4:
data4 = data4[,setdiff(colnames(data4),c("n.income","age"))]; names(data4)
#[1] "hsize5"     "c.age"      "sex"        "marital"    "edu7"       "ww"         "c.neti.bis"



# III. Prepare database for OT algorithm with the remaining covariates
#---------------------------------------------------------------------

# Using the mergedbs() function (requires the function "compare_lists","transfo_targets",and "imput_cov")
# Handle missing data by multiple imputation (MICE)
# Stores all the information in a single database

library(mice); library(plyr); library(missMDA)

db_test  = merge_dbs(data3,data4,NAME_Y1 = "c.neti",NAME_Y2 = "c.neti.bis",ordinal_DB1 = c(2,4,5,8), ordinal_DB2 = c(1,2,7), impute = "MICE",R_MICE = 3, seed_func = 4036)
# DBS MERGING in progress. Please wait ... 
# Y1 
# Y2 
# DBS MERGING OK 
# -----------------------
# SUMMARY OF DBS MERGING: 
# Nb of removed subjects because of NA on Y: 100 ( 10 %) 
# Nb of removed covariates because of their different types: 1 
# Nb of remained covariates: 3 
# More details in output ... 

summary(db_test)
#           Length Class      Mode     
# DB_READY       6      data.frame list     
# Y1_LEVELS      7      -none-     character
# Y2_LEVELS      4      -none-     character
# REMOVE1        1      -none-     character
# REMOVE2        0      -none-     NULL     
# REMAINING_VAR  3      -none-     character
# IMPUTE_TYPE    1      -none-     character
# MICE_DETAILS   2      -none-     list     
# DB1_RAW        8      data.frame list     
# DB2_RAW        7      data.frame list     
# SEED           1      -none-     numeric  

summary(db_test$DB_READY)
# DB             Y1         Y2           c.age     hsize5    sex    
# Min.   :1.0   (15,20] :112   1   :149   [16,34] :193   1  :123   1:429  
# 1st Qu.:1.0   (0,10]  :106   2   :119   (34,44] :172   2  :385   2:471  
# Median :1.0   (10,15] :101   3   : 75   (44,54] :180   3  :219          
# Mean   :1.4   (-Inf,0]: 93   4   : 17   (54,64] :124   4  :130          
# 3rd Qu.:2.0   (20,25] : 58   NA's:540   (64,104]:231   >=5: 43          
# Max.   :2.0   (Other) : 70                                              
#               NA's    :360    



# IV. OT application on the remaining dataset
#--------------------------------------------

# The OT function requires the prior execution of: "inst","average_from_group_closest"

library(rdist) 
library(dplyr); library(ROI); library(ROI.plugin.glpk)
library(ompr); library(ompr.roi)


#----------------------------------------------------------------------------------------------------------
# The OT function: Implementation of the optimal transportation algorithm for data integration
#                  with or without relaxation of the constraints on marginal (OUTCOME and R-OUTCOME models)
#----------------------------------------------------------------------------------------------------------

# This function require the functions:
# --> "instance", 
# --> "average_distance_to_closest": Compute the cost between pairs of outcomes as the average distance between
#     covariations of individuals with these outcomes, but considering only the percent closest neighbors.
# --> "individual_from_group_closest" (indiv_method option = "sequential"): Sequentially assign the modality of the individuals
#     to that of the closest neighbor in the other base until the joint probability values are met.
# --> "individual_from_group_optimal" (indiv_method option = "optimal"): Solve an optimization problem to get the individual
#     transport that minimizes total distance while satisfying the joint probability computed by the model by group.


# ARGUMENTS:

# percent_c   : Percent of closest neighbors taken in the computation of the costs
# maxrelax    : Maximum percentage of deviation from expected probability masses (0 for the OUTCOME model, different for 0 for the R-OUTCOME model. 
#               Please consult the corresponding article) for more details.
# norm        : Distance chosen for calculate the distances between categorical covariates.Equal to O (by default) for the Manhattan distance,
#               equal to 1 for the Euclidean distance or equal to 2 for the Hammind distance.
# indiv_method: Specifies the method used to get individual transport from group joint probabilities ("sequential" or "optimal"). Please consult the
#               corresponding article for more details 
# full_disp   : If true, write the transported value of each individual;
#               otherwise, juste write the number of missed transports
# solver_disp : If false, do not display the outputs of the solver


# OUTPUTS:

# TIME_EXE   : running time of the function
# TRANSPORT_A: Cost matrix corresponding to an estimation (i.e gamma) to the joint distribution of (YA,ZA)
# TRANSPORT_B: Cost matrix corresponding to an estimation (i.e gamma) to the joint distribution of (YB,ZB)
# estimatorZA: Estimators for the distributions of Z conditional to X and Y in base A 
# estimatorYB: Estimators for the distributions of Y conditional to X and Z in base B
# DATA1_OT   : 1st database (A here) with individual OT prediction for "c.neti.bis"
# DATA2_OT   : 2nd database (B here) with individual OT prediction for "c.neti"
#---------------


# Demo of an OUTCOME model (standard OT algorithm)
#-------------------------------------------------

try4      = OT(db_test$DB_READY, percent_c = 1, maxrelax = 0, norm = 1, indiv_method="sequential", full_disp = FALSE, solver_disp = FALSE)
summary(try4)
#          Length    Class      Mode   
# TIME_EXE       1   difftime   numeric
# TRANSPORT_A   28   -none-     numeric
# TRANSPORT_B   28   -none-     numeric
# estimatorZA 1372   -none-     numeric
# estimatorYB 1372   -none-     numeric
# DATA1_OT       7   data.frame list   
# DATA2_OT       7   data.frame list   

TRANSPORT_A = try4$TRANSPORT_A
row.names(TRANSPORT_A) = levels(db_test$DB_READY[,2])
colnames(TRANSPORT_A)  = levels(db_test$DB_READY[,3]); TRANSPORT_A
#                    1         2          3            4
# (-Inf,0]  0.17222222 0.0000000 0.00000000 0.0000000000
# (0,10]    0.19629630 0.0000000 0.00000000 0.0000000000
# (10,15]   0.04537037 0.1416667 0.00000000 0.0000000000
# (15,20]   0.00000000 0.1888889 0.01851852 0.0000000000
# (20,25]   0.00000000 0.0000000 0.10740741 0.0000000000
# (25,35]   0.00000000 0.0000000 0.08240741 0.0009259259
# (35, Inf] 0.00000000 0.0000000 0.00000000 0.0462962963

# The prediction provided with OT corresponds to the "OTpred" variable of the two datasets DATA1_OT and DATA2_OT

head(try4$DATA1_OT)
#       DB       Y1   Y2    c.age hsize5 sex OTpred
# 21384  1   (0,10] <NA> (64,104]      1   2      1
# 35973  1  (10,15] <NA> (64,104]      2   1      2
# 11774  1  (15,20] <NA>  (44,54]      1   1      2
# 32127  1  (10,15] <NA> (64,104]      2   1      2
# 6301   1 (-Inf,0] <NA>  [16,34]      4   1      1
# 12990  1 (-Inf,0] <NA>  [16,34]      2   2      1


head(try4$DATA2_OT)
#       DB   Y1 Y2    c.age hsize5 sex   OTpred
# 33372  2 <NA>  2 (64,104]      2   1  (10,15]
# 36437  2 <NA>  1  [16,34]      2   2 (-Inf,0]
# 3211   2 <NA>  2  (44,54]      2   1  (10,15]
# 21109  2 <NA>  1  [16,34]      3   2 (-Inf,0]
# 8474   2 <NA>  3  (44,54]      1   2  (20,25]
# 16376  2 <NA>  3 (64,104]      2   1  (20,25]



#----------------------------------------------------------------------------------------------------------
# The OT_joint function: Model where we directly compute the distribution of the outcomes for each individual or for sets of indviduals 
# that similar values of covariates
#----------------------------------------------------------------------------------------------------------

# ARGUMENTS

# aggregate_tol : Quantify how much individuals'covariates must be close for aggregation
# norm          : 1 or 2 for entropy depending on the type of regularization chosen (see article for more details)
# percent_clos  : Percent of closest neighbors taken into consideration in regularization
# lambda_reg    : Coefficient measuring the importance of the regularization term (corresponds toR-JOINT model for a value other than 0)
# full_disp     : A boolean. If TRUE, write the transported value of each individual; otherwise, juste write the number of missed transports
# solver_disp   : A boolean. If FALSE, do not display the outputs of the solver


# OUTPUTS

# TIME_EXE      : Running time of the function
# GAMMA_A       : Cost matrix corresponding to an estimation (i.e gamma) to the joint distribution of (YA,ZA) 
# GAMMA_B       : Cost matrix corresponding to an estimation (i.e gamma) to the joint distribution of (YB,ZB)
# estimatorZA   : Estimators for the distributions of Z conditional to X and Y in base A 
# estimatorYB   : Estimators for the distributions of Y conditional to X and Z in base B
# DATA1_OT      : 1st database (A here) with individual OT prediction for "c.neti.bis"
# DATA2_OT      : 2nd database (B here) with individual OT prediction for "c.neti"
#-----------

# A demo
try5 = OT_joint(db_test$DB_READY,maxrelax = 0.0, lambda_reg = 0.0, percent_clos = 0.2, norm = 1, aggregate_tol = 0.5, full_disp = FALSE, solver_disp = FALSE)
#--------------------------------------- 
#  AGGREGATE INDIVIDUALS WRT COVARIATES 
#  Reg. weight           =   0 
#  Percent closest       =  20 % 
#  Aggregation tolerance =  0.5 
--------------------------------------- 
  
  summary(try5)
# Length Class      Mode   
# TIME_EXE       1   difftime   numeric
# GAMMA_A       28   -none-     numeric
# GAMMA_B       28   -none-     numeric
# estimatorZA 1372   -none-     numeric
# estimatorYB 1372   -none-     numeric
# DATA1_OT       7   data.frame list   
# DATA2_OT       7   data.frame list  




# V. ASSESS THE PROXIMITY BETWEEN c.neti and c.neti.bis (predicted) BY GROUPING THE MODALITIES OF c.neti 
#-------------------------------------------------------------------------------------------------------

# The function error_group() requires the prior execution of the following functions: 
# family_part(), count_pos(); find_coord(), and try_group()

# Suppose that Y and Z are 2 categorical variables (ordered or not) where the number of levels of Y i bigger than the number of levels of Z
# The error_group() function researches the optimal grouping of modalities of Y to approach at best the distribution of Z to
# give an assessment of the proximity between the two encodings

# Demo on database A only:

cc= error_group(Ypred,try4$DATA1_OT$Y1,ord=TRUE)
#                                                        combi error_rate
# 1  (-Inf,0] (0,10]/(10,15] (15,20]/(20,25] (25,35]/(35, Inf]        7.6
# 2  (-Inf,0] (0,10]/(10,15] (15,20]/(20,25]/(25,35] (35, Inf]       15.6
# 3  (-Inf,0] (0,10] (10,15]/(15,20]/(20,25] (25,35]/(35, Inf]       17.4
# 4  (-Inf,0] (0,10]/(10,15] (15,20] (20,25]/(25,35]/(35, Inf]       17.8
# 5  (-Inf,0] (0,10]/(10,15]/(15,20] (20,25] (25,35]/(35, Inf]       24.8
# 6  (-Inf,0] (0,10] (10,15]/(15,20]/(20,25]/(25,35] (35, Inf]       25.4
# 7  (-Inf,0]/(0,10] (10,15] (15,20]/(20,25] (25,35]/(35, Inf]       27.2
# 8  (-Inf,0] (0,10] (10,15]/(15,20] (20,25]/(25,35]/(35, Inf]       27.6
# 9  (-Inf,0] (0,10]/(10,15]/(15,20] (20,25]/(25,35] (35, Inf]       32.8
# 10 (-Inf,0]/(0,10] (10,15] (15,20]/(20,25]/(25,35] (35, Inf]       35.2
# 11 (-Inf,0]/(0,10] (10,15] (15,20] (20,25]/(25,35]/(35, Inf]       37.4
# 12 (-Inf,0] (0,10]/(10,15]/(15,20]/(20,25] (25,35] (35, Inf]       43.1
# 13 (-Inf,0]/(0,10] (10,15]/(15,20] (20,25] (25,35]/(35, Inf]       44.4
# 14 (-Inf,0] (0,10] (10,15] (15,20]/(20,25]/(25,35]/(35, Inf]       46.3
# 15 (-Inf,0]/(0,10] (10,15]/(15,20] (20,25]/(25,35] (35, Inf]       52.4
# 16 (-Inf,0]/(0,10]/(10,15] (15,20] (20,25] (25,35]/(35, Inf]       58.7
# 17 (-Inf,0]/(0,10] (10,15]/(15,20]/(20,25] (25,35] (35, Inf]       62.8
# 18 (-Inf,0]/(0,10]/(10,15] (15,20] (20,25]/(25,35] (35, Inf]       66.7
# 19 (-Inf,0]/(0,10]/(10,15] (15,20]/(20,25] (25,35] (35, Inf]       77.0
# 20 (-Inf,0]/(0,10]/(10,15]/(15,20] (20,25] (25,35] (35, Inf]       78.7

#--> On database A, by grouping the modalities of the c.neti variable (7 levels) like 1 (best grouping) in 4 modalities (number of modalities of c.neti.bis)
#    the dissimilarity rate between the 2 variables is less than 8%.








