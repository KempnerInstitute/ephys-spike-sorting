#!/usr/bin/env nextflow
nextflow.enable.dsl = 1

params.ecephys_path = DATA_PATH

println "DATA_PATH: ${DATA_PATH}"
println "RESULTS_PATH: ${RESULTS_PATH}"
println "PARAMS: ${params}"


params_keys = params.keySet()
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
	params.job_dispatch_args = ""
}
if (!params_keys.contains('preprocessing_args')) {
	params.preprocessing_args = ""
}
if (!params_keys.contains('spikesorting_args')) {
	params.spikesorting_args = ""
}
if (!params_keys.contains('postprocessing_args')) {
	params.postprocessing_args = ""
}
if (!params_keys.contains('unit_classifier_args')) {
	params.unit_classifier_args = ""
}
if (!params_keys.contains('nwb_subject_args')) {
	params.nwb_subject_args = ""
}
if (!params_keys.contains('nwb_ecephys_args')) {
	params.nwb_ecephys_args = ""
}

if (runmode == 'fast'){
	params.preprocessing_args = "--motion skip"
	params.postprocessing_args = "--skip-extensions spike_locations,principal_components"
	params.unit_classifier_args = "--skip-metrics-recomputation"
	params.nwb_ecephys_args = "--skip-lfp"
	println "Running in fast mode. Setting parameters:"
	println "preprocessing_args: ${params.preprocessing_args}"
	println "postprocessing_args: ${params.postprocessing_args}"
	println "unit_classifier_args: ${params.unit_classifier_args}"
	println "nwb_ecephys_args: ${params.nwb_ecephys_args}"
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
	tag 'job-dispatch'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-base_si-0.101.2.sif'

	cpus 4
	memory '32 GB'
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

	TASK_DIR=\$(pwd)

	mkdir -p capsule
	mkdir -p capsule/data
	mkdir -p capsule/results
	mkdir -p capsule/scratch

	echo "[${task.tag}] cloning git repo..."
	git clone "https://github.com/AllenNeuralDynamics/aind-ephys-job-dispatch.git" capsule-repo
	git -C capsule-repo -c core.fileMode=false checkout d6bdb9cc02d6711790a5c406cd50c1434074b5e2 --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${params.job_dispatch_args}

	max_duration_min=\$(python get_max_recording_duration_min.py)
	echo "Max recording duration in minutes: \$max_duration_min"

	cd \$TASK_DIR

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Preprocess Ecephys
process preprocessing {
	tag 'preprocessing'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-base_si-0.101.2.sif'

	cpus 16
	memory '64 GB'
	// Allocate 4x recording duration
	time { max_duration_min.value.toFloat()*4 + 'm' }

	input:
	env max_duration_min
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
	git -C capsule-repo -c core.fileMode=false checkout 8b993d495e6230b6b2aabfd4acff364679e864b8 --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] allocated time: ${task.time}"

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${params.preprocessing_args}

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Spikesort Kilosort2.5 Ecephys
process spikesort_kilosort25 {
	tag 'spikesort-kilosort25'
	container 'file:///${CONTAINER_DIR}/aind-ephys-spikesort-kilosort25_si-0.101.2.sif'
	containerOptions '--nv'
        clusterOptions '-p gpu --gres=gpu:1'

	cpus 16
	memory '64 GB'
	// Allocate 4x recording duration
	time { max_duration_min.value.toFloat()*4 + 'm' }

	input:
	env max_duration_min
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

	echo "[${task.tag}] cloning git repo..."
	git clone "https://github.com/AllenNeuralDynamics/aind-ephys-spikesort-kilosort25.git" capsule-repo
	git -C capsule-repo -c core.fileMode=false checkout 8c8987260a27c75b1f523d306b40a16962a97ea6 --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] allocated time: ${task.time}"

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${params.spikesorting_args}

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Spikesort Kilosort4 Ecephys
process spikesort_kilosort4 {
	tag 'spikesort-kilosort4'
	container 'file:///${CONTAINER_DIR}/aind-ephys-spikesort-kilosort4_si-0.101.2.sif'
	containerOptions '--nv'
        clusterOptions '-p gpu --gres=gpu:1'

	cpus 16
	memory '64 GB'
	// Allocate 4x recording duration
	time { max_duration_min.value.toFloat()*4 + 'm' }

	input:
	env max_duration_min
	path 'capsule/data/' from preprocessing_to_spikesort_kilosort4

	output:
	path 'capsule/results/*' into spikesort_kilosort4_to_postprocessing
	path 'capsule/results/*' into spikesort_kilosort4_to_visualization
	path 'capsule/results/*' into spikesort_kilosort4_to_results_collector

	when:
	sorter == 'kilosort4'

	script:
	"""
	#!/usr/bin/env bash
	set -e

	mkdir -p capsule
	mkdir -p capsule/data
	mkdir -p capsule/results
	mkdir -p capsule/scratch

	echo "[${task.tag}] cloning git repo..."
	git clone "https://github.com/AllenNeuralDynamics/aind-ephys-spikesort-kilosort4.git" capsule-repo
	git -C capsule-repo -c core.fileMode=false checkout 6b4e6cd5bf90e05be7ce7e2de9a28f4dcfa02c29 --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] allocated time: ${task.time}"

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${params.spikesorting_args}

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Spikesort SpykingCircus Ecephys
process spikesort_spykingcircus2 {
	tag 'spikesort-spykingcircus2'
	container 'file:///${CONTAINER_DIR}/aind-ephys-spikesort-spykingcircus2_si-0.101.2.sif'

	cpus 16
	memory '64 GB'
	// Allocate 4x recording duration
	time { max_duration_min.value.toFloat()*4 + 'm' }

	input:
	env max_duration_min
	path 'capsule/data/' from preprocessing_to_spikesort_spykingcircus2

	output:
	path 'capsule/results/*' into spikesort_spykingcircus2_to_postprocessing
	path 'capsule/results/*' into spikesort_spykingcircus2_to_visualization
	path 'capsule/results/*' into spikesort_spykingcircus2_to_results_collector

	when:
	sorter == 'spykingcircus2'

	script:
	"""
	#!/usr/bin/env bash
	set -e

	mkdir -p capsule
	mkdir -p capsule/data
	mkdir -p capsule/results
	mkdir -p capsule/scratch

	echo "[${task.tag}] cloning git repo..."
	git clone "https://github.com/AllenNeuralDynamics/aind-ephys-spikesort-spykingcircus2.git" capsule-repo
	git -C capsule-repo -c core.fileMode=false checkout 1f88d6741e33bf9a0e6e23107c64f3c7ad17b5e4 --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] allocated time: ${task.time}"

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${params.spikesorting_args}

	echo "[${task.tag}] completed!"
	"""
}


// capsule - Postprocess Ecephys
process postprocessing {
	tag 'postprocessing'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-base_si-0.101.2.sif'

	cpus 16
	memory '64 GB'
	// Allocate 4x recording duration
	time { max_duration_min.value.toFloat()*4 + 'm' }

	input:
	env max_duration_min
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
	git -C capsule-repo -c core.fileMode=false checkout 1bcc57e0b6be45dc39afd3ef18e0ad678173cc2e --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] allocated time: ${task.time}"

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${params.postprocessing_args}

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Curate Ecephys
process curation {
	tag 'curation'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-base_si-0.101.2.sif'

	cpus 4
	memory '32 GB'
	// Allocate 10min per recording hour. Minimum 10m
	time { max_duration_min.value.toFloat()/6 > 10 ? max_duration_min.value.toFloat()/6 + 'm' : '10m' }

	input:
	env max_duration_min
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
	git -C capsule-repo -c core.fileMode=false checkout a8d31a85ceeedb903f19c5b8476cdaf8a8b750e6 --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] allocated time: ${task.time}"


	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Unit Classifier Ecephys
process unit_classifier {
	tag 'unit-classifier'
	container 'file:///${CONTAINER_DIR}/aind-ephys-unit-classifier_si-0.101.2.sif'

	cpus 4
	memory '32 GB'
	// Allocate 30min per recording hour. Minimum 10m
	time { max_duration_min.value.toFloat()*0.5 > 10 ? max_duration_min.value.toFloat()*0.5 + 'm' : '10m' }

	input:
	env max_duration_min
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
	git -C capsule-repo -c core.fileMode=false checkout a5f1e947c7099090cca2c8250b9bad0b796a67dd --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] allocated time: ${task.time}"


	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${params.unit_classifier_args}

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Visualize Ecephys
process visualization {
	tag 'visualization'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-base_si-0.101.2.sif'

	cpus 4
	memory '64 GB'
	// Allocate 2h per recording hour
	time { max_duration_min.value.toFloat()*2 + 'm' }

	input:
	env max_duration_min
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
	git -C capsule-repo -c core.fileMode=false checkout f58ab7cda7757b4703da049a160a5677c2cd9c54 --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] allocated time: ${task.time}"


	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run

	echo "[${task.tag}] completed!"
	"""
}

