library(data.table); library(dplyr); library(ggplot2); library(cowplot);library(lubridate);library(lfe);library(SciViews)
'%!in%' <- function(x,y)!('%in%'(x,y))

##################################################################################################################################
##### Rawdata input #####
##################################################################################################################################

##################################################################################################################################
##### Rider data (rider는 management_partner에서 관장)
##### 라이더 데이터는 1) rider: 라이더 정보 데이터(라이더id, 입직시기), 2) management_partner: 지점 데이터(지점id, 지점이름) 두개로 쪼개 추후 주문건 데이터와 각각 merge 예정

#부산 라이더 이전 데이터 
rider_past <- as.data.frame(fread("rider_info.csv", stringsAsFactors = T))
rider_past$created_at <- as.POSIXct(rider_past$created_at)
#부산 + 부산외 지역 라이더 새 데이터
rider <- as.data.frame(fread("riders_2023.csv", stringsAsFactors = T))
rider <- rider[-1,]
#라이더 데이터 합치기
colnames(rider_past); colnames(rider)
rider <- rbind(rider_past, rider)
remove(rider_past)

###지점 데이터 만들기: 라이더데이터에서 지점번호-지점이름 컬럼만 추출. 추후 주문건데이터에 지점id기준으로 지점 정보 merge해주기 위함
management_partner <- rider[,c(3:4)]
management_partner <- management_partner %>% distinct() #지점 총 1963개

#지점번호 1개당 지점이름 두개인것 (앞선 지점 해지 후 담당자/지점 이름 약간 변경된 경우): 변경 후 이름으로 정리
#단, 정리후에도 한 지점 이름이 두개의 지점번호를 가질 수는 있음
#example) 277	부산재송지점
#         277	해지_부산재송지점(김호용)
management_partner$management_partner_name <- as.character(management_partner$management_partner_name)
management_partner$nchar <- nchar(management_partner$management_partner_name)
test <- management_partner %>% group_by(management_partner_id) %>% summarise(min_nchar = min(nchar))
management_partner <- left_join(management_partner, test)
management_partner <- management_partner %>% filter(nchar==min_nchar) #지점 총 1942개
remove(test)
management_partner <- management_partner[,c(1:2)]

###라이더 데이터: id-입직시기 데이터 정리
rider <- rider[,c(1:2)]
#중복기록 제거
rider <- rider %>% distinct() 
#여러 지점 활동기록 있을 경우, 첫 활동시작 시점 기록
rider <- rider %>% group_by(rider_id) %>% summarise(created_at = min(created_at)) #라이더 89007명

##################################################################################################################################
##### Store data - monitoring_partner
#부산 상점 이전 데이터
store_past <- as.data.frame(fread("store_rider_value_stores_1221.csv"))
#부산 + 부산외 지역 상점 새 데이터
store <- as.data.frame(fread("store_2023.csv"))
colnames(store_past)
colnames(store)
#상점 데이터 합치기
store <- rbind(store_past, store)
store <- store %>% distinct() 
remove(store_past)
#상점 데이터 필요없는 컬럼 없애기
store <- store[,c(-7, -8, -11)]
store <- store %>% distinct() #상점 86,914개
#상점 id 하나에 여러 상점 이름 붙어있는것 처리
store <- store %>% group_by(store_id) %>% filter(row_number()==1) #상점 83,429개

##################################################################################################################################
### Order data
#부산 주문 이전 데이터
rawdata_past <- as.data.frame(fread("recommendation_data_20201221.csv"))
#필요한 컬럼만 추리기
rawdata_past <- rawdata_past[,c(1,2,3,4,5,6,7,11,13,14,15,16,21,22,23,24,25,26,17)]
#최근데이터와 컬럼이름 맞추기
colnames(rawdata_past)[c(8,9,10,11,12,13,14,15)] <- c("monitoring_partner_id", "submitted_at", "assigned_at", "picked_up_at","delivered_at",
                                                    "dest_lat", "dest_lng", "distance")
#부산 +  부산외 지역 주문 새 데이터
rawdata <- as.data.frame(fread("recommendation_data_2023.csv")) #8,610,872rows
rawdata_busanadd <- as.data.frame(fread("recommendation_data_busan_exclusive_dec_feb.csv"))
colnames(rawdata_past) #9,179,288rows
colnames(rawdata) #8,610,872rows
colnames(rawdata_busanadd) #13,518,010rows
# [1] "order_id"              "management_partner_id" "store_id"              "agent_id"             
# [5] "store_base_fee"        "agent_fee"             "agent_extra_fee"       "monitoringpartner_id" 
# [9] "submitted_at"          "assigned_at"           "picked_up_at"          "delivered_at"         
# [13] "dest_lat"              "dest_lng"              "distance"              "year"                 
# [17] "month"                 "day"                   "is_rec_assigned"

#주문 데이터 합치기
rawdata <- rbind(rawdata_past, rawdata)
rawdata <- rbind(rawdata, rawdata_busanadd)
remove(rawdata_past, rawdata_busanadd)

length(unique(rawdata$order_id)) #28,199,923건 -> 중복된 주문 있어 처리해야함 (데이터 커서 아래 지역별로 처리)
rawdata <- rawdata %>% group_by(order_id) %>% filter(row_number()==1)

#데이터 1차 확인
#sum(is.na(rawdata$store_id)) #76850
rawdata <- rawdata %>% filter(is.na(store_id)!=1) #왜없는진 모르겠지만 이상하므로 삭제

sum(is.na(rawdata$rider_id)) #0

