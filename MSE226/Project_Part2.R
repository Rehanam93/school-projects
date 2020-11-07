#### MS&E 226: Project Part 2 ####
### Ankita Banerjea & Rehana Mohammed ###

# Loading required packages
library(knitr)
library(tidyverse)
library(plyr)
library(dplyr)
library(cvTools)
library(data.table)
library(GGally)
library(ggplot2)
library(glmnet)
library(corrplot)
library(RColorBrewer)
library(wesanderson)
library(glmnet)
library(broom)
library(pROC)
library(ROCR)
library(caret)
library(arm)
library(plotmo)

# Loading dataset - edit path
college_dist <- read.csv("/Users/ankitabanerjea/Downloads/CollegeDistance.csv")

# Setting aside holdout set (20% of 4739 ~ 948)
set.seed(134)
M <- 948 
in.test <- sample(nrow(college_dist), size = M)
test <- college_dist[in.test,]
train <- college_dist[-in.test,]

#### 1/ Prediction on test set ####

### Regression ###

# Lasso with log(distance) - all covariates included.

# set y and x matrix
y_train = train$education
train$distance <- (train$distance + 0.5)
train$distance <- log(train$distance)
x_train = train %>%
  dplyr::select(-"education") %>%
  data.matrix()

# find best lambda using cv
lambda = cv.glmnet(x_train, y_train, alpha = 1, seed = 1)
best_lambda = lambda$lambda.min

# fit model with best lambda and estimate CV error
model_reg_lasso = glmnet(x_train, y_train, alpha = 1, lambda = best_lambda, standardize = TRUE)
reg_lasso_predictions = predict(model_reg_lasso, s = best_lambda, newx = x_train)

# estimate RMSE on train set
reg_lasso_RMSE = sqrt(mean((train$education - reg_lasso_predictions) ^ 2)) # 1.532

# estimate RMSE on test set
x_test <- test %>%
  dplyr::select(-"education") %>%
  data.matrix()
pred_test = predict(model_reg_lasso, s = best_lambda, newx = x_test)

reg_test_RMSE <- sqrt(mean((test$education - pred_test) ^ 2)) # 1.522

### Classification ###

# Penalized logistic regression - LASSO with log(distance)

train <- train %>%
  mutate(educ_bin = ifelse(education > 12, 1, 0))

test <- test %>%
  mutate(educ_bin = ifelse(education > 12, 1, 0))

x <- train %>%
  dplyr::select(-c("educ_bin", "education")) %>%
  data.matrix()
y <- train$educ_bin

lambdas <- 10^seq(2, -3, by = -.1)

# get optimal lambda
lasso = cv.glmnet(x, y, alpha = 1, type.measure = "class", family = "binomial", lambda = lambdas)
min.lambda = lasso$lambda.min

model_class_lasso = glmnet(x, y, alpha = 1, lambda = min.lambda, type.measure = "auc")
class_lasso_predictions = predict(model_class_lasso, s = min.lambda, newx = x)

# estimate RMSE on train set
class_lasso_RMSE <- sqrt(mean((train$educ_bin - class_lasso_predictions)^2)) # 0.437

# estimate RMSE on test set

x.test <- test %>%
  dplyr::select(-c("educ_bin", "education")) %>%
  data.matrix()

pred.test = predict(model_class_lasso, s = min.lambda, newx = x.test)

class_test_RMSE <- sqrt(mean((test$educ_bin - pred.test) ^ 2)) # 0.434

#### 2/ Inference -- proceeding with the best regression model ####

summary(model_reg_lasso) # not interpretable - maybe use one of the initial models we ran without lasso?













