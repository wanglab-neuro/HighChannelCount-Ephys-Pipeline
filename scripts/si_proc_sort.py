#!/usr/bin/env python
# coding: utf-8

# Run this script as follow:
# python combined_script.py "path\to\data" 30

# Import libraries
import spikeinterface as si
import spikeinterface.extractors as se 
import spikeinterface.preprocessing as spre
import spikeinterface.sorters as ss
from spikeinterface.core import ZarrRecordingExtractor
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import warnings
warnings.simplefilter("ignore")

import argparse

# Set up argument parser
parser = argparse.ArgumentParser(description="Spike sorting script")
parser.add_argument("base_folder", type=str, help="Path to the base folder")
parser.add_argument("n_jobs", type=int, help="Number of jobs for spike sorting")

# Parse arguments
args = parser.parse_args()

# Define the base folder
base_folder = Path(args.base_folder)
# base_folder = Path(r"/scratch2/weka/wanglab/prevosto/data/sc012/sc012_0123/sc012_0123_001")
# base_folder = Path(r"D:\Vincent\Data\sc014\sc014_0324\sc014_0324_001")
file_path = base_folder.joinpath("Record Node 101")

# Set sorter parameters
sorter_params = dict(n_jobs=args.n_jobs)
# sorter_params = dict(n_jobs=30)

# Read the OpenEphys file
recording = se.read_openephys(file_path, stream_id='1')

# Get recording information
channel_ids = recording.get_channel_ids()
fs = recording.get_sampling_frequency()
num_chan = recording.get_num_channels()
num_segments = recording.get_num_segments()

# Print recording information
print(f'Channel ids: {channel_ids}')
print(f'Sampling frequency: {fs}')
print(f'Number of channels: {num_chan}')
print(f"Number of segments: {num_segments}")

# Phase shift
recording = spre.phase_shift(recording)

# High-pass filter
recording_f = spre.highpass_filter(recording, freq_min=300)
# recording = spre.bandpass_filter(recording, freq_min=300, freq_max=6000)

# Common Median Reference
recording_baseline = si.SelectSegmentRecording(recording_f, segment_indices=0)
recording_b_cmr = spre.common_reference(recording_baseline, reference='global', operator='median')

# Job settings for saving the preprocessed recording
job_kwargs = dict(n_jobs=10, chunk_duration="1s", progress_bar=True)
recording_saved = recording_b_cmr.save(folder=base_folder / "preprocessed", format='zarr', **job_kwargs)

# Define the zarr folder
# zarr_folder = base_folder / "preprocessed.zarr"

# Load the preprocessed recording
# recording_saved = ZarrRecordingExtractor(root_path=zarr_folder)

# Run spike sorting using PyKilosort
sorting_pyKS = ss.run_pykilosort(recording_saved,
                                 output_folder=base_folder / 'results_pyKS',
                                 verbose=True, docker_image="spikeinterface/pykilosort-base:latest",
                                 **sorter_params)

# Extract waveforms
job_kwargs = dict(n_jobs=30, chunk_duration="1s", progress_bar=False)
we_all = si.extract_waveforms(recording_saved, sorting_pyKS, folder=base_folder / "waveforms_all", 
                              max_spikes_per_unit=None,
                              overwrite=True,
                              **job_kwargs)

# Print waveform information for each unit
for unit in sorting_pyKS.get_unit_ids():
    waveforms = we_all.get_waveforms(unit_id=unit)
    spiketrain = sorting_pyKS.get_unit_spike_train(unit)
    print(f"Unit {unit} - num waveforms: {waveforms.shape[0]} - num spikes: {len(spiketrain)}")
