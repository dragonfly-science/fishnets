#' A base object for a node in a Fishnet
#' 
#' @author Nokome Bentley
Node <- function(){
  self <- object('Node')
  
  #' Fit the node
  #' 
  #' This default is provided for nodes that do not need to do
  #' any fitting (e.g. those that use pre-calculated lookup tables).
  #' Other nodes will need to override this.
  self$fit <- function(data){
  }
  
  #' Tune parameters of the node
  #' 
  #' Each type of network node will normally have "hyper-parameters" that can be tuned. e.g. in a GLM
  #' which predictor variables are included. This is a 'virtual' method for tuning and should be overidden by 
  #' node implementations.
  self$tune <- function(){
    stop('Not implemented. The tune() method should be overridden by objects that extend Node.')
  }
  
  #' Cross validation of a node
  #' 
  #' @param data The data.frame to cross validate against
  #' @param folds Number of folds (number of times that data is split into training and testing datasets)
  #' @param fit Function for fitting model. Should return an object with a "predict" method.
  #' @param ... Other arguments to fit function
  self$cross <- function(data,folds,jacknife=FALSE,...){
    # Begin by removing all data rows with NAs for variable of interest
    data <- model.frame(paste(self$predictand,'~',paste(self$predictors,collapse='+')),data) 
    # data = data[!is.na(data[,self$predictand]),]
    # if we want a jacknife then folds should be equal to number of data rows
    if(missing(folds)) {
      if(jacknife) folds <- nrow(data) else folds <- 10
      message('folds:',folds,'\n')
    } else { 
      if(folds>nrow(data)) {
        folds <- nrow(data)
        message('folds:',folds,'\n')
      }
    }
    
    # Randomly assign rows of data to a fold
    # Do this in a way that divides the data as evenly as possible..
    # Systematically assign folder number to give very close to even numbers in each fold...
    folder = rep(1:folds,length.out=nrow(data))
    # Randomly rearrange
    folder = sample(folder)
    # Result data.frame
    results = NULL
    # For each fold...
    for(fold in 1:folds){
      #cat("Fold",fold,": ")
      # Define training a testing datasets
      train = data[folder!=fold,]
      test = data[folder==fold,]
      # Fit model to training data
      self$fit(train,...)
      #cat(self$brt$gbm.call$predictor.names,'\n')
      # Get predictions for testing data
      preds = self$predict(test)
      # Get the dependent variable
      tests = test[,self$predictand]
      # Calculate various prediction errors
      me = mean(abs(tests-preds),na.rm=T)
      mse = mean((tests-preds)^2,na.rm=T)
      mpe = mean(abs((tests-preds)/tests),na.rm=T)
      r2 = cor(tests,preds,use="pairwise.complete.obs")^2
      dev = mean((tests - preds) * (tests - preds),na.rm=T)
      # Add to results
      results = rbind(results,data.frame(
        fold = fold,
        obs = mean(tests,na.rm=T),
        hat = mean(preds,na.rm=T),
        me = me,
        mse = mse,
        mpe = mpe,
        r2 = r2,
        dev = dev
      ))
      #cat(mpe,r2,"\n")
    }
    # Summarise results
    summary <- data.frame(mean=apply(results[,4:8],2,mean,na.rm=T),se=apply(results[,4:8],2,function(x) {y <- x[!is.na(x)]; sd(y)/sqrt(length(y))}))
    # Return summary and raw results
    return (list(
      summary = summary,
      folds = results
    ))
  }
  
  self$expand <- function(data,samples=NULL){
    data <- as.data.frame(data)
    if(!is.null(samples)) return(data[rep(1:nrow(data),samples),])
    else return(data)
  }
   
  self
}
