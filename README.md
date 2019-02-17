「AIによる成田空港の霧予測実験」
様々な機械学習アルゴリズムを駆使して、成田空港における霧の発生予測にチャレンジしました（2018）
データミックス社「データサイエンティスト育成講座」卒業課題として取り組みました

Pre-process.ipynb : 気象データの前処理  
Random_Forest_CLF.ipynb : Random Forestによる霧予測実験  
Deep_Learning_CLF_CAT4.ipynb : Deep Neural Networkによる霧予測実験  
LSTM_Keras_3hr.ipynb : 観測データのみを使ったLSTMによる霧の短時間予測  
Glmnet_Binomial.R : Elastic Netによる霧予測実験  
まとめ資料：https://www.slideshare.net/YoshikiKato2/aifog-forecast-by-machine-learning-106230220

2019年の航空気象研究会での発表に際し、Ver.2としての追加を行った  
UnderSampling_Bagging_CLF.ipynb : Under Sampling & Baggingによる予測実験（霧は極度の不均衡データ）  
DNN_CLF_LearningRate1.ipynb : AdamのLearning Rateを小さくすることで、精度向上に成功（class_weightも調整）  
DNN_CLF_Interpretation.ipynb : DNNの内部を解釈する試み  
発表スライド：https://www.slideshare.net/YoshikiKato2/ai-131126419
