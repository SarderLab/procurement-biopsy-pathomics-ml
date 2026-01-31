# Author: Jeremy Rubin
# Date: 01/30/26
# Code to get internal validation metrics for models predicting 1-year eGFR 

set.seed(382025)

### Script to help with machine learning model cross-validation
source("Helper_CV_Functions.R")
source("Create_Train_Test_Exclusion_Data.R")

library(pROC)
library(glmnet)
library(randomForest)
library(dplyr)
library(mRMRe)
library(stringr)
library(caret)

# Number of bootstraps for internal validation procedure
nboot <- 100

## Number of top MRMR-ranked features you want to select for machine learning model fitting
num.MRMR.features <- 1

### Outcome is a character string "B" for Delayed Graft Function or 
### "C" for 1-year eGFR outcome
outcome <- "B"

### Whether or not you want to make a train/test split 
make.split <- T

## Name of file containing features and outcome
input.file.name <- "Renal_Data.csv"

## Name of files containing training subject and testing subject indices 
## If the training/testing split has been made already
train.sub.name <- "pathomic_graft_train_subjects.csv"
test.sub.name <- "pathomic_graft_test_subjects.csv"

## First entry is the number of top MRMR features you want
# Second entry is the name of the outcome variable, 
# Third entry is the number of training subjects and 
## Last five columns are performance metrics for each of the five models (four machine learning and one for KDPI)
results.vector <- rep(0,8)
results.vector[1] <- num.MRMR.features

## First entry is the number of top MRMR features you want
# Second entry is the name of the outcome variable, 
# Third entry is the number of training subjects and 
## Last five columns are performance metrics for each of the five models (four machine learning and one for KDPI)

results.vector[2] <- "DGF"

names(results.vector) <- c("Number of MRMR features","Outcome","Number of training subjects",
                            "Lasso","Ridge","Elastic net","Random forest","KDPI")
  
training_data_list <- generate_training_testing_exclusion_data(input.file.name,
                                             num.MRMR.features,outcome,
                                             train.sub.name,
                                             test.sub.name,
                                             make.split)

final_features <- training_data_list[[1]]
cur.outcome <- training_data_list[[2]]
KDPI <- training_data_list[[3]]

## Number of training subejcts
results.vector[3] <- length(cur.outcome)

## Grid of node sizes to search over for the random forest
nodesize.try <- seq(from=1,to=floor(sqrt(length(cur.outcome))),by=floor(log(length(cur.outcome))))

cur.outcome <- as.factor(cur.outcome)

###### Model training
### Code adapted to handle when you only have a single MRMR-selected feature vs. multiple MRMR-selected features  
### One vs multiple MRMR-selected features
if(is.vector(final_features) && !is.matrix(final_features) && !is.data.frame(final_features))
{
  training_data_matrix <- data.matrix(cbind(0,final_features))
} else{
  training_data_matrix <- data.matrix(final_features)
}
  
## Lasso model fit
lasso.mod <- cv.glmnet(x=training_data_matrix,
                       y=cur.outcome,
                       family="binomial",
                       type.measure = "auc",
                       alpha=1,
                       nfolds = 5)  
      
## Ridge regression model fit 
ridge.mod <- cv.glmnet(x=training_data_matrix,
                         y=cur.outcome,
                         family="binomial",
                         type.measure = "auc",
                         alpha=0,
                         nfolds = 5)
      
## Elastic net model fit 
enet.mod <- cv.glmnet(x=training_data_matrix,
                        y=cur.outcome,
                        family="binomial",
                        type.measure = "auc",
                        alpha=0.5,
                        nfolds = 5)

## Use cross-validation to pick nodesize that leads to greatest average C-statistic for the random forest
set.seed(382025)
rf.Cs <- sapply(nodesize.try, FUN=CV.avg.all.folds,
                      X.train=final_features,
                      Y.train=cur.outcome,
                      algorithm="rf",
                      outcome="binary")
    
nodesize.best <- nodesize.try[which(rf.Cs==max(rf.Cs))[1]]  
    
#### Saving optimal nodesize for predicting 1-year eGFR with random forest
write.csv(nodesize.best,file="nodesize_best_rf_DGF.csv")
    
############################# Get the baseline MSEs for each model trained and tested on the original data
# Case of one MRMR-selected feature
if(is.vector(final_features) && !is.matrix(final_features) && !is.data.frame(final_features))
{
  training_data_matrix <- as.matrix(cbind(0,final_features))
  train.df.baseline <- cbind(0,final_features)
  colnames(train.df.baseline) <- c("zero","X.train")
  
  
} else{
  training_data_matrix <- as.matrix(final_features)
  train.df.baseline <- final_features
}
      