#sum(is.na(rawdata$picked_up_at)) #269786
rawdata <- rawdata %>% filter(is.na(picked_up_at)!=1) #왜없는진 모르겠지만 이상하므로 삭제

#sum(is.na(rawdata$delivered_at)) #9134
rawdata <- rawdata %>% filter(is.na(delivered_at)!=1) #왜없는진 모르겠지만 이상하므로 삭제

# agent -> rider
colnames(rawdata)[c(4,6,7)] <- c("rider_id","rider_fee","rider_extra_fee")

##################################################################################################################################
##### Data 사이즈 커서 미리 쳐내기
# 분석기간: 20년 7월 ~ 21년 1월 
rawdata$y_m <- paste(rawdata$year, rawdata$month, sep="_")
unique(rawdata$y_m)
rawdata <- rawdata %>% filter(y_m %in% c("2020_7", "2020_8", "2020_9", "2020_10", "2020_11", "2020_12", "2021_1"))
nrow(rawdata) #21,446,829

rawdata <- rawdata[,-20]

##################################################################################################################################
### Merge data
#주문+상점정보
orders <- left_join(rawdata, store)
remove(rawdata)
#sum(is.na(orders$store_name)==1)

#주문+라이더정보
orders <- left_join(orders, rider)
#sum(is.na(orders$created_at))

#주문+지점정보
orders <- left_join(orders, management_partner[,1:2])
sum(is.na(orders$management_partner_name)) #128758
test <- orders %>% filter(is.na(management_partner_name)==1) 
#management_partner_id == 1066 1105 1207 1277 1231 1236  922 1169 1162 1239 1183 1090 1295 1135 1125 1371인 경우, 지점이름 없음

#주문 데이터 최종 정리
orders <- orders[,-8] #monitoring_partner_id 삭제
orders <- orders[,c(1,4,3,2,27,15,16,17,21,22,23,19,20,26,8,9,10,11,18,5,6,7,14,24,25,12,13)]
colnames(orders)
# [1] "order_id"                "rider_id"                "store_id"                "management_partner_id"   "management_partner_name" "year"                   
# [7] "month"                   "day"                     "si_do"                   "si_gun_gu"               "eup_myeon_dong"          "store_name"             
# [13] "franchise_name"          "created_at"              "submitted_at"            "assigned_at"             "picked_up_at"            "delivered_at"           
# [19] "is_rec_assigned"         "store_base_fee"          "rider_fee"               "rider_extra_fee"         "distance"                "lat"                    
# [25] "lng"                     "dest_lat"                "dest_lng"       

##################################################################################################################################
##### 지역별 데이터 확인
#지역
unique(orders$si_do)
# "부산광역시" "경상남도" "인천광역시" "광주광역시"     "대구광역시"     "대전광역시"     "울산광역시"    
# "세종특별자치시" "경기도"         "경상북도"       "충청북도"       "서울특별시"     "전라북도"       "전라남도"      
# "충청남도"       "강원도"         "제주특별자치도" "강원특별자치도"     

#부산광역시: 4,198,788건
order_busan <- orders %>% filter(si_do=="부산광역시") #4,199,241건 
length(unique(order_busan$order_id))

unique(order_busan$management_partner_name)
order_busan <- order_busan %>% filter(management_partner_name %!in% c("중지_울산삼산지점(김태흥)", "해지_울산호계지점(조윤환)",  "해지_진해용원지점(허현석)"))

min(order_busan$submitted_at); max(order_busan$submitted_at)
# [1] "2020-07-01 00:01:08 UTC"
# [1] "2021-01-31 23:59:46 UTC"
sum(order_busan$is_rec_assigned, na.rm=T)
sum(is.na(order_busan$is_rec_assigned))

###경상남도: 733,243건
order_gyeongsangnamdo <- orders %>% filter(si_do=="경상남도") #733,481건
length(unique(order_gyeongsangnamdo$order_id))

unique(order_gyeongsangnamdo$management_partner_name)
order_gyeongsangnamdo <- order_gyeongsangnamdo %>% filter(management_partner_name %!in% c("부산다대지점", "부산정관지점"))

min(order_gyeongsangnamdo$submitted_at); max(order_gyeongsangnamdo$submitted_at)
#[1] "2020-07-26 00:04:59 UTC"
#[1] "2021-01-31 23:59:35 UTC"

sum(order_gyeongsangnamdo$is_rec_assigned, na.rm=T)

sum(is.na(order_gyeongsangnamdo$is_rec_assigned))
order_gyeongsangnamdo$is_rec_assigned <- ifelse(is.na(order_gyeongsangnamdo$is_rec_assigned)==1, 0, order_gyeongsangnamdo$is_rec_assigned)
        
unique(order_gyeongsangnamdo$si_gun_gu)
# [1] "진주시"            "양산시"            "거제시"            "김해시"            "통영시"           
# [6] "창원시 의창구"     "창원시 진해구"     "창원시 성산구"     "창원시 마산합포구" "거창군"           
# [11] "밀양시"            "창원시 마산회원구" "함안군"            "사천시"            "창녕군"  

#진주시: 13033건 -> 추천배차 도입 이후 생긴 신규지역, 추천배차 주문 없음
order_jinju <- order_gyeongsangnamdo %>% filter(si_gun_gu=="진주시") 
length(unique(order_jinju$order_id))
unique(order_jinju$management_partner_name) 
min(order_jinju$submitted_at); max(order_jinju$submitted_at)
# [1] "2020-12-01 09:55:22 UTC"
# [1] "2021-01-31 23:33:27 UTC"

