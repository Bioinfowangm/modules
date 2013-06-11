## defaults
SAMPLE_FILE ?= samples.txt
SAMPLES ?= $(shell cat $(SAMPLE_FILE))

VPATH ?= bam
LOGDIR = metrics/log

## includes
include ~/share/modules/Makefile.inc
include ~/share/modules/gatk.inc
include ~/share/modules/hg19.inc


.DELETE_ON_ERROR:

.SECONDARY: 

.PHONY: all gc dup

COLLECT_METRICS = $(JAVA) -Xmx8G -jar $(JARDIR)/CollectMultipleMetrics.jar VALIDATION_STRINGENCY=LENIENT
COLLECT_GC_METRICS = $(JAVA) -Xmx8G -jar $(JARDIR)/CollectGcBiasMetrics.jar VALIDATION_STRINGENCY=LENIENT

all : summary_metrics gc flagstats

flagstats : $(foreach sample,$(SAMPLES),metrics/$(sample).flagstats)

summary_metrics : $(foreach sample,$(SAMPLES),metrics/$(sample).alignment_summary_metrics)

dup : $(foreach sample,$(SAMPLES),metrics/$(sample).dup_metrics)

gc : $(foreach sample,$(SAMPLES),metrics/$(sample).gc_bias_metrics)

metrics/%.alignment_summary_metrics : %.bam
	$(call INIT_MEM,12G,13G) $(COLLECT_METRICS) I=$< O=metrics/$* REFERENCE_SEQUENCE=$(REF_FASTA) &> $(LOGDIR)/$(@F).log

metrics/%.gc_bias_metrics : %.bam
	$(call INIT_MEM,12G,13G) $(COLLECT_GC_METRICS) I=$< O=$@ CHART_OUTPUT=$(addsuffix .pdf,$@) REFERENCE_SEQUENCE=$(REF_FASTA) &> $(LOGDIR)/$(@F).log

metrics/%.flagstats : %.bam
	$(call INIT_MEM,2G,3G) $(SAMTOOLS) flagstat $< > $@ 2> $(LOGDIR)/$(@F).log
	
bam/%.markdup.bam metrics/%.dup_metrics : %.bam
	$(call INIT_MEM,18G,19G) $(MARK_DUP) I=$< O=bam/$*.markdup.bam METRICS_FILE=metrics/$*.dup_metrics &> $(LOGDIR)/$(@F).log