// capsule - Collect Results Ecephys
process results_collector {
	tag 'result-collector'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-base_si-0.101.2.sif'

	cpus 4
	memory '32 GB'
	// Allocate 1x recording duration
	time { max_duration_min.value.toFloat() > 10 ? max_duration_min.value.toFloat() + 'm' : '10m' }

	publishDir "$RESULTS_PATH", saveAs: { filename -> new File(filename).getName() }

	input:
	env max_duration_min
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
	git -C capsule-repo -c core.fileMode=false checkout 73cb90e9c321a6c06012681ca08d93b71e99d952 --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] allocated time: ${task.time}"

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run

	echo "[${task.tag}] completed!"
	"""
}

// capsule - aind-subject-nwb
process nwb_subject {
	tag 'nwb-subject'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-nwb_si-0.101.2.sif'

	cpus 4
	memory '32 GB'
	// Allocate 10min per recording hour. Minimum 10m
	time { max_duration_min.value.toFloat()/6 > 10 ? max_duration_min.value.toFloat()/6 + 'm' : '10m' }

	input:
	env max_duration_min
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
	git clone "https://github.com/AllenNeuralDynamics/aind-subject-nwb.git" capsule-repo
    git -C capsule-repo -c core.fileMode=false checkout 6a3615779353c733622c7e65cd8aea12622b4b35 --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] allocated time: ${task.time}"

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${params.nwb_subject_args}

	echo "[${task.tag}] completed!"
	"""
}