#양산시: 39,863건 -> 추천배차 도입 이후 생긴 신규지역. 추천배차 주문 없음.
order_yangsan <- order_gyeongsangnamdo %>% filter(si_gun_gu=="양산시")
length(unique(order_yangsan$order_id))
unique(order_yangsan$management_partner_name)
min(order_yangsan$submitted_at); max(order_yangsan$submitted_at)
# [1] "2020-12-01 08:24:04 UTC"
# [1] "2021-01-31 23:51:02 UTC"

#거제시: 274,392건 -> 기간내 추천배차 주문 없어 비교적합.
order_geoje <- order_gyeongsangnamdo %>% filter(si_gun_gu=="거제시") 
length(unique(order_geoje$order_id))
unique(order_geoje$management_partner_name)
min(order_geoje$submitted_at); max(order_geoje$submitted_at)
# [1] "2020-07-26 00:04:59 UTC"
# [1] "2021-01-31 23:59:31 UTC"

#김해시: 222,162건 -> 기간내 추천배차 주문 없어 비교적합.
order_gimhae <- order_gyeongsangnamdo %>% filter(si_gun_gu=="김해시") 
length(unique(order_gimhae$order_id))
unique(order_gimhae$management_partner_name)
min(order_gimhae$submitted_at); max(order_gimhae$submitted_at)
# [1] "2020-07-26 00:09:17 UTC"
# [1] "2021-01-31 23:59:35 UTC"

#통영시: 3,077건 -> 기간내 추천배차 주문 없어 비교적합.
order_tongyeong <- order_gyeongsangnamdo %>% filter(si_gun_gu=="통영시")
length(unique(order_tongyeong$order_id))
unique(order_tongyeong$management_partner_name)
min(order_tongyeong$submitted_at); max(order_tongyeong$submitted_at)
# [1] "2020-07-26 11:23:09 UTC"
# [1] "2021-01-31 17:15:39 UTC

#창원시 의창구: 39,438건 -> 추천배차 도입 이후 생긴 신규지역. 추천배차 주문 없음.
order_changwon_eui <- order_gyeongsangnamdo %>% filter(si_gun_gu=="창원시 의창구")
length(unique(order_changwon_eui$order_id))
unique(order_changwon_eui$management_partner_name)
min(order_changwon_eui$submitted_at); max(order_changwon_eui$submitted_at)
# [1] "2020-11-25 11:38:46 UTC"
# [1] "2021-01-31 23:39:33 UTC"

#창원시 진해구: 40,812건  -> 추천배차 도입 이후 생긴 신규지역. 추천배차 주문 없음.
order_changwon_jin <- order_gyeongsangnamdo %>% filter(si_gun_gu=="창원시 진해구")  
length(unique(order_changwon_jin$order_id))
unique(order_changwon_jin$management_partner_name)
min(order_changwon_jin$submitted_at); max(order_changwon_jin$submitted_at)
# [1] "2020-12-01 00:01:50 UTC"
# [1] "2021-01-31 23:59:28 UTC"

#창원시 성산구: 54,694건  -> 추천배차 도입 이후 생긴 신규지역. 추천배차 주문 없음.
order_changwon_sung <- order_gyeongsangnamdo %>% filter(si_gun_gu=="창원시 성산구")
length(unique(order_changwon_sung$order_id))
unique(order_changwon_sung$management_partner_name)
min(order_changwon_sung$submitted_at); max(order_changwon_sung$submitted_at)
# [1] "2020-12-01 00:04:23 UTC"
# [1] "2021-01-31 23:59:21 UTC"

#창원시 마산합포구: 17,245건  -> 추천배차 도입 이후 생긴 신규지역. 추천배차 주문 없음.
order_changwon_ma <- order_gyeongsangnamdo %>% filter(si_gun_gu=="창원시 마산합포구")  
length(unique(order_changwon_ma$order_id))
unique(order_changwon_ma$management_partner_name)
min(order_changwon_ma$submitted_at); max(order_changwon_ma$submitted_at)
# [1] "2020-12-01 00:19:24 UTC"
# [1] "2021-01-31 23:52:54 UTC"

#창원시 마산회원구: 12,905건  -> 추천배차 도입 이후 생긴 신규지역. 추천배차 주문 없음.
order_changwon_ma2 <- order_gyeongsangnamdo %>% filter(si_gun_gu=="창원시 마산회원구")
length(unique(order_changwon_ma2$order_id))
unique(order_changwon_ma2$management_partner_name)
min(order_changwon_ma2$submitted_at); max(order_changwon_ma2$submitted_at)
# [1] "2020-12-01 10:13:29 UTC"
# [1] "2021-01-31 23:42:51 UTC"

#거창군: 12,479건  -> 추천배차 도입 이후 생긴 신규지역. 추천배차 주문 없음.
order_geochang <- order_gyeongsangnamdo %>% filter(si_gun_gu=="거창군")
length(unique(order_geochang$order_id))
unique(order_geochang$management_partner_name)
min(order_geochang$submitted_at); max(order_geochang$submitted_at)
# [1] "2020-12-01 00:35:04 UTC"
# [1] "2021-01-31 23:54:59 UTC"

#밀양시: 3,193건  -> 추천배차 도입 이후 생긴 신규지역. 추천배차 주문 없음.
order_milyang <- order_gyeongsangnamdo %>% filter(si_gun_gu=="밀양시")
length(unique(order_milyang$order_id))
unique(order_milyang$management_partner_name)
min(order_milyang$submitted_at); max(order_milyang$submitted_at)
# [1] "2020-12-01 09:42:37 UTC"
# [1] "2021-01-31 22:03:15 UTC"

