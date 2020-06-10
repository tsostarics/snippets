#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
NumericMatrix add_halves(NumericMatrix mat, bool upper = true){
  int l = mat.nrow();
  if(upper){
    for(int i=0; i<l-1; i++){
      for(int j=i+1; j<l; j++){
        mat(i,j) = mat(i,j) + mat(j,i);
        mat(j,i) = 0;
      }
    }
  }
  else{
  for(int j=0; j<l-1; j++){
      for(int i=j+1; i<l; i++){
        mat(i,j) = mat(i,j) + mat(j,i);
        mat(j,i) = 0;
      }
    }
  }
  return mat;
}