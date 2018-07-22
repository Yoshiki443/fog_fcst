##############################
# glmnetでロジスティック回帰 #
##############################
#-データの取り込み
# ワーキングディレクトリはセットしておく
DATA<-read.csv("train_data.csv")
TEST<-read.csv("test_data.csv")

#-使う変数の絞り込み
use_valiable<-c("FG","PRCP_P24HR","RH_SFC","TMP_SFC","TD_SFC","PRES_SFC","LCDC_SFC","MCDC_SFC","HCDC_SFC",
                "WSPD_SFC","WDIR_SFC","APCP_SFC","TimeRange","MONTH","D_PRES_SFC","D_TMP_SFC","D_TD_SFC",
                "LL_VWS1","LL_VWS2","LL_STBL1","LL_STBL2","WARMER_RA",
                "RH_1000","VVEL_1000","WSPD_1000","RH_975","VVEL_975","WSPD_975",
                "RH_950","VVEL_950","WSPD_950","RH_850","RH_700","RH_500","RH_300")
DATA<-DATA[,use_valiable]
TEST<-TEST[,use_valiable]

#-カテゴリー変数
DATA$MONTH<-as.factor(DATA$MONTH)
TEST$MONTH<-as.factor(TEST$MONTH)

require(makedummies)
DATA<-makedummies(DATA)
TEST<-makedummies(TEST)

#-正規化（0-1）
rh_val<-c("RH_SFC", "RH_1000", "RH_975", "RH_950", "RH_850", "RH_700", "RH_500", "RH_300",
          "LCDC_SFC", "MCDC_SFC", "HCDC_SFC")
DATA[,rh_val]<-DATA[,rh_val]/100
TEST[,rh_val]<-TEST[,rh_val]/100

cont_val<-c("WSPD_SFC", "APCP_SFC", "D_PRES_SFC", "D_TMP_SFC", "D_TD_SFC", "LL_VWS1", "LL_VWS2",
            "LL_STBL1", "LL_STBL2", "WARMER_RA", "VVEL_1000", "WSPD_1000", "VVEL_975", "WSPD_975",
            "VVEL_950", "WSPD_950", "TMP_SFC", "TD_SFC", "PRES_SFC")
for(i in cont_val){
  a_min<-min(DATA[,i])
  a_max<-max(DATA[,i])
  DATA[,i]<-scale(DATA[,i], center = a_min, scale = (a_max - a_min))
  TEST[,i]<-scale(TEST[,i], center = a_min, scale = (a_max - a_min))
}

#-学習用とテスト用にデータを分ける
set.seed(443)
num_rows<-dim(DATA)[1]
idx<-c(1:num_rows)
train_idx<-sample(idx, size = num_rows*0.7 )
TRAIN<-DATA[train_idx, ]
DEV<-DATA[-train_idx, ]

### モデル作成 ###
#-alpha = 1 のLasso回帰
require(glmnet)
set.seed(443)

#elastic1 <- glmnet(as.matrix(TRAIN[,-1]), as.matrix(TRAIN[,1]), 
#                   family="binomial", alpha=0.3, lambda=1000, standardize=FALSE)
elastic1 <- cv.glmnet(as.matrix(TRAIN[,-1]), as.matrix(TRAIN[,1]), 
                      family="binomial", alpha=1, standardize=FALSE)
coef(elastic1)
round( exp( coef(elastic1) ), 3 )

#-精度検証
score_dev<-predict(elastic1, as.matrix(DEV[,-1]), type="response")

# 最適な閾値を探す
opt_threshold<-function(score,data){
  ets <- NULL
  cand<-seq(0, 1, 0.01)
  Pc<-length(data$FG[data$FG==1])/length(data$FG)
  for(i in 1: length(cand)){
    ypred_flag <- ifelse(score > cand[i], 1, 0)
    conf_mat <- table(data$FG, ypred_flag )
    Sf <- Pc * (conf_mat[3] + conf_mat[4])
    tmp_ets <- (conf_mat[4] - Sf) / (conf_mat[2] + conf_mat[3] + conf_mat[4] - Sf)
    ets <- c(ets, tmp_ets)
  }
  return(list(ETS = ets))
}