#함안군: 156건  -> 샘플 너무 적음. 삭제
order_haman <- order_gyeongsangnamdo %>% filter(si_gun_gu=="함안군")
#사천시: 48건  -> 샘플 너무 적음. 삭제
order_sacheon <- order_gyeongsangnamdo %>% filter(si_gun_gu=="사천시")
#창녕군: 34건  -> 샘플 너무 적음. 삭제
order_changnyeoung <- order_gyeongsangnamdo %>% filter(si_gun_gu=="창녕군")

order_gyeongsangnamdo <- rbind(order_jinju, order_yangsan, order_geoje, order_gimhae, order_tongyeong,
                               order_changwon_eui, order_changwon_jin, order_changwon_sung, order_changwon_ma, order_changwon_ma2,
                               order_geochang, order_milyang)

#인천광역시: 2,147,566건 -> 추천배차 주문 없음. 전체 사용가능
order_incheon <- orders %>% filter(si_do=="인천광역시")
length(unique(order_incheon$order_id))
unique(order_incheon$management_partner_name)
min(order_incheon$submitted_at); max(order_incheon$submitted_at)
# [1] "2020-07-26 UTC"
# [1] "2021-01-31 23:58:40 UTC"
sum(order_incheon$is_rec_assigned, na.rm=T)

#광주광역시: 1,062,211건 -> 984지점 제외 후 사용
order_gwangju <- orders %>% filter(si_do=="광주광역시")
length(unique(order_gwangju$order_id))
min(order_gwangju$submitted_at); max(order_gwangju$submitted_at)
# [1] "2020-07-26 00:00:05 UTC"
# [1] "2021-01-31 23:59:05 UTC"
#984번 지점 추천배차 테스트 도입했으므로, 이 지점 삭제
sum(order_gwangju$is_rec_assigned, na.rm=T) #50547
tmp <- order_gwangju %>% filter(is_rec_assigned==1)
unique(tmp$management_partner_id); min(tmp$submitted_at)
order_gwangju <- order_gwangju %>% filter(management_partner_id != 984)

#대구광역시: 2,435,079건 -> 809, 508지점 제외 후 사용
order_daegu <- orders %>% filter(si_do=="대구광역시")
length(unique(order_daegu$order_id))
min(order_daegu$submitted_at); max(order_daegu$submitted_at)
# [1] "2020-07-26 00:00:07 UTC"
# [1] "2021-01-31 23:58:56 UTC"
sum(order_daegu$is_rec_assigned, na.rm=T) 
tmp <- order_daegu %>% filter(is_rec_assigned==1) 
unique(tmp$management_partner_id); min(tmp$submitted_at)
order_daegu <- order_daegu %>% filter(management_partner_id %!in% c(809, 508))

#대전광역시: 677,060건 -> 전체 사용가능
order_daejeon <- orders %>% filter(si_do=="대전광역시") #677,060건
length(unique(order_daejeon$order_id))
min(order_daejeon$submitted_at); max(order_daejeon$submitted_at)
# [1] "2020-07-26 00:00:18 UTC"
# [1] "2021-01-31 23:59:16 UTC"
sum(order_daejeon$is_rec_assigned, na.rm=T) 

#울산광역시: 636,437건 -> 추천배차 도입한 25번 지점 빼고 포함
order_ulsan <- orders %>% filter(si_do=="울산광역시")
length(unique(order_ulsan$order_id))
min(order_ulsan$submitted_at); max(order_ulsan$submitted_at)
# [1] "2020-07-26 00:00:47 UTC"
# [1] "2021-01-31 23:59:16 UTC"
#25번 지점 추천배차 테스트 도입했으므로, 이지점 삭제
sum(order_ulsan$is_rec_assigned, na.rm=T) 
tmp <- order_ulsan %>% filter(is_rec_assigned==1) 
unique(tmp$management_partner_id); min(tmp$submitted_at)
order_ulsan <- order_ulsan %>% filter(management_partner_id != 25)

#세종특별자치시: 341,138건 -> 전체 사용가능
order_sejong <- orders %>% filter(si_do=="세종특별자치시")
length(unique(order_sejong$order_id))
min(order_sejong$submitted_at); max(order_sejong$submitted_at)
# [1] "2020-07-26 00:02:16 UTC"
# [1] "2021-01-31 23:43:18 UTC"
sum(order_sejong$is_rec_assigned, na.rm=T) 

#경기도: 3,602,197건 -> 전체 사용가능
order_kyeonggi <- orders %>% filter(si_do=="경기도")
length(unique(order_kyeonggi$order_id))
min(order_kyeonggi$submitted_at); max(order_kyeonggi$submitted_at)
# [1] "2020-07-26 10:26:05 UTC"
# [1] "2021-01-31 23:39:59 UTC
sum(order_kyeonggi$is_rec_assigned, na.rm=T)

#경상북도: 595,933건 -> 전체 사용가능
order_kyeongsangbukdo <- orders %>% filter(si_do=="경상북도") 
length(unique(order_kyeongsangbukdo$order_id))
min(order_kyeongsangbukdo$submitted_at); max(order_kyeongsangbukdo$submitted_at)
# [1] "2020-07-26 11:35:16 UTC"
# [1] "2021-01-31 22:12:10 UTC"

