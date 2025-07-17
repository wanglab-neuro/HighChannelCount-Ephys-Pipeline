#!/usr/bin/env nextflow
// hash:sha256:e8fd4dc1ac3c54af6420d3d329bada8e51d3dd2997710f612508fe981cfeb219

nextflow.enable.dsl = 1

params.ecephys_url = 's3://aind-ephys-data/ecephys_713593_2024-02-08_14-10-37'

capsule_aind_ephys_job_dispatch_4_to_capsule_aind_ephys_preprocessing_1_1 = channel.create()
ecephys_to_preprocess_ecephys_2 = channel.fromPath(params.ecephys_url + "/", type: 'any')
capsule_aind_ephys_postprocessing_5_to_capsule_aind_ephys_curation_2_3 = channel.create()
ecephys_to_job_dispatch_ecephys_4 = channel.fromPath(params.ecephys_url + "/", type: 'any')
ecephys_to_postprocess_ecephys_5 = channel.fromPath(params.ecephys_url + "/", type: 'any')
capsule_spikesort_kilosort_4_ecephys_7_to_capsule_aind_ephys_postprocessing_5_6 = channel.create()
capsule_aind_ephys_preprocessing_1_to_capsule_aind_ephys_postprocessing_5_7 = channel.create()
capsule_aind_ephys_job_dispatch_4_to_capsule_aind_ephys_postprocessing_5_8 = channel.create()
capsule_aind_ephys_job_dispatch_4_to_capsule_aind_ephys_visualization_6_9 = channel.create()
capsule_aind_ephys_preprocessing_1_to_capsule_aind_ephys_visualization_6_10 = channel.create()
capsule_aind_ephys_curation_2_to_capsule_aind_ephys_visualization_6_11 = channel.create()
capsule_spikesort_kilosort_4_ecephys_7_to_capsule_aind_ephys_visualization_6_12 = channel.create()
capsule_aind_ephys_postprocessing_5_to_capsule_aind_ephys_visualization_6_13 = channel.create()
ecephys_to_visualize_ecephys_14 = channel.fromPath(params.ecephys_url + "/", type: 'any')
capsule_aind_ephys_preprocessing_1_to_capsule_spikesort_kilosort_4_ecephys_7_15 = channel.create()
capsule_aind_ephys_job_dispatch_4_to_capsule_aind_ephys_results_collector_9_16 = channel.create()
capsule_aind_ephys_preprocessing_1_to_capsule_aind_ephys_results_collector_9_17 = channel.create()
capsule_spikesort_kilosort_4_ecephys_7_to_capsule_aind_ephys_results_collector_9_18 = channel.create()
capsule_aind_ephys_postprocessing_5_to_capsule_aind_ephys_results_collector_9_19 = channel.create()
capsule_aind_ephys_curation_2_to_capsule_aind_ephys_results_collector_9_20 = channel.create()
capsule_aind_ephys_visualization_6_to_capsule_aind_ephys_results_collector_9_21 = channel.create()
ecephys_to_collect_results_ecephys_22 = channel.fromPath(params.ecephys_url + "/", type: 'any')
ecephys_to_nwb_packaging_subject_23 = channel.fromPath(params.ecephys_url + "/", type: 'any')
capsule_aind_ephys_job_dispatch_4_to_capsule_nwb_packaging_units_11_24 = channel.create()
capsule_nwb_packaging_ecephys_capsule_12_to_capsule_nwb_packaging_units_11_25 = channel.create()
capsule_aind_ephys_results_collector_9_to_capsule_nwb_packaging_units_11_26 = channel.create()
ecephys_to_nwb_packaging_units_27 = channel.fromPath(params.ecephys_url + "/", type: 'any')
capsule_aind_ephys_job_dispatch_4_to_capsule_nwb_packaging_ecephys_capsule_12_28 = channel.create()
ecephys_to_nwb_packaging_ecephys_29 = channel.fromPath(params.ecephys_url + "/", type: 'any')
capsule_nwb_packaging_subject_capsule_10_to_capsule_nwb_packaging_ecephys_capsule_12_30 = channel.create()
capsule_aind_ephys_job_dispatch_4_to_capsule_quality_control_ecephys_13_31 = channel.create()
capsule_aind_ephys_results_collector_9_to_capsule_quality_control_ecephys_13_32 = channel.create()
ecephys_to_quality_control_ecephys_33 = channel.fromPath(params.ecephys_url + "/", type: 'any')
capsule_quality_control_ecephys_13_to_capsule_quality_control_collector_ecephys_14_34 = channel.create()