## Lasso C-statistic
baseline_C_lasso <- assess.glmnet(lasso.mod,
                                  newx=training_data_matrix,
                                  newy=cur.outcome,
                                  family="binomial",
                                  s="lambda.min")[[3]][1]
## Ridge regression C-statistic
baseline_C_ridge <- 
  assess.glmnet(ridge.mod,
                newx=training_data_matrix,
                newy=cur.outcome,
                family="binomial",
                s="lambda.min")[[3]][1]
      
## Elastic net C-statistic
baseline_C_enet <- 
  assess.glmnet(enet.mod,
                newx=training_data_matrix,
                newy=cur.outcome,
                family="binomial",
                s="lambda.min")[[3]][1]
      
## Random forest C-statistic
rf.mod.baseline <- randomForest(
        x = train.df.baseline,  
        y = cur.outcome,                                              
        ntree = 500,
        nodesize=nodesize.best,
        keep.forest=TRUE,
        keep.inbag=TRUE
     )  

predictions.rf.baseline <- as.data.frame(unlist(predict(rf.mod.baseline,newdata=train.df.baseline,type="prob")))[,2]
baseline_C_rf <- auc(cur.outcome,predictions.rf.baseline)

## Baseline C-statistic using KDPI alone to directly assess AUC with no formal model fitting
baseline_C_KDPI <- auc(cur.outcome,KDPI)
    
## Concatenate all baseline C-statistics in one vector
baseline_Cs <- c(baseline_C_lasso,baseline_C_ridge,baseline_C_enet,baseline_C_rf,baseline_C_KDPI)
    
### Vectors to store MSEs for differnet components of internal validation-adjusted MSE 
boot_C_all_models <- matrix(0,nrow=nboot,ncol=5)
test_C_all_models <- matrix(0,nrow=nboot,ncol=5)
    
#### Saving predicted DGF probabilities from optimal random forest model for training cohort
write.csv(predictions.rf.baseline,file="training_DGF_prob.csv")