#충청북도: 245,178건 -> 전체 사용가능
order_chungcheongbukdo <- orders %>% filter(si_do=="충청북도") 
length(unique(order_chungcheongbukdo$order_id))
min(order_chungcheongbukdo$submitted_at); max(order_chungcheongbukdo$submitted_at)
# [1] "2020-08-20 15:22:30 UTC"
# [1] "2021-01-31 23:56:35 UTC"

#서울특별시: 3,095,961건 -> 신규 추가 지역, 전체 사용가능
order_seoul <- orders %>% filter(si_do=="서울특별시") 
length(unique(order_seoul$order_id))
min(order_seoul$submitted_at); max(order_seoul$submitted_at)
# [1] "2020-12-01 00:00:04 UTC"
# [1] "2021-01-31 23:59:57 UTC"

#전라북도: 185,303건 -> 신규 추가 지역, 전체 사용가능
order_jeollabukdo <- orders %>% filter(si_do=="전라북도") 
length(unique(order_jeollabukdo$order_id))
min(order_jeollabukdo$submitted_at); max(order_jeollabukdo$submitted_at)
# [1] "2020-12-01 00:00:47 UTC"
# [1] "2021-01-31 23:59:16 UTC"

#전라남도: 212,640건 -> 신규 추가 지역, 전체 사용가능 
order_jeollanamdo <- orders %>% filter(si_do=="전라남도")
length(unique(order_jeollanamdo$order_id))
min(order_jeollanamdo$submitted_at); max(order_jeollanamdo$submitted_at)
# [1] "2020-12-01 00:00:55 UTC"
# [1] "2021-01-31 23:58:44 UTC"

#충청남도: 179,214건 -> 신규 추가 지역, 전체 사용가능 
order_chungcheongnamdo <- orders %>% filter(si_do=="충청남도")
length(unique(order_chungcheongnamdo$order_id))
min(order_chungcheongnamdo$submitted_at); max(order_chungcheongnamdo$submitted_at)
# [1] "2020-12-01 00:01:13 UTC"
# [1] "2021-01-31 23:58:18 UTC"

#강원도: 259,151건 -> 신규 추가 지역, 전체 사용가능 
order_gangwondo <- orders %>% filter(si_do=="강원도")
length(unique(order_gangwondo$order_id))
min(order_gangwondo$submitted_at); max(order_gangwondo$submitted_at)
# [1] "2020-12-01 00:02:44 UTC"
# [1] "2021-01-31 23:58:56 UTC"

#제주특별자치도: 71,314건 -> 신규 추가 지역, 전체 사용가능 
order_jeju <- orders %>% filter(si_do=="제주특별자치도")
length(unique(order_jeju$order_id))
min(order_jeju$submitted_at); max(order_jeju$submitted_at)
# [1] "2020-12-01 00:05:01 UTC"
# [1] "2021-01-31 23:57:08 UTC"

#강원특별자치도: 5,662건 -> 신규 추가 지역, 전체 사용가능 
order_gangwonspecial <- orders %>% filter(si_do=="강원특별자치도")
length(unique(order_gangwonspecial$order_id))
min(order_gangwonspecial$submitted_at); max(order_gangwonspecial$submitted_at)
# [1] "2020-12-23 23:16:28 UTC"
# [1] "2021-01-31 23:21:15 UTC"

orders <- rbind(order_busan, order_gyeongsangnamdo, order_incheon, order_gwangju, order_daegu, order_daejeon,
                order_ulsan, order_sejong, order_kyeonggi, order_kyeongsangbukdo, order_chungcheongbukdo,
                order_seoul, order_jeollabukdo, order_jeollanamdo, order_chungcheongnamdo, order_gangwondo,
                order_jeju, order_gangwonspecial)

##### 최종 20,684,075건

##################################################################################################################################
##### Data cleansing #####
##################################################################################################################################
#orders: 20,684,075건에서 시작

##### 데이터 기간 확인
min(orders$submitted_at);max(orders$submitted_at)
# [1] "2020-07-01 00:01:08 UTC"
# [1] "2021-01-31 23:59:58 UTC"

##### 추천배차 주문 확인
tmp <- orders %>% filter(is_rec_assigned==1)
unique(tmp$si_do) #[1] "부산광역시"

##### 부산 초기 테스트 도입 5지점 모두 삭제 
orders <- orders %>% filter(management_partner_id %!in% c(520,461,773,369,908))  #20,061,149건남음

##### 2020-10-26 이전 추천배차 사용경험 있는 라이더 제외
orders$ymd <- as.Date(orders$submitted_at)
test <- orders %>% filter(is_rec_assigned==1)
test <- test %>% filter(ymd < "2020-10-26")
test <- unique(test$rider_id) #28명 라이더 

orders <- orders %>% filter(rider_id %!in% test) #19,956,061건

##### 프렌즈 데이터: 19,953,897건
#test <- orders %>% filter(grepl("프렌즈",management_partner_name)) 
orders <- orders %>% filter(!grepl("프렌즈",management_partner_name)) 

##### 테스트/오류/4륜 주문건: 19,946,500건
#test <- orders %>% filter(grepl("Test|test|TEST|QA|테스트|임시|오등록|vroong|사륜|4륜|잘못입력|ddd|상점정보등록",store_name))
orders <- orders %>% filter(!grepl("Test|test|TEST|QA|테스트|임시|오등록|vroong|사륜|4륜|잘못입력|ddd|상점정보등록",store_name)) 

##### process 소요시간 음수/1시간 이상 제거: 
orders[,15:18] <- lapply(orders[,15:18],function(x) ymd_hms(x))
orders <- as.data.frame(orders)

