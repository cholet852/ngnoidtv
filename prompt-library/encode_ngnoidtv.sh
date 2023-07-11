#!/bin/bash

# Get the video name and video quality from user input
read -p "Enter the video name: " video_name
read -p "Enter the video quality (e.g. 0-63, 28): " video_quality

# Define an array of resolutions
resolutions=("720p" "360p" "240p")

# Create the master playlist file
master_playlist="${video_name}.HLS.MPL.NGNOIDTV.${video_quality}.500.250.125.m3u8"
echo "#EXTM3U" > "$master_playlist"
echo "#EXT-X-VERSION:3" >> "$master_playlist"
echo "" >> "$master_playlist"
echo "# $video_name - $(date +'%A, %B %d, %H:%M')" >> "$master_playlist"
echo "" >> "$master_playlist"

# Define fixed bandwidth values
bandwidths=("500000" "250000" "125000")

# Iterate over the resolutions and encode the video for each resolution
for i in "${!resolutions[@]}"; do
    resolution="${resolutions[i]}"
    bandwidth="${bandwidths[i]}"

    # Set the width and audio bitrate based on the resolution
    if [[ $resolution == "720p" ]]; then
        width=1280
        audio_bitrate=384k
    elif [[ $resolution == "360p" ]]; then
        width=640
        audio_bitrate=256k
    elif [[ $resolution == "240p" ]]; then
        width=426
        audio_bitrate=192k
    else
        echo "Invalid resolution. Please choose either 720p, 360p, or 240p."
        exit 1
    fi

    # Construct the output file names
    segment_filename="${video_name}.HLS.Q${video_quality}.${resolution}.a${audio_bitrate}.NGNOIDTV.m4s"
    playlist_filename="${segment_filename}.m3u8"

    # Add stream information to the master playlist
    resolution_string="${width}x$((width * 9 / 16))"
    echo "#EXT-X-STREAM-INF:BANDWIDTH=${bandwidth},RESOLUTION=${resolution_string}" >> "$master_playlist"
    echo "${segment_filename}.m3u8" >> "$master_playlist"

    # Execute the FFmpeg command with the provided inputs
    /snap/bin/ffmpeg -hwaccel cuda -i input_video.mkv -map_metadata -1 -force_key_frames "expr:gte(t,n_forced*2)" -sc_threshold 0 -vf "hwupload_cuda,scale_npp=w=${width}:h=-2" -cq:v ${video_quality} -c:v h264_nvenc -c:a libfdk_aac -b:a ${audio_bitrate} -hls_time 6 -hls_playlist_type vod -hls_segment_type fmp4 -hls_segment_filename "${segment_filename}" -hls_flags single_file "${playlist_filename}"
done