for(p in 1:nboot)
{
  ### Bootstrap sampling
  bootRows <- sort(sample(1:length(cur.outcome), size=length(cur.outcome), replace=T))
  Y.boot <- cur.outcome[bootRows]
  KDPI.boot <- KDPI[bootRows]
      
  ### Onevs multiple MRMR-selected features 
  if(is.vector(final_features) && !is.matrix(final_features) && !is.data.frame(final_features))
  {
    X.train.boot <- final_features[bootRows]
    
    ### Makes sure you don't get a degenerate bootstrap sample with identical rows
    while(var(X.train.boot)==0)
    {
      bootRows <- sort(sample(1:length(cur.outcome), size=length(cur.outcome), replace=T))
      Y.boot <- cur.outcome[bootRows]
      KDPI.boot <- KDPI[bootRows]
      X.train.boot <- final_features[bootRows]
    }
    
    training_matrix_boot <- data.matrix(cbind(0,X.train.boot))
    boot.matrix <- as.matrix(cbind(0,X.train.boot))
    boot.matrix.original <- as.matrix(cbind(0,final_features))
    
    train.df.boot <- cbind(0,X.train.boot)
    test.df.C <- cbind(0,final_features)
    
    colnames(train.df.boot) <- c("zero","X.train.boot")
    colnames(test.df.C) <- c("zero","final_features")
    
  } else{
    
    X.train.boot <- final_features[bootRows,]
    
    ### Makes sure you don't get a degenerate bootstrap sample with identical rows
    while(sum(apply(X.train.boot,MARGIN=2,var)==0) > 0)
    {
      bootRows <- sort(sample(1:length(cur.outcome), size=length(cur.outcome), replace=T))
      Y.boot <- cur.outcome[bootRows]
      KDPI.boot <- KDPI[bootRows]
      X.train.boot <- combined.df[bootRows,]
    }
    
    training_matrix_boot <- data.matrix(X.train.boot)
    boot.matrix <- as.matrix(X.train.boot)
    boot.matrix.original <- as.matrix(final_features)
    
    train.df.boot <- X.train.boot
    test.df.C <- final_features

    colnames(train.df.boot) <- colnames(X.train.boot)    
    colnames(test.df.C) <- colnames(final_features)

  }
  
  ### Bootstrap subject-trained lasso model
  lasso.mod.boot <- cv.glmnet(x=training_matrix_boot,
                              y=Y.boot,
                              family="binomial",
                              type.measure="auc",
                              alpha=1,
                              nfolds = 5)  
        
  ### Bootstrap subject-trained ridge regression model
  ridge.mod.boot <- cv.glmnet(x=training_matrix_boot,
                              y=Y.boot,
                              family="binomial",
                              type.measure="auc",
                              alpha=0,
                              nfolds = 5)
        
  ### Bootstrap subject-trained elastic net model 
  enet.mod.boot <- cv.glmnet(x=training_matrix_boot,
                             y=Y.boot,
                             family="binomial",
                             type.measure="auc",
                             alpha=0.5,
                             nfolds = 5)
        
  ## Use cross-validation to pick nodesize that leads to smallest average MSE
  ## for random forest using bootstrapped data
  rf.Cs.boot <- sapply(nodesize.try, FUN=CV.avg.all.folds,
                             X.train=X.train.boot,
                             Y.train=Y.boot,
                             algorithm="rf",
                             outcome="binary")
      
  nodesize.best.boot <- nodesize.try[which(rf.Cs.boot==max(rf.Cs.boot))[1]]
      
  ############################ Bootstrap trained models tested on bootstrapped data
  
  #### lasso
  boot_C_lasso <- 
    assess.glmnet(lasso.mod.boot,
                  newx=boot.matrix,
                  newy=Y.boot,
                  family="binomial",
                  s="lambda.min")[[3]][1]
  #### ridge
  boot_C_ridge <- 
    assess.glmnet(ridge.mod.boot,
                  newx=boot.matrix,
                  newy=Y.boot,
                  family="binomial",
                  s="lambda.min")[[3]][1]
        
  #### elastic net
  boot_C_enet <- 
    assess.glmnet(enet.mod.boot,
                  newx=boot.matrix,
                  newy=Y.boot,
                  family="binomial",
                  s="lambda.min")[[3]][1]
        
  ### random forest
  rf.mod.boot <- randomForest(
          x = train.df.boot,  
          y = Y.boot,                                              
          ntree = 500,
          nodesize=nodesize.best.boot,
          keep.forest=TRUE,
          keep.inbag=TRUE
        )  
        
  predictions.rf.boot <- as.data.frame(unlist(predict(rf.mod.boot,newdata=train.df.boot,type="prob")))[,2]
  boot_C_rf <- auc(Y.boot,predictions.rf.boot)
  
  ####### bootstrapped trained models tested on original data
  ### lasso
  test_C_lasso <- 
    assess.glmnet(lasso.mod.boot,
                  newx=boot.matrix.original,
                  newy=cur.outcome,
                  family="binomial",
                  s="lambda.min")[[3]][1]
        
  ### ridge regression
  test_C_ridge <- 
    assess.glmnet(ridge.mod.boot,
                  newx=boot.matrix.original,
                  newy=cur.outcome,
                  family="binomial",
                  s="lambda.min")[[3]][1]
        
  ### elastic net
  test_C_enet <- 
    assess.glmnet(enet.mod.boot,
                  newx=boot.matrix.original,
                  newy=cur.outcome,
                  family="binomial",
                  s="lambda.min")[[3]][1]
        
  ### random forest
  predictions.rf.test <- as.data.frame(unlist(predict(rf.mod.boot,newdata=test.df.C,type="prob")))[,2]
  test_C_rf <- auc(cur.outcome,predictions.rf.test)
        
  ### bootstrapped KDPI tested on bootstrapped data
  boot_C_KDPI <- auc(Y.boot,KDPI.boot)
      
  ### Save all C-statistic results from testing bootstrap models on bootstrap data 
  boot_C_all_models[p,] <- c(boot_C_lasso,boot_C_ridge,boot_C_enet,boot_C_rf,boot_C_KDPI) 
      
  ########## bootstrapped KDPI on original data
  test_C_KDPI <- auc(cur.outcome,KDPI.boot)
      
  ### Saving all C-statistic results from testing bootstrap models on original data
  test_C_all_models[p,] <- c(test_C_lasso,test_C_ridge,test_C_enet,test_C_rf,test_C_KDPI)
}
    
### Applying the internal validation formula to compute final MSEs for all methods 
results.vector[4:8] <- baseline_Cs - apply(FUN=median,MARGIN=2,boot_C_all_models - test_C_all_models)
  
write.csv(results.vector,file=paste0(num.MRMR.features,"_MRMR_features_training_C_results.csv"))