#배달 프로세스별 소요시간 계산
orders$assign_sec <- as.numeric(orders$assigned_at-orders$submitted_at)
orders$pickup_sec <- as.numeric(orders$picked_up_at-orders$assigned_at)
orders$delivery_sec <- as.numeric(orders$delivered_at-orders$picked_up_at)
orders$waiting_sec <- as.numeric(orders$delivered_at-orders$submitted_at)

#sum(is.na(orders$assign_sec));sum(is.na(orders$pickup_sec));sum(is.na(orders$delivery_sec));sum(is.na(orders$waiting_sec))
sum(orders$pickup_sec<0) # 픽업/배달 소요시간이 음수인 주문건 39071건
sum(orders$delivery_sec<0) #0
sum(orders$assign_sec>=3600) #27961
sum(orders$pickup_sec>=3600) #12209
sum(orders$delivery_sec>=3600) #34493

#배차, 픽업, 배달 1시간 이내 주문만 추출
orders <- orders %>% filter(assign_sec<3600 & pickup_sec>=0 & pickup_sec<3600 & delivery_sec<3600) #19,840,076건

##### 배달 프로세스별 소요시간 말도안되게 짧은거 제거: 
# assign_sec: 주문뜨자마자 배차받을수 있으니 엄청 짧은것도 가능
summary(orders$assign_sec)
# pickup_sec: 가게에서 여러주문 동시에 배차받고 픽업할수 있으니 엄청 짧은것도 가능
summary(orders$pickup_sec)
### orders -> orders_rev
# delivery_sec: 1분 미만 삭제(321,245건)
summary(orders$delivery_sec)
test <- orders %>% filter(delivery_sec<=60)
orders_rev <- orders %>% filter(delivery_sec>60)
# waiting_sec: 5분 미만 삭제(71,803건): 
sum(orders_rev$waiting_sec<=300)
orders_rev <- orders_rev %>% filter(waiting_sec>300) # 19,447,028건 남음

##### 배달 거리 체크: 거리가 0인것
summary(orders_rev$distance)
sum(orders_rev$distance<0.1, na.rm=T) #127,659건(0.66%)
orders_rev$distance <- ifelse(orders_rev$distance<0.1, NA, orders_rev$distance)

##### 추천배차 주문 체크
# 부산 6개월 데이터 중 추천배차 주문은 3.6%
# 부산 전지점 추천배차 도입 이후 3개월 데이터 중 추천배차 주문은 7.2%
sum(orders_rev$is_rec_assigned==1, na.rm=T) # 121,850건
sum(orders_rev$si_do=="부산광역시") #3,390,531건
sum(orders_rev$si_do=="부산광역시" & orders_rev$ymd>="2020-10-26") #1,682,444건

##### 클렌징 후 최종 19,447,028건
#아래 변수만들면서 삭제된 건들 일부 있음

##################################################################################################################################
##### Add Variables #####
##################################################################################################################################

##### hourDOW(hour-of-day-of-week) 
orders_va <- orders_rev %>% mutate(DOW = wday(ymd),
                            hour = hour(assigned_at))
orders_va <- orders_va %>% mutate(hourDOW = paste(hour, DOW, sep="_"))

##### station-date 
orders_va$station_date <- paste(orders_va$management_partner_id, orders_va$ymd, sep="_")

##### 라이더 총 수수료
orders_va <- orders_va %>% mutate(rider_total_fee = rider_fee + rider_extra_fee) 

#라이더 배달 수수료 0이 아닌 배달건만 추림: 19,444,533건
orders_va <- orders_va %>% filter(rider_total_fee > 0)

##### 합배송 관련
# 라이더가 주문을 배차받은 순서로 데이터 재정렬
orders_va <- orders_va[order(orders_va$assigned_at),]
orders_va <- orders_va[order(orders_va$rider_id),]

# shift(주문묶음) 번호 컬럼 만들기
orders_va$deliveredat_num <- as.numeric(orders_va$delivered_at)
orders_va <- orders_va %>% group_by(ymd, rider_id) %>% mutate(deliveredat_maxnum = cummax(deliveredat_num))
orders_va$deliveredat_max <- as.POSIXct(orders_va$deliveredat_maxnum, origin="1970-01-01", tz="UTC")
orders_va <- orders_va[,-39]

func_check <- function(c1,c2){return(c(1, ifelse(tail(c1,-1)<=head(c2,-1),1,0)))}
orders_va <- orders_va %>% group_by(ymd, rider_id) %>%
        mutate(check = func_check(assigned_at,deliveredat_max),
               shift = cumsum(check==0)+1)

orders_va <- orders_va[,-38:-40]

##### 처치군(추천배차 1회 이상 사용 라이더) 더미
treat_rider <- orders_va %>% filter(is_rec_assigned==1)
unique(treat_rider$si_do); min(treat_rider$ymd); max(treat_rider$ymd)

treat_rider <- unique(treat_rider$rider_id) #866명 라이더, 2,862,480건 수행
test<-orders_va %>% filter(rider_id %in% treat_rider)
test<-test %>% filter(is_rec_assigned==1) #121,850건 (4.3%)이 추천배차로 수행

orders_va$rider_treated <- ifelse(orders_va$rider_id %in% treat_rider, 1, 0)

