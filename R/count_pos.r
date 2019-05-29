
#' count_pos()
#'
#' A function that counts the cardinals of possible subgroups from a set
#'
#' @param n An integer. The cardinal of a set
#' @param n_grp An integer. The number of desired subsets to compose the initial set
#'
#' @return A list of possible cardinals to compose the initial sets with n_groups
#' @export
#'
#' @examples
#' a1 = count_pos(5,2); a1
#'
count_pos = function(n,n_grp){

  max_grp = n - (n_grp - 1)

  BDD2 = rep(rep(1:max_grp,each = max_grp^(n_grp-1)),max_grp^0)

  if (n_grp > 1){

    for (k in 1:(n_grp-1)){
      BDD2 = cbind(BDD2,rep(rep(1:max_grp,each=max_grp^(n_grp-1-k)),max_grp^k))

    }

    recup = list()
    for (i in 1:nrow(BDD2)){

      recup[[i]] = as.vector(BDD2[i,])

    }

    recup2 = unique(lapply(recup,sort))
    indic  = sapply(recup2,sum)
    recup3 = recup2[indic == n]

  } else {

    recup3 =  BDD2[BDD2 == n]

  }

  return(recup3)

}

#--------------------------
# Example
a1 = count_pos(5,2); a1
#--------------------------