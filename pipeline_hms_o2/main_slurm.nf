#!/usr/bin/env nextflow
nextflow.enable.dsl = 1

params.ecephys_path = DATA_PATH

println "DATA_PATH: ${DATA_PATH}"
println "RESULTS_PATH: ${RESULTS_PATH}"
// println "PARAMS: ${params}"

// params_keys = params.keySet()
// // set global n_jobs
// if ("n_jobs" in params_keys) {
// 	n_jobs = params.n_jobs
// }
// else
// {
// 	n_jobs = -1
// }
// println "N JOBS: ${n_jobs}"
println "Params: ${params}"

// set sorter
if ("sorter" in params_keys) {
	sorter = params.sorter
}
else
{
	sorter = "kilosort25"
}
println "Using SORTER: ${sorter}"

// set runmode
if ("runmode" in params_keys) {
	runmode = params.runmode
}
else
{
	runmode = "full"
}
println "Using RUNMODE: ${runmode}"

if (!params_keys.contains('job_dispatch_args')) {
	job_dispatch_args = ""
}
else {
	job_dispatch_args = params.job_dispatch_args
}
if (!params_keys.contains('preprocessing_args')) {
	preprocessing_args = ""
}
else {
	preprocessing_args = params.preprocessing_args
}
if (!params_keys.contains('spikesorting_args')) {
	spikesorting_args = ""
}
else {
	spikesorting_args = params.spikesorting_args
}
if (!params_keys.contains('postprocessing_args')) {
	postprocessing_args = ""
}
else {
	postprocessing_args = params.postprocessing_args
}
if (!params_keys.contains('unit_classifier_args')) {
	unit_classifier_args = ""
}
else {
	unit_classifier_args = params.unit_classifier_args
}
if (!params_keys.contains('nwb_subject_args')) {
	nwb_subject_args = ""
}
else {
	nwb_subject_args = params.nwb_subject_args
}
if (!params_keys.contains('nwb_ecephys_args')) {
	nwb_ecephys_args = ""
}
else {
	nwb_ecephys_args = params.nwb_ecephys_args
}

if (runmode == 'fast'){
	preprocessing_args = "--motion skip"
	postprocessing_args = "--skip-extensions spike_locations,principal_components"
	unit_classifier_args = "--skip-metrics-recomputation"
	nwb_ecephys_args = "--skip-lfp"
	println "Running in fast mode. Setting parameters:"
	println "preprocessing_args: ${preprocessing_args}"
	println "postprocessing_args: ${postprocessing_args}"
	println "unit_classifier_args: ${unit_classifier_args}"
	println "nwb_ecephys_args: ${nwb_ecephys_args}"
}


job_dispatch_to_preprocessing = channel.create()
ecephys_to_preprocessing = channel.fromPath(params.ecephys_path + "/", type: 'any')
postprocessing_to_curation = channel.create()
ecephys_to_job_dispatch = channel.fromPath(params.ecephys_path + "/", type: 'any')
ecephys_to_postprocessing = channel.fromPath(params.ecephys_path + "/", type: 'any')
spikesort_kilosort25_to_postprocessing = channel.create()
spikesort_kilosort4_to_postprocessing = channel.create()
spikesort_spykingcircus2_to_postprocessing = channel.create()
preprocessing_to_postprocessing = channel.create()
job_dispatch_to_postprocessing = channel.create()
job_dispatch_to_visualization = channel.create()
unit_classifier_to_visualization = channel.create()
preprocessing_to_visualization = channel.create()
curation_to_visualization = channel.create()
spikesort_kilosort25_to_visualization = channel.create()
spikesort_kilosort4_to_visualization = channel.create()
spikesort_spykingcircus2_to_visualization = channel.create()
postprocessing_to_visualization = channel.create()
ecephys_to_visualization = channel.fromPath(params.ecephys_path + "/", type: 'any')
preprocessing_to_spikesort_kilosort25 = channel.create()
preprocessing_to_spikesort_kilosort4 = channel.create()
preprocessing_to_spikesort_spykingcircus2 = channel.create()
postprocessing_to_unit_classifier = channel.create()
job_dispatch_to_results_collector = channel.create()
preprocessing_to_results_collector = channel.create()
spikesort_kilosort25_to_results_collector = channel.create()
spikesort_kilosort4_to_results_collector = channel.create()
spikesort_spykingcircus2_to_results_collector = channel.create()
postprocessing_to_results_collector = channel.create()
curation_to_results_collector = channel.create()
unit_classifier_to_results_collector = channel.create()
visualization_to_results_collector = channel.create()
ecephys_to_collect_results = channel.fromPath(params.ecephys_path + "/", type: 'any')
ecephys_to_nwb_subject = channel.fromPath(params.ecephys_path + "/", type: 'any')
job_dispatch_to_nwb_units = channel.create()
nwb_ecephys_to_nwb_units = channel.create()
results_collector_to_nwb_units = channel.create()
ecephys_to_nwb_units = channel.fromPath(params.ecephys_path + "/", type: 'any')
job_dispatch_to_nwb_ecephys = channel.create()
ecephys_to_nwb_ecephys = channel.fromPath(params.ecephys_path + "/", type: 'any')
nwb_subject_to_nwb_ecephys = channel.create()

