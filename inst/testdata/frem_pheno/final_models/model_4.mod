;; 1. Based on: 5
$PROBLEM    PHENOBARB SIMPLE MODEL
$INPUT      ID DV MDV OPRED D_EPS1 TIME AMT WGT APGR D_ETA1 D_ETA2
            OETA1 OETA2 D_EPSETA1_1 D_EPSETA1_2 FREMTYPE
$DATA      ../frem_dataset.dta IGNORE=@
$PRED BASE1=D_ETA1*(ETA(1)-OETA1)
BASE2=D_ETA2*(ETA(2)-OETA2)
BSUM1=BASE1+BASE2
BASE_TERMS=BSUM1
IPRED=OPRED+BASE_TERMS
ERR1=EPS(1)*(D_EPS1+D_EPSETA1_1*(ETA(1)-OETA1))
ERR2=EPS(1)*(D_EPSETA1_2*(ETA(2)-OETA2))
ESUM1=ERR1+ERR2
ERROR_TERMS=ESUM1
Y=IPRED+ERROR_TERMS
;;;FREM CODE BEGIN COMPACT
;;;DO NOT MODIFY
     SDC3 = 0.704564727537
     SDC4 = 2.23763568135
     IF (FREMTYPE.EQ.100) THEN
;       WGT  0.704564727537
        Y = THETA(1) + ETA(3)*SDC3 + EPS(2)
        IPRED = THETA(1) + ETA(3)*SDC3
     END IF
     IF (FREMTYPE.EQ.200) THEN
;       APGR  2.23763568135
        Y = THETA(2) + ETA(4)*SDC4 + EPS(2)
        IPRED = THETA(2) + ETA(4)*SDC4
     END IF
;;;FREM CODE END COMPACT
D_EPSETA1_1_ = 0
D_EPSETA1_2_ = 0
D_EPSETA1_3_ = 0
D_EPSETA1_4_ = 0
D_EPSETA2_1_ = 0
D_EPSETA2_2_ = 0
D_EPSETA2_3_ = 0
D_EPSETA2_4_ = 0
"LAST
"D_EPSETA1_1_=H(1,2)
"D_EPSETA1_2_=H(1,3)
"D_EPSETA1_3_=H(1,4)
"D_EPSETA1_4_=H(1,5)
"D_EPSETA2_1_=H(2,2)
"D_EPSETA2_2_=H(2,3)
"D_EPSETA2_3_=H(2,4)
"D_EPSETA2_4_=H(2,5)
$THETA  1.52542372881 FIX ; TV_WGT
 6.42372881356 FIX ; TV_APGR
$OMEGA  BLOCK(4)
 0.0285719
 0.000282305104644 0.0278932
 0.025270419819 -0.0014941409308 1  ;    BSV_WGT
 -0.0667752841179 0.023293667081 0.244579616563 1  ;   BSV_APGR
$SIGMA  0.013129
$SIGMA  1E-07  FIX  ;     EPSCOV
$ETAS       FILE=model_4_input.phi
$ESTIMATION MCETA=1 METHOD=COND INTERACTION MAXEVALS=9999999 SLOW
            PRINT=1 NONINFETA=1
$COVARIANCE UNCONDITIONAL
$TABLE      H011 H021 G011 G021 G031 G041 D_EPSETA1_1_ D_EPSETA1_2_
            D_EPSETA1_3_ D_EPSETA1_4_ D_EPSETA2_1_ D_EPSETA2_2_
            D_EPSETA2_3_ D_EPSETA2_4_ ID FREMTYPE NOPRINT NOAPPEND
            ONEHEADER FILE=derivatives.tab FORMAT=s1PE15.8