# 추천배차 도입한 라이더가 다른 지역에서 수행한 주문이 있는지 확인-> 있음
tmp <- orders_va %>% filter(rider_treated == 1)
unique(tmp$si_do)
test <- tmp %>% filter(si_do!="부산광역시")
unique(test$rider_id)
#[1] 23725 31161 31390 45931 -> 타 지역에서 추천배차 도입 전/후 활동한 라이더들
test1 <- test %>% filter(rider_id==23725) #도입 전 울산에서 활동하여 이상없음
test1 <- test %>% filter(rider_id==31161) #도입 후 경상남도 양산으로 옮겨감 -> 삭제
test1 <- test %>% filter(rider_id==31390) #도입 후 경상남도 양산으로 옮겨감 -> 삭제
test1 <- test %>% filter(rider_id==45931) #도입 후 경상남도 양산으로 옮겨감 -> 삭제
# 추천배차 도입한 라이더가 다른 지역에서 수행한 주문 삭제
test <- test %>% filter(rider_id!=23725)
orders_va <- orders_va %>% filter(order_id %!in% test$order_id)

##### 도입후 기간 더미
orders_va$after <- ifelse(orders_va$ymd >= "2020-10-26", 1, 0)
        
#####최종 19,441,564건

##################################################################################################################################
##### 1) order, 2) shift, 3) day-level data set #####
#정제된 데이터를 1) 주문건, 2) 주문묶음, 3) 일 단위 세개의 데이터로 만들기
#앞서 제출한 논문 버전에서 main result에 활용한 데이터는 2, 3번 데이터 셋
##################################################################################################################################

##### order-level 데이터의 경우, 앞서 만든 데이터 사용

##### shift-level data: 5,674,537건
#오더, shift 기간 관련 변수
#데이터가 커서 나누어 돌린 후 붙여야함
# [1] "서울특별시"     "충청북도"       "경기도"         "전라남도"       "경상북도"       "울산광역시"    
# [7] "충청남도"       "대구광역시"     "광주광역시"     "강원도"         "강원특별자치도" "경상남도"      
# [13] "부산광역시"     "인천광역시"     "전라북도"       "대전광역시"     "제주특별자치도" "세종특별자치시"
orders_va <- as.data.frame(orders_va)

busan <- orders_va %>% filter(si_do=="부산광역시")
busan <- busan %>% 
        group_by(rider_id, management_partner_id, si_do, ymd, after, shift) %>%
        summarise(num_orders = n(), # 한 shift내 수행한 오더개수
                  shift_profit = sum(rider_total_fee),
                  start = assigned_at[which(row_number()==1)], # 한 shift내 첫 주문 배차시각
                  finish = max(delivered_at), # 한 shift내 마지막 주문 배달완료시각
                  total_duration = as.numeric(as.difftime(finish - start), units="mins"),
                  avg_assign = mean(assign_sec), avg_pickup = mean(pickup_sec), avg_deliver = mean(delivery_sec), avg_waiting = mean(waiting_sec))

data_shift <- rbind(seoul, chungcheongbukdo, kyunggido, jeollanamdo, gyeongsangbukdo, ulsan, chungcheongnamdo,
                    daegu, gwangju, gangwondo, gangwonspecial, gyeongsangnamdo, busan, incheon, jeollabukdo,
                    daejeon, jeju, sejong)
data_shift <- as.data.frame(data_shift)

# avg. duration per order
data_shift$avg_duration_orders <- data_shift$total_duration/data_shift$num_orders

# idle time
idletimes <- function(c1,c2){return(c(NA, as.numeric(as.difftime(tail(c1,-1)-head(c2,-1)), units="secs")))} # 한 shift를 끝내고 다음 shift를 시작하기까지 걸린시간

data_shift$rider_treated <- ifelse(data_shift$rider_id %in% treat_rider, 1, 0)

data_shift <- data_shift %>% group_by(rider_id, rider_treated, management_partner_id, si_do, ymd, after) %>%
        mutate(idle_btw_shifts = idletimes(start,finish))
data_shift <- as.data.frame(data_shift)
summary(data_shift$idle_btw_shifts)
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#       1      86     272    1624     838   84985  575681 

sum(data_shift$idle_btw_shifts>3600, na.rm=T) #1시간이상: 약 7.2%, 2시간이상: 약 3.4%

# idle time이 1시간 이상인 경우 NA 처리 (분석에 고려하지않음)
data_shift$idle_btw_shifts <- ifelse(data_shift$idle_btw_shifts>3600,NA,data_shift$idle_btw_shifts)
summary(data_shift$idle_btw_shifts) 

# idel time 분단위로 변경
data_shift$idle_btw_shifts <- data_shift$idle_btw_shifts/60

# hourDOW
data_shift$start_hour <- hour(data_shift$start)
data_shift <- data_shift %>% mutate(wday = wday(ymd),
                                    hourDOW = paste(start_hour, wday, sep="_"))

##### day-level data: 575,681건
head(data_shift)

# 하루 shift 개수, 전체 수행 주문수, 수수료, 실노동시간(hour), 쉬는시간(hour), 1시간당 주문수행개수
data_day <- data_shift %>% group_by(rider_id, rider_treated, management_partner_id, si_do, ymd, after) %>% 
        summarise(total_shift = n(),
                  total_orders = sum(num_orders),
                  total_fee = sum(shift_profit),
                  working_duration = sum(total_duration)/60,
                  idle_duration = sum(idle_btw_shifts, na.rm=TRUE)/60,
                  total_labor = working_duration + idle_duration,
                  orders_per_hour = total_orders/total_labor) 