// capsule - Preprocess Ecephys
process capsule_aind_ephys_preprocessing_1 {
	tag 'capsule-0331265'
	container "$REGISTRY_HOST/published/49b76676-d1f6-4202-9473-c763b2b83563:v4"

	cpus 16
	memory '64 GB'

	input:
	path 'capsule/data/' from capsule_aind_ephys_job_dispatch_4_to_capsule_aind_ephys_preprocessing_1_1.flatten()
	path 'capsule/data/ecephys_session' from ecephys_to_preprocess_ecephys_2.collect()

	output:
	path 'capsule/results/*' into capsule_aind_ephys_preprocessing_1_to_capsule_aind_ephys_postprocessing_5_7
	path 'capsule/results/*' into capsule_aind_ephys_preprocessing_1_to_capsule_aind_ephys_visualization_6_10
	path 'capsule/results/*' into capsule_aind_ephys_preprocessing_1_to_capsule_spikesort_kilosort_4_ecephys_7_15
	path 'capsule/results/*' into capsule_aind_ephys_preprocessing_1_to_capsule_aind_ephys_results_collector_9_17

	script:
	"""
	#!/usr/bin/env bash
	set -e

	export CO_CAPSULE_ID=49b76676-d1f6-4202-9473-c763b2b83563
	export CO_CPUS=16
	export CO_MEMORY=68719476736

	mkdir -p capsule
	mkdir -p capsule/data && ln -s \$PWD/capsule/data /data
	mkdir -p capsule/results && ln -s \$PWD/capsule/results /results
	mkdir -p capsule/scratch && ln -s \$PWD/capsule/scratch /scratch

	echo "[${task.tag}] cloning git repo..."
	git clone --branch v4.0 "https://\$GIT_ACCESS_TOKEN@\$GIT_HOST/capsule-0331265.git" capsule-repo
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${params.capsule_aind_ephys_preprocessing_1_args}

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Curate Ecephys
process capsule_aind_ephys_curation_2 {
	tag 'capsule-3565647'
	container "$REGISTRY_HOST/published/da74428e-26f9-4f08-a9bf-898dfca44722:v4"

	cpus 4
	memory '32 GB'

	input:
	path 'capsule/data/' from capsule_aind_ephys_postprocessing_5_to_capsule_aind_ephys_curation_2_3

	output:
	path 'capsule/results/*' into capsule_aind_ephys_curation_2_to_capsule_aind_ephys_visualization_6_11
	path 'capsule/results/*' into capsule_aind_ephys_curation_2_to_capsule_aind_ephys_results_collector_9_20

	script:
	"""
	#!/usr/bin/env bash
	set -e

	export CO_CAPSULE_ID=da74428e-26f9-4f08-a9bf-898dfca44722
	export CO_CPUS=4
	export CO_MEMORY=34359738368

	mkdir -p capsule
	mkdir -p capsule/data && ln -s \$PWD/capsule/data /data
	mkdir -p capsule/results && ln -s \$PWD/capsule/results /results
	mkdir -p capsule/scratch && ln -s \$PWD/capsule/scratch /scratch

	echo "[${task.tag}] cloning git repo..."
	git clone --branch v4.0 "https://\$GIT_ACCESS_TOKEN@\$GIT_HOST/capsule-3565647.git" capsule-repo
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Job Dispatch Ecephys
process capsule_aind_ephys_job_dispatch_4 {
	tag 'capsule-6237826'
	container "$REGISTRY_HOST/published/d75d79c4-8f21-4d17-83ec-13b2a43dcaa0:v4"

	cpus 4
	memory '32 GB'

	input:
	path 'capsule/data/ecephys_session' from ecephys_to_job_dispatch_ecephys_4.collect()

	output:
	path 'capsule/results/*' into capsule_aind_ephys_job_dispatch_4_to_capsule_aind_ephys_preprocessing_1_1
	path 'capsule/results/*' into capsule_aind_ephys_job_dispatch_4_to_capsule_aind_ephys_postprocessing_5_8
	path 'capsule/results/*' into capsule_aind_ephys_job_dispatch_4_to_capsule_aind_ephys_visualization_6_9
	path 'capsule/results/*' into capsule_aind_ephys_job_dispatch_4_to_capsule_aind_ephys_results_collector_9_16
	path 'capsule/results/*' into capsule_aind_ephys_job_dispatch_4_to_capsule_nwb_packaging_units_11_24
	path 'capsule/results/*' into capsule_aind_ephys_job_dispatch_4_to_capsule_nwb_packaging_ecephys_capsule_12_28
	path 'capsule/results/*' into capsule_aind_ephys_job_dispatch_4_to_capsule_quality_control_ecephys_13_31

	script:
	"""
	#!/usr/bin/env bash
	set -e

	export CO_CAPSULE_ID=d75d79c4-8f21-4d17-83ec-13b2a43dcaa0
	export CO_CPUS=4
	export CO_MEMORY=34359738368

	mkdir -p capsule
	mkdir -p capsule/data && ln -s \$PWD/capsule/data /data
	mkdir -p capsule/results && ln -s \$PWD/capsule/results /results
	mkdir -p capsule/scratch && ln -s \$PWD/capsule/scratch /scratch

	echo "[${task.tag}] cloning git repo..."
	git clone --branch v4.0 "https://\$GIT_ACCESS_TOKEN@\$GIT_HOST/capsule-6237826.git" capsule-repo
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${params.capsule_aind_ephys_job_dispatch_4_args}

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Postprocess Ecephys
process capsule_aind_ephys_postprocessing_5 {
	tag 'capsule-4319008'
	container "$REGISTRY_HOST/published/1639e98a-74dc-4b37-9464-1b6a3868c9b0:v4"

	cpus 16
	memory '128 GB'

	input:
	path 'capsule/data/ecephys_session' from ecephys_to_postprocess_ecephys_5.collect()
	path 'capsule/data/' from capsule_spikesort_kilosort_4_ecephys_7_to_capsule_aind_ephys_postprocessing_5_6.collect()
	path 'capsule/data/' from capsule_aind_ephys_preprocessing_1_to_capsule_aind_ephys_postprocessing_5_7.collect()
	path 'capsule/data/' from capsule_aind_ephys_job_dispatch_4_to_capsule_aind_ephys_postprocessing_5_8.flatten()

	output:
	path 'capsule/results/*' into capsule_aind_ephys_postprocessing_5_to_capsule_aind_ephys_curation_2_3
	path 'capsule/results/*' into capsule_aind_ephys_postprocessing_5_to_capsule_aind_ephys_visualization_6_13
	path 'capsule/results/*' into capsule_aind_ephys_postprocessing_5_to_capsule_aind_ephys_results_collector_9_19

	script:
	"""
	#!/usr/bin/env bash
	set -e

	export CO_CAPSULE_ID=1639e98a-74dc-4b37-9464-1b6a3868c9b0
	export CO_CPUS=16
	export CO_MEMORY=137438953472

	mkdir -p capsule
	mkdir -p capsule/data && ln -s \$PWD/capsule/data /data
	mkdir -p capsule/results && ln -s \$PWD/capsule/results /results
	mkdir -p capsule/scratch && ln -s \$PWD/capsule/scratch /scratch

	echo "[${task.tag}] cloning git repo..."
	git clone --branch v4.0 "https://\$GIT_ACCESS_TOKEN@\$GIT_HOST/capsule-4319008.git" capsule-repo
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${params.capsule_aind_ephys_postprocessing_5_args}

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Visualize Ecephys
process capsule_aind_ephys_visualization_6 {
	tag 'capsule-6869873'
	container "$REGISTRY_HOST/published/e7af8ddc-08ca-418b-9e36-8249e363404e:v5"

	cpus 4
	memory '64 GB'

	input:
	path 'capsule/data/' from capsule_aind_ephys_job_dispatch_4_to_capsule_aind_ephys_visualization_6_9.collect()
	path 'capsule/data/' from capsule_aind_ephys_preprocessing_1_to_capsule_aind_ephys_visualization_6_10
	path 'capsule/data/' from capsule_aind_ephys_curation_2_to_capsule_aind_ephys_visualization_6_11.collect()
	path 'capsule/data/' from capsule_spikesort_kilosort_4_ecephys_7_to_capsule_aind_ephys_visualization_6_12.collect()
	path 'capsule/data/' from capsule_aind_ephys_postprocessing_5_to_capsule_aind_ephys_visualization_6_13.collect()
	path 'capsule/data/ecephys_session' from ecephys_to_visualize_ecephys_14.collect()

	output:
	path 'capsule/results/*' into capsule_aind_ephys_visualization_6_to_capsule_aind_ephys_results_collector_9_21

	script:
	"""
	#!/usr/bin/env bash
	set -e

	export CO_CAPSULE_ID=e7af8ddc-08ca-418b-9e36-8249e363404e
	export CO_CPUS=4
	export CO_MEMORY=68719476736

	mkdir -p capsule
	mkdir -p capsule/data && ln -s \$PWD/capsule/data /data
	mkdir -p capsule/results && ln -s \$PWD/capsule/results /results
	mkdir -p capsule/scratch && ln -s \$PWD/capsule/scratch /scratch

	echo "[${task.tag}] cloning git repo..."
	git clone --branch v5.0 "https://\$GIT_ACCESS_TOKEN@\$GIT_HOST/capsule-6869873.git" capsule-repo
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Spikesort Kilosort4 Ecephys
process capsule_spikesort_kilosort_4_ecephys_7 {
	tag 'capsule-4110207'
	container "$REGISTRY_HOST/published/3372ccfd-0388-4e1e-8c4f-46b470fcf871:v2"

	cpus 16
	memory '61 GB'
	accelerator 1
	label 'gpu'

	input:
	path 'capsule/data/' from capsule_aind_ephys_preprocessing_1_to_capsule_spikesort_kilosort_4_ecephys_7_15

	output:
	path 'capsule/results/*' into capsule_spikesort_kilosort_4_ecephys_7_to_capsule_aind_ephys_postprocessing_5_6
	path 'capsule/results/*' into capsule_spikesort_kilosort_4_ecephys_7_to_capsule_aind_ephys_visualization_6_12
	path 'capsule/results/*' into capsule_spikesort_kilosort_4_ecephys_7_to_capsule_aind_ephys_results_collector_9_18

	script:
	"""
	#!/usr/bin/env bash
	set -e

	export CO_CAPSULE_ID=3372ccfd-0388-4e1e-8c4f-46b470fcf871
	export CO_CPUS=16
	export CO_MEMORY=65498251264

	mkdir -p capsule
	mkdir -p capsule/data && ln -s \$PWD/capsule/data /data
	mkdir -p capsule/results && ln -s \$PWD/capsule/results /results
	mkdir -p capsule/scratch && ln -s \$PWD/capsule/scratch /scratch

	echo "[${task.tag}] cloning git repo..."
	git clone --branch v2.0 "https://\$GIT_ACCESS_TOKEN@\$GIT_HOST/capsule-4110207.git" capsule-repo
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${params.capsule_spikesort_kilosort_4_ecephys_7_args}

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Collect Results Ecephys
process capsule_aind_ephys_results_collector_9 {
	tag 'capsule-0338545'
	container "$REGISTRY_HOST/published/5b7e48bb-8123-4b4c-b7bf-ebaa2de8555e:v5"

	cpus 8
	memory '64 GB'

	publishDir "$RESULTS_PATH", saveAs: { filename -> new File(filename).getName() }

	input:
	path 'capsule/data/' from capsule_aind_ephys_job_dispatch_4_to_capsule_aind_ephys_results_collector_9_16.collect()
	path 'capsule/data/' from capsule_aind_ephys_preprocessing_1_to_capsule_aind_ephys_results_collector_9_17.collect()
	path 'capsule/data/' from capsule_spikesort_kilosort_4_ecephys_7_to_capsule_aind_ephys_results_collector_9_18.collect()
	path 'capsule/data/' from capsule_aind_ephys_postprocessing_5_to_capsule_aind_ephys_results_collector_9_19.collect()
	path 'capsule/data/' from capsule_aind_ephys_curation_2_to_capsule_aind_ephys_results_collector_9_20.collect()
	path 'capsule/data/' from capsule_aind_ephys_visualization_6_to_capsule_aind_ephys_results_collector_9_21.collect()
	path 'capsule/data/ecephys_session' from ecephys_to_collect_results_ecephys_22.collect()

	output:
	path 'capsule/results/*'
	path 'capsule/results/*' into capsule_aind_ephys_results_collector_9_to_capsule_nwb_packaging_units_11_26
	path 'capsule/results/*' into capsule_aind_ephys_results_collector_9_to_capsule_quality_control_ecephys_13_32

	script:
	"""
	#!/usr/bin/env bash
	set -e

	export CO_CAPSULE_ID=5b7e48bb-8123-4b4c-b7bf-ebaa2de8555e
	export CO_CPUS=8
	export CO_MEMORY=68719476736

	mkdir -p capsule
	mkdir -p capsule/data && ln -s \$PWD/capsule/data /data
	mkdir -p capsule/results && ln -s \$PWD/capsule/results /results
	mkdir -p capsule/scratch && ln -s \$PWD/capsule/scratch /scratch

	echo "[${task.tag}] cloning git repo..."
	git clone --branch v5.0 "https://\$GIT_ACCESS_TOKEN@\$GIT_HOST/capsule-0338545.git" capsule-repo
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${params.capsule_aind_ephys_results_collector_9_args}

	echo "[${task.tag}] completed!"
	"""
}

// capsule - NWB Packaging Subject
process capsule_nwb_packaging_subject_capsule_10 {
	tag 'capsule-8198603'
	container "$REGISTRY_HOST/published/bdc9f09f-0005-4d09-aaf9-7e82abd93f19:v3"

	cpus 4
	memory '32 GB'

	input:
	path 'capsule/data/ecephys_session' from ecephys_to_nwb_packaging_subject_23.collect()

	output:
	path 'capsule/results/*' into capsule_nwb_packaging_subject_capsule_10_to_capsule_nwb_packaging_ecephys_capsule_12_30

	script:
	"""
	#!/usr/bin/env bash
	set -e

	export CO_CAPSULE_ID=bdc9f09f-0005-4d09-aaf9-7e82abd93f19
	export CO_CPUS=4
	export CO_MEMORY=34359738368

	mkdir -p capsule
	mkdir -p capsule/data && ln -s \$PWD/capsule/data /data
	mkdir -p capsule/results && ln -s \$PWD/capsule/results /results
	mkdir -p capsule/scratch && ln -s \$PWD/capsule/scratch /scratch

	echo "[${task.tag}] cloning git repo..."
	git clone --branch v3.0 "https://\$GIT_ACCESS_TOKEN@\$GIT_HOST/capsule-8198603.git" capsule-repo
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${params.capsule_nwb_packaging_subject_capsule_10_args}

	echo "[${task.tag}] completed!"
	"""
}

// capsule - NWB Packaging Units
process capsule_nwb_packaging_units_11 {
	tag 'capsule-5841110'
	container "$REGISTRY_HOST/published/b9333ffe-ae7c-4b67-882f-ea71054889dd:v6"

	cpus 4
	memory '32 GB'

	publishDir "$RESULTS_PATH/nwb", saveAs: { filename -> new File(filename).getName() }

	input:
	path 'capsule/data/' from capsule_aind_ephys_job_dispatch_4_to_capsule_nwb_packaging_units_11_24.collect()
	path 'capsule/data/' from capsule_nwb_packaging_ecephys_capsule_12_to_capsule_nwb_packaging_units_11_25.collect()
	path 'capsule/data/' from capsule_aind_ephys_results_collector_9_to_capsule_nwb_packaging_units_11_26.collect()
	path 'capsule/data/ecephys_session' from ecephys_to_nwb_packaging_units_27.collect()

	output:
	path 'capsule/results/*'

	script:
	"""
	#!/usr/bin/env bash
	set -e

	export CO_CAPSULE_ID=b9333ffe-ae7c-4b67-882f-ea71054889dd
	export CO_CPUS=4
	export CO_MEMORY=34359738368

	mkdir -p capsule
	mkdir -p capsule/data && ln -s \$PWD/capsule/data /data
	mkdir -p capsule/results && ln -s \$PWD/capsule/results /results
	mkdir -p capsule/scratch && ln -s \$PWD/capsule/scratch /scratch

	echo "[${task.tag}] cloning git repo..."
	git clone --branch v6.0 "https://\$GIT_ACCESS_TOKEN@\$GIT_HOST/capsule-5841110.git" capsule-repo
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run

	echo "[${task.tag}] completed!"
	"""
}

// capsule - NWB Packaging Ecephys
process capsule_nwb_packaging_ecephys_capsule_12 {
	tag 'capsule-3438484'
	container "$REGISTRY_HOST/published/b16dfc92-eab4-425d-978f-0ba61632c413:v3"

	cpus 8
	memory '64 GB'

	input:
	path 'capsule/data/' from capsule_aind_ephys_job_dispatch_4_to_capsule_nwb_packaging_ecephys_capsule_12_28.collect()
	path 'capsule/data/ecephys_session' from ecephys_to_nwb_packaging_ecephys_29.collect()
	path 'capsule/data/' from capsule_nwb_packaging_subject_capsule_10_to_capsule_nwb_packaging_ecephys_capsule_12_30.collect()

	output:
	path 'capsule/results/*' into capsule_nwb_packaging_ecephys_capsule_12_to_capsule_nwb_packaging_units_11_25

	script:
	"""
	#!/usr/bin/env bash
	set -e

	export CO_CAPSULE_ID=b16dfc92-eab4-425d-978f-0ba61632c413
	export CO_CPUS=8
	export CO_MEMORY=68719476736

	mkdir -p capsule
	mkdir -p capsule/data && ln -s \$PWD/capsule/data /data
	mkdir -p capsule/results && ln -s \$PWD/capsule/results /results
	mkdir -p capsule/scratch && ln -s \$PWD/capsule/scratch /scratch

	echo "[${task.tag}] cloning git repo..."
	git clone --branch v3.0 "https://\$GIT_ACCESS_TOKEN@\$GIT_HOST/capsule-3438484.git" capsule-repo
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${params.capsule_nwb_packaging_ecephys_capsule_12_args}

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Quality Control Ecephys
process capsule_quality_control_ecephys_13 {
	tag 'capsule-0625308'
	container "$REGISTRY_HOST/published/56a55c84-3013-4683-be83-14d607d2cfe6:v5"

	cpus 8
	memory '64 GB'

	input:
	path 'capsule/data/' from capsule_aind_ephys_job_dispatch_4_to_capsule_quality_control_ecephys_13_31.flatten()
	path 'capsule/data/' from capsule_aind_ephys_results_collector_9_to_capsule_quality_control_ecephys_13_32.collect()
	path 'capsule/data/ecephys_session' from ecephys_to_quality_control_ecephys_33.collect()

	output:
	path 'capsule/results/*' into capsule_quality_control_ecephys_13_to_capsule_quality_control_collector_ecephys_14_34

	script:
	"""
	#!/usr/bin/env bash
	set -e

	export CO_CAPSULE_ID=56a55c84-3013-4683-be83-14d607d2cfe6
	export CO_CPUS=8
	export CO_MEMORY=68719476736

	mkdir -p capsule
	mkdir -p capsule/data && ln -s \$PWD/capsule/data /data
	mkdir -p capsule/results && ln -s \$PWD/capsule/results /results
	mkdir -p capsule/scratch && ln -s \$PWD/capsule/scratch /scratch

	echo "[${task.tag}] cloning git repo..."
	git clone --branch v5.0 "https://\$GIT_ACCESS_TOKEN@\$GIT_HOST/capsule-0625308.git" capsule-repo
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Quality Control Collector Ecephys
process capsule_quality_control_collector_ecephys_14 {
	tag 'capsule-8310834'
	container "$REGISTRY_HOST/published/324399bc-41bd-43f2-8da4-954bd243973f:v1"

	cpus 1
	memory '8 GB'

	publishDir "$RESULTS_PATH", saveAs: { filename -> new File(filename).getName() }

	input:
	path 'capsule/data/' from capsule_quality_control_ecephys_13_to_capsule_quality_control_collector_ecephys_14_34.collect()

	output:
	path 'capsule/results/*'

	script:
	"""
	#!/usr/bin/env bash
	set -e

	export CO_CAPSULE_ID=324399bc-41bd-43f2-8da4-954bd243973f
	export CO_CPUS=1
	export CO_MEMORY=8589934592

	mkdir -p capsule
	mkdir -p capsule/data && ln -s \$PWD/capsule/data /data
	mkdir -p capsule/results && ln -s \$PWD/capsule/results /results
	mkdir -p capsule/scratch && ln -s \$PWD/capsule/scratch /scratch

	echo "[${task.tag}] cloning git repo..."
	git clone --branch v1.0 "https://\$GIT_ACCESS_TOKEN@\$GIT_HOST/capsule-8310834.git" capsule-repo
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run

	echo "[${task.tag}] completed!"
	"""
}
