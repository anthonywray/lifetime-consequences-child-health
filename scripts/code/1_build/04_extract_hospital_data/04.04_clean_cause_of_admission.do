version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 04.04_clean_cause_of_admission.do
* PURPOSE: The do file cleans and standardizes the components of the original string variable containing the cause of admission to the hospital.
************

use dis_orig disinreg using "$PROJ_PATH/processed/intermediate/hospitals/hospital_admissions_combined.dta", clear
bysort dis_orig disinreg: keep if _n == 1
replace dis_orig = upper(dis_orig)
replace dis_orig = upper(disinreg) if dis_orig == "" | dis_orig == "UNKNOWN"
keep dis_orig
duplicates drop
bysort dis_orig: gen dis_count = _N
split dis_orig, parse(;) gen(disease)
gen id = _n
reshape long disease, i(id) j(new_id)
drop if disease == ""
drop id new_id
duplicates drop

replace disease = "SARCOMA EYELID" if dis_orig == "PIGMENTED SARCOMA OF EYELID"
replace disease = "HEAD LICE" if dis_orig == "LICE"
replace disease = "SEPARATION UPPER EPIPHYSIS LEFT COLLAR FRACTURE" if dis_orig == "?SEP. UPPER EPIPHPIS OF PHUMTERUS (L) COLLER TRACTURE (L)"
replace disease = "BURN MOUTH" if dis_orig == "DRANK OUT OF A KETTLE OF B. WATER" | dis_orig == "DRINK G. KETTLE"
replace disease = "BRIGHTS DISEASE" if dis_orig == "BRIGHT DO"
replace disease = "SIMPLE FRACTURE OF LEFT TIBIA" if dis_orig == "FRACTURE OF TIBIA (SIM L)"
replace disease = "PUBIC DISLOCATION LEFT HIP" if dis_orig == "DISLOCATION (L. LIP) (PUBIC)"
replace disease = "OLD TUBERCULAR SPINE MENINGITIS" if dis_orig == "OLD TUBERCULOUS SPINE & TUB. MENINGIIS"
replace disease = "HEMATURIA URINE RETENTION" if dis_orig == "HEMATURIA RUN & FREQUENCY OF MICTASTES"
replace disease = "PULMONARY TUBERCULOSIS" if dis_orig == "TUB. PULMONOSIS"
replace disease = "MITRAL STENOSIS REGURGITATION" if dis_orig == "MIT. ST. AND REG."
replace disease = "MAIN EN GRIFFE CLAWHAND" if dis_orig == "MAIN IN GRIFFE"
replace disease = "DROWNED IN RIVER" if dis_orig == "MERSUS IN FLUMINE"
replace disease = "INJURY TO LEG RIGHT" if dis_orig == "INJURY TO LY. (RT.)"
replace disease = "DISLOCATION LENS" if dis_orig == "DIS. LOCT. LENS"
replace disease = "INGROWN TOENAIL" if dis_orig == "ING. ??"
replace disease = "INFECTION GLANDS" if dis_orig == "INGS. GLANDS"
replace disease = "FOREIGN BODY IN IRIS" if dis_orig == "FOREIGN BODY IN INS."
replace disease = "INTERNAL INFLAMMATION FOLLOWING BLOW" if dis_orig == "INT. IN FLM. FOLLG. BLOW"
replace disease = "INTERNAL INJURIES FRACTURE CLAVICLE RIBS" if dis_orig == "INT. INJS. & FR. CLAS. & RIBS"
replace disease = "SPITTING BLOOD AFTER FALL" if dis_orig == "SPITTING BLOOD AFTER OF ALL"
replace disease = "OLD WOUND MEDIAN NERVE" if dis_orig == "OLD AD. MEDIAN NERVES"
replace disease = "ABDOMINAL INJURY" if dis_orig == "ADD. INJURIES"
replace disease = "REDUNDANT PREPUCE" if dis_orig == "ADDN. PREPUCE"
replace disease = "CORNEAL OPACITY" if dis_orig == "CORNEAL OF A CITY"
replace disease = "CHLOROFORM POISONING" if dis_orig == "CHLOR. OF POISONING"
replace disease = "SUB ACUTE RHEUMATISM MORBUS CORDIS" if dis_orig == "SUB AC. CHEMICL., MOR. COR."
replace disease = "SUPPURATION AURICLE" if dis_orig == "SUPERY. AURIDES"
replace disease = "MORBUS ABDOMINAL" if dis_orig == "MOR. ADDOM"
replace disease = "STRICTURE OF RECTUM" if dis_orig == "STS. OF RECTUM"
replace disease = "STRUMOUS FINGER" if dis_orig == "STIR FINGER"
replace disease = "STRUMOUS DACTYLITIS" if dis_orig == "SH. DACTYLITIS"
replace disease = "ABSCESS TEMPORAL MUSCLE" if dis_orig == "ABSCESS SEMP. MUSCLE"
replace disease = "INJURY TO HEAD" if dis_orig == "MY TO HEAD"
replace disease = "NECROSIS HUMERUS" if dis_orig == "NEUROSIS HUMANS"
replace disease = "COMPOUND COMMINUTED FRACTURE OF HUMERUS" if dis_orig == "COMP. CORN. FR. OF HUMERUS"
replace disease = "CONTRACTED BICEPS" if dis_orig == "CONTRACTED CREEPS"
replace disease = "INFECTION LUNGS" if dis_orig == "INFN. CUNPS??"
replace disease = "DEAF MUTE" if dis_orig == "DEAFINITE"	
replace disease = "ANASARCA POST FEBRIS RUBRUM" if dis_orig == "ANASARCA PEST FIBRAIN RUBRAM"
replace disease = "ACUTE RHEUMATISM MORBUS CORDIS" if dis_orig == "AC. RHEUM. ML."
replace disease = "" if dis_orig == "TO BE FITTED WITH BELT"
replace disease = "" if dis_orig == "NO DISEASE" | dis_orig == "NONE"

replace disease = regexr(disease,"FOR RED CURE","")
replace disease = regexr(disease,"3RD DEG","")
replace disease = regexr(disease," DEC 1902","")
replace disease = subinstr(disease,"."," ",.)
replace disease = subinstr(disease,"   "," ",.)
replace disease = subinstr(disease,"  "," ",.)
replace disease = subinstr(disease,"?","",.)
replace disease = subinstr(disease,";","",.)
replace disease = subinstr(disease,"*","",.)
replace disease = subinstr(disease,"+","",.)
replace disease = subinstr(disease,"(","",.)
replace disease = subinstr(disease,")","",.)
replace disease = subinstr(disease,","," ",.)
replace disease = subinstr(disease,":"," ",.)
replace disease = subinstr(disease,"'","",.)
replace disease = subinstr(disease,"-"," ",.)
replace disease = subinstr(disease,"/"," ",.)
replace disease = subinstr(disease,"  "," ",.)
replace disease = subinstr(disease," & C "," ",.)
replace disease = subinstr(disease," &C "," ",.)
replace disease = regexr(disease," &( )*C$","")
replace disease = subinstr(disease," & "," ",.)
replace disease = subinstr(disease,"&"," ",.)
replace disease = regexr(disease,"[ ]P[ ][0-9][0-9]+$","")
replace disease = regexr(disease,"^P[ ][0-9][0-9]+( )*","")
replace disease = regexr(disease,"( )*T[ ][0-9][0-9]+( )*(0-9)*( )*"," FEVER ")
replace disease = subinstr(disease,"  "," ",.)
replace disease = trim(disease)
replace disease = regexr(disease,"( )*TEMP(ERATURE)*[ ][0-9][0-9]+( )*(0-9)*( )*"," FEVER ")
replace disease = subinstr(disease,"  "," ",.)
replace disease = regexr(disease,"1ST ","")
replace disease = regexr(disease,"2ND ","")
replace disease = regexr(disease,"3RD ","")
replace disease = subinstr(disease,"1/3RD","",.)
replace disease = regexr(disease,"[4-9]TH ","")
replace disease = regexr(disease,"[0-9]+( )(0-9)*"," ")
replace disease = trim(disease)
replace disease = subinstr(disease,"    "," ",.)
replace disease = subinstr(disease,"   "," ",.)
replace disease = subinstr(disease,"  "," ",.)

* Conflicting replacements
replace disease = regexr(disease," 2D "," ")
replace disease = regexr(disease," 3D "," ")
replace disease = regexr(disease," FR HGATE$","")
replace disease = regexr(disease," GENL "," GENERAL ")
replace disease = regexr(disease," IN JANTILE"," INFANTILE")
replace disease = regexr(disease," L E "," LEFT EYE ")
replace disease = regexr(disease," L E$"," LEFT EYE")
replace disease = regexr(disease," M C$"," MORBUS CORDIS")
replace disease = regexr(disease," OF BY$"," OF LEG")
replace disease = regexr(disease," RHEUT "," RHEUMATISM ")
replace disease = regexr(disease," PNEUM ","PNEUMONIA ")
replace disease = regexr(disease," R E "," RIGHT EYE ")
replace disease = regexr(disease," R E$"," RIGHT EYE")
replace disease = regexr(disease," TO BE "," ")
replace disease = regexr(disease,"^COMP PAC ","COMPOUND FRACTURE ")
replace disease = regexr(disease,"COMPD TR ","COMPOUND FRACTURE ")
replace disease = regexr(disease,"^GENL ","GENERAL ")
replace disease = regexr(disease,"^IRY TO HEAD","INJURY TO HEAD")
replace disease = regexr(disease,"^L CART KNEE","LOOSE CARTILAGE KNEE")
replace disease = regexr(disease,"SUB CONJ HAM ","SUB CONJUNCTIVAL HEMORRHAGE ")
replace disease = regexr(disease,"^SIM FR ","SIMPLE FRACTURE ")
replace disease = regexr(disease,"BODIES DIS","BRODIES DIS")
replace disease = regexr(disease,"CALCANEM","CALCANEUS")
replace disease = regexr(disease,"CAMP FAC ","COMPOUND FRACTURE ")
replace disease = regexr(disease,"CAMP FRAC","COMPOUND FRAC")
replace disease = regexr(disease,"CARB AC ","CARBOLIC ACID")
replace disease = regexr(disease,"CATARACT R E","CATARACT RIGHT EYE")
replace disease = regexr(disease,"CONG DISL ","CONGENITAL DISEASE ")
replace disease = regexr(disease,"CONVERG CON STRAB","CONCOMITANT CONVERGENT STRAB")
replace disease = regexr(disease,"DOLOR ABDOMINALES","ABDOMINAL PAIN")
replace disease = regexr(disease,"FISSURE IN ANO","FISTULA ANUS")
replace disease = regexr(disease,"FISTULA (IN )*AN[O|S]","FISTULA ANUS")
replace disease = regexr(disease,"FR TIBIA F$","FRACTURE TIBIA FEMUR")
replace disease = regexr(disease,"FRAC H$","FRACTURE HAND")
replace disease = regexr(disease,"HAEM","HEM")
replace disease = regexr(disease,"HOEM","HEM")
replace disease = regexr(disease,"INF STRAB","INTERNAL STRAB")
replace disease = regexr(disease,"INGY TO LEG","INJURY TO LEG")
replace disease = regexr(disease,"KERATO( )*IRITIS","KERATITIS")
replace disease = regexr(disease,"LENTICULAR OF ACITIES","LENTICULAR OPACITY")
replace disease = regexr(disease,"MOR BILLI","MORBILLI")
replace disease = regexr(disease,"MAB IN CHEST","STAB IN CHEST")
replace disease = regexr(disease,"MEBRANE CORP$","MEMBRANOUS CROUP")
replace disease = regexr(disease,"PNEUMONIA L B$","PNEUMONIA LEFT BRONCHUS")
replace disease = regexr(disease,"POISON G$","POISONING")
replace disease = regexr(disease,"RICK FR A HORSE","KICK HORSE")
replace disease = regexr(disease,"ROTHELU","PNEUMONIA")
replace disease = regexr(disease,"SCLERO CORNEAL","SCLERA CORNEA")
replace disease = regexr(disease,"SEPTICAEMIA","SEPTICEMIA")
replace disease = regexr(disease,"SPINAL CANES","CARIES SPINE")
replace disease = regexr(disease,"SUPP G ","SUPPURATION ")
replace disease = regexr(disease,"SWELL G FACD","SWELLING FACE")
replace disease = regexr(disease,"TALIPES CALCULUS","TALIPES CALCANEUS")
replace disease = regexr(disease,"UNSPECIFIED","")
replace disease = regexr(disease,"VARICEL GANGRENOUS","VARICELLA GANGRENOSA")
replace disease = regexr(disease,"VES RECT FIST","BLADDER RECTUM FIST")
replace disease = regexr(disease,"RECT VISICAL FIST","BLADDER RECTUM FIST")

* Standardize abbreviations

replace disease = trim(disease)
replace disease = subinstr(disease,"  "," ",.)
replace disease = subinstr(disease," A "," ",.)
replace disease = subinstr(disease," ABLE "," ",.)
replace disease = subinstr(disease," ABOUT "," ",.)
replace disease = subinstr(disease," ABT "," ",.)
replace disease = subinstr(disease," AF "," ",.)
replace disease = subinstr(disease," AFR "," ",.)
replace disease = subinstr(disease," AFT "," ",.)
replace disease = subinstr(disease," AFTER "," ",.)
replace disease = subinstr(disease," AIFL "," AFFLICTION ",.)
replace disease = subinstr(disease," AT "," ",.)
replace disease = subinstr(disease," BY "," ",.)
replace disease = subinstr(disease," DUE "," ",.)
replace disease = subinstr(disease," FOLLOWING "," ",.)
replace disease = subinstr(disease," FOR "," ",.)
replace disease = subinstr(disease," FROM "," ",.)
replace disease = subinstr(disease," IN "," ",.)
replace disease = subinstr(disease," OF "," ",.)
replace disease = subinstr(disease," ON "," ",.)
replace disease = subinstr(disease," SOME "," ",.)
replace disease = subinstr(disease," THE "," ",.)
replace disease = subinstr(disease," TO "," ",.)
replace disease = subinstr(disease," UP "," ",.)
replace disease = subinstr(disease," WITH "," ",.)
replace disease = subinstr(disease,"&","",.)
replace disease = subinstr(disease," P CAUSE"," ",.)
replace disease = subinstr(disease,"CAUSE "," ",.)
replace disease = regexr(disease,"[0-9]+","")

replace disease = trim(disease)
replace disease = regexr(disease," (S|E)TC$","")
replace disease = regexr(disease," AB$"," ABSCESS")
replace disease = regexr(disease," ABAL "," ABDOMINAL ")
replace disease = regexr(disease," ABS "," ABSCESS ")
replace disease = regexr(disease," ABS$"," ABSCESS")
replace disease = regexr(disease," ABSCES$"," ABSCESS")
replace disease = regexr(disease," ABST$"," OBSTRUCTION")
replace disease = regexr(disease," AC ","ACUTE ")
replace disease = regexr(disease," ACC$"," ACCIDENT")
replace disease = regexr(disease," ADDOM$","ABDOMINALIS")
replace disease = regexr(disease," AFFECT$"," AFFECTION")
replace disease = regexr(disease," AFFN$"," AFFECTION")
replace disease = regexr(disease," AMFUCT$"," INFECTION")
replace disease = regexr(disease," AMP$"," AMPUTATION")
replace disease = regexr(disease," AMP(UT)*(AT)*$"," AMPUTATION")
replace disease = regexr(disease," AMTS$"," AMPUTATION")
replace disease = regexr(disease," AND "," ")
replace disease = regexr(disease," ANI$"," ANUS")
replace disease = regexr(disease," ANI "," ANUS ")
replace disease = regexr(disease," ANO$"," ANUS")
replace disease = regexr(disease," ANK "," ANKLE ")
replace disease = regexr(disease," ANKEL "," ANKLE ")
replace disease = regexr(disease," ANNS$"," ANUS")
replace disease = regexr(disease," ANRIS"," ANUS")
replace disease = regexr(disease," ANT "," ANTERIOR ")
replace disease = regexr(disease," AR "," AROUND ")
replace disease = regexr(disease," ARD "," ")
replace disease = regexr(disease," AURIS$"," EAR")
replace disease = regexr(disease," BEH "," ")
replace disease = regexr(disease," BNES$"," LEFT KNEE")
replace disease = regexr(disease," BR PN"," BRONCHOPN")
replace disease = regexr(disease," C PALATE","CLEFT PALATE")
replace disease = regexr(disease," C$","")
replace disease = regexr(disease," CAR$"," EAR")
replace disease = regexr(disease," CELL "," CELLULITIS ")
replace disease = regexr(disease," CHES$"," CHEST")
replace disease = regexr(disease," CHRONICA ","CHRONIC ")
replace disease = regexr(disease," CIRCUM$"," CIRCUMCISION")
replace disease = regexr(disease," CODIS$"," CORDIS")
replace disease = regexr(disease," CURTIS$"," CORDIS")
replace disease = regexr(disease," CONSOL(ID)*$"," CONSOLIDATION")
replace disease = regexr(disease," COMEA$"," CORNEA")
replace disease = regexr(disease," COMPD "," COMPOUND ")
replace disease = regexr(disease," CORJ$"," CONJUNCTIVITIS")
replace disease = regexr(disease," CORNLD$"," CORNEA")
replace disease = regexr(disease," CURV$"," CURVATURE")
replace disease = regexr(disease," CUTAN "," CUTANEOUS ")
replace disease = regexr(disease," DAY$","")
replace disease = regexr(disease," DEC$","")
replace disease = regexr(disease," DEC$","")
replace disease = regexr(disease," DEG$","")
replace disease = regexr(disease," DEGENERT$"," DEGENERATIVE")
replace disease = regexr(disease," DEMONT$","")
replace disease = regexr(disease," DESCENDED"," UNDESCENDED")
replace disease = regexr(disease," DIP(H)*(C)*$"," DIPHTHERIA")
replace disease = regexr(disease," DIPHTH "," DIPHTHERITIC ")
replace disease = regexr(disease," DIS "," DISEASE ")
replace disease = regexr(disease," DIS$"," DISEASE")
replace disease = regexr(disease," DO$"," DISEASE")
replace disease = regexr(disease," DO$","DISEASE")
replace disease = regexr(disease," DORE "," SORE ")
replace disease = regexr(disease," DULL$"," DULLNESS")
replace disease = regexr(disease," D(R)* V$"," DIARRHEA VOMITING")
replace disease = regexr(disease," E "," ")
replace disease = regexr(disease," E$","")
replace disease = regexr(disease," EMPLICATIONS$","")
replace disease = regexr(disease," ENLG$"," ENLARGEMENT")
replace disease = regexr(disease," ENPIP$"," ERYSIPELAS")
replace disease = regexr(disease," ERYSIP$"," ERYSIPELAS")
replace disease = regexr(disease," ETC$","")
replace disease = regexr(disease," EXT "," EXTERNAL ")
replace disease = regexr(disease," FACT "," FRACTURE ")
replace disease = regexr(disease," FEM(L)* "," FEMORAL ")
replace disease = regexr(disease," FEV "," FEVER ")
replace disease = regexr(disease," FEV$"," FEVER")
replace disease = regexr(disease," FIB "," FIBULA ")
replace disease = regexr(disease," FIB$"," FIBULA")
replace disease = regexr(disease," FIB(I)*A$"," FIBULA")
replace disease = regexr(disease," FISTU$"," FISTULA")
replace disease = regexr(disease," FOLLG "," ")
replace disease = regexr(disease," FOLLS "," FOLLICLES ")
replace disease = regexr(disease," FORT$"," FOOT")
replace disease = regexr(disease," FR "," FRACTURE ")
replace disease = regexr(disease," FR "," FRACTURE ")
replace disease = regexr(disease," FR$"," FRACTURE")
replace disease = regexr(disease," FRAC(E)* "," FRACTURE ")
replace disease = regexr(disease," FRED HERNIA"," IRREDUCIBLE HERNIA")
replace disease = regexr(disease," FUMIR$"," FEMUR")
replace disease = regexr(disease," GEN "," GENERAL ")
replace disease = regexr(disease," GL "," GLAND ")
replace disease = regexr(disease," GLUTL "," GLUTEUS ")
replace disease = regexr(disease," GON$"," GONORRHEA")
replace disease = regexr(disease," GERS$"," GONORRHEA")
replace disease = regexr(disease," GT TOE"," RIGHT TOE")
replace disease = regexr(disease," HAS "," ")
replace disease = regexr(disease," HD$"," HEAD")
replace disease = regexr(disease," HE$"," HEART")
replace disease = regexr(disease," HIST "," HISTORY ")
replace disease = regexr(disease," HOOPING"," WHOOPING")
replace disease = regexr(disease," HMG$"," HEMORRHAGE")
replace disease = regexr(disease," HT "," HEART ")
replace disease = regexr(disease," HYP "," HIP ")
replace disease = regexr(disease," IN$","")
replace disease = regexr(disease," IND HERNIA"," INGUINAL HERNIA")
replace disease = regexr(disease," ING "," INGUINAL ")
replace disease = regexr(disease," INGL "," INGUINAL ")
replace disease = regexr(disease," INGL"," INGUINAL$")
replace disease = regexr(disease," INTO "," ")
replace disease = regexr(disease," INY$"," INJURY")
replace disease = regexr(disease," INTERMA$"," INTERMITTENT")
replace disease = regexr(disease," ISCHI$"," ISCHIUM")
replace disease = regexr(disease," JR$"," JOINT")
replace disease = regexr(disease," JT "," JOINT ")
replace disease = regexr(disease," SH JT$"," SHOULDER JOINT")
replace disease = regexr(disease," JT$"," JOINT")
replace disease = regexr(disease," L(E) "," LEFT ")
replace disease = regexr(disease," L(E)* "," LEFT ")
replace disease = regexr(disease," L(E)*$"," LEFT")
replace disease = regexr(disease," L(E)*$"," LEFT")
replace disease = regexr(disease," L(T)* "," LEFT ")
replace disease = regexr(disease," L(T)*$"," LEFT")
replace disease = regexr(disease," LAND$"," HAND")
replace disease = regexr(disease," LID$"," EYELID")
replace disease = regexr(disease," LNG HERNIA"," INGUINAL HERNIA")
replace disease = regexr(disease," MEMB$"," MEMBRANE")
replace disease = regexr(disease," MEMBRA$"," MEMBRANOUS")
replace disease = regexr(disease," MID "," MIDDLE ")
replace disease = regexr(disease," MORAL$","")
replace disease = regexr(disease," NASI$"," NASAL")
replace disease = regexr(disease," NEAR "," ")
replace disease = regexr(disease," NEC$"," NECROSIS")
replace disease = regexr(disease," NR "," ")
replace disease = regexr(disease," NR "," NEAR ")
replace disease = regexr(disease," OBS$"," OBSTRUCTION")
replace disease = regexr(disease," OF "," ")
replace disease = regexr(disease," OF$","")
replace disease = regexr(disease," OPT "," OPERATION ")
replace disease = regexr(disease," OPN "," OPERATION ")
replace disease = regexr(disease," OPTN "," OPERATION ")
replace disease = regexr(disease," OPTH(A)*$"," EYE")
replace disease = regexr(disease," ORBIT "," ORBITAL ")
replace disease = regexr(disease," OLEPHARON"," ANKYLOBLEPHARON")
replace disease = regexr(disease," OT "," ")
replace disease = regexr(disease," OULER "," OUTER ")
replace disease = regexr(disease," PAT(A)*$"," PATELLA")
replace disease = regexr(disease," PER "," ")
replace disease = regexr(disease," PEST "," POST ")
replace disease = regexr(disease," PHIMI "," PHIMOSIS ")
replace disease = regexr(disease," PLENA"," PLEURAL")
replace disease = regexr(disease," PL EFF$"," PLEURAL EFFUSION")
replace disease = regexr(disease,"( )*PNEUMATISM"," RHEUMATISM")
replace disease = regexr(disease," PN(E)*$"," PNEUMONIA")
replace disease = regexr(disease," PROB "," ")
replace disease = regexr(disease," PROBABLY "," ")
replace disease = regexr(disease," PT "," ")
replace disease = regexr(disease," PUL$"," PULMONARY")
replace disease = regexr(disease," PUR "," PURULENT ")
replace disease = regexr(disease," R(T)* "," RIGHT ")
replace disease = regexr(disease," R(T)*$"," RIGHT")
replace disease = regexr(disease," REG$"," REGION")
replace disease = regexr(disease," RETD TEST"," RETAINED TEST")
replace disease = regexr(disease," RHEM$"," RHEUMATISM")
replace disease = regexr(disease," RH$"," RHEUMATISM")
replace disease = regexr(disease," RHEUM$"," RHEUMATISM")
replace disease = regexr(disease," RHUEM$"," RHEUMATISM")
replace disease = regexr(disease," RITS "," RIBS ")
replace disease = regexr(disease," ROUND "," AROUND ")
replace disease = regexr(disease," ROUNG "," AROUND ")
replace disease = regexr(disease," RROUND "," AROUND ")
replace disease = regexr(disease," RUPD "," RUPTURE ")
replace disease = regexr(disease," S F$"," SCARLET FEVER")
replace disease = regexr(disease," SCALCIS$"," CALCANEUS")
replace disease = regexr(disease," SE FEVER"," SCARLET FEVER")
replace disease = regexr(disease," SHOULD$"," SHOULDER")
replace disease = regexr(disease," SH$"," SHOULDER")
replace disease = regexr(disease," SINCIO "," SYNOVITIS ")
replace disease = regexr(disease," SNIRIS$"," SYNOVITIS")
replace disease = regexr(disease," STEMN ", "STRUMOUS ")
replace disease = regexr(disease," STRAB(I)*(S)*$"," STRABISMUS")
replace disease = regexr(disease," STRIC(T)* "," STRICTURE ")
replace disease = regexr(disease," STRICT$"," STRICTURE")
replace disease = regexr(disease," STRUM "," STRUMOUS ")
replace disease = regexr(disease," STRUMU$"," STRUMOUS")
replace disease = regexr(disease," SUBMAX "," SUBMAXILLA ")
replace disease = regexr(disease," SUPP(D)*$"," SUPPURATION")
replace disease = regexr(disease," SYPH "," SYPHILIS ")
replace disease = regexr(disease," T$","")
replace disease = regexr(disease," TCOZ$","")
replace disease = regexr(disease," TEMP REGION","TEMPORAL REGION")
replace disease = regexr(disease," TENDOUS "," TENDON ")
replace disease = regexr(disease," TERTIE$"," URINE")
replace disease = regexr(disease," TEST$"," TESTICLE")
replace disease = regexr(disease," TESTILE$"," TESTICLE")
replace disease = regexr(disease," THRO LUNG"," LUNG")
replace disease = regexr(disease," THROUGH "," ")
replace disease = regexr(disease," TIB "," TIBIA ")
replace disease = regexr(disease," TIB "," TIBIA ")
replace disease = regexr(disease," TIMES$","")
replace disease = regexr(disease," TO "," ")
replace disease = regexr(disease," TO$","")
replace disease = regexr(disease," TUB$"," TUBERCULAR")
replace disease = regexr(disease," TUBERITE$"," TUBERCULAR")
replace disease = regexr(disease," TUBERCLE(S)*$"," TUBERCULAR")
replace disease = regexr(disease," TUM$"," TUMOUR")
replace disease = regexr(disease," TUM "," TUMOUR")
replace disease = regexr(disease," TUMOUS$"," TUMOUR")
replace disease = regexr(disease," ULECERT "," ULCERATION ")
replace disease = regexr(disease," UNA "," ULNA ")
replace disease = regexr(disease," UPP "," UPPER ")
replace disease = regexr(disease," UROGENT$"," UROGENITAL")
replace disease = regexr(disease," VEG$"," VEGETATION")
replace disease = regexr(disease," VEGETA[L|T]$"," VEGETATION")
replace disease = regexr(disease," VEGETN$"," VEGETATION")
replace disease = regexr(disease," VOM$"," VOMITING")
replace disease = regexr(disease,"CAL VEA$","CALCULUS VESICA")
replace disease = regexr(disease," W "," WOUND ")
replace disease = regexr(disease," W$"," WOUND")
replace disease = regexr(disease," WD "," WOUND ")
replace disease = regexr(disease," WD$"," WOUND")
replace disease = regexr(disease," WY$"," WOUND")
replace disease = regexr(disease," WDS "," WOUNDS ")
replace disease = regexr(disease," WINE$"," URINE")
replace disease = regexr(disease,"(E)*MALF(O)*(R)*(M)* ","MALFORMATION ")

replace disease = trim(disease)
replace disease = regexr(disease,"^AB ","ABSCESS ")
replace disease = regexr(disease,"^ABAL "," ABDOMINAL ")
replace disease = regexr(disease,"^ABC ","ABSCESS ")
replace disease = regexr(disease,"^ABDC "," ABDOMINAL ")
replace disease = regexr(disease,"^ABDOMD "," ABDOMINAL ")
replace disease = regexr(disease,"^ABS ","ABSCESS ")
replace disease = regexr(disease,"^ABS ","ABSCESS ")
replace disease = regexr(disease,"^ABS$","ABSCESS")
replace disease = regexr(disease,"^ABSCES ","ABSCESS ")
replace disease = regexr(disease,"^AC ","ACUTE ")
replace disease = regexr(disease,"^AE ","ACUTE ")
replace disease = regexr(disease,"^AFTER ","")
replace disease = regexr(disease,"^ALD ","OLD ")
replace disease = regexr(disease,"^ALDOM ","ABDOMINAL ")
replace disease = regexr(disease,"^ALLEGED "," ")
replace disease = regexr(disease,"^ANG ","ANGULAR ")
replace disease = regexr(disease,"^ANGR ","ANGULAR ")
replace disease = regexr(disease,"^ANK ","ANKLE ")
replace disease = regexr(disease,"^ANT ","ANTERIOR ")
replace disease = regexr(disease,"^ANTRAL","ANTRUM")
replace disease = regexr(disease,"^ARMPT ","AMPUTATION ")
replace disease = regexr(disease,"^BAS ","BASE ")
replace disease = regexr(disease,"^BED AMPUT","BAD AMPUT")
replace disease = regexr(disease,"^BED OPER","BAD OPER")
replace disease = regexr(disease,"^BIT ","BITE ")
replace disease = regexr(disease,"^BR PN ","BRONCHOPNEUMONIA ")
replace disease = regexr(disease,"^BR PN","BRONCHOPN")
replace disease = regexr(disease,"^BR ","BROKEN ")
replace disease = regexr(disease,"^BRO ","BROKEN ")
replace disease = regexr(disease,"^BURS$","BURSA")
replace disease = regexr(disease,"^BURT ","BURNT ")
replace disease = regexr(disease,"^C PALATE","CLEFT PALATE")
replace disease = regexr(disease,"^CAL ","CALCULUS ")
replace disease = regexr(disease,"^CART ","CARTILAGE ")
replace disease = regexr(disease,"^CART ","CARTILAGE")
replace disease = regexr(disease,"^CD ","COMPOUND ")
replace disease = regexr(disease,"^CD FR ","COMPOUND FRACTURE ")
replace disease = regexr(disease,"^CELL ","CELLULITIS")
replace disease = regexr(disease,"^CELL$","CELLULITIS")
replace disease = regexr(disease,"^CEPHAL ","CEPHALALGIA ")
replace disease = regexr(disease,"^CH ","CHRONIC ")
replace disease = regexr(disease,"^CHE ","CHRONIC ")
replace disease = regexr(disease,"^CHS ","CHRONIC ")
replace disease = regexr(disease,"^CKR ","CHRONIC ")
replace disease = regexr(disease,"^CH(R)* ","CHRONIC ")
replace disease = regexr(disease,"^CHROME ","CHRONIC ")
replace disease = regexr(disease,"^COUTH ","COUGH ")
replace disease = regexr(disease,"^COCAL EMP","LOCAL EMP")
replace disease = regexr(disease,"^COM(P)*(D)* ","COMPOUND ")
replace disease = regexr(disease,"^CON SCALP","CONTUSION SCALP")
replace disease = regexr(disease,"^COMPT FR","COMPOUND FR")
replace disease = regexr(disease,"^CONT ","CONTRACTURE ") if regexm(disease,"FEVER")==0 & regexm(disease,"PYREXIA")==0
replace disease = regexr(disease,"^CONT(D)* ","CONTINUED ")
replace disease = regexr(disease,"^CORNA$","CORNEA")
replace disease = regexr(disease,"^COSTAL","INTERCOSTAL")
replace disease = regexr(disease,"^CRUSH ","CRUSHED ")
replace disease = regexr(disease,"^CUR ","CURVATURE ")
replace disease = regexr(disease,"^CURVE(D)* ","CURVATURE ")
replace disease = regexr(disease,"^D(R)* V ","DIARRHEA VOMITING ")
replace disease = regexr(disease,"^D SCALP","SCALP")
replace disease = regexr(disease,"^DEBL ","DEBILITY ")
replace disease = regexr(disease,"^DEF(C)* ","DEFECTIVE ")
replace disease = regexr(disease,"^DEFT ","DEFLECTED ")
replace disease = regexr(disease,"^DES SPINE","DISEASE SPINE")
replace disease = regexr(disease,"^DES(E)* KNEE","DISEASE KNEE")
replace disease = regexr(disease,"^DES VAR","PES VAR")
replace disease = regexr(disease,"^DIPH$","DIPHTHERIA")
replace disease = regexr(disease,"^DIS LOCATION","DISLOCATION")
replace disease = regexr(disease,"^DIS ","DISEASE ")
replace disease = regexr(disease,"^DIS$","DISEASE")
replace disease = regexr(disease,"^DISC HIP","DISEASE HIP")
replace disease = regexr(disease,"^DISE KNEE","DISEASE KNEE")
replace disease = regexr(disease,"^E[S|X]T STRAB","EXTERNAL STRAB")
replace disease = regexr(disease,"^ECYEMA$","ECZEMA")
replace disease = regexr(disease,"^EFFECT(S)* ","")
replace disease = regexr(disease,"^ENTERIA$","ENTERIC FEVER")
replace disease = regexr(disease,"^EPNEUM ","PNEUMONIA ")
replace disease = regexr(disease,"^EQUINUS$","EQUINOVARUS")
replace disease = regexr(disease,"^FACT(S)* ","FRACTURE ")
replace disease = regexr(disease,"^FALT ","FALTY ")
replace disease = regexr(disease,"^FEB ","FEBRIS ")
replace disease = regexr(disease,"^FELL ","FALL ")
replace disease = regexr(disease,"^FOR ","")
replace disease = regexr(disease,"^FR ","FRACTURE ")
replace disease = regexr(disease,"^FRACK ","FRACTURE ")
replace disease = regexr(disease,"^GEN ","GENERAL ")
replace disease = regexr(disease,"^GENT ","GENERAL ")
replace disease = regexr(disease,"^GON$","GONORRHEA")
replace disease = regexr(disease,"^GON ","GONORRHEA ")
replace disease = regexr(disease,"^GONORRH ","GONORRHEA ")
replace disease = regexr(disease,"^GOU ","GOUT ")
replace disease = regexr(disease,"^GOW ","GOUT ")
replace disease = regexr(disease,"^GOW$","GOUT")
replace disease = regexr(disease,"^H$","")
replace disease = regexr(disease,"^HERIA","HERNIA")
replace disease = regexr(disease,"^HERINA","HERNIA")
replace disease = regexr(disease,"^HERRIA","HERNIA")
replace disease = regexr(disease,"^HOOPING","WHOOPING")
replace disease = regexr(disease,"^HT ","HEART ")
replace disease = regexr(disease,"^HYP ","HIP ")
replace disease = regexr(disease,"^ILIC ","ILIAC ")
replace disease = regexr(disease,"^INGL ","INGUINAL ")
replace disease = regexr(disease,"^IMPERF(O)*(R)* ","IMPERFORATE ")
replace disease = regexr(disease,"^INCONT ","INCONTINENCE ")
replace disease = regexr(disease,"^INFC ","INFECTION ")
replace disease = regexr(disease,"^INFCTOE","INFECTION TOE")
replace disease = regexr(disease,"^ING ","INGUINAL ")
replace disease = regexr(disease,"^INY ","INJURY ")
replace disease = regexr(disease,"^LACETD ","LACERATION ")
replace disease = regexr(disease,"^LARYNGEAL NS$","LARYNGEAL OBSTRUCTION")
replace disease = regexr(disease,"^LAS W","LACERATION W")
replace disease = regexr(disease,"^L PNEUM","LOBAR PNEUM")
replace disease = regexr(disease,"^L ING","LEFT ING")
replace disease = regexr(disease,"^L(E)* ","LEFT ")
replace disease = regexr(disease,"^LUCOMA$","LEUCOMA")
replace disease = regexr(disease,"^LIFT$","LEFT")
replace disease = regexr(disease,"^M ","MORBUS ")
replace disease = regexr(disease,"^MEMBR(A)*(N)* ","MEMBRANOUS ")
replace disease = regexr(disease,"^MORB CORD","MORBUS CORD")
replace disease = regexr(disease,"^MOR(B)* ","MORBUS ")
replace disease = regexr(disease,"^MIR COX","MORBUS COX")
replace disease = regexr(disease,"^NERUS$","NEVUS")
replace disease = regexr(disease,"^OBS ","OBSTRUCTION ")
replace disease = regexr(disease,"^OBSTN$","OBSTRUCTION")
replace disease = regexr(disease,"^OBSTR$","OBSTRUCTION")
replace disease = regexr(disease,"^OBSTRU$","OBSTRUCTION")
replace disease = regexr(disease,"^OBSTRUC(N|T)*$","OBSTRUCTION")
replace disease = regexr(disease,"^OF ","")
replace disease = regexr(disease,"^OID ","OLD ")
replace disease = regexr(disease,"^ON ","")
replace disease = regexr(disease,"^ORIS$","CANCRUM ORIS")
replace disease = regexr(disease,"^OXALURIA","HYPEROXALURIA")
replace disease = regexr(disease,"^PART ","PARTIAL ")
replace disease = regexr(disease,"^PAIS$","POISONING")
replace disease = regexr(disease,"^PERF(O)*(R)*(T)*(G)* ","PERFORATED ")
replace disease = regexr(disease,"^PL EFF","PLEURAL EFF")
replace disease = regexr(disease,"^PRO ","PROLAPSE")
replace disease = regexr(disease,"^PULM(ON)* ","PULMONARY ")
replace disease = regexr(disease,"^PUNCT ","PUNCTURE ")
replace disease = regexr(disease,"^R ","RIGHT ")
replace disease = regexr(disease,"^R(T)* ","RIGHT ")
replace disease = regexr(disease,"^RES CALC","RESIDUAL CAL")
replace disease = regexr(disease,"^RH ","RHEUMATIC")
replace disease = regexr(disease,"^RHEM$","RHEUMATISM")
replace disease = regexr(disease,"^RHEN ","RHEUMATIC ")
replace disease = regexr(disease,"^RHEN$","RHEUMATISM")
replace disease = regexr(disease,"^RHEUM$","RHEUMATISM")
replace disease = regexr(disease,"^RHUMT ","RHEUMATISM ")
replace disease = regexr(disease,"^RHUMT$","RHEUMATISM")
replace disease = regexr(disease,"^RH F ","RHEUMATIC FEVER ")
replace disease = regexr(disease,"^SABMAX","SUBMAX")
replace disease = regexr(disease,"^SAID ","")
replace disease = regexr(disease,"^SAVED ","")
replace disease = regexr(disease,"^SAYNES ","")
replace disease = regexr(disease,"^SCAILA ","")
replace disease = regexr(disease,"^SCALS ","SCALES ")
replace disease = regexr(disease,"^SCALED ","SCALES ")
replace disease = regexr(disease,"^SC F ","SCARLET FEVER ")
replace disease = regexr(disease,"^SCT LEVER","SCARLET FEVER")
replace disease = regexr(disease,"^S FRAC","SIMPLE FRAC")
replace disease = regexr(disease,"^SCALF ","SCALP ")
replace disease = regexr(disease,"^SCAR(T|L)*(D)* NEPH","SCARLET FEVER NEPH")
replace disease = regexr(disease,"^SCARLAT NEPH","SCARLET FEVER NEPH")
replace disease = regexr(disease,"^SCART$","SCARLET FEVER")
replace disease = regexr(disease,"^SCT ","SCARLET FEVER ")
replace disease = regexr(disease,"^SCT$","SCARLET FEVER")
replace disease = regexr(disease,"^SE FEVER","SCARLET FEVER")
replace disease = regexr(disease,"^SEAR FEVER","SCARLET FEVER")
replace disease = regexr(disease,"^SEBA(C)* TUM","SEBACEOUS TUM")
replace disease = regexr(disease,"^SEQ$","SEQUELA")
replace disease = regexr(disease,"^SEQ ","SEQUELA ")
replace disease = regexr(disease,"^SEQUE$","SEQUELA")
replace disease = regexr(disease,"^SET FEVER","SCARLET FEVER")
replace disease = regexr(disease,"^SINNS POP","ABSCESS POP")
replace disease = regexr(disease,"^SNPP ","SUPPURATION ")
replace disease = regexr(disease,"^SP(R)*(D)* ","SPRAIN ")
replace disease = regexr(disease,"^SPEC PARAP","SPASTIC PARAP")
replace disease = regexr(disease,"SPECIFIE","SPECIFIC")
replace disease = regexr(disease,"^STATS$","STAB")
replace disease = regexr(disease,"^STRIC(T)* ","STRICTURE ")
replace disease = regexr(disease,"^STRUM(D|S)* ","STRUMOUS ")
replace disease = regexr(disease,"^STUMOUS ","STRUMOUS ")
replace disease = regexr(disease,"^STR DIS","STRUMOUS DIS")
replace disease = regexr(disease,"^STRAN(G|J)*(L)* ","STRANGULATED ")
replace disease = regexr(disease,"^STRENUOUS DIS","STRUMOUS DIS")
replace disease = regexr(disease,"^STRONG HERNIA","STRANGULATED HERNIA")
replace disease = regexr(disease,"^SUBMAX ","SUBMAXILLA ")
replace disease = regexr(disease,"^SUPP$","SUPPURATION")
replace disease = regexr(disease,"^SUPPER ","SUPPURATION ")
replace disease = regexr(disease,"^SWALL(E)* ","SWALLOWED ")
replace disease = regexr(disease,"^SYPH ","SYPHILIS ")
replace disease = regexr(disease,"^SYPHILITIC ","SYPHILIS ")
replace disease = regexr(disease,"^T B ","TUBERCULAR ")
replace disease = regexr(disease,"^TAB ","TUBERCULAR ")
replace disease = regexr(disease,"^TEM$","FEVER")
replace disease = regexr(disease,"^THE ","")
replace disease = regexr(disease,"^TOB ","TUBERCULAR ")
replace disease = regexr(disease,"^TRAC ","FRACTURE ")
replace disease = regexr(disease,"^TRA(U)*M(AT)* CATAR","TRAUMATIC CATAR")
replace disease = regexr(disease,"^TRAUMT ","TRAUMATIC ")
replace disease = regexr(disease,"^TRITIS$","IRITIS")
replace disease = regexr(disease,"TUBAL NEPH","TUBULE NEPH")
replace disease = regexr(disease,"^TUBERCULS ","TUBERCULAR ")
replace disease = regexr(disease,"^TUBR ","TUBERCULAR ")
replace disease = regexr(disease,"^TUBERS ","TUBERCULAR ")
replace disease = regexr(disease,"^TUL ","TUBERCULAR ")
replace disease = regexr(disease,"^TUMMONS ","TUMOUR ")
replace disease = regexr(disease,"^TUMOUS","TUMOUR")
replace disease = regexr(disease,"^TYPH$","TYPHOID FEVER")
replace disease = regexr(disease,"^TYPHIERT$","TYPHOID FEVER")
replace disease = regexr(disease,"^UMB ","UMBILICAL ")
replace disease = regexr(disease,"^UMBIL ","UMBILICAL ")
replace disease = regexr(disease,"^VES ","VESICAL ")
replace disease = regexr(disease,"^VOMG ","VOMITING ")
replace disease = regexr(disease,"^VOMT ","VOMITING ")
replace disease = regexr(disease,"^WD ","WOUND ")
replace disease = regexr(disease,"^W ","WOUND ")
replace disease = regexr(disease,"3(R)*D$","")

replace disease = regexr(disease,"ABC$","ABSCESS")
replace disease = regexr(disease,"ABCESS","ABSCESS")
replace disease = regexr(disease,"ABCESS","ABSCESS")
replace disease = regexr(disease,"ABD ","ABDOMINAL ")
replace disease = regexr(disease,"ABD(C)*(OM)*(D)*(L)*(T)*$","ABDOMINAL")
replace disease = regexr(disease,"ABD(L|M)* ","ABDOMINAL ")
replace disease = regexr(disease,"ABD(OM)*(L)* ","ABDOMINAL ")
replace disease = regexr(disease,"ABDOM ","ABDOMINAL ")
replace disease = regexr(disease,"ABDOM[A|I]N$","ABDOMINAL")
replace disease = regexr(disease,"ABDOMEN","ABDOMINAL")
replace disease = regexr(disease,"ABDOMINAL HUMOUR","ABDOMINAL TUMOUR")
replace disease = regexr(disease,"ABDOMINALIS","ABDOMINAL")
replace disease = regexr(disease,"ABDOMT ","ABDOMINAL ")
replace disease = regexr(disease,"ABNORMALITY","ABNORMAL")
replace disease = regexr(disease,"ABRA(I)*DED ","ABRASION ")
replace disease = regexr(disease,"ABRCESS","ABSCESS")
replace disease = regexr(disease,"ABSCES ","ABSCESS")
replace disease = regexr(disease,"ABSCESSES","ABSCESS")
replace disease = regexr(disease,"ABSECESS","ABSCESS")
replace disease = regexr(disease,"ABSEESS","ABSCESS")
replace disease = regexr(disease,"ABSELL","ABSCESS")
replace disease = regexr(disease,"ABSESS","ABSCESS")
replace disease = regexr(disease,"ABSIN","ABSCESS")
replace disease = regexr(disease,"ABSTRACTION","OBSTRUCTION")
replace disease = regexr(disease,"AC , RHEU","AC RHEU")
replace disease = regexr(disease,"AC RHEUMT$","ACUTE RHEUMATISM")
replace disease = regexr(disease,"ACUTE RH PNEUMONIA","ACUTE RHEUMATIC PNEUMONIA")
replace disease = regexr(disease,"ACCIDENTAL","ACCIDENT")
replace disease = regexr(disease,"ACILLA","AXILLA")
replace disease = regexr(disease,"ADBL ","ABDOMINAL ")
replace disease = regexr(disease,"ADBOMEN","ABDOMEN")
replace disease = regexr(disease,"ADDISON S","ADDISONS")
replace disease = regexr(disease,"ADEN(D)* ","ADENOID ")
replace disease = regexr(disease,"ADENOMATOUS","ADENOMA")
replace disease = regexr(disease,"ADERITIS","ADENITIS")
replace disease = regexr(disease,"ADEROSED","ADENOID")
replace disease = regexr(disease,"ADEVITES","ADENITIS")
replace disease = regexr(disease,"ADHERENS","ADHERENT")
replace disease = regexr(disease,"ADHESIA","ADHESION")
replace disease = regexr(disease,"AEDEMA","EDEMA")
replace disease = regexr(disease,"AESTHESIA","ESTHESIA")
replace disease = regexr(disease,"AFFECT ","AFFECTION ")
replace disease = regexr(disease,"AFFN ","AFFECTION ")
replace disease = regexr(disease,"ALBUM(IN)* ","ALBUMINURIA ")
replace disease = regexr(disease,"ALBUMINIVIA","ALBUMINURIA")
replace disease = regexr(disease,"ALBUMINEMIA","ALBUMINURIA")
replace disease = regexr(disease,"ALCER","ULCER")
replace disease = regexr(disease,"ALLEGED","")
replace disease = regexr(disease,"AMAL ","ANUS ")
replace disease = regexr(disease,"AMGINA","ANGINA")
replace disease = regexr(disease,"AMLTN","AMPUTATION")
replace disease = regexr(disease,"AMP(L|R)* ","AMPUTATION ") if regexm(disease,"CAMP")==0
replace disease = regexr(disease,"AMP(UT)*(AT)* ","AMPUTATION ") if regexm(disease,"CAMP")==0
replace disease = regexr(disease,"AMPHI ","AMPUTATION ")
replace disease = regexr(disease,"AMPN ","AMPUTATION ")
replace disease = regexr(disease,"AMPT(N|R|S)*","AMPUTATION")
replace disease = regexr(disease,"ANAEMIA","ANEMIA")
replace disease = regexr(disease,"ANAESTHESIA","ANESTHESIA")
replace disease = regexr(disease,"ANAESTHSIA","ANESTHESIA")
replace disease = regexr(disease,"(PERI)*ANAL ","ANUS ")
replace disease = regexr(disease,"ANAMIA","ANEMIA")
replace disease = regexr(disease,"ANARSARCA","ANASARCA")
replace disease = regexr(disease,"ANASAR$","ANASARCA")
replace disease = regexr(disease,"ANASARCAOLIC","ANASARCA OLIGURIA")
replace disease = regexr(disease,"ANCHY(LOSED)* ","ANCHYLOSIS ")
replace disease = regexr(disease,"ANCLE","ANKLE")
replace disease = regexr(disease,"ANDITORY","AUDITORY")
replace disease = regexr(disease,"ANENCEPHALUS","ANENCEPHALY")
replace disease = regexr(disease,"ANEUR(UR)*ISM","ANEURYSM")
replace disease = regexr(disease,"ANEURISEN$","ANEURYSM")
replace disease = regexr(disease,"ANEUTISM","ANEURYSM")
replace disease = regexr(disease,"ANGELA DEFORMITY","ANGULAR DEFORMITY")
replace disease = regexr(disease,"ANGINAL","ANGINA")
replace disease = regexr(disease,"ANGLO NEUROTIC","ANGIONEUROTIC")
replace disease = regexr(disease,"ANKYLOSED","ANCHYLOSIS")
replace disease = regexr(disease,"ANKYLOSIS","ANCHYLOSIS")
replace disease = regexr(disease,"ANOEMIA","ANEMIA")
replace disease = regexr(disease,"ANT WALL","ANTERIOR")
replace disease = regexr(disease,"ANTERIA","ANTERIOR")
replace disease = regexr(disease,"ANTHURO$","ARTHRITIS")
replace disease = regexr(disease,"ANWATERIE","CURVATURE")
replace disease = regexr(disease,"AORTIC","AORTA")
replace disease = regexr(disease,"APHAXIA","APHASIA")
replace disease = regexr(disease,"APICAL ","APEX ")
replace disease = regexr(disease,"APP(R)*ENDIC(IT)*(I)*S","APPENDICITIS")
replace disease = regexr(disease,"APPENDECITIS","APPENDICITIS")
replace disease = regexr(disease,"APPENDICEAL","APPENDIX")
replace disease = regexr(disease,"APPENDICECTOMY","APPENDECTOMY")
replace disease = regexr(disease,"APPENDIS$","APPENDICITIS")
replace disease = regexr(disease,"APPENDISE","APPENDIX")
replace disease = regexr(disease,"AQUINO VARUS","EQUINOVARUS")
replace disease = regexr(disease,"AQUINO VARUS","EQUINOVARUS")
replace disease = regexr(disease,"ARENE","URINE")
replace disease = regexr(disease,"ARCHRITIS","ARTHRITIS")
replace disease = regexr(disease,"ARTHRITIC","ARTHRITIS")
replace disease = regexr(disease,"ARYTHEMA","ERYTHEMA")
replace disease = regexr(disease,"ASCARIS","ASCARIASIS")
replace disease = regexr(disease,"ASCUTES","ASCITES")
replace disease = regexr(disease,"ASOPH OBT$","ESOPHAGUS OBSTRUCTION")
replace disease = regexr(disease,"ASTHANOPIA","ASTHENOPIA")
replace disease = regexr(disease,"ASTHEMA","ASTHMA")
replace disease = regexr(disease,"ATAXY","ATAXIA")
replace disease = regexr(disease,"ATHETOSIS","ATELIOSIS")
replace disease = regexr(disease,"ATROPHIED","ATROPHY")
replace disease = regexr(disease,"AUCTE ","ACUTE ")
replace disease = regexr(disease,"AUGUE","AGUE")
replace disease = regexr(disease,"AXILA$","AXILLA")
replace disease = regexr(disease,"AXILL ","AXILLA ")
replace disease = regexr(disease,"AXILLARY","AXILLA")
replace disease = regexr(disease,"AXILLIARY","AXILLA")
replace disease = regexr(disease,"AXILLY","AXILLA")

replace disease = regexr(disease,"BADLEY","BADLY")
replace disease = regexr(disease,"BANDY LEGGED","BOW-LEGGED")
replace disease = regexr(disease,"BAP(H)*THALMOS","BUPHTHALMOS")
replace disease = regexr(disease,"BASAL","BASE")
replace disease = regexr(disease,"BASIC MEN","BASE MEN")
replace disease = regexr(disease,"BEFID VOULA","BIFID UVULA")
replace disease = regexr(disease,"BENTO","BENT")
replace disease = regexr(disease,"BITTEN","BITE")
replace disease = regexr(disease,"BLANITIS","BALANITIS")
replace disease = regexr(disease,"BLINDNESS","BLIND")
replace disease = regexr(disease,"BLOOD","BLEEDING")
replace disease = regexr(disease,"BODIES","BODY")
replace disease = regexr(disease,"BODILY","BODY")
replace disease = regexr(disease,"BONCHD ","BRONCHITIS ")
replace disease = regexr(disease,"BONCHOPNEU","BRONCHOPNEU")
replace disease = regexr(disease,"BORKEN","BROKEN")
replace disease = regexr(disease,"BOTHRAM","BOTH ARM")
replace disease = regexr(disease,"BOW LEG(S)*","BOW-LEGGED")
replace disease = regexr(disease,"BOWEL COMPN$","BOWEL CONSTIPATION")
replace disease = regexr(disease,"BR(ONCHO)* PNEU","BRONCHOPNEU")
replace disease = regexr(disease,"BRADAWL","BRAWL")
replace disease = regexr(disease,"BREATH$","BREATH")
replace disease = regexr(disease,"BRENSES","BRUISE")
replace disease = regexr(disease,"BRIGHT ","BRIGHTS")
replace disease = regexr(disease,"BROCHOPNEU","BRONCHOPNEU")
replace disease = regexr(disease,"BROKER","BROKEN")
replace disease = regexr(disease,"BRON(CH)*(O)* PNEUM","BRONCHOPNEUM")
replace disease = regexr(disease,"BRONC$","BRONCHITIS")
replace disease = regexr(disease,"BRONCH ","BRONCHITIS ")
replace disease = regexr(disease,"BRONCH PNEU","BRONCHOPNEU")
replace disease = regexr(disease,"BRONCH$","BRONCHITIS")
replace disease = regexr(disease,"BRONCH(I)*AL PNEUM","BRONCHOPNEUM")
replace disease = regexr(disease,"BRONCHIAL","BRONCHUS")
replace disease = regexr(disease,"BRONCHITES","BRONCHITIS")
replace disease = regexr(disease,"BRONCHITIS BR PNEUM","BRONCHOPNEUMONIA")
replace disease = regexr(disease,"BRONCHO ","BRONCHITIS ")
replace disease = regexr(disease,"BRONCHPNEU","BRONCHOPNEU")
replace disease = regexr(disease,"BRONCHS( )*PNEUM","BRONCHOPNEUM")
replace disease = regexr(disease,"BRONCHTITIS","BRONCHITIS")
replace disease = regexr(disease,"BRONKEN","BROKEN")
replace disease = regexr(disease,"BRONTITIS","BRONCHITIS")
replace disease = regexr(disease,"BRUISD","BRUISE")
replace disease = regexr(disease,"BRUISED","BRUISE")
replace disease = regexr(disease,"BRUISING","BRUISE")
replace disease = regexr(disease,"BRUSED","BRUISE")
replace disease = regexr(disease,"BUBOES","BUBO")
replace disease = regexr(disease,"BUISA PAT","BURSA PAT")
replace disease = regexr(disease,"BULLA ","BULLAE ")
replace disease = regexr(disease,"BULLAR PALSY","BULBAR PALSY")
replace disease = regexr(disease,"BULLETT","BULLET")
replace disease = regexr(disease,"BULLOUS","BULLAE")
replace disease = regexr(disease,"BURNED","BURN")
replace disease = regexr(disease,"BURNS","BURN")
replace disease = regexr(disease,"BURNT","BURN")
replace disease = regexr(disease,"BURSAE","BURSA")
replace disease = regexr(disease,"BURSAL","BURSA")
replace disease = regexr(disease,"BUTLOCK","BUTTOCK")
replace disease = regexr(disease,"BUTTACK","BUTTOCK")

replace disease = regexr(disease,"CALCANEOUS","CALCANEUS")
replace disease = regexr(disease,"CALCULAR","CALCULUS")
replace disease = regexr(disease,"CALCULI$","CALCULUS")
replace disease = regexr(disease,"CALCULUS VE[A|S]$","CALCULUS VESICA")
replace disease = regexr(disease,"CALVES","CALF")
replace disease = regexr(disease,"CAN ORIS","CANCRUM")
replace disease = regexr(disease,"CANCRUM","CANCRUM ORIS") if regexm(disease,"ORIS")==0
replace disease = regexr(disease,"CANES SPINE","CARIES SPINE")
replace disease = regexr(disease,"CAP(ILL)* BRONCH","CAPILLARY BRONCH")
replace disease = regexr(disease,"CAPITUS","CAPITIS")
replace disease = regexr(disease,"CARB ACID","CARBOLIC ACID")
replace disease = regexr(disease,"CARBUNELE","CARBUNCLE")
replace disease = regexr(disease,"CARCIN ","CARCINOMA")
replace disease = regexr(disease,"CARARRH","CATARRH")
replace disease = regexr(disease,"CARITITIS","CARDITIS")
replace disease = regexr(disease,"CAT PNEU","CAPILLARY PNEU")
replace disease = regexr(disease,"CATAR$","CATARACT")
replace disease = regexr(disease,"CATARCH","CATARRH")
replace disease = regexr(disease,"CATARRHAL","CATARRH")
replace disease = regexr(disease,"CATARACT RDRT$","CATARACT RIGHT EYE")
replace disease = regexr(disease,"CATCT","CATARACT")
replace disease = regexr(disease,"CATHER","CATHETER")
replace disease = regexr(disease,"CAUSE(D)*","")
replace disease = regexr(disease,"CAXAE","COXAE")
replace disease = regexr(disease,"CEA HIP","CONGENITAL HIP")
replace disease = regexr(disease,"CEDENIA","EDEMA")
replace disease = regexr(disease,"CELEFT PALATE","CLEFT PALATE")
replace disease = regexr(disease,"CELFT","CLEFT")
replace disease = regexr(disease,"CELLULO ","CELLULITIS ")
replace disease = regexr(disease,"CELLUTITIS","CELLULITIS")
replace disease = regexr(disease,"CENTR NERV SYSTEM","NERVE")
replace disease = regexr(disease,"CEPHAL$","CEPHALALGIA")
replace disease = regexr(disease,"CEPHALAGIA","CEPHALALGIA")
replace disease = regexr(disease,"CEPHALGIA","CEPHALALGIA")
replace disease = regexr(disease,"CEREBELLA ","CEREBELLUM ")
replace disease = regexr(disease,"CEREBELLAR","CEREBELLUM")
replace disease = regexr(disease,"CEREBIC$","CEREBRAL")
replace disease = regexr(disease,"CEREBR[I|O] ","CEREBRAL ")
replace disease = regexr(disease,"CEREBRI$","CEREBRAL")
replace disease = regexr(disease,"CERV ","CERVIX")
replace disease = regexr(disease,"CERVICAL","CERVIX")
replace disease = regexr(disease,"CERVICATIS","CERVICITIS")
replace disease = regexr(disease,"CERVICODORSUM","CERVICODORSAL")
replace disease = regexr(disease,"CHECK","CHEEK")
replace disease = regexr(disease,"CHEIROPOMPHYLAX","CHEIROPOMPHOLYX")
replace disease = regexr(disease,"CHESTWALL","CHEST WALL")
replace disease = regexr(disease,"CHICKEN POCK","CHICKEN POX")
replace disease = regexr(disease,"CHOEA","CHOREA")
replace disease = regexr(disease,"CHONDRONA","CHONDROMA")
replace disease = regexr(disease,"CHORCA","CHOREA")
replace disease = regexr(disease,"CHOREAH","CHOREA")
replace disease = regexr(disease,"CHOREIC","CHOREA")
replace disease = regexr(disease,"CHORES$","CHOREA")
replace disease = regexr(disease,"CHORIA","CHOREA")
replace disease = regexr(disease,"CHORIDITIS","CHOROIDITIS")
replace disease = regexr(disease,"CHOROIDO RETINITIS","CHORIORETINITIS")
replace disease = regexr(disease,"CHR ","CHRONIC")
replace disease = regexr(disease,"CHRON ","CHRONIC ")
replace disease = regexr(disease,"CHRONICABS","CHRONIC ABS")
replace disease = regexr(disease,"CHRONIS PURALENT","CHRONIC PURULENT")
replace disease = regexr(disease,"CIXA$","COXAE")
replace disease = regexr(disease,"CICATRICIAL","CICATRIX")
replace disease = regexr(disease,"CLA FRAC","CLAVICLE FRAC")
replace disease = regexr(disease,"CLADDER","BLADDER")
replace disease = regexr(disease,"CLEFF","CLEFT")
replace disease = regexr(disease,"CLEFT BLATE","CLEFT PALATE")
replace disease = regexr(disease,"CLEFT PAL$","CLEFT PALATE")
replace disease = regexr(disease,"CLEFT PAL ","CLEFT PALATE ")
replace disease = regexr(disease,"CLIARY","CILIARY")
replace disease = regexr(disease,"CLIFT","CLEFT")
replace disease = regexr(disease,"COLD ABS","OLD ABS")
replace disease = regexr(disease,"COLD AMPUT","OLD AMPUT")
replace disease = regexr(disease,"COLLAPSE LUNG","COLLAPSED LUNG")
replace disease = regexr(disease,"COLLAPSED","COLLAPSE") if regexm(disease,"LUNG")==0
replace disease = regexr(disease,"COLLAR BONE","COLLARBONE")
replace disease = regexr(disease,"COMFRD ","COMPOUND ")
replace disease = regexr(disease,"COMPD TR ","COMPOUND FRACTURE ")
replace disease = regexr(disease,"COMP FACT","COMPOUND FRACTURE")
replace disease = regexr(disease,"COMP FRAC","COMPOUND FRAC")
replace disease = regexr(disease,"COMPD TR ","COMPOUND FRACTURE ")
replace disease = regexr(disease,"COMPR FRAC","COMPRESSION FRAC")
replace disease = regexr(disease,"COMPT FR","COMPOUND FR")
replace disease = regexr(disease,"CON SPINE","CURVATURE SPINE")
replace disease = regexr(disease,"CON SYP[H|T]","CONGENITAL SYPH")
replace disease = regexr(disease,"CONC(O)*(M|N)* ","CONCOMITANT ")
replace disease = regexr(disease,"CONJUNCTIVAL","CONJUNCTIVA")
replace disease = regexr(disease,"CONCESSION(S)*","CONCUSSION")
replace disease = regexr(disease,"CONCLUSION(S)*","CONCUSSION")
replace disease = regexr(disease,"CONCULSIONS","CONCUSSION")
replace disease = regexr(disease,"CONCUSS ","CONCUSSION ")
replace disease = regexr(disease,"CONCUSS$","CONCUSSION")
replace disease = regexr(disease,"CONCUSSSION","CONCUSSION")
replace disease = regexr(disease,"CONDY CORNUTA","CONDYLOMATA")
replace disease = regexr(disease,"CONESM CONV","CONCOMITANT CONV")
replace disease = regexr(disease,"CONG(N)*(T)*(L)* ","CONGENITAL ")
replace disease = regexr(disease,"CONG(T)*$","CONGENITAL")
replace disease = regexr(disease,"CONGENITALIS","CONGENITAL")
replace disease = regexr(disease,"CONGEN(T)*(L)* ","CONGENITAL ")
replace disease = regexr(disease,"CONGENITALDISLOC","CONGENITAL DISLOCATION")
replace disease = regexr(disease,"CONGENTIAL","CONGENITAL")
replace disease = regexr(disease,"CONGEST ","CONGESTION ")
replace disease = regexr(disease,"CONGESTED","CONGESTION")
replace disease = regexr(disease,"CONGESTED","CONGESTION")
replace disease = regexr(disease,"CONGINGUINAL","CONGENITAL INGUINAL")
replace disease = regexr(disease,"CONICAL CORNEA","KERATOCONUS")
replace disease = regexr(disease,"CONJ SYPH","CONGENITAL SYPH")
replace disease = regexr(disease,"CONJ(U)*(N*) ","CONJUNCTIVITIS ")
replace disease = regexr(disease,"CONJ(U|I)*(N)*(C)*(T)*(V)*(L)*(S)*$","CONJUNCTIVITIS")
replace disease = regexr(disease,"CONJEN LYPH$","CONGENITAL SYPHILIS")
replace disease = regexr(disease,"CONJEN ","CONGENITAL ")
replace disease = regexr(disease,"CONJU(N)*CTIVA","CONJUNCTIVITIS")
replace disease = regexr(disease,"CONJUNCTIVITIES","CONJUNCTIVITIS")
replace disease = regexr(disease,"CONREAL","CORNEA")
replace disease = regexr(disease,"CONS STRAB","CONCOMITANT CONVERGENT STRAB")
replace disease = regexr(disease,"CONSEM CONVERG STRAB","CONCOMITANT CONVERGENT STRAB")
replace disease = regexr(disease,"CONSEQUENT VACCIN","")
replace disease = regexr(disease,"CONSOL(I)*(D)*(AT)* ","CONSOLIDATION ")
replace disease = regexr(disease,"CONSOLD$","CONSOLIDATION")
replace disease = regexr(disease,"CONSOLIDATED","CONSOLIDATION")
replace disease = regexr(disease,"CONSOLIDAT$","CONSOLIDATION")
replace disease = regexr(disease,"CONSTIP$","CONSTIPATION")
replace disease = regexr(disease,"CONTD ","CONTINUED ")
replace disease = regexr(disease,"CONTINUA","CONTINUED")
replace disease = regexr(disease,"CONTISIONS","CONTUSION")
replace disease = regexr(disease,"CONTN ","CONTUSSION ")
replace disease = regexr(disease,"CONTN$","CONTUSSION")
replace disease = regexr(disease,"CONTR$","CONTRACTION")
replace disease = regexr(disease,"CONTR(ACT)* ","CONTRACTION ")
replace disease = regexr(disease,"CONTRACT$","CONTRACTURE")
replace disease = regexr(disease,"CONTRACTD","CONTRACTURE")
replace disease = regexr(disease,"CONTRACTED","CONTRACTION")
replace disease = regexr(disease,"CONTUSED","CONTUSION")
replace disease = regexr(disease,"CONTUSSION","CONTUSION")
replace disease = regexr(disease,"CONV(E)*(R)*(G)*(T)* ","CONVERGENT ")
replace disease = regexr(disease,"CONVENGT","CONVERGENT")
replace disease = regexr(disease,"CONVERSIONS","CONVULSIONS")
replace disease = regexr(disease,"CONVULS$","CONVULSIONS")
replace disease = regexr(disease,"CONVULSIVE","CONVULSIONS")
replace disease = regexr(disease,"CORCUMERSION","CIRCUMCISION")
replace disease = regexr(disease,"CORE SYPH","CONGENITAL SYPH")
replace disease = regexr(disease,"CORES SPINE","CARIES SPINE")
replace disease = regexr(disease,"CORIDS","CORDIS")
replace disease = regexr(disease," COR DEVIATION"," CORNEAL DEVIATION")
replace disease = regexr(disease,"CORNIAL","CORNEAL")
replace disease = regexr(disease,"CORNEA RE$","CORNEA RIGHT")
replace disease = regexr(disease,"CORPORI$","CORPORIS")
replace disease = regexr(disease,"COSOLIDATION","CONSOLIDATION")
replace disease = regexr(disease,"COXA VERA","COXA VARA")
replace disease = regexr(disease,"COXAVARA","COXA VARA")
replace disease = regexr(disease,"COXOE","COXAE")
replace disease = regexr(disease,"CRASHED","CRUSHED")
replace disease = regexr(disease,"CRETIN(S)*$","CRETINISM")
replace disease = regexr(disease,"CROKED","CROOKED")
replace disease = regexr(disease,"CROOKED LED","CROOKED LEG")
replace disease = regexr(disease,"CROUPOUS","CROUP")
replace disease = regexr(disease,"CRUEL","CRUSHED")
replace disease = regexr(disease,"CRUISE(D|S)","CRUSHED")
replace disease = regexr(disease,"CRUSH$","CRUSHED")
replace disease = regexr(disease,"CRUSH$","CRUSHED")
replace disease = regexr(disease,"CRUSH$","CRUSHED")
replace disease = regexr(disease,"CRUSHD","CRUSHED")
replace disease = regexr(disease,"CRYPTORCHID$","CRYPTORCHIDISM")
replace disease = regexr(disease,"CUMATINE","CURVATURE")
replace disease = regexr(disease,"CURNS","BURNS")
replace disease = regexr(disease,"CURSA","BURSA")
replace disease = regexr(disease,"CURV ","CURVATURE ")
replace disease = regexr(disease,"CURVAT(R)* ","CURVATURE ")
replace disease = regexr(disease,"CURVAT(UR)*$","CURVATURE")
replace disease = regexr(disease,"CURVE(D)*$","CURVATURE")
replace disease = regexr(disease,"CUSHED","CRUSHED")
replace disease = regexr(disease,"CUT LEAD","CUT HEAD")
replace disease = regexr(disease,"CALANEOUS","CALCANEUS")

replace disease = regexr(disease,"DBL(E)*","DOUBLE") if regexm(disease,"ABDL")==0 & regexm(disease,"ADBL")==0
replace disease = regexr(disease,"DEAF ","DEAFNESS")
replace disease = regexr(disease,"DEAFINITE","DEAF EAR")
replace disease = regexr(disease,"DEARRHOEA","DIARRHEA")
replace disease = regexr(disease,"DEBELITY","DEBILITY")
replace disease = regexr(disease,"DECEASED HIP","DISEASE HIP")
replace disease = regexr(disease,"DEFOMITY","DEFORMITY")
replace disease = regexr(disease,"DEFORMED","DEFORMITY")
replace disease = regexr(disease,"DELIRIOUS","DELIRIUM")
replace disease = regexr(disease,"DEPHTH$","DIPHTHERIA")
replace disease = regexr(disease,"DEPHTHERIA","DIPHTHERIA")
replace disease = regexr(disease,"DEPRESSED","DEPRESSION")
replace disease = regexr(disease,"DERANGEM ","DERANGEMENT ")
replace disease = regexr(disease,"DESGUA$","DESQUAMATION")
replace disease = regexr(disease,"DESGUA(M)* ","DESQUAMATION ")
replace disease = regexr(disease,"DESQUA(M)* ","DESQUAMATION ")
replace disease = regexr(disease,"DETACHED","DETACHMENT")
replace disease = regexr(disease,"DETACHM ","DETACHMENT ")
replace disease = regexr(disease,"DETACHM$","DETACHMENT")
replace disease = regexr(disease,"DEVAITED","DEVIATION")
replace disease = regexr(disease,"DEVIAT ","DEVIATION ")
replace disease = regexr(disease,"DEVIAT$","DEVIATION")
replace disease = regexr(disease,"DEVIAT$","DEVIATION")
replace disease = regexr(disease,"DEVIATED","DEVIATION")
replace disease = regexr(disease,"DIABETS","DIABETES")
replace disease = regexr(disease,"DIAPHRAGMATIC","DIAPHRAGM")
replace disease = regexr(disease,"DIARREAHEA","DIARRHEA")
replace disease = regexr(disease,"DIARRH ","DIARRHEA ")
replace disease = regexr(disease,"DIARRH$","DIARRHEA")
replace disease = regexr(disease,"DIARRHAEA","DIARRHEA")
replace disease = regexr(disease,"DIARRHEA D$","DIARRHEA")
replace disease = regexr(disease,"DIARRHOEA","DIARRHEA")
replace disease = regexr(disease,"DIARRHOES","DIARRHEA")
replace disease = regexr(disease,"DIARROHEA","DIARRHEA")
replace disease = regexr(disease,"DIARROHOEA","DIARRHEA")
replace disease = regexr(disease,"DIATATIS","DIASTASIS")
replace disease = regexr(disease,"DIFFICULT ","DIFFICULTY ")
replace disease = regexr(disease,"DIFFUSE","DIFFUSION")
replace disease = regexr(disease,"DIL SLOULDER","DISLOCATION SHOULDER")
replace disease = regexr(disease,"DILALATION","DILATATION")
replace disease = regexr(disease,"DILATATIS VENTRICULI","DILATION VENTRICLE")
replace disease = regexr(disease,"DILATED","DILATION")
replace disease = regexr(disease,"DIPH ","DIPHTHERIA ")
replace disease = regexr(disease,"DIPH(TH)*(C)* ","DIPHTHERIA ")
replace disease = regexr(disease,"DIPHERIA","DIPHTHERIA")
replace disease = regexr(disease,"DIPHTH$","DIPHTHERIA")
replace disease = regexr(disease,"DIPHTHER(C)* ","DIPHTHERIA ")
replace disease = regexr(disease,"DIPHTHERC$","DIPHTHERIA")
replace disease = regexr(disease,"DIPHTHERITIC","DIPHTHERIA")
replace disease = regexr(disease,"DIPHTHERITIC","DIPHTHERIA")
replace disease = regexr(disease,"DIPHTHERITIS","DIPHTHERIA")
replace disease = regexr(disease,"DIPHTHERIAL","DIPHTHERIA")
replace disease = regexr(disease,"DIPHTHONGS","DIPHTHERIA")
replace disease = regexr(disease,"DIPTHER ","DIPHTHERIA ")
replace disease = regexr(disease,"DIPTHERIA","DIPHTHERIA")
replace disease = regexr(disease,"DIPTHERITIC ","DIPHTHERIA ")
replace disease = regexr(disease,"DISCASE ","DISEASE ")
replace disease = regexr(disease,"DISCASEAD","DISEASE")
replace disease = regexr(disease,"DISCH(ARG)* ","DISCHARGE")
replace disease = regexr(disease,"DISCHARGE FR ","DISCHARGE ")
replace disease = regexr(disease,"DISCHARGING","DISCHARGE")
replace disease = regexr(disease,"DISD ","DISEASE ")
replace disease = regexr(disease,"DISEAS$","DISEASE")
replace disease = regexr(disease,"DISEASED","DISEASE")
replace disease = regexr(disease,"DISL(O)*(C)*(A)*(T)*(N)* ","DISLOCATION ")
replace disease = regexr(disease,"DISLOC ","DISLOCATION")
replace disease = regexr(disease,"DISLOCATED","DISLOCATION")
replace disease = regexr(disease,"DISLOCATED","DISLOCATION")
replace disease = regexr(disease,"DISLOCATED","DISLOCATION")
replace disease = regexr(disease,"DISLOE ","DISLOCATION ")
replace disease = regexr(disease,"DISPLACED","DISPLACEMENT")
replace disease = regexr(disease,"DISPLACEMT","DISPLACEMENT")
replace disease = regexr(disease,"DISSEM ","DISSEMINATED ")
replace disease = regexr(disease,"DISSEMMATED","DISSEMINATED")
replace disease = regexr(disease,"DISSEMT ","DISSEMINATED ")
replace disease = regexr(disease,"DIST HIP","DISEASE HIP")
replace disease = regexr(disease,"DISTEN[T|D]$","DISTENSION")
replace disease = regexr(disease,"DISTENDED","DISTENSION")
replace disease = regexr(disease,"DISTENT ","DISTENSION")
replace disease = regexr(disease,"DISTORTED","DISTORTION")
replace disease = regexr(disease,"DIV(D)* ","DIVIDED ")
replace disease = regexr(disease,"DIVISION","DIVIDED")
replace disease = regexr(disease,"DORSAL","DORSUM")
replace disease = regexr(disease,"DROPPED HAND","WRIST DROP")
replace disease = regexr(disease,"DROSY SCARL$","DROPSY SCARLET FEVER")
replace disease = regexr(disease,"DRVIATED","DEVIATION")
replace disease = regexr(disease,"DUFFOCATION","SUFFOCATION")
replace disease = regexr(disease,"DULNESS","DULLNESS")
replace disease = regexr(disease,"DYSPNAEA","DYSPNEA")
replace disease = regexr(disease,"DYSPNOEA","DYSPNEA")
replace disease = regexr(disease,"DYSTICHIASIS","DISTICHIASIS")
replace disease = regexr(disease,"DYSPRICA","DYSPNEA")

replace disease = regexr(disease,"EARDES$","EAR")
replace disease = regexr(disease,"ECGEMA","ECZEMA")
replace disease = regexr(disease,"ECT(R)*OPI[A|O]N VES","ECTOPIA VES")
replace disease = regexr(disease,"ECTOPIA VESICA$","ECTOPIA VESICAE")
replace disease = regexr(disease,"ECYEMA","ECZEMA")
replace disease = regexr(disease,"ECZIMA","ECZEMA")
replace disease = regexr(disease,"EDEMATOUS","EDEMA") if regexm(disease,"LARYNGITIS")==0
replace disease = regexr(disease,"EDROPION","ECTROPION")
replace disease = regexr(disease,"EFF(U)*(N)*(S)* ","EFFUSION")
replace disease = regexr(disease,"EFF(U)*(S)*(N)*$","EFFUSION")
replace disease = regexr(disease,"EFF(U|I)S(S)*ION","EFFUSION")
replace disease = regexr(disease,"EFFUS ","EFFUSION ")
replace disease = regexr(disease,"ELLOW","ELBOW")
replace disease = regexr(disease,"EMPTY EMA","EMPYEMA")
replace disease = regexr(disease,"EMPYAEMA","EMPYEMA")
replace disease = regexr(disease,"EMPYENIA","EMPYEMA")
replace disease = regexr(disease,"EMPYOEMA","EMPYEMA")
replace disease = regexr(disease,"EMPYMEA","EMPYEMA")
replace disease = regexr(disease,"ENCHONDROMETA","ENCHONDROMA")
replace disease = regexr(disease,"ENL(G)*(D)* ","ENLARGEMENT ")
replace disease = regexr(disease,"ENLAG ","ENLARGEMENT ")
replace disease = regexr(disease,"ENLAR(G|J)(D)* ","ENLARGEMENT ")
replace disease = regexr(disease,"ENLARGED","ENLARGEMENT")
replace disease = regexr(disease,"ENLARGED","ENLARGEMENT")
replace disease = regexr(disease,"ENLARGEINT ","ENLARGEMENT ")
replace disease = regexr(disease,"ENLARGEM$","ENLARGEMENT")
replace disease = regexr(disease,"ENLARGMT ","ENLARGEMENT ")
replace disease = regexr(disease,"ENLARYRD ","ENLARGEMENT ")
replace disease = regexr(disease,"ENLAY(EM)* ","ENLARGEMENT ")
replace disease = regexr(disease,"ENLG ","ENLARGEMENT ")
replace disease = regexr(disease,"ENLS ","ENLARGEMENT ")
replace disease = regexr(disease,"ENT F$","ENTERIC FEVER")
replace disease = regexr(disease,"ENT FEV VELGASTRIC","ENTERIC FEVER GASTRIC")
replace disease = regexr(disease,"ENT(C)* FEVER","ENTERIC FEVER")
replace disease = regexr(disease,"ENTERICA","ENTERIC")
replace disease = regexr(disease,"ENTERICK","ENTERIC")
replace disease = regexr(disease,"ENTERICUS","ENTERIC")
replace disease = regexr(disease,"ENTERIC ","ENTERIC FEVER ") if regexm(disease,"FEVER")==0 & regexm(disease,"MESENTERIC")==0
replace disease = regexr(disease,"ENTERIC$","ENTERIC FEVER") if regexm(disease,"FEVER")==0 & regexm(disease,"MESENTERIC")==0
replace disease = regexr(disease,"ENTERITES","ENTERITIS")
replace disease = regexr(disease,"EPICOCELE","EPIPLOCELE")
replace disease = regexr(disease,"EPIDIDYIS","EPIDIDYMIS")
replace disease = regexr(disease,"EPIHYSITIS","EPIPHYSITIS")
replace disease = regexr(disease,"EPIDYDYMITIS","EPIDIDYMITIS")
replace disease = regexr(disease,"EPILEPT ","EPILEPSY ")
replace disease = regexr(disease,"EPILEPTIC$","EPILEPSY")
replace disease = regexr(disease,"EPILEPTIC ","EPILEPSY ")
replace disease = regexr(disease,"EPILEPTIFORM ","EPILEPSY ")
replace disease = regexr(disease,"EPISPODIAS","EPISPADIAS")
replace disease = regexr(disease,"EPISTASIS","EPISTAXIS")
replace disease = regexr(disease,"EQ VARUS","EQUINOVARUS")
replace disease = regexr(disease,"EQUI VARUS","EQUINOVARUS")
replace disease = regexr(disease,"EQUINO VARUS","EQUINOVARUS")
replace disease = regexr(disease,"EQUINUOVARUS","EQUINOVARUS")
replace disease = regexr(disease,"EQUINO ARMS","EQUINOVARUS")
replace disease = regexr(disease,"EQUINUS(O)*( )*VARUS","EQUINOVARUS")
replace disease = regexr(disease,"EQUINO VANES","EQUINOVARUS")
replace disease = regexr(disease,"EQUANUS","EQUINUS")
replace disease = regexr(disease,"ERBS PARALYSIS","ERBS PALSY PARALYSIS")
replace disease = regexr(disease,"ERYRIPELAS","ERYSIPELAS")
replace disease = regexr(disease,"ERYSIP ","ERYSIPELAS ")
replace disease = regexr(disease,"ERYSIPEALS","ERYSIPELAS")
replace disease = regexr(disease,"ERYSIPELA$","ERYSIPELAS")
replace disease = regexr(disease,"ERYSIPILAS","ERYSIPELAS")
replace disease = regexr(disease,"ERYSIPS$","ERYSIPELAS")
replace disease = regexr(disease,"ERISYPELAS","ERYSIPELAS")
replace disease = regexr(disease,"ERYTHEMATOUS","ERYTHEMA")
replace disease = regexr(disease,"ESSENTIAL PALSY","ESSENTIAL TREMOR PALSY")
replace disease = regexr(disease,"ETHMOIDAL","ETHMOID")
replace disease = regexr(disease,"ETTR BLADDER","EXTROVERTED BLADDER")
replace disease = regexr(disease,"EXCIS ","EXCISION ")
replace disease = regexr(disease,"EXCISED","EXCISION")
replace disease = regexr(disease,"EXCISSION","EXCISION")
replace disease = regexr(disease,"EXESTOSIS","EXOSTOSIS")
replace disease = regexr(disease,"EXISION","EXCISION")
replace disease = regexr(disease,"EXOPHTHALMIC","EXOPHTHALMOS")
replace disease = regexr(disease,"EXOSTOSES","EXOSTOSIS")
replace disease = regexr(disease,"EXT MALL","EXTERNAL MALL")
replace disease = regexr(disease,"EXT STRAB","EXTERNAL STRAB")
replace disease = regexr(disease,"EXTERNL","EXTERNAL")
replace disease = regexr(disease,"EXTRA OCULAR","EXTRAOCULAR")
replace disease = regexr(disease,"EXTRAV(AS)*$","EXTRAVASATION")
replace disease = regexr(disease,"EXTRAVAS(T)* ","EXTRAVASATION")
replace disease = regexr(disease,"EXTRAVERSION","EXTROVERSION")
replace disease = regexr(disease,"EXTROPION","ECTROPION")
replace disease = regexr(disease,"EXTROVER BLADDER","EXTROVERTED BLADDER")
replace disease = regexr(disease,"EYE BALL","EYEBALL")
replace disease = regexr(disease,"EYE LID","EYELID")
replace disease = regexr(disease,"EQUINT","SQUINT")
replace disease = regexr(disease,"EXOPHTHALMUS","EXOPHTHALMOS")

replace disease = regexr(disease,"FABRIS","FEBRIS")
replace disease = regexr(disease,"FACIAL","FACE")
replace disease = regexr(disease,"FACIEI","FACE")
replace disease = regexr(disease,"FAECAL","FECAL")
replace disease = regexr(disease,"FAECES","FECAL")
replace disease = regexr(disease,"FAINTING","FAINT")
replace disease = regexr(disease,"FAINTNESS","FAINT")
replace disease = regexr(disease,"FALL DOWN","FALL")
replace disease = regexr(disease,"FALLEN","FALL")
replace disease = regexr(disease,"FALL FR A ","FALL ")
replace disease = regexr(disease,"MEMBRANE FANCES","MEMBRANE FAUCES")
replace disease = regexr(disease,"FEBR[E|I]CULA","FEBRIS")
replace disease = regexr(disease,"FEBRIC ","FEVER ")
replace disease = regexr(disease,"FEBRILE","FEVER")
replace disease = regexr(disease,"FEVERISH","FEVER")
replace disease = regexr(disease,"FEVER TYPHOID","TYPHOID FEVER")
replace disease = regexr(disease,"FEET","FOOT")
replace disease = regexr(disease,"FEMORIS","FEMORAL")
replace disease = regexr(disease,"FESTULA","FISTULA")
replace disease = regexr(disease,"FIBRIS","FEBRIS")
replace disease = regexr(disease,"FIBRO ANGWMA","FIBROMYALGIA")
replace disease = regexr(disease,"FIBRO CELLULAR","FIBROUS CELLULAR")
replace disease = regexr(disease,"FISHTULA","FISTULA")
replace disease = regexr(disease,"FISTU$","FISTULA")
replace disease = regexr(disease,"FLAT FEET","FLAT FOOT")
replace disease = regexr(disease,"FLAT FOST","FLAT FOOT")
replace disease = regexr(disease,"FLEXED","FLEX")
replace disease = regexr(disease,"FOETID","FETID")
replace disease = regexr(disease,"FOETUS","FETUS")
replace disease = regexr(disease,"FOLLIC ","FOLLICULAR ")
replace disease = regexr(disease,"FOREMAN","FOREARM")
replace disease = regexr(disease,"FORHEAD","FOREHEAD")
replace disease = regexr(disease,"FR(E)*C(T)*(D)* ","FRACTURE ")
replace disease = regexr(disease,"FRAC(T)*(D)* ","FRACTURE ")
replace disease = regexr(disease,"FRAC(T)*(D)*$","FRACTURE")
replace disease = regexr(disease,"FRACT[C|E] ","FRACTURE ")
replace disease = regexr(disease,"FRACTIRED","FRACTURE")
replace disease = regexr(disease,"FRACTR ","FRACTURE ")
replace disease = regexr(disease,"FRACTURED","FRACTURE")
replace disease = regexr(disease,"FRASTURED","FRACTURE")
replace disease = regexr(disease,"FRAT HUMERUS","FRACTURE HUMERUS")
replace disease = regexr(disease,"FRATCTURE","FRACTURE")
replace disease = regexr(disease,"FRAUMATIC","TRAUMATIC")
replace disease = regexr(disease,"FRUNCT ","PUNCTURE ")
replace disease = regexr(disease,"FROST BITE","FROSTBITE")

replace disease = regexr(disease,"GALL STONES","GALLSTONE")
replace disease = regexr(disease,"GANGRENOSA","GANGRENE")
replace disease = regexr(disease,"GANGRENOUS","GANGRENE")
replace disease = regexr(disease,"GASTIC","GASTRIC")
replace disease = regexr(disease,"GASTRO ENTERIC","GASTROENTERITIS")
replace disease = regexr(disease,"GASTRO ENTERITIS","GASTROENTERITIS")
replace disease = regexr(disease,"GASTRODINIA","GASTRODYNIA")
replace disease = regexr(disease,"GENITAL ORGANS","GENITALIA")
replace disease = regexr(disease,"GENN VALGUM","GENU VALGUM")
replace disease = regexr(disease,"GENU VALG$","GENU VALGUM")
replace disease = regexr(disease,"GENU VARINO","GENU VARUM")
replace disease = regexr(disease,"GENU VARUS","GENU VARUM")
replace disease = regexr(disease,"GENU VULG[U|A]M","GENU VALGUM")
replace disease = regexr(disease,"GEUN VALGUM","GENU VALGUM")
replace disease = regexr(disease,"GLADS","GLAND")
replace disease = regexr(disease,"GLANDE","GLAND")
replace disease = regexr(disease,"GLANDULAR","GLAND")
replace disease = regexr(disease,"GLANS","GLAND")
replace disease = regexr(disease,"GLANCOMA","GLAUCOMA")
replace disease = regexr(disease,"GLAUCOMATOUS","GLAUCOMA")
replace disease = regexr(disease,"GLDS","GLANDS")
replace disease = regexr(disease,"GLUTEAL","GLUTEUS")
replace disease = regexr(disease,"GLYOMA","GLIOMA")
replace disease = regexr(disease,"GONORRH$","GONORRHEA")
replace disease = regexr(disease,"GONORRH(O)*EA(L)*","GONORRHEA")
replace disease = regexr(disease,"GONORRHEAD","GONORRHEA")
replace disease = regexr(disease,"GRAN(ULA)*(R)* LIDS","GRANULAR OPHTHALMIA")
replace disease = regexr(disease,"GRANULAR CONJ","GRANULAR OPHTHALMIA CONJ")
replace disease = regexr(disease,"GRANULAR OPHTHAL$","GRANULAR OPHTHALMIA")
replace disease = regexr(disease,"GRANULOMA ","GRANULOMATOSIS")
replace disease = regexr(disease,"GRAVEL","GRAVES")
replace disease = regexr(disease,"GRAZING","GRAZE")
replace disease = regexr(disease,"GREEN VALGUM","GENU VALGUM")
replace disease = regexr(disease,"GUN SHOT","GUNSHOT")
replace disease = regexr(disease,"GUMMA","GUMMA")
replace disease = regexr(disease,"GUMMATOUS","GUMMA")

replace disease = regexr(disease,"HAEMATURIA","HEMATURIA")
replace disease = regexr(disease,"HAIRLIP","HARELIP")
replace disease = regexr(disease,"HAL(L)*UX VARUS","HALLUX VALGUS")
replace disease = regexr(disease,"HALF PENNY","HALFPENNY")
replace disease = regexr(disease,"HALLER VALGUS","HALLUX VALGUS")
replace disease = regexr(disease,"HALLER VULGUS","HALLUX VALGUS")
replace disease = regexr(disease,"HAM$","HAMSTRING")
replace disease = regexr(disease,"HAMERAS","HUMERUS")
replace disease = regexr(disease,"HANLIP","HARELIP")
replace disease = regexr(disease,"HARE LIP","HARELIP")
replace disease = regexr(disease,"HEMATURE$","HEMATURIA")
replace disease = regexr(disease,"HEMOP$","HEMOPHILIA")
replace disease = regexr(disease,"HEMOPHILIC","HEMOPHILIA")
replace disease = regexr(disease,"HEMOR$","HEMORRHAGE")
replace disease = regexr(disease,"HEMOR(R)* ","HEMORRHAGE ")
replace disease = regexr(disease,"HEMORRHAGIC$","HEMORRHAGE")
replace disease = regexr(disease,"HEMORHAGE","HEMORRHAGE")
replace disease = regexr(disease,"HEMORRH ","HEMORRHAGE ")
replace disease = regexr(disease,"HEMORRH$","HEMORRHAGE")
replace disease = regexr(disease,"HEMORRHAGICA","HEMORRHAGE")
replace disease = regexr(disease,"HEMORRHC ","HEMORRHAGE ")
replace disease = regexr(disease,"HEPAT$","HEPATITIS")
replace disease = regexr(disease,"HERATITIS","HEPATITIS")
replace disease = regexr(disease,"HEREDTY","HEREDITARY")
replace disease = regexr(disease,"HERNIATED","HERNIA")
replace disease = regexr(disease,"HERNIAL","HERNIA")
replace disease = regexr(disease,"HERINA$","HERNIA")
replace disease = regexr(disease,"HEYSTERIA","HYSTERIA")
replace disease = regexr(disease,"HIGH TEMP","FEVER")
replace disease = regexr(disease,"HIP JNT$","HIP JOINT")
replace disease = regexr(disease,"HIP JOIN ","HIP JOINT ")
replace disease = regexr(disease,"HIP JR ","HIP JOINT ")
replace disease = regexr(disease,"HODGKIN S","HODGKINS")
replace disease = regexr(disease,"HT MURMUR","HEART MURMUR")
replace disease = regexr(disease,"HUMERAS","HUMERUS")
replace disease = regexr(disease,"HUMERI","HUMERUS")
replace disease = regexr(disease,"HYDATED","HYDATID")
replace disease = regexr(disease,"HYDROCE(PH)*$","HYDROCEPHALUS")
replace disease = regexr(disease,"HYDROCELE F HERNIA","HYDROCELE HERNIA")
replace disease = regexr(disease,"HYDROCEPH ","HYDROCEPHALUS ")
replace disease = regexr(disease,"HYDROCEPHALY","HYDROCEPHALUS")
replace disease = regexr(disease,"HYDROCLE","HYDROCELE")
replace disease = regexr(disease,"HYDROP(S)*$","HYDROPS ARTICULI")
replace disease = regexr(disease,"HYDROPERITONEUM","ASCITES")
replace disease = regexr(disease,"HYDROPTORIC","DIHYDROPTERORIC")
replace disease = regexr(disease,"HYPERAEMIA","HYPEREMIA")
replace disease = regexr(disease,"HYPERMETROPIC","HYPERMETROPIA")
replace disease = regexr(disease,"HYPERTROP(H)*(IED)* ","HYPERTROPHY")
replace disease = regexr(disease,"HYPERTROPHIC","HYPERTROPHY")
replace disease = regexr(disease,"HYPETROPIA","HYPERMETROPIA")
replace disease = regexr(disease,"HYPHEMIA","HYPHEMA")
replace disease = regexr(disease,"HYPO SPADIAS","HYPOSPADIAS")
replace disease = regexr(disease,"HYPOEMIA","HYPHEMA")
replace disease = regexr(disease,"HYPOPHYON","HYPOPYON")
replace disease = regexr(disease,"HYPOPION","HYPOPYON")
replace disease = regexr(disease,"HYPOPY ","HYPOPYON ")
replace disease = regexr(disease,"HYPOSPADIA$","HYPOSPADIAS")
replace disease = regexr(disease,"HYPOSPADS","HYPOSPADIAS")
replace disease = regexr(disease,"HIBERCULATUS","TUBERCULAR")
replace disease = regexr(disease,"HUNTINGDON","HUNTINGTON")

replace disease = regexr(disease,"IIN","IN")
replace disease = regexr(disease,"ILL$","ILLNESS")
replace disease = regexr(disease,"INABITITY","INABILITY")
replace disease = regexr(disease,"INCO ORDINATION","INCOORDINATION")
replace disease = regexr(disease,"IMPACTED","IMPACTION")
replace disease = regexr(disease,"IMPERFECTLY","IMPERFECT")
replace disease = regexr(disease,"IMP ANUS","IMPERFORATE ANUS")
replace disease = regexr(disease,"IMPORF ANUS","IMPERFORATE ANUS")
replace disease = regexr(disease,"IMPAIRED","IMPAIRMENT")
replace disease = regexr(disease,"INCO(N)* URINE","INCONTINENCE")
replace disease = regexr(disease,"INCONT$","INCONTINENCE URINE")
replace disease = regexr(disease,"INF(E)*(C)*(T)*(N)*(D)* ","INFECTION ")
replace disease = regexr(disease,"INFANT ","INFANTILE ")
replace disease = regexr(disease,"INFECTIONS","INFECTION")
replace disease = regexr(disease,"INFECTIVE","INFECTION")
replace disease = regexr(disease,"INFL ","INFLAMMATION ")
replace disease = regexr(disease,"INFL(A)*(M)*$","INFLAMMATION")
replace disease = regexr(disease,"INFL(A)*(M)*(M)*(E)*(R)*(T)*(N)* ","INFLAMMATION ")
replace disease = regexr(disease,"INFL(T|D)(N)*","INFLAMMATION")
replace disease = regexr(disease,"INFLAM(N)* ","INFLAMMATION ")
replace disease = regexr(disease,"INFLAMATION","INFLAMMATION")
replace disease = regexr(disease,"INFLAMED","INFLAMMATION")
replace disease = regexr(disease,"INFLAMMATORY","INFLAMMATION")
replace disease = regexr(disease,"INFLM(TN)* ","INFLAMMATION ")
replace disease = regexr(disease,"INFEMT PARA","INFANTILE PARA")
replace disease = regexr(disease,"INF(R|Y)* ","INFECTION ")
replace disease = regexr(disease,"INGUNAL","INGUINAL")
replace disease = regexr(disease,"ING(D|R)* HERNIA","INGUINAL HERNIA")
replace disease = regexr(disease,"INGNG TOE","INGROWN TOE")
replace disease = regexr(disease,"INGY TOE","INGROWN TOE")
replace disease = regexr(disease,"INGR(G)* TOE","INGROWN TOE")
replace disease = regexr(disease,"INGRS TOE","INGROWN TOE")
replace disease = regexr(disease,"INGROW(G)* TOE","INGROWN TOE")
replace disease = regexr(disease,"INGROWING TOE","INGROWN TOE")
replace disease = regexr(disease,"INGROWING","INGROWN")
replace disease = regexr(disease,"INGY HIP","INJURY HIP")
replace disease = regexr(disease,"INGY BACK","INJURY BACK")
replace disease = regexr(disease,"INHALING","INHALATION")
replace disease = regexr(disease,"INJ ","INJURY ")
replace disease = regexr(disease,"INJ LEAD","INJURY HEAD")
replace disease = regexr(disease,"INJ(I)*(U|E)*(A)*(R|L)*(T)*(Y)*(S)* ","INJURY ")
replace disease = regexr(disease,"INJ(R)*(Y|I)*(S)*$","INJURY")
replace disease = regexr(disease,"INJD","INJURY")
replace disease = regexr(disease,"INJURED","INJURY")
replace disease = regexr(disease,"INJURIES","INJURY")
replace disease = regexr(disease,"INJURY LEAD","INJURY HEAD")
replace disease = regexr(disease,"INJY ","INJURY ")
replace disease = regexr(disease,"INJYURY","INJURY")
replace disease = regexr(disease,"INL PERITON","TUBERCULAR PERITON")
replace disease = regexr(disease,"INNERSIDE","INNER SIDE")
replace disease = regexr(disease,"INSENSIBLE","INSENSIBILITY")
replace disease = regexr(disease,"INTERCRANIAL","INTRACRANIAL")
replace disease = regexr(disease,"INTESTINAL AS$","INTESTINAL ABSCESS")
replace disease = regexr(disease,"INT SHABISMUS","INTERNAL STRABISMUS")
replace disease = regexr(disease,"INT STRATISMUS","INTERNAL STRABISMUS")
replace disease = regexr(disease,"INT SAPH","INTERNAL SAPH")
replace disease = regexr(disease,"INST KERA","INTERSTITIAL KERA")
replace disease = regexr(disease,"INT(D)*(ER)*(N)*(L)* STRAB","INTERNAL STRAB")
replace disease = regexr(disease,"INTERS(T)* KERA","INTERSTITIAL KERA")
replace disease = regexr(disease,"INTERS(T)* HERNIA","INTERSTITIAL HERNIA")
replace disease = regexr(disease,"INTERSTIT KERA","INTERSTITIAL KERA")
replace disease = regexr(disease,"INT SAP$","INTERNAL SAPHENOUS NERVE")
replace disease = regexr(disease,"INT SEMILUNAR","INTERNAL SEMILUNAR")
replace disease = regexr(disease,"INT INJ","INTERNAL INJ")
replace disease = regexr(disease,"INT BONE STRAB","INTERNAL BONE STRAB")
replace disease = regexr(disease,"INT KERA","INTERSTITIAL KERA")
replace disease = regexr(disease,"INTESTINE","INTESTINAL")
replace disease = regexr(disease,"INTERC ABSCESS","INTERCOSTAL ABSCESS")
replace disease = regexr(disease,"INTE COLIC","INTESTINAL COLIC")
replace disease = regexr(disease,"INTEST DISORDER","INTESTINAL DISORDER")
replace disease = regexr(disease,"INTEST OBS$","INTESTINAL OBSTRUCTION")
replace disease = regexr(disease,"INTES(T)* OBST$","INTESTINAL OBSTRUCTION")
replace disease = regexr(disease,"INTEST(L)* OBST","INTESTINAL OBST")
replace disease = regexr(disease,"INTEST KERA","INTERSTITIAL KERA")
replace disease = regexr(disease,"INTEST ULCER","INTESTINAL ULCER")
replace disease = regexr(disease,"INTL MALEOLUS","ANKLE MALLEOLUS")
replace disease = regexr(disease,"INTRACRANIAL HUMOUR","INTRACRANIAL TUMOUR")
replace disease = regexr(disease,"INT SQUINT","INTERMITTENT SQUINT")
replace disease = regexr(disease,"INT SEQUINE","INTERMITTENT SQUINT")
replace disease = regexr(disease,"INT DER","INTERNAL DER")
replace disease = regexr(disease,"INT ING","INTERNAL ING")
replace disease = regexr(disease,"INTUSP$","INTUSSUSCEPTION")
replace disease = regexr(disease,"INY$","INJURY")
replace disease = regexr(disease,"INUP HIP","INCIPIENT HIP")
replace disease = regexr(disease,"INCIPT HIP","INCIPIENT HIP")
replace disease = regexr(disease,"IRRITABILITY","IRRITATION")
replace disease = regexr(disease,"INTRACRAN ","INTRACRANIAL ")
replace disease = regexr(disease,"INTRA CRAN","INTRACRAN")
replace disease = regexr(disease,"INURY HAND","INJURY HAND")
replace disease = regexr(disease,"FALL INY ","FALL INJURY ")
replace disease = regexr(disease,"INY HERNIA","INGUINAL HERNIA")
replace disease = regexr(disease,"INYD LEG","INJURY LEG")
replace disease = regexr(disease,"INYR NECK","INJURY NECK")
replace disease = regexr(disease,"IRRITABLE","IRRITATION")
replace disease = regexr(disease,"IRRIT ","IRRITATION ")
replace disease = regexr(disease,"IRRITAT$","IRRITATION")
replace disease = regexr(disease,"IRRED ","IRREDUCIBLE ")
replace disease = regexr(disease,"ISCHIS RECT","ISCHIORECT")
replace disease = regexr(disease,"ISCH REC(T|K)*","ISCHIORECT")
replace disease = regexr(disease,"ISCHIO( )*RECT ","ISCHIORECTAL ")
replace disease = regexr(disease,"I(V|R)*Y LEG","INJURY LEG")
replace disease = regexr(disease,"IRITS$","IRRITATION")
replace disease = regexr(disease,"INTL HAND","INFLAMMATION HAND")
replace disease = regexr(disease,"INTESL HOSMONLAGE","INTESTINAL HEMORRHAGE")
replace disease = regexr(disease,"INTERMAT$","INTERMITTENT")
replace disease = regexr(disease,"IRITITIS","IRITIS")
replace disease = regexr(disease,"INTIA OCULAR","INTRAOCULAR")
replace disease = regexr(disease,"INTERS KWAITIES","INTERSTITIAL KERATITIS")
replace disease = regexr(disease,"ISCHAEMIC CONTRACTURE","ISCHEMIC CONTRACTURE")
replace disease = regexr(disease,"INTRO THORACIC","INTRATHORACIC")
replace disease = regexr(disease,"IMPARAS","IMPERFORATE ANUS")

replace disease = regexr(disease,"JOINTS RL ","JOINTS RIGHT LEG ")
replace disease = regexr(disease,"JACKSONIAN","JACKSON")
replace disease = regexr(disease,"JACTI EPI","JACKSON EPI")
replace disease = regexr(disease,"JAUNDISE","JAUNDICE")
replace disease = regexr(disease,"JAUD$","JAUNDICE")

replace disease = regexr(disease,"KERAPH$","KERATITIS")
replace disease = regexr(disease,"KERATITES","KERATITIS")
replace disease = regexr(disease,"KICK FR A ","KICK ")
replace disease = regexr(disease,"KWAITES","KERATITIS")
replace disease = regexr(disease,"KROCK KNEE","KNOCK KNEE")
replace disease = regexr(disease,"KIND(N)*EY","KIDNEY")

replace disease = regexr(disease,"LACH(RIMAL)* ABS","LACHRYMAL ABS")
replace disease = regexr(disease,"LACHRIMATION","LACHRYMATION")
replace disease = regexr(disease,"LACRIMAL","LACHRYMAL")
replace disease = regexr(disease,"LAC(E)*(R)*(D|T)*$","LACERATION")
replace disease = regexr(disease,"LAC(ER)*(A)*(T)*(D)* ","LACERATION ")
replace disease = regexr(disease,"LACD ","LACERATED")
replace disease = regexr(disease,"LACERATED","LACERATION")
replace disease = regexr(disease,"LACEST ","LACERATION ")
replace disease = regexr(disease,"LACL LEG","LACERATION LEG")
replace disease = regexr(disease,"LAFT","LEFT")
replace disease = regexr(disease,"LAMBAR","LUMBAR")
replace disease = regexr(disease,"LAMILLAR","LAMELLAR")
replace disease = regexr(disease,"LARY(N)*$","LARYNGITIS")
replace disease = regexr(disease,"LARYN OBS","LARYNGEAL OBS")
replace disease = regexr(disease,"LARYNG DIPH","LARYNGEAL DIPH")
replace disease = regexr(disease,"LARYNGISMUS STRID$","LARYNGISMUS STRIDULUS")
replace disease = regexr(disease,"LARYNGRAL","LARYNGEAL")
replace disease = regexr(disease,"LARYNIGITIS","LARYNGITIS")
replace disease = regexr(disease,"LARYNGITIS STRIDOR","LARYNGISMUS STRIDULUS")
replace disease = regexr(disease,"LARYNGITIS STRIDULUS","LARYNGISMUS STRIDULUS")
replace disease = regexr(disease,"LARYNGISI STRIDULAE","LARYNGISMUS STRIDULUS")
replace disease = regexr(disease,"LAT CURV","LATERAL CURV")
replace disease = regexr(disease,"LEADACHE","HEADACHE")
replace disease = regexr(disease,"LENCOMA","LEUCOMA")
replace disease = regexr(disease,"LENSES","LENS")
replace disease = regexr(disease,"LENCHSMIA","LEUKEMIA")
replace disease = regexr(disease,"LERNIA","HERNIA")
replace disease = regexr(disease,"LEUKAEMIA","LEUKEMIA")
replace disease = regexr(disease,"LEUCORRHOEA","LEUCORRHEA")
replace disease = regexr(disease,"LEU(K|C)*OMA(TA)*","LEUCOMA")
replace disease = regexr(disease,"LINEE","KNEE")
replace disease = regexr(disease,"LOSE POWER","LOSS POWER")
replace disease = regexr(disease,"LOWER END","LOWER-END")
replace disease = regexr(disease,"LOWER PART","LOWER")
replace disease = regexr(disease,"LRYNGITIS","LARYNGITIS")
replace disease = regexr(disease,"LUCRN ","ULCER ")
replace disease = regexr(disease,"LUMBER","LUMBAR")
replace disease = regexr(disease,"LUMERNS","HUMERUS")
replace disease = regexr(disease,"LUMERUS","HUMERUS")
replace disease = regexr(disease,"LYMPHANG$","LYMPHANGIOMA")
replace disease = regexr(disease,"LYMPHAGITIS","LYMPHANGITIS")
replace disease = regexr(disease,"LYMPHANGEIOMA","LYMPHANGIOMA")
replace disease = regexr(disease,"LYMPHSSARCOMA","LYMPHOSARCOMA")
replace disease = regexr(disease,"LYMPHS ","LYMPH ")
replace disease = regexr(disease,"LYMPHAH$","LYMPHADENOMA")
replace disease = regexr(disease,"LYMPH$","LYMPHADENOMA")
replace disease = regexr(disease,"LYMPHADENTITIS","LYMPHADENITIS")

replace disease = regexr(disease,"MAB UNITED","MALUNITED")
replace disease = regexr(disease,"INJURY MACHY","INJURY MACHINE")
replace disease = regexr(disease,"MAMMT ABSCESS","MAMMARY ABSCESS")
replace disease = regexr(disease,"MASTORD","MASTOID")
replace disease = regexr(disease,"MALIG(T)* ","MALIGNANT ")
replace disease = regexr(disease,"MALING ","MALIGNANT ")
replace disease = regexr(disease,"MALENA","MELANA")
replace disease = regexr(disease,"MARBUS","MORBUS")
replace disease = regexr(disease,"MARASUMUS","MARASMUS")
replace disease = regexr(disease,"MARBELLA","MORBILLI")
replace disease = regexr(disease,"MAST ABS","MASTOID ABS")
replace disease = regexr(disease,"MAST CELLS","MASTOID CELLS")
replace disease = regexr(disease,"MAST PROCESS","MASTOID PROCESS")
replace disease = regexr(disease,"M CORD","MORBUS CORD")
replace disease = regexr(disease,"M COX","MORBUS COX")
replace disease = regexr(disease,"MR CORD","MORBUS CORD")
replace disease = regexr(disease,"MRO CORD","MORBUS CORD")
replace disease = regexr(disease,"MR COX","MORBUS COX")
replace disease = regexr(disease,"M(OR)* C ","MORBUS CORDIS ")
replace disease = regexr(disease,"MALF(R)*ORMED","MALFORMATION")
replace disease = regexr(disease,"MALLEOLI","MALLEOLUS")
replace disease = regexr(disease,"MASTER L","MEASLES L")
replace disease = regexr(disease,"MASTOID CELL$","MASTOID CELLS")
replace disease = regexr(disease,"MASTOID MASTOID","MASTOID")
replace disease = regexr(disease,"MASTODITIS","MASTOIDITIS")
replace disease = regexr(disease,"MAX CORWELL","GENU VALGUM")
replace disease = regexr(disease,"MEALUS URINARIUS","MEATUS URINARIUS")
replace disease = regexr(disease,"MEATAL","MEATUS")
replace disease = regexr(disease,"MEASLER","MEASLES")
replace disease = regexr(disease,"MED NERVE","MEDIAN NERVE")
replace disease = regexr(disease,"MELUNUNITED","MALUNITED")
replace disease = regexr(disease,"MELAENA","MELANA")
replace disease = regexr(disease,"MELENA","MELANA")
replace disease = regexr(disease,"MEBRA(N)*(E)* ","MEMBRANOUS ")
replace disease = regexr(disease,"MENING(TS)*$","MENINGITIS")
replace disease = regexr(disease,"MENINGEAL","MENINGES")
replace disease = regexr(disease,"MENINGITES","MENINGITIS")
replace disease = regexr(disease,"MERASMUS","MARASMUS")
replace disease = regexr(disease,"METAL BONE","MEATUS")
replace disease = regexr(disease,"MICRO( )*CEPHALIC","MICROCEPHALY")
replace disease = regexr(disease,"MOB COR$","MORBUS CORDIS")
replace disease = regexr(disease,"MONORCHID","MONORCHISM")
replace disease = regexr(disease,"MORBILLA","MORBILLI")
replace disease = regexr(disease,"MORBIS","MORBUS")
replace disease = regexr(disease,"MOR COR","MORBUS COR")
replace disease = regexr(disease,"MOR CORD","MORBUS CORD")
replace disease = regexr(disease,"MORE COR","MORBUS COR")
replace disease = regexr(disease,"MOR COX(A|O|I)*(E)* ","MORBUS COXAE ")
replace disease = regexr(disease,"MOR COX(A|O|I)*(E)*$","MORBUS COXAE")
replace disease = regexr(disease,"MORB COX(A|O|I)*(E)* ","MORBUS COXAE ")
replace disease = regexr(disease,"MORB COX(A|O|I)*(E)*$","MORBUS COXAE")
replace disease = regexr(disease,"MORBUS COX(A|O|I)*(E)* ","MORBUS COXAE ")
replace disease = regexr(disease,"MORBUS COX(A|O|I)*(E)*$","MORBUS COXAE")
replace disease = regexr(disease,"MORBUS COR ","MORBUS CORDIS ")
replace disease = regexr(disease,"MORBUS CORD ","MORBUS CORDIS ")
replace disease = regexr(disease,"MORBUS COR(D)*$","MORBUS CORDIS")
replace disease = regexr(disease,"MORBUS CORP ","MORBUS CORPORIS ")
replace disease = regexr(disease,"MORBUS CORP$","MORBUS CORPORIS")
replace disease = regexr(disease,"MORBUS ADDOM$","MORBUS ABDOMINAL")
replace disease = regexr(disease,"MORRHAGIA","MENORRHAGIA")
replace disease = regexr(disease,"MORT THOR","MORBUS THOR")
replace disease = regexr(disease,"MORBELLI","MORBILLI")
replace disease = regexr(disease,"MORTILLI","MORBILLI")
replace disease = regexr(disease,"MOSTOID","MASTOID")
replace disease = regexr(disease,"MOTER BUS","MOTOR BUS")
replace disease = regexr(disease,"MOVRABLE","MOVABLE")
replace disease = regexr(disease,"MR CEREBRIS","MORBUS CEREBRIS")
replace disease = regexr(disease,"MU(C|E)(O|V) PUR(U|N)LENT(O)*","MUCOPURULENT")
replace disease = regexr(disease,"MUCO PAR ","MUCOPURULENT")
replace disease = regexr(disease,"MUSCULAR","MUSCLE")
replace disease = regexr(disease,"MYOPIA B E$","MYOPIA BOTH EYES")
replace disease = regexr(disease,"MUCOUS","MUCUS")
replace disease = regexr(disease,"METACARP ","METACARPUS ")
replace disease = regexr(disease,"METACARP$","METACARPUS")
replace disease = regexr(disease,"METACARPAL(S)*","METACARPUS")
replace disease = regexr(disease,"MUSCOLO","MUSCLES")
replace disease = regexr(disease,"MUSELES","MUSCLES")
replace disease = regexr(disease,"MYOPIC","MYOPIA")
replace disease = regexr(disease,"MYCTALOPIA","NYCTALOPIA")
replace disease = regexr(disease,"MYSTAGMUS","NYSTAGMUS")
replace disease = regexr(disease,"MUSCULO SPINAL","MUSCULOSPIRAL")
replace disease = regexr(disease,"MUTLIPLE","MULTIPLE")

replace disease = regexr(disease,"NAEVO ","NEVUS ")
replace disease = regexr(disease,"NAEVO","NEVUS")
replace disease = regexr(disease,"NAEVI ","NEVUS ")
replace disease = regexr(disease,"NAEVI$","NEVUS")
replace disease = regexr(disease,"NARESIS","PARESIS")
replace disease = regexr(disease,"NAREXIS","PARESIS")
replace disease = regexr(disease,"NAVUS ","NEVUS ")
replace disease = regexr(disease,"NAVUS$","NEVUS")
replace disease = regexr(disease,"NAEVUS ","NEVUS ")
replace disease = regexr(disease,"NAEVUS$","NEVUS")
replace disease = regexr(disease,"NCEROSIS","NECROSIS")
replace disease = regexr(disease,"NEC ","NECROSIS ")
replace disease = regexr(disease,"NECRONS$","NECROSIS")
replace disease = regexr(disease,"NEAVUS ","NEVUS ")
replace disease = regexr(disease,"NEAVUS$","NEVUS")
replace disease = regexr(disease,"NEUROTIC","NEUROSIS") if regexm(dis_orig,"GAIT")==0
replace disease = regexr(disease,"NAIL RUN","NAIL")
replace disease = regexr(disease,"NECROSED","NECROSIS")
replace disease = regexr(disease,"NECROSIS TEMPORAL FOSSA","NECROSIS INFRATEMPORAL FOSSA")
replace disease = regexr(disease,"NEPHRITIC ","NEPHRITIS ")
replace disease = regexr(disease,"NEPHIRITIS","NEPHRITIS")
replace disease = regexr(disease,"NECK RL$","NECK RIGHT")
replace disease = regexr(disease,"NEURSIS","NEUROSIS")
replace disease = regexr(disease,"NICROSIS","NECROSIS")
replace disease = regexr(disease,"NOEVUS","NEVUS")
replace disease = regexr(disease,"NOR CORP","MORBUS CORP")
replace disease = regexr(disease,"NOERVES","NERVES")
replace disease = regexr(disease,"NOCROSIS","NECROSIS")
replace disease = regexr(disease,"NUTRAL REGINGH","MITRAL REGURGITATION")

replace disease = regexr(disease,"OBSCTRUCTION","OBSTRUCTION")
replace disease = regexr(disease,"OBSTRUCTIVE","OBSTRUCTION")
replace disease = regexr(disease,"OBST(N|R)*(U)*(C)*(N|T)*$","OBSTRUCTION")
replace disease = regexr(disease,"OBSTRACTION","OBSTRUCTION")
replace disease = regexr(disease,"OBSTRICN$","OBSTRUCTION")
replace disease = regexr(disease,"OBSTRUCT$","OBSTRUCTION")
replace disease = regexr(disease,"OBSTRUCTED","OBSTRUCTION")
replace disease = regexr(disease,"OBSTN ","OBSTRUCTION ")
replace disease = regexr(disease,"OBSTRUC(T)* ","OBSTRUCTION ")
replace disease = regexr(disease,"OBSTRCUTION","OBSTRUCTION")
replace disease = regexr(disease,"OBSTCOTOMY","OSTEOTOMY")
replace disease = regexr(disease,"OCCIPATAL","OCCIPITAL")
replace disease = regexr(disease,"OCCLUDED","OCCLUSION")
replace disease = regexr(disease,"OCULI$","OCULUS")
replace disease = regexr(disease,"OCULORUM","OCULUS")
replace disease = regexr(disease,"ODEMATOUS","EDEMATOUS")
replace disease = regexr(disease,"OEDEMA","EDEMA")
replace disease = regexr(disease,"ODEMA","EDEMA")
replace disease = regexr(disease,"OEDOMA","EDEMA")
replace disease = regexr(disease,"OERTEBRAE","VERTEBRAE")
replace disease = regexr(disease,"OESOPH","ESOPH")
replace disease = regexr(disease,"OPACITIES","OPACITY")
replace disease = regexr(disease,"OPAQUE","OPAQUE CATARACT")
replace disease = regexr(disease,"OPTHALMIA","OPHTHALMIA")
replace disease = regexr(disease,"OPHC$","OPHTHALMIA")
replace disease = regexr(disease,"OPTH$","OPHTHALMIA")
replace disease = regexr(disease,"OPLT$","OPHTHALMIA")
replace disease = regexr(disease,"OPTHAL$","OPHTHALMIA")
replace disease = regexr(disease,"OPTHC$","OPHTHALMIA")
replace disease = regexr(disease,"OPTHT$","OPHTHALMIA")
replace disease = regexr(disease,"OPHTH ","OPHTHALMIA ")
replace disease = regexr(disease,"OPIS$","OPISTHOTONOS")
replace disease = regexr(disease,"OPISTHOTONUS","OPISTHOTONOS")
replace disease = regexr(disease,"OPISTHOTONIC","OPISTHOTONOS")
replace disease = regexr(disease,"ORBIT$","ORBITAL")
replace disease = regexr(disease,"OSTITIS","OSTEITIS")
replace disease = regexr(disease,"OTORRHOEA","OTORRHEA")
replace disease = regexr(disease,"OTTORRHOEA","OTORRHEA")
replace disease = regexr(disease,"OPHT ","OPHTHALMIA ")
replace disease = regexr(disease,"OPHT(H|C)*(A)*(L)*(A|C)*$","OPHTHALMIA")
replace disease = regexr(disease,"OPHTH(C|L)*(C)*$","OPHTHALMIA")
replace disease = regexr(disease,"OPH$","OPHTHALMIA")
replace disease = regexr(disease,"OPHTHT$","OPHTHALMIA")
replace disease = regexr(disease,"OPHTHALMIC(US)*$","OPHTHALMIA")
replace disease = regexr(disease,"OPHTHALMIC ","OPHTHALMIA ")
replace disease = regexr(disease,"ORTHC$","ORTHOPEDY")
replace disease = regexr(disease,"ORTHO$","ORTHOPEDY")
replace disease = regexr(disease,"ORTHOPADIE$","ORTHOPEDY")
replace disease = regexr(disease,"ORTHOPAEDIC$","ORTHOPEDY")
replace disease = regexr(disease,"ORTHOPED(I)*(C|E)*$","ORTHOPEDY")
replace disease = regexr(disease,"ORTHOPET","ORTHOPEDY")
replace disease = regexr(disease,"ORP$","ORTHOPEDY")
replace disease = regexr(disease,"ORTORRHOEA","OTORRHEA")
replace disease = regexr(disease,"OSEALCIS","OSCALCIS")
replace disease = regexr(disease,"OSTECTOMY","OSTEOTOMY")
replace disease = regexr(disease,"OSTEOCLASIS","OSTEOCLASIA")
replace disease = regexr(disease,"OSTEVTONEY","OSTEOTOMY") 
replace disease = regexr(disease,"OXILL ","AXILLA ")

replace disease = regexr(disease,"POST AURICULAR","POSTAURICULAR")
replace disease = regexr(disease,"PABELLA","PATELLA")
replace disease = regexr(disease,"PAINS","PAIN")
replace disease = regexr(disease,"PALETE","PALATE")
replace disease = regexr(disease,"PALMAR$","PALM$")
replace disease = regexr(disease,"PALMAR ","PALM ")
replace disease = regexr(disease,"PALMARIS LONGUE","PALMARIS LONGUS")
replace disease = regexr(disease,"PAPILLOMATA","PAPILLOMA")
replace disease = regexr(disease,"PAPILL ","PAPILLOMA")
replace disease = regexr(disease,"PAPILN ","PAPILLOMA")
replace disease = regexr(disease,"PAPILLOME ","PAPILLOMA")
replace disease = regexr(disease,"PARAFFIN PIL$","PARAFFIN POISONING")
replace disease = regexr(disease,"PARALY(S)*$","PARALYSIS")
replace disease = regexr(disease,"ANALYSIS","PARALYSIS")
replace disease = regexr(disease,"PARAPLEGEA","PARALYSIS")
replace disease = regexr(disease,"PAREVIS","PARESIS")
replace disease = regexr(disease,"PARAPHIMORIS","PARAPHIMOSIS")
replace disease = regexr(disease,"PARAPHYMOSIS","PARAPHIMOSIS")
replace disease = regexr(disease,"PARENCHYMATOUS","PARENCHYMA")
replace disease = regexr(disease,"PAR(A|C|E)*SIS","PARESIS")
replace disease = regexr(disease,"PARALY(TIC)* ","PARALYSIS ")
replace disease = regexr(disease,"PAROTIC","PAROTID")
replace disease = regexr(disease,"PARTL","PARTIAL")
replace disease = regexr(disease,"PATMAR","PALM")
replace disease = regexr(disease,"PARTIALLY","PARTIAL")
replace disease = regexr(disease,"PATELLAA","PATELLA")
replace disease = regexr(disease,"PAYREXIA","PYREXIA")
replace disease = regexr(disease,"PEARLATINA","SCARLET FEVER")
replace disease = regexr(disease,"PEMPHYGUS","PEMPHIGUS")
replace disease = regexr(disease,"PENILE","PENIS")
replace disease = regexr(disease,"PENUM","PNEUM")
replace disease = regexr(disease,"PERFORATING","PERFORATED")
replace disease = regexr(disease,"PERFORATIVE","PERFORATED")
replace disease = regexr(disease,"PERFORATION","PERFORATED")
replace disease = regexr(disease,"PERITONITIS E$","PERITONITIS")
replace disease = regexr(disease,"PENTONITIS","PERITONITIS")
replace disease = regexr(disease,"PERI NEPH","NEPH")
replace disease = regexr(disease,"PERICARDIAL","PERICARDIUM")
replace disease = regexr(disease,"PERICHONDRIAL","PERICHONDRIUM")
replace disease = regexr(disease,"PERINAEUM","PERINEUM")
replace disease = regexr(disease,"PERIN(O)*EAL","PERINEUM")
replace disease = regexr(disease,"PERINEPHRIHI","NEPHRITIS")
replace disease = regexr(disease,"PERIONITIS","PERITONITIS")
replace disease = regexr(disease,"PERIOSTEAL","PERIOSTEUM")
replace disease = regexr(disease,"PERIOSTITE","PERIOSTITIS")
replace disease = regexr(disease,"PERIOSTITUS","PERIOSTITIS")
replace disease = regexr(disease,"PERITONEAL","PERITONEUM")
replace disease = regexr(disease,"PERITYPHELITIS","PERITYPHLITIS")
replace disease = regexr(disease,"PERITYPHLYTIS","PERITYPHLITIS")
replace disease = regexr(disease,"PERTISIS","PERTUSSIS")
replace disease = regexr(disease,"PERTUSTIS","PERTUSSIS")
replace disease = regexr(disease,"PETRETIA","PYREXIA")
replace disease = regexr(disease,"PHAG(O|A)*DOEMIC","PHAGEDENIC")
replace disease = regexr(disease,"PHAGEDAENA","PHAGEDENIC")
replace disease = regexr(disease,"PHAGEDAENIC","PHAGEDENIC")
replace disease = regexr(disease,"PHAGEDOENA","PHAGEDENIC")
replace disease = regexr(disease,"PHAGADAENA","PHAGEDENIC")
replace disease = regexr(disease,"PHALANGES","PHALANX")
replace disease = regexr(disease,"PHAYRNX","PHARYNX")
replace disease = regexr(disease,"PHARNYX","PHARYNX")
replace disease = regexr(disease,"PHARYN$","PHARYNX")
replace disease = regexr(disease,"PHARYN(G)* ","PHARYNX ")
replace disease = regexr(disease,"PHARYN(G)*(L)*(EAL)*$","PHARYNGEAL")
replace disease = regexr(disease,"PHARYN(G)*(L)*(EAL)* ","PHARYNGEAL ")
replace disease = regexr(disease,"PHARANG","PHARYNG")
replace disease = regexr(disease,"PHIM$","PHIMOSIS")
replace disease = regexr(disease,"PHIMOS$","PHIMOSIS")
replace disease = regexr(disease,"PHLYC(T)* ","PHLYCTENULAR ")
replace disease = regexr(disease,"PHLYE ","PHLYCTENULAR ")
replace disease = regexr(disease,"PHGLEMON","PHLEGM")
replace disease = regexr(disease,"PH(E|O|Y)MOSIS","PHIMOSIS")
replace disease = regexr(disease,"PINCARDITIS","PANCARDITIS")
replace disease = regexr(disease,"PITYRIASIS RUBRA","PITYRIASIS")
replace disease = regexr(disease,"PLAM","PALM")
replace disease = regexr(disease,"PEUDO","PSEUDO")
replace disease = regexr(disease,"PLANTAR FASCIA$","PLANTAR FASCIITIS")
replace disease = regexr(disease,"PLASIC","PLASTIC")
replace disease = regexr(disease,"PLASTIC OP ","PLASTIC OPERATION ")
replace disease = regexr(disease,"PEURAL","PLEURAL")
replace disease = regexr(disease,"PLERUATIC","PLEURAL")
replace disease = regexr(disease,"PLEURATIC","PLEURAL")
replace disease = regexr(disease,"PLEURITIS","PLEURISY")
replace disease = regexr(disease,"PLEURO PNEU","PLEUROPNEU")
replace disease = regexr(disease,"PLUMEY","PENNY")
replace disease = regexr(disease,"PLEU(R)* EFF","PLEURAL EFF")
replace disease = regexr(disease,"PLEURITIC EFF","PLEURAL EFF")
replace disease = regexr(disease,"PLEURISM","PLEURAL EFFUSION")
replace disease = regexr(disease,"PLEURO EFF","PLEURAL EFF")
replace disease = regexr(disease,"PLEN EFF","PLEURAL EFF")
replace disease = regexr(disease,"PLEW EFF","PLEURAL EFF")
replace disease = regexr(disease,"PERIC EFF","PLEURAL EFF")
replace disease = regexr(disease,"PLEURSEY","PLEURISY")
replace disease = regexr(disease,"PLURISY","PLEURISY")
replace disease = regexr(disease,"PLEURSY","PLEURISY")
replace disease = regexr(disease,"PLERUAL","PLEURAL")
replace disease = regexr(disease,"PLURAL EFF","PLEURAL EFF")
replace disease = regexr(disease,"PNEMONIA","PNEUMONIA")
replace disease = regexr(disease,"PNEUMONIC","PNEUMONIA")
replace disease = regexr(disease,"PNUEMONIA","PNEUMONIA")
replace disease = regexr(disease,"PNEU(M)*$","PNEUMONIA")
replace disease = regexr(disease,"PNEU(M) ","PNEUMONIA ")
replace disease = regexr(disease,"PNEUMA$","PNEUMONIA")
replace disease = regexr(disease,"PNEUMON$","PNEUMONIA")
replace disease = regexr(disease,"PNEUMANIA$","PNEUMONIA")
replace disease = regexr(disease,"POIS G$","POISONING")
replace disease = regexr(disease,"POIS(D)* ","POISONING ")
replace disease = regexr(disease,"POISD$","POISONING")
replace disease = regexr(disease,"POIS$","POISONING")
replace disease = regexr(disease,"POICONING","POISONING")
replace disease = regexr(disease,"POISIONING","POISONING")
replace disease = regexr(disease,"POISON G ","POISONING ")
replace disease = regexr(disease,"POISON ","POISONING ")
replace disease = regexr(disease,"POISON$","POISONING")
replace disease = regexr(disease,"POISONED","POISONING")
replace disease = regexr(disease,"POISONG","POISONING")
replace disease = regexr(disease,"POLATE","PALATE")
replace disease = regexr(disease,"POLIOENCEPHOLITIS","POLIOENCEPHALITIS")
replace disease = regexr(disease,"POLYFUS","POLYP")
replace disease = regexr(disease,"POLYPI","POLYP")
replace disease = regexr(disease,"POLYPOID","POLYP")
replace disease = regexr(disease,"POLYPUS","POLYP")
replace disease = regexr(disease,"POPL(I)*(T)*(L)* ","POPLITEAL ")
replace disease = regexr(disease,"POPETL ","POPLITEAL ")
replace disease = regexr(disease,"POPLET ","POPLITEAL ")
replace disease = regexr(disease,"POPLTD ","POPLITEAL ")
replace disease = regexr(disease,"POPLD ","POPLITEAL ")
replace disease = regexr(disease,"POPHT ","POPLITEAL ")
replace disease = regexr(disease,"POL(T)*D  ","POPLITEAL ")
replace disease = regexr(disease,"POPLITEAL IN FE","POPLITEAL IN FEMUR")
replace disease = regexr(disease,"POSB ","")
replace disease = regexr(disease,"POST BASIL ","POST BASILAR ")
replace disease = regexr(disease,"PREPATELLA(R)* BURSA$","PREPATELLAR BURSITIS")
replace disease = regexr(disease,"PREMATURE BIRTH","PREMATURITY")
replace disease = regexr(disease,"PREMATURE CHILD","PREMATURITY")
replace disease = regexr(disease,"PREFUCE","PREPUCE")
replace disease = regexr(disease,"PROB RESULT ","")
replace disease = regexr(disease,"PROLIPAS ","PROLAPSE ")
replace disease = regexr(disease,"PROAS ","PSOAS ")
replace disease = regexr(disease,"PROCTOSIS","PROCTISIS")
replace disease = regexr(disease,"PROGRESSIVA","PROGRESSIVE")
replace disease = regexr(disease,"PROLAPSED","PROLAPSE")
replace disease = regexr(disease,"PROLAPSUS","PROLAPSE")
replace disease = regexr(disease,"PROLAPUS","PROLAPSE")
replace disease = regexr(disease,"PROLAP ","PROLAPSE ")
replace disease = regexr(disease,"PRURIGI$","PRURIGO")
replace disease = regexr(disease,"PSEUDOHYPO ","PSEUDO HYPERTROPHY ")
replace disease = regexr(disease,"POTT S ","POTTS ")
replace disease = regexr(disease,"POTUS$","POTTS")
replace disease = regexr(disease,"POTIS","POTTS")
replace disease = regexr(disease,"PEUMONIA","PNEUMONIA")
replace disease = regexr(disease,"PUEUMONIA","PNEUMONIA")
replace disease = regexr(disease,"PULMON(Y)* ","PULMONARY ")
replace disease = regexr(disease,"PULMONALIS$","PULMONARY")
replace disease = regexr(disease,"PULMY ","PULMONARY ")
replace disease = regexr(disease,"PULM$","PULMONOSIS")
replace disease = regexr(disease,"PULMON$","PULMONOSIS")
replace disease = regexr(disease,"PULMONAM$","PULMONOSIS")
replace disease = regexr(disease,"PULMONIS$","PULMONOSIS")
replace disease = regexr(disease,"PULMONIS ","PULMONOSIS ")
replace disease = regexr(disease,"PULMONUM$","PULMONOSIS")
replace disease = regexr(disease,"PULMONUNS$","PULMONOSIS")
replace disease = regexr(disease,"PULMOR$","PULMONOSIS")
replace disease = regexr(disease,"PUN[C|S]T$","PUNCTURE")
replace disease = regexr(disease,"PUNC ","PUNCTURE ")
replace disease = regexr(disease,"PUNC$","PUNCTURE")
replace disease = regexr(disease,"PUNCT(A|D)*$","PUNCTURE")
replace disease = regexr(disease,"PUNCTD ","PUNCTURE ")
replace disease = regexr(disease,"PUNCTURED","PUNCTURE")
replace disease = regexr(disease,"PUNET W","PUNCTURE W")
replace disease = regexr(disease,"PUN(S)*T W","PUNCTURE W")
replace disease = regexr(disease,"PURL CATARRH","PURULENT CATARRH")
replace disease = regexr(disease,"PUSTULAR","PUSTULE")
replace disease = regexr(disease,"PURPURIC","PURPURA")
replace disease = regexr(disease,"PURPURE$","PURPURA")
replace disease = regexr(disease,"PURNLENT","PURULENT")
replace disease = regexr(disease,"PURULANT","PURULENT")
replace disease = regexr(disease,"PURULENT OPTH(.)*$","PURULENT OPHTHALMIA")
replace disease = regexr(disease,"PYAEMIA","PYEMIA")
replace disease = regexr(disease,"PYRESIA","PYREXIA")
replace disease = regexr(disease,"PYESIA","PYREXIA")
replace disease = regexr(disease,"PYEXIA","PYREXIA")
replace disease = regexr(disease,"PURULENTO","PURULENT")

replace disease = regexr(disease,"QUM","GUM")
replace disease = regexr(disease,"QUINSEY","QUINSY")
replace disease = regexr(disease,"QUIRITIS","NEURITIS")

replace disease = regexr(disease,"RAPEX","RIGHT APEX")
replace disease = regexr(disease,"RACHITS","RACHITIS")
replace disease = regexr(disease,"RACTIT(I|U)*S","RACHITIS")
replace disease = regexr(disease,"RACLUTS","RACHITIS")
replace disease = regexr(disease,"RACTUM","RECTUM")
replace disease = regexr(disease,"RAD(S)* ","RADICAL ")
replace disease = regexr(disease,"RADICAL CLOSE","RADICAL CURE")
replace disease = regexr(disease,"RADIAL","RADIUS")
replace disease = regexr(disease,"RAYNASDIS ","RAYNAUDS ")
replace disease = regexr(disease,"RBASE","RIGHT BASE")
replace disease = regexr(disease,"REC APPEND","RECENT APPEND")
replace disease = regexr(disease,"RECTAL","RECTUM") if regexm(disease,"ISCHIO")==0
replace disease = regexr(disease,"RECTI$","RECTUM")
replace disease = regexr(disease,"RECH$","RECTUM")
replace disease = regexr(disease,"RECTI ","RECTUM ")
replace disease = regexr(disease,"RECTUS","RECTUM")
replace disease = regexr(disease,"RECURR ","RECURRENT ")
replace disease = regexr(disease,"RECURRING","RECURRENT")
replace disease = regexr(disease,"REGURG$","REGURGITATION")
replace disease = regexr(disease,"REGURGTIN","REGURGITATION")
replace disease = regexr(disease,"REDUCED","REDUCTION")
replace disease = regexr(disease,"REPRACTION","REFRACTION")
replace disease = regexr(disease,"REFRACTURE","FRACTURE")
replace disease = regexr(disease,"REGURG ","REGURGITATION ")
replace disease = regexr(disease,"RELAP ","RELAPSE ")
replace disease = regexr(disease,"RELAPSING","RELAPSE")
replace disease = regexr(disease,"REMOVED","REMOVAL")
replace disease = regexr(disease,"RENALE","RENAL")
replace disease = regexr(disease,"RENALIS","RENAL")
replace disease = regexr(disease,"RES ABSCESS","RESIDUAL ABSCESS")
replace disease = regexr(disease,"RETEN(T)*(N)*$","RETENTION")
replace disease = regexr(disease,"RETEN(T)*(N)* ","RETENTION ")
replace disease = regexr(disease,"RETRACTED","RETRACTION")
replace disease = regexr(disease,"RETRO PHAR","RETROPHAR")
replace disease = regexr(disease,"RH F ","RHEUMATIC FEVER")
replace disease = regexr(disease,"RH F$","RHEUMATIC FEVER")
replace disease = regexr(disease,"RH FEVER","RHEUMATIC FEVER")
replace disease = regexr(disease,"RHEM ","RHEUMATISM ")
replace disease = regexr(disease,"RHAUMATISM","RHEUMATISM")
replace disease = regexr(disease,"RHEMATISM","RHEUMATISM")
replace disease = regexr(disease,"RHEN FEVER","RHEUMATIC FEVER")
replace disease = regexr(disease,"RHENUMATISM","RHEUMATISM")
replace disease = regexr(disease,"RHEU FEV$","RHEUMATIC FEVER")
replace disease = regexr(disease,"RHEU FEV","RHEUMATIC FEV")
replace disease = regexr(disease,"RHEU(M)* FEV ","RHEUMATIC FEVER")
replace disease = regexr(disease,"RHEU(M)* FEVER","RHEUMATIC FEVER")
replace disease = regexr(disease,"RHEU(M)*$","RHEUMATISM")
replace disease = regexr(disease,"RHEUT$","RHEUMATISM")
replace disease = regexr(disease,"RHEU(M)*(T)*(C)* ","RHEUMATIC ")
replace disease = regexr(disease,"RHEU(M)*[ ]","RHEUMATISM ") if regexm(disease,"RHEU(M)*[ ]FEV")==0
replace disease = regexr(disease,"RHEUM(A)*(T)*(S)*(M)*$","RHEUMATISM")
replace disease = regexr(disease,"RHEUMA(L)*(T)*(I)*SM","RHEUMATISM")
replace disease = regexr(disease,"RHEUMAHIEM","RHEUMATISM")
replace disease = regexr(disease,"RHEUMAT(I)*(E)*(A)* ","RHEUMATIC ")
replace disease = regexr(disease,"RHEUMATION","RHEUMATISM")
replace disease = regexr(disease,"RHEUMATICA","RHEUMATIC")
replace disease = regexr(disease,"RHEUTE ","RHEUMATIC ")
replace disease = regexr(disease,"RHIMOSIS","PHIMOSIS")
replace disease = regexr(disease,"RHINORRHOEA","RHINORRHEA")
replace disease = regexr(disease,"RICHETTY","RICKETS")
replace disease = regexr(disease,"RICK INJ","KICK INJ")
replace disease = regexr(disease,"RICKETTS","RICKETS")
replace disease = regexr(disease,"RICKET(T|L)*Y","RICKETS")
replace disease = regexr(disease,"RICKETS AUV LEG","RICKETS CURVATURE LEG")
replace disease = regexr(disease,"RICPTD BLADDER","RUPTURED BLADDER")
replace disease = regexr(disease,"RICTAL","RECTUM")
replace disease = regexr(disease,"ROW LEGS","BOW-LEGGED")
replace disease = regexr(disease,"RTTEIMPLERIA","RHEUMATIC HEMIPLEGIA")
replace disease = regexr(disease,"RUBEOLA","RUBELLA")
replace disease = regexr(disease,"RUN OVER","RUNOVER")
replace disease = regexr(disease,"RUN ORER","RUNOVER")
replace disease = regexr(disease,"RUPT(D)* ","RUPTURE ")
replace disease = regexr(disease,"RUPTURED","RUPTURE")
replace disease = regexr(disease,"RUPTURED","RUPTURE")
replace disease = regexr(disease,"ISCHIO RECTAL","ISCHIORECTAL")

replace disease = regexr(disease,"S POX","SMALLPOX")
replace disease = regexr(disease,"SACRAL","SACRUM")
replace disease = regexr(disease,"SACLDED","SCALD")
replace disease = regexr(disease,"SACRO DISC","SACROILIAC")
replace disease = regexr(disease,"SARYNGITIS","LARYNGITIS")
replace disease = regexr(disease,"SARYNX","LARYNX")
replace disease = regexr(disease,"S(T)*RANG(TD)* ","STRANGULATED ")
replace disease = regexr(disease,"S[A|U]BAC ","SUB ACUTE ")
replace disease = regexr(disease,"SC F$","SCARLET FEVER")
replace disease = regexr(disease,"SC(T)* FEVER","SCARLET FEVER")
replace disease = regexr(disease,"SCALDED","SCALD")
replace disease = regexr(disease,"SCAPULAR","SCAPULA")
replace disease = regexr(disease,"SCARLT DROPSY","SCARLET FEVER DROPSY")
replace disease = regexr(disease,"SCARLATINA(L)*","SCARLET FEVER")
replace disease = regexr(disease,"SCARLATI$","SCARLET FEVER")
replace disease = regexr(disease,"SCARLATIN(I)*FORM$","SCARLET FEVER")
replace disease = regexr(disease,"SCIATIC$","SCIATICA")
replace disease = regexr(disease,"SCLERAL","SCLERA")
replace disease = regexr(disease,"SCLERES$","SCLERA")
replace disease = regexr(disease,"SCLEROTIC$","SCLERA")
replace disease = regexr(disease,"SCLEROMA NEO","SCLEREMA NEO")
replace disease = regexr(disease,"SCROTAL","SCROTUM")
replace disease = regexr(disease,"SCROFULOUS","SCROFULA")
replace disease = regexr(disease,"SCROFULIDE(S)*","SCROFULA")
replace disease = regexr(disease,"SCROTI$","SCROTUM")
replace disease = regexr(disease,"SCT LEVER","SCARLET FEVER")
replace disease = regexr(disease,"SCIATIC ","SCIATICA ")
replace disease = regexr(disease,"SCPTIE ","SEPTIC ")
replace disease = regexr(disease,"SEAR FEV$","SCARLET FEVER")
replace disease = regexr(disease,"SEALATENA","SCARLET FEVER")
replace disease = regexr(disease,"SEBORRHEICA","SEBORRHEA")
replace disease = regexr(disease,"SEBORRHOEA","SEBORRHEA")
replace disease = regexr(disease,"SEC HEM","SECONDARY HEM")
replace disease = regexr(disease,"SEPARATED","SEPARATION")
replace disease = regexr(disease,"SEPERATION","SEPARATION")
replace disease = regexr(disease,"SEPTICAEMIA","SEPTICEMIA")
replace disease = regexr(disease,"SEAL WOUND","SCALD WOUND")
replace disease = regexr(disease,"SEQUELAE","SEQUELA")
replace disease = regexr(disease,"SHIFF ","STIFF ")
replace disease = regexr(disease,"SHIFT ARM","STIFF ARM")
replace disease = regexr(disease,"SHOULDERSHEST","SHOULDER CHEST")
replace disease = regexr(disease,"SHORT BREATH","SHORTNESS BREATH")
replace disease = regexr(disease,"SHUMUOUS","STRUMOUS")
replace disease = regexr(disease,"SHUM DIS","STRUMOUS DIS")
replace disease = regexr(disease,"SHUM ABSE ","STRUMOUS ABSCESS ")
replace disease = regexr(disease,"SHUMOUS","STRUMOUS")
replace disease = regexr(disease,"SIMP FRAC","SIMPLE FRAC")
replace disease = regexr(disease,"SINUSES","SINUS")
replace disease = regexr(disease,"SLOUGHING","SLOUGH")
replace disease = regexr(disease,"SMALL POX","SMALLPOX")
replace disease = regexr(disease,"SMASHED","SMASH")
replace disease = regexr(disease,"SMERDAL","")
replace disease = regexr(disease,"SMPYEMA","EMPYEMA")
replace disease = regexr(disease,"SPLENOMEGALIA","SPLENOMEGALY")
replace disease = regexr(disease,"SPINABIFIDA","SPINA BIFIDA")
replace disease = regexr(disease,"SPIRIAL CAR","SPINAL CAR")
replace disease = regexr(disease,"SPITS SALT","SPIRITS SALT")
replace disease = regexr(disease,"SPL ANKLE","SPRAIN ANKLE")
replace disease = regexr(disease,"SPORADIE","SPORADIC")
replace disease = regexr(disease,"SPONTAN ","SPONTANEOUS ")
replace disease = regexr(disease,"SPRAINCED","SPRAIN")
replace disease = regexr(disease,"SPRAINED","SPRAIN")
replace disease = regexr(disease,"ST POST EPILEPT$","STATUS POST EPILEPTICUS")
replace disease = regexr(disease,"STRAINED","STRAIN")
replace disease = regexr(disease,"STABBED","STAB")
replace disease = regexr(disease,"STABISMUS","STRABISMUS")
replace disease = regexr(disease,"STABS","STAB")
replace disease = regexr(disease,"STAPHILOMA","STAPHYLOMA")
replace disease = regexr(disease,"STAPHYLOMATOUS","STAPHYLOMA")
replace disease = regexr(disease,"STIFFNESS","STIFF")
replace disease = regexr(disease,"STR[E|U]CTURE","STRICTURE")
replace disease = regexr(disease,"STRANG$","STRANGULATED")
replace disease = regexr(disease,"STRATFORMUS","STRABISMUS")
replace disease = regexr(disease,"STANNOUS","STRUMOUS")
replace disease = regexr(disease,"STAPHY ","STAPHYLOCOCCUS ")
replace disease = regexr(disease,"STRAMOUS","STRUMOUS")
replace disease = regexr(disease,"STRANGULATION","STRANGULATED")
replace disease = regexr(disease,"STRABISMAS","STRABISMUS")
replace disease = regexr(disease,"STRUMONS ","STRUMOUS ")
replace disease = regexr(disease,"STRUMOUS MIST","STRUMOUS WRIST")
replace disease = regexr(disease,"STUM(OUS)* ","STRUMOUS ")
replace disease = regexr(disease,"STRU DIS","STRUMOUS DIS")
replace disease = regexr(disease,"STRUMT DIS","STRUMOUS DIS")
replace disease = regexr(disease,"STRUNI CAR","STRUMOUS CAR")
replace disease = regexr(disease,"STOMACK","STOMACH")
replace disease = regexr(disease,"STRUMP$","STUMP$")
replace disease = regexr(disease,"STRUMP ","STUMP ")
replace disease = regexr(disease,"SUB MAX ","SUBMAXILLA ")
replace disease = regexr(disease,"SUB MAX","SUBMAX")
replace disease = regexr(disease,"SUBPERCOVANIAL","SUPRACRANIAL")
replace disease = regexr(disease,"SUFFPD ","SUPPURATION ")
replace disease = regexr(disease,"SULPH ACID","SULPHURIC ACID")
replace disease = regexr(disease,"SUB ACUTE","SUBACUTE")
replace disease = regexr(disease,"SUP THUMB","SUPPURATION THUMB")
replace disease = regexr(disease,"SUPERF ","SUPERFICIAL ")
replace disease = regexr(disease,"SUPERNUM (NY)*( )*","SUPERNUMERACY ")
replace disease = regexr(disease,"SUPP(TOC)* ","SUPPURATION ")
replace disease = regexr(disease,"SUPP(L)*(D)*(U)*(R)*(T)*(N)*(G)* ","SUPPURATION ")
replace disease = regexr(disease,"SUPPERT ","SUPPURATION ")
replace disease = regexr(disease,"SUPPETG ","SUPPURATION ")
replace disease = regexr(disease,"SUPPINATING","SUPPURATION")
replace disease = regexr(disease,"SUPPINGUINAL","SUPPURATION INGUINAL")
replace disease = regexr(disease,"SUPPR$","SUPPURATION")
replace disease = regexr(disease,"SUPPS ","SUPPURATION ")
replace disease = regexr(disease,"SUPPTOC","SUPPURATION OC")
replace disease = regexr(disease,"SUPPTVE ","SUPPURATION ")
replace disease = regexr(disease,"SUPPURAT ","SUPPURATION ")
replace disease = regexr(disease,"SUPPURATING ","SUPPURATION ")
replace disease = regexr(disease,"SUPPURATING$","SUPPURATION")
replace disease = regexr(disease,"SUPPURATIVE ","SUPPURATION ")
replace disease = regexr(disease,"SUPPURT$","SUPPURATION")
replace disease = regexr(disease,"SUPERATIVE ","SUPPURATION ")
replace disease = regexr(disease,"SUPPORT EYE","SUPPURATION EYE")
replace disease = regexr(disease,"SUP HAND","SUPPURATION HAND")
replace disease = regexr(disease,"SUPERFIELD KERA","SUPPURATION KERA")
replace disease = regexr(disease,"SUP(P)*ERL KERA","SUPPURATION KERA")
replace disease = regexr(disease,"SUP KERA","SUPPURATION KERA")
replace disease = regexr(disease,"SUP BURSA","SUPPURATION BURSA")
replace disease = regexr(disease,"SUPERNUMERY","SUPERNUMERARY")
replace disease = regexr(disease,"SUPER MY FINGER","SUPERNUMERARY FINGER")
replace disease = regexr(disease,"SUP MAXILL","SUPERIOR MAXILL")
replace disease = regexr(disease,"SUP(ER)* MAX$","SUPERIOR MAXILLA")
replace disease = regexr(disease,"SUPER MISCELLANY","SUPERIOR MAXILLA")
replace disease = regexr(disease,"SWALL$","SWALLOWED")
replace disease = regexr(disease,"SWALLY","SWALLOWED")
replace disease = regexr(disease,"SWELLY ","SWALLOWED ")
replace disease = regexr(disease,"SWALLOIN$","SWALLOWED")
replace disease = regexr(disease,"SWEELING","SWELLING")
replace disease = regexr(disease,"SWELL(G)* ","SWELLING ")
replace disease = regexr(disease,"SWELL(G)*$","SWELLING")
replace disease = regexr(disease,"SWELLED","SWELLING")
replace disease = regexr(disease,"SWELLS","SWELLING")
replace disease = regexr(disease,"SWELLY","SWELLING")
replace disease = regexr(disease,"SWLLING","SWELLING")
replace disease = regexr(disease,"SWOLLEN","SWELLING")
replace disease = regexr(disease,"SYMPTONS","SYMPTOM")
replace disease = regexr(disease,"SYNECHIAE","SYNECHIA")
replace disease = regexr(disease,"SYNOVITES","SYNOVITIS")
replace disease = regexr(disease,"SYNO KNEE","SYNOVITIS KNEE")
replace disease = regexr(disease,"SYPH$","SYPHILIS")
replace disease = regexr(disease,"SYPH$","SYPHILIS")
replace disease = regexr(disease,"SYPHITIS","SYPHILIS")
replace disease = regexr(disease,"SYMP OPHTH","SYMPATHETIC OPHTH")
replace disease = regexr(disease,"SYME ","SYMES ")
replace disease = regexr(disease,"SYM ","SYMPATHETIC ") if regexm(disease,"PHARON")

replace disease = regexr(disease,"TABERCULOAS","TUBERCULAR")
replace disease = regexr(disease,"TALIPES VA[L|R](GU)*(IE)*(S)*","TALIPES VARUS") if regexm(disease, "VARUS")==0
replace disease = regexr(disease,"TALIPS","TALIPES")
replace disease = regexr(disease,"TALPIES","TALIPES")
replace disease = regexr(disease,"TAMOUR","TUMOUR")
replace disease = regexr(disease,"TOOTH","TEETH")
replace disease = regexr(disease,"TEMP BONE","TEMPLE BONE")
replace disease = regexr(disease,"TEST[E|I]S","TESTICLE")
replace disease = regexr(disease,"THECAL","THECA")
replace disease = regexr(disease,"THIGH HIG$","THIGH REGION")
replace disease = regexr(disease,"THORAT","THROAT")
replace disease = regexr(disease,"THYR ","THYROID ")
replace disease = regexr(disease,"TIBIA FIB ","TIBIA FIBULA")
replace disease = regexr(disease,"TIBIAL","TIBIA LEFT")
replace disease = regexr(disease,"TIBULA","FIBULA")
replace disease = regexr(disease,"TIBIAE","TIBIA")
replace disease = regexr(disease,"TINIA","TINEA")
replace disease = regexr(disease,"TO NAIL","TOENAIL")
replace disease = regexr(disease,"TOE NAIL","TOENAIL")
replace disease = regexr(disease,"TORSUS","TARSUS")
replace disease = regexr(disease,"TOXAEMIA","TOXEMIA")
replace disease = regexr(disease,"TOYNRUS","INJURY")
replace disease = regexr(disease,"TRACH ","TRACHEA ")
replace disease = regexr(disease,"TRACH$","TRACHEA")
replace disease = regexr(disease,"TRAOMY","TRACHEOTOMY")
replace disease = regexr(disease,"TRACHESTOMY","TRACHEOSTOMY")
replace disease = regexr(disease,"TRONHDER","SHOULDER")
replace disease = regexr(disease,"TUBERCULER","TUBERCULAR")
replace disease = regexr(disease,"TUBERCULIDE","TUBERCULAR")
replace disease = regexr(disease,"TUBERCULOR","TUBERCULAR")
replace disease = regexr(disease,"TUBERCULOYS","TUBERCULAR")
replace disease = regexr(disease,"TUB ","TUBERCULAR ")
replace disease = regexr(disease,"TUB(AR)* ","TUBERCULAR ")
replace disease = regexr(disease,"TUB(ER)*DIS","TUBERCULAR DIS")
replace disease = regexr(disease,"TUBE(R)*(C)* ","TUBERCULAR ")
replace disease = regexr(disease,"TUBER$","TUBERCULAR")
replace disease = regexr(disease,"TUBER(C)* ","TUBERCULAR ")
replace disease = regexr(disease,"TUBERCUL ","TUBERCULAR ")
replace disease = regexr(disease,"TUBERCULOS ","TUBERCULAR ")
replace disease = regexr(disease,"TUBERCULOSIS GLDS","TUBERCULAR GLANDS")
replace disease = regexr(disease,"TUBERCULOUS GLDS","TUBERCULAR GLANDS")
replace disease = regexr(disease,"TUBERCULOS GLDS","TUBERCULAR GLANDS")
replace disease = regexr(disease,"TUBERCULOUS","TUBERCULAR")
replace disease = regexr(disease,"TUBERE$","TUBERCULAR")
replace disease = regexr(disease,"TUBURCULER","TUBERCULAR")
replace disease = regexr(disease,"TUBURCULIDE","TUBERCULAR")
replace disease = regexr(disease,"TUBURCULOR","TUBERCULAR")
replace disease = regexr(disease,"TUBURCULOS$","TUBERCULAR")
replace disease = regexr(disease,"TUBURCULOUS ","TUBERCULAR ")
replace disease = regexr(disease,"TUBURCULOYS","TUBERCULAR")
replace disease = regexr(disease,"TUBURCULS ","TUBERCULAR ")
replace disease = regexr(disease,"TUBERAC ","TUBERCULAR ")
replace disease = regexr(disease,"TUBERC$","TUBERCULAR")
replace disease = regexr(disease,"TUBERE ","TUBERCULAR ")
replace disease = regexr(disease,"TUBERELE$","TUBERCULAR")
replace disease = regexr(disease,"TUMOR","TUMOUR")
replace disease = regexr(disease,"TUMR","TUMOUR")
replace disease = regexr(disease,"TURMOUR","TUMOUR")
replace disease = regexr(disease,"TURBINATED","TURBINATE")
replace disease = regexr(disease,"TURBINAL","TURBINATE")
replace disease = regexr(disease,"TWELLING","SWELLING")
replace disease = regexr(disease,"TWITG$","TWITCHING")
replace disease = regexr(disease,"TYMPANA$","TYMPANUM")
replace disease = regexr(disease,"TYMPANI$","TYMPANUM")
replace disease = regexr(disease,"TYP(H)* ","TYPHOID ")
replace disease = regexr(disease,"TYPHIOD","TYPHOID")
replace disease = regexr(disease,"TYPHOID","TYPHOID FEVER") if regexm(disease,"FEVER")==0
replace disease = regexr(disease,"TYPHORD","TYPHOID")
replace disease = regexr(disease,"TYPHILITIS","TYPHLITIS")
replace disease = regexr(disease,"TYMPANITES","TYMPANITIS")

replace disease = regexr(disease,"ULC ","ULCER ")
replace disease = regexr(disease,"ULCERA ","ULCER ")
replace disease = regexr(disease,"ULCERAT ","ULCER ")
replace disease = regexr(disease,"ULCERATED","ULCER")
replace disease = regexr(disease,"ULCERATION","ULCER")
replace disease = regexr(disease,"ULCERATIVE","ULCER")
replace disease = regexr(disease,"ULCERATIS","ULCER")
replace disease = regexr(disease,"ULCEROUS","ULCER")
replace disease = regexr(disease,"ULCERT(N)* ","ULCER ")
replace disease = regexr(disease,"ULCERAT$","ULCER")
replace disease = regexr(disease,"ULCERT$","ULCER")
replace disease = regexr(disease,"ULCERTN","ULCER")
replace disease = regexr(disease,"ULCR","ULCER")
replace disease = regexr(disease,"ULNAR","ULNA")
replace disease = regexr(disease,"UNDES(C)*(END)* ","UNDESCENDED " )
replace disease = regexr(disease,"UNDESCENDING","UNDESCENDED")
replace disease = regexr(disease,"UPPER END","UPPER-END")
replace disease = regexr(disease,"URAEMIA","UREMIA")

replace disease = regexr(disease,"VALVU ","VALVULAR ")
replace disease = regexr(disease,"V V ","VARICOSE VEINS ")
replace disease = regexr(disease,"V[A|E](R)*I(C)*O(C)*(E)*L(E)*(S)*","VARICOCELE")
replace disease = regexr(disease,"VAR VEINS","VARICOSE VEINS")
replace disease = regexr(disease,"VARSUS","VARUS")
replace disease = regexr(disease,"VELGASTRIC","GASTRITIS")
replace disease = regexr(disease,"^VEN$","VENEREAL")
replace disease = regexr(disease," VEN$"," VENEREAL")
replace disease = regexr(disease,"VERTEBRA$","VERTEBRAE")
replace disease = regexr(disease,"VESICAL STONE","CALCULUS VESICA")
replace disease = regexr(disease,"VESICA[L|E]","VESICA")
replace disease = regexr(disease,"VESICOE(A)*","VESICA")
replace disease = regexr(disease,"VESICULAR","VESICLE")
replace disease = regexr(disease,"VESSICAE","VESICAE")
replace disease = regexr(disease,"VASICE$","VESICA")
replace disease = regexr(disease,"VEST CALCULUS","CALCULUS VESICA")
replace disease = regexr(disease,"VITRESOUS","VITREOUS")
replace disease = regexr(disease,"VOM(IT)* ","VOMITING ")
replace disease = regexr(disease,"VOMITING O$","VOMITING DIARRHEA")

replace disease = regexr(disease,"W(H)*ARTY","WARTS")
replace disease = regexr(disease,"WARE LIP","HARELIP")
replace disease = regexr(disease,"WARTS WARTS","WARTS")
replace disease = regexr(disease,"WAY NECK","WRY NECK")
replace disease = regexr(disease,"WEAKNEES","WEAKNESS")
replace disease = regexr(disease,"WEARING","")
replace disease = regexr(disease,"WEB FING","WEBBED FING")
replace disease = regexr(disease,"WH C ","WHOOPING COUGH ")
replace disease = regexr(disease,"WH C$","WHOOPING COUGH")
replace disease = regexr(disease,"WH COUGH","WHOOPING COUGH")
replace disease = regexr(disease,"WHOOP J ","WHOOPING ")
replace disease = regexr(disease,"WHOOPG COUGH$","WHOOPING COUGH")
replace disease = regexr(disease,"WHOOPINGOUGH","WHOOPING COUGH")
replace disease = regexr(disease,"WOULD","WOUND")
replace disease = regexr(disease,"WOUND FR ","WOUND ")
replace disease = regexr(disease,"WOUNDED","WOUND")
replace disease = regexr(disease,"WOUNDSHOULDER","WOUND SHOULDER")

replace disease = subinstr(disease,"    "," ",.)
replace disease = subinstr(disease,"   "," ",.)
replace disease = subinstr(disease,"  "," ",.)
replace disease = trim(disease)
duplicates drop
sort disease 

* Reformat words:
gen disease_cleaned = disease

replace disease = regexr(disease,"ABDOMINAL","ABDOMEN")
replace disease = regexr(disease,"ANAEMIC","ANEMIA")
replace disease = regexr(disease,"AURAL","EAR")
replace disease = regexr(disease,"BADLY","BAD")
replace disease = regexr(disease,"CORNEAL","CORNEA")
replace disease = regexr(disease,"CRANIAL","CRANIUM")
replace disease = regexr(disease,"FEBRIS RUBRUM","SCARLET FEVER")
replace disease = regexr(disease,"FEBRIS","FEVER")
replace disease = regexr(disease,"INTESTINAL","INTESTINE")
replace disease = regexr(disease,"LARYNGEAL","LARYNX")
replace disease = regexr(disease,"LARYNGISMUS","LARYNGISMUS STRIDULUS") if regexm(disease,"STRIDULUS") == 0 
replace disease = regexr(disease,"LOCALIZED","LOCAL")
replace disease = regexr(disease,"LYMPHOMATOUS","LYMPHOMA")
replace disease = regexr(disease,"LYMPHOID","LYMPH")
replace disease = regexr(disease,"LYMPHATIC","LYMPH")
replace disease = regexr(disease,"MEDIASTINAL","MEDIASTINUM")
replace disease = regexr(disease,"PAINFUL","PAIN")
replace disease = regexr(disease,"PELVIC","PELVIS")
replace disease = regexr(disease,"PHLYCTENULAR","PHLYCTENULE")
replace disease = regexr(disease,"PYLORIC","PYLORUS")
replace disease = regexr(disease,"PHAGEDENIC","PHAGEDENA")
replace disease = regexr(disease,"PHARYNGEAL","PHARYNX")
replace disease = regexr(disease,"RHEUMATIC","RHEUMATISM")
replace disease = regexr(disease,"SEPTIC ","SEPSIS ")
replace disease = regexr(disease,"SEPTIC$","SEPSIS")
replace disease = regexr(disease,"SPLENIC","SPLEEN")
replace disease = regexr(disease,"SPASMODIC","SPASM")
replace disease = regexr(disease,"SPINAL$","SPINE")
replace disease = regexr(disease,"SPINAL ","SPINE ")
replace disease = regexr(disease,"STRUMOUS","STRUMA")
replace disease = regexr(disease,"SUBPHRENIC","SUBDIAPHRAGM")
replace disease = regexr(disease,"SYPHILITIC","SYPHILIS")
replace disease = regexr(disease,"TENDERNESS","TENDER")
replace disease = regexr(disease,"TARSAL","TARSUS")
replace disease = regexr(disease,"TONSILLAR","TONSIL")
replace disease = regexr(disease,"TRACHEAL","TRACHEA")
replace disease = regexr(disease,"TYMPANIC","TYMPANUM")
replace disease = regexr(disease,"UNCONSCIOUSNESS","UNCONSCIOUS")
replace disease = regexr(disease,"URAEMIC","UREMIA")
replace disease = regexr(disease,"(PERI)*URETHRAL","URETHRA")
replace disease = regexr(disease,"VAGINAL","VAGINA")

order dis_orig dis_count

/* 	Assign disease category:

	Assigns components of the cleaned cause of admission variable to various categories. 
	Assigns multiple word strings to a "main" disease variable. 
	Manually coded information about each disease is used to create all variables 
	related to the causes of admission that will be used in regressions. */
	

* Plural to singular, tense change
#delimit ;
local singular "
ACUTE ADENOID ADHESION AFFECTION ANKLE ARM BOIL BONE BOWEL BRUISE BUTTOCK BURN CATARACT CONCUSSION CONDYLE CONE CONSTIPATION CONTRACTION CONTUSION CONVULSION COUGH CUT CYST DIGIT DISEASE DISLOCATION DUCT
EAR ELBOW EMBOLISM EMPYEMA EXPLOSION EYE EYELID FEMUR FEVER FINGER FIT FOLLICLE FRACTURE GENITAL GLAND GRANULATION GROWTH GUM HAMSTRING HAND HEMORRHOID HIP JAW JOINT KIDNEY KNEE 
LARYNGEAL LEG LIMB LIP LUNG LYMPHATIC MASTOID METATARSAL METACARPAL MOVEMENT MUSCLE NERVE NOSTRIL OPERATION PAIN PHLYCTENULE POLYP PYREXIA PYLE REGION RIB 
SALT SCALD SCAR SCROTUM SEPTUM SHOULDER SLOUGH SORE SPASM STONE SWELLING SYMPTOM TENDON TESTICLE THIGH THUMB TOENAIL TOE TONSIL TREMOR TUMOUR TURBINATE ULCER VALVE VEGETATION VEIN WALL WOUND";
#delimit cr;
foreach word of local singular {
	replace disease = regexr(disease,"`word'S","`word'")
}

* Extract main component
gen main = ""

replace main = main+",RECTANGULAR TALIPES" if regexm(disease,"TALIPES") & regexm(disease,"RECTANGULAR") & main!=""
replace main = "RECTANGULAR TALIPES" if regexm(disease,"TALIPES") & regexm(disease,"RECTANGULAR") & main==""
replace disease = regexr(disease,"RECTANGULAR","") if regexm(main,"RECTANGULAR TALIPES")
replace disease = regexr(disease,"TALIPES","") if regexm(main,"RECTANGULAR TALIPES")

replace main = main+",TALIPES EQUINOVALGUS" if (regexm(disease,"TALIPES") | regexm(disease,"EQUINO")) & regexm(disease,"VALGUS") & main!=""
replace main = "TALIPES EQUINOVALGUS" if (regexm(disease,"TALIPES") | regexm(disease,"EQUINO")) & regexm(disease,"VALGUS")  & main==""
replace disease = regexr(disease,"TALIPES","") if regexm(main,"TALIPES EQUINOVALGUS")
replace disease = regexr(disease,"EQUINO","") if regexm(main,"TALIPES EQUINOVALGUS")
replace disease = regexr(disease,"VALGUS","") if regexm(main,"TALIPES EQUINOVALGUS")

replace main = main+",TALIPES EQUINOVARUS" if (regexm(disease,"TALIPES") | regexm(disease,"EQUINO")) & regexm(disease,"VARUS") & main!=""
replace main = "TALIPES EQUINOVARUS" if (regexm(disease,"TALIPES") | regexm(disease,"EQUINO")) & regexm(disease,"VARUS")  & main==""
replace disease = regexr(disease,"TALIPES","") if regexm(main,"TALIPES EQUINOVARUS")
replace disease = regexr(disease,"EQUINO","") if regexm(main,"TALIPES EQUINOVARUS")
replace disease = regexr(disease,"VARUS","") if regexm(main,"TALIPES EQUINOVARUS")

replace main = main+",ADDISONS DISEASE" if regexm(disease,"ADDISONS") & regexm(disease,"DISEASE") & main!=""
replace main = "ADDISONS DISEASE" if regexm(disease,"ADDISONS") & regexm(disease,"DISEASE")  & main==""
replace disease = regexr(disease,"ADDISONS","") if regexm(main,"ADDISONS DISEASE")
replace disease = regexr(disease,"DISEASE","") if regexm(main,"ADDISONS DISEASE")

replace main = main+",AERIAL FISTULA" if regexm(disease,"AERIAL") & regexm(disease,"FISTULA") & main!=""
replace main = "AERIAL FISTULA" if regexm(disease,"AERIAL") & regexm(disease,"FISTULA")  & main==""
replace disease = regexr(disease,"AERIAL","") if regexm(main,"AERIAL FISTULA")
replace disease = regexr(disease,"FISTULA","") if regexm(main,"AERIAL FISTULA")

replace main = main+",ALTERNATING CONCOMITANT STRABISMUS" if regexm(disease,"ALTERNATING") & regexm(disease,"CONCOMITANT") & regexm(disease,"STRABISMUS") & main!=""
replace main = "ALTERNATING CONCOMITANT STRABISMUS" if regexm(disease,"ALTERNATING") & regexm(disease,"CONCOMITANT") & regexm(disease,"STRABISMUS") & main==""
replace disease = regexr(disease,"ALTERNATING","") if regexm(main,"ALTERNATING CONCOMITANT STRABISMUS")
replace disease = regexr(disease,"CONCOMITANT","") if regexm(main,"ALTERNATING CONCOMITANT STRABISMUS")
replace disease = regexr(disease,"STRABISMUS","") if regexm(main,"ALTERNATING CONCOMITANT STRABISMUS")

replace main = main+",ANGINA FAUCIUM" if regexm(disease,"ANGINA") & regexm(disease,"FAUCIUM") & main!=""
replace main = "ANGINA FAUCIUM" if regexm(disease,"ANGINA") & regexm(disease,"FAUCIUM")  & main==""
replace disease = regexr(disease,"FAUCIUM","") if regexm(main,"ANGINA FAUCIUM")
replace disease = regexr(disease,"ANGINA","") if regexm(main,"ANGINA FAUCIUM")

replace main = main+",ANGULAR CURVATURE" if regexm(disease,"ANGULAR") & regexm(disease,"CURVATURE") & main!=""
replace main = "ANGULAR CURVATURE" if regexm(disease,"ANGULAR") & regexm(disease,"CURVATURE") & main==""
replace disease = regexr(disease,"ANGULAR","") if regexm(main,"ANGULAR CURVATURE")
replace disease = regexr(disease,"CURVATURE","") if regexm(main,"ANGULAR CURVATURE")

replace main = main+",ANGULAR DEFORMITY" if regexm(disease,"ANGULAR") & regexm(disease,"DEFORMITY") & main!=""
replace main = "ANGULAR DEFORMITY" if regexm(disease,"ANGULAR") & regexm(disease,"DEFORMITY") & main==""
replace disease = regexr(disease,"ANGULAR","") if regexm(main,"ANGULAR DEFORMITY")
replace disease = regexr(disease,"DEFORMITY","") if regexm(main,"ANGULAR DEFORMITY")

replace main = main+",ANGINA LUDOVICI" if regexm(disease,"ANGINA") & regexm(disease,"LUDOVICI") & main!=""
replace main = "ANGINA LUDOVICI" if regexm(disease,"ANGINA") & regexm(disease,"LUDOVICI")  & main==""
replace disease = regexr(disease,"LUDOVICI","") if regexm(main,"ANGINA LUDOVICI")
replace disease = regexr(disease,"ANGINA","") if regexm(main,"ANGINA LUDOVICI")

replace main = main+",ANGIONEUROTIC EDEMA" if regexm(disease,"ANGIONEUROSIS") & regexm(disease,"EDEMA") & main!=""
replace main = "ANGIONEUROTIC EDEMA" if regexm(disease,"ANGIONEUROSIS") & regexm(disease,"EDEMA")  & main==""
replace disease = regexr(disease,"ANGIONEUROSIS","") if regexm(main,"ANGIONEUROTIC EDEMA")
replace disease = regexr(disease,"EDEMA","") if regexm(main,"ANGIONEUROTIC EDEMA")

replace main = main+",ARRESTED GROWTH" if regexm(disease,"ARRESTED") & regexm(disease,"GROWTH") & main!=""
replace main = "ARRESTED GROWTH" if regexm(disease,"ARRESTED") & regexm(disease,"GROWTH") & main==""
replace disease = regexr(disease,"ARRESTED","") if regexm(main,"ARRESTED GROWTH")
replace disease = regexr(disease,"GROWTH","") if regexm(main,"ARRESTED GROWTH")

replace main = main+",BAKERS CYST" if regexm(disease,"BAKERS") & regexm(disease,"CYST") & main!=""
replace main = "BAKERS CYST" if regexm(disease,"BAKERS") & regexm(disease,"CYST")  & main==""
replace disease = regexr(disease,"BAKERS","") if regexm(main,"BAKERS CYST")
replace disease = regexr(disease,"CYST","") if regexm(main,"BAKERS CYST")

replace main = main+",BEHAVIOURAL DISORDER" if regexm(disease,"BEHAVIOUR(AL)*") & regexm(disease,"DISORDER") & main!=""
replace main = "BEHAVIOURAL DISORDER" if regexm(disease,"BEHAVIOUR(AL)*") & regexm(disease,"DISORDER") & main==""
replace disease = regexr(disease,"BEHAVIOUR(AL)*","") if regexm(main,"BEHAVIOURAL DISORDER")
replace disease = regexr(disease,"DISORDER","") if regexm(main,"BEHAVIOURAL DISORDER")

replace main = main+",BELLS PALSY" if regexm(disease,"BELLS") & regexm(disease,"PALSY") & main!=""
replace main = "BELLS PALSY" if regexm(disease,"BELLS") & regexm(disease,"PALSY") & main==""
replace disease = regexr(disease,"BELLS","") if regexm(main,"BELLS PALSY")
replace disease = regexr(disease,"PALSY","") if regexm(main,"BELLS PALSY")

replace main = main+",BIFID UVULA" if regexm(disease,"BIFID") & regexm(disease,"UVULA") & main!=""
replace main = "BIFID UVULA" if regexm(disease,"BIFID") & regexm(disease,"UVULA")  & main==""
replace disease = regexr(disease,"BIFID","") if regexm(main,"BIFID UVULA")
replace disease = regexr(disease,"UVULA","") if regexm(main,"BIFID UVULA")

replace main = main+",BILIARY COLIC" if regexm(disease,"BILIARY") & regexm(disease,"COLIC") & main!=""
replace main = "BILIARY COLIC" if regexm(disease,"BILIARY") & regexm(disease,"COLIC")  & main==""
replace disease = regexr(disease,"BILIARY","") if regexm(main,"BILIARY COLIC")
replace disease = regexr(disease,"COLIC","") if regexm(main,"BILIARY COLIC")

replace main = main+",BRACHIAL MONOPLEGIA" if regexm(disease,"BRACHIAL") & regexm(disease,"MONOPLEGIA") & main!=""
replace main = "BRACHIAL MONOPLEGIA" if regexm(disease,"BRACHIAL") & regexm(disease,"MONOPLEGIA")  & main==""
replace disease = regexr(disease,"BRACHIAL","") if regexm(main,"BRACHIAL MONOPLEGIA")
replace disease = regexr(disease,"MONOPLEGIA","") if regexm(main,"BRACHIAL MONOPLEGIA")

replace main = main+",BULBAR PALSY" if regexm(disease,"BULBAR") & regexm(disease,"PALSY") & main!=""
replace main = "BULBAR PALSY" if regexm(disease,"BULBAR") & regexm(disease,"PALSY")  & main==""
replace disease = regexr(disease,"BULBAR","") if regexm(main,"BULBAR PALSY")
replace disease = regexr(disease,"PALSY","") if regexm(main,"BULBAR PALSY")

replace main = main+",CALCULUS URETER" if regexm(disease,"CALCULUS") & regexm(disease,"URETER") & main!=""
replace main = "CALCULUS URETER" if regexm(disease,"CALCULUS") & regexm(disease,"URETER")  & main==""
replace disease = regexr(disease,"CALCULUS","") if regexm(main,"CALCULUS URETER")
replace disease = regexr(disease,"URETER","") if regexm(main,"CALCULUS URETER")

replace main = main+",CALCULUS VESICA" if regexm(disease,"CALCULUS") & regexm(disease,"VESICA") & main!=""
replace main = "CALCULUS VESICA" if regexm(disease,"CALCULUS") & regexm(disease,"VESICA")  & main==""
replace disease = regexr(disease,"CALCULUS","") if regexm(main,"CALCULUS VESICA")
replace disease = regexr(disease,"VESICA","") if regexm(main,"CALCULUS VESICA")

replace main = main+",CANCRUM ORIS" if regexm(disease,"CANCRUM") & regexm(disease,"ORIS") & main!=""
replace main = "CANCRUM ORIS" if regexm(disease,"CANCRUM") & regexm(disease,"ORIS")  & main==""
replace disease = regexr(disease,"CANCRUM","") if regexm(main,"CANCRUM ORIS")
replace disease = regexr(disease,"ORIS","") if regexm(main,"CANCRUM ORIS")

replace main = main+",CARIES SPINE" if regexm(disease,"CARIES") & regexm(disease,"SPINE") & main!=""
replace main = "CARIES SPINE" if regexm(disease,"CARIES") & regexm(disease,"SPINE")  & main==""
replace disease = regexr(disease,"CARIES","") if regexm(main,"CARIES SPINE")
replace disease = regexr(disease,"SPINE","") if regexm(main,"CARIES SPINE")

replace main = main+",CEREBROSPINAL DISEASE" if regexm(disease,"CEREBROSPINE") & regexm(disease,"DISEASE") & main!=""
replace main = "CEREBROSPINAL DISEASE" if regexm(disease,"CEREBROSPINE") & regexm(disease,"DISEASE") & main==""
replace disease = regexr(disease,"CEREBROSPINE","") if regexm(main,"CEREBROSPINAL DISEASE")
replace disease = regexr(disease,"DISEASE","") if regexm(main,"CEREBROSPINAL DISEASE")

replace main = main+",CEREBROSPINAL MENINGITIS" if regexm(disease,"CEREBROSPINE") & regexm(disease,"MENINGITIS") & main!=""
replace main = "CEREBROSPINAL MENINGITIS" if regexm(disease,"CEREBROSPINE") & regexm(disease,"MENINGITIS") & main==""
replace disease = regexr(disease,"CEREBROSPINE","") if regexm(main,"CEREBROSPINAL MENINGITIS")
replace disease = regexr(disease,"MENINGITIS","") if regexm(main,"CEREBROSPINAL MENINGITIS")

replace main = main+",CEREBROSPINAL SCLEROSIS" if regexm(disease,"CEREBROSPINE") & regexm(disease,"SCLEROSIS") & main!=""
replace main = "CEREBROSPINAL SCLEROSIS" if regexm(disease,"CEREBROSPINE") & regexm(disease,"SCLEROSIS") & main==""
replace disease = regexr(disease,"CEREBROSPINE","") if regexm(main,"CEREBROSPINAL SCLEROSIS")
replace disease = regexr(disease,"SCLEROSIS","") if regexm(main,"CEREBROSPINAL SCLEROSIS")

replace main = main+",CERVICODORSAL CARIES" if regexm(disease,"CERVICODORSUM") & regexm(disease,"CARIES") & main!=""
replace main = "CERVICODORSAL CARIES" if regexm(disease,"CERVICODORSUM") & regexm(disease,"CARIES")  & main==""
replace disease = regexr(disease,"CERVICODORSUM","") if regexm(main,"CERVICODORSAL CARIES")
replace disease = regexr(disease,"CARIES","") if regexm(main,"CERVICODORSAL CARIES")

replace main = main+",CHICKEN POX" if regexm(disease,"CHICKEN") & regexm(disease,"POX") & main!=""
replace main = "CHICKEN POX" if regexm(disease,"CHICKEN") & regexm(disease,"POX")  & main==""
replace disease = regexr(disease,"CHICKEN","") if regexm(main,"CHICKEN POX")
replace disease = regexr(disease,"POX","") if regexm(main,"CHICKEN POX")

replace main = main+",CHOLERA INFANTUM" if regexm(disease,"CHOLERA") & regexm(disease,"INFANTUM") & main!=""
replace main = "CHOLERA INFANTUM" if regexm(disease,"CHOLERA") & regexm(disease,"INFANTUM") & main==""
replace disease = regexr(disease,"CHOLERA","") if regexm(main,"CHOLERA INFANTUM")
replace disease = regexr(disease,"INFANTUM","") if regexm(main,"CHOLERA INFANTUM")

replace main = main+",CHOLERA NOSTRAS" if regexm(disease,"CHOLERA") & regexm(disease,"NOSTRAS") & main!=""
replace main = "CHOLERA NOSTRAS" if regexm(disease,"CHOLERA") & regexm(disease,"NOSTRAS") & main==""
replace disease = regexr(disease,"CHOLERA","") if regexm(main,"CHOLERA NOSTRAS")
replace disease = regexr(disease,"NOSTRAS","") if regexm(main,"CHOLERA NOSTRAS")

replace main = main+",CLAW HAND" if regexm(disease,"CLAW") & regexm(disease,"HAND") & main!=""
replace main = "CLAW HAND" if regexm(disease,"CLAW") & regexm(disease,"HAND")  & main==""
replace disease = regexr(disease,"CLAW","") if regexm(main,"CLAW HAND")
replace disease = regexr(disease,"HAND","") if regexm(main,"CLAW HAND")

replace main = main+",CLAW TOE" if regexm(disease,"CLAW") & regexm(disease,"TOE") & main!=""
replace main = "CLAW TOE" if regexm(disease,"CLAW") & regexm(disease,"TOE")  & main==""
replace disease = regexr(disease,"CLAW","") if regexm(main,"CLAW TOE")
replace disease = regexr(disease,"TOE","") if regexm(main,"CLAW TOE")

replace main = main+",CLEFT PALATE" if regexm(disease,"CLEFT") & regexm(disease,"PALATE") & main!=""
replace main = "CLEFT PALATE" if regexm(disease,"CLEFT") & regexm(disease,"PALATE") & main==""
replace disease = regexr(disease,"CLEFT","") if regexm(main,"CLEFT PALATE")
replace disease = regexr(disease,"PALATE","") if regexm(main,"CLEFT PALATE")

replace main = main+",CLUB FOOT" if regexm(disease,"CLUB") & regexm(disease,"FOOT") & main!=""
replace main = "CLUB FOOT" if regexm(disease,"CLUB") & regexm(disease,"FOOT")  & main==""
replace disease = regexr(disease,"CLUB","") if regexm(main,"CLUB FOOT")
replace disease = regexr(disease,"FOOT","") if regexm(main,"CLUB FOOT")

replace main = main+",CLUBBED FINGER" if regexm(disease,"CLUBBED") & regexm(disease,"FINGER") & main!=""
replace main = "CLUBBED FINGER" if regexm(disease,"CLUBBED") & regexm(disease,"FINGER")  & main==""
replace disease = regexr(disease,"CLUBBED","") if regexm(main,"CLUBBED FINGER")
replace disease = regexr(disease,"FINGER","") if regexm(main,"CLUBBED FINGER")

replace main = main+",COLLAPSED LUNG" if regexm(disease,"COLLAPSED") & regexm(disease,"LUNG") & main!=""
replace main = "COLLAPSED LUNG" if regexm(disease,"COLLAPSED") & regexm(disease,"LUNG")  & main==""
replace disease = regexr(disease,"COLLAPSED","") if regexm(main,"COLLAPSED LUNG")
replace disease = regexr(disease,"LUNG","") if regexm(main,"COLLAPSED LUNG")

replace main = main+",DIASTASIS CORDIS" if regexm(disease,"DIASTASIS") & regexm(disease,"CORDIS") & main!=""
replace main = "DIASTASIS CORDIS" if regexm(disease,"DIASTASIS") & regexm(disease,"CORDIS") & main==""
replace disease = regexr(disease,"DIASTASIS","") if regexm(main,"DIASTASIS CORDIS")
replace disease = regexr(disease,"CORDIS","") if regexm(main,"DIASTASIS CORDIS")

replace main = main+",DIPHTHERITIC CONJUNCTIVITIS" if regexm(disease,"DIPHTHERIA") & regexm(disease,"CONJUNCTIVITIS") & main!=""
replace main = "DIPHTHERITIC CONJUNCTIVITIS" if regexm(disease,"DIPHTHERIA") & regexm(disease,"CONJUNCTIVITIS") & main==""
replace disease = regexr(disease,"DIPHTHERIA","") if regexm(main,"DIPHTHERITIC CONJUNCTIVITIS")
replace disease = regexr(disease,"CONJUNCTIVITIS","") if regexm(main,"DIPHTHERITIC CONJUNCTIVITIS")

replace main = main+",DIPHTHERITIC PARALYSIS" if regexm(disease,"DIPHTHERIA") & regexm(disease,"PARALYSIS") & main!=""
replace main = "DIPHTHERITIC PARALYSIS" if regexm(disease,"DIPHTHERIA") & regexm(disease,"PARALYSIS") & main==""
replace disease = regexr(disease,"DIPHTHERIA","") if regexm(main,"DIPHTHERITIC PARALYSIS")
replace disease = regexr(disease,"PARALYSIS","") if regexm(main,"DIPHTHERITIC PARALYSIS")

replace main = main+",CONVERGENT CONCOMITANT STRABISMUS" if regexm(disease,"CONVERGENT") & regexm(disease,"CONCOMITANT") & regexm(disease,"STRABISMUS") & main!=""
replace main = "CONVERGENT CONCOMITANT STRABISMUS" if regexm(disease,"CONVERGENT") & regexm(disease,"CONCOMITANT") & regexm(disease,"STRABISMUS") & main==""
replace disease = regexr(disease,"CONVERGENT","") if regexm(main,"CONVERGENT CONCOMITANT STRABISMUS")
replace disease = regexr(disease,"CONCOMITANT","") if regexm(main,"CONVERGENT CONCOMITANT STRABISMUS")
replace disease = regexr(disease,"STRABISMUS","") if regexm(main,"CONVERGENT CONCOMITANT STRABISMUS")

replace main = main+",CONVERGENT STRABISMUS" if regexm(disease,"CONVERGENT") & regexm(disease,"STRABISMUS") & main!=""
replace main = "CONVERGENT STRABISMUS" if regexm(disease,"CONVERGENT") & regexm(disease,"STRABISMUS") & main==""
replace disease = regexr(disease,"CONVERGENT","") if regexm(main,"CONVERGENT STRABISMUS")
replace disease = regexr(disease,"STRABISMUS","") if regexm(main,"CONVERGENT STRABISMUS")

replace main = main+",COW LUNG" if regexm(disease,"COW") & regexm(disease,"LUNG") & main!=""
replace main = "COW LUNG" if regexm(disease,"COW") & regexm(disease,"LUNG") & main==""
replace disease = regexr(disease,"COW","") if regexm(main,"COW LUNG")
replace disease = regexr(disease,"LUNG","") if regexm(main,"COW LUNG")

replace main = main+",COXA VARA" if regexm(disease,"COXA") & regexm(disease,"VARA") & main!=""
replace main = "COXA VARA" if regexm(disease,"COXA") & regexm(disease,"VARA")  & main==""
replace disease = regexr(disease,"COXA","") if regexm(main,"COXA VARA")
replace disease = regexr(disease,"VARA","") if regexm(main,"COXA VARA")

replace main = main+",CYSTIC HYGROMA" if regexm(disease,"CYSTIC") & regexm(disease,"HYGROMA") & main!=""
replace main = "CYSTIC HYGROMA" if regexm(disease,"CYSTIC") & regexm(disease,"HYGROMA")  & main==""
replace disease = regexr(disease,"CYSTIC","") if regexm(main,"CYSTIC HYGROMA")
replace disease = regexr(disease,"HYGROMA","") if regexm(main,"CYSTIC HYGROMA")

replace main = main+",CYSTIC SARCOMA" if regexm(disease,"CYSTIC") & regexm(disease,"SARCOMA") & main!=""
replace main = "CYSTIC SARCOMA" if regexm(disease,"CYSTIC") & regexm(disease,"SARCOMA")  & main==""
replace disease = regexr(disease,"CYSTIC","") if regexm(main,"CYSTIC SARCOMA")
replace disease = regexr(disease,"SARCOMA","") if regexm(main,"CYSTIC SARCOMA")

replace main = main+",DIABETES INSIPIDUS" if regexm(disease,"DIABETES") & regexm(disease,"INSIPIDUS") & main!=""
replace main = "DIABETES INSIPIDUS" if regexm(disease,"DIABETES") & regexm(disease,"INSIPIDUS")  & main==""
replace disease = regexr(disease,"DIABETES","") if regexm(main,"DIABETES INSIPIDUS")
replace disease = regexr(disease,"INSIPIDUS","") if regexm(main,"DIABETES INSIPIDUS")

replace main = main+",DIABETES MELLITUS" if regexm(disease,"DIABETES") & regexm(disease,"MELLITUS") & main!=""
replace main = "DIABETES MELLITUS" if regexm(disease,"DIABETES") & regexm(disease,"MELLITUS")  & main==""
replace disease = regexr(disease,"DIABETES","") if regexm(main,"DIABETES MELLITUS")
replace disease = regexr(disease,"MELLITUS","") if regexm(main,"DIABETES MELLITUS")

replace main = main+",DIAPHRAGMATIC PLEURISY" if regexm(disease,"DIAPHRAGMATIC") & regexm(disease,"PLEURISY") & main!=""
replace main = "DIAPHRAGMATIC PLEURISY" if regexm(disease,"DIAPHRAGMATIC") & regexm(disease,"PLEURISY")  & main==""
replace disease = regexr(disease,"DIAPHRAGMATIC","") if regexm(main,"DIAPHRAGMATIC PLEURISY")
replace disease = regexr(disease,"PLEURISY","") if regexm(main,"DIAPHRAGMATIC PLEURISY")

replace main = main+",DISSEMINATED SCLEROSIS" if regexm(disease,"DISSEMINATED") & regexm(disease,"SCLEROSIS") & main!=""
replace main = "DISSEMINATED SCLEROSIS" if regexm(disease,"DISSEMINATED") & regexm(disease,"SCLEROSIS")  & main==""
replace disease = regexr(disease,"DISSEMINATED","") if regexm(main,"DISSEMINATED SCLEROSIS")
replace disease = regexr(disease,"SCLEROSIS","") if regexm(main,"DISSEMINATED SCLEROSIS")

replace main = main+",INSULAR SCLEROSIS" if regexm(disease,"INSULAR") & regexm(disease,"SCLEROSIS") & main!=""
replace main = "INSULAR SCLEROSIS" if regexm(disease,"INSULAR") & regexm(disease,"SCLEROSIS")  & main==""
replace disease = regexr(disease,"INSULAR","") if regexm(main,"INSULAR SCLEROSIS")
replace disease = regexr(disease,"SCLEROSIS","") if regexm(main,"INSULAR SCLEROSIS")

replace main = main+",DIVERGENT STRABISMUS" if regexm(disease,"DIVERGENT") & regexm(disease,"STRABISMUS") & main!=""
replace main = "DIVERGENT STRABISMUS" if regexm(disease,"DIVERGENT") & regexm(disease,"STRABISMUS") & main==""
replace disease = regexr(disease,"DIVERGENT","") if regexm(main,"DIVERGENT STRABISMUS")
replace disease = regexr(disease,"STRABISMUS","") if regexm(main,"DIVERGENT STRABISMUS")

replace main = main+",DUCHENNES PARALYSIS" if regexm(disease,"DUCHENNES") & regexm(disease,"PARALYSIS") & main!=""
replace main = "DUCHENNES PARALYSIS" if regexm(disease,"DUCHENNES") & regexm(disease,"PARALYSIS") & main==""
replace disease = regexr(disease,"DUCHENNES","") if regexm(main,"DUCHENNES PARALYSIS")
replace disease = regexr(disease,"PARALYSIS","") if regexm(main,"DUCHENNES PARALYSIS")

replace main = main+",EMPYEMA THORACIS" if regexm(disease,"EMPYEMA") & regexm(disease,"THORACIS") & main!=""
replace main = "EMPYEMA THORACIS" if regexm(disease,"EMPYEMA") & regexm(disease,"THORACIS")  & main==""
replace disease = regexr(disease,"EMPYEMA","") if regexm(main,"EMPYEMA THORACIS")
replace disease = regexr(disease,"THORACIS","") if regexm(main,"EMPYEMA THORACIS")

replace main = main+",EXTERNAL STRABISMUS" if regexm(disease,"EXTERNAL") & regexm(disease,"STRABISMUS") & main!=""
replace main = "EXTERNAL STRABISMUS" if regexm(disease,"EXTERNAL") & regexm(disease,"STRABISMUS") & main==""
replace disease = regexr(disease,"CONVERGENT","") if regexm(main,"EXTERNAL STRABISMUS")
replace disease = regexr(disease,"EXTERNAL","") if regexm(main,"EXTERNAL STRABISMUS")

replace main = main+",EXTROVERTED BLADDER" if regexm(disease,"EXTROVERTED") & regexm(disease,"BLADDER") & main!=""
replace main = "EXTROVERTED BLADDER" if regexm(disease,"EXTROVERTED") & regexm(disease,"BLADDER")  & main==""
replace disease = regexr(disease,"EXTROVERTED","") if regexm(main,"EXTROVERTED BLADDER")
replace disease = regexr(disease,"BLADDER","") if regexm(main,"EXTROVERTED BLADDER")

replace main = main+",EXFOLIATIVE DERMATITIS" if regexm(disease,"EXFOLIATIVE") & regexm(disease,"DERMATITIS") & main!=""
replace main = "EXFOLIATIVE DERMATITIS" if regexm(disease,"EXFOLIATIVE") & regexm(disease,"DERMATITIS")  & main==""
replace disease = regexr(disease,"EXFOLIATIVE","") if regexm(main,"EXFOLIATIVE DERMATITIS")
replace disease = regexr(disease,"DERMATITIS","") if regexm(main,"EXFOLIATIVE DERMATITIS")

replace main = main+",INTERNAL STRABISMUS" if regexm(disease,"INTERNAL") & regexm(disease,"STRABISMUS") & main!=""
replace main = "INTERNAL STRABISMUS" if regexm(disease,"INTERNAL") & regexm(disease,"STRABISMUS") & main==""
replace disease = regexr(disease,"INTERNAL","") if regexm(main,"INTERNAL STRABISMUS")
replace disease = regexr(disease,"STRABISMUS","") if regexm(main,"INTERNAL STRABISMUS")

replace main = main+",DENTIGEROUS CYST" if regexm(disease,"DENTIGEROUS") & regexm(disease,"CYST") & main!=""
replace main = "DENTIGEROUS CYST" if regexm(disease,"DENTIGEROUS") & regexm(disease,"CYST")  & main==""
replace disease = regexr(disease,"DENTIGEROUS","") if regexm(main,"DENTIGEROUS CYST")
replace disease = regexr(disease,"CYST","") if regexm(main,"DENTIGEROUS CYST")

replace main = main+",ECTOPIA VESICA" if regexm(disease,"ECTOPIA") & regexm(disease,"VESICA(E)*") & main!=""
replace main = "ECTOPIA VESICA" if regexm(disease,"ECTOPIA") & regexm(disease,"VESICA(E)*") & main==""
replace disease = regexr(disease,"ECTOPIA","") if regexm(main,"ECTOPIA VESICA")
replace disease = regexr(disease,"VESICA(E)*","") if regexm(main,"ECTOPIA VESICA")

replace main = main+",ECZEMA ALBINA" if regexm(disease,"ECZEMA") & regexm(disease,"ALBINA") & main!=""
replace main = "ECZEMA ALBINA" if regexm(disease,"ECZEMA") & regexm(disease,"ALBINA") & main==""
replace disease = regexr(disease,"ECZEMA","") if regexm(main,"ECZEMA ALBINA")
replace disease = regexr(disease,"ALBINA","") if regexm(main,"ECZEMA ALBINA")

replace main = main+",EDEMATOUS LARYNGITIS" if regexm(disease,"EDEMATOUS") & regexm(disease,"LARYNGITIS") & main!=""
replace main = "EDEMATOUS LARYNGITIS" if regexm(disease,"EDEMATOUS") & regexm(disease,"LARYNGITIS")  & main==""
replace disease = regexr(disease,"EDEMATOUS","") if regexm(main,"EDEMATOUS LARYNGITIS")
replace disease = regexr(disease,"LARYNGITIS","") if regexm(main,"EDEMATOUS LARYNGITIS")

replace main = main+",ENCYSTED HYDROCELE" if regexm(disease,"ENCYSTED") & regexm(disease,"HYDROCELE") & main!=""
replace main = "ENCYSTED HYDROCELE" if regexm(disease,"ENCYSTED") & regexm(disease,"HYDROCELE")  & main==""
replace disease = regexr(disease,"ENCYSTED","") if regexm(main,"ENCYSTED HYDROCELE")
replace disease = regexr(disease,"HYDROCELE","") if regexm(main,"ENCYSTED HYDROCELE")

replace main = main+",ENGLISH CHOLERA" if regexm(disease,"ENGLISH") & regexm(disease,"CHOLERA") & main!=""
replace main = "ENGLISH CHOLERA" if regexm(disease,"ENGLISH") & regexm(disease,"CHOLERA")  & main==""
replace disease = regexr(disease,"ENGLISH","") if regexm(main,"ENGLISH CHOLERA")
replace disease = regexr(disease,"CHOLERA","") if regexm(main,"ENGLISH CHOLERA")

replace main = main+",GASTROENTERIC CATARRH" if regexm(disease,"GASTROENTERIC") & regexm(disease,"CATARRH") & main!=""
replace main = "GASTROENTERIC CATARRH" if regexm(disease,"GASTROENTERIC") & regexm(disease,"CATARRH")  & main==""
replace disease = regexr(disease,"GASTROENTERIC","") if regexm(main,"GASTROENTERIC CATARRH")
replace disease = regexr(disease,"CATARRH","") if regexm(main,"GASTROENTERIC CATARRH")

replace main = main+",ENTERIC FEVER" if regexm(disease,"ENTERIC") & regexm(disease,"FEVER") & main!=""
replace main = "ENTERIC FEVER" if regexm(disease,"ENTERIC") & regexm(disease,"FEVER")  & main==""
replace disease = regexr(disease,"ENTERIC","") if regexm(main,"ENTERIC FEVER")
replace disease = regexr(disease,"FEVER","") if regexm(main,"ENTERIC FEVER")

replace main = main+",ERBS PALSY" if regexm(disease,"ERBS") & regexm(disease,"PALSY") & main!=""
replace main = "ERBS PALSY" if regexm(disease,"ERBS") & regexm(disease,"PALSY")  & main==""
replace disease = regexr(disease,"ERBS","") if regexm(main,"ERBS PALSY")
replace disease = regexr(disease,"PALSY","") if regexm(main,"ERBS PALSY")

replace main = main+",ERYTHEMA MULTIFORME" if regexm(disease,"ERYTHEMA") & regexm(disease,"MULTIFORME") & main!=""
replace main = "ERYTHEMA MULTIFORME" if regexm(disease,"ERYTHEMA") & regexm(disease,"MULTIFORME") & main==""
replace disease = regexr(disease,"ERYTHEMA","") if regexm(main,"ERYTHEMA MULTIFORME")
replace disease = regexr(disease,"MULTIFORME","") if regexm(main,"ERYTHEMA MULTIFORME")

replace main = main+",ERYTHEMA NODOSUM" if regexm(disease,"ERYTHEMA") & regexm(disease,"NODOSUM") & main!=""
replace main = "ERYTHEMA NODOSUM" if regexm(disease,"ERYTHEMA") & regexm(disease,"NODOSUM") & main==""
replace disease = regexr(disease,"ERYTHEMA","") if regexm(main,"ERYTHEMA NODOSUM")
replace disease = regexr(disease,"NODOSUM","") if regexm(main,"ERYTHEMA NODOSUM")

replace main = main+",ERYTHEMA URTICARIA" if regexm(disease,"ERYTHEMA") & regexm(disease,"URTICARIA") & main!=""
replace main = "ERYTHEMA URTICARIA" if regexm(disease,"ERYTHEMA") & regexm(disease,"URTICARIA") & main==""
replace disease = regexr(disease,"ERYTHEMA","") if regexm(main,"ERYTHEMA URTICARIA")
replace disease = regexr(disease,"URTICARIA","") if regexm(main,"ERYTHEMA URTICARIA")

replace main = main+",ESSENTIAL TREMOR" if regexm(disease,"ESSENTIAL") & regexm(disease,"TREMOR") & main!=""
replace main = "ESSENTIAL TREMOR" if regexm(disease,"ESSENTIAL") & regexm(disease,"TREMOR")  & main==""
replace disease = regexr(disease,"ESSENTIAL","") if regexm(main,"ESSENTIAL TREMOR")
replace disease = regexr(disease,"TREMOR","") if regexm(main,"ESSENTIAL TREMOR")

replace main = main+",FAVUS CAPITIS" if regexm(disease,"FAVUS") & regexm(disease,"CAPITIS") & main!=""
replace main = "FAVUS CAPITIS" if regexm(disease,"FAVUS") & regexm(disease,"CAPITIS")  & main==""
replace disease = regexr(disease,"FAVUS","") if regexm(main,"FAVUS CAPITIS")
replace disease = regexr(disease,"CAPITIS","") if regexm(main,"FAVUS CAPITIS")

replace main = main+",FLAT FOOT" if regexm(disease,"FLAT") & regexm(disease,"FOOT") & main!=""
replace main = "FLAT FOOT" if regexm(disease,"FLAT") & regexm(disease,"FOOT")  & main==""
replace disease = regexr(disease,"FLAT","") if regexm(main,"FLAT FOOT")
replace disease = regexr(disease,"FOOT","") if regexm(main,"FLAT FOOT")

replace main = main+",FOLLICULAR TONSILLITIS" if regexm(disease,"FOLLICULAR") & regexm(disease,"TONSILLITIS") & main!=""
replace main = "FOLLICULAR TONSILLITIS" if regexm(disease,"FOLLICULAR") & regexm(disease,"TONSILLITIS")  & main==""
replace disease = regexr(disease,"FOLLICULAR","") if regexm(main,"FOLLICULAR TONSILLITIS")
replace disease = regexr(disease,"TONSILLITIS","") if regexm(main,"FOLLICULAR TONSILLITIS")

replace main = main+",FRIEDREICHS ATAXIA" if regexm(disease,"FRIEDREICHS") & regexm(disease,"ATAXIA") & main!=""
replace main = "FRIEDREICHS ATAXIA" if regexm(disease,"FRIEDREICHS") & regexm(disease,"ATAXIA")  & main==""
replace disease = regexr(disease,"FRIEDREICHS","") if regexm(main,"FRIEDREICHS ATAXIA")
replace disease = regexr(disease,"ATAXIA","") if regexm(main,"FRIEDREICHS ATAXIA")

replace main = main+",FRIEDREICHS CATARACT" if regexm(disease,"FRIEDREICHS") & regexm(disease,"CATARACT") & main!=""
replace main = "FRIEDREICHS CATARACT" if regexm(disease,"FRIEDREICHS") & regexm(disease,"CATARACT")  & main==""
replace disease = regexr(disease,"FRIEDREICHS","") if regexm(main,"FRIEDREICHS CATARACT")
replace disease = regexr(disease,"CATARACT","") if regexm(main,"FRIEDREICHS CATARACT")

replace main = main+",FUNGAL DISEASE" if regexm(disease,"FUNGAL") & regexm(disease,"DISEASE") & main!=""
replace main = "FUNGAL DISEASE" if regexm(disease,"FUNGAL") & regexm(disease,"DISEASE") & main==""
replace disease = regexr(disease,"FUNGAL","") if regexm(main,"FUNGAL DISEASE")
replace disease = regexr(disease,"DISEASE","") if regexm(main,"FUNGAL DISEASE")

replace main = main+",GASTROINTESTINAL DISEASE" if regexm(disease,"GASTROINTESTIN(E)*(AL)*") & regexm(disease,"DISEASE") & main!=""
replace main = "GASTROINTESTINAL DISEASE" if regexm(disease,"GASTROINTESTIN(E)*(AL)*") & regexm(disease,"DISEASE") & main==""
replace disease = regexr(disease,"GASTROINTESTIN(E)*(AL)*","") if regexm(main,"GASTROINTESTINAL DISEASE")
replace disease = regexr(disease,"DISEASE","") if regexm(main,"GASTROINTESTINAL DISEASE")

replace main = main+",GENU VALGUM" if regexm(disease,"GENU") & regexm(disease,"VALGUM") & main!=""
replace main = "GENU VALGUM" if regexm(disease,"GENU") & regexm(disease,"VALGUM")  & main==""
replace disease = regexr(disease,"GENU","") if regexm(main,"GENU VALGUM")
replace disease = regexr(disease,"VALGUM","") if regexm(main,"GENU VALGUM")

replace main = main+",GENU VARUM" if regexm(disease,"GENU") & regexm(disease,"VARUM") & main!=""
replace main = "GENU VARUM" if regexm(disease,"GENU") & regexm(disease,"VARUM")  & main==""
replace disease = regexr(disease,"GENU","") if regexm(main,"GENU VARUM")
replace disease = regexr(disease,"VARUM","") if regexm(main,"GENU VARUM")

replace main = main+",GERMAN MEASLES" if regexm(disease,"GERMAN") & regexm(disease,"MEASLES") & main!=""
replace main = "GERMAN MEASLES" if regexm(disease,"GERMAN") & regexm(disease,"MEASLES")  & main==""
replace disease = regexr(disease,"GERMAN","") if regexm(main,"GERMAN MEASLES")
replace disease = regexr(disease,"MEASLES","") if regexm(main,"GERMAN MEASLES")

replace main = main+",GRANULAR OPHTHALMIA" if regexm(disease,"GRANULAR") & regexm(disease,"OPHTHALMIA") & main!=""
replace main = "GRANULAR OPHTHALMIA" if regexm(disease,"GRANULAR") & regexm(disease,"OPHTHALMIA")  & main==""
replace disease = regexr(disease,"GRANULAR","") if regexm(main,"GRANULAR OPHTHALMIA")
replace disease = regexr(disease,"OPHTHALMIA","") if regexm(main,"GRANULAR OPHTHALMIA")

replace main = main+",HALLUX VALGUS" if regexm(disease,"HALLUX") & regexm(disease,"VALGUS") & main!=""
replace main = "HALLUX VALGUS" if regexm(disease,"HALLUX") & regexm(disease,"VALGUS")  & main==""
replace disease = regexr(disease,"HALLUX","") if regexm(main,"HALLUX VALGUS")
replace disease = regexr(disease,"VALGUS","") if regexm(main,"HALLUX VALGUS")

replace main = main+",HAMMER TOE" if regexm(disease,"HAMMER") & regexm(disease,"TOE") & main!=""
replace main = "HAMMER TOE" if regexm(disease,"HAMMER") & regexm(disease,"TOE")  & main==""
replace disease = regexr(disease,"HAMMER","") if regexm(main,"HAMMER TOE")
replace disease = regexr(disease,"TOE","") if regexm(main,"HAMMER TOE")

replace main = main+",HEBRAS PRURIGO" if regexm(disease,"HEBRA(S)*") & regexm(disease,"PRURIGO") & main!=""
replace main = "HEBRAS PRURIGO" if regexm(disease,"HEBRA(S)*") & regexm(disease,"PRURIGO")  & main==""
replace disease = regexr(disease,"HEBRA(S)*","") if regexm(main,"HEBRAS PRURIGO")
replace disease = regexr(disease,"PRURIGO","") if regexm(main,"HEBRAS PRURIGO")

replace main = main+",INFANTILE PRURIGO" if regexm(disease,"INFANTILE") & regexm(disease,"PRURIGO") & main!=""
replace main = "INFANTILE PRURIGO" if regexm(disease,"INFANTILE") & regexm(disease,"PRURIGO")  & main==""
replace disease = regexr(disease,"INFANTILE","") if regexm(main,"INFANTILE PRURIGO")
replace disease = regexr(disease,"PRURIGO","") if regexm(main,"INFANTILE PRURIGO")

replace main = main+",HEAD LICE" if regexm(disease,"HEAD") & regexm(disease,"LICE") & main!=""
replace main = "HEAD LICE" if regexm(disease,"HEAD") & regexm(disease,"LICE") & main==""
replace disease = regexr(disease,"HEAD","") if regexm(main,"HEAD LICE")
replace disease = regexr(disease,"LICE","") if regexm(main,"HEAD LICE")

replace main = main+",HERPES ZOSTER" if regexm(disease,"HERPES") & regexm(disease,"ZOSTER") & main!=""
replace main = "HERPES ZOSTER" if regexm(disease,"HERPES") & regexm(disease,"ZOSTER")  & main==""
replace disease = regexr(disease,"HERPES","") if regexm(main,"HERPES ZOSTER")
replace disease = regexr(disease,"ZOSTER","") if regexm(main,"HERPES ZOSTER")

replace main = main+",HUNTINGTON'S CHOREA" if regexm(disease,"HUNTINGTONS") & regexm(disease,"CHOREA") & main!=""
replace main = "HUNTINGTON'S CHOREA" if regexm(disease,"HUNTINGTONS") & regexm(disease,"CHOREA") & main==""
replace disease = regexr(disease,"HUNTINGTONS","") if regexm(main,"HUNTINGTON'S CHOREA")
replace disease = regexr(disease,"CHOREA","") if regexm(main,"HUNTINGTON'S CHOREA")

replace main = main+",HYDROPS ARTICULI" if regexm(disease,"HYDROPS") & regexm(disease,"ARTICULI") & main!=""
replace main = "HYDROPS ARTICULI" if regexm(disease,"HYDROPS") & regexm(disease,"ARTICULI")  & main==""
replace disease = regexr(disease,"HYDROPS","") if regexm(main,"HYDROPS ARTICULI")
replace disease = regexr(disease,"ARTICULI","") if regexm(main,"HYDROPS ARTICULI")

replace main = main+",HYDROA VACCINIFORME" if regexm(disease,"HYDROA") & regexm(disease,"VACCINIFORME") & main!=""
replace main = "HYDROA VACCINIFORME" if regexm(disease,"HYDROA") & regexm(disease,"VACCINIFORME")  & main==""
replace disease = regexr(disease,"HYDROA","") if regexm(main,"HYDROA VACCINIFORME")
replace disease = regexr(disease,"VACCINIFORME","") if regexm(main,"HYDROA VACCINIFORME")

replace main = main+",IMPERFORATE ANUS" if regexm(disease,"IMPERFORATE") & (regexm(disease,"ANUS") | regexm(disease,"RECTUM")) & main!=""
replace main = "IMPERFORATE ANUS" if regexm(disease,"IMPERFORATE") & (regexm(disease,"ANUS") | regexm(disease,"RECTUM")) & main==""
replace disease = regexr(disease,"IMPERFORATE","") if regexm(main,"IMPERFORATE ANUS")
replace disease = regexr(disease,"ANUS","") if regexm(main,"IMPERFORATE ANUS")
replace disease = regexr(disease,"RECTUM","") if regexm(main,"IMPERFORATE ANUS")

replace main = main+",INFANTILE CONVULSIONS" if regexm(disease,"INFANTILE") & regexm(disease,"CONVULSION(S)*") & main!=""
replace main = "INFANTILE PRURIGO" if regexm(disease,"INFANTILE") & regexm(disease,"CONVULSION(S)*")  & main==""
replace disease = regexr(disease,"INFANTILE","") if regexm(main,"INFANTILE CONVULSIONS")
replace disease = regexr(disease,"CONVULSION(S)*","") if regexm(main,"INFANTILE CONVULSIONS")

replace main = main+",INFANTILE PARALYSIS" if regexm(disease,"INFANTILE") & regexm(disease,"PARALYSIS") & main!=""
replace main = "INFANTILE PARALYSIS" if regexm(disease,"INFANTILE") & regexm(disease,"PARALYSIS")  & main==""
replace disease = regexr(disease,"INFANTILE","") if regexm(main,"INFANTILE PARALYSIS")
replace disease = regexr(disease,"PARALYSIS","") if regexm(main,"INFANTILE PARALYSIS")

replace main = main+",INTERSTITIAL HERNIA" if regexm(disease,"INTERSTITIAL") & regexm(disease,"HERNIA") & main!=""
replace main = "INTERSTITIAL HERNIA" if regexm(disease,"INTERSTITIAL") & regexm(disease,"HERNIA")  & main==""
replace disease = regexr(disease,"INTERSTITIAL","") if regexm(main,"INTERSTITIAL HERNIA")
replace disease = regexr(disease,"HERNIA","") if regexm(main,"INTERSTITIAL HERNIA")

replace main = main+",INTESTINAL COLIC" if regexm(disease,"INTESTINAL") & regexm(disease,"COLIC") & main!=""
replace main = "INTESTINAL COLIC" if regexm(disease,"COLIC") & regexm(disease,"INTESTINAL") & main==""
replace disease = regexr(disease,"INTESTINAL","") if regexm(main,"INTESTINAL COLIC")
replace disease = regexr(disease,"COLIC","") if regexm(main,"INTESTINAL COLIC")

replace main = main+",INCARCERATED HERNIA" if regexm(disease,"INCARCERATED") & regexm(disease,"HERNIA") & main!=""
replace main = "INCARCERATED HERNIA" if regexm(disease,"INCARCERATED") & regexm(disease,"HERNIA")  & main==""
replace disease = regexr(disease,"INCARCERATED","") if regexm(main,"INCARCERATED HERNIA")
replace disease = regexr(disease,"HERNIA","") if regexm(main,"INCARCERATED HERNIA")

replace main = main+",INTERMITTENT SQUINT" if regexm(disease,"INTERMITTENT") & regexm(disease,"SQUINT") & main!=""
replace main = "INTERMITTENT SQUINT" if regexm(disease,"INTERMITTENT") & regexm(disease,"SQUINT") & main==""
replace disease = regexr(disease,"INTERMITTENT","") if regexm(main,"INTERMITTENT SQUINT")
replace disease = regexr(disease,"SQUINT","") if regexm(main,"INTERMITTENT SQUINT")

replace main = main+",INSPIRATORY DYSPNEA" if regexm(disease,"INSPIRATORY") & regexm(disease,"DYSPNEA") & main!=""
replace main = "INSPIRATORY DYSPNEA" if regexm(disease,"INSPIRATORY") & regexm(disease,"DYSPNEA") & main==""
replace disease = regexr(disease,"INSPIRATORY","") if regexm(main,"INSPIRATORY DYSPNEA")
replace disease = regexr(disease,"DYSPNEA","") if regexm(main,"INSPIRATORY DYSPNEA")

replace main = main+",INTERSTITIAL KERATITIS" if regexm(disease,"INTERSTITIAL") & regexm(disease,"KERATITIS") & main!=""
replace main = "INTERSTITIAL KERATITIS" if regexm(disease,"INTERSTITIAL") & regexm(disease,"KERATITIS")  & main==""
replace disease = regexr(disease,"INTERSTITIAL","") if regexm(main,"INTERSTITIAL KERATITIS")
replace disease = regexr(disease,"KERATITIS","") if regexm(main,"INTERSTITIAL KERATITIS")

replace main = main+",INTERSTITIAL NEPHRITIS" if regexm(disease,"INTERSTITIAL") & regexm(disease,"NEPHRITIS") & main!=""
replace main = "INTERSTITIAL NEPHRITIS" if regexm(disease,"INTERSTITIAL") & regexm(disease,"NEPHRITIS")  & main==""
replace disease = regexr(disease,"INTERSTITIAL","") if regexm(main,"INTERSTITIAL NEPHRITIS")
replace disease = regexr(disease,"NEPHRITIS","") if regexm(main,"INTERSTITIAL NEPHRITIS")

replace main = main+",STRANGULATED INGUINAL HERNIA" if (regexm(disease,"INGUINAL") | regexm(disease,"STRANGULATED")) & regexm(disease,"HERNIA") & main!=""
replace main = "STRANGULATED INGUINAL HERNIA" if (regexm(disease,"INGUINAL") | regexm(disease,"STRANGULATED")) & regexm(disease,"HERNIA")  & main==""
replace disease = regexr(disease,"INGUINAL","") if regexm(main,"STRANGULATED INGUINAL HERNIA")
replace disease = regexr(disease,"STRANGULATED","") if regexm(main,"STRANGULATED INGUINAL HERNIA")
replace disease = regexr(disease,"HERNIA","") if regexm(main,"STRANGULATED INGUINAL HERNIA")

replace main = main+",INTERNAL DERANGEMENT" if regexm(disease,"INTERNAL") & regexm(disease,"DERANGEMENT") & main!=""
replace main = "INTERNAL DERANGEMENT" if regexm(disease,"INTERNAL") & regexm(disease,"DERANGEMENT") & main==""
replace disease = regexr(disease,"INTERNAL","") if regexm(main,"INTERNAL DERANGEMENT")
replace disease = regexr(disease,"DERANGEMENT","") if regexm(main,"INTERNAL DERANGEMENT")

replace main = main+",ISCHEMIC CONTRACTURE" if regexm(disease,"ISCHEMIC") & regexm(disease,"CONTRACTURE") & main!=""
replace main = "ISCHEMIC CONTRACTURE" if regexm(disease,"ISCHEMIC") & regexm(disease,"CONTRACTURE") & main==""
replace disease = regexr(disease,"ISCHEMIC","") if regexm(main,"ISCHEMIC CONTRACTURE")
replace disease = regexr(disease,"CONTRACTURE","") if regexm(main,"ISCHEMIC CONTRACTURE")

replace main = main+",JACKSONIAN EPILEPSY" if regexm(disease,"JACKSON") & regexm(disease,"EPILEPSY") & main!=""
replace main = "JACKSONIAN EPILEPSY" if regexm(disease,"JACKSON") & regexm(disease,"EPILEPSY") & main==""
replace disease = regexr(disease,"IRREDUCIBLE","") if regexm(main,"JACKSONIAN EPILEPSY")
replace disease = regexr(disease,"JACKSON","") if regexm(main,"JACKSONIAN EPILEPSY")

replace main = main+",KNOCK KNEE" if regexm(disease,"KNOCK") & regexm(disease,"KNEE") & main!=""
replace main = "KNOCK KNEE" if regexm(disease,"KNOCK") & regexm(disease,"KNEE")  & main==""
replace disease = regexr(disease,"KNOCK","") if regexm(main,"KNOCK KNEE")
replace disease = regexr(disease,"KNEE","") if regexm(main,"KNOCK KNEE")

replace main = main+",LABIOGLOSSAL POUCH" if regexm(disease,"LABIOGLOSSAL") & regexm(disease,"POUCH") & main!=""
replace main = "LABIOGLOSSAL POUCH" if regexm(disease,"LABIOGLOSSAL") & regexm(disease,"POUCH") & main==""
replace disease = regexr(disease,"LABIOGLOSSAL","") if regexm(main,"LABIOGLOSSAL POUCH")
replace disease = regexr(disease,"POUCH","") if regexm(main,"LABIOGLOSSAL POUCH")

replace main = main+",LABYRINTHINE VERTIGO" if regexm(disease,"LABYRINTHINE") & regexm(disease,"VERTIGO") & main!=""
replace main = "LABYRINTHINE VERTIGO" if regexm(disease,"LABYRINTHINE") & regexm(disease,"VERTIGO") & main==""
replace disease = regexr(disease,"LABYRINTHINE","") if regexm(main,"LABYRINTHINE VERTIGO")
replace disease = regexr(disease,"VERTIGO","") if regexm(main,"LABYRINTHINE VERTIGO")

replace main = main+",LABYRINTHINE FISTULA" if regexm(disease,"LABYRINTHINE") & regexm(disease,"FISTULA") & main!=""
replace main = "LABYRINTHINE FISTULA" if regexm(disease,"LABYRINTHINE") & regexm(disease,"FISTULA") & main==""
replace disease = regexr(disease,"LABYRINTHINE","") if regexm(main,"LABYRINTHINE FISTULA")
replace disease = regexr(disease,"FISTULA","") if regexm(main,"LABYRINTHINE FISTULA")

replace main = main+",LAMELLAR CATARACT" if regexm(disease,"LAMELLAR") & regexm(disease,"CATARACT") & main!=""
replace main = "LAMELLAR CATARACT" if regexm(disease,"LAMELLAR") & regexm(disease,"CATARACT") & main==""
replace disease = regexr(disease,"LAMELLAR","") if regexm(main,"LAMELLAR CATARACT")
replace disease = regexr(disease,"CATARACT","") if regexm(main,"LAMELLAR CATARACT")

replace main = main+",LARDACEOUS DISEASE" if regexm(disease,"LARDACEOUS") & regexm(disease,"DISEASE") & main!=""
replace main = "LARDACEOUS DISEASE" if regexm(disease,"LARDACEOUS") & regexm(disease,"DISEASE") & main==""
replace disease = regexr(disease,"LARDACEOUS","") if regexm(main,"LARDACEOUS DISEASE")
replace disease = regexr(disease,"DISEASE","") if regexm(main,"LARDACEOUS DISEASE")

replace main = main+",LARYNGEAL DIPHTHERIA" if regexm(disease,"LARYNGEAL") & regexm(disease,"DIPHTHERIA") & main!=""
replace main = "LARYNGEAL DIPHTHERIA" if regexm(disease,"LARYNGEAL") & regexm(disease,"DIPHTHERIA") & main==""
replace disease = regexr(disease,"LARYNGEAL","") if regexm(main,"LARYNGEAL DIPHTHERIA")
replace disease = regexr(disease,"DIPHTHERIA","") if regexm(main,"LARYNGEAL DIPHTHERIA")

replace main = main+",LARYNGISMUS STRIDULUS" if regexm(disease,"LARYNGISMUS") & regexm(disease,"STRIDULUS") & main!=""
replace main = "LARYNGISMUS STRIDULUS" if regexm(disease,"LARYNGISMUS") & regexm(disease,"STRIDULUS") & main==""
replace disease = regexr(disease,"LARYNGISMUS","") if regexm(main,"LARYNGISMUS STRIDULUS")
replace disease = regexr(disease,"STRIDULUS","") if regexm(main,"LARYNGISMUS STRIDULUS")

replace main = main+",AMYTROPHIC LATERAL SCLEROSIS" if regexm(disease,"LATERAL") & regexm(disease,"SCLEROSIS") & main!=""
replace main = "AMYTROPHIC LATERAL SCLEROSIS" if regexm(disease,"LATERAL") & regexm(disease,"SCLEROSIS") & main==""
replace disease = regexr(disease,"LATERAL","") if regexm(main,"AMYTROPHIC LATERAL SCLEROSIS")
replace disease = regexr(disease,"SCLEROSIS","") if regexm(main,"AMYTROPHIC LATERAL SCLEROSIS")

replace main = main+",LATERAL CURVATURE" if regexm(disease,"LATERAL") & regexm(disease,"CURVATURE") & main!=""
replace main = "LATERAL CURVATURE" if regexm(disease,"LATERAL") & regexm(disease,"CURVATURE")  & main==""
replace disease = regexr(disease,"LATERAL","") if regexm(main,"LATERAL CURVATURE")
replace disease = regexr(disease,"CURVATURE","") if regexm(main,"LATERAL CURVATURE")

replace main = main+",LENTICULAR OPACITY" if regexm(disease,"LENTICULAR") & regexm(disease,"OPACITY") & main!=""
replace main = "LENTICULAR OPACITY" if regexm(disease,"LENTICULAR") & regexm(disease,"OPACITY") & main==""
replace disease = regexr(disease,"LENTICULAR","") if regexm(main,"LENTICULAR OPACITY")
replace disease = regexr(disease,"OPACITY","") if regexm(main,"LENTICULAR OPACITY")

replace main = main+",LOBAR PNEUMONIA" if regexm(disease,"LOBAR") & regexm(disease,"PNEUMONIA") & main!=""
replace main = "LOBAR PNEUMONIA" if regexm(disease,"LOBAR") & regexm(disease,"PNEUMONIA") & main==""
replace disease = regexr(disease,"LOBAR","") if regexm(main,"LOBAR PNEUMONIA")
replace disease = regexr(disease,"PNEUMONIA","") if regexm(main,"LOBAR PNEUMONIA")

replace main = main+",LOCOMOTOR ATAXIA" if regexm(disease,"LOCOMOTOR") & regexm(disease,"ATAXIA") & main!=""
replace main = "LOCOMOTOR ATAXIA" if regexm(disease,"LOCOMOTOR") & regexm(disease,"ATAXIA") & main==""
replace disease = regexr(disease,"LOCOMOTOR","") if regexm(main,"LOCOMOTOR ATAXIA")
replace disease = regexr(disease,"ATAXIA","") if regexm(main,"LOCOMOTOR ATAXIA")

replace main = main+",LUPUS VULGARIS" if regexm(disease,"LUPUS") & regexm(disease,"VULGARIS") & main!=""
replace main = "LUPUS VULGARIS" if regexm(disease,"LUPUS") & regexm(disease,"VULGARIS")  & main==""
replace disease = regexr(disease,"LUPUS","") if regexm(main,"LUPUS VULGARIS")
replace disease = regexr(disease,"VULGARIS","") if regexm(main,"LUPUS VULGARIS")

replace main = main+",MAIN EN GRIFFE" if regexm(disease,"MAIN EN GRIFFE") & main!=""
replace main = "MAIN EN GRIFFE" if regexm(disease,"MAIN EN GRIFFE") & main==""
replace disease = regexr(disease,"MAIN EN GRIFFE","") if regexm(main,"MAIN EN GRIFFE")

replace main = main+",MEATUS URINARIUS" if regexm(disease,"MEATUS") & regexm(disease,"URINARIUS") & main!=""
replace main = "MEATUS URINARIUS" if regexm(disease,"MEATUS") & regexm(disease,"URINARIUS") & main==""
replace disease = regexr(disease,"MEATUS","") if regexm(main,"MEATUS URINARIUS")
replace disease = regexr(disease,"URINARIUS","") if regexm(main,"MEATUS URINARIUS")

replace main = main+",MELANOTIC SARCOMA" if regexm(disease,"MELANOTIC") & regexm(disease,"SARCOMA") & main!=""
replace main = "MELANOTIC SARCOMA" if regexm(disease,"MELANOTIC") & regexm(disease,"SARCOMA") & main==""
replace disease = regexr(disease,"MELANOTIC","") if regexm(main,"MELANOTIC SARCOMA")
replace disease = regexr(disease,"SARCOMA","") if regexm(main,"MELANOTIC SARCOMA")

replace main = main+",MENTAL IMPAIRMENT" if regexm(disease,"MENTAL") & regexm(disease,"IMPAIRMENT") & main!=""
replace main = "MENTAL IMPAIRMENT" if regexm(disease,"MENTAL") & regexm(disease,"IMPAIRMENT") & main==""
replace disease = regexr(disease,"MENTAL","") if regexm(main,"MENTAL IMPAIRMENT")
replace disease = regexr(disease,"IMPAIRMENT","") if regexm(main,"MENTAL IMPAIRMENT")

replace main = main+",MITRAL DISEASE" if regexm(disease,"MITRAL") & regexm(disease,"DISEASE") & main!=""
replace main = "MITRAL DISEASE" if regexm(disease,"MITRAL") & regexm(disease,"DISEASE")  & main==""
replace disease = regexr(disease,"MITRAL","") if regexm(main,"MITRAL DISEASE")
replace disease = regexr(disease,"DISEASE","") if regexm(main,"MITRAL DISEASE")

replace main = main+",MITRAL REGURGITATION" if regexm(disease,"MITRAL") & regexm(disease,"REGURGITATION") & main!=""
replace main = "MITRAL REGURGITATION" if regexm(disease,"MITRAL") & regexm(disease,"REGURGITATION")  & main==""
replace disease = regexr(disease,"MITRAL","") if regexm(main,"MITRAL REGURGITATION")
replace disease = regexr(disease,"REGURGITATION","") if regexm(main,"MITRAL REGURGITATION")

replace main = main+",MITRAL STENOSIS" if regexm(disease,"MITRAL") & regexm(disease,"STENOSIS") & main!=""
replace main = "MITRAL STENOSIS" if regexm(disease,"MITRAL") & regexm(disease,"STENOSIS")  & main==""
replace disease = regexr(disease,"MITRAL","") if regexm(main,"MITRAL STENOSIS")
replace disease = regexr(disease,"STENOSIS","") if regexm(main,"MITRAL STENOSIS")

replace main = main+",MOLLUSCUM CONTAGIOSUM" if regexm(disease,"MOLLUSCUM") & regexm(disease,"CONTAGIOSUM") & main!=""
replace main = "MOLLUSCUM CONTAGIOSUM" if regexm(disease,"MOLLUSCUM") & regexm(disease,"CONTAGIOSUM") & main==""
replace disease = regexr(disease,"MOLLUSCUM","") if regexm(main,"MOLLUSCUM CONTAGIOSUM")
replace disease = regexr(disease,"CONTAGIOSUM","") if regexm(main,"MOLLUSCUM CONTAGIOSUM")

replace main = main+",MORBUS BRIGHTII" if regexm(disease,"MORBUS") & regexm(disease,"BRIGHTII") & main!=""
replace main = "MORBUS BRIGHTII" if regexm(disease,"MORBUS") & regexm(disease,"BRIGHTII")  & main==""
replace disease = regexr(disease,"MORBUS","") if regexm(main,"MORBUS BRIGHTII")
replace disease = regexr(disease,"BRIGHTII","") if regexm(main,"MORBUS BRIGHTII")

replace main = main+",MORBUS CEREBRIS" if regexm(disease,"MORBUS") & regexm(disease,"CEREBRIS") & main!=""
replace main = "MORBUS CEREBRIS" if regexm(disease,"MORBUS") & regexm(disease,"CEREBRIS")  & main==""
replace disease = regexr(disease,"MORBUS","") if regexm(main,"MORBUS CEREBRIS")
replace disease = regexr(disease,"CEREBRIS","") if regexm(main,"MORBUS CEREBRIS")

replace main = main+",MORBUS CORDIS" if regexm(disease,"MORBUS") & regexm(disease,"CORDIS") & main!=""
replace main = "MORBUS CORDIS" if regexm(disease,"MORBUS") & regexm(disease,"CORDIS")  & main==""
replace disease = regexr(disease,"MORBUS","") if regexm(main,"MORBUS CORDIS")
replace disease = regexr(disease,"CORDIS","") if regexm(main,"MORBUS CORDIS")

replace main = main+",MORBUS CORPORIS" if regexm(disease,"MORBUS") & regexm(disease,"CORPORIS") & main!=""
replace main = "MORBUS CORPORIS" if regexm(disease,"MORBUS") & regexm(disease,"CORPORIS")  & main==""
replace disease = regexr(disease,"MORBUS","") if regexm(main,"MORBUS CORPORIS")
replace disease = regexr(disease,"CORPORIS","") if regexm(main,"MORBUS CORPORIS")

replace main = main+",MORBUS COXAE" if regexm(disease,"MORBUS") & regexm(disease,"COXAE") & main!=""
replace main = "MORBUS COXAE" if regexm(disease,"MORBUS") & regexm(disease,"COXAE")  & main==""
replace disease = regexr(disease,"MORBUS","") if regexm(main,"MORBUS COXAE")
replace disease = regexr(disease,"COXAE","") if regexm(main,"MORBUS COXAE")

replace main = main+",MORBUS COXARIUS" if regexm(disease,"MORBUS") & regexm(disease,"COXARIUS") & main!=""
replace main = "MORBUS COXARIUS" if regexm(disease,"MORBUS") & regexm(disease,"COXARIUS")  & main==""
replace disease = regexr(disease,"MORBUS","") if regexm(main,"MORBUS COXARIUS")
replace disease = regexr(disease,"COXARIUS","") if regexm(main,"MORBUS COXARIUS")

replace main = main+",MORBUS GENU" if regexm(disease,"MORBUS") & regexm(disease,"GENU") & main!=""
replace main = "MORBUS GENU" if regexm(disease,"MORBUS") & regexm(disease,"GENU")  & main==""
replace disease = regexr(disease,"MORBUS","") if regexm(main,"MORBUS GENU")
replace disease = regexr(disease,"GENU","") if regexm(main,"MORBUS GENU")

replace main = main+",MORBUS OCULI" if regexm(disease,"MORBUS") & regexm(disease,"OCULI") & main!=""
replace main = "MORBUS OCULI" if regexm(disease,"MORBUS") & regexm(disease,"OCULI")  & main==""
replace disease = regexr(disease,"MORBUS","") if regexm(main,"MORBUS OCULI")
replace disease = regexr(disease,"OCULI","") if regexm(main,"MORBUS OCULI")

replace main = main+",MORBUS PEDIS" if regexm(disease,"MORBUS") & regexm(disease,"PEDIS") & main!=""
replace main = "MORBUS PEDIS" if regexm(disease,"MORBUS") & regexm(disease,"PEDIS")  & main==""
replace disease = regexr(disease,"MORBUS","") if regexm(main,"MORBUS PEDIS")
replace disease = regexr(disease,"PEDIS","") if regexm(main,"MORBUS PEDIS")

replace main = main+",MORBUS PECTORIS" if regexm(disease,"MORBUS") & regexm(disease,"PECTORIS") & main!=""
replace main = "MORBUS PECTORIS" if regexm(disease,"MORBUS") & regexm(disease,"PECTORIS")  & main==""
replace disease = regexr(disease,"MORBUS","") if regexm(main,"MORBUS PECTORIS")
replace disease = regexr(disease,"PECTORIS","") if regexm(main,"MORBUS PECTORIS")

replace main = main+",MORBUS PULMONOSIS" if regexm(disease,"MORBUS") & regexm(disease,"PULMONOSIS") & main!=""
replace main = "MORBUS PULMONOSIS" if regexm(disease,"MORBUS") & regexm(disease,"PULMONOSIS")  & main==""
replace disease = regexr(disease,"MORBUS","") if regexm(main,"MORBUS PULMONOSIS")
replace disease = regexr(disease,"PULMONOSIS","") if regexm(main,"MORBUS PULMONOSIS")

replace main = main+",MORBUS SPINALIS" if regexm(disease,"MORBUS") & regexm(disease,"SPINALIS") & main!=""
replace main = "MORBUS SPINALIS" if regexm(disease,"MORBUS") & regexm(disease,"SPINALIS")  & main==""
replace disease = regexr(disease,"MORBUS","") if regexm(main,"MORBUS SPINALIS")
replace disease = regexr(disease,"SPINALIS","") if regexm(main,"MORBUS SPINALIS")

replace main = main+",MORBUS THORACIS" if regexm(disease,"MORBUS") & regexm(disease,"THORACIS") & main!=""
replace main = "MORBUS THORACIS" if regexm(disease,"MORBUS") & regexm(disease,"THORACIS")  & main==""
replace disease = regexr(disease,"MORBUS","") if regexm(main,"MORBUS THORACIS")
replace disease = regexr(disease,"THORACIS","") if regexm(main,"MORBUS THORACIS")

replace main = main+",MORBUS VESICA" if regexm(disease,"MORBUS") & regexm(disease,"VESICA") & main!=""
replace main = "MORBUS VESICA" if regexm(disease,"MORBUS") & regexm(disease,"VESICA")  & main==""
replace disease = regexr(disease,"MORBUS","") if regexm(main,"MORBUS VESICA")
replace disease = regexr(disease,"VESICA","") if regexm(main,"MORBUS VESICA")

replace main = main+",MOTOR ATAXIA" if regexm(disease,"MOTOR") & regexm(disease,"ATAXIA") & main!=""
replace main = "MOTOR ATAXIA" if regexm(disease,"MOTOR") & regexm(disease,"ATAXIA") & main==""
replace disease = regexr(disease,"MOTOR","") if regexm(main,"MOTOR ATAXIA")
replace disease = regexr(disease,"ATAXIA","") if regexm(main,"MOTOR ATAXIA")

replace main = main+",MUCOPURULENT CONJUNCTIVITIS" if regexm(disease,"MUCOPURULENT") & regexm(disease,"CONJUNCTIVITIS") & main!=""
replace main = "MUCOPURULENT CONJUNCTIVITIS" if regexm(disease,"MUCOPURULENT") & regexm(disease,"CONJUNCTIVITIS")  & main==""
replace disease = regexr(disease,"MUCOPURULENT","") if regexm(main,"MUCOPURULENT CONJUNCTIVITIS")
replace disease = regexr(disease,"CONJUNCTIVITIS","") if regexm(main,"MUCOPURULENT CONJUNCTIVITIS")

replace main = main+",MUCOPURULENT OPHTHALMIA" if regexm(disease,"MUCOPURULENT") & regexm(disease,"OPHTHALMIA") & main!=""
replace main = "MUCOPURULENT OPHTHALMIA" if regexm(disease,"MUCOPURULENT") & regexm(disease,"OPHTHALMIA")  & main==""
replace disease = regexr(disease,"MUCOPURULENT","") if regexm(main,"MUCOPURULENT OPHTHALMIA")
replace disease = regexr(disease,"OPHTHALMIA","") if regexm(main,"MUCOPURULENT OPHTHALMIA")

replace main = main+",MUSCULOSPIRAL PARALYSIS" if regexm(disease,"MUSCULOSPIRAL") & regexm(disease,"PARALYSIS") & main!=""
replace main = "MUSCULOSPIRAL PARALYSIS" if regexm(disease,"MUSCULOSPIRAL") & regexm(disease,"PARALYSIS") & main==""
replace disease = regexr(disease,"MUSCULOSPIRAL","") if regexm(main,"MUSCULOSPIRAL PARALYSIS")
replace disease = regexr(disease,"PARALYSIS","") if regexm(main,"MUSCULOSPIRAL PARALYSIS")

replace main = main+",MYOSITIS OSSIFICANS" if regexm(disease,"MYOSITIS") & regexm(disease,"OSSIFICANS") & main!=""
replace main = "MYOSITIS OSSIFICANS" if regexm(disease,"MYOSITIS") & regexm(disease,"OSSIFICANS") & main==""
replace disease = regexr(disease,"MYOSITIS","") if regexm(main,"MYOSITIS OSSIFICANS")
replace disease = regexr(disease,"OSSIFICANS","") if regexm(main,"MYOSITIS OSSIFICANS")

replace main = main+",NASAL SPUR" if regexm(disease,"NASAL") & regexm(disease,"SPUR") & main!=""
replace main = "NASAL SPUR" if regexm(disease,"NASAL") & regexm(disease,"SPUR")  & main==""
replace disease = regexr(disease,"NASAL","") if regexm(main,"NASAL SPUR")
replace disease = regexr(disease,"SPUR","") if regexm(main,"NASAL SPUR")

replace main = main+",NERVOUS DEBILITY" if regexm(disease,"NERVOUS") & regexm(disease,"DEBILITY") & main!=""
replace main = "NERVOUS DEBILITY" if regexm(disease,"NERVOUS") & regexm(disease,"DEBILITY") & main==""
replace disease = regexr(disease,"NERVOUS","") if regexm(main,"NERVOUS DEBILITY")
replace disease = regexr(disease,"DEBILITY","") if regexm(main,"NERVOUS DEBILITY")

replace main = main+",NEUROLOGICAL TUMOUR" if regexm(disease,"NEUROLOGICAL") & regexm(disease,"TUMOUR") & main!=""
replace main = "NEUROLOGICAL TUMOUR" if regexm(disease,"NEUROLOGICAL") & regexm(disease,"TUMOUR") & main==""
replace disease = regexr(disease,"NEUROLOGICAL","") if regexm(main,"NEUROLOGICAL TUMOUR")
replace disease = regexr(disease,"TUMOUR","") if regexm(main,"NEUROLOGICAL TUMOUR")

replace main = main+",NOMA PUDENDI" if regexm(disease,"PUDENDI") & main!=""
replace main = "NOMA PUDENDI" if regexm(disease,"PUDENDI") & main==""
replace disease = regexr(disease,"NOMA","") if regexm(main,"NOMA PUDENDI")
replace disease = regexr(disease,"PUDENDI","") if regexm(main,"NOMA PUDENDI")

replace main = main+",MOOD DISORDER" if regexm(disease,"MOOD") & regexm(disease,"DISORDER") & main!=""
replace main = "MOOD DISORDER" if regexm(disease,"MOOD") & regexm(disease,"DISORDER") & main==""
replace disease = regexr(disease,"MOOD","") if regexm(main,"MOOD DISORDER")
replace disease = regexr(disease,"DISORDER","") if regexm(main,"MOOD DISORDER")

replace main = main+",NUTRITION DISORDER" if regexm(disease,"NUTRITION") & regexm(disease,"DISORDER") & main!=""
replace main = "NUTRITION DISORDER" if regexm(disease,"NUTRITION") & regexm(disease,"DISORDER") & main==""
replace disease = regexr(disease,"NUTRITION","") if regexm(main,"NUTRITION DISORDER")
replace disease = regexr(disease,"DISORDER","") if regexm(main,"NUTRITION DISORDER")

replace main = main+",EATING DISORDER" if regexm(disease,"EATING") & regexm(disease,"DISORDER") & main!=""
replace main = "EATING DISORDER" if regexm(disease,"EATING") & regexm(disease,"DISORDER") & main==""
replace disease = regexr(disease,"EATING","") if regexm(main,"EATING DISORDER")
replace disease = regexr(disease,"DISORDER","") if regexm(main,"EATING DISORDER")

replace main = main+",OPTIC NEURITIS" if regexm(disease,"OPTIC") & regexm(disease,"NEURITIS") & main!=""
replace main = "OPTIC NEURITIS" if regexm(disease,"OPTIC") & regexm(disease,"NEURITIS")  & main==""
replace disease = regexr(disease,"OPTIC","") if regexm(main,"OPTIC NEURITIS")
replace disease = regexr(disease,"NEURITIS","") if regexm(main,"OPTIC NEURITIS")

replace main = main+",OPHTHALMIA NEONATORUM" if regexm(disease,"OPHTHALMIA") & regexm(disease,"NEONATORUM") & main!=""
replace main = "OPHTHALMIA NEONATORUM" if regexm(disease,"OPHTHALMIA") & regexm(disease,"NEONATORUM") & main==""
replace disease = regexr(disease,"OPHTHALMIA","") if regexm(main,"OPHTHALMIA NEONATORUM")
replace disease = regexr(disease,"NEONATORUM","") if regexm(main,"OPHTHALMIA NEONATORUM")

replace main = main+",OTITIS INTERNA" if regexm(disease,"OTITIS") & regexm(disease,"INTERNA") & main!=""
replace main = "OTITIS INTERNA" if regexm(disease,"OTITIS") & regexm(disease,"INTERNA")  & main==""
replace disease = regexr(disease,"OTITIS","") if regexm(main,"OTITIS INTERNA")
replace disease = regexr(disease,"INTERNA","") if regexm(main,"OTITIS INTERNA")

replace main = main+",OTITIS MEDIA" if regexm(disease,"OTITIS") & regexm(disease,"MEDIA") & main!=""
replace main = "OTITIS MEDIA" if regexm(disease,"OTITIS") & regexm(disease,"MEDIA")  & main==""
replace disease = regexr(disease,"OTITIS","") if regexm(main,"OTITIS MEDIA")
replace disease = regexr(disease,"MEDIA","") if regexm(main,"OTITIS MEDIA")

replace main = main+",PARALYSIS AGITANS" if regexm(disease,"PARALYSIS") & regexm(disease,"AGITANS") & main!=""
replace main = "PARALYSIS AGITANS" if regexm(disease,"PARALYSIS") & regexm(disease,"AGITANS")  & main==""
replace disease = regexr(disease,"PARALYSIS","") if regexm(main,"PARALYSIS AGITANS")
replace disease = regexr(disease,"AGITANS","") if regexm(main,"PARALYSIS AGITANS")

replace main = main+",PARASITIC INFECTION" if regexm(disease,"PARASITIC") & regexm(disease,"INFECTION") & main!=""
replace main = "PARASITIC INFECTION" if regexm(disease,"PARASITIC") & regexm(disease,"INFECTION")  & main==""
replace disease = regexr(disease,"PARASITIC","") if regexm(main,"PARASITIC INFECTION")
replace disease = regexr(disease,"INFECTION","") if regexm(main,"PARASITIC INFECTION")

replace main = main+",PARASITIC FETUS" if regexm(disease,"PARASITIC") & regexm(disease,"FETUS") & main!=""
replace main = "PARASITIC FETUS" if regexm(disease,"PARASITIC") & regexm(disease,"FETUS")  & main==""
replace disease = regexr(disease,"PARASITIC","") if regexm(main,"PARASITIC FETUS")
replace disease = regexr(disease,"FETUS","") if regexm(main,"PARASITIC FETUS")

replace main = main+",PAROXYSMAL NOCTURNAL HEMOGLOBINURIA" if regexm(disease,"PAROXYSMAL") & regexm(disease,"HEMOGLOBIN") & main!=""
replace main = "PAROXYSMAL NOCTURNAL HEMOGLOBINURIA" if regexm(disease,"PAROXYSMAL") & regexm(disease,"HEMOGLOBIN")  & main==""
replace disease = regexr(disease,"PAROXYSMAL","") if regexm(main,"PAROXYSMAL NOCTURNAL HEMOGLOBINURIA")
replace disease = regexr(disease,"HEMOGLOBIN(URIA)*","") if regexm(main,"PAROXYSMAL NOCTURNAL HEMOGLOBINURIA")

replace main = main+",PASSING BLOOD IN URINE" if regexm(disease,"PASSING") & regexm(disease,"BLEEDING") & main!=""
replace main = "PASSING BLOOD IN URINE" if regexm(disease,"PASSING") & regexm(disease,"BLEEDING")  & main==""
replace disease = regexr(disease,"PASSING","") if regexm(main,"PASSING BLOOD IN URINE")
replace disease = regexr(disease,"BLEEDING","") if regexm(main,"PASSING BLOOD IN URINE")
replace disease = regexr(disease,"URINE","") if regexm(main,"PASSING BLOOD IN URINE")

replace main = main+",PECTUS COLUMBINUM" if regexm(disease,"PECTUS") & regexm(disease,"COLUMBINUM") & main!=""
replace main = "PECTUS COLUMBINUM" if regexm(disease,"PECTUS") & regexm(disease,"COLUMBINUM") & main==""
replace disease = regexr(disease,"PECTUS","") if regexm(main,"PECTUS COLUMBINUM")
replace disease = regexr(disease,"COLUMBINUM","") if regexm(main,"PECTUS COLUMBINUM")

replace main = main+",PENDULOUS FIBROMA" if regexm(disease,"PENDULOUS") & regexm(disease,"FIBROMA") & main!=""
replace main = "PENDULOUS FIBROMA" if regexm(disease,"PENDULOUS") & regexm(disease,"FIBROMA")  & main==""
replace disease = regexr(disease,"PENDULOUS","") if regexm(main,"PENDULOUS FIBROMA")
replace disease = regexr(disease,"FIBROMA","") if regexm(main,"PENDULOUS FIBROMA")

replace main = main+",PERIPHERAL NEURITIS" if regexm(disease,"PERIPHERAL") & regexm(disease,"NEURITIS") & main!=""
replace main = "PERIPHERAL NEURITIS" if regexm(disease,"PERIPHERAL") & regexm(disease,"NEURITIS")  & main==""
replace disease = regexr(disease,"PERIPHERAL","") if regexm(main,"PERIPHERAL NEURITIS")
replace disease = regexr(disease,"NEURITIS","") if regexm(main,"PERIPHERAL NEURITIS")

replace main = main+",PNEUMOCOCCAL PERITONITIS" if regexm(disease,"PNEUMOCOCCAL") & regexm(disease,"PERITONITIS") & main!=""
replace main = "PNEUMOCOCCAL PERITONITIS" if regexm(disease,"PNEUMOCOCCAL") & regexm(disease,"PERITONITIS") & main==""
replace disease = regexr(disease,"PNEUMOCOCCAL","") if regexm(main,"PNEUMOCOCCAL PERITONITIS")
replace disease = regexr(disease,"PERITONITIS","") if regexm(main,"PNEUMOCOCCAL PERITONITIS")

replace main = main+",POOR NUTRITION" if regexm(disease,"POOR") & regexm(disease,"NUTRITION") & main!=""
replace main = "POOR NUTRITION" if regexm(disease,"POOR") & regexm(disease,"NUTRITION") & main==""
replace disease = regexr(disease,"POOR","") if regexm(main,"POOR NUTRITION")
replace disease = regexr(disease,"NUTRITION","") if regexm(main,"POOR NUTRITION")

replace main = main+",PORRIGO CAPITIS" if regexm(disease,"PORRIGO") & regexm(disease,"CAPITIS") & main!=""
replace main = "PORRIGO CAPITIS" if regexm(disease,"PORRIGO") & regexm(disease,"CAPITIS") & main==""
replace disease = regexr(disease,"PORRIGO","") if regexm(main,"PORRIGO CAPITIS")
replace disease = regexr(disease,"CAPITIS","") if regexm(main,"PORRIGO CAPITIS")

replace main = main+",POSTAURICULAR ABSCESS" if regexm(disease,"POSTAURICULAR") & regexm(disease,"ABSCESS") & main!=""
replace main = "POSTAURICULAR ABSCESS" if regexm(disease,"POSTAURICULAR") & regexm(disease,"ABSCESS") & main==""
replace disease = regexr(disease,"POSTAURICULAR","") if regexm(main,"POSTAURICULAR ABSCESS")
replace disease = regexr(disease,"ABSCESS","") if regexm(main,"POSTAURICULAR ABSCESS")

replace main = main+",POST BASILAR MENINGITIS" if regexm(disease,"POST") & regexm(disease,"BASILAR") & regexm(disease,"MENINGITIS") & main!=""
replace main = "POST BASILAR MENINGITIS" if regexm(disease,"POST") & regexm(disease,"BASILAR") & regexm(disease,"MENINGITIS") & main==""
replace disease = regexr(disease,"POST","") if regexm(main,"POST BASILAR MENINGITIS")
replace disease = regexr(disease,"BASILAR","") if regexm(main,"POST BASILAR MENINGITIS")
replace disease = regexr(disease,"MENINGITIS","") if regexm(main,"POST BASILAR MENINGITIS")

replace main = main+",PSEUDOLEUKEMIA INFANTUM" if regexm(disease,"PSEUDOLEUKEMIA") & regexm(disease,"INFANTUM") & main!=""
replace main = "PSEUDOLEUKEMIA INFANTUM" if regexm(disease,"PSEUDOLEUKEMIA") & regexm(disease,"INFANTUM") & main==""
replace disease = regexr(disease,"PSEUDOLEUKEMIA","") if regexm(main,"PSEUDOLEUKEMIA INFANTUM")
replace disease = regexr(disease,"INFANTUM","") if regexm(main,"PSEUDOLEUKEMIA INFANTUM")

replace main = main+",SCLERMA NEONATORUM" if regexm(disease,"SCLERMA") & regexm(disease,"NEONATORUM") & main!=""
replace main = "SCLERMA NEONATORUM" if regexm(disease,"SCLERMA") & regexm(disease,"NEONATORUM") & main==""
replace disease = regexr(disease,"SCLERMA","") if regexm(main,"SCLERMA NEONATORUM")
replace disease = regexr(disease,"NEONATORUM","") if regexm(main,"SCLERMA NEONATORUM")

replace main = main+",SPLENOMEGALIA INFANTUM" if regexm(disease,"SPLENOMEGALIA") & regexm(disease,"INFANTUM") & main!=""
replace main = "SPLENOMEGALIA INFANTUM" if regexm(disease,"SPLENOMEGALIA") & regexm(disease,"INFANTUM") & main==""
replace disease = regexr(disease,"SPLENOMEGALIA","") if regexm(main,"SPLENOMEGALIA INFANTUM")
replace disease = regexr(disease,"INFANTUM","") if regexm(main,"SPLENOMEGALIA INFANTUM")

replace main = main+",STRUMOUS DACTYLITIS" if regexm(disease,"STRUMA") & regexm(disease,"DACTYLITIS") & main!=""
replace main = "STRUMOUS DACTYLITIS" if regexm(disease,"STRUMA") & regexm(disease,"DACTYLITIS") & main==""
replace disease = regexr(disease,"STRUMA","") if regexm(main,"STRUMOUS DACTYLITIS")
replace disease = regexr(disease,"DACTYLITIS","") if regexm(main,"STRUMOUS DACTYLITIS")

replace main = main+",TALIPES ACQUIRED" if regexm(disease,"TALIPES") & regexm(disease,"ACQUIRED") & main!=""
replace main = "TALIPES ACQUIRED" if regexm(disease,"TALIPES") & regexm(disease,"ACQUIRED")  & main==""
replace disease = regexr(disease,"TALIPES","") if regexm(main,"TALIPES ACQUIRED")
replace disease = regexr(disease,"ACQUIRED","") if regexm(main,"TALIPES ACQUIRED")

replace main = main+",TALIPES CARIES" if regexm(disease,"TALIPES") & regexm(disease,"CARIES") & main!=""
replace main = "TALIPES CARIES" if regexm(disease,"TALIPES") & regexm(disease,"CARIES")  & main==""
replace disease = regexr(disease,"TALIPES","") if regexm(main,"TALIPES CARIES")
replace disease = regexr(disease,"CARIES","") if regexm(main,"TALIPES CARIES")

replace main = main+",TALIPES CAVUS" if regexm(disease,"TALIPES") & regexm(disease,"CAVUS") & main!=""
replace main = "TALIPES CAVUS" if regexm(disease,"TALIPES") & regexm(disease,"CAVUS")  & main==""
replace disease = regexr(disease,"TALIPES","") if regexm(main,"TALIPES CAVUS")
replace disease = regexr(disease,"CAVUS","") if regexm(main,"TALIPES CAVUS")

replace main = main+",TALIPES EQUINUS" if regexm(disease,"TALIPES") & regexm(disease,"EQUINUS") & main!=""
replace main = "TALIPES EQUINUS" if regexm(disease,"TALIPES") & regexm(disease,"EQUINUS")  & main==""
replace disease = regexr(disease,"TALIPES","") if regexm(main,"TALIPES EQUINUS")
replace disease = regexr(disease,"EQUINUS","") if regexm(main,"TALIPES EQUINUS")

replace main = main+",TALIPES PARALYTIC" if regexm(disease,"TALIPES") & regexm(disease,"PARALYTIC") & main!=""
replace main = "TALIPES PARALYTIC" if regexm(disease,"TALIPES") & regexm(disease,"PARALYTIC")  & main==""
replace disease = regexr(disease,"TALIPES","") if regexm(main,"TALIPES PARALYTIC")
replace disease = regexr(disease,"PARALYTIC","") if regexm(main,"TALIPES PARALYTIC")

replace main = main+",TALIPES PLANUS" if regexm(disease,"TALIPES") & regexm(disease,"PLANUS") & main!=""
replace main = "TALIPES PLANUS" if regexm(disease,"TALIPES") & regexm(disease,"PLANUS")  & main==""
replace disease = regexr(disease,"TALIPES","") if regexm(main,"TALIPES PLANUS")
replace disease = regexr(disease,"PLANUS","") if regexm(main,"TALIPES PLANUS")

replace main = main+",TALIPES VALGUS" if regexm(disease,"TALIPES") & regexm(disease,"VALGUS") & main!=""
replace main = "TALIPES VALGUS" if regexm(disease,"TALIPES") & regexm(disease,"VALGUS")  & main==""
replace disease = regexr(disease,"TALIPES","") if regexm(main,"TALIPES VALGUS")
replace disease = regexr(disease,"VALGUS","") if regexm(main,"TALIPES VALGUS")

replace main = main+",TALIPES VARUS" if regexm(disease,"TALIPES") & regexm(disease,"VARUS") & main!=""
replace main = "TALIPES VARUS" if regexm(disease,"TALIPES") & regexm(disease,"VARUS")  & main==""
replace disease = regexr(disease,"TALIPES","") if regexm(main,"TALIPES VARUS")
replace disease = regexr(disease,"VARUS","") if regexm(main,"TALIPES VARUS")

replace main = main+",TALIPES CARIES" if regexm(disease,"PES") & regexm(disease,"CARIES") & main!=""
replace main = "TALIPES CARIES" if regexm(disease,"PES") & regexm(disease,"CARIES")  & main==""
replace disease = regexr(disease,"PES","") if regexm(main,"TALIPES CARIES")
replace disease = regexr(disease,"CARIES","") if regexm(main,"TALIPES CARIES")

replace main = main+",TALIPES CAVUS" if regexm(disease,"PES") & regexm(disease,"CAVUS") & main!=""
replace main = "TALIPES CAVUS" if regexm(disease,"PES") & regexm(disease,"CAVUS")  & main==""
replace disease = regexr(disease,"PES","") if regexm(main,"TALIPES CAVUS")
replace disease = regexr(disease,"CAVUS","") if regexm(main,"TALIPES CAVUS")

replace main = main+",TALIPES PLANUS" if regexm(disease,"PES") & regexm(disease,"PLANUS") & main!=""
replace main = "TALIPES PLANUS" if regexm(disease,"PES") & regexm(disease,"PLANUS")  & main==""
replace disease = regexr(disease,"PES","") if regexm(main,"TALIPES PLANUS")
replace disease = regexr(disease,"PLANUS","") if regexm(main,"TALIPES PLANUS")

replace main = main+",TALIPES VALGUS" if regexm(disease,"PES") & regexm(disease,"VALGUS") & main!=""
replace main = "TALIPES VALGUS" if regexm(disease,"PES") & regexm(disease,"VALGUS")  & main==""
replace disease = regexr(disease,"PES","") if regexm(main,"TALIPES VALGUS")
replace disease = regexr(disease,"VALGUS","") if regexm(main,"TALIPES VALGUS")

replace main = main+",TALIPES VARUS" if regexm(disease,"PES") & regexm(disease,"VARUS") & main!=""
replace main = "TALIPES VARUS" if regexm(disease,"PES") & regexm(disease,"VARUS")  & main==""
replace disease = regexr(disease,"PES","") if regexm(main,"TALIPES VARUS")
replace disease = regexr(disease,"VARUS","") if regexm(main,"TALIPES VARUS")

replace main = main+",PETIT MAL SEIZURE" if regexm(disease,"PETIT") & regexm(disease,"MAL") & main!=""
replace main = "PETIT MAL SEIZURE" if regexm(disease,"PETIT") & regexm(disease,"MAL")  & main==""
replace disease = regexr(disease,"PETIT","") if regexm(main,"PETIT MAL SEIZURE")
replace disease = regexr(disease,"MAL","") if regexm(main,"PETIT MAL SEIZURE")

replace main = main+",PHLYCTENULAR KERATOCONJUNCTIVITIS" if regexm(disease,"PHLYCTENULAR") & (regexm(disease,"KERATITIS") | regexm(disease,"CONJUNCTIVITIS")) & main!=""
replace main = "PHLYCTENULAR KERATOCONJUNCTIVITIS" if regexm(disease,"PHLYCTENULAR") & (regexm(disease,"KERATITIS") | regexm(disease,"CONJUNCTIVITIS")) & main==""
replace disease = regexr(disease,"PHLYCTENULAR","") if regexm(main,"PHLYCTENULAR KERATOCONJUNCTIVITIS")
replace disease = regexr(disease,"CONJUNCTIVITIS","") if regexm(main,"PHLYCTENULAR KERATOCONJUNCTIVITIS")
replace disease = regexr(disease,"KERATITIS","") if regexm(main,"PHLYCTENULAR KERATOCONJUNCTIVITIS")

replace main = main+",PLANTAR FASCIITIS" if regexm(disease,"PLANTAR") & regexm(disease,"FASCIITIS") & main!=""
replace main = "PLANTAR FASCIITIS" if regexm(disease,"PLANTAR") & regexm(disease,"FASCIITIS")  & main==""
replace disease = regexr(disease,"PLANTAR","") if regexm(main,"PLANTAR FASCIITIS")
replace disease = regexr(disease,"FASCIITIS","") if regexm(main,"PLANTAR FASCIITIS")

replace main = main+",PLASTIC MENINGITIS" if regexm(disease,"PLASTIC") & regexm(disease,"MENINGITIS") & main!=""
replace main = "PLASTIC MENINGITIS" if regexm(disease,"PLASTIC") & regexm(disease,"MENINGITIS") & main==""
replace disease = regexr(disease,"PLASTIC","") if regexm(main,"PLASTIC MENINGITIS")
replace disease = regexr(disease,"MENINGITIS","") if regexm(main,"PLASTIC MENINGITIS")

replace main = main+",POSTERIOR SYNECHIA" if regexm(disease,"POSTERIOR") & regexm(disease,"SYNECHIA") & main!=""
replace main = "POSTERIOR SYNECHIA" if regexm(disease,"POSTERIOR") & regexm(disease,"SYNECHIA")  & main==""
replace disease = regexr(disease,"POSTERIOR","") if regexm(main,"POSTERIOR SYNECHIA")
replace disease = regexr(disease,"SYNECHIA","") if regexm(main,"POSTERIOR SYNECHIA")

replace main = main+",POTTS DISEASE" if regexm(disease,"POTTS") & regexm(disease,"DISEASE") & main!=""
replace main = "POTTS DISEASE" if regexm(disease,"POTTS") & regexm(disease,"DISEASE") & main==""
replace disease = regexr(disease,"POTTS","") if regexm(main,"POTTS DISEASE")
replace disease = regexr(disease,"DISEASE","") if regexm(main,"POTTS DISEASE")

replace main = main+",PREPATELLAR BURSITIS" if regexm(disease,"PREPATELLAR") & regexm(disease,"BURSITIS") & main!=""
replace main = "PREPATELLAR BURSITIS" if regexm(disease,"PREPATELLAR") & regexm(disease,"BURSITIS")  & main==""
replace disease = regexr(disease,"PREPATELLAR","") if regexm(main,"PREPATELLAR BURSITIS")
replace disease = regexr(disease,"BURSITIS","") if regexm(main,"PREPATELLAR BURSITIS")

replace main = main+",PULMONARY CATARRH" if regexm(disease,"PULMONARY") & regexm(disease,"CATARRH") & main!=""
replace main = "PULMONARY CATARRH" if regexm(disease,"PULMONARY") & regexm(disease,"CATARRH")  & main==""
replace disease = regexr(disease,"PULMONARY","") if regexm(main,"PULMONARY CATARRH")
replace disease = regexr(disease,"CATARRH","") if regexm(main,"PULMONARY CATARRH")

replace main = main+",PULMONARY CONSOLIDATION" if regexm(disease,"PULMONARY") & regexm(disease,"CONSOLIDATION") & main!=""
replace main = "PULMONARY CONSOLIDATION" if regexm(disease,"PULMONARY") & regexm(disease,"CONSOLIDATION")  & main==""
replace disease = regexr(disease,"PULMONARY","") if regexm(main,"PULMONARY CONSOLIDATION")
replace disease = regexr(disease,"CONSOLIDATION","") if regexm(main,"PULMONARY CONSOLIDATION")

replace main = main+",PULMONARY TUBERCULOSIS" if regexm(disease,"PULMONARY") & regexm(disease,"TUBERCULOSIS") & main!=""
replace main = "PULMONARY TUBERCULOSIS" if regexm(disease,"PULMONARY") & regexm(disease,"TUBERCULOSIS")  & main==""
replace disease = regexr(disease,"PULMONARY","") if regexm(main,"PULMONARY TUBERCULOSIS")
replace disease = regexr(disease,"TUBERCULOSIS","") if regexm(main,"PULMONARY TUBERCULOSIS")

replace main = main+",PURPURA SIMPLEX" if regexm(disease,"PURPURA") & regexm(disease,"SIMPLEX") & main!=""
replace main = "PURPURA SIMPLEX" if regexm(disease,"PURPURA") & regexm(disease,"SIMPLEX")  & main==""
replace disease = regexr(disease,"PURPURA","") if regexm(main,"PURPURA SIMPLEX")
replace disease = regexr(disease,"SIMPLEX","") if regexm(main,"PURPURA SIMPLEX")

replace main = main+",PYRAMIDAL CATARACT" if regexm(disease,"PYRAMIDAL") & regexm(disease,"CATARACT") & main!=""
replace main = "PYRAMIDAL CATARACT" if regexm(disease,"PYRAMIDAL") & regexm(disease,"CATARACT")  & main==""
replace disease = regexr(disease,"PYRAMIDAL","") if regexm(main,"PYRAMIDAL CATARACT")
replace disease = regexr(disease,"CATARACT","") if regexm(main,"PYRAMIDAL CATARACT")

replace main = main+",RAYNAUDS DISEASE" if regexm(disease,"RAYNAUD(S)*") & regexm(disease,"DISEASE") & main!=""
replace main = "RAYNAUDS DISEASE" if regexm(disease,"RAYNAUD(S)*") & regexm(disease,"DISEASE")  & main==""
replace disease = regexr(disease,"RAYNAUD(S)*","") if regexm(main,"RAYNAUDS DISEASE")
replace disease = regexr(disease,"DISEASE","") if regexm(main,"RAYNAUDS DISEASE")

replace main = main+",IRREDUCIBLE HERNIA" if regexm(disease,"IRREDUCIBLE") & regexm(disease,"HERNIA") & main!=""
replace main = "IRREDUCIBLE HERNIA" if regexm(disease,"IRREDUCIBLE") & regexm(disease,"HERNIA") & main==""
replace disease = regexr(disease,"IRREDUCIBLE","") if regexm(main,"IRREDUCIBLE HERNIA")
replace disease = regexr(disease,"HERNIA","") if regexm(main,"IRREDUCIBLE HERNIA")

replace main = main+",UNREDUCIBLE HERNIA" if regexm(disease,"UNREDUCIBLE") & regexm(disease,"HERNIA") & main!=""
replace main = "UNREDUCIBLE HERNIA" if regexm(disease,"UNREDUCIBLE") & regexm(disease,"HERNIA") & main==""
replace disease = regexr(disease,"UNREDUCIBLE","") if regexm(main,"UNREDUCIBLE HERNIA")
replace disease = regexr(disease,"HERNIA","") if regexm(main,"UNREDUCIBLE HERNIA")

replace main = main+",REDUCIBLE HERNIA" if regexm(disease,"REDUCIBLE") & regexm(disease,"HERNIA") & main!=""
replace main = "REDUCIBLE HERNIA" if regexm(disease,"REDUCIBLE") & regexm(disease,"HERNIA") & main==""
replace disease = regexr(disease,"REDUCIBLE","") if regexm(main,"REDUCIBLE HERNIA")
replace disease = regexr(disease,"HERNIA","") if regexm(main,"REDUCIBLE HERNIA")

replace main = main+",RECTANGULAR TALIPES" if regexm(disease,"RECTANGULAR") & regexm(disease,"TALIPES") & main!=""
replace main = "RECTANGULAR TALIPES" if regexm(disease,"RECTANGULAR") & regexm(disease,"TALIPES") & main==""
replace disease = regexr(disease,"RECTANGULAR","") if regexm(main,"RECTANGULAR TALIPES")
replace disease = regexr(disease,"TALIPES","") if regexm(main,"RECTANGULAR TALIPES")

replace main = main+",RECTOVAGINAL FISTULA" if regexm(disease,"RECTOVAGINA") & regexm(disease,"FISTULA") & main!=""
replace main = "RECTOVAGINAL FISTULA" if regexm(disease,"RECTOVAGINA") & regexm(disease,"FISTULA") & main==""
replace disease = regexr(disease,"RECTOVAGINA","") if regexm(main,"RECTOVAGINAL FISTULA")
replace disease = regexr(disease,"FISTULA","") if regexm(main,"RECTOVAGINAL FISTULA")

replace main = main+",REFRACTION ERROR" if regexm(disease,"REFRACTION") & regexm(disease,"ERROR") & main!=""
replace main = "REFRACTION ERROR" if regexm(disease,"REFRACTION") & regexm(disease,"ERROR")  & main==""
replace disease = regexr(disease,"REFRACTION","") if regexm(main,"REFRACTION ERROR")
replace disease = regexr(disease,"ERROR","") if regexm(main,"REFRACTION ERROR")

replace main = main+",RETINITIS PIGMENTOSA" if regexm(disease,"RETINITIS") & regexm(disease,"PIGMENTOSA") & main!=""
replace main = "RETINITIS PIGMENTOSA" if regexm(disease,"RETINITIS") & regexm(disease,"PIGMENTOSA")  & main==""
replace disease = regexr(disease,"RETINITIS","") if regexm(main,"RETINITIS PIGMENTOSA")
replace disease = regexr(disease,"PIGMENTOSA","") if regexm(main,"RETINITIS PIGMENTOSA")

replace main = main+",RETROPHARYNGEAL ABSCESS" if regexm(disease,"RETRO") & regexm(disease,"PHARYNX") & regexm(disease,"ABSCESS") & main!=""
replace main = "" if regexm(disease,"RETROPHARYNGEAL ABSCESS") & regexm(disease,"RETRO") & regexm(disease,"PHARYNX") & regexm(disease,"ABSCESS") & main==""
replace disease = regexr(disease,"RETRO","") if regexm(main,"RETROPHARYNGEAL ABSCESS")
replace disease = regexr(disease,"PHARYNX","") if regexm(main,"RETROPHARYNGEAL ABSCESS")
replace disease = regexr(disease,"ABSCESS","") if regexm(main,"RETROPHARYNGEAL ABSCESS")

replace main = main+",RHEUMATIC FEVER" if regexm(disease,"RHEUMATISM") & regexm(disease,"FEVER") & main!=""
replace main = "RHEUMATIC FEVER" if regexm(disease,"RHEUMATISM") & regexm(disease,"FEVER")  & main==""
replace disease = regexr(disease,"RHEUMATISM","") if regexm(main,"RHEUMATIC FEVER")
replace disease = regexr(disease,"FEVER","") if regexm(main,"RHEUMATIC FEVER")

replace main = main+",RHEUMATOID ARTHRITIS" if regexm(disease,"RHEUMATOID") & regexm(disease,"ARTHRITIS") & main!=""
replace main = "RHEUMATOID ARTHRITIS" if regexm(disease,"RHEUMATOID") & regexm(disease,"ARTHRITIS") & main==""
replace disease = regexr(disease,"RHEUMATOID","") if regexm(main,"RHEUMATOID ARTHRITIS")
replace disease = regexr(disease,"ARTHRITIS","") if regexm(main,"RHEUMATOID ARTHRITIS")

replace main = main+",SCARLET FEVER" if regexm(disease,"SCARLET") & regexm(disease,"FEVER") & main!=""
replace main = "SCARLET FEVER" if regexm(disease,"SCARLET") & regexm(disease,"FEVER")  & main==""
replace disease = regexr(disease,"SCARLET","") if regexm(main,"SCARLET FEVER")
replace disease = regexr(disease,"FEVER","") if regexm(main,"SCARLET FEVER")

replace main = main+",SCLEREMA NEONATORUM" if regexm(disease,"SCLEREMA") & main!=""
replace main = "SCLEREMA NEONATORUM" if regexm(disease,"SCLEREMA") & main==""
replace disease = regexr(disease,"SCLEREMA","") if regexm(main,"SCLEREMA NEONATORUM")
replace disease = regexr(disease,"NEONATORUM","") if regexm(main,"SCLEREMA NEONATORUM")

replace main = main+",SEBACEOUS CYST" if regexm(disease,"SEBACEOUS") & regexm(disease,"CYST") & main!=""
replace main = "SEBACEOUS CYST" if regexm(disease,"SEBACEOUS") & regexm(disease,"CYST")  & main==""
replace disease = regexr(disease,"SEBACEOUS","") if regexm(main,"SEBACEOUS CYST")
replace disease = regexr(disease,"CYST","") if regexm(main,"SEBACEOUS CYST")

replace main = main+",SEPTAL SPUR" if regexm(disease,"SEPTAL") & regexm(disease,"SPUR") & main!=""
replace main = "SEPTAL SPUR" if regexm(disease,"SEPTAL") & regexm(disease,"SPUR")  & main==""
replace disease = regexr(disease,"SEPTAL","") if regexm(main,"SEPTAL SPUR")
replace disease = regexr(disease,"SPUR","") if regexm(main,"SEPTAL SPUR")

replace main = main+",SHORT SIGHT" if regexm(disease,"SHORT") & regexm(disease,"SIGHT") & main!=""
replace main = "SHORT SIGHT" if regexm(disease,"SHORT") & regexm(disease,"SIGHT")  & main==""
replace disease = regexr(disease,"SHORT","") if regexm(main,"SHORT SIGHT")
replace disease = regexr(disease,"SIGHT","") if regexm(main,"SHORT SIGHT")

replace main = main+",SPASMODIC TORTICOLLIS" if regexm(disease,"SPASMODIC") & regexm(disease,"TORTICOLLIS") & main!=""
replace main = "SPASMODIC TORTICOLLIS" if regexm(disease,"SPASMODIC") & regexm(disease,"TORTICOLLIS")  & main==""
replace disease = regexr(disease,"SPASMODIC","") if regexm(main,"SPASMODIC TORTICOLLIS")
replace disease = regexr(disease,"TORTICOLLIS","") if regexm(main,"SPASMODIC TORTICOLLIS")

replace main = main+",SPEECH LOSS" if regexm(disease,"SPEECH") & regexm(disease,"LOSS") & main!=""
replace main = "SPEECH LOSS" if regexm(disease,"SPEECH") & regexm(disease,"LOSS")  & main==""
replace disease = regexr(disease,"SPEECH","") if regexm(main,"SPEECH LOSS")
replace disease = regexr(disease,"LOSS","") if regexm(main,"SPEECH LOSS")

replace main = main+",SPINA BIFIDA" if regexm(disease,"SPINA") & regexm(disease,"BIFIDA") & main!=""
replace main = "SPINA BIFIDA" if regexm(disease,"SPINA") & regexm(disease,"BIFIDA")  & main==""
replace disease = regexr(disease,"SPINA","") if regexm(main,"SPINA BIFIDA")
replace disease = regexr(disease,"BIFIDA","") if regexm(main,"SPINA BIFIDA")

replace main = main+",SPRENGEL'S DEFORMITY" if regexm(disease,"SPRENGELS") & regexm(disease,"DEFORMITY") & main!=""
replace main = "SPRENGEL'S DEFORMITY" if regexm(disease,"SPRENGELS") & regexm(disease,"DEFORMITY") & main==""
replace disease = regexr(disease,"SPRENGELS","") if regexm(main,"SPRENGEL'S DEFORMITY")
replace disease = regexr(disease,"DEFORMITY","") if regexm(main,"SPRENGEL'S DEFORMITY")

replace main = main+",SPURIOUS VALGUS" if regexm(disease,"SPURIOUS") & regexm(disease,"VALGUS") & main!=""
replace main = "SPURIOUS VALGUS" if regexm(disease,"SPURIOUS") & regexm(disease,"VALGUS")  & main==""
replace disease = regexr(disease,"SPURIOUS","") if regexm(main,"SPURIOUS VALGUS")
replace disease = regexr(disease,"VALGUS","") if regexm(main,"SPURIOUS VALGUS")

replace main = main+",STATUS EPILEPTICUS" if regexm(disease,"STATUS") & regexm(disease,"EPILEPTICUS") & main!=""
replace main = "STATUS EPILEPTICUS" if regexm(disease,"STATUS") & regexm(disease,"EPILEPTICUS")  & main==""
replace disease = regexr(disease,"STATUS","") if regexm(main,"STATUS EPILEPTICUS")
replace disease = regexr(disease,"EPILEPTICUS","") if regexm(main,"STATUS EPILEPTICUS")

replace main = main+",STRUMPELLS PARALYSIS" if regexm(disease,"STRUMPELLS") & regexm(disease,"PARALYSIS") & main!=""
replace main = "STRUMPELLS PARALYSIS" if regexm(disease,"STRUMPELLS") & regexm(disease,"PARALYSIS") & main==""
replace disease = regexr(disease,"STRUMPELLS","") if regexm(main,"STRUMPELLS PARALYSIS")
replace disease = regexr(disease,"PARALYSIS","") if regexm(main,"STRUMPELLS PARALYSIS")

replace main = main+",STRANGULATED HERNIA" if regexm(disease,"STRANGULATED") & regexm(disease,"HERNIA") & main!=""
replace main = "STRANGULATED HERNIA" if regexm(disease,"STRANGULATED") & regexm(disease,"HERNIA")  & main==""
replace disease = regexr(disease,"STRANGULATED","") if regexm(main,"STRANGULATED HERNIA")
replace disease = regexr(disease,"HERNIA","") if regexm(main,"STRANGULATED HERNIA")

replace main = main+",SYMPATHETIC IRITIS" if regexm(disease,"SYMPATHETIC") & regexm(disease,"IRITIS") & main!=""
replace main = "SYMPATHETIC IRITIS" if regexm(disease,"SYMPATHETIC") & regexm(disease,"IRITIS")  & main==""
replace disease = regexr(disease,"SYMPATHETIC","") if regexm(main,"SYMPATHETIC IRITIS")
replace disease = regexr(disease,"IRITIS","") if regexm(main,"SYMPATHETIC IRITIS")

replace main = main+",SYMPATHETIC IRRITATION" if regexm(disease,"SYMPATHETIC") & regexm(disease,"IRRITATION") & main!=""
replace main = "SYMPATHETIC IRRITATION" if regexm(disease,"SYMPATHETIC") & regexm(disease,"IRRITATION")  & main==""
replace disease = regexr(disease,"SYMPATHETIC","") if regexm(main,"SYMPATHETIC IRRITATION")
replace disease = regexr(disease,"IRRITATION","") if regexm(main,"SYMPATHETIC IRRITATION")

replace main = main+",SYMPATHETIC OPHTHALMIA" if regexm(disease,"SYMPATHETIC") & regexm(disease,"OPHTHALMIA") & main!=""
replace main = "SYMPATHETIC OPHTHALMIA" if regexm(disease,"SYMPATHETIC") & regexm(disease,"OPHTHALMIA")  & main==""
replace disease = regexr(disease,"SYMPATHETIC","") if regexm(main,"SYMPATHETIC OPHTHALMIA")
replace disease = regexr(disease,"OPHTHALMIA","") if regexm(main,"SYMPATHETIC OPHTHALMIA")

replace main = main+",SYME'S" if regexm(disease,"SYMES") & main != ""
replace main = "SYME'S" if regexm(disease,"SYMES") & main == ""
replace disease = regexr(disease,"SYMES","") if regexm(main,"SYME'S")

replace main = main+",TABES MESENTERICA" if regexm(disease,"TABES") & regexm(disease,"MESENTERICA") & main!=""
replace main = "TABES MESENTERICA" if regexm(disease,"TABES") & regexm(disease,"MESENTERICA")  & main==""
replace disease = regexr(disease,"TABES","") if regexm(main,"TABES MESENTERICA")
replace disease = regexr(disease,"MESENTERICA","") if regexm(main,"TABES MESENTERICA")

replace main = main+",TARSAL CYST" if regexm(disease,"TARSAL") & regexm(disease,"CYST") & main!=""
replace main = "TARSAL CYST" if regexm(disease,"TARSAL") & regexm(disease,"CYST")  & main==""
replace disease = regexr(disease,"TARSAL","") if regexm(main,"TARSAL CYST")
replace disease = regexr(disease,"CYST","") if regexm(main,"TARSAL CYST")

replace main = main+",THYROGLOSSAL CYST" if regexm(disease,"THYROGLOSSAL") & regexm(disease,"CYST") & main!=""
replace main = "THYROGLOSSAL CYST" if regexm(disease,"THYROGLOSSAL") & regexm(disease,"CYST")  & main==""
replace disease = regexr(disease,"THYROGLOSSAL","") if regexm(main,"THYROGLOSSAL CYST")
replace disease = regexr(disease,"CYST","") if regexm(main,"THYROGLOSSAL CYST")

replace main = main+",TINEA TONSURANS" if regexm(disease,"TINEA") & regexm(disease,"TONSURANS") & main!=""
replace main = "TINEA TONSURANS" if regexm(disease,"TINEA") & regexm(disease,"TONSURANS")  & main==""
replace disease = regexr(disease,"TINEA","") if regexm(main,"TINEA TONSURANS")
replace disease = regexr(disease,"TONSURANS","") if regexm(main,"TINEA TONSURANS")

replace main = main+",TUBERCULAR DISEASE" if regexm(disease,"TUBERCULAR") & regexm(disease,"DISEASE") & main!=""
replace main = "TUBERCULAR DISEASE" if regexm(disease,"TUBERCULAR") & regexm(disease,"DISEASE") & main==""
replace disease = regexr(disease,"TUBERCULAR","") if regexm(main,"TUBERCULAR DISEASE")
replace disease = regexr(disease,"DISEASE","") if regexm(main,"TUBERCULAR DISEASE")

replace main = main+",TUMOUR ALBUS" if regexm(disease,"TUMOUR") & regexm(disease,"ALBUS") & main!=""
replace main = "TUMOUR ALBUS" if regexm(disease,"TUMOUR") & regexm(disease,"ALBUS")  & main==""
replace disease = regexr(disease,"TUMOUR","") if regexm(main,"TUMOUR ALBUS")
replace disease = regexr(disease,"ALBUS","") if regexm(main,"TUMOUR ALBUS")

replace main = main+",TURBINATE HYPERTROPHY" if regexm(disease,"TURBINATE") & regexm(disease,"HYPERTROPHY") & main!=""
replace main = "TURBINATE HYPERTROPHY" if regexm(disease,"TURBINATE") & regexm(disease,"HYPERTROPHY") & main==""
replace disease = regexr(disease,"TURBINATE","") if regexm(main,"TURBINATE HYPERTROPHY")
replace disease = regexr(disease,"HYPERTROPHY","") if regexm(main,"TURBINATE HYPERTROPHY")

replace main = main+",TYPHOID FEVER" if regexm(disease,"TYPHOID") & regexm(disease,"FEVER") & main!=""
replace main = "TYPHOID FEVER" if regexm(disease,"TYPHOID") & regexm(disease,"FEVER")  & main==""
replace disease = regexr(disease,"TYPHOID","") if regexm(main,"TYPHOID FEVER")
replace disease = regexr(disease,"FEVER","") if regexm(main,"TYPHOID FEVER")

replace main = main+",UMBILICAL HERNIA" if regexm(disease,"UMBILICAL") & regexm(disease,"HERNIA") & main!=""
replace main = "UMBILICAL HERNIA" if regexm(disease,"UMBILICAL") & regexm(disease,"HERNIA")  & main==""
replace disease = regexr(disease,"UMBILICAL","") if regexm(main,"UMBILICAL HERNIA")
replace disease = regexr(disease,"HERNIA","") if regexm(main,"UMBILICAL HERNIA")

replace main = main+",UNDESCENDED TESTICLE" if regexm(disease,"UNDESCENDED") & regexm(disease,"TESTICLE") & main!=""
replace main = "UNDESCENDED TESTICLE" if regexm(disease,"UNDESCENDED") & regexm(disease,"TESTICLE")  & main==""
replace disease = regexr(disease,"UNDESCENDED","") if regexm(main,"UNDESCENDED TESTICLE")
replace disease = regexr(disease,"TESTICLE","") if regexm(main,"UNDESCENDED TESTICLE")

replace main = main+",UNILATERAL CONVULSION" if regexm(disease,"UNILATERAL") & regexm(disease,"CONVULSION") & main!=""
replace main = "UNILATERAL CONVULSION" if regexm(disease,"UNILATERAL") & regexm(disease,"CONVULSION") & main==""
replace disease = regexr(disease,"UNILATERAL","") if regexm(main,"UNILATERAL CONVULSION")
replace disease = regexr(disease,"CONVULSION","") if regexm(main,"UNILATERAL CONVULSION")

replace main = main+",URINARY INCONTINENCE" if regexm(disease,"INCONTINENCE") & regexm(disease,"URINE") & main!=""
replace main = "URINARY INCONTINENCE" if regexm(disease,"INCONTINENCE") & regexm(disease,"URINE")  & main==""
replace disease = regexr(disease,"INCONTINENCE","") if regexm(main,"URINARY INCONTINENCE")
replace disease = regexr(disease,"URINE","") if regexm(main,"URINARY INCONTINENCE")

replace main = main+",VARICELLA GANGRENOSA" if regexm(disease,"VARICELLA") & regexm(disease,"GANGRENOSA") & main!=""
replace main = "VARICELLA GANGRENOSA" if regexm(disease,"VARICELLA") & regexm(disease,"GANGRENOSA")  & main==""
replace disease = regexr(disease,"VARICELLA","") if regexm(main,"VARICELLA GANGRENOSA")
replace disease = regexr(disease,"GANGRENOSA","") if regexm(main,"VARICELLA GANGRENOSA")

replace main = main+",VARICOSE VEINS" if regexm(disease,"VARICOSE") & regexm(disease,"VEIN") & main!=""
replace main = "VARICOSE VEINS" if regexm(disease,"VARICOSE") & regexm(disease,"VEIN")  & main==""
replace disease = regexr(disease,"VARICOSE","") if regexm(main,"VARICOSE VEINS")
replace disease = regexr(disease,"VEIN","") if regexm(main,"VARICOSE VEINS")

replace main = main+",VENEREAL DISEASE" if regexm(disease,"VENEREAL") & regexm(disease,"DISEASE") & main!=""
replace main = "VENEREAL DISEASE" if regexm(disease,"VENEREAL") & regexm(disease,"DISEASE") & main==""
replace disease = regexr(disease,"VENEREAL","") if regexm(main,"VENEREAL DISEASE")
replace disease = regexr(disease,"DISEASE","") if regexm(main,"VENEREAL DISEASE")

replace main = main+",VENTRAL HERNIA" if regexm(disease,"VENTRAL") & regexm(disease,"HERNIA") & main!=""
replace main = "VENTRAL HERNIA" if regexm(disease,"VENTRAL") & regexm(disease,"HERNIA")  & main==""
replace disease = regexr(disease,"VENTRAL","") if regexm(main,"VENTRAL HERNIA")
replace disease = regexr(disease,"HERNIA","") if regexm(main,"VENTRAL HERNIA")

replace main = main+",VESICAL FISTULA" if regexm(disease,"VESICAL") & regexm(disease,"FISTULA") & main!=""
replace main = "VESICAL FISTULA" if regexm(disease,"VESICAL") & regexm(disease,"FISTULA")  & main==""
replace disease = regexr(disease,"VESICAL","") if regexm(main,"VESICAL FISTULA")
replace disease = regexr(disease,"FISTULA","") if regexm(main,"VESICAL FISTULA")

replace main = main+",VITREOUS OPACITY" if regexm(disease,"VITREOUS") & regexm(disease,"OPACITY") & main!=""
replace main = "VITREOUS OPACITY" if regexm(disease,"VITREOUS") & regexm(disease,"OPACITY")  & main==""
replace disease = regexr(disease,"VITREOUS","") if regexm(main,"VITREOUS OPACITY")
replace disease = regexr(disease,"OPACITY","") if regexm(main,"VITREOUS OPACITY")

replace main = main+",WEBBED FINGERS" if regexm(disease,"WEBBED") & regexm(disease,"FINGER") & main!=""
replace main = "WEBBED FINGERS" if regexm(disease,"WEBBED") & regexm(disease,"FINGER")  & main==""
replace disease = regexr(disease,"WEBBED","") if regexm(main,"WEBBED FINGERS")
replace disease = regexr(disease,"FINGER","") if regexm(main,"WEBBED FINGERS")

replace main = main+",WEBBED FINGERS" if regexm(disease,"WEBBED") & regexm(disease,"DIGIT") & main!=""
replace main = "WEBBED FINGERS" if regexm(disease,"WEBBED") & regexm(disease,"DIGIT")  & main==""
replace disease = regexr(disease,"WEBBED","") if regexm(main,"WEBBED FINGERS")
replace disease = regexr(disease,"DIGIT","") if regexm(main,"WEBBED FINGERS")

replace main = main+",WHOOPING COUGH" if regexm(disease,"WHOOPING") & regexm(disease,"COUGH") & main!=""
replace main = "WHOOPING COUGH" if regexm(disease,"WHOOPING") & regexm(disease,"COUGH")  & main==""
replace disease = regexr(disease,"WHOOPING","") if regexm(main,"WHOOPING COUGH")
replace disease = regexr(disease,"COUGH","") if regexm(main,"WHOOPING COUGH")

replace main = main+",WRIST DROP" if regexm(disease,"WRIST") & regexm(disease,"DROP") & main!=""
replace main = "WRIST DROP" if regexm(disease,"WRIST") & regexm(disease,"DROP")  & main==""
replace disease = regexr(disease,"WRIST","") if regexm(main,"WRIST DROP")
replace disease = regexr(disease,"DROP","") if regexm(main,"WRIST DROP")

replace main = main+",WRY NECK" if regexm(disease,"WRY") & regexm(disease,"NECK") & main!=""
replace main = "WRY NECK" if regexm(disease,"WRY") & regexm(disease,"NECK")  & main==""
replace disease = regexr(disease,"WRY","") if regexm(main,"WRY NECK")
replace disease = regexr(disease,"NECK","") if regexm(main,"WRY NECK")

replace main = main+",ZYMOTIC ENTERITIS" if regexm(disease,"ZYMOTIC") & regexm(disease,"ENTERITIS") & main!=""
replace main = "ZYMOTIC ENTERITIS" if regexm(disease,"ZYMOTIC") & regexm(disease,"ENTERITIS")  & main==""
replace disease = regexr(disease,"ZYMOTIC","") if regexm(main,"ZYMOTIC ENTERITIS")
replace disease = regexr(disease,"ENTERITIS","") if regexm(main,"ZYMOTIC ENTERITIS")

replace main = main+",INTESTINAL OBSTRUCTION" if regexm(disease,"INTESTINE") & regexm(disease,"OBSTRUCTION") & main!=""
replace main = "INTESTINAL OBSTRUCTION" if regexm(disease,"INTESTINE") & regexm(disease,"OBSTRUCTION") & main==""
replace disease = regexr(disease,"INTESTINE","") if regexm(main,"INTESTINAL OBSTRUCTION")
replace disease = regexr(disease,"OBSTRUCTION","") if regexm(main,"INTESTINAL OBSTRUCTION")

replace main = main+",CORNEAL DEVIATION" if regexm(disease,"CORNEAL") & regexm(disease,"DEVIATION") & main!=""
replace main = "CORNEAL DEVIATION" if regexm(disease,"CORNEAL") & regexm(disease,"DEVIATION") & main==""
replace disease = regexr(disease,"CORNEAL","") if regexm(main,"CORNEAL DEVIATION")
replace disease = regexr(disease,"DEVIATION","") if regexm(main,"CORNEAL DEVIATION")

replace main = main+",PLEURAL EFFUSION" if regexm(disease,"PLEURAL") & regexm(disease,"EFFUSION") & main!=""
replace main = "PLEURAL EFFUSION" if regexm(disease,"EFFUSION") & regexm(disease,"PLEURAL") & main==""
replace disease = regexr(disease,"PLEURAL","") if regexm(main,"PLEURAL EFFUSION")
replace disease = regexr(disease,"EFFUSION","") if regexm(main,"PLEURAL EFFUSION")

replace main = main+",REDUNDANT PREPUCE" if regexm(disease,"REDUNDANT") & regexm(disease,"PREPUCE") & main!=""
replace main = "REDUNDANT PREPUCE" if regexm(disease,"REDUNDANT") & regexm(disease,"PREPUCE") & main==""
replace disease = regexr(disease,"REDUNDANT","") if regexm(main,"REDUNDANT PREPUCE")
replace disease = regexr(disease,"PREPUCE","") if regexm(main,"REDUNDANT PREPUCE")

replace main = main+",VICIOUS UNION" if regexm(disease,"VICIOUS") & regexm(disease,"UNION") & main!=""
replace main = "VICIOUS UNION" if regexm(disease,"VICIOUS") & regexm(disease,"UNION") & main==""
replace disease = regexr(disease,"VICIOUS","") if regexm(main,"VICIOUS UNION")
replace disease = regexr(disease,"UNION","") if regexm(main,"VICIOUS UNION")

replace main = main+",NEUROTIC GAIT" if regexm(disease,"NEUROTIC") & regexm(disease,"GAIT") & main!=""
replace main = "NEUROTIC GAIT" if regexm(disease,"NEUROTIC") & regexm(disease,"GAIT") & main==""
replace disease = regexr(disease,"NEUROTIC","") if regexm(main,"NEUROTIC GAIT")
replace disease = regexr(disease,"GAIT","") if regexm(main,"NEUROTIC GAIT")

replace main = main+",SPASTIC GAIT" if regexm(disease,"SPASTIC") & regexm(disease,"GAIT") & main!=""
replace main = "SPASTIC GAIT" if regexm(disease,"SPASTIC") & regexm(disease,"GAIT") & main==""
replace disease = regexr(disease,"SPASTIC","") if regexm(main,"SPASTIC GAIT")
replace disease = regexr(disease,"GAIT","") if regexm(main,"SPASTIC GAIT")

replace main = main+",UNSTEADY GAIT" if regexm(disease,"UNSTEADY") & regexm(disease,"GAIT") & main!=""
replace main = "UNSTEADY GAIT" if regexm(disease,"UNSTEADY") & regexm(disease,"GAIT") & main==""
replace disease = regexr(disease,"UNSTEADY","") if regexm(main,"UNSTEADY GAIT")
replace disease = regexr(disease,"GAIT","") if regexm(main,"UNSTEADY GAIT")

replace main = main+",STRIDULOUS BREATHING" if regexm(disease,"STRIDULOUS") & regexm(disease,"BREATHING") & main!=""
replace main = "STRIDULOUS BREATHING" if regexm(disease,"STRIDULOUS") & regexm(disease,"BREATHING") & main==""
replace disease = regexr(disease,"STRIDULOUS","") if regexm(main,"STRIDULOUS BREATHING")
replace disease = regexr(disease,"BREATHING","") if regexm(main,"STRIDULOUS BREATHING")

#delimit ;
local main "
ABDOMINODYNIA ABSCESS ACETONURIA ACHOLIA LYMPHADENITIS ADENITIS LYMPHADENOMA ADENOMA ADHESION AGUE ALBINISM ALBUMINURIA ALETECTASIS AMAUROSIS AMETROPIA AMBLYOPIA AMYOTROPHY ANASARCA ANCHYLOSIS ANEMIA ANENCEPHALY 
ANEURYSM ANKYLOBLEPHARON ANTHYOPIA ANTHRAX ANURIA APHAKIA APHALANGIA APHASIA APPENDICITIS OSTEOARTHRITIS ARTHRITIS ASCARIASIS ALKAPTONURIA ALOPECIA AMENTIA ANGIOMA ANOREXIA ANXIETY APHEMIA APHONIA ASCITES 
ASPHYXIA ASTHMA ASTHENOPIA ASTIGMATISM ATAXIA ATRESIA ARTHRALGIA ASTHENIA ATELIOSIS ATELECTASIS ATONY 
BALANITIS BLEPHARITIS BLEPHAROSPASM BLIND BLISTER BUBONOCELE BUBO BRADYCARDIA BRIGHTS BRODIES BRONCHITIS BRONCHOPNEUMONIA BRONCHIECTASIS BRONCHIOLITIS BUPHTHALMOS BURSA BURSITIS BULIMIA
CALCANEUS CALCULUS CANCER CAPITIS CARBUNCLE CARCINOMA CARDIAC CARDIALGIA ENDOCARDITIS PANCARDITIS ENDOPERICARDITIS MYOCARDITIS PERICARDITIS CARDITIS CARIES CATALEPSY CATARRH CATARACT CELLULITIS CEPHALALGIA CEREBRITIS CERVICITIS CHEIROPOMPHOLYX CHEMOSIS CHILBLAINS 
CHLOASMA CHLOROSIS CHOLECYSTITIS DACRYOCYSTITIS CHOLERA ENCHONDROMA CHONDROMA CHOREA RETINOCHOROIDITIS CHOROIDITIS CHORIORETINITIS CICATRIX CIRCINATA CIRCUMCISION CIRRHOSIS CLAVUS CLEFT CLITORITIS COLOBOMA COLITIS CORNEITIS CORYZA 
GLAUCOMA LEUCOMA LYMPHOSARCOMA SARCOMA COMA CONJUNCTIVITIS CONDYLOMATA CONSTIPATION CONTRACTURE CONVULSION COPROSTASIS CORDIS COUGH COXALGIA CRETINISM CRYPTORCHIDISM CROUP CURVATURE CYANOSIS CYCLITIS CYNANCHE
CYSTITIS CYSTIC CYST DACRYOCYSTITIS DACTYLITIS DEBILITY DEMENTIA DESQUAMATION DERMATITIS DERMOID DIABETES DIAPHYSITIS DIARRHEA DIPHTHERIA DIPLEGIA DYSURIA DROPSY DYSPNEA DISTICHIASIS DUMB DYSPHAGIA DYSPEPSIA DYSENTERY DYSTROPHY
ECCHYMOSIS ECLAMPSIA ECTHYMA ECTROPION ECZEMA MYXEDEMA EDEMA ELEPHANTIASIS EMBOLISM EMPHYSEMA EMPYEMA ENCEPHALITIS GASTROENTERITIS ENCEPHALOCELE PERIENTERITIS ENTERITIS ENURESIS EPIDIDYMITIS EPILEPSY EPIPHORA EPIPHYSITIS 
EPIPLOCELE EPISPADIAS EPISTAXIS EPULIS ERYSIPELAS ERYTHEMA ESOPHAGISMUS EXOMPHALOS EXOPHTHALMOS EXOSTOSIS EXTRAVASATION EXTROVERSION 
FAVUS FEBRIS FEVER FIBROMYALGIA FIBROID FIBROSIS FIBROMA FISSURE FISTULA FRIEDRICHS FURUNCLE FROSTBITE
GALLSTONE GANGLION GANGRENE GASTRITIS GASTRODYNIA GIGANTISM GINGIVITIS GLIOMA GLOSSITIS GLOTTITIS GLYCOSURIA GRANULOMA GOITRE GONORRHEA GOUT GRANULOMATOSIS GRAVES GUMMA
HALLUCINATION HARELIP HEMARTHROSIS HEMATEMESIS HEMATOCELE CEPHALHEMATOMA HEMATOMA HEMATURIA HEMIKINESIS HEMIPLEGIA HEMOGLOBINURIA HEMOPHILIA HEMOPTYSIS HEMORRHAGE HEMORRHOID HEPATITIS HERMAPHRODITISM HERNIA HERPES 
HIRSUTISM HODGKINS HOSPITALISM HYDATID HYDROCELE HYDROCEPHALUS HYDRONEPHROSIS HYDROPERITONEUM HYDROPHOBIA HYDROTHORAX HYGROMA HYPEREMIA HYPERPYREXIA HYPERMETROPIA HYPEROSTOSIS HYPERTROPHY HYPHEMA HYPOPYON HYPOSPADIAS 
HYSTERIA HYPOTHERMIA HYPERESTHESIA HYDROMYELIA HYPOCHONDRIA 
ICHTHYMA ICHTHYOSIS ICTERUS IDIOCY ILEITIS IMBECILITY IMPERFORATE PERFORATED IDIOT IMPETIGO INANITION INDURATION INFANTILE INFANTUM INFANTILISM INFLUENZA INGROWN INSANITY INTERTRIGO INTRACRANIUM INTUSSUSCEPTION IRIDEMIA IRITIS 
IRIDOPLEGIA IRIDODIALYSIS JAUNDICE 
KAPOSIS KELOID KERATITIS KERATOCONUS KERATOMALACIA KYPHOSIS
LANGUOR LARYNGITIS LESION LEONTIASIS LEPROSY LEUCODERMA LEUCOCYTHEMIA LEUCORRHEA LEUKEMIA LICHEN LIPOMA LITHEMIA LITHURIA LUMBAGO LUPUS LYMPHANGIOMA LYMPHANGIECTASIA LYMPHANGITIS LYMPHOMA 
MALARIA MALNUTRITION MANIA MARASMUS MASTITIS MASTODYNIA MASTOIDITIS MELANA MENINGOCELE MENINGITIS MEASLES MEDIASTINITIS MELANCHOLIA MESENTERY MICROCEPHALUS MICROPHTHALMUS 
MEMBRANOUS MENORRHAGIA MICROCEPHALY MICROSTOMA MICTURITION MITRAL MOLE MOLLUSCUM MONGOLISM MONORCHISM MORBILLI MUMPS MUCOCELE MUTISM MYOPIA OSTEOMYELITIS POLIOMYELITIS MYDRIASIS MYELITIS MYOPATHY MYOSITIS 
NEBULA NEGLECT NEOPLASM NECROSIS NEPHRITIS NEPHROLITHIASIS NEURALGIA NEURITIS NEUROMA NEUROMIMESIS NEUROSIS NEVOID NEVUS NEONATORUM NOMA NYCTALOPIA NYSTAGMUS PYONEPHROSIS NEPHROSIS NEUROPATHY
OCCLUSION OLIGURIA ONYCHIA OPACITY PANOPHTHALMIA OPHTHALMIA OPHTHALMOPLEGIA PERIORCHITIS OBESITY OPISTHOTONOS ORCHITIS ORTHOPEDY OSTEOMALACIA OSTEOMA PERIOSTEITIS OSTEITIS PAROTITIS OSTEOCLASIA OTITIS OTORRHEA HYPEROXALURIA OZAENA 
PALPEBRAE PALSY PANOPHTHALMITIS PAPILLITIS PAPILLOMA PARALYSIS PARAPHIMOSIS PARAPLEGIA PARESIS PELIOSIS PEMPHIGUS PERICHONDRITIS PERITONITIS PERIOSTITIS PERITYPHLITIS PERTUSSIS PITYRIASIS PHAGEDENA PHARYNGITIS PHARYNGISMUS 
PHENOMENALISM PHIMOSIS PHLEBITIS PHRENITIS PHTHISIS PILES PLANUS PLEURISY PLEURODYNIA PLEUROPNEUMONIA PNEUMONIA PYOPNEUMOTHORAX PNEUMOTHORAX POLYDIPSIA POLIOENCEPHALITIS POLYP POLYURIA POMPHOLYX PONTONITIS PREMATURITY 
PROCTISIS PROLAPSE PROPTOSIS PRURIGO PSORIASIS PTOSIS PUBERTY PUBIS PULMONARY PUPIL PURPURA PYELITIS PYEMIA PYONEPHROSIS PYOPNEUMOTHORAX PYOSALPINX PYREXIA PYURIA PYLE QUINSY 
RACHITIS REFRACTION RETARDED RETINITIS RHEUMATISM RHEUMATIC RHINITIS RHINORRHEA RICKETS RINGWORM RUBELLA 
SARCOCELE SCABIES SCALES SCLERODERMA SCLEROSIS SCOLIOSIS SCROFULA SCROFULODERMA SCURVY SEBORRHEA SEIZURE SEPSIS SEPTICEMIA SEQUESTRUM SMALLPOX SEQUELA SHINGLES SICCA SLOUGH SPEECH SPERMATOCELE SPLENOMEGALY STAPHYLOMA STAPHYLOCOCCUS STARVATION STENOSIS 
STOMATITIS STRABISMUS STRICTURE STRUMA STRUMOUS STYE SUNSTROKE SUPERNUMERARY SYMPATHETIC SYNECHIA SYPHILIS SUPERNUMERACY SYNCOPE SYNOSTOSIS TENOSYNOVITIS SYNOVITIS SYRINGOMYELIA 
TABES TACHYCARDIA TALIPES TAPEWORM TERATOMA TETANY TETANUS THROMBOSIS THRUSH TINEA TONSILLITIS TORSION TORTICOLLIS TOXEMIA TRACHEITIS TRACHOMA TRANSPOSITION TRICHIASIS TRICHINOSIS TRISMUS TUBERCULAR TUBERCLE TUBERCULOSIS TUMOUR 
TYMPANITIS TYPHLITIS TYPHLITIS TYPHUS 
ULCER UREMIA URTICARIA UVEITIS VACCINIA VAGINITIS VALVULAR VARICELLA VARICOCELE VARUS VENEREAL VERMIFORMIS VASCULAR VERRUCA VERTIGO VOMITING VULVITIS WARTS WASTING WHITLOW XANTHELASMA XERODERMA";
#delimit cr;
foreach type of local main {
	replace main = main+",`type'" if regexm(disease,"`type'") & main!=""
	replace main = "`type'" if regexm(disease,"`type'") & main==""
	replace disease = regexr(disease,"`type'","")
}

replace main = regexr(main,"TUBERCULAR","TUBERCULAR DISEASE") if regexm(main,"DISEASE") == 0
replace main = "IMPERFORATE DESCENDED TESTICLE" if dis_orig == "IMPERFORATED DESCENDED TESTES"

* Surgery:

gen surgery = ""

replace surgery = surgery+",PLASTER JACKET" if regexm(disease,"PLASTER") & regexm(disease,"JACKET") & surgery!=""
replace surgery = "PLASTER JACKET" if regexm(disease,"PLASTER") & regexm(disease,"JACKET") & surgery==""
replace disease = regexr(disease,"PLASTER","") if regexm(surgery,"PLASTER JACKET")
replace disease = regexr(disease,"JACKET","") if regexm(surgery,"PLASTER JACKET")

replace surgery = surgery+",RADICAL CURE" if regexm(disease,"RADICAL") & regexm(disease,"CURE") & surgery!=""
replace surgery = "RADICAL CURE" if regexm(disease,"RADICAL") & regexm(disease,"CURE") & surgery==""
replace disease = regexr(disease,"RADICAL","") if regexm(surgery,"RADICAL CURE")
replace disease = regexr(disease,"CURE","") if regexm(surgery,"RADICAL CURE")

replace surgery = surgery+",AMPUTATION" if regexm(main,"SYME'S") & main != "" & regexm(main,"AMPUTATION") == 0
replace surgery = "AMPUTATION" if regexm(main,"SYME'S") & main == "" & regexm(disease,"AMPUTATION") == 0

#delimit ;
local surg "
AMPUTATION ANESTHESIA APPARATUS APPENDECTOMY ARTIFICIAL ARTHRECTOMY CAPSULOTOMY CATHETER COLOTOMY CRANIECTOMY EROSION EXCISION EXTRACTION INSTRUMENT LAMINECTOMY LITHOTOMY OPERATION OSTEOTOMY PARACENTESIS PLASTIC PTERYGIUM
REMOVAL RESECTION RHINOPLASTY SPLINT STITCH SUTURE TENOTOMY TONSILLOTOMY TONSILLECTOMY TRACHEOTOMY TRACHEOSTOMY";
#delimit cr;

foreach type of local surg {
	replace surgery = surgery + ",`type'" if regexm(disease,"`type'") & surgery!=""
	replace surgery = "`type'" if regexm(disease,"`type'") & surgery==""
	replace disease = regexr(disease,"`type'","")
}

* Symptoms:

gen sympt = ""

replace sympt = sympt+",HEART MURMUR" if regexm(disease,"HEART") & regexm(disease,"MURMUR") & sympt!=""
replace sympt = "HEART MURMUR" if regexm(disease,"HEART") & regexm(disease,"MURMUR") & sympt==""
replace disease = regexr(disease,"HEART","") if regexm(sympt,"HEART MURMUR")
replace disease = regexr(disease,"MURMUR","") if regexm(sympt,"HEART MURMUR")

replace sympt = sympt+",APPETITE DISORDER" if regexm(disease,"APPETITE") & regexm(disease,"DISORDER") & sympt!=""
replace sympt = "APPETITE DISORDER" if regexm(disease,"APPETITE") & regexm(disease,"DISORDER") & sympt==""
replace disease = regexr(disease,"APPETITE","") if regexm(sympt,"APPETITE DISORDER")
replace disease = regexr(disease,"DISORDER","") if regexm(sympt,"APPETITE DISORDER")

replace sympt = sympt+",ARTICULAR PAIN" if regexm(disease,"ARTICULAR") & regexm(disease,"PAIN") & sympt!=""
replace sympt = "ARTICULAR PAIN" if regexm(disease,"ARTICULAR") & regexm(disease,"PAIN") & sympt==""
replace disease = regexr(disease,"ARTICULAR","") if regexm(sympt,"ARTICULAR PAIN")
replace disease = regexr(disease,"PAIN","") if regexm(sympt,"ARTICULAR PAIN")

replace sympt = sympt+",BILIOUS ATTACK" if regexm(disease,"BILIOUS") & regexm(disease,"ATTACK") & sympt!=""
replace sympt = "BILIOUS ATTACK" if regexm(disease,"BILIOUS") & regexm(disease,"ATTACK") & sympt==""
replace disease = regexr(disease,"BILIOUS","") if regexm(sympt,"BILIOUS ATTACK")
replace disease = regexr(disease,"ATTACK","") if regexm(sympt,"BILIOUS ATTACK")

replace sympt = sympt+",BRITTLE BONE DISEASE" if regexm(disease,"BRITTLE") & regexm(disease,"BONE") & regexm(disease,"DISEASE") & sympt!=""
replace sympt = "BRITTLE BONE DISEASE" if regexm(disease,"BRITTLE") & regexm(disease,"BONE") & regexm(disease,"DISEASE") & sympt==""
replace disease = regexr(disease,"BRITTLE","") if regexm(sympt,"BRITTLE BONE DISEASE")
replace disease = regexr(disease,"BONE","") if regexm(sympt,"BRITTLE BONE DISEASE")
replace disease = regexr(disease,"DISEASE","") if regexm(sympt,"BRITTLE BONE DISEASE")

replace sympt = sympt+",INABILITY TO SWALLOW" if regexm(disease,"INABILITY") & regexm(disease,"SWALLOW") & sympt!=""
replace sympt = "INABILITY TO SWALLOW" if regexm(disease,"INABILITY") & regexm(disease,"SWALLOW") & sympt==""
replace disease = regexr(disease,"INABILITY","") if regexm(sympt,"INABILITY TO SWALLOW")
replace disease = regexr(disease,"SWALLOW","") if regexm(sympt,"INABILITY TO SWALLOW")

replace sympt = sympt+",INABILITY TO WALK" if regexm(disease,"INABILITY") & regexm(disease,"WALK") & sympt!=""
replace sympt = "INABILITY TO WALK" if regexm(disease,"INABILITY") & regexm(disease,"WALK") & sympt==""
replace disease = regexr(disease,"INABILITY","") if regexm(sympt,"INABILITY TO WALK")
replace disease = regexr(disease,"WALK","") if regexm(sympt,"INABILITY TO WALK")

replace sympt = sympt+",LINE IN EYE" if regexm(disease,"LINE") & regexm(disease,"EYE") & sympt!=""
replace sympt = "LINE IN EYE" if regexm(disease,"LINE") & regexm(disease,"EYE") & sympt==""
replace disease = regexr(disease,"LINE","") if regexm(sympt,"LINE IN EYE")
replace disease = regexr(disease,"EYE","") if regexm(sympt,"LINE IN EYE")

replace sympt = sympt+",LOSING FLESH" if regexm(disease,"LOSING") & regexm(disease,"FLESH") & sympt!=""
replace sympt = "LOSING FLESH" if regexm(disease,"LOSING") & regexm(disease,"FLESH") & sympt==""
replace disease = regexr(disease,"LOSING","") if regexm(sympt,"LOSING FLESH")
replace disease = regexr(disease,"FLESH","") if regexm(sympt,"LOSING FLESH")

replace sympt = sympt+",LOSS OF FINGER" if regexm(disease,"LOSS") & regexm(disease,"FINGER") & sympt!=""
replace sympt = "LOSS OF FINGER" if regexm(disease,"LOSS") & regexm(disease,"FINGER") & sympt==""
replace disease = regexr(disease,"LOSS","") if regexm(sympt,"LOSS OF FINGER")
replace disease = regexr(disease,"FINGER","") if regexm(sympt,"LOSS OF FINGER")

replace sympt = sympt+",LOSS OF HUMOR" if regexm(disease,"LOSS") & regexm(disease,"HUMOR") & sympt!=""
replace sympt = "LOSS OF HUMOR" if regexm(disease,"LOSS") & regexm(disease,"HUMOR") & sympt==""
replace disease = regexr(disease,"LOSS","") if regexm(sympt,"LOSS OF HUMOR")
replace disease = regexr(disease,"HUMOR","") if regexm(sympt,"LOSS OF HUMOR")

replace sympt = sympt+",LOSS OF WALKING POWER" if regexm(disease,"LOSS") & regexm(disease,"POWER") & regexm(disease,"WALKING") & sympt!=""
replace sympt = "LOSS OF WALKING POWER" if regexm(disease,"LOSS") & regexm(disease,"POWER") & regexm(disease,"WALKING") & sympt==""
replace disease = regexr(disease,"LOSS","") if regexm(sympt,"LOSS OF WALKING POWER")
replace disease = regexr(disease,"POWER","") if regexm(sympt,"LOSS OF WALKING POWER")
replace disease = regexr(disease,"WALKING","") if regexm(sympt,"LOSS OF WALKING POWER")

replace sympt = sympt+",LOSS OF POWER" if regexm(disease,"LOSS") & regexm(disease,"POWER") & sympt!=""
replace sympt = "LOSS OF POWER" if regexm(disease,"LOSS") & regexm(disease,"POWER") & sympt==""
replace disease = regexr(disease,"LOSS","") if regexm(sympt,"LOSS OF POWER")
replace disease = regexr(disease,"POWER","") if regexm(sympt,"LOSS OF POWER")

replace sympt = sympt+",LOSS OF SIGHT" if regexm(disease,"LOSS") & regexm(disease,"SIGHT") & sympt!=""
replace sympt = "LOSS OF SIGHT" if regexm(disease,"LOSS") & regexm(disease,"SIGHT") & sympt==""
replace disease = regexr(disease,"LOSS","") if regexm(sympt,"LOSS OF SIGHT")
replace disease = regexr(disease,"SIGHT","") if regexm(sympt,"LOSS OF SIGHT")

replace sympt = sympt+",DEFECTIVE SIGHT" if regexm(disease,"DEFECTIVE") & regexm(disease,"SIGHT") & sympt!=""
replace sympt = "DEFECTIVE SIGHT" if regexm(disease,"DEFECTIVE") & regexm(disease,"SIGHT") & sympt==""
replace disease = regexr(disease,"DEFECTIVE","") if regexm(sympt,"DEFECTIVE SIGHT")
replace disease = regexr(disease,"SIGHT","") if regexm(sympt,"DEFECTIVE SIGHT")

replace sympt = sympt+",LONG SIGHT" if regexm(disease,"LONG") & regexm(disease,"SIGHT") & sympt!=""
replace sympt = "LONG SIGHT" if regexm(disease,"LONG") & regexm(disease,"SIGHT") & sympt==""
replace disease = regexr(disease,"LONG","") if regexm(sympt,"LONG SIGHT")
replace disease = regexr(disease,"SIGHT","") if regexm(sympt,"LONG SIGHT")

replace sympt = sympt+",SHORT SIGHT" if regexm(disease,"SHORT") & regexm(disease,"SIGHT") & sympt!=""
replace sympt = "SHORT SIGHT" if regexm(disease,"SHORT") & regexm(disease,"SIGHT") & sympt==""
replace disease = regexr(disease,"SHORT","") if regexm(sympt,"SHORT SIGHT")
replace disease = regexr(disease,"SIGHT","") if regexm(sympt,"SHORT SIGHT")

replace sympt = sympt+",LOSS OF USE" if regexm(disease,"LOSS") & regexm(disease,"USE") & sympt!=""
replace sympt = "LOSS OF USE" if regexm(disease,"LOSS") & regexm(disease,"USE") & sympt==""
replace disease = regexr(disease,"LOSS","") if regexm(sympt,"LOSS OF USE")
replace disease = regexr(disease,"USE","") if regexm(sympt,"LOSS OF USE")

replace sympt = sympt+",LOSS OF VOICE" if regexm(disease,"LOSS") & regexm(disease,"VOICE") & sympt!=""
replace sympt = "LOSS OF VOICE" if regexm(disease,"LOSS") & regexm(disease,"VOICE") & sympt==""
replace disease = regexr(disease,"LOSS","") if regexm(sympt,"LOSS OF VOICE")
replace disease = regexr(disease,"VOICE","") if regexm(sympt,"LOSS OF VOICE")

replace sympt = sympt+",LOSS OF WEIGHT" if regexm(disease,"LOSS") & regexm(disease,"WEIGHT") & sympt!=""
replace sympt = "LOSS OF WEIGHT" if regexm(disease,"LOSS") & regexm(disease,"WEIGHT") & sympt==""
replace disease = regexr(disease,"LOSS","") if regexm(sympt,"LOSS OF WEIGHT")
replace disease = regexr(disease,"WEIGHT","") if regexm(sympt,"LOSS OF WEIGHT")

replace sympt = sympt+",MIMETIC MOVEMENT" if regexm(disease,"MIMETIC") & regexm(disease,"MOVEMENT") & sympt!=""
replace sympt = "MIMETIC MOVEMENT" if regexm(disease,"MIMETIC") & regexm(disease,"MOVEMENT") & sympt==""
replace disease = regexr(disease,"MIMETIC","") if regexm(sympt,"MIMETIC MOVEMENT")
replace disease = regexr(disease,"MOVEMENT","") if regexm(sympt,"MIMETIC MOVEMENT")

replace sympt = sympt+",NIGHT TERRORS" if regexm(disease,"NIGHT") & regexm(disease,"TERRORS") & sympt!=""
replace sympt = "NIGHT TERRORS" if regexm(disease,"NIGHT") & regexm(disease,"TERRORS") & sympt==""
replace disease = regexr(disease,"NIGHT","") if regexm(sympt,"NIGHT TERRORS")
replace disease = regexr(disease,"TERRORS","") if regexm(sympt,"NIGHT TERRORS")

replace sympt = sympt+",NO MEMBRANE" if regexm(disease,"NO MEMBRANE") & sympt!=""
replace sympt = "NO MEMBRANE" if regexm(disease,"NO MEMBRANE") & sympt==""
replace disease = regexr(disease,"NO MEMBRANE","") if regexm(sympt,"NO MEMBRANE")

replace sympt = sympt+",SHORTNESS OF BREATH" if regexm(disease,"SHORTNESS") & regexm(disease,"BREATH") & sympt!=""
replace sympt = "SHORTNESS OF BREATH" if regexm(disease,"SHORTNESS") & regexm(disease,"BREATH") & sympt==""
replace disease = regexr(disease,"SHORTNESS","") if regexm(sympt,"SHORTNESS OF BREATH")
replace disease = regexr(disease,"BREATH","") if regexm(sympt,"SHORTNESS OF BREATH")

replace sympt = sympt+",TENDER SPOT" if regexm(disease,"TENDER") & regexm(disease,"SPOT") & sympt!=""
replace sympt = "TENDER SPOT" if regexm(disease,"TENDER") & regexm(disease,"SPOT") & sympt==""
replace disease = regexr(disease,"TENDER","") if regexm(sympt,"TENDER SPOT")
replace disease = regexr(disease,"SPOT","") if regexm(sympt,"TENDER SPOT")

replace sympt = sympt+",DIFFICULTY BREATHING" if regexm(disease,"DIFFICULTY") & regexm(disease,"BREATH") & sympt!=""
replace sympt = "DIFFICULTY BREATHING" if regexm(disease,"DIFFICULTY") & regexm(disease,"BREATH") & sympt==""
replace disease = regexr(disease,"DIFFICULTY","") if regexm(sympt,"DIFFICULTY BREATHING")
replace disease = regexr(disease,"BREATH(ING)*","") if regexm(sympt,"DIFFICULTY BREATHING")

#delimit ;
local sympt "ABSENCE ACCUMULATION ADHERENT AFFECTION AFFLICTION ATROPHY BLEEDING BLOODSHOT BREATHING BULLAE BURST 
CALLUS CLOSURE COLD COLLAPSE COMMINUTED COMPENSATION COMPRESSION CONDITION CONFUSION CONGESTION CONSOLIDATION CONSTRICTED CONTRACTION CONTAGIOUS CRAMP CROAKING CURVED
DAMAGE DEAFNESS DEFECTIVE DEFORMITY DEFLECTED DEGENERATIVE DELIRIUM DERANGEMENT DETACHMENT DEVIATION DEVELOPMENT DIFFICULTY DIFFUSION DILATION DILATATION DISEASE DISCHARGE DISORDER DISPLACEMENT DISSEMINATED DISTENSION
DISTORTION DIVIDED DRUNK DROWSINESS DULLNESS DECAY DEFECT DEGENERATION
EARACHE EDEMATOUS ELONGATED EMACIATION ENLARGEMENT EFFUSION ERUPTION EXHAUSTION EXTRUSION FAINT FALTY FATTY FIT FILM FISSION FLATULENCE FLEX FLUID FRICTION FUNGATING FUNCTIONAL 
GIDDINESS GRANULATION GROWTH HEADACHE HOARSENESS HYSTERICAL 
IDLENESS ILLNESS IMMERSION IMPEDIMENT IMPACTION IMPAIRMENT INCONTINENCE INDIGESTION INFECTION INFLAMMATION INSUFFICIENCY IRRITATION INSENSIBILITY INCOORDINATION INVERTED 
LACHRYMATION LAMENESS LIPPITUDE LOOSE LUMP 
MALFORMATION MALPOSITION MALAISE MALINGERING MALUNITED MASTURBATION MENSTRUATION MIGRAINE MISCHIEF MISPLACED MORBUS MOVABLE MOVEMENT 
NARROWED NERVES NEUTRAL OBSTRUCTION OPAQUE PAIN PAUPERTAS PEELING PERCUSSION PHLEGM PHOTOPHOBIA PRESSURE PURULENT 
RASH RECESSION REDUCTION REGURGITATION RESPIRATION RESONANCE RETAINED RETENTION RETRACTION RIGOR RIGIDITY RUPTURE 
SALIVATION SCIATICA SEPARATION SHIVERING SHORTNESS SHRUNKEN SICKNESS SLOUGHING SNEEZING SOFT SORE SPASM SPASTIC SPITTING SQUINT STAMMERING STIFF STRANGULATED STRICTURE STRIDOR STUPOR SUFFOCATION SUICIDAL 
SUPPURATION SUPPRESSION SWALLOWING SWELLING SYMPTOM TENDER THICKENED TRAUMATISM TREMOR TWITCHING TEETHING 
UNCONSCIOUS UNDIFFERENTIATED UNEQUAL UNUNITED VEGETATION VENOUS VOMITING WEAKNESS";
#delimit cr;

foreach type of local sympt {
	replace sympt = sympt + ",`type'" if regexm(disease,"`type'") & sympt!=""
	replace sympt = "`type'" if regexm(disease,"`type'") & sympt==""
	replace disease = regexr(disease,"`type'","")
}

* Extract body part component
gen bodypt = ""

replace bodypt = bodypt+",ANTERIOR CHAMBER" if regexm(disease,"ANTERIOR") & regexm(disease,"CHAMBER") & bodypt!=""
replace bodypt = "ANTERIOR CHAMBER" if regexm(disease,"ANTERIOR") & regexm(disease,"CHAMBER")  & bodypt==""
replace disease = regexr(disease,"ANTERIOR","") if regexm(bodypt,"ANTERIOR CHAMBER")
replace disease = regexr(disease,"CHAMBER","") if regexm(bodypt,"ANTERIOR CHAMBER")

replace bodypt = bodypt+",AUDITORY CANAL" if regexm(disease,"AUDITORY") & regexm(disease,"CANAL") & bodypt!=""
replace bodypt = "AUDITORY CANAL" if regexm(disease,"AUDITORY") & regexm(disease,"CANAL")  & bodypt==""
replace disease = regexr(disease,"AUDITORY","") if regexm(bodypt,"AUDITORY CANAL")
replace disease = regexr(disease,"CANAL","") if regexm(bodypt,"AUDITORY CANAL")

replace bodypt = bodypt+",AUDITORY MEATUS" if regexm(disease,"AUDITORY") & regexm(disease,"MEATUS") & bodypt!=""
replace bodypt = "AUDITORY MEATUS" if regexm(disease,"AUDITORY") & regexm(disease,"MEATUS")  & bodypt==""
replace disease = regexr(disease,"AUDITORY","") if regexm(bodypt,"AUDITORY MEATUS")
replace disease = regexr(disease,"MEATUS","") if regexm(bodypt,"AUDITORY MEATUS")

replace bodypt = bodypt+",BILE DUCT" if regexm(disease,"BILE") & regexm(disease,"DUCT") & bodypt!=""
replace bodypt = "BILE DUCT" if regexm(disease,"BILE") & regexm(disease,"DUCT")  & bodypt==""
replace disease = regexr(disease,"BILE","") if regexm(bodypt,"BILE DUCT")
replace disease = regexr(disease,"DUCT","") if regexm(bodypt,"BILE DUCT")

replace bodypt = bodypt+",BRACHIAL ARTERY" if regexm(disease,"BRACHIAL") & regexm(disease,"ARTERY") & bodypt!=""
replace bodypt = "BRACHIAL ARTERY" if regexm(disease,"BRACHIAL") & regexm(disease,"ARTERY") & bodypt==""
replace disease = regexr(disease,"BRACHIAL","") if regexm(bodypt,"BRACHIAL ARTERY")
replace disease = regexr(disease,"ARTERY","") if regexm(bodypt,"BRACHIAL ARTERY")

replace bodypt = bodypt+",CONICAL STUMP" if regexm(disease,"CONICAL") & regexm(disease,"STUMP") & bodypt!=""
replace bodypt = "CONICAL STUMP" if regexm(disease,"CONICAL") & regexm(disease,"STUMP")  & bodypt==""
replace disease = regexr(disease,"CONICAL","") if regexm(bodypt,"CONICAL STUMP")
replace disease = regexr(disease,"STUMP","") if regexm(bodypt,"CONICAL STUMP")

replace bodypt = bodypt+",FLEXOR TENDON" if regexm(disease,"FLEXOR") & regexm(disease,"TENDON") & bodypt!=""
replace bodypt = "FLEXOR TENDON" if regexm(disease,"FLEXOR") & regexm(disease,"TENDON")  & bodypt==""
replace disease = regexr(disease,"FLEXOR","") if regexm(bodypt,"FLEXOR TENDON")
replace disease = regexr(disease,"TENDON","") if regexm(bodypt,"FLEXOR TENDON")

replace bodypt = bodypt+",GALL BLADDER" if regexm(disease,"GALL") & regexm(disease,"BLADDER") & bodypt!=""
replace bodypt = "GALL BLADDER" if regexm(disease,"GALL") & regexm(disease,"BLADDER")  & bodypt==""
replace disease = regexr(disease,"GALL","") if regexm(bodypt,"GALL BLADDER")
replace disease = regexr(disease,"BLADDER","") if regexm(bodypt,"GALL BLADDER")

replace bodypt = bodypt+",ILIAC FOSSA" if regexm(disease,"ILIAC") & regexm(disease,"FOSSA") & bodypt!=""
replace bodypt = "ILIAC FOSSA" if regexm(disease,"ILIAC") & regexm(disease,"FOSSA")  & bodypt==""
replace disease = regexr(disease,"ILIAC","") if regexm(bodypt,"ILIAC FOSSA")
replace disease = regexr(disease,"FOSSA","") if regexm(bodypt,"ILIAC FOSSA")

replace bodypt = bodypt+",HARD PALATE" if regexm(disease,"HARD") & regexm(disease,"PALATE") & bodypt!=""
replace bodypt = "HARD PALATE" if regexm(disease,"HARD") & regexm(disease,"PALATE")  & bodypt==""
replace disease = regexr(disease,"HARD","") if regexm(bodypt,"HARD PALATE")
replace disease = regexr(disease,"PALATE","") if regexm(bodypt,"HARD PALATE")

replace bodypt = bodypt+",ILIAC CREST" if regexm(disease,"ILIAC") & regexm(disease,"CREST") & bodypt!=""
replace bodypt = "ILIAC CREST" if regexm(disease,"ILIAC") & regexm(disease,"CREST")  & bodypt==""
replace disease = regexr(disease,"ILIAC","") if regexm(bodypt,"ILIAC CREST")
replace disease = regexr(disease,"CREST","") if regexm(bodypt,"ILIAC CREST")

replace bodypt = bodypt+",INDEX FINGER" if regexm(disease,"INDEX") & regexm(disease,"FINGER") & bodypt!=""
replace bodypt = "INDEX FINGER" if regexm(disease,"INDEX") & regexm(disease,"FINGER")  & bodypt==""
replace disease = regexr(disease,"INDEX","") if regexm(bodypt,"INDEX FINGER")
replace disease = regexr(disease,"FINGER","") if regexm(bodypt,"INDEX FINGER")

replace bodypt = bodypt+",INFERIOR MAXILLA" if regexm(disease,"INFERIOR") & regexm(disease,"MAXILLA") & bodypt!=""
replace bodypt = "INFERIOR MAXILLA" if regexm(disease,"INFERIOR") & regexm(disease,"MAXILLA")  & bodypt==""
replace disease = regexr(disease,"INFERIOR","") if regexm(bodypt,"INFERIOR MAXILLA")
replace disease = regexr(disease,"MAXILLA","") if regexm(bodypt,"INFERIOR MAXILLA")

replace bodypt = bodypt+",INFRATEMPORAL FOSSA" if regexm(disease,"INFRATEMPORAL") & regexm(disease,"FOSSA") & bodypt!=""
replace bodypt = "INFRATEMPORAL FOSSA" if regexm(disease,"INFRATEMPORAL") & regexm(disease,"FOSSA")  & bodypt==""
replace disease = regexr(disease,"INFRATEMPORAL","") if regexm(bodypt,"INFRATEMPORAL FOSSA")
replace disease = regexr(disease,"FOSSA","") if regexm(bodypt,"INFRATEMPORAL FOSSA")

replace bodypt = bodypt+",INGUINAL LIGAMENT" if regexm(disease,"POUPARTS") & regexm(disease,"LIGAMENT") & bodypt!=""
replace bodypt = "INGUINAL LIGAMENT" if regexm(disease,"POUPARTS") & regexm(disease,"LIGAMENT")  & bodypt==""
replace disease = regexr(disease,"POUPARTS","") if regexm(bodypt,"INGUINAL LIGAMENT")
replace disease = regexr(disease,"LIGAMENT","") if regexm(bodypt,"INGUINAL LIGAMENT")

replace bodypt = bodypt+",INTERNAL SAPHENOUS NERVE" if regexm(disease,"INTERNAL") & regexm(disease,"SAPHENOUS") & bodypt!=""
replace bodypt = "INTERNAL SAPHENOUS NERVE" if regexm(disease,"INTERNAL") & regexm(disease,"SAPHENOUS")  & bodypt==""
replace disease = regexr(disease,"INTERNAL","") if regexm(bodypt,"INTERNAL SAPHENOUS NERVE")
replace disease = regexr(disease,"SAPHENOUS","") if regexm(bodypt,"INTERNAL SAPHENOUS NERVE")

replace bodypt = bodypt+",INTERNAL SEMILUNAR CARTILAGE" if regexm(disease,"INTERNAL") & regexm(disease,"SEMILUNAR") & regexm(disease,"CARTILAGE") & bodypt!=""
replace bodypt = "INTERNAL SEMILUNAR CARTILAGE" if regexm(disease,"INTERNAL") & regexm(disease,"SEMILUNAR") & regexm(disease,"CARTILAGE")  & bodypt==""
replace disease = regexr(disease,"INTERNAL","") if regexm(bodypt,"INTERNAL SEMILUNAR CARTILAGE")
replace disease = regexr(disease,"SEMILUNAR","") if regexm(bodypt,"INTERNAL SEMILUNAR CARTILAGE")
replace disease = regexr(disease,"CARTILAGE","") if regexm(bodypt,"INTERNAL SEMILUNAR CARTILAGE")

replace bodypt = bodypt+",LATERAL SINUS" if regexm(disease,"LATERAL") & regexm(disease,"SINUS") & bodypt!=""
replace bodypt = "LATERAL SINUS" if regexm(disease,"LATERAL") & regexm(disease,"SINUS")  & bodypt==""
replace disease = regexr(disease,"LATERAL","") if regexm(bodypt,"LATERAL SINUS")
replace disease = regexr(disease,"SINUS","") if regexm(bodypt,"LATERAL SINUS")

replace bodypt = bodypt+",LITTLE TOE" if regexm(disease,"LITTLE") & regexm(disease,"TOE") & bodypt!=""
replace bodypt = "LITTLE TOE" if regexm(disease,"LITTLE") & regexm(disease,"TOE")  & bodypt==""
replace disease = regexr(disease,"LITTLE","") if regexm(bodypt,"LITTLE TOE")
replace disease = regexr(disease,"TOE","") if regexm(bodypt,"LITTLE TOE")

replace bodypt = bodypt+",MASTOID CELLS" if regexm(disease,"MASTOID") & regexm(disease,"CELLS") & bodypt!=""
replace bodypt = "MASTOID CELLS" if regexm(disease,"MASTOID") & regexm(disease,"CELLS")  & bodypt==""
replace disease = regexr(disease,"MASTOID","") if regexm(bodypt,"MASTOID CELLS")
replace disease = regexr(disease,"CELLS","") if regexm(bodypt,"MASTOID CELLS")

replace bodypt = bodypt+",MASTOID PROCESS" if regexm(disease,"MASTOID") & regexm(disease,"PROCESS") & bodypt!=""
replace bodypt = "MASTOID PROCESS" if regexm(disease,"MASTOID") & regexm(disease,"PROCESS")  & bodypt==""
replace disease = regexr(disease,"MASTOID","") if regexm(bodypt,"MASTOID PROCESS")
replace disease = regexr(disease,"PROCESS","") if regexm(bodypt,"MASTOID PROCESS")

replace bodypt = bodypt+",MEATUS URINARIUS" if regexm(disease,"MEATUS") & regexm(disease,"URINARIUS") & bodypt!=""
replace bodypt = "MEATUS URINARIUS" if regexm(disease,"MEATUS") & regexm(disease,"URINARIUS")  & bodypt==""
replace disease = regexr(disease,"MEATUS","") if regexm(bodypt,"MEATUS URINARIUS")
replace disease = regexr(disease,"URINARIUS","") if regexm(bodypt,"MEATUS URINARIUS")

replace bodypt = bodypt+",MEDIAN NERVE" if regexm(disease,"MEDIAN") & regexm(disease,"NERVE") & bodypt!=""
replace bodypt = "MEDIAN NERVE" if regexm(disease,"MEDIAN") & regexm(disease,"NERVE")  & bodypt==""
replace disease = regexr(disease,"MEDIAN","") if regexm(bodypt,"MEDIAN NERVE")
replace disease = regexr(disease,"NERVE","") if regexm(bodypt,"MEDIAN NERVE")

replace bodypt = bodypt+",NASAL SEPTUM" if regexm(disease,"NASAL") & regexm(disease,"SEPTUM") & bodypt!=""
replace bodypt = "NASAL SEPTUM" if regexm(disease,"NASAL") & regexm(disease,"SEPTUM")  & bodypt==""
replace disease = regexr(disease,"NASAL","") if regexm(bodypt,"NASAL SEPTUM")
replace disease = regexr(disease,"SEPTUM","") if regexm(bodypt,"NASAL SEPTUM")

replace bodypt = bodypt+",NERVOUS TISSUE" if regexm(disease,"NERVOUS") & regexm(disease,"TISSUE") & bodypt!=""
replace bodypt = "NERVOUS TISSUE" if regexm(disease,"NERVOUS") & regexm(disease,"TISSUE")  & bodypt==""
replace disease = regexr(disease,"NERVOUS","") if regexm(bodypt,"NERVOUS TISSUE")
replace disease = regexr(disease,"TISSUE","") if regexm(bodypt,"NERVOUS TISSUE")

replace bodypt = bodypt+",OS CALCIS" if regexm(disease,"OS") & regexm(disease,"CALCIS") & bodypt!=""
replace bodypt = "OS CALCIS" if regexm(disease,"OS") & regexm(disease,"CALCIS")  & bodypt==""
replace disease = regexr(disease,"OS","") if regexm(bodypt,"OS CALCIS")
replace disease = regexr(disease,"CALCIS","") if regexm(bodypt,"OS CALCIS")

replace bodypt = bodypt+",PALMARIS LONGUS" if regexm(disease,"PALMARIS") & regexm(disease,"LONGUS") & bodypt!=""
replace bodypt = "PALMARIS LONGUS" if regexm(disease,"PALMARIS") & regexm(disease,"LONGUS")  & bodypt==""
replace disease = regexr(disease,"PALMARIS","") if regexm(bodypt,"PALMARIS LONGUS")
replace disease = regexr(disease,"LONGUS","") if regexm(bodypt,"PALMARIS LONGUS")

replace bodypt = bodypt+",PLANTAR ARTERY" if regexm(disease,"PLANTAR") & regexm(disease,"ARTERY") & bodypt!=""
replace bodypt = "PLANTAR ARTERY" if regexm(disease,"PLANTAR") & regexm(disease,"ARTERY")  & bodypt==""
replace disease = regexr(disease,"PLANTAR","") if regexm(bodypt,"PLANTAR ARTERY")
replace disease = regexr(disease,"ARTERY","") if regexm(bodypt,"PLANTAR ARTERY")

replace bodypt = bodypt+",ROOF OF MOUTH" if regexm(disease,"ROOF") & regexm(disease,"MOUTH") & bodypt!=""
replace bodypt = "ROOF OF MOUTH" if regexm(disease,"ROOF") & regexm(disease,"MOUTH")  & bodypt==""
replace disease = regexr(disease,"ROOF","") if regexm(bodypt,"ROOF OF MOUTH")
replace disease = regexr(disease,"MOUTH","") if regexm(bodypt,"ROOF OF MOUTH")

replace bodypt = bodypt+",SCARPA TRIANGLE" if regexm(disease,"SCARPA") & regexm(disease,"TRIANGLE") & bodypt!=""
replace bodypt = "SCARPA TRIANGLE" if regexm(disease,"SCARPA") & regexm(disease,"TRIANGLE")  & bodypt==""
replace disease = regexr(disease,"SCARPA","") if regexm(bodypt,"SCARPA TRIANGLE")
replace disease = regexr(disease,"TRIANGLE","") if regexm(bodypt,"SCARPA TRIANGLE")

replace bodypt = bodypt+",SOFT PALATE" if regexm(disease,"SOFT") & regexm(disease,"PALATE") & bodypt!=""
replace bodypt = "SOFT PALATE" if regexm(disease,"SOFT") & regexm(disease,"PALATE")  & bodypt==""
replace disease = regexr(disease,"SOFT","") if regexm(bodypt,"SOFT PALATE")
replace disease = regexr(disease,"PALATE","") if regexm(bodypt,"SOFT PALATE")

replace bodypt = bodypt+",SPERMATIC CORD" if regexm(disease,"SPERMATIC") & regexm(disease,"CORD") & bodypt!=""
replace bodypt = "SPERMATIC CORD" if regexm(disease,"SPERMATIC") & regexm(disease,"CORD")  & bodypt==""
replace disease = regexr(disease,"SPERMATIC","") if regexm(bodypt,"SPERMATIC CORD")
replace disease = regexr(disease,"CORD","") if regexm(bodypt,"SPERMATIC CORD")

replace bodypt = bodypt+",SUPERIOR MAXILLA" if regexm(disease,"SUPERIOR") & regexm(disease,"MAXILLA") & bodypt!=""
replace bodypt = "SUPERIOR MAXILLA" if regexm(disease,"SUPERIOR") & regexm(disease,"MAXILLA")  & bodypt==""
replace disease = regexr(disease,"SUPERIOR","") if regexm(bodypt,"SUPERIOR MAXILLA")
replace disease = regexr(disease,"MAXILLA","") if regexm(bodypt,"SUPERIOR MAXILLA")

replace bodypt = bodypt+",TEAR DUCT" if regexm(disease,"TEAR") & regexm(disease,"DUCT") & bodypt!=""
replace bodypt = "TEAR DUCT" if regexm(disease,"TEAR") & regexm(disease,"DUCT")  & bodypt==""
replace disease = regexr(disease,"TEAR","") if regexm(bodypt,"TEAR DUCT")
replace disease = regexr(disease,"DUCT","") if regexm(bodypt,"TEAR DUCT")

replace bodypt = bodypt+",TRANSVERSE PROCESS" if regexm(disease,"TRANSVERSE") & regexm(disease,"PROCESS") & bodypt!=""
replace bodypt = "TRANSVERSE PROCESS" if regexm(disease,"TRANSVERSE") & regexm(disease,"PROCESS")  & bodypt==""
replace disease = regexr(disease,"TRANSVERSE","") if regexm(bodypt,"TRANSVERSE PROCESS")
replace disease = regexr(disease,"PROCESS","") if regexm(bodypt,"TRANSVERSE PROCESS")

replace bodypt = bodypt+",URINARY TRACT" if regexm(disease,"URINARY") & regexm(disease,"TRACT") & bodypt!=""
replace bodypt = "URINARY TRACT" if regexm(disease,"URINARY") & regexm(disease,"TRACT")  & bodypt==""
replace disease = regexr(disease,"URINARY","") if regexm(bodypt,"URINARY TRACT")
replace disease = regexr(disease,"TRACT","") if regexm(bodypt,"URINARY TRACT")

replace bodypt = bodypt+",VARIOUS BODY PARTS" if regexm(disease,"VARIOUS") & regexm(disease,"BODY") & regexm(disease,"PARTS") & bodypt!=""
replace bodypt = "VARIOUS BODY PARTS" if regexm(disease,"VARIOUS") & regexm(disease,"BODY") & regexm(disease,"PARTS") & bodypt==""
replace disease = regexr(disease,"VARIOUS","") if regexm(bodypt,"VARIOUS BODY PARTS")
replace disease = regexr(disease,"BODY","") if regexm(bodypt,"VARIOUS BODY PARTS")
replace disease = regexr(disease,"PARTS","") if regexm(bodypt,"VARIOUS BODY PARTS")

replace bodypt = bodypt+",VOCAL CORDS" if regexm(disease,"VOCAL") & regexm(disease,"CORDS") & bodypt!=""
replace bodypt = "VOCAL CORDS" if regexm(disease,"VOCAL") & regexm(disease,"CORDS")  & bodypt==""
replace disease = regexr(disease,"VOCAL","") if regexm(bodypt,"VOCAL CORDS")
replace disease = regexr(disease,"CORDS","") if regexm(bodypt,"VOCAL CORDS")

#delimit ;
local bodypt "
ABDOMEN ABDOMINAL ABDOMINIS ACCESSORY ACHILLES ADENOID ALVEOLAR ALVEOLUS AMYLOID ANGINA ANKLE ANOCOCCYGEAL ANTECHAMBER ANTRUM ANUS AORTA APEX APPENDIX ARCH AUDITORY FOREARM ARM ARTERY AURICLE AURIOLE SUBMAXILLA MAXILLA SUBAXILLA AXILLA 
BACK BASE BELLY BICEPS BLADDER BOW-LEGGED BOWEL BRAIN BRANCHIAL BREAST BRONCHUS BRONCHOCELE BUTTOCK 
CALF CANTHUS CAPILLARY CAPSULE CAPSULAR METACARPUS CARPUS CARTILAGE CAVITY CELLULAR CEREBRAL CEREBELLUM CEREBRUM CERVIX CHAMBER CHEEK CHEST CHOROID CILIARY CLAVICLE COLLARBONE COLLAR COLON CONDYLE CONE CONJUNCTIVE CORD CORACOID 
CORNEA CRANIUM SUBCUTANEOUS CUTANEOUS 
DENTAL DIAPHRAGM DIGIT DORSUM DUCT 
HEART ELBOW ENTROPION EPICONDYLAR EPIDIDYMIS EPIGASTRIUM EPIPHYSIS ESOPHAGUS ETHMOID EXTRAOCULAR EXTENSOR EXTREMITIES EYELID EYEBALL EYELASH EYEBROW EYE 
FACE FASCIA FAUCES FECAL FEMORAL FEMUR FIBULA FIBROUS FINGER FOLLICLE FOREARM FOREHEAD FOOT FRONTAL GASTRIC GENITALIA GLAND GLOBE GLUTEUS GLOTTIS GROIN GUM 
HAMSTRING HAND HEAD HEEL HEPATIC HIP HUMERUS HYPOCHONDRIUM HYPOGASTRIUM HYMEN
SACROILIAC ILIAC ILIUM INGUINAL INTESTINAL INTRACRANIAL INTRAOCULAR INTERCOSTAL INTESTINE IRIS ISCHIORECTAL ISCHIUM INTRATHORACIC
JAW JOINT KIDNEY KNEE LACHRYMAL LABIA LABIUM LARYNX LEG LENS LIMB LIP LIVER LOBE LOIN LUMBAR LUNG LYMPHATIC LYMPH 
MALAR MALLEOLUS MAMMARY MANDIBLE MASTOID MEATUS MEDIAN MEDIASTINUM MEIBOMIAN MEMBRANE MENINGES MESENTERIC METACARPOPHALANGEAL METATARSUS MOLAR MOUTH MUSCLE MUCUS NASOPHARYNX NASAL NOSTRIL NODULE PUBES 
TOENAIL NAIL NECK NERVE NODES NOSE OCCIPUT OCCIPITAL OCULUS OLECRANON OPTIC ORBITAL OVARY ORGANS OMENTUM 
PALATE PALM PARENCHYMA PARIETAL PAROTID PATELLA PECTORAL PELVIS PENIS PERICARDIUM PERICHONDRIUM PERINEUM PERIOSTEUM RETROPERITONEUM PERITONEUM PETROUS PHALANX RETROPHARYNX NASOPHARYNX PHARYNX PHLYCTENULE PINNA PLANTAR PLEURA 
PONTINE POPLITEAL PREPUCE PROLAPSE PROSTATE PSOAS PUBIC PUSTULE PYLORUS
RADIUS RANULA RECTUM RENAL RETINA RIB 
SALIVARY SACRUM SCALP SCAPULA SCLERA SCROTUM SEBACEOUS SEMIMEMBRANOSUS SEPTUM SHEATH SHOULDER SIDE SINUS SKIN SKULL SOCKET SOLE SPINE SPINAL SPLEEN STERNUM STOMACH STUMP SUBDURAL SUBMUCOUS SUBMENTAL 
TARSUS TEMPORAL TEMPLE TENDON TESTICLE THECA THIGH THORACIC THORAX THUMB THROAT THYROID THYROGLOSSAL THYMUS TIBIA TISSUE TOE TONGUE TONSIL TEETH TRACHEA TROCHANTER TUBULE TURBINATE TYMPANUM 
ULNA UMBILICAL UMBILICUS URETHRA GENITOURINARY URINARY URINE UROGENITAL UTERUS UVULA 
VAGINAL VAGINA VALVE VAULT VEIN VENTRICLE VERTEBRAE VESICLE VISION VULVA WRIST";
#delimit cr;

foreach type of local bodypt {
	replace bodypt = bodypt+",`type'" if regexm(disease,"`type'") & bodypt!=""
	replace bodypt = "`type'" if regexm(disease,"`type'") & bodypt==""
	replace disease = regexr(disease,"`type'","")
}

* External causes variables
gen external = ""

replace external = external+",COLLES FRACTURE" if regexm(disease,"COLLES") & regexm(disease,"FRACTURE") & external!=""
replace external = "COLLES FRACTURE" if regexm(disease,"COLLES") & regexm(disease,"FRACTURE")  & external==""
replace disease = regexr(disease,"COLLES","") if regexm(external,"COLLES FRACTURE")
replace disease = regexr(disease,"FRACTURE","") if regexm(external,"COLLES FRACTURE")

replace external = external+",COMPOUND COMMINUTED FRACTURE" if regexm(disease,"COMPOUND") & regexm(disease,"COMMINUTED") & regexm(disease,"FRACTURE") & external!=""
replace external = "COMPOUND COMMINUTED FRACTURE" if regexm(disease,"COMPOUND") & regexm(disease,"COMMINUTED") & regexm(disease,"FRACTURE")  & external==""
replace disease = regexr(disease,"COMPOUND","") if regexm(external,"COMPOUND COMMINUTED FRACTURE")
replace disease = regexr(disease,"COMMINUTED","") if regexm(external,"COMPOUND COMMINUTED FRACTURE")
replace disease = regexr(disease,"FRACTURE","") if regexm(external,"COMPOUND COMMINUTED FRACTURE")

replace external = external+",COMPOUND FRACTURE" if regexm(disease,"COMPOUND") & regexm(disease,"FRACTURE") & external!=""
replace external = "COMPOUND FRACTURE" if regexm(disease,"COMPOUND") & regexm(disease,"FRACTURE")  & external==""
replace disease = regexr(disease,"COMPOUND","") if regexm(external,"COMPOUND FRACTURE")
replace disease = regexr(disease,"FRACTURE","") if regexm(external,"COMPOUND FRACTURE")

replace external = external+",COMPOUND DISLOCATION" if regexm(disease,"COMPOUND") & regexm(disease,"DISLOCATION") & external!=""
replace external = "COMPOUND DISLOCATION" if regexm(disease,"COMPOUND") & regexm(disease,"DISLOCATION")  & external==""
replace disease = regexr(disease,"COMPOUND","") if regexm(external,"COMPOUND DISLOCATION")
replace disease = regexr(disease,"DISLOCATION","") if regexm(external,"COMPOUND DISLOCATION")

replace external = external+",DROWNED IN RIVER" if regexm(disease,"DROWNED") & regexm(disease,"RIVER") & external!=""
replace external = "DROWNED IN RIVER" if regexm(disease,"DROWNED") & regexm(disease,"RIVER")  & external==""
replace disease = regexr(disease,"DROWNED","") if regexm(external,"DROWNED IN RIVER")
replace disease = regexr(disease,"RIVER","") if regexm(external,"DROWNED IN RIVER")

replace external = external+",KNOCKED DOWN" if regexm(disease,"KNOCKED") & regexm(disease,"DOWN") & external!=""
replace external = "KNOCKED DOWN" if regexm(disease,"DOWN") & regexm(disease,"KNOCKED")  & external==""
replace disease = regexr(disease,"KNOCKED","") if regexm(external,"KNOCKED DOWN")
replace disease = regexr(disease,"DOWN","") if regexm(external,"KNOCKED DOWN")

replace external = external+",GREENSTICK FRACTURE" if regexm(disease,"GREENSTICK") & regexm(disease,"FRACTURE") & external!=""
replace external = "GREENSTICK FRACTURE" if regexm(disease,"GREENSTICK") & regexm(disease,"FRACTURE")  & external==""
replace disease = regexr(disease,"GREENSTICK","") if regexm(external,"GREENSTICK FRACTURE")
replace disease = regexr(disease,"FRACTURE","") if regexm(external,"GREENSTICK FRACTURE")

replace external = external+",MALUNITED FRACTURE" if regexm(disease,"MALUNITED") & regexm(disease,"FRACTURE") & external!=""
replace external = "MALUNITED FRACTURE" if regexm(disease,"MALUNITED") & regexm(disease,"FRACTURE")  & external==""
replace disease = regexr(disease,"MALUNITED","") if regexm(external,"MALUNITED FRACTURE")
replace disease = regexr(disease,"FRACTURE","") if regexm(external,"MALUNITED FRACTURE")

replace external = external+",POTTS CURVATURE" if regexm(disease,"POTTS") & regexm(disease,"CURVATURE") & external!=""
replace external = "POTTS CURVATURE" if regexm(disease,"POTTS") & regexm(disease,"CURVATURE")  & external==""
replace disease = regexr(disease,"POTTS","") if regexm(external,"POTTS CURVATURE")
replace disease = regexr(disease,"CURVATURE","") if regexm(external,"POTTS CURVATURE")

replace external = external+",POTTS FRACTURE" if regexm(disease,"POTTS") & regexm(disease,"FRACTURE") & external!=""
replace external = "POTTS FRACTURE" if regexm(disease,"POTTS") & regexm(disease,"FRACTURE")  & external==""
replace disease = regexr(disease,"POTTS","") if regexm(external,"POTTS FRACTURE")
replace disease = regexr(disease,"FRACTURE","") if regexm(external,"POTTS FRACTURE")

replace external = external+",SWALLOWED BOILING WATER" if regexm(disease,"SWALLOWED") & regexm(disease,"BOILING") & regexm(disease,"WATER") & external!=""
replace external = "SWALLOWED BOILING WATER" if regexm(disease,"SWALLOWED") & regexm(disease,"BOILING") & regexm(disease,"WATER") & external==""
replace disease = regexr(disease,"SWALLOWED","") if regexm(external,"SWALLOWED BOILING WATER")
replace disease = regexr(disease,"BOILING","") if regexm(external,"SWALLOWED BOILING WATER")
replace disease = regexr(disease,"WATER","") if regexm(external,"SWALLOWED BOILING WATER")

replace external = external+",UNITED FRACTURE" if regexm(disease,"UNITED") & regexm(disease,"FRACTURE") & external!=""
replace external = "UNITED FRACTURE" if regexm(disease,"UNITED") & regexm(disease,"FRACTURE")  & external==""
replace disease = regexr(disease,"UNITED","") if regexm(external,"UNITED FRACTURE")
replace disease = regexr(disease,"FRACTURE","") if regexm(external,"UNITED FRACTURE")

#delimit ;
local external "ABRASION ACCIDENT BENT BITE BLOW BROKEN BRUISE BULLET BURN COMPOUND CONCUSSION CONTUSION CROOKED CRUSHED DEPRESSION DISLOCATION DROWNING FALL FRACTURE GORGED GORED GUNSHOT
INCISED INJURY INHALATION KICK LACERATION PENETRATING PUNCTURE RUNOVER SCALD SEVERED SHOT SHOCK SMASH SPRAIN STRAIN STAB SWALLOWED TAENIA TORN VIOLENCE WOUND WORMS";
#delimit cr;
foreach type of local external {
	replace external = external + ",`type'" if regexm(disease,"`type'") & external!=""
	replace external = "`type'" if regexm(disease,"`type'") & external==""
	replace disease = regexr(disease,"`type'","")
}

gen object = ""

replace object = object+",HIGH BOOT" if regexm(disease,"HIGH") & regexm(disease,"BOOT") & object!=""
replace object = "HIGH BOOT" if regexm(disease,"HIGH") & regexm(disease,"BOOT")  & object==""
replace disease = regexr(disease,"HIGH","") if regexm(object,"HIGH BOOT")
replace disease = regexr(disease,"BOOT","") if regexm(object,"HIGH BOOT")

replace object = object+",FOREIGN BODY" if regexm(disease,"FOREIGN") & regexm(disease,"BODY") & object!=""
replace object = "FOREIGN BODY" if regexm(disease,"FOREIGN") & regexm(disease,"BODY")  & object==""
replace disease = regexr(disease,"FOREIGN","") if regexm(object,"FOREIGN BODY")
replace disease = regexr(disease,"BODY","") if regexm(object,"FOREIGN BODY")

replace object = object+",CYANIDE POTASSIUM" if regexm(disease,"CYANIDE") & regexm(disease,"POTASSIUM") & object!=""
replace object = "CYANIDE POTASSIUM" if regexm(disease,"CYANIDE") & regexm(disease,"POTASSIUM")  & object==""
replace disease = regexr(disease,"CYANIDE","") if regexm(object,"CYANIDE POTASSIUM")
replace disease = regexr(disease,"POTASSIUM","") if regexm(object,"CYANIDE POTASSIUM")

replace object = object+",CHLOROFORM POISONING" if regexm(disease,"CHLOROFORM") & regexm(disease,"POISONING") & object!=""
replace object = "CHLOROFORM POISONING" if regexm(disease,"CHLOROFORM") & regexm(disease,"POISONING")  & object==""
replace disease = regexr(disease,"CHLOROFORM","") if regexm(object,"CHLOROFORM POISONING")
replace disease = regexr(disease,"POISONING","") if regexm(object,"CHLOROFORM POISONING")

replace object = object+",IODINE POISONING" if regexm(disease,"IODINE") & regexm(disease,"POISONING") & object!=""
replace object = "IODINE POISONING" if regexm(disease,"IODINE") & regexm(disease,"POISONING")  & object==""
replace disease = regexr(disease,"IODINE","") if regexm(object,"IODINE POISONING")
replace disease = regexr(disease,"POISONING","") if regexm(object,"IODINE POISONING")

replace object = object+",LEAD POISONING" if regexm(disease,"LEAD") & regexm(disease,"COLIC") & object!=""
replace object = "LEAD POISONING" if regexm(disease,"LEAD") & regexm(disease,"COLIC")  & object==""
replace disease = regexr(disease,"LEAD","") if regexm(object,"LEAD POISONING")
replace disease = regexr(disease,"COLIC","") if regexm(object,"LEAD POISONING")

replace object = object+",LEAD POISONING" if regexm(disease,"LEAD") & regexm(disease,"POISONING") & object!=""
replace object = "LEAD POISONING" if regexm(disease,"LEAD") & regexm(disease,"POISONING")  & object==""
replace disease = regexr(disease,"LEAD","") if regexm(object,"LEAD POISONING")
replace disease = regexr(disease,"POISONING","") if regexm(object,"LEAD POISONING")

replace object = object+",MOTOR BUS" if regexm(disease,"MOTOR BUS") & object!=""
replace object = "MOTOR BUS" if regexm(disease,"MOTOR BUS") & object==""
replace disease = regexr(disease,"MOTOR BUS","") if regexm(object,"MOTOR BUS")

replace object = object+",NITRIC ACID" if regexm(disease,"NITRIC") & regexm(disease,"ACID") & object!=""
replace object = "NITRIC ACID" if regexm(disease,"NITRIC") & regexm(disease,"ACID")  & object==""
replace disease = regexr(disease,"NITRIC","") if regexm(object,"NITRIC ACID")
replace disease = regexr(disease,"ACID","") if regexm(object,"NITRIC ACID")

replace object = object+",LAUDANUM POISONING" if regexm(disease,"LAUDANUM") & regexm(disease,"POISONING") & object!=""
replace object = "LAUDANUM POISONING" if regexm(disease,"LAUDANUM") & regexm(disease,"POISONING")  & object==""
replace disease = regexr(disease,"LAUDANUM","") if regexm(object,"LAUDANUM POISONING")
replace disease = regexr(disease,"POISONING","") if regexm(object,"LAUDANUM POISONING")

replace object = object+",OPIUM POISONING" if regexm(disease,"OPIUM") & regexm(disease,"POISONING") & object!=""
replace object = "OPIUM POISONING" if regexm(disease,"OPIUM") & regexm(disease,"POISONING")  & object==""
replace disease = regexr(disease,"OPIUM","") if regexm(object,"OPIUM POISONING")
replace disease = regexr(disease,"POISONING","") if regexm(object,"OPIUM POISONING")

replace object = object+",OXALIC ACID POISONING" if regexm(disease,"OXALIC") & regexm(disease,"POISONING") & object!=""
replace object = "OXALIC ACID POISONING" if regexm(disease,"OXALIC") & regexm(disease,"POISONING")  & object==""
replace disease = regexr(disease,"OXALIC","") if regexm(object,"OXALIC ACID POISONING")
replace disease = regexr(disease,"POISONING","") if regexm(object,"OXALIC ACID POISONING")
replace disease = regexr(disease,"ACID","") if regexm(object,"OXALIC ACID POISONING")

replace object = object+",PARAFFIN POISONING" if regexm(disease,"PARAFFIN") & regexm(disease,"POISONING") & object!=""
replace object = "PARAFFIN POISONING" if regexm(disease,"PARAFFIN") & regexm(disease,"POISONING")  & object==""
replace disease = regexr(disease,"PARAFFIN","") if regexm(object,"PARAFFIN POISONING")
replace disease = regexr(disease,"POISONING","") if regexm(object,"PARAFFIN POISONING")

replace object = object+",PHOSPHORUS POISONING" if regexm(disease,"PHOSPHORUS") & regexm(disease,"POISONING") & object!=""
replace object = "PHOSPHORUS POISONING" if regexm(disease,"PHOSPHORUS") & regexm(disease,"POISONING")  & object==""
replace disease = regexr(disease,"PHOSPHORUS","") if regexm(object,"PHOSPHORUS POISONING")
replace disease = regexr(disease,"POISONING","") if regexm(object,"PHOSPHORUS POISONING")

replace object = object+",PTOMAINE POISONING" if regexm(disease,"PTOMAIN(E)*") & regexm(disease,"POISONING") & object!=""
replace object = "PTOMAINE POISONING" if regexm(disease,"PTOMAIN(E)*") & regexm(disease,"POISONING")  & object==""
replace disease = regexr(disease,"PTOMAIN(E)*","") if regexm(object,"PTOMAINE POISONING")
replace disease = regexr(disease,"POISONING","") if regexm(object,"PTOMAINE POISONING")

replace object = object+",SLATE PENCIL" if regexm(disease,"SLATE") & regexm(disease,"PENCIL") & object!=""
replace object = "SLATE PENCIL" if regexm(disease,"SLATE") & regexm(disease,"PENCIL")  & object==""
replace disease = regexr(disease,"SLATE","") if regexm(object,"SLATE PENCIL")
replace disease = regexr(disease,"PENCIL","") if regexm(object,"SLATE PENCIL")

replace object = object+",SOLDERING FLUID" if regexm(disease,"SOLDERING") & object!=""
replace object = "SOLDERING FLUID" if regexm(disease,"SOLDERING") & object==""
replace disease = regexr(disease,"SOLDERING","") if regexm(object,"SOLDERING FLUID")
replace sympt = regexr(disease,"FLUID","") if regexm(object,"SOLDERING FLUID")

replace object = object+",SULPHURIC ACID" if regexm(disease,"SULPHURIC") & regexm(disease,"ACID") & object!=""
replace object = "SULPHURIC ACID" if regexm(disease,"SULPHURIC") & regexm(disease,"ACID")  & object==""
replace disease = regexr(disease,"SULPHURIC","") if regexm(object,"SULPHURIC ACID")
replace disease = regexr(disease,"ACID","") if regexm(object,"SULPHURIC ACID")

replace object = object+",VITRIOL POISONING" if regexm(disease,"VITRIOL") & regexm(disease,"POISONING") & object!=""
replace object = "VITRIOL POISONING" if regexm(disease,"VITRIOL") & regexm(disease,"POISONING")  & object==""
replace disease = regexr(disease,"VITRIOL","") if regexm(object,"VITRIOL POISONING")
replace disease = regexr(disease,"POISONING","") if regexm(object,"VITRIOL POISONING")

#delimit ;
local object "
ACID AMMONIA ATROPINE BEAD BED BELLADONNA BOOT BRAWL BULL BUTTON CAB CAMPHOR CANAL CARBOLIC CHERRY COIN COMMERCIAL COPAIBA COPPER DIHYDROPTERORIC DOG DOLL DONKEY EXPLOSION FISHBONE FLORIN FLOOR FUMES GLASS GUNPOWDER GUN 
HALFPENNY HALF HALL HERB HORSE HOUND IRON JUG LADDER LIFT LIME MACHINE MUSSEL NEEDLE PELLETS PENCIL PENNY PISTOL PLUMBISM POISONING POTASH PORK PORTER RAILWAY REVOLVER RUSTY SALT SHELL SMOKE SPIKE SPIRITS SPOON STEEL STONE SULPHATE TOP TUBE WATER WINDOW WIRE";
#delimit cr;
foreach type of local object {
	replace object = object + ",`type'" if regexm(disease,"`type'") & object!=""
	replace object = "`type'" if regexm(disease,"`type'") & object==""
	replace disease = regexr(disease,"`type'","")
}

* Extract location words
gen loc = ""
local location "ABOVE ANTERIOR AROUND BEHIND BELOW BENEATH CENTRAL EXTERNAL FRONT GREAT INNER INTERNAL LEFT LOWER-END LOWER MIDDLE NEAR NEIGHBOURHOOD OUTER OVER POSTERIOR REGION RESIDUAL RETRO RIGHT SECTION SPACE SUPRA UNDER UPPER-END UPPER"
foreach type of local location {
	replace loc = loc+",`type'" if regexm(disease,"`type'") & loc!=""
	replace loc = "`type'" if regexm(disease,"`type'") & loc==""
	replace disease = regexr(disease,"`type'","")
}

replace disease = trim(disease)
replace loc = loc+",SUB" if disease == "SUB" & loc!=""
replace loc = "SUB" if disease == "SUB" & loc==""
replace disease = "" if disease == "SUB"

* Extract severity component
gen sev = ""
#delimit ;
local sev "
ABNORMAL SUBACUTE ACUTE ADVANCED AMBULATORY ATTACK BAD BIG BOTH BROWN CASE CAVERNOUS CHRONIC COMPLAINT COMPLETE CONGENITAL CONTINUED CONVALESCENT DEAD DEEP DEFICIENT DEGENERATIVE DOUBLE DOUBTFUL EARLY EPIDEMIC EXCESSIVE EXCESS
EXTREME FAILING FETID FREQUENT GENERAL GRAZE HABIT HEREDITARY HIGH HISTORY HYPER IMPERATIVE IMPERFECT INABILITY INCIPIENT INHERITED INTERMITTENT IRREGULAR IRREDUCIBLE LARGE LATE LOCAL MALIGNANT MIXED MODERATE MULTIPLE 
NATURE NEW NOCTURNAL OBSTINATE OLD PARTIAL PERSISTENT POST PROGRESSIVE PSEUDO QUOTIDIAN READMITTED RECENT RECURRENT REMAINS RELAPSE SECONDARY SECOND SEMILUNAR SEVERE SEVERAL SHORTNESS SIMPLE SLIGHT SMALL SPECIFIC SPONTANEOUS SPORADIC SUDDEN 
SUPERFICIAL SUSPICION TRAUMATIC TROUBLE TWO UNHEALED UNILATERAL UNREDUCIBLE UNRESOLVED UNTREATED VERY VIOLENT WEAK";
#delimit cr;
foreach type of local sev {
	replace sev = sev+",`type'" if regexm(disease,"`type'") & sev!=""
	replace sev = "`type'" if regexm(disease,"`type'") & sev==""
	replace disease = regexr(disease,"`type'","")
}

* Conflict entries
replace disease = trim(disease)
local short_words "BOIL COLIC MUTE POTTS CORN"
foreach term of local short_words {
	replace object = object+",`term'" if disease == "`term'" & object!=""
	replace object = "`term'" if disease == "`term'" & object==""
	replace disease = "" if disease == "`term'"
}

local short_words "ACHE ACNE CUT LONG SCAR STATE TIC ONYA WEN"
foreach term of local short_words {
	replace sympt = sympt+",`term'" if disease == "`term'" & sympt!=""
	replace sympt = "`term'" if disease == "`term'" & sympt==""
	replace disease = "" if disease == "`term'"
}

local short_words "ANAL BODY BONE CHIN DUCT EAR WALL GENITAL SAC"
foreach term of local short_words {
	replace bodypt = bodypt+",`term'" if disease == "`term'" & bodypt!=""
	replace bodypt = "`term'" if disease == "`term'" & bodypt==""
	replace disease = "" if disease == "`term'"
}

local short_words "PEN PIN PLUM RAT VAN NUT"
foreach term of local short_words {
	replace object = object+",`term'" if disease == "`term'" & object!=""
	replace object = "`term'" if disease == "`term'" & object==""
	replace disease = "" if disease == "`term'"
}

replace disease = trim(disease)

replace bodypt = bodypt+",BLADDER" if regexm(disease,"VESICA") & bodypt!=""
replace bodypt = "BLADDER" if regexm(main,"VESICA") & bodypt==""

replace bodypt = bodypt+",EYELID" if (disease == "LID" | disease == "LIDS") & bodypt!=""
replace bodypt = "EYELID" if (disease == "LID" | disease == "LIDS") & bodypt==""
replace disease = "" if (disease == "LID" | disease == "LIDS")

replace disease = subinstr(disease,"    "," ",.)
replace disease = subinstr(disease,"   "," ",.)
replace disease = subinstr(disease,"  "," ",.)
replace disease = trim(disease)

replace external = regexr(external,"FRACTURE,FRACTURE$","FRACTURE")
replace main = regexr(main,"FEVER,FEVER$","FEVER")
replace main = regexr(main,"FEVER,FEVER,","FEVER,")
replace disease = regexr(disease,"DISEASE","") if regexm(sympt,"DISEASE")
replace disease = regexr(disease,"FRACTURE","") if regexm(external,"FRACTURE")
replace disease = regexr(disease,"FEVER","") if regexm(main,"FEVER")
replace disease = regexr(disease,"BOTH","") if regexm(sev,"BOTH")
replace disease = regexr(disease,"BONE","") if regexm(bodypt,"BONE")
replace disease = regexr(disease,"EAR","") if regexm(bodypt,"EAR")
replace disease = regexr(disease,"TOE","") if regexm(bodypt,"TOE")

#delimit ;
replace disease = "" if 
	disease == "ALL" | disease == "FELT" | disease == "IN" | disease == "NIL" | disease == "OD" | disease == "OF" | disease == "ON" | disease == "OR" | disease == "OTHER" | disease == "RD";
#delimit cr
replace disease = trim(disease)
replace disease = "" if length(disease) == 1

duplicates drop
sort disease
order dis_orig disease main sympt bodypt 
compress dis_orig disease sev loc main surgery sympt bodypt external
replace dis_orig = upper(dis_orig)

* Standardize terminology

gen alt = ""
replace alt = alt+","+"CHICKEN POX" if regexm(main,"VARICELLA")
replace alt = alt+","+"CLUB FOOT" if regexm(main,"TALIPES") | regexm(main,"EQUINOVARUS")
replace alt = alt+","+"BLADDER STONE" if regexm(main,"CALCULUS VESICA")
replace alt = alt+","+"EAR INFECTION" if regexm(main,"OTITIS MEDIA")
replace alt = alt+","+"ENLARGED SPLEEN" if regexm(main,"SPLENOMEGALY")
replace alt = alt+","+"FEVER" if regexm(main,"PYREXIA")
replace alt = alt+","+"GENU VARUM" if regexm(main,"BOW-LEGGED")
replace alt = alt+","+"GOITER" if regexm(main,"STRUMA")
replace alt = alt+","+"HEMMORHAGE" if regexm(main,"PILES")
replace alt = alt+","+"INGUINAL HERNIA" if regexm(main,"BUBONOCELE")
replace alt = alt+","+"JAUNDICE" if regexm(main,"ICTERUS")
replace alt = alt+","+"KIDNEY STONES" if regexm(main,"NEPHROLITHIASIS")
replace alt = alt+","+"MENIERE'S DISEASE" if regexm(main,"LABYRINTHINE VERTIGO")
replace alt = alt+","+"MEASLES" if regexm(main,"MORBILLI")
replace alt = alt+","+"PERITONSILLAR ABSCESS" if regexm(main,"QUINCY")
replace alt = alt+","+"POLIOMYELITIS" if regexm(main,"INFANTILE PARALYSIS")
replace alt = alt+","+"PULMONARY TUBERCULOSIS" if regexm(main,"TABES")
replace alt = alt+","+"RICKETS" if regexm(main,"RACHITIS")
replace alt = alt+","+"SHINGLES" if regexm(main,"HERPES ZOSTER")
replace alt = alt+","+"SMALLPOX" if regexm(main,"VACCINIA")
replace alt = alt+","+"SYPHILIS" if regexm(main,"GUMMA")
replace alt = alt+","+"TINIA CAPITITIS" if regexm(main,"TINIA TONSURANS") | regexm(main,"RINGWORM")
replace alt = alt+","+"TORTICOLLIS" if regexm(main,"WRY NECK")
replace alt = alt+","+"TUBERCULAR LUPOSA" if regexm(main,"LUPUS VULGARIS")
replace alt = alt+","+"TYPHOID FEVER" if regexm(main,"ENTERIC")
replace alt = alt+","+"SULFURIC ACID POISONING" if object == "VITRIOL POISONING"
replace alt = alt+","+"UVEITIS" if main == "IRITIS"
replace alt = alt+","+"VERMIFORM APPENDIX" if regexm(main,"VERMIFORMIS")
replace alt = alt+","+"VOLKMANN'S CONTRACTURE" if regexm(main,"ISCHEMIC CONTRACTURE")
replace alt = alt+","+"WARTS" if regexm(main,"VERRUCA")
replace alt = regexr(alt,"^(,)*","")

sort dis_orig
order dis_orig
unique dis_orig

save "$PROJ_PATH/processed/temp/hosp_disease_cleaned_temp.dta", replace

local disease_vars "main sympt bodypt surgery external object loc sev alt"
foreach distype of local disease_vars {
	use "$PROJ_PATH/processed/temp/hosp_disease_cleaned_temp.dta", clear
	keep dis_orig `distype'
	duplicates drop
	drop if `distype' == ""
	gen temp_id = _n
	split `distype', parse(,) gen(temp_`distype')
	drop `distype'
	reshape long temp_`distype', i(temp_id) j(new_id)
	drop if temp_`distype' == ""
	sort dis_orig temp_`distype'
	keep dis_orig temp_`distype'
	duplicates drop
	egen temp_id = group(dis_orig)
	egen obs_id = seq(), by(dis_orig)
	reshape wide temp_`distype', i(temp_id) j(obs_id)
	egen `distype' = concat(temp_`distype'*), punct(,)
	drop temp_*
	replace `distype' = regexr(`distype',"(,)*$","")
	compress `distype'
	save "$PROJ_PATH/processed/temp/disease_`distype'.dta", replace
}

use "$PROJ_PATH/processed/temp/hosp_disease_cleaned_temp.dta", clear
keep dis_orig disease_cleaned
duplicates drop
drop if disease_cleaned == ""
gen temp_id = _n
split disease_cleaned, parse(,) gen(temp_dc)
drop disease_cleaned
reshape long temp_dc, i(temp_id) j(new_id)
drop if temp_dc == ""
sort dis_orig temp_dc
keep dis_orig temp_dc
duplicates drop
egen temp_id = group(dis_orig)
egen obs_id = seq(), by(dis_orig)
reshape wide temp_dc, i(temp_id) j(obs_id)
egen disease_cleaned = concat(temp_dc*), punct(;)
drop temp_*
replace disease_cleaned = regexr(disease_cleaned,"(;)*$","")
compress disease_cleaned
sort dis_orig
unique dis_orig
save "$PROJ_PATH/processed/temp/disease_dc.dta", replace

use "$PROJ_PATH/processed/temp/hosp_disease_cleaned_temp.dta", clear
keep dis_orig disease
duplicates drop
drop if disease == ""
gen temp_id = _n
split disease, parse(,) gen(temp_dc)
drop disease
reshape long temp_dc, i(temp_id) j(new_id)
drop if temp_dc == ""
sort dis_orig temp_dc
keep dis_orig temp_dc
duplicates drop
egen temp_id = group(dis_orig)
egen obs_id = seq(), by(dis_orig)
reshape wide temp_dc, i(temp_id) j(obs_id)
egen disease = concat(temp_dc*), punct(;)
drop temp_*
replace disease = regexr(disease,"(;)*$","")
compress disease
sort dis_orig
unique dis_orig
save "$PROJ_PATH/processed/temp/disease_uncleaned.dta", replace

use "$PROJ_PATH/processed/temp/hosp_disease_cleaned_temp.dta", clear
keep dis_orig dis_count
duplicates drop
unique dis_orig
merge 1:1 dis_orig using "$PROJ_PATH/processed/temp/disease_uncleaned.dta", assert(1 3) keep(1 3) nogen
merge 1:1 dis_orig using "$PROJ_PATH/processed/temp/disease_dc.dta", assert(1 3) keep(1 3) nogen
foreach distype of local disease_vars {
	merge 1:1 dis_orig using "$PROJ_PATH/processed/temp/disease_`distype'.dta", assert(1 3) keep(1 3) nogen
}

foreach distype of local disease_vars {
	rm "$PROJ_PATH/processed/temp/disease_`distype'.dta"
}
rm "$PROJ_PATH/processed/temp/disease_dc.dta"
rm "$PROJ_PATH/processed/temp/hosp_disease_cleaned_temp.dta"

count
local obs = r(N)
local newobs = `obs' + 1
set obs `newobs'
replace dis_count = 1 in `newobs'
sort dis_orig

save "$PROJ_PATH/processed/intermediate/diseases/hosp_disease_cleaned.dta", replace

/***** Disease_coding_input
Inputs CSV files that contain manually coded information about each disease. 
	This information is used to create variables related to the causes of admission that will be used in regressions */

insheet using "$PROJ_PATH/raw/diseases/main_categories.csv", clear names
drop if main == ""
tempfile mainvars
save `mainvars', replace

insheet using "$PROJ_PATH/raw/diseases/bodypt_categories.csv", clear names
drop if bodypt == ""
tempfile bodyptvars
save `bodyptvars', replace

insheet using "$PROJ_PATH/raw/diseases/sympt_categories.csv", clear names
drop if sympt == ""
tempfile symptvars
save `symptvars', replace

		
insheet using "$PROJ_PATH/raw/diseases/sympt_categories.csv", clear names
keep if sympt == "INTESTINAL OBSTRUCTION" | sympt == "NEUROTIC GAIT" | sympt == "PLEURAL EFFUSION" | sympt == "REDUNDANT PREPUCE" | sympt == "SPASTIC GAIT" | sympt == "STRIDULOUS BREATHING" | sympt == "VICIOUS UNION"
replace complication = "Y" if sympt == "INTESTINAL OBSTRUCTION" | sympt == "PLEURAL EFFUSION"
rename sympt main
tempfile sympt_to_main
save `sympt_to_main', replace

insheet using "$PROJ_PATH/raw/diseases/sympt_categories.csv", clear names
* drop if sympt == ""
drop if sympt == "INTESTINAL OBSTRUCTION" | sympt == "NEUROTIC GAIT" | sympt == "PLEURAL EFFUSION" | sympt == "REDUNDANT PREPUCE" | sympt == "SPASTIC GAIT" | sympt == "STRIDULOUS BREATHING" | sympt == "VICIOUS UNION"
replace chronic = "N" if congenital == "Y"
tempfile disease_sympt
save `disease_sympt', replace

insheet using "$PROJ_PATH/raw/diseases/main_categories.csv", clear names
count
local obs = r(N)
local newobs = `obs' + 1
set obs `newobs'
replace main = "SUPERNUMERACY" in `newobs'
drop if main == "INTESTINAL OBSTRUCTION" | main == "NEUROTIC GAIT" | main == "PLEURAL EFFUSION" | main == "REDUNDANT PREPUCE" | main == "SPASTIC GAIT" | main == "STRIDULOUS BREATHING" | main == "VICIOUS UNION"
append using `sympt_to_main'
duplicates drop
replace category = "" if category == "Neurological" | category == "Heart" | category == "Violence"
replace chronic = "N" if main == "BRONCHOPNEUMONIA" | main == "LOBAR PNEUMONIA" | main == "PNEUMONIA" | main == "PLEUROPNEUMONIA"
replace acute = "Y" if main == "BRONCHOPNEUMONIA" | main == "LOBAR PNEUMONIA" | main == "PNEUMONIA" | main == "PLEUROPNEUMONIA"
replace infectious = "Y" if main == "BRONCHOPNEUMONIA" | main == "LOBAR PNEUMONIA" | main == "PNEUMONIA" | main == "PLEUROPNEUMONIA"
replace infection = "N" if main == "BRONCHOPNEUMONIA" | main == "LOBAR PNEUMONIA" | main == "PNEUMONIA" | main == "PLEUROPNEUMONIA"
replace infectious = "Y" if main == "EMPYEMA" | main == "DIPHTHERIA PARALYSIS"

replace chronic = "N" if congenital == "Y"
replace symptom = "Y" if category == "Symptom"
replace category = "" if category == "Symptom" | category == "Congenital"
replace category = "" if main == "FEVER" | main == "PYREXIA"
replace system = "Urinary" if regexm(main,"LARDACEOUS")
replace system = "" if regexm(main,"WHOOPING COUGH") | main == "PHTHISIS" | main == "TINEA" | main == "MORBUS CORPORIS" | main == "PERTUSSIS" | main == "CIRCUMCISION"
replace category = "" if regexm(main,"LARDACEOUS") | main == "SYNOVITIS" | main == "SLOUGH" | main == "WARTS" | main == "CIRRHOSIS" | main == "CARIES"
replace category = "" if main == "HEMORRHAGE"
tempfile disease_main
save `disease_main', replace

insheet using "$PROJ_PATH/raw/diseases/bodypt_categories.csv", clear names
replace category = "Surgical" if category == "Surgery"
replace category = "Surgical" if regexm(bodypt,"STUMP")
replace system = "Reproductive" if bodypt == "SCROTUM"
tempfile disease_bodypt
save `disease_bodypt', replace

use "$PROJ_PATH/processed/intermediate/diseases/hosp_disease_cleaned.dta", clear
drop if dis_orig == ""

replace disease_cleaned = regexr(disease_cleaned,"CERVIX","CERVICAL") if regexm(dis_orig,"CERVIX") == 0 & regexm(dis_orig,"CERVICAL") == 1
order dis_orig disease_cleaned main
keep dis_orig disease_cleaned main
duplicates drop
unique dis_orig
split main, parse(,) gen(main)
drop main
gen temp_id = _n
reshape long main, i(temp_id) j(new_id)
egen temp = total(main != ""), by(temp_id)
drop if main == "" & temp > 0 
drop temp* new_id
duplicates drop
keep dis_orig disease_cleaned main
duplicates drop
sort dis_orig main
unique main

merge m:1 main using `disease_main', keep(1 3)
gen unassigned = (main != "" & system == "" & category == "" & anatomy == "" & acute == "" & infectious == "")
recode unassigned (mis = 0)
egen temp = max(unassigned), by(dis_orig)
replace unassigned = temp
drop temp
drop main
duplicates drop
gen type = "Main"
tempfile main_categories
save `main_categories', replace

use "$PROJ_PATH/processed/intermediate/diseases/hosp_disease_cleaned.dta", clear
drop if dis_orig == ""

replace disease_cleaned = regexr(disease_cleaned,"CERVIX","CERVICAL") if regexm(dis_orig,"CERVIX") == 0 & regexm(dis_orig,"CERVICAL") == 1
order dis_orig disease_cleaned sympt
keep dis_orig disease_cleaned sympt
duplicates drop
unique dis_orig
split sympt, parse(,) gen(sympt)
drop sympt
gen temp_id = _n
reshape long sympt, i(temp_id) j(new_id)
egen temp = total(sympt != ""), by(temp_id)
drop if sympt == "" & temp > 0 
drop temp* new_id
duplicates drop
keep dis_orig disease_cleaned sympt
duplicates drop
sort dis_orig sympt
unique sympt

merge m:1 sympt using `disease_sympt', keep(1 3)
gen unassigned = (sympt != "" & system == "" & category == "" & anatomy == "" & acute == "" & infectious == "")
recode unassigned (mis = 0)
egen temp = max(unassigned), by(dis_orig)
replace unassigned = temp
drop temp
drop sympt
duplicates drop
gen type = "Sympt"
tempfile sympt_categories
save `sympt_categories', replace

use "$PROJ_PATH/processed/intermediate/diseases/hosp_disease_cleaned.dta", clear
drop if dis_orig == ""

replace disease_cleaned = regexr(disease_cleaned,"CERVIX","CERVICAL") if regexm(dis_orig,"CERVIX") == 0 & regexm(dis_orig,"CERVICAL") == 1
order dis_orig disease_cleaned bodypt
keep dis_orig disease_cleaned bodypt
replace bodypt = regexr(bodypt,"CERVIX","CERVICAL") if regexm(dis_orig,"CERVIX") == 0 & regexm(dis_orig,"CERVICAL") == 1
duplicates drop
unique dis_orig
split bodypt, parse(,) gen(bodypt)
drop bodypt
gen temp_id = _n
reshape long bodypt, i(temp_id) j(new_id)
egen temp = total(bodypt != ""), by(temp_id)
drop if bodypt == "" & temp > 0 
drop temp* new_id
duplicates drop
keep dis_orig disease_cleaned bodypt
duplicates drop
sort dis_orig bodypt
unique bodypt

merge m:1 bodypt using `disease_bodypt', keep(1 3)
drop bodypt
duplicates drop
gen type = "Bodypt"
tempfile bodypt_categories
save `bodypt_categories', replace

clear
append using `main_categories'
append using `sympt_categories'
append using `bodypt_categories'
drop _merge

recode unassigned (mis = 0)
egen temp = max(unassigned), by(dis_orig)
replace unassigned = temp
drop temp

* Manual changes
replace system = "Venereal" if system == "Skin" & regexm(disease_cleaned,"WART") & (regexm(disease_cleaned,"GONORRHEA") | regexm(disease_cleaned,"GENITAL"))
replace contagious = "Y" if system != "" & regexm(disease_cleaned,"WART") & (regexm(disease_cleaned,"GONORRHEA") | regexm(disease_cleaned,"GENITAL"))
replace infectious = "Y" if system != "" & regexm(disease_cleaned,"WART") & (regexm(disease_cleaned,"GONORRHEA") | regexm(disease_cleaned,"GENITAL"))

replace system = "Skeletal" if category == "TB" & regexm(disease_cleaned,"CURVATURE") & regexm(disease_cleaned,"ANGULAR")==0 & regexm(disease_cleaned,"SPIN")==0 & regexm(disease_cleaned,"POTT")==0 & regexm(disease_cleaned,"LATERAL")==0
replace complication = "N" if category == "TB" & regexm(disease_cleaned,"CURVATURE") & regexm(disease_cleaned,"ANGULAR")==0 & regexm(disease_cleaned,"SPIN")==0 & regexm(disease_cleaned,"POTT")==0 & regexm(disease_cleaned,"LATERAL")==0
replace category = "" if category == "TB" & regexm(disease_cleaned,"CURVATURE") & regexm(disease_cleaned,"ANGULAR")==0 & regexm(disease_cleaned,"SPIN")==0 & regexm(disease_cleaned,"POTT")==0 & regexm(disease_cleaned,"LATERAL")==0

duplicates drop
sort dis_orig
drop if dis_orig == ""
egen dis_id = group(dis_orig)

save "$PROJ_PATH/processed/temp/disease_categories_inprog.dta", replace

gen i_surg = (category == "Surgical")
gen i_inj = (category == "Injury" | category == "Violence")
gen neuro = (category == "Neurological")
gen heart = (anatomy == "Heart")
replace category = "" if category == "Surgical" | category == "Injury" | category == "Neurological" | category == "Heart" | category == "Violence"
drop system category anatomy type
duplicates drop
duplicates drop

foreach var of varlist acute chronic congenital contagious infectious infection inflammation complication symptom {
	replace `var' = "1" if `var' == "Y"
	replace `var' = "2" if `var' == "Y/N"
	replace `var' = "0" if `var' == "N"
	destring `var', replace
	recode `var' (2 = 0.5)
}
foreach var of varlist acute chronic congenital contagious infectious infection inflammation complication symptom neuro heart i_* {
	egen max_`var' = max(`var'), by(dis_id)
	replace `var' = max_`var'
	drop max_`var'
	duplicates drop
}
sort dis_id
unique dis_orig

tempfile indicators
save `indicators'

use "$PROJ_PATH/processed/intermediate/diseases/hosp_disease_cleaned.dta", clear
drop if dis_orig == ""

replace disease_cleaned = regexr(disease_cleaned,"CERVIX","CERVICAL") if regexm(dis_orig,"CERVIX") == 0 & regexm(dis_orig,"CERVICAL") == 1
keep dis_orig disease_cleaned sev
duplicates drop 

gen sev_acute = ((regexm(sev,"ACUTE") & regexm(sev,"SUBACUTE")==0) | sev == "BAD" | sev == "ADVANCED" | sev == "EXCESSIVE" | sev == "EXTREME" | sev == "SEVERE" | sev == "SUDDEN" | sev == "TRAUMATIC" | sev == "VIOLENT")
gen sev_chronic = (regexm(sev,"SECOND") | regexm(sev,"CHRONIC") | regexm(sev,"CONTINUED") | regexm(sev,"CONVALESCENT") | sev == "FREQUENT" | sev == "HISTORY" | sev == "MULTIPLE" | regexm(sev,"OBSTINATE") | regexm(sev,"OLD") | sev == "RECENT" | sev == "READMITTED" | sev == "RELAPSE" | sev == "UNHEALED" | sev == "UNRESOLVED")
gen sev_congenital = (regexm(sev,"CONGENITAL") | sev == "HEREDITARY" )
replace sev_chronic = 0 if sev_congenital == 1
drop sev
duplicates drop
unique dis_orig
tempfile sev
save `sev', replace

use "$PROJ_PATH/processed/intermediate/diseases/hosp_disease_cleaned.dta", clear
drop if dis_orig == ""

keep dis_orig disease_cleaned surgery external object
replace disease_cleaned = regexr(disease_cleaned,"CERVIX","CERVICAL") if regexm(dis_orig,"CERVIX") == 0 & regexm(dis_orig,"CERVICAL") == 1

gen ext_surgery = (surgery != "")
gen ext_injury = (external != "" & external != "WORMS" & surgery == "")
gen ext_foreign = (object != "" & external == "" & surgery == "")
gen ext_parasitic = (external == "WORMS")
keep dis_orig disease_cleaned ext_*
duplicates drop
egen temp = max(ext_foreign), by(dis_orig)
drop if ext_foreign != temp
drop temp
unique dis_orig
tempfile external
save `external', replace

use "$PROJ_PATH/processed/intermediate/diseases/hosp_disease_cleaned.dta", clear
drop if dis_orig == ""

replace disease_cleaned = regexr(disease_cleaned,"CERVIX","CERVICAL") if regexm(dis_orig,"CERVIX") == 0 & regexm(dis_orig,"CERVICAL") == 1
keep dis_orig sympt
gen gen_disease = regexm(sympt,"DISEASE")
drop sympt
egen temp = max(gen_disease), by(dis_orig)
drop if temp != gen_disease
drop temp
duplicates drop
unique dis_orig
tempfile general_diseases
save `general_diseases', replace

use "$PROJ_PATH/processed/intermediate/diseases/hosp_disease_cleaned.dta", clear
drop if dis_orig == ""

keep dis_orig disease_cleaned
replace disease_cleaned = regexr(disease_cleaned,"CERVIX","CERVICAL") if regexm(dis_orig,"CERVIX") == 0 & regexm(dis_orig,"CERVICAL") == 1
duplicates drop
unique dis_orig
merge 1:1 dis_orig using `external', assert(3) keep(3) nogen
merge 1:1 dis_orig using `sev', assert(3) keep(3) nogen
merge 1:1 dis_orig using `indicators', assert(1 3) keep(1 3) nogen

replace congenital = 1 if sev_congenital == 1
replace chronic = 1 if sev_chronic == 1 & congenital == 0
replace acute = 1 if sev_acute == 1
drop sev_*

gen injury = (ext_injury == 1 | i_inj == 1 | ext_surgery == 1 | i_surg == 1)
replace chronic = 0 if injury == 1
replace congenital = 0 if injury == 1
replace infectious = 0 if injury == 1
replace contagious = 0 if injury == 1
drop ext_surgery i_surg ext_injury i_inj

tempfile vars_combined
save `vars_combined', replace

use "$PROJ_PATH/processed/temp/disease_categories_inprog.dta", clear
keep dis_orig disease_cleaned dis_id system category anatomy type
replace category = "" if category == "Surgical" | category == "Injury" | category == "Neurological" | category == "Heart" | category == "Violence"

replace system = upper(system)
replace category = upper(category)
replace anatomy = upper(anatomy)

replace system = "SKELETAL, MUSCULAR" if system == "JOINTS" | system == "MUSCULAR" | system == "MUSCLES" | system == "SKELETAL" | system == "MUSCULAR/SKELETAL"
replace system = "URINARY, EXCRETORY" if system == "URINARY" | system == "EXCRETORY" | system == "URINARY/EXCRETORY"

gen temp = (system != "" & system != "SKELETAL, MUSCULAR")
egen temp2 = total(temp), by(dis_id)
replace system = "" if temp2 > 0 & temp == 0
drop temp* dis_id disease_cleaned
tempfile systems
save `systems', replace

use "$PROJ_PATH/processed/intermediate/diseases/hosp_disease_cleaned.dta", clear
drop if dis_orig == ""

keep dis_orig disease_cleaned
replace disease_cleaned = regexr(disease_cleaned,"CERVIX","CERVICAL") if regexm(dis_orig,"CERVIX") == 0 & regexm(dis_orig,"CERVICAL") == 1
duplicates drop
merge 1:m dis_orig using `systems', assert(1 3) keep(1 3) nogen
merge m:1 dis_orig using `vars_combined', assert(1 3) keep(1 3) nogen
drop dis_id
egen dis_id = group(dis_orig)

replace category = "" if category == "NEUROLOGICAL"
replace anatomy = "" if anatomy == "NOSE/EYE"
replace anatomy = "EAR, NOSE, THROAT" if regexm(anatomy,"EAR") | regexm(anatomy,"NOSE") | regexm(anatomy,"THROAT")
replace anatomy = "" if anatomy != "EYE" & anatomy != "MOUTH" & anatomy != "EAR, NOSE, THROAT" & (category != "" | system != "")
tab anatomy
replace anatomy = "" if anatomy != "EYE" & anatomy != "MOUTH" & anatomy != "EAR, NOSE, THROAT"

tab system
tab category
tab anatomy

replace system = "" if (regexm(disease_cleaned,"^ABSCESS") | regexm(disease_cleaned,"^[A-Z]+[ ]ABSCESS$")) & system != "IMMUNE" & category != "TB"
egen temp = total(system != "" & type != "Bodypt"), by(dis_orig)
replace system = "" if temp > 0 & type == "Bodypt"
drop temp*
egen temp = total(category != ""), by(dis_orig)
replace system = "" if (system == "SKELETAL, MUSCULAR" | system == "SKIN") & temp > 0
drop temp*
egen temp = total(anatomy != ""), by(dis_orig)
replace category = "" if category == "SOFT TISSUE" & temp > 0
drop temp*
egen temp1 = total(system != ""), by(dis_orig)
egen temp2 = total(category != ""), by(dis_orig)
replace anatomy = "" if temp1 > 0 | temp2 > 0
drop temp*

replace category = "INJURY" if injury == 1
replace category = "FOREIGN OBJECT" if ext_foreign == 1
replace category = "PARASITIC, FUNGAL" if ext_parasitic == 1 | category == "PARASITIC" | category == "FUNGAL"
replace category = "NUTRITION, DECAY" if category == "NUTRITION" | category == "DECAY"
replace category = "CIRCULATORY" if category == "LYMPHATIC"
replace category = "INFECTIOUS FEVER" if category == "FEVER"
replace system = "" if injury == 1 | ext_foreign == 1 | ext_parasitic == 1
replace anatomy = "" if injury == 1 | ext_foreign == 1 | ext_parasitic == 1
drop injury ext_foreign ext_parasitic

rename system cat1
rename category cat2
rename anatomy cat3

gen temp_id = _n
reshape long cat, i(temp_id) j(new_id)
drop temp_id new_id type
egen temp = total(cat != ""), by(dis_id)
drop if cat == "" & temp > 0
drop temp
duplicates drop

rename cat dis_group
sort dis_id dis_group
egen obs_id = seq(), by(dis_id)
sum obs_id
local max_obs = r(max)
reshape wide dis_group, i(dis_id) j(obs_id)

order dis_orig 
drop dis_id disease_cleaned
egen dis_group = concat(dis_group1-dis_group`max_obs'), punct(;)
drop dis_group1-dis_group`max_obs'
replace dis_group = regexr(dis_group,"(;)*$","")
tempfile categorical_vars
save `categorical_vars', replace

use "$PROJ_PATH/processed/intermediate/diseases/hosp_disease_cleaned.dta", clear
drop if dis_orig == ""

replace disease_cleaned = regexr(disease_cleaned,"CERVIX","CERVICAL") if regexm(dis_orig,"CERVIX") == 0 & regexm(dis_orig,"CERVICAL") == 1
order dis_orig disease_cleaned
keep dis_orig disease_cleaned dis_count
duplicates drop
egen temp_count = sum(dis_count), by(dis_orig)
drop dis_count
duplicates drop
rename temp_count dis_count 
unique dis_orig
merge 1:1 dis_orig using `categorical_vars', assert(1 3) keep(1 3) nogen

foreach var of varlist acute chronic congenital contagious infectious infection inflammation complication symptom neuro heart {
	recode `var' (mis = 0)
}

merge 1:1 dis_orig using `general_diseases', assert(3) nogen

sort dis_orig 
unique dis_orig

tab chronic 
replace chronic = 1 if gen_disease == 1 & congenital == 0 & dis_group != "INJURY"

replace dis_group = "UNCLASSIFIED DISEASES" if dis_group == "" & gen_disease == 1
replace dis_group = "INFECTIONS AND INFLAMMATION" if dis_group == "" & (inflammation > 0 | infection > 0)
replace dis_group = "AILMENTS" if (dis_group == "" & symptom > 0)
drop gen_disease

gen injury = regexm(dis_group,"INJURY")
gen muscskel = regexm(dis_group,"SKELETAL")
gen immune = regexm(dis_group,"IMMUNE")
gen resp = regexm(dis_group,"RESPIRATORY")
gen circul = regexm(dis_group,"CIRCULATORY")
gen digest = regexm(dis_group,"DIGESTIVE")
gen skin = regexm(dis_group,"SKIN")
gen tuberc = (regexm(dis_group,"TB") | regexm(dis_orig,"CONSUMPTION"))
gen nervous = regexm(dis_group,"NERVOUS")
gen nutrition = regexm(dis_group,"NUTRITION")
gen gen_dis = regexm(dis_group,"UNCLASSIFIED DISEASES")
gen inflam = regexm(dis_group,"INFLAMMATION")
gen ailment = regexm(dis_group,"AILMENT")
gen ent = regexm(dis_group,"THROAT")
gen urinary = regexm(dis_group,"URINARY")
gen eye = regexm(dis_group,"EYE")
gen fever = regexm(dis_group,"FEVER")
gen genitals = regexm(dis_group,"REPRODUCTIVE")
gen tissue = regexm(dis_group,"TISSUE")
gen foreign = regexm(dis_group,"FOREIGN")
gen mouth = regexm(dis_group,"MOUTH")
gen venereal = regexm(dis_group,"VENEREAL")
gen parasitic = regexm(dis_group,"PARASITIC")
gen unclass = (dis_group == "" & ailment == 0)

la var injury "Accidents and injuries"
la var muscskel "Muscular-skeletal systems"
la var immune "Autoimmune disorders"
la var resp "Respiratory system"
la var circul "Circulatory system"
la var digest "Digestive system"
la var skin "Diseases of the skin"
la var tuberc "Tubercular disease"
la var nervous "Nervous system"
la var nutrition "Nutrition and decay"
la var ailment "General ailments"
la var ent "Diseases of the ear, nose and throat"
la var urinary "Urinary and excretory system"
la var eye "Diseases of the eye"
la var fever "Infectious fevers"
la var genitals "Diseases of the reproductive organs"
la var tissue "Soft tissue"
la var foreign "Foreign objects"
la var mouth "Diseases of the mouth"
la var venereal "Veneral diseases"
la var parasitic "Parasitic and fungal infections"
la var unclass "Not classified"
la var gen_dis "Unclassified diseases"
la var inflam "Infections and inflammation"

la var acute "Acute condition"
la var chronic "Chronic condition"
la var congenital "Congenital condition"
la var inflammation "Inflammatory"
la var infection "Infection"
la var contagious "Contagious disease"
la var infectious "Infectious disease"

replace unassigned = 0 if injury == 1 | foreign == 1
tab unassigned

recode acute-symptom neuro heart injury-parasitic (mis = 0) if dis_orig == ""
recode acute-symptom neuro heart injury-parasitic (1 = 0) if dis_orig == ""
replace dis_group = "" if dis_orig == ""
replace unclass = 1 if dis_orig == ""

count
local obs = r(N)
local obsplus = `obs' + 1
set obs `obsplus'
recode acute-heart injury-unclass (mis = 0)
replace dis_count = 1 in `obsplus'
replace unclass = 1 in `obsplus'
replace unassigned = 1 in `obsplus'

replace acute = 0.5 if acute == 0 & (regexm(disease_cleaned,"NEPHRITIS") | regexm(disease_cleaned,"NEURITIS") | regexm(disease_cleaned,"HYPERPYREXIA") | regexm(disease_cleaned,"CONJUNCTIV") | ///
	regexm(disease_cleaned,"BLEEDING") | regexm(disease_cleaned,"MELANA") | regexm(disease_cleaned,"FEVER") | regexm(disease_cleaned,"KERATITIS"))
replace acute = 1 if regexm(disease_cleaned,"HEMOGLOBIN") | regexm(disease_cleaned,"DIPHTHERIA") | regexm(disease_cleaned,"HYDROPHOBIA") | regexm(disease_cleaned,"LICHEN")
replace unassigned = 0 if acute == 1

* Create disease specific variables

gen diphth = regexm(disease_cleaned,"DIPHTHERIA")
gen pneumonia = regexm(disease_cleaned,"PNEUMONIA")
gen chorea = regexm(disease_cleaned,"CHOREA")
gen empyema = regexm(disease_cleaned,"EMPYEMA")
gen phimosis = regexm(disease_cleaned,"PHIMOSIS")
gen bronchitis = regexm(disease_cleaned,"BRONCH")
gen dis_hip = (regexm(disease_cleaned,"HIP") & regexm(disease_cleaned,"DISEASE"))
gen dis_knee = (regexm(disease_cleaned,"KNEE") & regexm(disease_cleaned,"DISEASE")) 
gen diarrhea = regexm(disease_cleaned,"DIARRHEA")
gen rickets = regexm(disease_cleaned,"RICKETS")
gen cleft_palate = regexm(disease_cleaned,"CLEFT PALATE")
gen talipes = regexm(disease_cleaned,"TALIPES")
gen scarlet = regexm(disease_cleaned,"SCARLET")
gen erysip = regexm(disease_cleaned,"ERYSIPELAS")
gen fracture = regexm(disease_cleaned,"FRACTURE")
gen typhoid = regexm(disease_cleaned,"TYPHOID") | regexm(disease_cleaned,"ENTERIC")
gen tuberculosis = regexm(disease_cleaned,"TUBERCULOSIS") | regexm(disease_cleaned,"PHTHISIS") | regexm(disease_cleaned,"CONSUMPTION")
gen tub_dis = regexm(disease_cleaned,"TUBERCULAR") | regexm(disease_cleaned,"TUBERCLE") | regexm(disease_cleaned,"STRUMOUS")
gen rheumatism = regexm(disease_cleaned,"RHEUMAT")
gen necrosis = regexm(disease_cleaned,"NECROSIS")
gen harelip = regexm(disease_cleaned,"HARELIP")
gen pleurisy = regexm(disease_cleaned,"PLEURISY")
gen morbus_cordis = regexm(disease_cleaned,"MORBUS CORDIS")
gen eczema = regexm(disease_cleaned,"ECZEMA")
gen broncho_pneumonia = regexm(disease_cleaned,"BRONCH") & regexm(disease_cleaned,"PNEUMONIA")
gen meningitis = regexm(disease_cleaned,"MENINGITIS")
gen burn = regexm(disease_cleaned,"BURN")
gen laryingitis = regexm(disease_cleaned,"LARYNGITIS")
gen abscess = regexm(disease_cleaned,"ABSCESS")

gen policy_diseases = (diphth == 1 | pneumonia == 1 | diarrhea == 1 | tuberc == 1 | nutrition == 1 | erysip == 1 | regexm(disease_cleaned,"TYPHOID") | /// 
	regexm(disease_cleaned,"ENTERIC") | regexm(disease_cleaned,"MEASLES") | regexm(disease_cleaned,"WHOOPING COUGH") | ///
	regexm(disease_cleaned,"PERTUSSIS") | regexm(disease_cleaned,"MARASMUS") | regexm(disease_cleaned,"POLIO"))

sort dis_orig

save "$PROJ_PATH/processed/intermediate/diseases/hosp_disease_variables.dta", replace
rm "$PROJ_PATH/processed/temp/disease_categories_inprog.dta"
rm "$PROJ_PATH/processed/temp/disease_uncleaned.dta"

disp "DateTime: $S_DATE $S_TIME"

*EOF
