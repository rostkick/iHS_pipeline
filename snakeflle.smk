configfile: 'configure.yml'

rule sampling:
	input:
		vcf=config['input_vcf']
	output:
		vcf=temp('result/sampled.vcf.gz')
	params:
		bcftools=config['tools']['bcftools'],
		tabix=config['tools']['tabix'],
		samples=config['samples']
	shell:"""
		mkdir -p result;
		{params.bcftools} view -S {params.samples} {input.vcf} -Oz -o {output.vcf}; \
		{params.tabix} -p vcf {output.vcf}"""
		
 
rule filtration:
	input: 
		vcf=config['input_vcf'] if config['samples'] is None else rules.sampling.output.vcf 
	output:
		vcf=temp('result/filtered.vcf.gz')
	params:
		bcftools=config['tools']['bcftools'],
		cchr=config['chromosome'],
		ref=config['refs']['fasta']
	log:
		'logs/filtration.log'
	shell: """
		mkdir -p result;
		{params.bcftools} view -i "%FILTER='PASS'" --regions {params.cchr} {input.vcf} -Ou 2>{log} | \
		{params.bcftools} norm -f {params.ref} -c ws -Ou 2>>{log} | \
		{params.bcftools} view -m 2 -M 2 -Ou 2>>{log} | \
		{params.bcftools} annotate --set-id '%CHROM\_%POS\_%REF\_%ALT' \
		-Oz -o {output.vcf} 2>>{log} || true
		"""

rule phasing:
	input:
		vcf=rules.filtration.output.vcf
	output:
		vcf=temp('result/phased.vcf.gz')
	params:
		output='result/phased.vcf.gz'.strip('.vcf.gz'),
		eagle=config['tools']['eagle'],
		cchr=config['chromosome'],
		gmap=config['refs']['gmap_dir'] + 'eagle_chr{cchr}_b37.map'.format(cchr=config['chromosome'])
	log:
		'logs/phasing.log'
	threads: 
		workflow.cores
	shell:"""
		{params.eagle} --vcf {input.vcf} --outPrefix {params.output} \
		--chrom {params.cchr} --geneticMapFile {params.gmap} \
		--Kpbwt=20000 --numThreads={threads} &>{log}
		"""

rule paste_aa:
	# default_target: True
	input:
		vcf=rules.phasing.output.vcf
	output:
		vcf='result/aa.vcf.gz'
	params:
		java=config['tools']['java'],
		vcfaa=config['tools']['vcfaa'],
		mf=config['refs']['manifest']
	log:
		'logs/vcfaa.log'
	shell: """
		{params.java} -jar {params.vcfaa} \
		-m {params.mf} {input.vcf} > {output.vcf} 2>{log}
		"""

rule get_iHS_score:
	default_target: True
	input:
		vcf=rules.paste_aa.output.vcf
	output:
		vcf='result/ihs.tsv'
	params:
		position=config['position']
	script: "iHS.R"
