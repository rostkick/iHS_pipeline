library(rehh)
library(data.table)
library(dplyr)


hh_vcf <- data2haplohh(hap_file = "selection/asw.vcf",
                       vcf_reader = "data.table",
                       verbose = FALSE)
res <- calc_ehh(hh_vcf, mrk = "1_207782889_A_G", include_nhaplo = TRUE)
plot(res)
res.scan <- scan_hh(hh_vcf, discard_integration_at_border = FALSE)
ihs <- ihh2ihs(res.scan, freqbin = 1, verbose = FALSE)
ihs$ihs %>% as_tibble() %>% filter(POSITION==207782856)
ihs$ihs %>% as_tibble() %>% filter(POSITION==207782889)
