# Submission Readiness Check

부산 12-2월 확장 데이터 없이, **현재 존재하는 데이터/코드/산출물만으로** revision 패키지를 점검한 결과.

## 1. `docs/20-revision-guide.md`의 1, 2, ... 이슈는 전부 다시 써야 하나?

아니다. 전부 갈아엎을 필요는 없고, 아래처럼 나뉜다.

### 그대로 유지 가능한 축
- Event-study
- Oster bounds
- Dose-response
- Stable workers
- Inequality metrics
- Learning dynamics
- AI vs dispatch 구분
- `skill -> proficiency` 전환 방향

### 수정이 필요한 축
- 근로자-고객 연계: formal mediation이 아니라 linkage analysis로 정리
- 소비자 측 고정효과 설명: customer FE / weather controls 삭제
- 대표성/검정력: placeholder가 아니라 실제 수치로 교체
- 사회적 영향 문구: “low-proficiency gains”보다 “top tier below compression, especially medium-proficiency gains”처럼 더 정확히
- matched sample 크기: 현재 산출물 기준 재확인 필요

## 2. 새로 확보한 근거

### Worker-customer linkage
- 파일: `output/tables/worker_customer_linkage.csv`
- 파일: `output/figures/worker_customer_linkage.png`
- 해석: `output/interpretation/07-worker-customer-linkage.md`
- 핵심 결과:
  - All orders: beta = -0.0205, SE = 0.0042, p < 0.001
  - Single-order days: beta = -0.0181, SE = 0.0045, p < 0.001
  - Stacked-order days: beta = -0.0719, SE = 0.0072, p < 0.001
- 사용 가능한 주장:
  - worker-side efficiency와 customer waiting time은 operationally linked
  - 하지만 현재 데이터는 formal mediation을 식별하지 못함
  - AI adoption 자체의 평균 waiting-time effect는 여전히 비유의

### Representativeness + Precision
- 파일: `output/tables/sample_representativeness.csv`
- 파일: `output/tables/precision_benchmarks.csv`
- 파일: `output/figures/sample_representativeness.png`
- 해석: `output/interpretation/08-submission-diagnostics.md`
- 핵심 결과:
  - All active Busan riders: 1,085 riders / 35,410 rider-days
  - Analytic full sample: 936 riders / 33,896 rider-days
  - Orders/hour: 4.586 vs 4.620
  - Daily orders: 30.63 vs 30.81
  - Daily labor hours: 6.77 vs 6.76
  - Daily fee: 91,736 vs 92,296 KRW
- precision benchmark:
  - Daily productivity DID MDE: 0.212 orders/hour
  - Customer waiting DID MDE: 0.461 minutes

## 3. 수정 원고/response letter에서 유지할 주장

- Parallel trends are supported.
- Omitted-variable bias would need to be stronger than observable selection to overturn the estimate.
- Productivity inequality compresses after adoption.
- The clearest productivity gains appear among medium-proficiency riders.
- Customer-side effects should be framed as conditional on customers served by treated riders.
- Worker-side efficiency and customer waiting time are linked, but formal mediation is not identified.
- The analytic full sample is broadly representative of active Busan riders over the study window.
- The matched DID design is precise enough to detect moderate operational effects.

## 4. 빼거나 약화해야 할 주장

- “formal mediation” 또는 “customer-rated delivery experience”
- “customer fixed effects” / “weather controls”를 썼다는 설명
- “single-order waiting time improved”라는 단정
- “platform-wide consumer welfare” 해석
- “AI promotes social equality”
- “lower-proficiency workers benefited the most”라는 과도한 일반화

## 5. 참고문헌 최종 점검 포인트

- Chen et al. (2024a/b): 동일 SSRN 항목 중복 금지
- Allon et al.: 2018 SSRN이 아니라 2023 MSOM 최종판 사용 권장
- Knight et al.: `skill` 용어 회피의 근거로 사용 금지
- Brynjolfsson et al. (2025): 제목 끝 `*` 제거 필요
- Dell'Acqua et al. (2023): 본문에서 “inside the frontier” 조건 병기
- 신규 필수 반영 후보:
  - Raisch & Krakowski (2021)
  - Berente et al. (2021)
  - Russell & Norvig (2021)
  - Merton (1936)
  - Oster (2019)
  - Sun & Abraham (2021)
  - Callaway & Sant’Anna (2021)
  - Cohen et al. (2022)
  - Allon et al. (2023)
  - Cachon et al. (2017)

## 6. 아직 보류해야 하는 것

- 부산 12-2월 확장 데이터를 써야 하는 장기 event-study
- 장기 적응/learning에 대한 강한 인과 주장
- 확장 데이터에 의존하는 추가 robustness