#####################################################################################################################
##### 추천배차 도입 전 데이터에서, 시간당 수행주문건수로 proficiency 변수 만들기 #####
#####################################################################################################################
proficiency <- data_day %>% filter(ymd<"2020-10-26") %>%
        group_by(rider_id) %>% summarise(prof = mean(orders_per_hour))
summary(proficiency$prof)
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# 1.349   3.611   4.263   4.333   4.960   9.945 

### 1/3씩 그룹핑
quantile(proficiency$prof, probs = c(.333, .667))
# 33.3%    66.7% 
# 3.842137 4.693688 
test<-proficiency %>% filter(prof<3.842) #1242 riders
test<-proficiency %>% filter(prof>=3.842 & prof<4.694) #1248riders
test<-proficiency %>% filter(prof>=4.694) #1242riders
proficiency <- proficiency %>% mutate(prof_low = ifelse(prof<3.842,1,0),
                                      prof_med = ifelse(prof>=3.842 & prof<4.694,1,0),
                                      prof_high = ifelse(prof>=4.694,1,0))

##### 앞서 만든 데이터와 merge
### order-level
data_order <- left_join(orders_va,proficiency)
sum(is.na(data_order$prof))
# prof가 NA인 라이더: 추천배차 도입 전 기간 데이터 없는 지역 라이더 -> 분석에 사용하기 어려움
data_order.f <- data_order %>% filter(is.na(prof)==0)
unique(data_order.f$si_do)
# [1] "울산광역시"     "광주광역시"     "대구광역시"     "경상남도"       "부산광역시"     "인천광역시"    
# [7] "대전광역시"     "경기도"         "세종특별자치시" "경상북도"       "충청북도"       "서울특별시" 

### order-level, 도입전
data_order_pre <- data_order.f %>% filter(after==0)

### shift-level
data_shift <- left_join(data_shift,proficiency)
sum(is.na(data_shift$prof))
# prof가 NA인 라이더: 추천배차 도입 전 기간 데이터 없는 지역 라이더 -> 분석에 사용하기 어려움
data_shift.f <- data_shift %>% filter(is.na(prof)==0)
unique(data_shift.f$si_do)

### day-level
data_day <- left_join(data_day, proficiency)
sum(is.na(data_day$prof))
# prof가 NA인 라이더: 추천배차 도입 전 기간 데이터 없는 지역 라이더 -> 분석에 사용하기 어려움
data_day.f <- data_day %>% filter(is.na(prof)==0)
unique(data_day.f$si_do)

##################################################################################################################################
##### Data export
##################################################################################################################################
write.csv(data_order.f, "data_order.csv")
write.csv(data_shift.f, "data_shift.csv")
write.csv(data_day.f, "data_day.csv")


##################################################################################################################################
##### [코드 참고] 추천배차 전후 일정기간 존재하는 라이더 체크 및 추출하기
# ISR revision 분석에서는 현재 필요하지 않을 것으로 생각되나, 참고차 이전에 사용했던 코드 남김
##################################################################################################################################
### 2020.09.28 이후 데이터 중, 추천배차 도입 전후 / 전체기간에 대한 라이더 샘플수 
length(unique(orders$rider_id)) # 총 2529명 라이더

test <- orders %>% group_by(rider_id, created_at) %>% summarise(first_date = min(date),
                                                                last_date = max(date),
                                                                total_orders=n(),
                                                                before_orders=length(which(date>="2020-09-26" & date<"2020-10-26")),
                                                                after_orders=length(which(date>="2020-10-26" & date<="2020-11-30")),
                                                                AI_assigned_orders = sum(is_rec_assigned),
                                                                AI_completed_orders = sum(is_rec_completed),
                                                                num_date = length(unique(date)),
                                                                AI_intro_date = min(date[is_rec_completed==1]))

rider_ba <- test %>% filter(before_orders >=1 & after_orders >= 1)
length(unique(rider_ba$rider_id)); sum(rider_ba$AI_completed_orders>=1)
# [rider_ba]
# 2020-09-28이후 2020-10-26전으로 오더 1건이라도 수행한 라이더: 658명
# 그중, AI 추천배차로 1회 이상 배달완료한 라이더 453명 (68.8%)

rider_preexist <- test %>% filter(first_date <="2020-09-26" & before_orders >=1 & after_orders >=1)
length(unique(rider_preexist$rider_id)); sum(rider_preexist$AI_completed_orders>=1)
# [rider_preexist]
# 2020-09-28이전에 부릉에 들어와서 추천배차 도입 전후로 오더 1건이라도 수행한 라이더: 584명
# 그중, AI 추천배차로 1회 이상 배달완료한 라이더 400명 (68.5%)

rider_fullexist <- test %>% filter(first_date <="2020-09-26" & before_orders >=1 & after_orders >=1 & last_date>="2020-11-30")
length(unique(rider_fullexist$rider_id)); sum(rider_fullexist$AI_completed_orders>=1)
# [rider_fullexist]
# 2020-09-28 이전에 부릉에 들어와서 2020-11-26 끝까지 탈퇴안한 라이더: 351명
# 그중, AI 추천배차로 1회 이상 배달완료한 라이더 252명 (71.8%)


##### 2개월, 기준 충족 라이더 데이터 추출 #####
### data_2m_preexist
data_2m_preexist <- orders %>% filter(date>="2020-09-26") %>% 
        filter(rider_id %in% rider_preexist$rider_id)
nrow(data_2m_preexist); length(unique(data_2m_preexist$rider_id)) #815,191건, 584명 라이더
length(unique(data_2m_preexist$date)) #66일 데이터