// capsule - aind-ecephys-nwb
process nwb_ecephys {
	tag 'nwb-ecephys'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-nwb_si-0.101.2.sif'

	cpus 16
	memory '64 GB'
	// Allocate 2x recording duration
	time { max_duration_min.value.toFloat()*2 + 'm' }

	input:
	env max_duration_min
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
	git -C capsule-repo -c core.fileMode=false checkout 5bbb7a8dc57058f2040ea0b3957dd345ca302795 --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] allocated time: ${task.time}"

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run ${params.nwb_ecephys_args}

	echo "[${task.tag}] completed!"
	"""
}


// capsule - aind-units-nwb
process nwb_units {
	tag 'nwb-units'
	container 'file:///${CONTAINER_DIR}/aind-ephys-pipeline-nwb_si-0.101.2.sif'

	cpus 4
	memory '32 GB'
	// Allocate 2x recording duration
	time { max_duration_min.value.toFloat()*2 + 'm' }

	publishDir "$RESULTS_PATH/nwb", saveAs: { filename -> new File(filename).getName() }

	input:
	env max_duration_min
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
	git clone "https://github.com/AllenNeuralDynamics/aind-units-nwb.git" capsule-repo
	git -C capsule-repo -c core.fileMode=false checkout b532ec8dc7d1dc8751bb4de80941772465aaecd9 --quiet
	mv capsule-repo/code capsule/code
	rm -rf capsule-repo

	echo "[${task.tag}] allocated time: ${task.time}"

	echo "[${task.tag}] running capsule..."
	cd capsule/code
	chmod +x run
	./run

	echo "[${task.tag}] completed!"
	"""
}
