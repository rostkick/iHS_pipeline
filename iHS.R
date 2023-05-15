options(warn = -1)

library(rehh)
library(data.table)
suppressPackageStartupMessages(library(dplyr))


hh_vcf <- data2haplohh(hap_file = snakemake@input$vcf,
					   vcf_reader = "data.table",
					   verbose = FALSE)
res.scan <- scan_hh(hh_vcf, discard_integration_at_border = FALSE)
ihs <- ihh2ihs(res.scan, freqbin = 1, verbose = FALSE)
ihs <- ihs$ihs %>% as_tibble()
print(ihs %>% filter(POSITION==snakemake@params$position))
ihs %>% write.table(snakemake@output$vcf, quote=F)