if (sorter == 'kilosort25') {
	spikesort_to_postprocessing = spikesort_kilosort25_to_postprocessing
	spikesort_to_visualization = spikesort_kilosort25_to_visualization
	spikesort_to_results_collector = spikesort_kilosort25_to_results_collector
}
else if (sorter == 'kilosort4') {
	spikesort_to_postprocessing = spikesort_kilosort4_to_postprocessing
	spikesort_to_visualization = spikesort_kilosort4_to_visualization
	spikesort_to_results_collector = spikesort_kilosort4_to_results_collector
}
else if (sorter == 'spykingcircus2') {
	spikesort_to_postprocessing = spikesort_spykingcircus2_to_postprocessing
	spikesort_to_visualization = spikesort_spykingcircus2_to_visualization
	spikesort_to_results_collector = spikesort_spykingcircus2_to_results_collector
}


// capsule - Job Dispatch Ecephys
process job_dispatch {
	// tag 'job-dispatch'
	// container 'ghcr.io/allenneuraldynamics/aind-ephys-pipeline-base:si-0.101.2'
	tag 'capsule-5832718'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-base_si-0.100.7.sif'

	cpus 4
	memory '8 GB'
	time '1h'

	input:
	path 'capsule/data/ecephys_session' from ecephys_to_job_dispatch.collect()

	output:
	path 'capsule/results/*' into job_dispatch_to_preprocessing
	path 'capsule/results/*' into job_dispatch_to_postprocessing
	path 'capsule/results/*' into job_dispatch_to_visualization
	path 'capsule/results/*' into job_dispatch_to_results_collector
	path 'capsule/results/*' into job_dispatch_to_nwb_ecephys
	path 'capsule/results/*' into job_dispatch_to_nwb_units
	env max_duration_min
	
	script:
	"""
	#!/usr/bin/env bash
	set -e

	mkdir -p capsule
	mkdir -p capsule/data
	mkdir -p capsule/results
	mkdir -p capsule/scratch

	TASK_DIR=\$(pwd)

	echo "[${task.tag}] cloning git repo..."
	git clone "https://github.com/AllenNeuralDynamics/aind-ephys-job-dispatch.git" capsule-repo
	# git -C capsule-repo checkout e86186dc31e33e5326648f2a28d5e780253e153a --quiet
	git -C capsule-repo checkout 5d76d29ba2817cfc3bb6b35a06ce94cae22b815a --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${job_dispatch_args}

	max_duration_min=\$(python get_max_recording_duration_min.py)
	echo "MAX DURATION: \$max_duration_min"

	cd \$TASK_DIR

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Preprocess Ecephys
process preprocessing {
	// tag 'preprocessing'
	// container 'ghcr.io/allenneuraldynamics/aind-ephys-pipeline-base:si-0.101.2'
	// maxForks 1
	tag 'capsule-4923505'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-base_si-0.100.7.sif'

	cpus 8
	memory '64 GB'
	time '4h'

	input:
	path 'capsule/data/' from job_dispatch_to_preprocessing.flatten()
	path 'capsule/data/ecephys_session' from ecephys_to_preprocessing.collect()

	output:
	path 'capsule/results/*' into preprocessing_to_postprocessing
	path 'capsule/results/*' into preprocessing_to_visualization
	path 'capsule/results/*' into preprocessing_to_spikesort_kilosort25
	path 'capsule/results/*' into preprocessing_to_spikesort_kilosort4
	path 'capsule/results/*' into preprocessing_to_spikesort_spykingcircus2
	path 'capsule/results/*' into preprocessing_to_results_collector

	script:
	"""
	#!/usr/bin/env bash
	set -e

	mkdir -p capsule
	mkdir -p capsule/data
	mkdir -p capsule/results
	mkdir -p capsule/scratch

	echo "[${task.tag}] cloning git repo..."
	git clone "https://github.com/AllenNeuralDynamics/aind-ephys-preprocessing.git" capsule-repo
	# git -C capsule-repo checkout 18ea0a8c22a3ea65af265d7912bf0ddcd88d61c5 --quiet
	git -C capsule-repo checkout 23acc0e17e21e77a5e4a8900bae8218a085adf81 --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	# ./run ${preprocessing_args} --n-jobs ${n_jobs}
	./run ${params.preprocessing_args}

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Spikesort Kilosort2.5 Ecephys
process spikesort_kilosort25 {
	// tag 'spikesort-kilosort25'
	// container 'ghcr.io/allenneuraldynamics/aind-ephys-spikesort-kilosort25:si-0.101.2'
	// containerOptions '--gpus all'
	// maxForks 1
	tag 'capsule-2633671'
	container 'file:///${CONTAINER_DIR}/aind-ephys-spikesort-kilosort25_si-0.100.7.sif'
	containerOptions ' --nv'
	clusterOptions '-p gpu --gres=gpu:1'

	cpus 4 
	memory '32 GB'
	time '4h'

	input:
	path 'capsule/data/' from preprocessing_to_spikesort_kilosort25

	output:
	path 'capsule/results/*' into spikesort_kilosort25_to_postprocessing
	path 'capsule/results/*' into spikesort_kilosort25_to_visualization
	path 'capsule/results/*' into spikesort_kilosort25_to_results_collector

	when:
	sorter == 'kilosort25'

	script:
	"""
	#!/usr/bin/env bash
	set -e

	mkdir -p capsule
	mkdir -p capsule/data
	mkdir -p capsule/results
	mkdir -p capsule/scratch

	#module load cuda/12.1
	echo "[${task.tag}] cloning git repo..."
	git clone "https://github.com/AllenNeuralDynamics/aind-ephys-spikesort-kilosort25.git" capsule-repo
	git -C capsule-repo checkout 89de53271ed4fffcc5502fd07f9c6ad9d9d8f53a --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${spikesorting_args} --n-jobs ${n_jobs}

	echo "[${task.tag}] completed!"
	"""
}

// // capsule - Spikesort Kilosort4 Ecephys
// process spikesort_kilosort4 {
// 	tag 'spikesort-kilosort4'
// 	container 'ghcr.io/allenneuraldynamics/aind-ephys-spikesort-kilosort4:si-0.101.2'
// 	containerOptions '--gpus all'
// 	maxForks 1

// 	input:
// 	path 'capsule/data/' from preprocessing_to_spikesort_kilosort4

// 	output:
// 	path 'capsule/results/*' into spikesort_kilosort4_to_postprocessing
// 	path 'capsule/results/*' into spikesort_kilosort4_to_visualization
// 	path 'capsule/results/*' into spikesort_kilosort4_to_results_collector

// 	when:
// 	sorter == 'kilosort4'

// 	script:
// 	"""
// 	#!/usr/bin/env bash
// 	set -e

// 	mkdir -p capsule
// 	mkdir -p capsule/data
// 	mkdir -p capsule/results
// 	mkdir -p capsule/scratch

// 	echo "[${task.tag}] cloning git repo..."
// 	git clone "https://github.com/AllenNeuralDynamics/aind-ephys-spikesort-kilosort4.git" capsule-repo
// 	git -C capsule-repo checkout 06c2da8f5ca00ba78bf6d9d841bf3d1bacf6fb03 --quiet
// 	mv capsule-repo/code capsule/code
// 	rm -rf capsule-repo

// 	echo "[${task.tag}] running capsule..."
// 	cd capsule/code
// 	chmod +x run
// 	./run ${spikesorting_args} --n-jobs ${n_jobs}

// 	echo "[${task.tag}] completed!"
// 	"""
// }

// // capsule - Spikesort SpykingCircus Ecephys
// process spikesort_spykingcircus2 {
// 	tag 'spikesort-spykingcircus2'
// 	container 'ghcr.io/allenneuraldynamics/aind-ephys-spikesort-spykingcircus2:si-0.101.2'
// 	maxForks 1

// 	input:
// 	path 'capsule/data/' from preprocessing_to_spikesort_spykingcircus2

// 	output:
// 	path 'capsule/results/*' into spikesort_spykingcircus2_to_postprocessing
// 	path 'capsule/results/*' into spikesort_spykingcircus2_to_visualization
// 	path 'capsule/results/*' into spikesort_spykingcircus2_to_results_collector

// 	when:
// 	sorter == 'spykingcircus2'

// 	script:
// 	"""
// 	#!/usr/bin/env bash
// 	set -e

// 	mkdir -p capsule
// 	mkdir -p capsule/data
// 	mkdir -p capsule/results
// 	mkdir -p capsule/scratch

// 	echo "[${task.tag}] cloning git repo..."
// 	git clone "https://github.com/AllenNeuralDynamics/aind-ephys-spikesort-spykingcircus2.git" capsule-repo
// 	git -C capsule-repo checkout 2f561b46ab54f462af75833fe042ab6f62f673f4 --quiet
// 	mv capsule-repo/code capsule/code
// 	rm -rf capsule-repo

// 	echo "[${task.tag}] running capsule..."
// 	cd capsule/code
// 	chmod +x run
// 	./run ${spikesorting_args} --n-jobs ${n_jobs}
// 	./run

// 	echo "[${task.tag}] completed!"
// 	"""
// }


// capsule - Postprocess Ecephys
process postprocessing {
	// tag 'postprocessing'
	// container 'ghcr.io/allenneuraldynamics/aind-ephys-pipeline-base:si-0.101.2'
	// maxForks 1
	tag 'capsule-5473620'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-base_si-0.100.7.sif'

	cpus 4
	memory '16 GB'
	time '4h'

	input:
	path 'capsule/data/ecephys_session' from ecephys_to_postprocessing.collect()
	path 'capsule/data/' from spikesort_to_postprocessing.collect()
	path 'capsule/data/' from preprocessing_to_postprocessing.collect()
	path 'capsule/data/' from job_dispatch_to_postprocessing.flatten()

	output:
	path 'capsule/results/*' into postprocessing_to_curation
	path 'capsule/results/*' into postprocessing_to_visualization
	path 'capsule/results/*' into postprocessing_to_unit_classifier
	path 'capsule/results/*' into postprocessing_to_results_collector

	script:
	"""
	#!/usr/bin/env bash
	set -e

	mkdir -p capsule
	mkdir -p capsule/data
	mkdir -p capsule/results
	mkdir -p capsule/scratch

	echo "[${task.tag}] cloning git repo..."
	git clone "https://github.com/AllenNeuralDynamics/aind-ephys-postprocessing.git" capsule-repo
	git -C capsule-repo checkout 232c93ba405ab29e059fff4361c0e2535541e2a9 --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	# ./run ${postprocessing_args} --n-jobs ${n_jobs}
	./run

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Curate Ecephys
process curation {
	// tag 'curation'
	// container 'ghcr.io/allenneuraldynamics/aind-ephys-pipeline-base:si-0.101.2'
	tag 'capsule-8866682'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-base_si-0.100.7.sif'

	cpus 1
	memory '8 GB'
	time '10min'

	input:
	path 'capsule/data/' from postprocessing_to_curation

	output:
	path 'capsule/results/*' into curation_to_visualization
	path 'capsule/results/*' into curation_to_results_collector

	script:
	"""
	#!/usr/bin/env bash
	set -e

	mkdir -p capsule
	mkdir -p capsule/data
	mkdir -p capsule/results
	mkdir -p capsule/scratch

	echo "[${task.tag}] cloning git repo..."
	git clone "https://github.com/AllenNeuralDynamics/aind-ephys-curation.git" capsule-repo
	git -C capsule-repo checkout 23cc0bceadb86f1bacf1cbbd3c0533515a12018e --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Unit Classifier Ecephys
process unit_classifier {
	// tag 'unit-classifier'
	// container 'ghcr.io/allenneuraldynamics/aind-ephys-unit-classifier:si-0.101.2'
	tag 'capsule-3820244'
	container 'file:///${CONTAINER_DIR}/aind-ephys-unit-classifier_si-0.100.7.sif'

	cpus 4
	memory '16GB'
	time '30min'

	input:
	path 'capsule/data/' from postprocessing_to_unit_classifier

	output:
	path 'capsule/results/*' into unit_classifier_to_visualization
	path 'capsule/results/*' into unit_classifier_to_results_collector

	script:
	"""
	#!/usr/bin/env bash
	set -e

	mkdir -p capsule
	mkdir -p capsule/data
	mkdir -p capsule/results
	mkdir -p capsule/scratch

	echo "[${task.tag}] cloning git repo..."
	git clone "https://github.com/AllenNeuralDynamics/aind-ephys-unit-classifier.git" capsule-repo
	git -C capsule-repo checkout f63d867b582d2ea199db50ac1c4867fe6f578dde --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${unit_classifier_args}

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Visualize Ecephys
process visualization {
	// tag 'visualization'
	// container 'ghcr.io/allenneuraldynamics/aind-ephys-pipeline-base:si-0.101.2'
	tag 'capsule-6668112'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-base_si-0.100.7.sif'

	cpus 4
	memory '16 GB'
	time '2h'

	input:
	path 'capsule/data/' from job_dispatch_to_visualization.collect()
	path 'capsule/data/' from unit_classifier_to_visualization.collect()
	path 'capsule/data/' from preprocessing_to_visualization
	path 'capsule/data/' from curation_to_visualization.collect()
	path 'capsule/data/' from spikesort_to_visualization.collect()
	path 'capsule/data/' from postprocessing_to_visualization.collect()
	path 'capsule/data/ecephys_session' from ecephys_to_visualization.collect()

	output:
	path 'capsule/results/*' into visualization_to_results_collector


	script:
	"""
	#!/usr/bin/env bash
	set -e

	mkdir -p capsule
	mkdir -p capsule/data
	mkdir -p capsule/results
	mkdir -p capsule/scratch

	echo "[${task.tag}] cloning git repo..."
	git clone "https://github.com/AllenNeuralDynamics/aind-ephys-visualization.git" capsule-repo
	git -C capsule-repo checkout d59e005fc75dbfbb9a3966a61aefde8b61f8f422 --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Collect Results Ecephys
process results_collector {
	// tag 'result-collector'
	// container 'ghcr.io/allenneuraldynamics/aind-ephys-pipeline-base:si-0.101.2'
	tag 'capsule-4820071'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-base_si-0.100.7.sif'

	cpus 4
	memory '16 GB'
	time '1h'

	publishDir "$RESULTS_PATH", saveAs: { filename -> new File(filename).getName() }

	input:
	path 'capsule/data/' from job_dispatch_to_results_collector.collect()
	path 'capsule/data/' from preprocessing_to_results_collector.collect()
	path 'capsule/data/' from spikesort_to_results_collector.collect()
	path 'capsule/data/' from postprocessing_to_results_collector.collect()
	path 'capsule/data/' from curation_to_results_collector.collect()
	path 'capsule/data/' from unit_classifier_to_results_collector.collect()
	path 'capsule/data/' from visualization_to_results_collector.collect()
	path 'capsule/data/ecephys_session' from ecephys_to_collect_results.collect()

	output:
	path 'capsule/results/*'
	path 'capsule/results/*' into results_collector_to_nwb_units

	script:
	"""
	#!/usr/bin/env bash
	set -e

	mkdir -p capsule
	mkdir -p capsule/data
	mkdir -p capsule/results
	mkdir -p capsule/scratch

	echo "[${task.tag}] cloning git repo..."

	git clone "https://github.com/AllenNeuralDynamics/aind-ephys-results-collector.git" capsule-repo
	git -C capsule-repo checkout aa4f29acefd7bf206af1c193ccf95afb883646fa --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run

	echo "[${task.tag}] completed!"
	"""
}

// capsule - aind-subject-nwb
process nwb_subject {
	// tag 'nwb-subject'
	// container 'ghcr.io/allenneuraldynamics/aind-ephys-pipeline-nwb:si-0.101.2'
	tag 'capsule-9109637'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-nwb_si-0.100.7.sif'

	cpus 4
	memory '16 GB'
	time '10min'

	input:
	path 'capsule/data/ecephys_session' from ecephys_to_nwb_subject.collect()

	output:
	path 'capsule/results/*' into nwb_subject_to_nwb_ecephys

	script:
	"""
	#!/usr/bin/env bash
	set -e

	mkdir -p capsule
	mkdir -p capsule/data
	mkdir -p capsule/results
	mkdir -p capsule/scratch

	echo "[${task.tag}] cloning git repo..."
	git clone "https://github.com/AllenNeuralDynamics/aind-subject-nwb" capsule-repo
    git -C capsule-repo checkout e552ae1dadc901d09aa7b6211e2d21b53e43355d --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo



	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${nwb_subject_args}

	echo "[${task.tag}] completed!"
	"""
}

// // capsule - aind-ecephys-nwb
// process nwb_ecephys {
// 	tag 'nwb-ecephys'
// 	container 'ghcr.io/allenneuraldynamics/aind-ephys-pipeline-nwb:si-0.101.2'
// capsule - NWB-Packaging-Units
process nwb_units {
	tag 'capsule-6946197'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-nwb_si-0.100.7.sif'

	cpus 4
	memory '16 GB'
	time '2h'

	publishDir "$RESULTS_PATH", saveAs: { filename -> new File(filename).getName() }

	input:
	path 'capsule/data/' from job_dispatch_to_nwb_ecephys.collect()
	path 'capsule/data/ecephys_session' from ecephys_to_nwb_ecephys.collect()
	path 'capsule/data/' from nwb_subject_to_nwb_ecephys.collect()

	output:
	path 'capsule/results/*' into nwb_ecephys_to_nwb_units

	script:
	"""
	#!/usr/bin/env bash
	set -e

	mkdir -p capsule
	mkdir -p capsule/data
	mkdir -p capsule/results
	mkdir -p capsule/scratch

	echo "[${task.tag}] cloning git repo..."
	git clone "https://github.com/AllenNeuralDynamics/aind-ecephys-nwb.git" capsule-repo
	git -C capsule-repo checkout e1faeb6724d1b40293270304e7b6d60147180430 --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${nwb_ecephys_args}

	echo "[${task.tag}] completed!"
	"""
}


// capsule - aind-units-nwb
process nwb_units {
	tag 'nwb-units'
	container 'ghcr.io/allenneuraldynamics/aind-ephys-pipeline-nwb:si-0.101.2'

	publishDir "$RESULTS_PATH/nwb", saveAs: { filename -> new File(filename).getName() }

	input:
	path 'capsule/data/' from job_dispatch_to_nwb_units.collect()
	path 'capsule/data/' from results_collector_to_nwb_units.collect()
	path 'capsule/data/ecephys_session' from ecephys_to_nwb_units.collect()
	path 'capsule/data/' from nwb_ecephys_to_nwb_units.collect()

	output:
	path 'capsule/results/*'

	script:
	"""
	#!/usr/bin/env bash
	set -e

	mkdir -p capsule
	mkdir -p capsule/data
	mkdir -p capsule/results
	mkdir -p capsule/scratch

	echo "[${task.tag}] cloning git repo..."
	# git clone "https://github.com/AllenNeuralDynamics/aind-units-nwb.git" capsule-repo
	# git -C capsule-repo checkout d3c1bb7ea3279feda51fcf0c9f022bf714cf74e5 --quiet
	git clone "https://github.com/AllenNeuralDynamics/NWB_Packaging_Units.git" capsule-repo
	git -C capsule-repo checkout ba80069df2bd0cea5ce771976fde4de462cccbde --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run

	echo "[${task.tag}] completed!"
	"""
}