result <- opt_threshold(score_dev, DEV)
ETS_max <- max(result$ETS, na.rm = T)
max_idx <- which(result$ETS == ETS_max)
border <- seq(0,1,0.01)[max_idx]
y_fcst<-ifelse(score_dev > border, 1, 0)
conf_mat<-table(DEV$FG, y_fcst)
print( conf_mat )
sprintf("ETS : %s", ETS_max )
sprintf("BI : %s", (conf_mat[4]+conf_mat[3])/(conf_mat[4]+conf_mat[2]) )
sprintf("border : %s", border)

#-予測実験
score_test<-predict(elastic1, as.matrix(TEST[,-1]), type="response")
y_fcst<-ifelse(score_test > border, 1, 0)
conf_mat<-table(TEST$FG, y_fcst)

Pc <- length(TEST$FG[TEST$FG==1])/length(TEST$FG)
Sf <- Pc * (conf_mat[3] + conf_mat[4])
ETS <- (conf_mat[4] - Sf) / (conf_mat[2] + conf_mat[3] + conf_mat[4] - Sf)

print( conf_mat )
sprintf("ETS : %s", ETS )
sprintf("BI : %s", (conf_mat[4]+conf_mat[3])/(conf_mat[4]+conf_mat[2]) )


### モデル作成 ###
#-alpha = 0.2 のElasticNet
elastic2 <- cv.glmnet(as.matrix(TRAIN[,-1]), as.matrix(TRAIN[,1]), 
                      family="binomial", alpha=0.2, standardize=FALSE)
coef(elastic2)
round( exp( coef(elastic2) ), 3 )

#-精度検証
score_dev<-predict(elastic2, as.matrix(DEV[,-1]), type="response")

# 最適な閾値を探す
opt_threshold<-function(score,data){
  ets <- NULL
  cand<-seq(0, 1, 0.01)
  Pc<-length(data$FG[data$FG==1])/length(data$FG)
  for(i in 1: length(cand)){
    ypred_flag <- ifelse(score > cand[i], 1, 0)
    conf_mat <- table(data$FG, ypred_flag )
    Sf <- Pc * (conf_mat[3] + conf_mat[4])
    tmp_ets <- (conf_mat[4] - Sf) / (conf_mat[2] + conf_mat[3] + conf_mat[4] - Sf)
    ets <- c(ets, tmp_ets)
  }
  return(list(ETS = ets))
}

result <- opt_threshold(score_dev, DEV)
ETS_max <- max(result$ETS, na.rm = T)
max_idx <- which(result$ETS == ETS_max)
border <- seq(0,1,0.01)[max_idx]
y_fcst<-ifelse(score_dev > border, 1, 0)
conf_mat<-table(DEV$FG, y_fcst)
print( conf_mat )
sprintf("ETS : %s", ETS_max )
sprintf("BI : %s", (conf_mat[4]+conf_mat[3])/(conf_mat[4]+conf_mat[2]) )
sprintf("border : %s", border)

#-予測実験
score_test<-predict(elastic2, as.matrix(TEST[,-1]), type="response")
y_fcst<-ifelse(score_test > border, 1, 0)
conf_mat<-table(TEST$FG, y_fcst)

Pc <- length(TEST$FG[TEST$FG==1])/length(TEST$FG)
Sf <- Pc * (conf_mat[3] + conf_mat[4])
ETS <- (conf_mat[4] - Sf) / (conf_mat[2] + conf_mat[3] + conf_mat[4] - Sf)

print( conf_mat )
sprintf("ETS : %s", ETS )
sprintf("BI : %s", (conf_mat[4]+conf_mat[3])/(conf_mat[4]+conf_mat[2]) )

### モデル作成 ###
#-alpha = 0 のRidge回帰
# 精度悪化

### モデル保存 ###
saveRDS(elastic2, file="R_model/glmnet_elastic_0p2")

### モデル読み込み ###
elastic2 <- readRDS(file="R_model/glmnet_elastic_0p2")
score_dev<-predict(elastic2, as.matrix(DEV[,-1]), type="response")
score_test<-predict(elastic2, as.matrix(TEST[,-1]), type="response")

library(pROC)
roc_dev <- roc(DEV$FG, score_dev)
auc(roc_dev)
plot(roc_dev, lty=1, legacy.axes = TRUE)

roc_test <- roc(TEST$FG, score_test)
auc(roc_test)
plot(roc_test, lty=1, legacy.axes = TRUE)
